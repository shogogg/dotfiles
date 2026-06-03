# Phase 7: Code Review

Read `STATE.json` to retrieve `startCommitHash`, `baseBranch`, `lastReviewCommit`, and `cycleCount`.

Report: "Phase 7 (cycle N/3): CodeRabbit レビューを準備しています..."

## Step 1: Show Commit History and Ask User for Diff Base

Display the recent commit history for context:

```bash
git log --oneline <startCommitHash>..HEAD
```

Use `AskUserQuestion` to let the user choose the diff base:

```
AskUserQuestion:
  question: "CodeRabbit レビューの差分起点を選択してください。"
  header: "差分起点"
  options:
    - label: "セッション開始時点から (推奨)"
      description: "startCommitHash (<first 7 chars>) 以降の全変更を対象"
    - label: "ベースブランチから"
      description: "<baseBranch> からの全変更を対象"
    - label: "前回レビュー時点から"                          # ← Only include this option if lastReviewCommit is not null
      description: "lastReviewCommit (<first 7 chars>) 以降の変更のみ対象"
```

**Notes:**
- The "前回レビュー時点から" option is **only shown when `lastReviewCommit` is not null** (i.e., a previous review cycle has occurred).
- If the user selects "Other", treat their input as a commit hash or ref to use as the diff base.
- Store the selected base as `<selectedBase>` for the next step.

Report: "Phase 7 (cycle N/3): Running CodeRabbit review in background..."

## Step 2: Launch Background Review

Launch sub-agent **in the background**:
```
Task(subagent_type="coderabbit-reviewer", max_turns=30, run_in_background=true)
```
Prompt must include:
- Output file path: `<work-dir>/REVIEW_RESULT.md`
- **Base**: `<selectedBase>` — tell the sub-agent to use `--base <selectedBase>` option
- **Review type**: `committed` — tell the sub-agent to use `--type committed` (tdd-development always commits before review)
- **Return directive**: "Write ALL review results to the output file. Return ONLY a brief completion summary (2-3 sentences) to the orchestrator: state the Must Fix / Consider / Ignorable counts. Do NOT include the full review content in your final response. End your response with exactly this line: `ORCHESTRATOR: Read REVIEW_RESULT.md for counts only. If Must Fix > 0, launch tdd-implementer for each item. Do not analyze or fix code yourself.`"

Save the returned `output_file` path and `task_id` for polling.

## Step 3: Wait for Completion with User Check-in

The sub-agent handles CodeRabbit CLI execution and polling internally. The orchestrator only monitors the sub-agent's overall completion and checks in with the user periodically.

**Monitoring loop:**

1. Use `TaskOutput(task_id=..., block=true, timeout=300000)` to wait up to 5 minutes for the sub-agent to complete
2. If the sub-agent completes → proceed to Step 4
3. If timeout (5 minutes elapsed without completion) → ask the user:
   ```
   AskUserQuestion:
     question: "CodeRabbit レビューが完了していません。待機を続けますか？"
     header: "レビュー待機"
     options:
       - label: "待機を続ける"
         description: "引き続きレビュー完了を待ちます（さらに5分待機）"
       - label: "中断してPhase 8へ進む"
         description: "レビューを中断し、最終レポートに進みます"
   ```
   - If user chooses to continue → repeat from step 1
   - If user chooses to abort → stop the background task using `TaskStop(task_id=...)`, report "CodeRabbit レビューを中断しました", and proceed to Phase 8

## Step 4: Process Review Results

Read `<work-dir>/REVIEW_RESULT.md` and check the "Must Fix" count.

## Output Template (REVIEW_RESULT.md)

Instruct the sub-agent to follow this structure:

```markdown
# Code Review Result

## Cycle Info
- **Cycle**: N/3
- **Previous cycles**: [list of previous Must Fix patterns if any]

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

Report: "Phase 7: Must Fix X / Consider Y / Ignorable Z"

## Next Steps

### No "Must Fix" items

**Pre-launch comprehensive knowledge distillation in background:**

Before transitioning to Phase 8, kick off the comprehensive distillation so that Phase 8 does not need to wait for it to complete.

```
Task(subagent_type="knowledge-distiller", max_turns=15, run_in_background=true,
  prompt="files: <work-dir>/QC_SUMMARY.md <work-dir>/QC_TEST.raw <work-dir>/QC_LINT.raw <work-dir>/QC_ANALYSE.raw <work-dir>/QC_FORMAT.raw <work-dir>/REVIEW_RESULT.md <work-dir>/USER_FEEDBACK.md\nmemory: x-coding-best-practices\noutput: <work-dir>/LEARNING_SUMMARY.md")
