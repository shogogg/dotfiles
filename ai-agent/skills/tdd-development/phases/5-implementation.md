# Phase 5: TDD Implementation

Report: "Phase 5: Implementing with TDD..."

Launch sub-agent:
```
Task(subagent_type="tdd-implementer", max_turns=50)
```

Prompt must include:
- Input files: `<work-dir>/PLAN.md` and `<work-dir>/TEST_CASES.md`
- **Return directive**: "Return ONLY a brief completion summary (3-5 sentences) to the orchestrator: list the files created/modified, state whether tests pass, and note any issues encountered. Do NOT include full file contents or large code blocks in your final response."

If the plan has "Implementation Units", launch a separate `tdd-implementer` for each unit sequentially. Proceed to Phase 6 only after all units are complete.

## Error Handling

If a sub-agent fails mid-implementation:
- Report which unit failed and the error details to the user
- Ask whether to retry the failed unit, skip it, or abort the workflow

Report: "Phase 5 complete: Implementation finished."

## State Update
Update `STATE.json`: set `currentPhase` to `6`.
