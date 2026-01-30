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
```
