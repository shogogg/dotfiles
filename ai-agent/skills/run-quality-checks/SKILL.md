---
name: run-quality-checks
description: Runs project quality checks (tests, lint, static analysis, formatting) and reports results. Use after code changes to validate quality, or when the user asks to run tests, lint, or static analysis.
context: fork
allowed-tools: Bash, Read, Write, Glob, Grep, TaskCreate, TaskUpdate, TaskList
---

# /run-quality-checks

## CRITICAL: No Autonomous Troubleshooting Policy

**When a command fails to execute as expected (not finding the tool, wrong arguments, unexpected errors, etc.), you MUST NOT:**

1. Investigate or debug the issue on your own (e.g., checking `--help`, reading documentation, searching for alternatives)
2. Retry with different arguments or options
3. Fall back to alternative tools or commands
4. Attempt to install or configure missing tools

**Instead, you MUST:**

1. Report the exact command that was executed
2. Report the exact error output (unmodified)
3. Stop and let the caller/user decide the next action

**This policy applies to tool execution failures only.** Test failures, lint errors, and other code quality issues are expected outputs and should be handled normally per the workflow below.

**Clarification**: "Tool execution failure" means the command itself cannot run properly (e.g., command not found, invalid arguments, permission denied, unexpected crash). "Code quality issues" means the command ran successfully but reported problems in the code (e.g., test assertions failed, lint rule violations).

## Arguments

`$ARGUMENTS` may contain:

- **Workspace directory path** (positional, optional): If provided, write individual results to `<work-dir>/QC_*.md` files (one per category + summary). Otherwise, output the result directly.
- `--target=<paths>` (optional): Target files or directories for all quality checks (lint, analyse, format). When provided, check each task's description for how to pass arguments and prioritize targeted execution over full project scans.
- `--test-scope=<scope>` (optional): Test execution scope.
  - `changed` — Run only the specified test files (listed in `--test-args`).
  - `directory` — Run tests in the specified directory/namespace (listed in `--test-args`).
  - `full` — Run the full test suite (default).
  - `custom` — Pass custom arguments to the test runner (listed in `--test-args`).
- `--test-args=<args>` (optional): Arguments for `--test-scope`. Examples:
  - `--test-scope=changed --test-args=tests/Unit/FooTest.php tests/Unit/BarTest.php`
  - `--test-scope=directory --test-args=tests/Unit/Services/`
  - `--test-scope=custom --test-args=--filter=testMethodName`

## Workflow

### Step 0: Record Start Time (REQUIRED)

**MANDATORY**: Before any other action, record the start time:

```bash
START_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
START_EPOCH=$(date +%s)
```

Store these values for use in Step 4 (statistics reporting).

### Step 1: Detect Task Runner (CRITICAL — DO THIS FIRST)

