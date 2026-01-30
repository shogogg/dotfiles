---
name: tdd-development
description: Orchestrates a structured TDD development workflow including codebase exploration, work planning, test design, implementation, quality checks (tests/lint/format), and CodeRabbit code review. Triggers when the user wants to implement a feature, fix a bug, refactor code, or requests TDD-based development. Also triggers on keywords like "develop", "implement", "build", "code this".
context: inherit
allowed-tools: Task, Skill, Bash, Read, Write, mcp__jetbrains__open_file_in_editor
---

# /coding Workflow Orchestrator

This skill orchestrates a structured TDD development workflow across 9 phases (Phase 0–8).

## Orchestration Principle

The main agent is **strictly an orchestrator** — it delegates all substantive work to sub-agents and only manages phase transitions and state.

### MUST DO
- Use `Task` tool to launch sub-agents for all exploration, planning, test design, implementation, and review work
- Use `Skill` tool to invoke other skills (e.g., `run-quality-checks`)
- Use `Read` **only** for workspace files: `STATE.json`, `PLAN.md`, `TEST_CASES.md`, `QUALITY_RESULT.md`, `REVIEW_RESULT.md`
- Use `Write` **only** for `STATE.json`
- Use `Bash` **only** for git operations and workspace directory management

### MUST NOT
- Read, search, or explore source code files directly — delegate to sub-agents
- Write or edit source code files directly — delegate to sub-agents
- Analyze code structure, dependencies, or architecture directly — delegate to sub-agents
- Generate implementation code, test code, or review content — delegate to sub-agents

## Workflow Progress Checklist

Copy this checklist and track progress:

```
Workflow Progress:
- [ ] Phase 0: Pre-checks
- [ ] Phase 1: Planning
- [ ] Phase 2: Test Design
- [ ] Phase 3: Approval Gate
- [ ] Phase 4: TDD Implementation
- [ ] Phase 5: Quality Checks
- [ ] Phase 6: Code Review
- [ ] Phase 7: User Review
- [ ] Phase 8: Final Report
```

## Resume Detection

Before starting Phase 0, check for an existing workspace:

1. Run `ls -d .ai-workspace/*_$(git branch --show-current | tr '/' '_') 2>/dev/null`
2. If workspace found, read its `STATE.json`.
3. If `currentPhase` exists in STATE.json:
   - Use `AskUserQuestion`:
     - **前回の続きから再開する** (Phase N から) — Resume from recorded phase
     - **最初からやり直す** — Start fresh from Phase 0
   - Resume: set `<work-dir>` to existing workspace, skip to recorded phase
   - Fresh: proceed to Phase 0 normally
4. If no workspace or no `currentPhase` → proceed to Phase 0.

## Phases

Read each phase document **only when you are ready to execute that phase**. Do not read ahead.

1. [Pre-checks](phases/0-pre-checks.md) — Clarify task, create branch, verify tools, initialize workspace
2. [Planning](phases/1-planning.md) — Explore codebase → create work plan
3. [Test Design](phases/2-test-design.md) — Design test cases based on work plan
4. [Approval Gate](phases/3-approval-gate.md) — Present plan & tests to user for approval
5. [Implementation](phases/4-implementation.md) — Implement code following TDD methodology
6. [Quality Checks](phases/5-quality-checks.md) — Run tests, lint, formatting (max 3 retries)
7. [Code Review](phases/6-code-review.md) — CodeRabbit review (max 3 cycles)
8. [User Review](phases/7-user-review.md) — Present changes to user for approval
9. [Final Report](phases/8-final-report.md) — Summarize results and present to user

## Loop Control

- Phase 5 retry limit: **3** (report to user on exceed)
- Phase 5→6 cycle limit: **3** ("Must Fix" → fix → Phase 5 = 1 cycle)
- Phase 6 "No Must Fix": Does not count as cycle
- Phase 6→5 return: Reset Phase 5 retry counter
- Phase 7 user review: If user requests fixes → fix → return to Phase 5
- Phase 7→5 return: Reset Phase 5 retry counter, does NOT count against cycleCount
- State file: `<work-dir>/STATE.json` (initialize in Phase 0)
