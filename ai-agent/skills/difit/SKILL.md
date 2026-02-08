---
name: difit
description: Runs difit to launch a browser-based diff review UI and reports the result. Use when the user wants to review diffs with difit, visually review code changes in a browser, or says "difit でレビュー".
model: sonnet
allowed-tools: Bash(run-difit.sh), TaskOutput, AskUserQuestion
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

### Step 3: Run difit in Background

Execute the following command with `run_in_background: true`:

```bash
Bash(command="$SKILL_DIR/run-difit.sh --clean <target> <base>", run_in_background=true)
```

Save the returned `task_id` for polling.

**Important**:
- Always use `run-difit.sh` wrapper (not `npx difit` directly). It provides a pseudo-tty to prevent difit from entering STDIN mode.
- Do NOT pipe diff to stdin. Always pass arguments directly.
- Always include the `--clean` flag.

### Step 4: Wait for Completion with User Check-in

Poll for completion using `TaskOutput` with a 30-second interval. Check in with the user every 15 minutes (30 polls).

**Polling loop:**

1. Set `poll_count = 0`
2. Call `TaskOutput(task_id=..., block=true, timeout=30000)`
3. If the task completes → save the output and proceed to Step 5
4. If timeout (30 seconds elapsed without completion):
   - Increment `poll_count`
   - If `poll_count` is a multiple of 30 (every 15 minutes) → ask the user:
     ```
     AskUserQuestion:
       question: "difit でのレビューが継続中です。待機を続けますか？"
       header: "レビュー待機"
       options:
         - label: "待機を続ける"
           description: "引き続きレビュー完了を待ちます"
         - label: "レビュー完了として続行"
           description: "レビューを終了し、承認済みとして次に進みます"
     ```
     - If user chooses to continue → go to step 2
     - If user chooses to finish → stop the background task using `TaskStop(task_id=...)`, treat as APPROVED, and proceed to Step 5 with no feedback
   - Otherwise → go to step 2

### Step 5: Determine Result

First, verify that difit ran successfully:

1. **Startup check**: If the output does NOT contain `difit server started on` → The launch failed. Retry once (go back to Step 3). If the retry also lacks this marker, report an error and stop.
2. **Premature exit check**: If stderr contains `Warning: difit exited in` → The session ended too quickly for the user to review. Retry once (go back to Step 3). If the retry also exits prematurely, report an error and stop.

Then, inspect the output for user feedback:

- **If output contains `📝 Comments from review session:`** → User has feedback.
- **Otherwise** → No feedback (APPROVED).

### Step 6: Report Result

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
- If the output does not contain `difit server started on` (empty, blank, or unexpected response), retry once (as described in Step 5). If the retry also fails, report:
  ```
  Error: difit failed to start after retry. Please run difit manually.
  ```
- If stderr contains `Warning: difit exited in` (premature exit without user review), retry once. If the retry also exits prematurely, report:
  ```
  Error: difit exited too quickly for user review after retry. Please run difit manually.
  ```
