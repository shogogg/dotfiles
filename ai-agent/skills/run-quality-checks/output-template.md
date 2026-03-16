# Output Template

Write results to `<work-dir>/QUALITY_RESULT.md` using the following format:

```markdown
# Quality Check Result

## Summary
- Overall: PASS / FAIL
- Tests: PASS / FAIL / SKIPPED
- Lint: PASS / FAIL / SKIPPED
- Static Analysis: PASS / FAIL / SKIPPED
- Format: PASS / FAIL / SKIPPED
- Auto-fix Applied: YES / NO

## Details

### Tests
- Command: `...`
- Exit code: 0
- Output: (truncated if long)

### Lint
- Command: `...`
- Exit code: 1
- Output:
  ```
  (error details)
  ```

<!-- Repeat for each category -->

## Auto-fix Results

<!-- Include this section only if auto-fix tasks were executed -->

### Format (auto-fix)
- Command: `task format`
- Files modified: YES / NO
- Diff summary:
  ```
  (git diff --stat output, or "No changes")
  ```

### Lint (auto-fix)
- Command: `task lint:fix`
- Files modified: YES / NO
- Diff summary:
  ```
  (git diff --stat output, or "No changes")
  ```

<!-- Include only categories where auto-fix was executed -->

---

## Statistics

- **Agent/Skill**: run-quality-checks
- **Start Time**: {ISO 8601 timestamp}
- **End Time**: {ISO 8601 timestamp}
- **Duration**: {seconds} seconds ({human-readable format})
- **Commands Executed**: {number of commands}
- **Test Scope**: {full/changed/directory/custom} (if applicable)
```
