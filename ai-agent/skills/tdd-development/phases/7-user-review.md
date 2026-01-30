# Phase 7: User Review

Report: "Phase 7: ユーザーレビューを開始します..."

## Step 1: Launch difit-based Review

Launch the `user-review` skill to provide browser-based diff review:

```
Skill("user-review", args="<work-dir>")
```

This will:
- Calculate merge-base with the main branch
- Launch difit in browser for visual diff review
- Collect user feedback and save to `<work-dir>/USER_FEEDBACK.md`

## Step 2: Present Summary

While waiting for difit review, present a concise summary to the user:
- List of all created/modified files with a brief description of each change.
- Key implementation decisions that were made.
- Any "Consider" items from the CodeRabbit review that were not addressed.
- Cycle count and retry statistics from `STATE.json`.

## Step 3: Process Feedback

Read `<work-dir>/USER_FEEDBACK.md` and check the status.

### Status: APPROVED

Proceed to Phase 8 (Final Report).

### Status: CHANGES_REQUESTED

各フィードバック項目を個別に修正し、それぞれコミットする:

For each feedback item (1 to N):
1. Report: "Addressing feedback item M/N: <title>"
2. Launch `tdd-implementer` to apply the specific change (provide the item details from `USER_FEEDBACK.md` and `PLAN.md`). Include **return directive**: "Return ONLY a brief summary (2-3 sentences) of what was changed. Do NOT include full file contents in your final response."
3. **Commit the fix immediately** with message:
   ```
   fix: <description of the change> [ISSUE-NUMBER]
   
   ユーザーフィードバック対応: <original feedback description>
   ```
4. Move to next item.

After all feedback items are resolved:
1. Reset `phase5RetryCount` to 0 in `STATE.json`.
2. Return to Phase 5.

## Recording Learnings

After processing user feedback, analyze patterns and record learnings:

1. **Serena Memory に記録**:
   ```
   mcp__plugin_serena_serena__read_memory("user-feedback-patterns.md")
   ```
   既存の内容を読み取り、新しいパターンを追加:
   ```
   mcp__plugin_serena_serena__edit_memory("user-feedback-patterns.md", ...)
   ```
   または新規作成:
   ```
   mcp__plugin_serena_serena__write_memory("user-feedback-patterns.md", content)
   ```

2. **記録する内容**:
   - フィードバックの傾向（例: 命名規則、コードスタイル、設計パターン）
   - ユーザー固有の好み
   - 再発防止のためのチェックポイント

**Critical Rule**: Only explicit approval in `USER_FEEDBACK.md` (Status: APPROVED) constitutes approval.

## State Update
Update `STATE.json`: set `currentPhase` to `8`.