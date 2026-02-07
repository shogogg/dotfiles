# Phase 8: User Review

Report: "Phase 8: ユーザーレビューを開始します..."

## Step 1: Read Start Commit Hash from State

Read `STATE.json` from the workspace directory and retrieve the `startCommitHash` field.

```json
{
  "currentPhase": 8,
  "startCommitHash": "abc1234",  // ← Use this value
  "featureBranch": "feature/my-feature"
}
```

`startCommitHash` is the HEAD at the beginning of the session. Using this ensures only commits made during this session are included in the diff.

## Step 2: Launch difit Review

Launch the `difit` skill to open a browser-based diff review:

```
Skill("difit", args="HEAD <startCommitHash>")
```

- `HEAD` and `<startCommitHash>` are passed as-is. The difit skill handles `HEAD` → `@` conversion internally.
- Timeout (10 minutes) is managed within the difit skill.

**Important**: Wait for skill completion. Do NOT run in background.

## Step 3: Handle Timeout

If the difit skill reports a timeout, present retry options via `AskUserQuestion`:

- 「レビューを継続する」 — Re-run difit (go back to Step 2).
- 「レビュー完了として続行」 — Treat as APPROVED and proceed to Step 5.

## Step 4: Determine Review Result

Inspect the difit skill's return value:

- **`"No user feedback. It is APPROVED."`** → Status is **APPROVED**.
- **Starts with `"There is user feedback."`** → Status is **CHANGES_REQUESTED**. The text following this line is the feedback content.

## Step 5: Write USER_FEEDBACK.md

Write `<work-dir>/USER_FEEDBACK.md` based on the review result. This file is consumed by:
- `tdd-implementer` (reads it autonomously for feedback patterns)
- `feedback-validator` (receives it as input)
- Phase 9 learning sub-agent (references it for session learnings)

### When APPROVED

```markdown
# User Feedback

## Status
APPROVED
```

### When CHANGES_REQUESTED

```markdown
# User Feedback

## Status
CHANGES_REQUESTED

## Round N Feedback (<timestamp>)
<difit feedback content as-is>
```

- **Round number**: If `USER_FEEDBACK.md` already exists, find the highest round number and increment by 1. Otherwise, start at 1.
- **Timestamp**: Use ISO 8601 format (e.g., `2026-02-06T10:30:00Z`).
- **Feedback content**: Paste the difit output as-is. Do NOT attempt structured parsing — LLM sub-agents can interpret raw text.

## Step 6: Present Summary (After Review Completion)

Present a concise summary to the user:

- List of all created/modified files with a brief description of each change.
- Key implementation decisions that were made.
- Any "Consider" items from the CodeRabbit review that were not addressed.
- Cycle count and retry statistics from `STATE.json`.

**Note**: This summary is presented AFTER difit review completes, not during. This ensures the user can focus on the browser-based review first.

## Step 7: Process Feedback

### Status: APPROVED

Proceed to Phase 9 (Final Report).

### Status: CHANGES_REQUESTED

#### Validate Feedback

Before applying fixes, validate the feedback by launching the `feedback-validator` sub-agent:

1. **Launch validator**:
   - **Input**: Feedback items from `USER_FEEDBACK.md`, `<work-dir>/PLAN.md`, `<work-dir>/REVIEW_RESULT.md` (if exists), and source files referenced in the feedback.
   - **Output file**: `<work-dir>/FEEDBACK_VALIDATION.md`
   - **Return directive**: "Write validation results to the output file. Return ONLY a brief summary (2-3 sentences) stating the count of Valid/Concern/Needs Discussion items."

2. **Read validation results** from `<work-dir>/FEEDBACK_VALIDATION.md`:
   - **All Valid**: Proceed to "Apply Fixes" below.
   - **Concern or Needs Discussion exists**: Present the concerns/options to the user via `AskUserQuestion` with choices:
     - 「元のフィードバックで進める」 — Apply the original feedback as-is.
     - 「AIの提案を採用する」 — Use the alternative suggested by the validator.
     - 「フィードバックを修正する」 — Revise the feedback (return to Step 7 with CHANGES_REQUESTED and updated feedback).

#### Apply Fixes

**Launch knowledge distillation in background (parallel with fixes):**

```
Task(subagent_type="knowledge-distiller", max_turns=15, run_in_background=true,
  prompt="files: <work-dir>/USER_FEEDBACK.md\nmemory: x-coding-best-practices")
```

This runs in parallel with the fix loop below. Distilled patterns will be available to subsequent fix items via Serena Memory.

**Create Tasks for feedback items:**

Before starting the fix loop, create a Task for each feedback item:
- For each feedback item (1 to N), call `TaskCreate`:
  - `subject`: `"Fix UF-<round>-<M>: <title>"` (where `<round>` is the current feedback round number and `<M>` is the item number)
  - `description`: Include the feedback content from USER_FEEDBACK.md
  - `activeForm`: `"Fixing UF-<round>-<M>: <title>"`

**Fix each feedback item individually and commit each one:**

For each feedback item (1 to N):
1. Call `TaskUpdate(taskId=..., status="in_progress")` for the corresponding Task.
2. Report: "Addressing feedback item M/N: <title>"
3. Launch `tdd-implementer` to apply the specific change. Provide:
   - Item details from `USER_FEEDBACK.md`
   - `<work-dir>/PLAN.md` for context
   - **Work directory**: `<work-dir>` (for session-specific learnings reference)
   - **CRITICAL instruction**: "You MUST run `task --list-all` first and use `task` commands for ALL test executions. Do NOT use composer/npm/make if task is available."
   - **SCOPE RESTRICTION**: "Fix ONLY this specific feedback item. Do NOT address multiple items or make unrelated changes. Each item must be a separate commit."
   - **Return directive**: "Return ONLY a brief summary (2-3 sentences) of what was changed. State which test command you used (must be `task test` if available). Do NOT include full file contents in your final response."
4. **IMPORTANT: Commit IMMEDIATELY after each fix** - Do NOT batch multiple fixes into one commit. Message format:
   ```
   fix: <description of the change> [ISSUE-NUMBER]

   ユーザーフィードバック対応: <original feedback description>
   ```
5. Call `TaskUpdate(taskId=..., status="completed")` for the corresponding Task.
6. Move to next item.

After all feedback items are resolved:
1. Reset `phase6RetryCount` to 0 in `STATE.json`.
2. Return to Phase 6.

**Critical Rule**: Only explicit approval in `USER_FEEDBACK.md` (Status: APPROVED) constitutes approval.

## State Update
Update `STATE.json`: set `currentPhase` to `9`.