> **Terminology**: In this document, "`task`" (in backticks) refers to the **go-task CLI** (https://taskfile.dev), NOT Claude Code's `Task` tool for launching sub-agents. They are completely different things. When running quality checks, you execute go-task commands via the **Bash** tool.

**MANDATORY**: Run `task --list-all` via the **Bash** tool as your FIRST action (after recording start time).

```bash
task --list-all
```

**Decision tree:**
- ✅ Command succeeds → **MUST use Step 2a**. Proceed immediately. Do NOT check for other runners.
- ❌ Command fails → **Report the failure and stop.** Do NOT proceed to find alternative runners. Report the exact error message and let the caller/user decide.

**CRITICAL RULES:**
1. If `task --list-all` succeeds, you MUST use go-task `task` CLI commands (via Bash) for ALL quality checks.
2. Do NOT fall back to `composer`, `npm`, or `make` when go-task `task` is available.
3. If a specific task category (e.g., lint) is not found in the task list, mark that category as SKIPPED. Do NOT use fallback commands for missing categories.
4. If any `task` command fails with an execution error (not a code quality error), report the exact command and error output and stop. Do NOT retry with different arguments or investigate the cause.

### Step 1.5: Create Progress Tasks (MANDATORY)

After identifying available quality check categories from `task --list-all`, create a task for each detected category using `TaskCreate`. This makes progress visible to the user.

**Create tasks for each detected category:**

```
TaskCreate: subject="テストを実行する", activeForm="テストを実行しています"
TaskCreate: subject="Lint を実行する", activeForm="Lint を実行しています"
TaskCreate: subject="静的解析を実行する", activeForm="静的解析を実行しています"
TaskCreate: subject="フォーマットを確認する", activeForm="フォーマットを確認しています"
```

- Only create tasks for categories that were actually found in `task --list-all` output.
- Create all tasks in a single parallel call.

### Step 2a: Execute via Taskfile (PRIMARY PATH)

**You MUST be here if `task --list-all` succeeded.**

From the task list output, identify tasks by name or description:

| Category | Type | Keywords to match | Example commands |
|---|---|---|---|
| Test | check | test, testing, spec | `task test`, `task tests` |
| Lint | check | lint, linter, eslint, phpcs, cs | `task lint`, `task cs` |
| Lint | fix | lint:fix, cs:fix, eslint:fix | `task lint:fix`, `task cs:fix` |
| Static Analysis | check | analyse, analyze, static, phpstan, psalm | `task analyse`, `task phpstan` |
| Format | check | format:check, format:verify | `task format:check` |
| Format | fix | format, format:fix, prettier, php-cs-fixer, fix | `task format`, `task format:fix` |

**Auto-fix detection (IMPORTANT):**

For each category (Lint, Format), identify both "check" and "fix" task variants from the `task --list-all` output. A "fix" variant is a task that **automatically modifies source files** to resolve issues (e.g., reformatting code, fixing coding style).

Detection heuristics:
- Task names containing `:fix` suffix (e.g., `lint:fix`, `cs:fix`, `format:fix`)
- Task descriptions mentioning "fix", "auto-fix", "reformat", "format" (for write operations)
- For Format category: the primary task (e.g., `task format`) is often the fix variant by default; a separate check-only task may exist (e.g., `format:check`, `format:dry-run`)

Record detected fix tasks for use in the auto-fix step below.

**Progress tracking (MANDATORY):**
- Before running each category: `TaskUpdate` → `status: "in_progress"`
- After each category completes: `TaskUpdate` → `status: "completed"`

**Execution Strategy: 3 Sub-steps**

The execution is split into 3 sub-steps to maximize parallelism while ensuring file-modifying operations don't conflict:

#### Sub-step A: Auto-fix (Sequential — file-modifying operations)

For categories where a "fix" variant was detected, run auto-fix tasks **sequentially** to avoid file conflicts:

1. **Format fix** (if detected): Execute `task format` (or detected fix variant)
   - Check for diffs: `git diff --stat`
   - Record diff summary
2. **Lint fix** (if detected): Execute `task lint:fix` (or detected fix variant)
   - Check for diffs: `git diff --stat`
   - Record diff summary

Record all auto-fix results (commands executed, files changed, diff summary) for the Auto-fix section in the output.

#### Sub-step B: All Checks (Parallel — self-reporting)

Launch ALL check tasks simultaneously using **parallel Bash tool calls**. Each check runs in its own Bash call, and **each Bash call writes its own formatted report file directly** — no post-processing by the agent is needed.

| Category | Command (example) | Report file |
|---|---|---|
| Test | `task test` | `<work-dir>/QC_TEST.md` |
| Lint | `task lint` | `<work-dir>/QC_LINT.md` |
| Static Analysis | `task analyse` | `<work-dir>/QC_ANALYSE.md` |
| Format | `task format:check` | `<work-dir>/QC_FORMAT.md` |

**Each parallel Bash call pattern:**
```bash
CMD="task <command>"
$CMD > <work-dir>/.qc_<category>_raw.txt 2>&1
EXIT=$?
{
  echo "# <Category> Result"
  echo ""
  echo "- **Command**: \`$CMD\`"
  echo "- **Exit code**: $EXIT"
  echo "- **Status**: $([ $EXIT -eq 0 ] && echo PASS || echo FAIL)"
  echo ""
  echo "## Output"
  echo '```'
  if [ $EXIT -eq 0 ]; then
    tail -20 <work-dir>/.qc_<category>_raw.txt
  else
    tail -100 <work-dir>/.qc_<category>_raw.txt
  fi
  echo '```'
} > <work-dir>/QC_<CATEGORY>.md
echo "EXIT:$EXIT"
```

**CRITICAL**: All available category checks MUST be issued as parallel Bash tool calls in a single message, not sequentially.

**Progress tracking**: After each parallel Bash call returns, `TaskUpdate` that category → `status: "completed"`.

#### Sub-step C: Write Summary (Trivial)

After all parallel checks complete, write `<work-dir>/QC_SUMMARY.md` from the collected exit codes. This requires **no content processing** — just map exit codes to PASS/FAIL:

```markdown
# Quality Check Summary

