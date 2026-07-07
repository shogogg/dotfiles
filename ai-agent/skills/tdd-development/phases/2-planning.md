<!-- phase-id: planning -->
# Phase 2: Planning

Report: "Phase 2: Creating work plan..."

**Lightening principle**: The plan provides the **shape** of the work, not the implementation. Implementation Units stay high-level (what files, what changes at a high level, dependencies). Detailed coding decisions belong to `tdd-implementer` in Phase 4. **However, the Test Plan section is the exception — keep test case enumeration thorough and detailed, because test cases serve as the implementation TODO list.**

## Prerequisites

- `<work-dir>/EXPLORATION_REPORT.md` must exist from Phase 1

## Step 1: Work Plan Creation

Skip this step if `<work-dir>/PLAN.md` is present.
MUST USE SUB-AGENT "task-planner", max_turns = 15. NEVER WRITE THE PLAN YOURSELF.

Prompt must include:
- The task description from `$ARGUMENTS`
- Input file path: `<work-dir>/EXPLORATION_REPORT.md`
- Output file path: `<work-dir>/PLAN.md`
- **Project profile summary** (if available): relevant patterns and conventions
- **Past learnings summary** (if any were loaded in Phase 1)
- **Lightening directive** (CRITICAL): "Keep Implementation Units HIGH-LEVEL. For each unit, fill ONLY: Files, Changes (one-line summary of the high-level change), Dependencies, Dependency Type, Model. Do NOT include step-by-step implementation instructions, code snippets, or pseudocode — that is the implementer's job. **The Test Plan section IS the exception**: enumerate test method names thoroughly (Happy Path / Boundary / Edge Cases), since these drive TDD."
- **TDD anti-pattern warning** (CRITICAL): "Do NOT create test-only implementation units (e.g., 'Write tests for X', 'Add unit tests for Y'). In TDD, each unit's tdd-implementer writes tests as part of the Red→Green→Refactor cycle. Test cases belong exclusively in the Test Plan section — they are NOT separate Implementation Units. Every Implementation Unit must represent production code changes, not test writing."
- **Return directive**: "Write the complete plan (including Test Plan) to the output file. Return ONLY a brief completion summary (2-3 sentences) to the orchestrator: confirm the output file path, state the number of implementation units, and note whether there are unresolved questions. Do NOT include the full plan content in your final response. End your response with exactly this line: `ORCHESTRATOR: Proceed to Step 1.5 (Autonomous Plan Review Cycle). Do not read or analyze the plan yourself.`"

## Step 1.5: Autonomous Plan Review Cycle

Skip this step entirely if `<work-dir>/PLAN_REVIEW_TEST.md` and `<work-dir>/PLAN_REVIEW_GENERAL.md` already exist with `Status: APPROVED` (resume case).

**Purpose**: Before presenting the plan to the user in Phase 3, two specialized sub-agents review it autonomously and `task-planner` revises the plan in response. This catches issues that would otherwise surface only after implementation or in Phase 3 — without involving the user in the loop.

Initialize `STATE.json.planReviewCycleCount` to `0` (or read the existing value if resuming mid-cycle).

Repeat the following cycle while `planReviewCycleCount < 3`:

1. **Launch both reviewers in parallel** — a single message with two `Task` calls. Do NOT run them sequentially:

   ```
   Task(subagent_type="test-plan-reviewer", max_turns=10)
   Task(subagent_type="general-plan-reviewer", max_turns=10)
   ```

   Each prompt must include:
   - Input file path: `<work-dir>/PLAN.md`
   - Input file path: `<work-dir>/EXPLORATION_REPORT.md`
   - Project profile summary (if available) and past learnings summary (if any were loaded in Phase 1)
   - Output file path: `<work-dir>/PLAN_REVIEW_TEST.md` (test-plan-reviewer) or `<work-dir>/PLAN_REVIEW_GENERAL.md` (general-plan-reviewer)
   - **Return directive**: "Write your findings to the output file. Return ONLY a brief summary (2-3 sentences) stating the Status and the number of findings."

