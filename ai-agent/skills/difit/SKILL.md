---
name: difit
description: Runs difit to launch a browser-based diff review UI and reports the result. Use when the user wants to review diffs with difit, visually review code changes in a browser, or says "difit でレビュー".
model: sonnet
allowed-tools: Bash(run-difit.sh), Bash(fetch-comments.sh), TaskStop, AskUserQuestion, Read
context: inherit
---

# difit Skill

Launches difit for browser-based diff review and reports the result.

## Arguments

- `$ARGUMENTS`: `<output_file> <target> <base>`
  - `<output_file>`: Path to write difit output (required).
  - `<target>`: Review target (HEAD, commit hash, branch name, or `.` for uncommitted changes)
  - `<base>`: Review base (HEAD, commit hash, branch name)

## Workflow

### Step 1: Parse Arguments

Split `$ARGUMENTS` by whitespace. The **first token** is `<output_file>`, the **second token** is `<target>`, and the **third token** is `<base>`.

Example: `$ARGUMENTS` = `"/path/to/work/DIFIT_OUTPUT.md HEAD GROO-794_branch"` → `<output_file>` = `/path/to/work/DIFIT_OUTPUT.md`, `<target>` = `HEAD`, `<base>` = `GROO-794_branch`

**Do NOT modify or convert the arguments** (e.g., do NOT replace `HEAD` with `@`). The shell script handles conversion automatically.

### Step 2: Validate Arguments

1. **All three arguments (`<output_file>`, `<target>`, `<base>`) must be present**. If any is missing, output an error and stop:
   ```
   Error: difit requires <output_file>, <target>, and <base> arguments.
   ```
2. **`<target>` and `<base>` must not be identical**. If they are the same, output an error and stop:
   ```
   Error: <target> and <base> are the same. No diff to review.
   ```

### Step 3: Run difit in Background

Execute the following command with `run_in_background: true`. Pass `<output_file>` as the **first positional argument**:

```bash
Bash(command="$SKILL_DIR/run-difit.sh --clean --keep-alive <output_file> <target> <base>", run_in_background=true)
```

Save the returned `task_id` (used later to stop the server in Step 6).

**Important**:
- Always use `run-difit.sh` wrapper (not `npx difit` directly). It provides a pseudo-tty to prevent difit from entering STDIN mode.
- Do NOT pipe diff to stdin. Always pass arguments directly.
- Always include the `--clean` flag.
- Always include the `--keep-alive` flag. This keeps the difit server running even after the browser tab is closed, so comments can be retrieved via HTTP in Step 5 regardless of browser/process state. (Without it, closing the browser shuts the server down and comments become unretrievable.)
- `<output_file>` is the first positional argument — the script redirects difit output there (no pipe). The file is used to detect server startup and the auto-assigned port.
- Because `--keep-alive` is set, the background task will **not** complete on its own; it must be stopped via `TaskStop` in Step 6.

### Step 4: Ask User for Review Completion

After launching difit in Step 3, immediately confirm completion with the user. **You MUST use the `AskUserQuestion` tool for this — never ask via a plain text message and wait for a manual reply.** Do NOT poll for completion first.

```
AskUserQuestion:
  question: "ブラウザでの difit レビューが完了したら選択してください。"
  header: "レビュー完了確認"
  options:
    - label: "完了"
      description: "レビューを終えました。コメントを取得して続行します"
    - label: "中止"
      description: "レビューを中止し、承認として続行します（コメント未取得）"
```

- **「完了」** → Proceed to Step 4.5. Approval status is determined by fetching comments via HTTP in Step 5, not from this selection. The user does **not** need to close the browser — `--keep-alive` keeps the server reachable.
- **「中止」** → Skip Steps 4.5 and 5. Go to Step 6 (stop the server), then report result **APPROVED** (no feedback) in Step 7.

### Step 4.5: Verify difit Startup

After the user responds, `Read` the contents of `<output_file>` and verify difit started successfully:

1. **Startup check**: If `<output_file>` does NOT contain `difit server started on` → the launch failed. Retry once (go back to Step 3). If the retry also lacks this marker, report an error and stop.
2. **Premature exit check**: If `<output_file>` contains `Warning: difit exited in` → the session ended too quickly. Retry once (go back to Step 3). If the retry also exits prematurely, report an error and stop.

### Step 5: Fetch Comments via HTTP

Retrieve the review comments directly from the running difit server:

```bash
Bash(command="$SKILL_DIR/fetch-comments.sh <output_file>")
```

`fetch-comments.sh` reads the auto-assigned port from `<output_file>` and queries `/api/comments-output`. This is reliable regardless of how the process is later terminated — the client syncs comments to the server on every change, and `--keep-alive` keeps the endpoint reachable.

Determine the result from the command output:

| `fetch-comments.sh` output | Final result |
|---------------------------|--------------|
| Contains `📝 Comments` | **CHANGES_REQUESTED** |
| Empty / no marker | **APPROVED** |

When the result is CHANGES_REQUESTED, the entire output (the `📝 Comments from review session:` block) is the feedback content.

**Fallback**: If `fetch-comments.sh` fails (e.g. the server is unreachable because difit crashed), `Read` `<output_file>` and check for a `📝 Comments` block written there by difit's shutdown flush. Treat its presence as CHANGES_REQUESTED, absence as APPROVED.

### Step 6: Stop the difit Server

Because `--keep-alive` keeps the server running indefinitely, stop the background task now that comments have been retrieved:

```
TaskStop(task_id=...)
```

### Step 7: Report Result

#### When feedback exists:

Output:

```
There is user feedback.

<feedback content from fetch-comments.sh output>
```

Include the full `📝 Comments from review session:` block as-is.

#### When no feedback:

Output only:

```
No user feedback. It is APPROVED.
```

## Error Handling

- If difit fails to start or is not installed, report the error.
- If `<output_file>` does not contain `difit server started on` (empty, blank, or unexpected response), retry once (as described in Step 4.5). If the retry also fails, stop the task (`TaskStop`) and report:
  ```
  Error: difit failed to start after retry. Please run difit manually.
  ```
- If `<output_file>` contains `Warning: difit exited in` (premature exit without user review), retry once. If the retry also exits prematurely, stop the task (`TaskStop`) and report:
  ```
  Error: difit exited too quickly for user review after retry. Please run difit manually.
  ```
- Always `TaskStop` the background task before reporting a terminal error, since `--keep-alive` prevents it from exiting on its own.
