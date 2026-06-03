# Phase 8: Final Report

Report: "Phase 8: Generating final report..."

## Step 0: Squash Commits

Consolidate all commits created during this session into a single commit.

### 0.1 Read State Information

Read `STATE.json` and retrieve:
- `startCommitHash`: HEAD at session start
- `firstCommitHash`: Hash of the first commit created in this session

If `firstCommitHash` does not exist (no commits were made), skip to Step 1.

### 0.2 Check Commit Count

```bash
COMMIT_COUNT=$(git rev-list --count ${startCommitHash}..HEAD)
```

- If `COMMIT_COUNT <= 1`: No squash needed, skip to Step 1
- If `COMMIT_COUNT >= 2`: Proceed with squash confirmation

### 0.3 Get First Commit Message

```bash
FIRST_COMMIT_MSG=$(git log --format=%B -n 1 ${firstCommitHash})
```

### 0.4 User Confirmation

Use `AskUserQuestion` to confirm squash operation:

**Options** (user-facing, in Japanese):
1. **統合する** — Squash commits using the first commit message
2. **統合しない** — Keep the current commit history

### 0.5 Execute Squash (if user selected "統合する")

```bash
# Soft reset to preserve changes while undoing commits
git reset --soft ${startCommitHash}

# Re-commit with the first commit message
git commit -m "${FIRST_COMMIT_MSG}"
```

### 0.6 Report Result

Report to user:
- Number of commits before squash
- Final commit message used

## Step 1: Comprehensive Knowledge Distillation (Background, Fire-and-Forget)

The comprehensive distillation is normally pre-launched at the end of Phase 7 (in the "No Must Fix items" branch). Phase 8 does NOT wait for it to complete and does NOT embed its output into the final report.

### 1.1 Check Pre-Launched Task

Read `STATE.json.learningDistillTaskId`:

- **If set (pre-launched in Phase 7)**: Skip re-launching. The background task continues running independently.
- **If not set (backward compatibility / Phase 7 was skipped)**: Launch the sub-agent now in background, fire-and-forget. Do NOT save the task_id, do NOT wait.

  ```
  Task(subagent_type="knowledge-distiller", max_turns=15, run_in_background=true,
    prompt="files: <work-dir>/QUALITY_RESULT.md <work-dir>/REVIEW_RESULT.md <work-dir>/USER_FEEDBACK.md\nmemory: x-coding-best-practices\noutput: <work-dir>/LEARNING_SUMMARY.md")
  ```

The sub-agent will (independently of Phase 8):
- Read all available session files (skips any that do not exist)
- Merge with any patterns already added during Phase 5/6/7 distillation cycles
- Write consolidated patterns to Serena Memory `x-coding-best-practices`
- Write `<work-dir>/LEARNING_SUMMARY.md`

**Important**: Phase 8 proceeds immediately without waiting. The distillation output is referenced by file path only — it may not be available yet when the user reads the final report.

## Step 2: Launch Background Final Report Generation

Delegate the full report compilation (statistics gathering, task aggregation, FINAL_REPORT.md writing) to a `general-purpose` sub-agent running in the background. The main agent does NOT wait — it proceeds directly to Step 3 (minimal inline summary) so the user can move on immediately.

### 2.1 Launch Sub-Agent

```
Task(subagent_type="general-purpose", max_turns=10, run_in_background=true,
  prompt="<prompt below>")
```

**Sub-agent prompt** (English):

