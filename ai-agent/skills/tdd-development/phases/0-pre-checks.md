# Phase 0: Pre-checks (Main agent executes directly)

## Parallel Execution Strategy

Some checks can run in parallel for efficiency. Group steps as follows:

### Group A: Environment Checks (Run in parallel)

Execute these two checks **in parallel** using parallel Bash tool calls:

1. **Verify go-task runner**: Check if `Taskfile.yaml` or `Taskfile.dist.yaml` exists at the project root. If found, confirm the go-task `task` CLI command is available (run `task --version` via Bash). If not found, warn the user but continue.

2. **CodeRabbit auth**: Run `coderabbit auth status`. If not authenticated, **abort the workflow** and inform the user.

### Group B: User Clarification (Sequential)

After Group A completes:

3. **Clarify the task**: Use `AskUserQuestion` to resolve any ambiguity in `$ARGUMENTS`.

4. **Branch**: Ask the user if a feature branch should be created.

   **If yes (creating new branch)**:
   a. Record the current branch as the base branch:
      ```bash
      BASE_BRANCH=$(git rev-parse --abbrev-ref HEAD)
      ```
   b. Create the feature branch:
      ```bash
      git checkout -b <branch-name>
      ```
   c. Store `BASE_BRANCH` for later use.

   **If no (staying on current branch)**:
   Determine the base branch using fallback detection:
   ```bash
   # Try remote tracking branches first (more reliable)
   BASE_BRANCH=$(git merge-base HEAD origin/main 2>/dev/null && echo "origin/main") || \
   BASE_BRANCH=$(git merge-base HEAD origin/master 2>/dev/null && echo "origin/master") || \
   # Fall back to local branches
   BASE_BRANCH=$(git merge-base HEAD main 2>/dev/null && echo "main") || \
   BASE_BRANCH=$(git merge-base HEAD master 2>/dev/null && echo "master") || \
   # Last resort: use current HEAD (no comparison possible)
   BASE_BRANCH="HEAD"
   ```

   **Note**: If `BASE_BRANCH` is "HEAD", warn the user that diff comparison may not work properly in Phase 7.

### Group C: Workspace Setup (Sequential, after Group B)

5. **Create workspace**: Create `.ai-workspace/YYYY-MM-DD_<branch>/` where:
   - `YYYY-MM-DD` is today's date
   - `<branch>` is the current git branch name (sanitize any slashes to underscores)

6. **Initialize state**: Write `STATE.json` to the workspace directory:
   ```json
   {
     "currentPhase": 1,
     "currentPhaseId": "exploration",
     "phase5RetryCount": 0,
     "baseBranch": "<BASE_BRANCH>",
     "featureBranch": "<current-branch-name>",
     "startCommitHash": "<current-HEAD-hash>",
     "firstCommitHash": null,
     "lastReviewCommit": null,
     "qualityScope": null,
     "qualityFailedCategories": []
   }
   ```
   - `startCommitHash`: The HEAD commit hash at session start (obtained via `git rev-parse HEAD`)
   - `baseBranch`: The branch/ref determined in step 4 (e.g., "origin/main", "main", or "HEAD")
   - `featureBranch`: The current branch name after step 4
   - `lastReviewCommit`: Updated after each review cycle (Phase 6) with the HEAD commit hash at review time. Used as a "since last review" diff base option.
   - `qualityScope`: Saved in Phase 5 Step 1 after the user selects test/target scope. Format: `{ "test": { "scope": "<full|changed|directory|custom>", "args": "<args-string>" }, "target": { "mode": "<full|files|directories|custom>", "paths": [<paths>] } }`. Reused on subsequent Phase 5 invocations to skip re-prompting. `null` until first selection.
   - `currentPhaseId`: Stable string identifier for the current phase (e.g., `"exploration"`, `"quality-checks"`). Updated alongside `currentPhase` at every phase transition. Used by Resume Detection to identify the correct phase even if phase numbers are renumbered.
   - `qualityFailedCategories`: List of category names (`test`, `lint`, `analyse`, `format`) that failed in the most recent Phase 5 run. Used by Phase 5 Step 2 to pass `--categories=<failed>` on retry so only failed checks re-run. Cleared on overall PASS.

## State Update
Update `STATE.json`: set `currentPhase` to `1` and `currentPhaseId` to `"exploration"`.