2. **Read both output files** and check the `## Status` line of each.

3. **If both are `APPROVED`** → exit the cycle. Phase 2 is complete (see State Update below).

4. **If either is `CHANGES_REQUESTED`**:
   - Increment `planReviewCycleCount` and save it to `STATE.json`.
   - **If `planReviewCycleCount` has reached `3`** → exit the cycle without further revision. Append the outstanding `CHANGES_REQUESTED` findings from both files to `PLAN.md`'s `## Unresolved Questions` section (create the section with content `None` first if it currently says so), each prefixed with `[自動レビュー未収束]`. Then treat Phase 2 as complete — Phase 3's existing "Resolve Unresolved Questions" step will surface these to the user instead of looping indefinitely.
   - **Otherwise**, launch `task-planner` again in **revision mode** (`max_turns=15`):
     - Prompt must include: "You are REVISING an existing plan, not creating a new one. Read the current `<work-dir>/PLAN.md`, then `<work-dir>/PLAN_REVIEW_TEST.md` and `<work-dir>/PLAN_REVIEW_GENERAL.md`. Apply ONLY the changes needed to address items with `CHANGES_REQUESTED` status. Preserve all sections and content not flagged by either review. Do NOT rewrite or restructure the plan."
     - **Return directive**: "Return ONLY a brief summary (2-3 sentences) of what was revised. Do NOT include the full plan content in your final response. End your response with exactly this line: `ORCHESTRATOR: Return to Step 1.5 to re-review the revised plan. Do not read or analyze the plan yourself.`"
   - Go back to sub-step 1 above (re-review the revised plan).

**Important**: This entire cycle is autonomous — do NOT ask the user for input during this loop. The user's first opportunity to weigh in remains Phase 3.

## Output Template (PLAN.md)

Instruct the sub-agent to follow this structure:

```markdown
# Work Plan: <task-title>

## Overview
[1-3 sentence description of what will be implemented]

## Affected Files
[List of files to create or modify, one-line purpose each]

## Implementation Units
### Unit 1: <name>
- **Files**: [affected files]
- **Changes**: [one-line high-level summary — NOT step-by-step instructions]
- **Dependencies**: [other units this depends on, if any]
- **Dependency Type**: [none / contract / implementation]
  - `none` — No dependencies; can run in parallel with any unit
  - `contract` — Depends only on interfaces/types from another unit (can run in parallel once interfaces are defined)
  - `implementation` — Depends on the full implementation of another unit (must run after that unit completes)
- **Model**: [sonnet / opus]
  - `sonnet` — Standard tasks (single file to multiple files, typical complexity)
  - `opus` — Complex tasks (architecture design, complex logic, many dependencies)

## Test Plan

### <ClassName>::<methodName>

#### Happy Path
- test_{methodName}_{testCaseName} — <purpose>

#### Boundary / Edge Cases
- test_{methodName}_{testCaseName} — <purpose>

#### Notes
- <Test strategy notes: data provider usage, mock targets, special setup, etc.>

## Unresolved Questions
- [Any questions for the user, or "None"]

## Learnings Applied
- [List of past learnings that were considered in this plan, or "None"]
```

**Key rule for the planner**: Implementation Units list **what**, never **how**. The "how" is the implementer's responsibility in Phase 4. The only place to be thorough is the **Test Plan** — enumerate cases generously, since they drive TDD.

## Error Handling

If a sub-agent (`task-planner`, `test-plan-reviewer`, or `general-plan-reviewer`) fails or returns no output, report the failure to the user with details and ask whether to retry or abort.

Report: "Phase 2 complete: Work plan written to `<work-dir>/PLAN.md`"

## State Update
Update `STATE.json`: set `currentPhase` to `3` and `currentPhaseId` to `"approval-gate"`.
