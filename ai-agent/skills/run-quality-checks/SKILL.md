---
name: run-quality-checks
description: Runs project quality checks (tests, lint, static analysis, formatting) and reports results. Use after code changes to validate quality, or when the user asks to run tests, lint, or static analysis.
context: fork
allowed-tools: Bash, Read, Write, Glob, Grep
---

# /run-quality-checks

## Arguments

`$ARGUMENTS` may contain:

- **Workspace directory path** (positional, optional): If provided, write the result to `<work-dir>/QUALITY_RESULT.md`. Otherwise, output the result directly.
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

### Step 1: Detect Task Runner (CRITICAL — DO THIS FIRST)

> **Terminology**: In this document, "`task`" (in backticks) refers to the **go-task CLI** (https://taskfile.dev), NOT Claude Code's `Task` tool for launching sub-agents. They are completely different things. When running quality checks, you execute go-task commands via the **Bash** tool.

**MANDATORY**: Run `task --list-all` via the **Bash** tool as your FIRST action.

```bash
task --list-all
```

**Decision tree:**
- ✅ Command succeeds → **MUST use Step 2a**. Proceed immediately. Do NOT check for other runners.
- ❌ Command fails with "command not found" or similar → Proceed to Step 2b.

**CRITICAL RULES:**
1. If `task --list-all` succeeds, you MUST use go-task `task` CLI commands (via Bash) for ALL quality checks.
2. Do NOT fall back to `composer`, `npm`, or `make` when go-task `task` is available.
3. If a specific task category (e.g., lint) is not found in the task list, mark that category as SKIPPED. Do NOT use fallback commands for missing categories.

### Step 2a: Execute via Taskfile (PRIMARY PATH)

**You MUST be here if `task --list-all` succeeded.**

From the task list output, identify tasks by name or description:

| Category | Keywords to match | Example commands |
|---|---|---|
| Test | test, testing, spec | `task test`, `task tests` |
| Lint | lint, linter, eslint, phpcs, cs | `task lint`, `task cs` |
| Static Analysis | analyse, analyze, static, phpstan, psalm | `task analyse`, `task phpstan` |
| Format | format, prettier, php-cs-fixer, fix | `task format`, `task fix` |

**When `--target` is provided (IMPORTANT):**

1. For each task (lint, analyse, format), examine the task description from `task --list-all` output.
2. If the description indicates how to pass file/directory arguments (e.g., "Usage: task phpstan [-- <files>]"), use that format:
   ```bash
   task <task-name> -- <target-paths>
   # Example: task phpstan -- src/Services/
   # Example: task lint -- src/Foo.php src/Bar.php
   ```
3. If the description does NOT indicate argument support, run the task without arguments (full project scope) and note this in the output.

**When `--test-scope` is provided:**
```bash
task <test-task> -- <test-args>
# Example: task test -- tests/Unit/FooTest.php
```

**Priority order:**
1. Use `--target` with task-specific argument syntax (if supported by task description)
2. Use `--test-scope` / `--test-args` for test tasks
3. Fall back to full project execution only when targeting is not possible

Lint, static analysis, and format tasks run with `--target` arguments when provided, otherwise run on the full project.

Run all applicable tasks even if some fail. Capture stdout and stderr.

### Step 2b: Fallback Execution (ONLY IF go-task `task` CLI UNAVAILABLE)

**ONLY use this step if `task --list-all` failed with "command not found".**

| Indicator | Commands |
|---|---|
| `composer.json` | `composer test`, `composer analyse`, `composer lint` |
| `package.json` | `npm test`, `npm run lint` |
| `Makefile` | `make test`, `make lint` |

If none exist, report: "Could not determine project type. No quality checks were run."

### Step 3: Compile Results

For each executed check, record:
- Command executed
- Exit code (0 = pass, non-zero = fail)
- Output summary (truncate to key errors if output is long)

If a command times out, record it as FAIL with a timeout note.

### Step 4: Write Output

If a workspace directory was provided, write results to `<work-dir>/QUALITY_RESULT.md`.
See [output-template.md](output-template.md) for the required format.

### Step 5: Return Summary

Output a brief summary: overall PASS/FAIL status and error counts.

Communicate results in Japanese.
