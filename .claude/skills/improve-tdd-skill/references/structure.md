# TDD Development Skill Structure Reference

## Overview

The `tdd-development` skill is a structured TDD workflow orchestrator with 10 phases (0-2, 4-10). Phase 3 (Test Design) has been merged into Phase 2 (Planning). Phase 10 (PR Review Comments) is optional and user-initiated. It follows a strict delegation principle where the main agent only manages phase transitions and state, while sub-agents perform all substantive work.

## File Locations

**Base Path**: `ai-agent/skills/tdd-development/`

| File | Purpose |
|------|---------|
| `SKILL.md` | Main skill definition, orchestration rules, loop control |
| `phases/0-pre-checks.md` | Environment validation, task clarification, branch creation |
| `phases/1-exploration.md` | Project profile, codebase exploration, scope decisions |
| `phases/2-planning.md` | Work plan and test plan creation via task-planner sub-agent |
| `phases/4-approval-gate.md` | User approval for plan (including test plan) |
| `phases/5-implementation.md` | TDD implementation via tdd-implementer sub-agent |
| `phases/6-quality-checks.md` | Tests, lint, formatting via run-quality-checks skill |
| `phases/7-user-review.md` | User review via difit skill |
| `phases/8-code-review.md` | CodeRabbit review via coderabbit-reviewer sub-agent |
| `phases/9-final-report.md` | Summary, squash commits, learning capture |
| `phases/10-pr-review.md` | PR review comments response (optional, user-initiated) |

**Related Skills:**

| File | Purpose |
|------|---------|
| `ai-agent/skills/distill-knowledge/SKILL.md` | Knowledge distillation from reviews/feedback into Serena Memory |

## Phase Details

### Phase 0: Pre-checks
- **Executor**: Main agent (direct)
- **Key Actions**:
  - Verify Taskfile availability
  - CodeRabbit auth check
  - Task clarification (AskUserQuestion)
  - Branch creation
  - Workspace initialization

### Phase 1: Exploration
- **Executor**: Multiple sub-agents (parallel codebase-explorer + general-purpose integrator)
- **Key Actions**:
  - Check/update project profile (`.ai-workspace/PROJECT_PROFILE.md`)
  - Load learnings from memory (Serena)
  - Scope decision: Light, Medium, Full, Skip
  - **Parallel exploration** (Step 1.4):
    - Agent A: Task-related code exploration → `EXPLORATION_CODE.md`
    - Agent B: Test & quality infrastructure → `EXPLORATION_TEST.md` (Medium/Full only)
    - Agent C: Patterns & conventions → `EXPLORATION_PATTERNS.md` (Full only)
  - **Integration** (Step 1.5): Agent D merges results → `EXPLORATION_REPORT.md` + `PROJECT_PROFILE.md`

### Phase 2: Planning (includes Test Plan)
- **Executor**: Sub-agent (task-planner)
- **Output**: `<work-dir>/PLAN.md`
- **Key Sections**: Overview, Target Files, Implementation Approach, Implementation Units, **Test Plan**, Risks and Notes, Unresolved Questions
- **Test Plan format**: Test method names grouped by class/method, categorized by Happy Path / Boundary / Edge Cases, with notes on test strategy (data providers, mocks, etc.)

### Phase 3: (Removed — merged into Phase 2)

### Phase 4: Approval Gate
- **Executor**: Main agent + Sub-agent (feedback-validator)
- **Key Actions**:
  - Resolve unresolved questions
  - Present summary to user (including Test Plan)
  - Open files in IDE
  - Get explicit approval
  - **Feedback validation**: When user requests changes, validate feedback via feedback-validator before applying

### Phase 5: Implementation
- **Executor**: Multiple sub-agents (tdd-implementer, parallel when possible)
- **Key Actions**:
  - Read plan and analyze dependency graph (independent, contract, implementation dependencies)
  - **Interface stub creation**: If contract dependencies exist, create interface/type stubs first to unblock parallel units
  - **Parallel batch execution**: Launch independent and contract-unblocked units in parallel
  - Implementation-dependent units wait for their dependencies to complete
  - Each unit follows TDD (Red-Green-Refactor)
  - Error handling: failed units don't block parallel siblings

### Phase 6: Quality Checks
- **Executor**: Skill (run-quality-checks)
- **Key Actions**:
  - Propose test scope
  - Run tests, lint, formatting
  - Handle failures (max 3 retries)
- **Control**: `retryCount` in STATE.json

