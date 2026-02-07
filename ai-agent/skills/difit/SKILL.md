---
name: difit
description: Runs difit to launch a browser-based diff review UI and reports the result. Use when the user wants to review diffs with difit, visually review code changes in a browser, or says "difit でレビュー".
model: sonnet
allowed-tools: Bash(run-difit.sh)
context: fork
---

# difit Skill

Launches difit for browser-based diff review and reports the result.

## Arguments

- `$ARGUMENTS`: `<target> <base>`
  - `<target>`: Review target (HEAD, commit hash, branch name, or `.` for uncommitted changes)
  - `<base>`: Review base (HEAD, commit hash, branch name)

## Workflow

### Step 1: Convert Arguments

Replace `HEAD` with `@` in both `<target>` and `<base>` arguments.

Examples:
- `HEAD main` → `@ main`
- `. HEAD` → `. @`
- `HEAD~3 HEAD` → `@~3 @`

### Step 2: Validate Arguments

Before running difit, validate the arguments:

1. **Both `<target>` and `<base>` must be present**. If either is missing, output an error and stop:
   ```
   Error: difit requires both <target> and <base> arguments.
   ```
2. **`<target>` and `<base>` must not be identical**. If they are the same, output an error and stop:
   ```
   Error: <target> and <base> are the same. No diff to review.
   ```

### Step 3: Run difit

Execute the following command:

```bash
$SKILL_DIR/run-difit.sh --clean <target> <base>
```

Use `timeout: 600000` (10 minutes) in the Bash tool call. Do NOT run in background.

**Important**:
- Always use `run-difit.sh` wrapper (not `npx difit` directly). It provides a pseudo-tty to prevent difit from entering STDIN mode.
- Do NOT pipe diff to stdin. Always pass arguments directly.
- Always include the `--clean` flag.

### Step 4: Determine Result

First, verify that difit ran successfully:

1. **Startup check**: If the output does NOT contain `difit server started on` → The launch failed. Retry once (go back to Step 3). If the retry also lacks this marker, report an error and stop.
2. **Premature exit check**: If stderr contains `Warning: difit exited in` → The session ended too quickly for the user to review. Retry once (go back to Step 3). If the retry also exits prematurely, report an error and stop.

Then, inspect the output for user feedback:

- **If output contains `📝 Comments from review session:`** → User has feedback.
- **Otherwise** → No feedback (APPROVED).

### Step 5: Report Result

#### When feedback exists:

Output:

```
There is user feedback.

<feedback content from difit output>
```

Include the full feedback section from difit STDOUT as-is.

#### When no feedback:

Output only:

```
No user feedback. It is APPROVED.
```

## Error Handling

- If difit fails to start or is not installed, report the error.
- If the command times out, report that the review session timed out.
- If the output does not contain `difit server started on` (empty, blank, or unexpected response), retry once (as described in Step 4). If the retry also fails, report:
  ```
  Error: difit failed to start after retry. Please run difit manually.
  ```
- If stderr contains `Warning: difit exited in` (premature exit without user review), retry once. If the retry also exits prematurely, report:
  ```
  Error: difit exited too quickly for user review after retry. Please run difit manually.
  ```
