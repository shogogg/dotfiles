# Phase 3: Approval Gate

## Step 1: Resolve Unresolved Questions

Read `<work-dir>/PLAN.md` and `<work-dir>/TEST_CASES.md`. Check if either file contains an "Unresolved Questions" section with open questions.

If unresolved questions exist:
1. Use `AskUserQuestion` to relay each question to the user.
2. After receiving answers, launch the appropriate sub-agent to update the document:
   - `task-planner` for `PLAN.md` updates
   - `unit-test-designer` for `TEST_CASES.md` updates
   - **Return directive for sub-agents**: "Apply the requested changes to the file. Return ONLY a brief summary (2-3 sentences) of what was changed. Do NOT include the full file content in your final response."
3. Re-read the updated documents and check for any new unresolved questions. If new questions emerged, repeat from step 1.

If no unresolved questions exist, proceed to Step 2.

## Step 2: Present Summary and Open in IDE

Present a **brief summary** of `PLAN.md` and `TEST_CASES.md` to the user — do NOT present the full file contents. The summary should include:
- From `PLAN.md`: the Overview section, the list of Affected Files, and the number/names of Implementation Units.
- From `TEST_CASES.md`: the number of test cases per unit and their names.
- If this is a re-presentation after modifications, **highlight only what changed** compared to the previous version.

Then open the following files in the IDE using `mcp__jetbrains__open_file_in_editor` so the user can review full details there:
1. `<work-dir>/PLAN.md`
2. `<work-dir>/TEST_CASES.md`
3. All files listed in "Affected Files" section of `PLAN.md` that already exist on disk.

## Step 3: Explicit Approval

Use `AskUserQuestion` to ask the user for explicit approval with two choices:

1. **承認する** — Approve and proceed to Phase 4.
2. **修正を依頼する** — Request changes.

If the user selects "修正を依頼する":
1. Collect the requested changes from the user.
2. Launch the appropriate sub-agent (`task-planner` / `unit-test-designer`) to apply the changes.
   - **Return directive for sub-agents**: "Apply the requested changes to the file. Return ONLY a brief summary (2-3 sentences) of what was changed. Do NOT include the full file content in your final response."
3. Return to Step 2 to present the updated summary again.

**Critical Rule**: Only an explicit selection of "承認する" constitutes approval. Answering questions, providing comments, or giving feedback does NOT count as approval. The workflow MUST NOT proceed to Phase 4 without the explicit approval selection.

## State Update
Update `STATE.json`: set `currentPhase` to `4`.
