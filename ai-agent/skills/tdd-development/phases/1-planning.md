# Phase 1: Planning

Report: "Phase 1: Creating work plan..."

## Step 0: Load Past Learnings

過去の学習結果を Serena Memory から参照し、同じ問題を回避する。

```
mcp__plugin_serena_serena__list_memories()
```

以下の Memory が存在する場合は読み込む:
- `coderabbit-learnings.md` — CodeRabbit レビューからの学習
- `user-feedback-patterns.md` — ユーザーフィードバックのパターン
- `quality-check-learnings.md` — Quality Checks からの学習

```
mcp__plugin_serena_serena__read_memory("<memory-name>")
```

**参照した学習内容は、後続のサブエージェントに伝達すること。**

## Step 1: Codebase Exploration
Skip this step if `<work-dir>/EXPLORATION_REPORT.md` is present.
MUST USE SUB-AGENT "codebase-explorer", max_turns = 30. NEVER EXPLORE THE CODEBASE YOURSELF.

Prompt must include:
- The task description from `$ARGUMENTS`
- Output file path: `<work-dir>/EXPLORATION_REPORT.md`
- **Past learnings summary** (if any were loaded in Step 0)
- **Return directive**: "Write ALL findings to the output file. Return ONLY a brief completion summary (2-3 sentences) to the orchestrator: confirm the output file path, list the number of key files found, and note any concerns. Do NOT include the full report content in your final response."

## Step 2: Work Plan Creation
Skip this step if `<work-dir>/PLAN.md` is present.
MUST USE SUB-AGENT "task-planner", max_turns = 20. NEVER WRITE THE PLAN YOURSELF.

Prompt must include:
- The task description from `$ARGUMENTS`
- Input file path: `<work-dir>/EXPLORATION_REPORT.md`
- Output file path: `<work-dir>/PLAN.md`
- **Past learnings summary** (if any were loaded in Step 0)
- **Return directive**: "Write the complete plan to the output file. Return ONLY a brief completion summary (2-3 sentences) to the orchestrator: confirm the output file path, state the number of implementation units, and note whether there are unresolved questions. Do NOT include the full plan content in your final response."

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

Report: "Phase 1 complete: Work plan written to `<work-dir>/PLAN.md`"

## State Update
Update `STATE.json`: set `currentPhase` to `2`.