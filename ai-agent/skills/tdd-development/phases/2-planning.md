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
- **Return directive**: "Write the complete plan (including Test Plan and Metadata section) to the output file. Return ONLY a brief completion summary (2-3 sentences) to the orchestrator: confirm the output file path, state the number of implementation units, note whether there are unresolved questions, and report the planning method used (codex or self). Do NOT include the full plan content in your final response. End your response with exactly this line: `ORCHESTRATOR: Update STATE.json and proceed to Phase 3. Do not read or analyze the plan yourself.`"

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
- **Model**: [haiku / sonnet / opus]
  - `haiku` — Simple tasks (single file, clear spec, small changes)
  - `sonnet` — Standard tasks (typical complexity, multiple files)
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

## Metadata
- **Planning Method**: codex | self
```

**Key rule for the planner**: Implementation Units list **what**, never **how**. The "how" is the implementer's responsibility in Phase 4. The only place to be thorough is the **Test Plan** — enumerate cases generously, since they drive TDD.

## Error Handling

If the sub-agent fails or returns no output, report the failure to the user with details and ask whether to retry or abort.

Report: "Phase 2 complete: Work plan written to `<work-dir>/PLAN.md`"

## State Update
Update `STATE.json`: set `currentPhase` to `3`.
