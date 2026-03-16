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

### Step 1: Parse Arguments

Split `$ARGUMENTS` by whitespace. The **first token** is `<target>`, the **second token** is `<base>`.

Example: `$ARGUMENTS` = `"HEAD GROO-794_branch"` → `<target>` = `HEAD`, `<base>` = `GROO-794_branch`

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

Execute the following command with `run_in_background: true`. Pass `<target>` and `<base>` as separate arguments:

```bash
Bash(command="$SKILL_DIR/run-difit.sh --clean <target> <base>", run_in_background=true)
```

Save the returned `task_id` for polling.

**Important**:
- Always use `run-difit.sh` wrapper (not `npx difit` directly). It provides a pseudo-tty to prevent difit from entering STDIN mode.
- Do NOT pipe diff to stdin. Always pass arguments directly.
- Always include the `--clean` flag.

### Step 4: Ask User for Review Result

After launching difit in Step 3, immediately present a question to the user (do NOT poll for completion first):

```
AskUserQuestion:
  question: "difit でのレビュー結果を教えてください。"
  header: "レビュー結果"
  options:
    - label: "承認"
      description: "変更内容に問題なし"
    - label: "コメントあり"
      description: "difit 上でコメントを残しました"
```

Store the user's answer as `<userChoice>` (`approved` or `has_comments`).

### Step 4.5: Verify difit Process Completion

After the user responds, verify that the difit process has finished:

1. Call `TaskOutput(task_id=..., block=true, timeout=5000)` to check completion.
2. **If the task has completed** → save the output and proceed to Step 5.
3. **If the task is still running** (timeout without completion) → inform the user:
   ```
   AskUserQuestion:
     question: "difit プロセスがまだ実行中です。対応を選択してください。"
     header: "プロセス未終了"
     options:
       - label: "待機する"
         description: "difit の終了を待ちます（5秒間隔でチェック）"
       - label: "中止して続行"
         description: "difit を停止し、ユーザーの回答に基づいて続行"
   ```
   - **「待機する」**: Poll with `TaskOutput(task_id=..., block=true, timeout=5000)` in a loop until the task completes.
   - **「中止して続行」**: Stop the background task using `TaskStop(task_id=...)`. Skip output parsing (Step 5) and determine result solely from `<userChoice>`:
     - `approved` → APPROVED, proceed to Step 6 with no feedback.
     - `has_comments` → treat as contradiction (see Step 5 contradiction handling below). Ask user to confirm.

### Step 5: Determine Result

**Note**: This step is skipped if difit was aborted in Step 4.5.

First, verify that difit ran successfully:

1. **Startup check**: If the output does NOT contain `difit server started on` → The launch failed. Retry once (go back to Step 3). If the retry also lacks this marker, report an error and stop.
2. **Premature exit check**: If stderr contains `Warning: difit exited in` → The session ended too quickly for the user to review. Retry once (go back to Step 3). If the retry also exits prematurely, report an error and stop.

Then, determine the final result using **both** difit output and `<userChoice>`. **difit output takes priority**:

| difit output | `<userChoice>` | Final result |
|-------------|----------------|--------------|
| `📝 Comments` present | approved | **CHANGES_REQUESTED** (output takes priority) |
| `📝 Comments` present | has_comments | **CHANGES_REQUESTED** |
| No `📝 Comments` | approved | **APPROVED** |
| No `📝 Comments` | has_comments | **Contradiction** (see below) |

**Contradiction handling** (user chose "コメントあり" but difit output has no comments):

```
AskUserQuestion:
  question: "difit の出力にコメントが見つかりません。どうしますか？"
  header: "コメント不検出"
  options:
    - label: "承認として続行"
      description: "コメントなしとして承認扱いにする"
    - label: "difit を再起動"
      description: "再度 difit を起動してレビューし直す"
```

- **「承認として続行」** → APPROVED, proceed to Step 6.
- **「difit を再起動」** → Go back to Step 3.

When the result is CHANGES_REQUESTED, extract the feedback content following the `📝 Comments from review session:` marker from the difit output.

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