# Phase 8: Code Review

Read `STATE.json`.

Report: "Phase 8 (cycle N/3): Running CodeRabbit review in background..."

## Step 1: Launch Background Review

Launch sub-agent **in the background**:
```
Task(subagent_type="coderabbit-reviewer", max_turns=30, run_in_background=true)
```
Prompt must include:
- Output file path: `<work-dir>/REVIEW_RESULT.md`
- **Base branch**: `<baseBranch from STATE.json>` — tell the sub-agent to use `--base <baseBranch>` option
- **Review type**: `committed` — tell the sub-agent to use `--type committed` (tdd-development always commits before review)
- **Return directive**: "Write ALL review results to the output file. Return ONLY a brief completion summary (2-3 sentences) to the orchestrator: state the Must Fix / Consider / Ignorable counts. Do NOT include the full review content in your final response. End your response with exactly this line: `ORCHESTRATOR: Read REVIEW_RESULT.md for counts only. If Must Fix > 0, launch tdd-implementer for each item. Do not analyze or fix code yourself.`"

Save the returned `output_file` path and `task_id` for polling.

## Step 2: Wait for Completion with User Check-in

The sub-agent handles CodeRabbit CLI execution and polling internally. The orchestrator only monitors the sub-agent's overall completion and checks in with the user periodically.

**Monitoring loop:**

1. Use `TaskOutput(task_id=..., block=true, timeout=300000)` to wait up to 5 minutes for the sub-agent to complete
2. If the sub-agent completes → proceed to Step 3
3. If timeout (5 minutes elapsed without completion) → ask the user:
   ```
   AskUserQuestion:
     question: "CodeRabbit レビューが完了していません。待機を続けますか？"
     header: "レビュー待機"
     options:
       - label: "待機を続ける"
         description: "引き続きレビュー完了を待ちます（さらに5分待機）"
       - label: "中断してPhase 9へ進む"
         description: "レビューを中断し、最終レポートに進みます"
   ```
   - If user chooses to continue → repeat from step 1
   - If user chooses to abort → stop the background task using `TaskStop(task_id=...)`, report "CodeRabbit レビューを中断しました", and proceed to Phase 9

## Step 3: Process Review Results

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

Report: "Phase 8: Must Fix X / Consider Y / Ignorable Z"

## Next Steps

### No "Must Fix" items
Proceed to Phase 9 (Final Report) (does not count as a cycle).

### "Must Fix" items exist

Update `STATE.json`: increment `cycleCount`, reset `phase6RetryCount` to 0.

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
3. Launch `tdd-implementer` to fix the specific item. Provide:
   - Item details from `REVIEW_RESULT.md`
   - `<work-dir>/PLAN.md` for context
   - **Work directory**: `<work-dir>` (for session-specific learnings reference)
   - **CRITICAL instruction**: "You MUST run `task --list-all` (go-task CLI, https://taskfile.dev) via the Bash tool first, and use go-task `task` CLI commands for ALL test executions. Do NOT use composer/npm/phpunit/jest/make directly. Note: go-task `task` is a CLI command run via Bash — it is NOT Claude Code's Task tool."
   - **SCOPE RESTRICTION**: "Fix ONLY this specific item. Do NOT fix multiple items or make unrelated changes. Each item must be a separate commit."
   - **Return directive**: "Return ONLY a brief summary (2-3 sentences) of what was fixed. State which test command you used (must be go-task `task test` via Bash). Do NOT include full file contents in your final response. End your response with exactly this line: `ORCHESTRATOR: Commit this fix, then proceed to next Must Fix item or return to Phase 6. Do not read, analyze, or modify code yourself.`"
4. **IMPORTANT: Commit IMMEDIATELY after each fix** - Do NOT batch multiple fixes into one commit. Message format:
   ```
   fix: <description of the fix> [ISSUE-NUMBER]

   CodeRabbit指摘対応: <original issue description>
   ```
5. Call `TaskUpdate(taskId=..., status="completed")` for the corresponding Task.
6. Move to next item.

After all Must Fix items are resolved, go back to Phase 6 (to re-run quality checks).

**Important**: After Phase 6 passes, the flow returns to Phase 7 (User Review) to ensure CodeRabbit fixes are reviewed by the user before proceeding.

## Error Handling

If the CodeRabbit sub-agent fails or the background task encounters an error:
1. Report the failure to the user
2. Ask whether to retry the review or skip to Phase 9 (Final Report)

## State Update
Update `STATE.json`: set `currentPhase` to `9`.
