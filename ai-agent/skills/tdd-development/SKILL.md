---
name: tdd-development
description: Orchestrates a structured TDD development workflow including codebase exploration, work planning (with test plan), implementation, quality checks (tests/lint/format), and CodeRabbit code review. Triggers when the user wants to implement a feature, fix a bug, refactor code, or requests TDD-based development. Also triggers on keywords like "develop", "implement", "build", "code this".
context: inherit
allowed-tools: Task, Skill, Bash, Read, Write, TaskCreate, TaskUpdate, TaskList, mcp__jetbrains__open_file_in_editor
---

# /coding Workflow Orchestrator

This skill orchestrates a structured TDD development workflow across 10 phases (Phase 0–9). Phase 9 (PR Review Comments) is optional and user-initiated.

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
- [ ] Phase 3: Approval Gate
- [ ] Phase 4: TDD Implementation
- [ ] Phase 5: Quality Checks
- [ ] Phase 6: User Review
- [ ] Phase 7: Code Review
- [ ] Phase 8: Final Report
- [ ] Phase 9: PR Review Comments (optional)
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
4. [Approval Gate](phases/3-approval-gate.md) — Present plan (including test plan) to user for approval
5. [Implementation](phases/4-implementation.md) — Implement code following TDD methodology
6. [Quality Checks](phases/5-quality-checks.md) — Run tests, lint, formatting (max 3 retries)
7. [User Review](phases/6-user-review.md) — Present changes to user for approval
8. [Code Review](phases/7-code-review.md) — CodeRabbit review (max 3 cycles)
9. [Final Report](phases/8-final-report.md) — Summarize results and present to user
10. [PR Review Comments](phases/9-pr-review.md) — Address PR review comments (optional, user-initiated)

## Loop Control

- Phase 5 retry limit: **3** (report to user on exceed)
- Phase 6 user review: If user requests fixes → fix → return to Phase 5
- Phase 6→5 return: Reset Phase 5 retry counter, does NOT count against cycleCount
- Phase 5→7 cycle limit: **3** ("Must Fix" → fix → Phase 5 = 1 cycle)
- Phase 7 "No Must Fix": Does not count as cycle
- Phase 7→5 return: Reset Phase 5 retry counter (flow goes 5→6→7, user reviews CodeRabbit fixes)
- Phase 9 PR review: If fixes needed → fix → return to Phase 5 (no push until quality checks pass)
- Phase 9→5 return: Reset Phase 5 retry counter, does NOT count against cycleCount
- State file: `<work-dir>/STATE.json` (initialize in Phase 0)

### CRITICAL: Phase File Re-read on Loop Return

When returning to Phase 5 from Phase 6, 7, or 9, you MUST re-read the phase documents before executing them. This is because earlier phase instructions may have drifted out of your active attention due to intervening conversation.

**Rule**: Before executing Phase 5, re-read `phases/5-quality-checks.md`. Before executing Phase 6, re-read `phases/6-user-review.md`. Before executing Phase 7, re-read `phases/7-code-review.md`.

This applies every time you enter these phases, not just the first time. Treat each phase entry as if you are reading the instructions for the first time.

## Tasks Usage

Use Claude Code's `TaskCreate`/`TaskUpdate`/`TaskList` tools for **work-item-level** progress tracking, NOT phase-level tracking (that is STATE.json's role).

### Principles
- **Do NOT use Tasks for phase tracking** — STATE.json handles phase transitions
- **Create Tasks after Phase 3 approval** — from Implementation Units in PLAN.md
- **Create Tasks for fix items** — in Phase 6 (User Feedback) and Phase 7 (Must Fix)
- **Only the orchestrator manages Tasks** — sub-agents must NOT call TaskCreate/TaskUpdate/TaskList

### Naming Convention

| Type | Subject Format | Example |
|------|---------------|---------|
| Implementation Unit | `Implement Unit N: <name>` | `Implement Unit 1: UserService CRUD` |
| Code Review Fix | `Fix CR-<cycle>-<M>: <title>` | `Fix CR-1-2: Missing null check` |
| User Feedback Fix | `Fix UF-<round>-<M>: <title>` | `Fix UF-1-1: Error message in Japanese` |
| PR Review Fix | `Fix PR-<round>-<M>: <title>` | `Fix PR-1-1: Missing validation` |