```
Compile the final TDD development session report.

Working directory: <work-dir>
Output file: <work-dir>/FINAL_REPORT.md

Steps:
1. Read STATE.json for session metadata (task description, startCommitHash, baseBranch, cycleCount, etc.).
2. Read Statistics sections from any of these files that exist:
   - EXPLORATION_REPORT.md (Exploration)
   - PLAN.md (Planning, including Metadata.Planning Method)
   - IMPLEMENTATION_STATS.md (Implementation — may contain multiple entries)
   - QUALITY_RESULT.md (Quality Checks)
   - REVIEW_RESULT.md (Code Review)
   - USER_FEEDBACK.md (if exists — for user review record)
3. Each Statistics section reports Start Time (ISO 8601), End Time (ISO 8601), Duration. Parse these and compute total session duration (earliest start to latest end).
4. Call TaskList and group by subject prefix:
   - "Implement Unit" / "Implement:" → Implementation Units
   - "Fix CR-" → Code Review Fixes
   - "Fix UF-" → User Feedback Fixes
   Count completed vs total for each group.
5. Read git log <startCommitHash>..HEAD to enumerate commits.
6. Write FINAL_REPORT.md using the template below. Use "N/A" for any missing values; never block on missing data.

Template:

# TDD Development Session Report

## Implementation Summary
- **Task**: <task description from STATE.json>
- **Planning Method**: <codex|self from PLAN.md Metadata>
- **Files changed**: <list from git diff --name-only startCommitHash..HEAD>
- **Key changes**: <brief summary from PLAN.md Overview>

## Test Results
- **Status**: PASS / FAIL
- **Details**: <pass/fail counts from last QUALITY_RESULT.md>

## Review Record
- **User Review**: Approved / Approved after N revision(s)
- **Code Review (CodeRabbit)**:
  - **Must Fix**: <count and resolution status>
  - **Consider**: <count and brief notes>
  - **Ignorable**: <count>
- **Cycles used**: <cycleCount>/3

## Work Items (Tasks)
- **Implementation Units**: <completed>/<total>
- **Code Review Fixes**: <completed>/<total>
- **User Feedback Fixes**: <completed>/<total>

## Execution Time Statistics

### Summary
| Phase | Duration | Start Time | End Time |
|-------|----------|------------|----------|
| Exploration | <N>分<N>秒 | HH:MM | HH:MM |
| Planning | <N>分<N>秒 | HH:MM | HH:MM |
| Implementation | <N>分<N>秒 | HH:MM | HH:MM |
| Quality Checks | <N>分<N>秒 | HH:MM | HH:MM |
| Code Review | <N>分<N>秒 | HH:MM | HH:MM |
| **Total Session** | **<N>分<N>秒** | HH:MM | HH:MM |

### Notes
- Times shown are based on Statistics sections in output files
- Implementation time includes all units (serial and parallel)
- Multiple quality check or review rounds are summed
- N/A indicates the phase was skipped or statistics unavailable

## Commits Created
<list from git log --oneline startCommitHash..HEAD>

## Learnings Summary
A detailed learnings summary is being distilled in the background and will be written to:
- <work-dir>/LEARNING_SUMMARY.md

If the file already exists when you read this report, open it directly. Distilled patterns are also persisted to Serena Memory (x-coding-best-practices) for future sessions.

## Next Steps
- [ ] Review the commits in git log
- [ ] Push to remote when ready
- [ ] Create PR if needed
- [ ] After PR review, run Phase 9 (/coding → Resume → Phase 9) to address review comments

Return directive: Write FINAL_REPORT.md to <work-dir>/FINAL_REPORT.md. Return ONLY a brief completion summary (1-2 sentences) — do NOT include the full report content. Do NOT embed LEARNING_SUMMARY.md content (the distillation may not be complete yet — always reference by path).
```

Save the returned `task_id` to `STATE.json` as `finalReportTaskId`. Fire-and-forget — the main agent never awaits this task.

## Step 3: Present Minimal Inline Summary

Without waiting for Step 1 or Step 2 to complete, present a minimal completion summary to the user so they can move on immediately.

### 3.1 Gather Minimal Inline Data

Issue these in parallel via Bash:

```bash
git log --oneline <startCommitHash>..HEAD
```

```bash
git diff --name-only <startCommitHash>..HEAD | wc -l
```

That's all the inline data needed. Do NOT read statistics files, do NOT parse durations — those are handled by the background sub-agent.

### 3.2 Present Summary

```markdown
## 🎉 TDD Development セッション完了

### 概要
- **タスク**: <task description from STATE.json>
- **変更ファイル数**: <count> files
- **コミット数**: <commit count>

### コミット一覧
<git log --oneline output>

### 詳細レポート（バックグラウンド生成中）
完全なレポートは以下のファイルに書き出されます:
- `<work-dir>/FINAL_REPORT.md`

### 学習内容（バックグラウンド蒸留中）
学習結果は以下のファイルに書き出され、Serena Memory (`x-coding-best-practices`) にも保存されます:
- `<work-dir>/LEARNING_SUMMARY.md`

### 次のステップ
1. リモートにプッシュ: `git push`
2. PR作成後、Phase 9 (`/coding` → Resume → Phase 9) でレビューコメントに対応可能

> 詳細レポートと学習サマリーはバックグラウンドで生成中です。完了を待たずに次の作業に移れます。
```

## State Update
Update `STATE.json`:
- Set `currentPhase` to `9`.
- Set `finalReportTaskId` to the `task_id` returned by Step 2.1.
