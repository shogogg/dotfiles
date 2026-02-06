# Phase 8: User Review

Report: "Phase 8: ユーザーレビューを開始します..."

## Step 1: Read Base Branch from State

Read `STATE.json` from the workspace directory and retrieve the `baseBranch` field.

```json
{
  "currentPhase": 8,
  "baseBranch": "origin/main",  // ← Use this value
  "featureBranch": "feature/my-feature"
}
```

**Fallback**: If `baseBranch` is not present in `STATE.json` (legacy workspace), the `user-review` skill will perform automatic detection.

## Step 2: Launch difit-based Review

Launch the `user-review` skill with the base branch information:

```
Skill("user-review", args="<work-dir> --base-branch=<baseBranch>")
```

**Important**: 
- Wait for skill completion. Do NOT run in background.
- The skill will launch difit in the browser and wait for user interaction.
- Timeout is handled within the skill (10 minutes with retry option).

## Step 3: Present Summary (After Review Completion)

After the `user-review` skill completes, present a concise summary to the user:

- List of all created/modified files with a brief description of each change.
- Key implementation decisions that were made.
- Any "Consider" items from the CodeRabbit review that were not addressed.
- Cycle count and retry statistics from `STATE.json`.

**Note**: This summary is presented AFTER difit review completes, not during. This ensures the user can focus on the browser-based review first.

## Step 4: Process Feedback

Read `<work-dir>/USER_FEEDBACK.md` and check the status.

### Status: APPROVED

Proceed to Phase 9 (Final Report).

### Status: CHANGES_REQUESTED

#### Record Feedback Round

Record feedback in USER_FEEDBACK.md with round number:

```markdown
## Round N Feedback (2026-02-04T10:30:00Z)

### Item 1: <title>
- **Issue**: <description>
- **Category**: naming / style / logic / design

### Item 2: ...
```

**Note**: tdd-implementer autonomously reads `<work-dir>/USER_FEEDBACK.md` and references past feedback patterns.

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
     - 「フィードバックを修正する」 — Revise the feedback (return to Step 4 with CHANGES_REQUESTED and updated feedback).

#### Apply Fixes

**Fix each feedback item individually and commit each one:**

For each feedback item (1 to N):
1. Report: "Addressing feedback item M/N: <title>"
2. Launch `tdd-implementer` to apply the specific change. Provide:
   - Item details from `USER_FEEDBACK.md`
   - `<work-dir>/PLAN.md` for context
   - **Work directory**: `<work-dir>` (for session-specific learnings reference)
   - **CRITICAL instruction**: "You MUST run `task --list-all` first and use `task` commands for ALL test executions. Do NOT use composer/npm/make if task is available."
   - **SCOPE RESTRICTION**: "Fix ONLY this specific feedback item. Do NOT address multiple items or make unrelated changes. Each item must be a separate commit."
   - **Return directive**: "Return ONLY a brief summary (2-3 sentences) of what was changed. State which test command you used (must be `task test` if available). Do NOT include full file contents in your final response."
3. **IMPORTANT: Commit IMMEDIATELY after each fix** - Do NOT batch multiple fixes into one commit. Message format:
   ```
   fix: <description of the change> [ISSUE-NUMBER]
   
   ユーザーフィードバック対応: <original feedback description>
   ```
4. Move to next item.

After all feedback items are resolved:
1. Reset `phase6RetryCount` to 0 in `STATE.json`.
2. Return to Phase 6.

**Critical Rule**: Only explicit approval in `USER_FEEDBACK.md` (Status: APPROVED) constitutes approval.

## State Update
Update `STATE.json`: set `currentPhase` to `9`.