- Overall: PASS / FAIL
- Test: PASS / FAIL / SKIPPED
- Lint: PASS / FAIL / SKIPPED
- Static Analysis: PASS / FAIL / SKIPPED
- Format: PASS / FAIL / SKIPPED
- Auto-fix Applied: YES / NO
```

Also append statistics (start time, end time, duration, command count) to `QC_SUMMARY.md`.

**When `--target` is provided (IMPORTANT):**

> **Note**: The `--target` handling below applies **within each category's Bash call** in Sub-step B. Each category's final output (including merged results from multiple paths) must be redirected to its `QC_<CATEGORY>_RAW.txt` file.

1. For each task (lint, analyse, format), examine the task description from `task --list-all` output.
2. If the description indicates how to pass file/directory arguments:
   
   **Multiple paths provided (2 or more):**
   - Split paths into batches of 5 (max 5 concurrent executions per batch)
   - For each batch, execute tasks in parallel using Bash job control (`&` and `wait`)
   - Each path runs as: `task <task-name> -- <single-path>`
   - Capture individual outputs to temporary files (e.g., `result1.txt`, `result2.txt`, ...)
   - Collect and merge all results after all batches complete
   
   **Example parallel execution:**
   ```bash
   # Batch 1 (5 parallel)
   task phpstan -- src/Foo.php > result1.txt 2>&1 &
   task phpstan -- src/Bar.php > result2.txt 2>&1 &
   task phpstan -- src/Baz.php > result3.txt 2>&1 &
   task phpstan -- src/Qux.php > result4.txt 2>&1 &
   task phpstan -- src/Quux.php > result5.txt 2>&1 &
   wait
   
   # Batch 2 (remaining)
   task phpstan -- src/Other.php > result6.txt 2>&1 &
   wait
   
   # Collect results
   cat result*.txt
   ```
   
   **Single path provided:**
   ```bash
   task <task-name> -- <single-path>
   # Example: task phpstan -- src/Services/
   ```

3. If the description does NOT indicate argument support, run the task without arguments (full project scope) and note this in the output.

**When `--test-scope` is provided:**
```bash
task <test-task> -- <test-args>
# Example: task test -- tests/Unit/FooTest.php
```

**Priority order:**
1. Use `--target` with task-specific argument syntax (if supported by task description)
   - Multiple paths: parallel execution (max 5 concurrent)
   - Single path: direct execution
2. Use `--test-scope` / `--test-args` for test tasks
3. Fall back to full project execution only when targeting is not possible

Lint, static analysis, and format tasks run with `--target` arguments when provided (parallelized for multiple paths), otherwise run on the full project.

Run all applicable tasks even if some fail. Capture stdout and stderr.

**IMPORTANT: Command execution failure handling**
If any `task` command fails with an **execution error** (e.g., command not found, invalid task name, permission denied, unexpected crash — NOT code quality errors like test failures or lint violations):
1. Record the exact command and error output
2. Mark that category as FAIL with the raw error output
3. Continue to the next category (do NOT retry, modify arguments, or investigate)
4. In the final report, clearly distinguish execution errors from code quality errors

### Step 2b: Report Failure (ONLY IF go-task `task` CLI UNAVAILABLE)

**If `task --list-all` failed, do NOT attempt to find or use alternative tools.**

Report the following to the caller/user:
1. The exact command that was executed (`task --list-all`)
2. The exact error output
3. A message: "go-task CLI が利用できません。対応方法をご指示ください。"

**Do NOT** scan for `composer.json`, `package.json`, `Makefile`, or any other tool configuration files. Wait for user instructions.

### Step 3: Write Summary and Return

**No compilation or assembly step is needed.** Each check has already written its own `QC_<CATEGORY>.md` report in Sub-step B.

If a workspace directory was provided:

1. **Calculate statistics:**
   ```bash
   END_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
   END_EPOCH=$(date +%s)
   DURATION=$((END_EPOCH - START_EPOCH))
   MINUTES=$((DURATION / 60))
   SECONDS=$((DURATION % 60))
   ```

2. **Write `<work-dir>/QC_SUMMARY.md`** using the exit codes already collected from parallel Bash calls. See [output-template.md](output-template.md) for the required format. This requires **no content processing** — just map exit codes to PASS/FAIL and append statistics.

3. **Write `<work-dir>/QC_AUTOFIX.md`** (only if auto-fix was executed in Sub-step A). Record commands executed, files modified, and diff summaries.

4. **Return a brief summary**: overall PASS/FAIL status and error counts. Communicate results in Japanese.
