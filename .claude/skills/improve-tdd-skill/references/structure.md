# TDD Development Skill Structure Reference

## Overview

The `tdd-development` skill is a structured TDD workflow orchestrator with 10 phases (0-9). It follows a strict delegation principle where the main agent only manages phase transitions and state, while sub-agents perform all substantive work.

## File Locations

**Base Path**: `ai-agent/skills/tdd-development/`

| File | Purpose |
|------|---------|
| `SKILL.md` | Main skill definition, orchestration rules, loop control |
| `phases/0-pre-checks.md` | Environment validation, task clarification, branch creation |
| `phases/1-exploration.md` | Project profile, codebase exploration, scope decisions |
| `phases/2-planning.md` | Work plan creation via task-planner sub-agent |
| `phases/3-test-design.md` | Test case design via unit-test-designer sub-agent |
| `phases/4-approval-gate.md` | User approval for plan and tests |
| `phases/5-implementation.md` | TDD implementation via tdd-implementer sub-agent |
| `phases/6-quality-checks.md` | Tests, lint, formatting via run-quality-checks skill |
| `phases/7-code-review.md` | CodeRabbit review via coderabbit-reviewer sub-agent |
| `phases/8-user-review.md` | User review via user-review skill (difit) |
| `phases/9-final-report.md` | Summary, squash commits, learning capture |

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

### Phase 2: Planning
- **Executor**: Sub-agent (task-planner)
- **Output**: `<work-dir>/PLAN.md`
- **Key Sections**: Overview, Affected Files, Implementation Units

### Phase 3: Test Design
- **Executor**: Sub-agent (unit-test-designer)
- **Output**: `<work-dir>/TEST_CASES.md`
- **Key Sections**: Test cases per unit, Unresolved Questions

### Phase 4: Approval Gate
- **Executor**: Main agent + Sub-agent (feedback-validator)
- **Key Actions**:
  - Resolve unresolved questions
  - Present summary to user
  - Open files in IDE
  - Get explicit approval
  - **Feedback validation**: When user requests changes, validate feedback via feedback-validator before applying

### Phase 5: Implementation
- **Executor**: Sub-agent (tdd-implementer)
- **Key Actions**:
  - Read plan and test cases
  - Implement following TDD (Red-Green-Refactor)
  - Handle multi-unit sequential implementation

### Phase 6: Quality Checks
- **Executor**: Skill (run-quality-checks)
- **Key Actions**:
  - Propose test scope
  - Run tests, lint, formatting
  - Handle failures (max 3 retries)
- **Control**: `retryCount` in STATE.json

### Phase 7: Code Review
- **Executor**: Sub-agent (coderabbit-reviewer, **background execution**) + knowledge distillation
- **Output**: `<work-dir>/REVIEW_RESULT.md`
- **Key Actions**:
  - Launch CodeRabbit review in background (`run_in_background: true`)
  - Poll output_file every ~30 seconds for completion
  - Every 5 minutes, ask user to continue waiting or abort
  - Classify findings (Must Fix, Consider, Ignorable)
  - **Launch distill-knowledge in background (parallel with fixes)**
  - Fix Must Fix items and return to Phase 6
- **Control**: `cycleCount` (max 3 cycles)

### Phase 8: User Review
- **Executor**: Skill (user-review) + Sub-agent (feedback-validator) + knowledge distillation
- **Key Actions**:
  - Launch difit for visual diff review
  - Handle user feedback
  - **Feedback validation**: When user requests changes, validate feedback via feedback-validator before applying
  - **Launch distill-knowledge in background (parallel with fixes)**
  - Return to Phase 6 if fixes needed

### Phase 9: Final Report
- **Executor**: Main agent + Sub-agent (general-purpose via distill-knowledge)
- **Key Actions**:
  - Squash commits (optional)
  - Comprehensive knowledge distillation via `distill-knowledge` skill (consolidates all session learnings into Serena Memory `review-knowledge`)
  - Sub-agent writes `LEARNING_SUMMARY.md`
  - Main agent compiles final report using `LEARNING_SUMMARY.md`

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
2. **Phase 6-7 cycles**: Max 3 (Must Fix → fix → Phase 6 = 1 cycle)
3. **Phase 7 "No Must Fix"**: Does not count as cycle
4. **Return from Phase 7/8**: Resets Phase 6 retry counter
5. **Return from Phase 8**: Does NOT count against cycleCount

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

### Exploration Level Adjustment
- **File**: `phases/1-exploration.md`
- **Section**: Step 1.3 (Exploration Scope Decision)
- **Parameters**: Level thresholds, default level, user override options
- **Section**: Step 1.4 (Parallel Codebase Exploration)
- **Parameters**: Agent configuration per level (which agents to launch, max_turns per agent)

### Retry/Cycle Limits
- **Files**: `SKILL.md`, `phases/6-quality-checks.md`, `phases/7-code-review.md`
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
- **Files**: `phases/4-approval-gate.md`, `phases/8-user-review.md`
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
    ├── PLAN.md
    ├── TEST_CASES.md
    ├── QUALITY_RESULT.md
    ├── REVIEW_RESULT.md
    ├── FEEDBACK_VALIDATION.md
    └── LEARNING_SUMMARY.md
```
