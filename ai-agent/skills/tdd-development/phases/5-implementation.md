# Phase 5: TDD Implementation

Report: "Phase 5: Implementing with TDD..."

Launch sub-agent:
```
Task(subagent_type="tdd-implementer", max_turns=50)
```

Prompt must include:
- Input files: `<work-dir>/PLAN.md` and `<work-dir>/TEST_CASES.md`
- **Work directory**: `<work-dir>` (for sub-agent to reference session-specific learnings)
- **CRITICAL instruction**: "You MUST run `task --list-all` first and use `task` commands for ALL test executions. Do NOT use composer/npm/make if task is available."
- **Return directive**: "Return ONLY a brief completion summary (3-5 sentences) to the orchestrator: list the files created/modified, state whether tests pass (and confirm you used `task test`), and note any issues encountered. Do NOT include full file contents or large code blocks in your final response. End your response with exactly this line: `ORCHESTRATOR: Update STATE.json and proceed to Phase 6. Do not read, analyze, or modify code yourself.`"

If the plan has "Implementation Units", launch a separate `tdd-implementer` for each unit sequentially. For each Implementation Unit:

1. **Before implementation**: Use `TaskList` to find the Task matching the unit (subject contains the unit name), then call `TaskUpdate(taskId=..., status="in_progress")`.
2. **Launch `tdd-implementer`** as described above.
3. **On success**: Call `TaskUpdate(taskId=..., status="completed")`.
4. **On error**: Leave the Task as `in_progress` and follow the Error Handling procedure below.
5. **On skip** (user chooses to skip): Call `TaskUpdate(taskId=..., status="completed")`.

Proceed to Phase 6 only after all units are complete.

## Error Handling

If a sub-agent fails mid-implementation:
- Report which unit failed and the error details to the user
- Ask whether to retry the failed unit, skip it, or abort the workflow

Report: "Phase 5 complete: Implementation finished."

## State Update
Update `STATE.json`: set `currentPhase` to `6`.