```

Save the returned `task_id` to `STATE.json` as `learningDistillTaskId`. Phase 8 will read this field and skip re-launching the distiller. Do NOT wait for the task to complete — it runs fire-and-forget.

Then proceed to Phase 8 (Final Report) (does not count as a cycle).

### "Must Fix" items exist

Update `STATE.json`: increment `cycleCount`, reset `phase5RetryCount` to 0.

If `cycleCount > 3`: Report to user and ask for guidance.

**Launch knowledge distillation in background (parallel with fixes):**

```
Task(subagent_type="knowledge-distiller", max_turns=15, run_in_background=true,
  prompt="files: <work-dir>/REVIEW_RESULT.md\nmemory: x-coding-best-practices")
```

This runs in parallel with the fix loop below. Distilled patterns will be available to subsequent fix items via Serena Memory.

**Create Tasks for Must Fix items:**

Before starting the fix loop, create a Task for each Must Fix item:
- For each Must Fix item (1 to N), call `TaskCreate`:
  - `subject`: `"Fix CR-<cycle>-<M>: <title>"` (where `<cycle>` is the current cycleCount and `<M>` is the item number)
  - `description`: Include the file path, issue description, and suggested fix from REVIEW_RESULT.md
  - `activeForm`: `"Fixing CR-<cycle>-<M>: <title>"`

**Fix each Must Fix item individually and commit each one:**

For each Must Fix item (1 to N):
1. Call `TaskUpdate(taskId=..., status="in_progress")` for the corresponding Task.
2. Report: "Fixing Must Fix item M/N: <title>"
3. **Determine difficulty level and select model**:
   
   Analyze the Must Fix item content and classify complexity:
   
   - **haiku**: Simple changes requiring minimal logic adjustment
     - Typo fixes, comment additions/modifications
     - Code formatting, variable/method renaming
     - Constant value changes
     - Simple conditional logic fixes (1-2 lines)
     - **Method/function reordering**
   
   - **sonnet** (default): Moderate changes requiring logic understanding
     - Adding new methods/functions
     - Modifying existing logic (5-20 lines)
     - Changes spanning multiple files
     - Adding test cases
   
   - **opus**: Complex changes requiring architectural understanding
     - Architectural changes
     - Large-scale refactoring (20+ lines or 3+ files)
     - Complex algorithm implementation
     - Performance optimization
   
   Set `<selectedModel>` to the determined value (haiku/sonnet/opus). When in doubt, default to sonnet.

4. Launch `tdd-implementer` with the selected model:
   
   ```
   Task(subagent_type="tdd-implementer", max_turns=50, model="<selectedModel>")
   ```
   
   Provide:
   - Item details from `REVIEW_RESULT.md`
   - `<work-dir>/PLAN.md` for context
   - **Work directory**: `<work-dir>` (for session-specific learnings reference)
   - **CRITICAL instruction**: "You MUST run `task --list-all` (go-task CLI, https://taskfile.dev) via the Bash tool first, and use go-task `task` CLI commands for ALL test executions. Do NOT use composer/npm/phpunit/jest/make directly. Note: go-task `task` is a CLI command run via Bash — it is NOT Claude Code's Task tool."
   - **SCOPE RESTRICTION**: "Fix ONLY this specific item. Do NOT fix multiple items or make unrelated changes. Each item must be a separate commit."
   - **Return directive**: "Return ONLY a brief summary (2-3 sentences) of what was fixed. State which test command you used (must be go-task `task test` via Bash). Do NOT include full file contents in your final response. End your response with exactly this line: `ORCHESTRATOR: Commit this fix, then proceed to next Must Fix item or return to Phase 5. Do not read, analyze, or modify code yourself.`"

5. **IMPORTANT: Commit IMMEDIATELY after each fix** - Do NOT batch multiple fixes into one commit. Message format:
   ```
   fix: <description of the fix> [ISSUE-NUMBER]

   CodeRabbit指摘対応: <original issue description>
   ```
6. Call `TaskUpdate(taskId=..., status="completed")` for the corresponding Task.
7. Move to next item.

After all Must Fix items are resolved, go back to Phase 5 (to re-run quality checks).

**Important**: After Phase 5 passes, the flow returns to Phase 6 (User Review) to ensure CodeRabbit fixes are reviewed by the user before proceeding.

## Error Handling

If the CodeRabbit sub-agent fails or the background task encounters an error:
1. Report the failure to the user
2. Ask whether to retry the review or skip to Phase 8 (Final Report)

## State Update
Update `STATE.json`:
- Set `currentPhase` to `8`.
- Set `lastReviewCommit` to the current HEAD commit hash (`git rev-parse HEAD`). This records the state at review time for use as a "since last review" option in future review cycles.
- Set `learningDistillTaskId` to the `task_id` returned by the comprehensive distillation launch (only when proceeding via the "No Must Fix items" branch).
