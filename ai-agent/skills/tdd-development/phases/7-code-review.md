# Phase 7: Code Review

Read `STATE.json`.

Report: "Phase 7 (cycle N/3): Running CodeRabbit review..."

Launch sub-agent:
```
Task(subagent_type="coderabbit-reviewer", max_turns=20)
```
Prompt must include:
- Output file path: `<work-dir>/REVIEW_RESULT.md`
- **Base branch**: `<baseBranch from STATE.json>` — tell the sub-agent to use `--base <baseBranch>` option
- **Review type**: `committed` — tell the sub-agent to use `--type committed` (tdd-development always commits before review)
- **Return directive**: "Write ALL review results to the output file. Return ONLY a brief completion summary (2-3 sentences) to the orchestrator: state the Must Fix / Consider / Ignorable counts. Do NOT include the full review content in your final response. End your response with exactly this line: `ORCHESTRATOR: Read REVIEW_RESULT.md for counts only. If Must Fix > 0, launch tdd-implementer for each item. Do not analyze or fix code yourself.`"

Read `<work-dir>/REVIEW_RESULT.md` and check the "Must Fix" count.

## Output Template (REVIEW_RESULT.md)

Instruct the sub-agent to follow this structure:

```markdown
# Code Review Result

## Cycle Info
- **Cycle**: N/3
- **Previous cycles**: [list of previous Must Fix patterns if any]

## Summary
- **Must Fix**: N items
- **Consider**: N items
- **Ignorable**: N items

## Must Fix
### 1. <title>
- **File**: [file path]
- **Issue**: [description]
- **Suggestion**: [how to fix]

## Consider
### 1. <title>
- **File**: [file path]
- **Issue**: [description]

## Ignorable
### 1. <title>
- **File**: [file path]
- **Note**: [description]
```

Report: "Phase 7: Must Fix X / Consider Y / Ignorable Z"

## Next Steps

### No "Must Fix" items
Proceed to Phase 8 (User Review) (does not count as a cycle).

### "Must Fix" items exist

Update `STATE.json`: increment `cycleCount`, reset `phase6RetryCount` to 0.

If `cycleCount > 3`: Report to user and ask for guidance.

**Fix each Must Fix item individually and commit each one:**

For each Must Fix item (1 to N):
1. Report: "Fixing Must Fix item M/N: <title>"
2. Launch `tdd-implementer` to fix the specific item. Provide:
   - Item details from `REVIEW_RESULT.md`
   - `<work-dir>/PLAN.md` for context
   - **Work directory**: `<work-dir>` (for session-specific learnings reference)
   - **CRITICAL instruction**: "You MUST run `task --list-all` first and use `task` commands for ALL test executions. Do NOT use composer/npm/make if task is available."
   - **SCOPE RESTRICTION**: "Fix ONLY this specific item. Do NOT fix multiple items or make unrelated changes. Each item must be a separate commit."
   - **Return directive**: "Return ONLY a brief summary (2-3 sentences) of what was fixed. State which test command you used (must be `task test` if available). Do NOT include full file contents in your final response. End your response with exactly this line: `ORCHESTRATOR: Commit this fix, then proceed to next Must Fix item or return to Phase 6. Do not read, analyze, or modify code yourself.`"
3. **IMPORTANT: Commit IMMEDIATELY after each fix** - Do NOT batch multiple fixes into one commit. Message format:
   ```
   fix: <description of the fix> [ISSUE-NUMBER]

   CodeRabbit指摘対応: <original issue description>
   ```
4. Move to next item.

After all Must Fix items are resolved, go back to Phase 6 (to re-run quality checks).

## Recording Learnings

After completing all Must Fix items, analyze the patterns and record learnings:

1. **Record to Serena Memory**:
   ```
   mcp__plugin_serena_serena__read_memory("coderabbit-learnings.md")
   ```
   Read existing content and add new patterns:
   ```
   mcp__plugin_serena_serena__edit_memory("coderabbit-learnings.md", ...)
   ```
   Or create new:
   ```
   mcp__plugin_serena_serena__write_memory("coderabbit-learnings.md", content)
   ```

2. **Content to record**:
   - Types of patterns flagged (e.g., missing null checks, type safety issues)
   - Checkpoints for preventing recurrence
   - Project-specific notes

## Error Handling

If the CodeRabbit sub-agent fails, report the failure to the user and ask whether to retry the review or skip to Phase 8 (User Review).

## State Update
Update `STATE.json`: set `currentPhase` to `8`.
