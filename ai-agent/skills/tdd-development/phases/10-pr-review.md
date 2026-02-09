# Phase 10: PR Review Comments

Report: "Phase 10: PR レビューコメントへの対応を開始します..."

## Step 1: Obtain Review Comments

Ask the user how to provide review feedback:

```
AskUserQuestion:
  question: "PR レビューコメントの取得方法を選択してください。"
  header: "取得方法"
  options:
    - label: "PR から自動取得"
      description: "fetch-pr-review-comments スキルを使って未解決のレビューコメントを取得します"
    - label: "手動で入力する"
      description: "レビューコメントの内容を直接入力します"
```

### Option A: Automatic Fetch from PR

Launch the `fetch-pr-review-comments` skill:

```
Skill("fetch-pr-review-comments")
```

If no unresolved comments are found, report to the user and proceed to completion (Step 5).

If comments are found, proceed to Step 2 with the fetched comments.

### Option B: Manual Input

Ask the user to provide the review comments:

```
AskUserQuestion:
  question: "レビューコメントの内容を入力してください。"
  header: "コメント入力"
  options:
    - label: "入力完了"
      description: "入力が完了したらこちらを選択してください"
```

The user will provide the feedback as their custom input via the "Other" option. Proceed to Step 2 with the user-provided comments.

## Step 2: Write PR_REVIEW_FEEDBACK.md (Append Mode)

**CRITICAL: This file uses append mode.** Never overwrite existing content — always append new rounds to preserve the full feedback history.

### First Round (file does not exist)

Create `<work-dir>/PR_REVIEW_FEEDBACK.md`:

```markdown
# PR Review Feedback

## Status
CHANGES_REQUESTED

## Round 1 Feedback (<timestamp>)
<review comments content>
```

### Subsequent Rounds (file already exists)

Read the file to find the highest round number, then **append** at the end:

```markdown

## Round N Feedback (<timestamp>)
<review comments content>
```

- **Timestamp**: Use ISO 8601 format (e.g., `2026-02-06T10:30:00Z`).
- **Append method**: Use `Bash` to append (e.g., `cat >> file`) or `Read` + `Write` preserving existing content. NEVER use `Write` alone as it overwrites.

## Step 2.5: Immediate Knowledge Distillation (Background)

Launch knowledge distillation immediately after writing the feedback:

```
Task(subagent_type="knowledge-distiller", max_turns=15, run_in_background=true,
  prompt="files: <work-dir>/PR_REVIEW_FEEDBACK.md\nmemory: x-coding-best-practices\nscope: Distill ONLY the latest round (Round N) of PR review feedback. Previous rounds have already been distilled in earlier cycles.")
```

Save the returned `task_id`. This runs in parallel with subsequent steps and does NOT need to be awaited.

## Step 3: Present Comments to User

Present the review comments to the user in a clear format:
- List each comment with file path, line number, reviewer, and content.
- Do NOT use table format — use structured markdown with headers per comment.

Ask the user which comments to address:

```
AskUserQuestion:
  question: "どのコメントに対応しますか？"
  header: "対応選択"
  options:
    - label: "すべて対応する"
      description: "全てのレビューコメントに対応します"
    - label: "選択して対応する"
      description: "対応するコメントを選択します（番号で指定）"
    - label: "対応しない"
      description: "レビューコメントへの対応をスキップします"
```

- **すべて対応する**: Proceed to Step 4 with all comments.
- **選択して対応する**: Ask the user which comment numbers to address, then proceed to Step 4 with selected comments.
- **対応しない**: Proceed to Step 5 (completion).

## Step 4: Apply Fixes

### Validate Feedback

Before applying fixes, validate the feedback by launching the `feedback-validator` sub-agent:

1. **Launch validator**:
   - **Input**: Review comments, `<work-dir>/PLAN.md`, and source files referenced in the comments.
   - **Output file**: `<work-dir>/FEEDBACK_VALIDATION.md`
   - **Return directive**: "Write validation results to the output file. Return ONLY a brief summary (2-3 sentences) stating the count of Valid/Concern/Needs Discussion items."

2. **Read validation results** from `<work-dir>/FEEDBACK_VALIDATION.md`:
   - **All Valid**: Proceed to "Fix Loop" below.
   - **Concern or Needs Discussion exists**: Present the concerns/options to the user via `AskUserQuestion` with choices:
     - 「元のフィードバックで進める」 — Apply the original feedback as-is.
     - 「AIの提案を採用する」 — Use the alternative suggested by the validator.
     - 「フィードバックを修正する」 — Revise the feedback (return to Step 3).

### Fix Loop

**Create Tasks for each feedback item:**

For each feedback item (1 to N), call `TaskCreate`:
- `subject`: `"Fix PR-<round>-<M>: <title>"` (where `<round>` is the current feedback round and `<M>` is the item number)
- `description`: Include the review comment content, file path, and line number
- `activeForm`: `"Fixing PR-<round>-<M>: <title>"`

**Fix each item individually and commit each one:**

For each feedback item (1 to N):
1. Call `TaskUpdate(taskId=..., status="in_progress")` for the corresponding Task.
2. Report: "Addressing PR review item M/N: <title>"
3. Launch `tdd-implementer` to apply the specific change. Provide:
   - Item details from `PR_REVIEW_FEEDBACK.md`
   - `<work-dir>/PLAN.md` for context
   - **Work directory**: `<work-dir>` (for session-specific learnings reference)
   - **CRITICAL instruction**: "You MUST run `task --list-all` (go-task CLI, https://taskfile.dev) via the Bash tool first, and use go-task `task` CLI commands for ALL test executions. Do NOT use composer/npm/phpunit/jest/make directly. Note: go-task `task` is a CLI command run via Bash — it is NOT Claude Code's Task tool."
   - **SCOPE RESTRICTION**: "Fix ONLY this specific feedback item. Do NOT address multiple items or make unrelated changes. Each item must be a separate commit."
   - **Return directive**: "Return ONLY a brief summary (2-3 sentences) of what was changed. State which test command you used (must be go-task `task test` via Bash). Do NOT include full file contents in your final response."
4. **IMPORTANT: Commit IMMEDIATELY after each fix** - Do NOT batch multiple fixes into one commit. Message format:
   ```
   fix: <description of the change> [ISSUE-NUMBER]

   PRレビューコメント対応: <original review comment summary>
   ```
5. Call `TaskUpdate(taskId=..., status="completed")` for the corresponding Task.
6. Move to next item.

After all feedback items are resolved:
1. Reset `phase6RetryCount` to 0 in `STATE.json`.
2. Push changes to remote: `git push`
3. Return to Phase 6 (Quality Checks → User Review → Code Review → Phase 10).

## Step 5: Completion

If no comments to address or all comments resolved:

Report to the user:

```markdown
## PR レビューコメント対応完了

- **対応したコメント数**: N
- **ラウンド数**: M
- **ステータス**: 完了
```

Update `PR_REVIEW_FEEDBACK.md` — append:

```markdown

## Final Status
COMPLETED (after N rounds of feedback)
```

Update `STATE.json`: set `currentPhase` to `11`.

## State Update

When transitioning phases during the fix loop:
- Return to Phase 6: set `currentPhase` to `6`
- On completion: set `currentPhase` to `11`

## Loop Control

- Phase 10 → Phase 6 return: Reset `phase6RetryCount` to 0
- Phase 10 does NOT count against `cycleCount`
- There is no explicit limit on Phase 10 rounds (each round requires user initiation)
