# Phase 0: Pre-checks (Main agent executes directly)

1. **Clarify the task**: Use `AskUserQuestion` to resolve any ambiguity in `$ARGUMENTS`.

2. **Branch**: Ask the user if a feature branch should be created. If yes, create it with `git checkout -b <branch-name>`.

3. **Verify task runner**: Check if `Taskfile.yaml` or `Taskfile.dist.yaml` exists at the project root. If found, confirm `task` command is available. If not found, warn the user but continue.

4. **CodeRabbit auth**: Run `coderabbit auth status`. If not authenticated, **abort the workflow** and inform the user.

5. **Create workspace**: Create `.ai-workspace/YYYY-MM-DD_<branch>/` where:
   - `YYYY-MM-DD` is today's date
   - `<branch>` is the current git branch name (sanitize any slashes to underscores)

6. **Initialize state**: Write `STATE.json` to the workspace directory:
   ```json
   {"currentPhase": 1, "phase5RetryCount": 0, "cycleCount": 0}
   ```

## State Update
Update `STATE.json`: set `currentPhase` to `1`.
