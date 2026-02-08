# Phase 4: Approval Gate

## Step 1: Resolve Unresolved Questions

Read `<work-dir>/PLAN.md`. Check if it contains an "Unresolved Questions" section with open questions.

If unresolved questions exist:
1. Use `AskUserQuestion` to relay each question to the user.
2. After receiving answers, launch the `task-planner` sub-agent to update `PLAN.md`:
   - **Return directive**: "Apply the requested changes to the file. Return ONLY a brief summary (2-3 sentences) of what was changed. Do NOT include the full file content in your final response."
3. Re-read the updated document and check for any new unresolved questions. If new questions emerged, repeat from step 1.

If no unresolved questions exist, proceed to Step 2.

## Step 2: Present Summary and Open in IDE

Present a **brief summary** of `PLAN.md` to the user — do NOT present the full file contents. The summary should include:
- The Overview section, the list of Target Files, and the number/names of Implementation Units.
- The Test Plan section: number of test cases per class/method and their names.
- If this is a re-presentation after modifications, **highlight only what changed** compared to the previous version.

Then open the following files in the IDE using `mcp__jetbrains__open_file_in_editor` so the user can review full details there:
1. `<work-dir>/PLAN.md`
2. All files listed in "Target Files" section of `PLAN.md` that already exist on disk.

## Step 3: Explicit Approval

Use `AskUserQuestion` to ask the user for explicit approval with two choices:

1. **承認する** — Approve and proceed to Phase 5.
2. **修正を依頼する** — Request changes.

If the user selects "修正を依頼する":
1. Collect the requested changes from the user.
2. **Validate feedback** by launching the `feedback-validator` sub-agent:
   - **Input**: User's change requests, `<work-dir>/PLAN.md`, `<work-dir>/EXPLORATION_REPORT.md`, and any source files referenced in the feedback.
   - **Output file**: `<work-dir>/FEEDBACK_VALIDATION.md`
   - **Return directive**: "Write validation results to the output file. Return ONLY a brief summary (2-3 sentences) stating the count of Valid/Concern/Needs Discussion items."
3. Read `<work-dir>/FEEDBACK_VALIDATION.md` and check for "Concern" or "Needs Discussion" items:
   - **All Valid**: Proceed to step 4.
   - **Concern or Needs Discussion exists**: Present the concerns/options to the user via `AskUserQuestion` with choices:
     - 「元のフィードバックで進める」 — Apply the original feedback as-is.
     - 「AIの提案を採用する」 — Use the alternative suggested by the validator.
     - 「フィードバックを修正する」 — Revise the feedback (returns to step 1).
4. Launch the `task-planner` sub-agent to apply the (possibly revised) changes to `PLAN.md`.
   - **Return directive**: "Apply the requested changes to the file. Return ONLY a brief summary (2-3 sentences) of what was changed. Do NOT include the full file content in your final response."
5. Return to Step 2 to present the updated summary again.

**Critical Rule**: Only an explicit selection of "承認する" constitutes approval. Answering questions, providing comments, or giving feedback does NOT count as approval. The workflow MUST NOT proceed to Phase 5 without the explicit approval selection.

## Step 4: Create Tasks from Implementation Units

After "承認する" is selected, create Tasks to track implementation progress.

1. Read `<work-dir>/PLAN.md` and extract all Implementation Units.
2. For each Implementation Unit, call `TaskCreate`:
   - `subject`: `"Implement Unit N: <unit-name>"`
   - `description`: Include the unit's Files, Changes, and Dependencies from PLAN.md
   - `activeForm`: `"Implementing Unit N: <unit-name>"`
3. If there are no Implementation Units (single-plan without units), create a single Task:
   - `subject`: `"Implement: <task-title>"`
   - `description`: Include the plan's Affected Files and key changes
   - `activeForm`: `"Implementing: <task-title>"`
4. Call `TaskList` to confirm all Tasks were created successfully.

## State Update
Update `STATE.json`: set `currentPhase` to `5`.
