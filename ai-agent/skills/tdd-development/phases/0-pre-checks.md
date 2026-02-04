# Phase 0: Pre-checks (Main agent executes directly)

## Parallel Execution Strategy

Some checks can run in parallel for efficiency. Group steps as follows:

### Group A: Environment Checks (Run in parallel)

Execute these two checks **in parallel** using parallel Bash tool calls:

1. **Verify task runner**: Check if `Taskfile.yaml` or `Taskfile.dist.yaml` exists at the project root. If found, confirm `task` command is available. If not found, warn the user but continue.

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

   **Note**: If `BASE_BRANCH` is "HEAD", warn the user that diff comparison may not work properly in Phase 8.

### Group C: Workspace Setup (Sequential, after Group B)

5. **Create workspace**: Create `.ai-workspace/YYYY-MM-DD_<branch>/` where:
   - `YYYY-MM-DD` is today's date
   - `<branch>` is the current git branch name (sanitize any slashes to underscores)

6. **Initialize state**: Write `STATE.json` to the workspace directory:
   ```json
   {
     "currentPhase": 1,
     "phase5RetryCount": 0,
     "cycleCount": 0,
     "baseBranch": "<BASE_BRANCH>",
     "featureBranch": "<current-branch-name>"
   }
   ```
   - `baseBranch`: The branch/ref determined in step 4 (e.g., "origin/main", "main", or "HEAD")
   - `featureBranch`: The current branch name after step 4

## State Update
Update `STATE.json`: set `currentPhase` to `1`.
