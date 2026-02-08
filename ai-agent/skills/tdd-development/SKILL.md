---
name: tdd-development
description: Orchestrates a structured TDD development workflow including codebase exploration, work planning (with test plan), implementation, quality checks (tests/lint/format), and CodeRabbit code review. Triggers when the user wants to implement a feature, fix a bug, refactor code, or requests TDD-based development. Also triggers on keywords like "develop", "implement", "build", "code this".
context: inherit
allowed-tools: Task, Skill, Bash, Read, Write, TaskCreate, TaskUpdate, TaskList, mcp__jetbrains__open_file_in_editor
---

# /coding Workflow Orchestrator

This skill orchestrates a structured TDD development workflow across 9 phases (Phase 0–2, 4–9). Phase 3 (Test Design) has been merged into Phase 2 (Planning).

## Orchestration Principle

The main agent is **strictly an orchestrator** — it delegates all substantive work to sub-agents and only manages phase transitions and state.

### MUST DO
- Use `Task` tool to launch sub-agents for all exploration, planning, test design, implementation, and review work
- Use `Skill` tool to invoke other skills (e.g., `run-quality-checks`)
- Use `Read` **only** for workspace files: `STATE.json`, `PLAN.md`, `QUALITY_RESULT.md`, `REVIEW_RESULT.md`
- Use `Write` **only** for `STATE.json`
- Use `Bash` **only** for git operations and workspace directory management
- Use `TaskCreate`/`TaskUpdate`/`TaskList` to track Implementation Units and fix items (NOT for phase tracking)

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
- [ ] Phase 1: Exploration
- [ ] Phase 2: Planning (includes Test Plan)
- [ ] Phase 4: Approval Gate
- [ ] Phase 5: TDD Implementation
- [ ] Phase 6: Quality Checks
- [ ] Phase 7: Code Review
- [ ] Phase 8: User Review
- [ ] Phase 9: Final Report
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
2. [Exploration](phases/1-exploration.md) — Load past learnings, check profile, explore codebase
3. [Planning](phases/2-planning.md) — Create work plan and test plan based on exploration results
4. [Approval Gate](phases/4-approval-gate.md) — Present plan (including test plan) to user for approval
5. [Implementation](phases/5-implementation.md) — Implement code following TDD methodology
6. [Quality Checks](phases/6-quality-checks.md) — Run tests, lint, formatting (max 3 retries)
7. [Code Review](phases/7-code-review.md) — CodeRabbit review (max 3 cycles)
8. [User Review](phases/8-user-review.md) — Present changes to user for approval
9. [Final Report](phases/9-final-report.md) — Summarize results and present to user

## Loop Control

- Phase 6 retry limit: **3** (report to user on exceed)
- Phase 6→7 cycle limit: **3** ("Must Fix" → fix → Phase 6 = 1 cycle)
- Phase 7 "No Must Fix": Does not count as cycle
- Phase 7→6 return: Reset Phase 6 retry counter
- Phase 8 user review: If user requests fixes → fix → return to Phase 6
- Phase 8→6 return: Reset Phase 6 retry counter, does NOT count against cycleCount
- State file: `<work-dir>/STATE.json` (initialize in Phase 0)

## Tasks Usage

Use Claude Code's `TaskCreate`/`TaskUpdate`/`TaskList` tools for **work-item-level** progress tracking, NOT phase-level tracking (that is STATE.json's role).

### Principles
- **Do NOT use Tasks for phase tracking** — STATE.json handles phase transitions
- **Create Tasks after Phase 4 approval** — from Implementation Units in PLAN.md
- **Create Tasks for fix items** — in Phase 7 (Must Fix) and Phase 8 (User Feedback)
- **Only the orchestrator manages Tasks** — sub-agents must NOT call TaskCreate/TaskUpdate/TaskList

### Naming Convention

| Type | Subject Format | Example |
|------|---------------|---------|
| Implementation Unit | `Implement Unit N: <name>` | `Implement Unit 1: UserService CRUD` |
| Code Review Fix | `Fix CR-<cycle>-<M>: <title>` | `Fix CR-1-2: Missing null check` |
| User Feedback Fix | `Fix UF-<round>-<M>: <title>` | `Fix UF-1-1: Error message in Japanese` |
