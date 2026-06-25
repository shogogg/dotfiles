---
name: difit
description: Runs difit to launch a browser-based diff review UI and reports the result. Use when the user wants to review diffs with difit, visually review code changes in a browser, or says "difit でレビュー".
model: sonnet
allowed-tools: Bash(run-difit.sh), TaskOutput, TaskStop, AskUserQuestion, Read
context: fork
---

# difit Skill

Launches difit for browser-based diff review and reports the result.

## Arguments

- `$ARGUMENTS`: `<target> <base> [<output_file>]`
  - `<target>`: Review target (HEAD, commit hash, branch name, or `.` for uncommitted changes)
  - `<base>`: Review base (HEAD, commit hash, branch name)
  - `<output_file>` (optional): Path to write difit output. If omitted, defaults to `/tmp/difit_output.txt`.

## Workflow

### Step 1: Parse Arguments

Split `$ARGUMENTS` by whitespace. The **first token** is `<target>`, the **second token** is `<base>`, and the **third token** (optional) is `<output_file>`.

Example: `$ARGUMENTS` = `"HEAD GROO-794_branch /path/to/work/DIFIT_OUTPUT.md"` → `<target>` = `HEAD`, `<base>` = `GROO-794_branch`, `<output_file>` = `/path/to/work/DIFIT_OUTPUT.md`

If `<output_file>` is not provided, default to `/tmp/difit_output.txt`.

**Do NOT modify or convert the arguments** (e.g., do NOT replace `HEAD` with `@`). The shell script handles conversion automatically.

### Step 2: Validate Arguments

1. **Both `<target>` and `<base>` must be present**. If either is missing, output an error and stop:
   ```
   Error: difit requires both <target> and <base> arguments.
   ```
2. **`<target>` and `<base>` must not be identical**. If they are the same, output an error and stop:
   ```
   Error: <target> and <base> are the same. No diff to review.
   ```

### Step 3: Run difit in Background

Execute the following command with `run_in_background: true`. Redirect both stdout and stderr to `<output_file>`:

```bash
Bash(command="$SKILL_DIR/run-difit.sh --clean <target> <base> > <output_file> 2>&1", run_in_background=true)
```

Save the returned `task_id` for polling.

**Important**:
- Always use `run-difit.sh` wrapper (not `npx difit` directly). It provides a pseudo-tty to prevent difit from entering STDIN mode.
- Do NOT pipe diff to stdin. Always pass arguments directly.
- Always include the `--clean` flag.
- All difit output (stdout + stderr) is written to `<output_file>`. `TaskOutput` returns empty — it is used only for process completion signaling.

### Step 4: Ask User for Review Completion

After launching difit in Step 3, immediately present a question to the user (do NOT poll for completion first):

```
AskUserQuestion:
  question: "ブラウザで difit のレビューが完了したら「完了」を選択してください。"
  header: "レビュー完了確認"
  options:
    - label: "完了"
      description: "ブラウザでのレビューが終わりました"
```

Wait for the user to select "完了" before proceeding. Approval status is determined from `<output_file>` content in Step 5, not from user input here.

### Step 4.5: Verify difit Process Completion

After the user responds, verify that the difit process has finished:

1. Call `TaskOutput(task_id=..., block=true, timeout=5000)` to check completion.
2. **If the task has completed** → proceed to Step 5.
3. **If the task is still running** (timeout without completion) → inform the user:
   ```
   AskUserQuestion:
     question: "difit プロセスがまだ実行中です。対応を選択してください。"
     header: "プロセス未終了"
     options:
       - label: "待機する"
         description: "difit の終了を待ちます（5秒間隔でチェック）"
       - label: "中止して続行（承認として扱う）"
         description: "difit を停止し、承認として続行する"
   ```
   - **「待機する」**: Poll with `TaskOutput(task_id=..., block=true, timeout=5000)` in a loop until the task completes.
   - **「中止して続行」**: Stop the background task using `TaskStop(task_id=...)`. Skip Step 5 and go directly to Step 6 with result **APPROVED** (no feedback).

### Step 5: Determine Result

**Note**: This step is skipped if difit was aborted in Step 4.5.

Read the contents of `<output_file>` and verify that difit ran successfully:

1. **Startup check**: If `<output_file>` does NOT contain `difit server started on` → The launch failed. Retry once (go back to Step 3). If the retry also lacks this marker, report an error and stop.
2. **Premature exit check**: If `<output_file>` contains `Warning: difit exited in` → The session ended too quickly for the user to review. Retry once (go back to Step 3). If the retry also exits prematurely, report an error and stop.

Then, determine the final result from `<output_file>` content:

| `<output_file>` content | Final result |
|------------------------|--------------|
| `📝 Comments` present | **CHANGES_REQUESTED** |
| `📝 Comments` absent | **APPROVED** |

When the result is CHANGES_REQUESTED, extract the feedback content following the `📝 Comments from review session:` marker from `<output_file>`.

### Step 6: Report Result

#### When feedback exists:

Output:

```
There is user feedback.

<feedback content from difit output>
```

Include the full feedback section from `<output_file>` as-is.

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
- If `<output_file>` contains `Warning: difit exited in` (premature exit without user review), retry once. If the retry also exits prematurely, report:
  ```
  Error: difit exited too quickly for user review after retry. Please run difit manually.
  ```