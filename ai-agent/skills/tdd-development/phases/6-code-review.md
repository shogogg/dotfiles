# Phase 6: Code Review

Read `STATE.json`.

Report: "Phase 6 (cycle N/3): Running CodeRabbit review..."

Launch sub-agent:
```
Task(subagent_type="coderabbit-reviewer", max_turns=20)
```
Prompt must include:
- Output file path: `<work-dir>/REVIEW_RESULT.md`
- **Return directive**: "Write ALL review results to the output file. Return ONLY a brief completion summary (2-3 sentences) to the orchestrator: state the Must Fix / Consider / Ignorable counts. Do NOT include the full review content in your final response."

Read `<work-dir>/REVIEW_RESULT.md` and check the "Must Fix" count.

## Output Template (REVIEW_RESULT.md)

Instruct the sub-agent to follow this structure:

```markdown
# Code Review Result

## Summary
- **Must Fix**: N items
- **Consider**: N items
- **Ignorable**: N items

## Must Fix
### 1. <title>
- **File**: [file path]
- **Issue**: [description]
- **Suggestion**: [how to fix]

## Consider
### 1. <title>
- **File**: [file path]
- **Issue**: [description]

## Ignorable
### 1. <title>
- **File**: [file path]
- **Note**: [description]
```

Report: "Phase 6: Must Fix X / Consider Y / Ignorable Z"

## Next Steps

### No "Must Fix" items
Proceed to Phase 7 (User Review) (does not count as a cycle).

### "Must Fix" items exist

Update `STATE.json`: increment `cycleCount`, reset `phase5RetryCount` to 0.

If `cycleCount > 3`: Report to user and ask for guidance.

**各 Must Fix 項目を個別に修正し、それぞれコミットする:**

For each Must Fix item (1 to N):
1. Report: "Fixing Must Fix item M/N: <title>"
2. Launch `tdd-implementer` to fix the specific item (provide the item details from `REVIEW_RESULT.md` and `PLAN.md`). Include **return directive**: "Return ONLY a brief summary (2-3 sentences) of what was fixed. Do NOT include full file contents in your final response."
3. **Commit the fix immediately** with message:
   ```
   fix: <description of the fix> [ISSUE-NUMBER]

   CodeRabbit指摘対応: <original issue description>
   ```
4. Move to next item.

After all Must Fix items are resolved, go back to Phase 5 (to re-run quality checks).

## Recording Learnings

After completing all Must Fix items, analyze the patterns and record learnings:

1. **Serena Memory に記録**:
   ```
   mcp__plugin_serena_serena__read_memory("coderabbit-learnings.md")
   ```
   既存の内容を読み取り、新しいパターンを追加:
   ```
   mcp__plugin_serena_serena__edit_memory("coderabbit-learnings.md", ...)
   ```
   または新規作成:
   ```
   mcp__plugin_serena_serena__write_memory("coderabbit-learnings.md", content)
   ```

2. **記録する内容**:
   - 指摘されたパターンの種類（例: null チェック漏れ、型安全性など）
   - 再発防止のためのチェックポイント
   - プロジェクト固有の注意点

## Error Handling

If the CodeRabbit sub-agent fails, report the failure to the user and ask whether to retry the review or skip to Phase 7 (User Review).

## State Update
Update `STATE.json`: set `currentPhase` to `7`.