### Phase 7: User Review
- **Executor**: Skill (difit) + Sub-agent (feedback-validator) + knowledge distillation
- **Key Actions**:
  - Launch difit for visual diff review (timeout handling is within difit skill via background execution + polling)
  - Handle user feedback
  - **USER_FEEDBACK.md uses append mode**: Each round is appended, never overwritten, to preserve full feedback history
  - **Immediate knowledge distillation (Step 4.5)**: Launch distill-knowledge in background immediately after writing feedback (before fixes)
  - **Feedback validation**: When user requests changes, validate feedback via feedback-validator before applying
  - Return to Phase 6 if fixes needed

### Phase 8: Code Review
- **Executor**: Sub-agent (coderabbit-reviewer, **background execution**) + knowledge distillation
- **Output**: `<work-dir>/REVIEW_RESULT.md`
- **Key Actions**:
  - Launch CodeRabbit review in background (`run_in_background: true`)
  - Poll output_file every ~30 seconds for completion
  - Every 5 minutes, ask user to continue waiting or abort
  - Classify findings (Must Fix, Consider, Ignorable)
  - **Launch distill-knowledge in background (parallel with fixes)**
  - Fix Must Fix items and return to Phase 6 (flow goes 6→7→8, user reviews CodeRabbit fixes)
- **Control**: `cycleCount` (max 3 cycles)

### Phase 9: Final Report
- **Executor**: Main agent + Sub-agent (general-purpose via distill-knowledge)
- **Key Actions**:
  - Squash commits (optional)
  - Comprehensive knowledge distillation via `distill-knowledge` skill (consolidates all session learnings into Serena Memory `review-knowledge`)
  - Sub-agent writes `LEARNING_SUMMARY.md`
  - Main agent compiles final report using `LEARNING_SUMMARY.md`

### Phase 10: PR Review Comments (Optional)
- **Executor**: Main agent + Skills (fetch-pr-review-comments) + Sub-agents (feedback-validator, tdd-implementer, knowledge-distiller)
- **Key Actions**:
  - Obtain review comments via two methods: auto-fetch from PR or manual user input
  - Write `PR_REVIEW_FEEDBACK.md` (append mode, like USER_FEEDBACK.md)
  - Background knowledge distillation
  - Present comments to user, ask which to address
  - Validate feedback via feedback-validator
  - Fix each item individually with tdd-implementer, commit each one
  - Push changes and return to Phase 6 (full loop: 6→7→8→10)
  - No explicit round limit (each round requires user initiation)
- **Control**: Does NOT count against `cycleCount`

## State Management

**File**: `<work-dir>/STATE.json`

### Key Fields

| Field | Type | Purpose |
|-------|------|---------|
| `currentPhase` | number | Current phase (0-9) |
| `baseBranch` | string | Original branch before feature branch |
| `featureBranch` | string | Created feature branch |
| `startCommitHash` | string | HEAD at session start |
| `firstCommitHash` | string | First commit in session |
| `retryCount` | number | Phase 6 retry counter (resets on return from 7 or 8) |
| `cycleCount` | number | Phase 6-7 cycle counter (max 3) |
| `explorationLevel` | string | quick, focused, full |

## Loop Control Rules

1. **Phase 6 retries**: Max 3 per cycle
2. **Return from Phase 7**: Resets Phase 6 retry counter, does NOT count against cycleCount
3. **Phase 6-8 cycles**: Max 3 (Must Fix → fix → Phase 6 = 1 cycle)
4. **Phase 8 "No Must Fix"**: Does not count as cycle
5. **Return from Phase 8**: Resets Phase 6 retry counter (flow goes 6→7→8, user reviews CodeRabbit fixes)
6. **Return from Phase 10**: Resets Phase 6 retry counter, does NOT count against cycleCount

## Knowledge & Memory Architecture

### Shared Knowledge (Serena Memory)

Cross-session, cross-agent knowledge is stored in Serena Memory `review-knowledge`. This is the primary store for review and feedback patterns, managed by the `distill-knowledge` skill.

- **Written by**: distill-knowledge sub-agent (Phase 7/8 background, Phase 9 comprehensive)
- **Read by**: All sub-agents (especially `tdd-implementer` in Pre-Implementation Step 2)
- **Scope**: Project-level, persists across sessions

### Agent Memory

All custom sub-agents have `memory: user` configured, providing persistent memory at `~/.claude/agent-memory/<name>/`. This stores agent-specific learnings.

