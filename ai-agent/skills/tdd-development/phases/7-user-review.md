# Phase 7: User Review

Report: "Phase 7: ユーザーレビューを開始します..."

## Step 1: Read Start Commit Hash from State

Read `STATE.json` from the workspace directory and retrieve the `startCommitHash` field.

```json
{
  "currentPhase": 7,
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
- Timeout handling (background polling with user check-in) is managed within the difit skill.

**Important**: Wait for skill completion. Do NOT run in background.

## Step 3: Determine Review Result

Inspect the difit skill's return value:

- **`"No user feedback. It is APPROVED."`** → Status is **APPROVED**.
- **Starts with `"There is user feedback."`** → Status is **CHANGES_REQUESTED**. The text following this line is the feedback content.

## Step 4: Write USER_FEEDBACK.md (Append Mode)

**CRITICAL: This file uses append mode.** Never overwrite existing content — always append new rounds to preserve the full feedback history for learning and traceability.

This file is consumed by:
- `tdd-implementer` (reads it autonomously for feedback patterns)
- `feedback-validator` (receives it as input)
- Phase 9 learning sub-agent (references it for session learnings)
- `knowledge-distiller` (reads latest round for immediate distillation)

### When APPROVED

If `USER_FEEDBACK.md` does not exist:

```markdown
# User Feedback

## Status
APPROVED
```

If `USER_FEEDBACK.md` already exists (previous rounds of feedback were given):

**Append** the following at the end of the file:

```markdown

## Final Status
APPROVED (after N rounds of feedback)
```

### When CHANGES_REQUESTED

**If `USER_FEEDBACK.md` does not exist**, create it with:

```markdown
# User Feedback

## Status
CHANGES_REQUESTED

## Round 1 Feedback (<timestamp>)
<difit feedback content as-is>
```

**If `USER_FEEDBACK.md` already exists**, use `Read` to find the highest round number, then **append** the new round at the end of the file:

```markdown

## Round N Feedback (<timestamp>)
<difit feedback content as-is>
```

Also update the `## Status` line to `CHANGES_REQUESTED` if it is not already set.

- **Round number**: Find the highest existing round number in the file and increment by 1. If no rounds exist, start at 1.
- **Timestamp**: Use ISO 8601 format (e.g., `2026-02-06T10:30:00Z`).
- **Feedback content**: Paste the difit output as-is. Do NOT attempt structured parsing — LLM sub-agents can interpret raw text.
- **Append method**: Use `Bash` to append (e.g., `cat >> file`) or `Read` + `Write` preserving existing content. NEVER use `Write` alone as it overwrites.

## Step 4.5: Immediate Knowledge Distillation (Background)

When status is **CHANGES_REQUESTED**, launch knowledge distillation **immediately after writing the feedback** (before presenting summary or applying fixes). This ensures the feedback is captured for learning even if subsequent steps modify the file.

```
Task(subagent_type="knowledge-distiller", max_turns=15, run_in_background=true,
  prompt="files: <work-dir>/USER_FEEDBACK.md\nmemory: x-coding-best-practices\nscope: Distill ONLY the latest round (Round N) of user feedback. Previous rounds have already been distilled in earlier cycles.")
```

Save the returned `task_id`. This distillation runs in parallel with all subsequent steps and does NOT need to be awaited.

**Note**: This replaces the distillation that was previously in "Apply Fixes" (Step 6). Do NOT launch distillation again in Step 6.

## Step 5: Present Summary (After Review Completion)

Present a concise summary to the user:

- List of all created/modified files with a brief description of each change.
- Key implementation decisions that were made.
- Cycle count and retry statistics from `STATE.json`.

**Note**: This summary is presented AFTER difit review completes, not during. This ensures the user can focus on the browser-based review first.

## Step 6: Process Feedback

### Status: APPROVED

Proceed to Phase 8 (Code Review).

### Status: CHANGES_REQUESTED

#### Validate Feedback

Before applying fixes, validate the feedback by launching the `feedback-validator` sub-agent:

1. **Launch validator**:
   - **Input**: Feedback items from `USER_FEEDBACK.md`, `<work-dir>/PLAN.md`, and source files referenced in the feedback.
   - **Output file**: `<work-dir>/FEEDBACK_VALIDATION.md`
   - **Return directive**: "Write validation results to the output file. Return ONLY a brief summary (2-3 sentences) stating the count of Valid/Concern/Needs Discussion items."

2. **Read validation results** from `<work-dir>/FEEDBACK_VALIDATION.md`:
   - **All Valid**: Proceed to "Apply Fixes" below.
   - **Concern or Needs Discussion exists**: Present the concerns/options to the user via `AskUserQuestion` with choices:
     - 「元のフィードバックで進める」 — Apply the original feedback as-is.
     - 「AIの提案を採用する」 — Use the alternative suggested by the validator.
     - 「フィードバックを修正する」 — Revise the feedback (return to Step 6 with CHANGES_REQUESTED and updated feedback).

#### Apply Fixes

**Note**: Knowledge distillation was already launched in Step 4.5 (immediately after writing feedback). Do NOT launch it again here.

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
   - **CRITICAL instruction**: "You MUST run `task --list-all` (go-task CLI, https://taskfile.dev) via the Bash tool first, and use go-task `task` CLI commands for ALL test executions. Do NOT use composer/npm/phpunit/jest/make directly. Note: go-task `task` is a CLI command run via Bash — it is NOT Claude Code's Task tool."
   - **SCOPE RESTRICTION**: "Fix ONLY this specific feedback item. Do NOT address multiple items or make unrelated changes. Each item must be a separate commit."
   - **Return directive**: "Return ONLY a brief summary (2-3 sentences) of what was changed. State which test command you used (must be go-task `task test` via Bash). Do NOT include full file contents in your final response."
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
Update `STATE.json`: set `currentPhase` to `8`.
