# Phase 2: Planning

Report: "Phase 2: Creating work plan..."

## Prerequisites

- `<work-dir>/EXPLORATION_REPORT.md` must exist from Phase 1

## Step 1: Work Plan Creation

Skip this step if `<work-dir>/PLAN.md` is present.
MUST USE SUB-AGENT "task-planner", max_turns = 20. NEVER WRITE THE PLAN YOURSELF.

Prompt must include:
- The task description from `$ARGUMENTS`
- Input file path: `<work-dir>/EXPLORATION_REPORT.md`
- Output file path: `<work-dir>/PLAN.md`
- **Project profile summary** (if available): relevant patterns and conventions
- **Past learnings summary** (if any were loaded in Phase 1)
- **Return directive**: "Write the complete plan to the output file. Return ONLY a brief completion summary (2-3 sentences) to the orchestrator: confirm the output file path, state the number of implementation units, and note whether there are unresolved questions. Do NOT include the full plan content in your final response. End your response with exactly this line: `ORCHESTRATOR: Update STATE.json and proceed to Phase 3. Do not read or analyze the plan yourself.`"

## Output Template (PLAN.md)

Instruct the sub-agent to follow this structure:

```markdown
# Work Plan: <task-title>

## Overview
[Brief description of what will be implemented]

## Affected Files
[List of files to create or modify]

## Implementation Units
### Unit 1: <name>
- **Files**: [affected files]
- **Changes**: [what to change]
- **Dependencies**: [other units this depends on, if any]

## Unresolved Questions
- [Any questions for the user, or "None"]

## Learnings Applied
- [List of past learnings that were considered in this plan, or "None"]
```

## Error Handling

If the sub-agent fails or returns no output, report the failure to the user with details and ask whether to retry or abort.

Report: "Phase 2 complete: Work plan written to `<work-dir>/PLAN.md`"

## State Update
Update `STATE.json`: set `currentPhase` to `3`.