| Agent | Memory Scope | Key Learnings |
|-------|-------------|---------------|
| `codebase-explorer` | `user` | Codebase structures, architectural patterns, project conventions |
| `task-planner` | `user` | Planning patterns, decomposition strategies, architectural decisions |
| `unit-test-designer` | `user` | Test patterns, naming conventions, edge cases |
| `tdd-implementer` | `user` | Coding patterns, common mistakes, implementation-specific learnings |
| `feedback-validator` | `user` | Feedback types, recurring concerns, user preferences |
| `coderabbit-reviewer` | `user` | Review patterns, false positives, classification decisions |

## Common Improvement Areas

### Test Execution Enforcement
- **File**: `ai-agent/agents/tdd-implementer.md`
- **Section**: "Test Execution (CRITICAL — Read Before Writing Any Code)"
- **Key design**: Test Execution section is placed BEFORE TDD Cycle to ensure it's read first
- **Fallback policy**: If `task` command not found, agent must ask user (no silent fallback)
- **Reinforcement**: TDD Cycle steps include inline reminders to use the detected `task` command
- **Disambiguation**: Terminology note distinguishes go-task `task` CLI from Claude Code's `Task` tool

### go-task vs Claude Code Task Disambiguation
- **Files affected**: All files referencing `task` CLI — `tdd-implementer.md`, `run-quality-checks/SKILL.md`, phases 0, 5, 6, 7, 8
- **Convention**: First mention in each file includes terminology note; CRITICAL instructions explicitly say "go-task `task` CLI" and "via the Bash tool"
- **Rationale**: LLMs can confuse go-task CLI `task` with Claude Code's `Task` tool (sub-agent launcher) or `TaskCreate`/`TaskUpdate` (task list management)

### Exploration Level Adjustment
- **File**: `phases/1-exploration.md`
- **Section**: Step 1.3 (Exploration Scope Decision)
- **Parameters**: Level thresholds, default level, user override options
- **Section**: Step 1.4 (Parallel Codebase Exploration)
- **Parameters**: Agent configuration per level (which agents to launch, max_turns per agent)

### Retry/Cycle Limits
- **Files**: `SKILL.md`, `phases/6-quality-checks.md`, `phases/8-code-review.md`
- **Parameters**: Max retry counts, cycle limits, escalation behavior

### Sub-agent Prompts
- **Files**: All phase files that launch sub-agents
- **Parameters**: max_turns, return directives, context passing

### Learning Capture / Knowledge Distillation
- **Skill**: `ai-agent/skills/distill-knowledge/SKILL.md`
- **Invoked from**: Phase 7 (background), Phase 8 (background), Phase 9 (foreground comprehensive)
- **Storage**: Serena Memory `review-knowledge` (cross-session, cross-agent)
- **Consumer**: `tdd-implementer` Pre-Implementation Step 2 reads `review-knowledge`
- **Considerations**: Pattern quality, deduplication, pruning old entries

### Feedback Validation
- **Files**: `phases/4-approval-gate.md`, `phases/7-user-review.md`
- **Agent**: `ai-agent/agents/feedback-validator.md`
- **Parameters**: Evaluation criteria, classification thresholds, output format

### Profile Management
- **File**: `phases/1-exploration.md`
- **Section**: Step 1 (Project Profile Check)
- **Parameters**: Freshness threshold (currently 30 days), update triggers
- **Note**: Profile is generated/updated by the integration sub-agent (Agent D) in Step 1.5 for all non-Skip exploration levels

### User Messages
- **Files**: Various
- **Principle**: Prompts in English, user-facing messages in Japanese
- **Tools**: AskUserQuestion for user interaction

## Workspace Structure

```
.ai-workspace/
├── PROJECT_PROFILE.md          # Global project profile
└── <timestamp>_<branch>/       # Per-session workspace
    ├── STATE.json
    ├── EXPLORATION_CODE.md     # Agent A output (task-related code)
    ├── EXPLORATION_TEST.md     # Agent B output (test infrastructure, Medium/Full)
    ├── EXPLORATION_PATTERNS.md # Agent C output (patterns/conventions, Full)
    ├── EXPLORATION_REPORT.md   # Integrated exploration report (Agent D)
    ├── PLAN.md                 # Work plan + Test Plan (merged)
    ├── QUALITY_RESULT.md
    ├── REVIEW_RESULT.md
    ├── FEEDBACK_VALIDATION.md
    ├── LEARNING_SUMMARY.md
    └── PR_REVIEW_FEEDBACK.md  # PR review comments (Phase 10, append mode)
```
