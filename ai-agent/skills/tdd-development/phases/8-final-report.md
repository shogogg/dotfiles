# Phase 8: Final Report

Report: "Phase 8: Generating final report..."

## Step 1: Backup Learnings to .ai-workspace

セッション全体の学習を `.ai-workspace/learnings/` にバックアップする。

### 1.1 ディレクトリ確認

```bash
mkdir -p .ai-workspace/learnings
```

### 1.2 Serena Memory から学習内容を取得

```
mcp__plugin_serena_serena__list_memories()
```

以下の Memory が存在する場合は読み込んでバックアップ:
- `coderabbit-learnings.md` → `.ai-workspace/learnings/code-review-insights.md`
- `user-feedback-patterns.md` → `.ai-workspace/learnings/best-practices.md`
- `quality-check-learnings.md` → `.ai-workspace/learnings/common-mistakes.md`

### 1.3 セッション固有の学習を追記

今回のセッションで得られた知見を各ファイルに追記:

**code-review-insights.md** に追記:
- CodeRabbit の Must Fix 項目のパターン
- 解決策の傾向

**best-practices.md** に追記:
- ユーザーが承認したアプローチ
- フィードバックから得られたベストプラクティス

**common-mistakes.md** に追記:
- Quality Checks で発生した失敗パターン
- 修正方法

## Step 2: Compile Final Report

Compile and present to the user:

```markdown
## Implementation Summary
- **Task**: [original task description]
- **Files changed**: [list of created/modified files]
- **Key changes**: [brief summary of what was implemented]

## Test Results
- **Status**: PASS / FAIL
- **Details**: [pass/fail counts from last quality check]

## Review Record
- **Must Fix**: [count and resolution status]
- **Consider**: [count and brief notes]
- **Ignorable**: [count]
- **User Review**: Approved / Approved after N revision(s)
- **Cycles used**: N/3

## Commits Created
[List of commits created during this session with their messages]

## Learnings Recorded
- **CodeRabbit patterns**: [count of new patterns recorded]
- **User feedback patterns**: [count of new patterns recorded]
- **Quality check insights**: [count of new insights recorded]
- **Backup location**: `.ai-workspace/learnings/`

## Next Steps
- [ ] Review the commits in git log
- [ ] Push to remote when ready
- [ ] Create PR if needed
```

## State Update
Update `STATE.json`: set `currentPhase` to `9`.