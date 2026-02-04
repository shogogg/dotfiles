# Phase 3: Test Design (depends on Phase 2)
Skip this phase if `<work-dir>/TEST_CASES.md` is present.
MUST USE SUB-AGENT "unit-test-designer", max_turns = 30. NEVER WRITE TEST CASES YOURSELF.

Prompt must include:
- Instruction to read the work plan at `<work-dir>/PLAN.md`
- Output file path: `<work-dir>/TEST_CASES.md`
- Instruction: "Write test cases to the output file only. Do not request user review."
- **Return directive**: "Write ALL test cases to the output file. Return ONLY a brief completion summary (2-3 sentences) to the orchestrator: confirm the output file path, state the number of test cases per unit, and note whether there are unresolved questions. Do NOT include the full test case content in your final response."

## Output Template (TEST_CASES.md)

Instruct the sub-agent to follow this structure:

```markdown
# Test Cases: <task-title>

## Unit 1: <name>

### Test: <test-name>
- **Purpose**: [what this test verifies]
- **Setup**: [preconditions or fixtures]
- **Steps**: [actions to perform]
- **Expected**: [expected outcome]

## Unresolved Questions
- [Any questions for the user, or "None"]
```

## Error Handling

If the sub-agent fails or returns no output, report the failure to the user with details and ask whether to retry or abort.

Report: "Phase 3 complete: Test cases written to `<work-dir>/TEST_CASES.md`"

## State Update
Update `STATE.json`: set `currentPhase` to `4`.
