# Output Files

The skill writes the following files to `<work-dir>` (the workspace directory provided as positional argument):

## Per-category files (raw output + exit code)

For each executed category, two files are written:

- `QC_<CATEGORY>.raw` — Raw, unmodified stdout/stderr from the command (no markdown wrapping).
- `QC_<CATEGORY>.exitcode` — A single line containing the exit code (e.g., `0` or `1`).

`<CATEGORY>` is one of: `TEST`, `LINT`, `ANALYSE`, `FORMAT`.

These files are written ONLY for categories actually executed in the current invocation. Pre-existing files from previous invocations (e.g., categories not in `--categories`) are NOT touched, allowing the orchestrator to retain prior state.

## Summary file

`<work-dir>/QC_SUMMARY.md`:

```markdown
# Quality Check Summary

- Overall: PASS / FAIL
- Test: PASS / FAIL / SKIPPED
- Lint: PASS / FAIL / SKIPPED
- Static Analysis: PASS / FAIL / SKIPPED
- Format: PASS / FAIL / SKIPPED
- Auto-fix Applied: YES / NO
- Categories Executed: test, lint, analyse, format

## Statistics
- Start Time: {ISO 8601}
- End Time: {ISO 8601}
- Duration: {seconds} seconds
- Commands Executed: {number}
- Test Scope: {full/changed/directory/custom}
- Task List Cache: HIT / MISS
```

**SKIPPED** appears for categories not present in `task --list-all` OR not in `--categories` when filtering.

## Auto-fix file (conditional)

`<work-dir>/QC_AUTOFIX.md` — Written ONLY when auto-fix tasks were executed in Sub-step A:

```markdown
# Auto-fix Results

## Format (auto-fix)
- Command: `task format`
- Files modified: YES / NO
- Diff summary:
  ```
  (git diff --stat output, or "No changes")
  ```

## Lint (auto-fix)
- Command: `task lint:fix`
- Files modified: YES / NO
- Diff summary:
  ```
  (git diff --stat output, or "No changes")
  ```
```

## Task list cache

`<work-dir>/TASK_LIST.txt` — Raw output of `task --list-all`. Written on first execution, reused thereafter to avoid repeated invocations across this skill and `tdd-implementer` sub-agents.

## Reading guidance for the orchestrator

- For PASS/FAIL decision: read `QC_<CATEGORY>.exitcode` files (one byte; `0` = PASS, non-zero = FAIL).
- For overall status: read `QC_SUMMARY.md`.
- For error details (when investigating a FAIL): read the specific `QC_<CATEGORY>.raw` file.
- Do NOT expect a consolidated `QUALITY_RESULT.md` — that file is no longer produced.
