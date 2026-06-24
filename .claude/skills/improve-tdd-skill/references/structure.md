# TDD Development Skill Structure Reference

## Overview

The `tdd-development` skill is a structured TDD workflow orchestrator with 10 contiguous phases (0-9). Phase 9 (PR Review Comments) is optional and user-initiated. Phase numbers have been consolidated — historical Phase 3 (Test Design) and Phase 10 are no longer used; their contents merged into Phase 2 and Phase 9 respectively. The orchestrator follows a strict delegation principle where the main agent only manages phase transitions and state, while sub-agents perform all substantive work.

## File Locations

**Base Path**: `ai-agent/skills/tdd-development/`

| File | Purpose |
|------|---------|
| `SKILL.md` | Main skill definition, orchestration rules, loop control |
| `phases/0-pre-checks.md` | Environment validation, task clarification, branch creation |
| `phases/1-exploration.md` | Project profile, codebase exploration, scope decisions (lightweight) |
| `phases/2-planning.md` | Work plan and test plan creation via task-planner sub-agent (high-level units) |
| `phases/3-approval-gate.md` | User approval for plan (including test plan) |
| `phases/4-implementation.md` | TDD implementation via tdd-implementer sub-agent |
| `phases/5-quality-checks.md` | Tests, lint, formatting via run-quality-checks skill |
| `phases/6-user-review.md` | User review via difit skill |
| `phases/7-code-review.md` | CodeRabbit review via coderabbit-reviewer sub-agent |
| `phases/8-final-report.md` | Summary, squash commits, learning capture |
| `phases/9-pr-review.md` | PR review comments response (optional, user-initiated) |

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

### Phase 1: Exploration (Lightweight)
- **Executor**: Multiple sub-agents (parallel codebase-explorer + optional integrator)
- **Design principle**: Light is the default. Spend exploration budget on what the task needs; detail-gathering belongs in Phase 4.
- **Key Actions**:
  - Check/update project profile (`.ai-workspace/PROJECT_PROFILE.md`)
  - Load learnings from memory (Serena)
  - Scope decision: Light (default), Medium, Full, Skip
  - **Parallel exploration** (Step 1.4) — `max_turns=10` per agent:
    - Agent A: Task-related code exploration → `EXPLORATION_CODE.md`
    - Agent B: Test & quality infrastructure → `EXPLORATION_TEST.md` (Medium/Full only)
    - Agent C: Patterns & conventions → `EXPLORATION_PATTERNS.md` (Full only)
  - **Integration** (Step 1.5):
    - **Light**: Skip integration agent; copy `EXPLORATION_CODE.md` directly as `EXPLORATION_REPORT.md`. Profile update via lightweight general-purpose sub-agent only if needed.
    - **Medium/Full**: Agent D (general-purpose, max_turns=10) merges results → `EXPLORATION_REPORT.md` + `PROJECT_PROFILE.md`
- **Report format**: Lightweight — required sections are Task Summary, Related Files, Key Concerns. Other sections (Dependencies, Test Patterns, Existing Patterns) are optional.

### Phase 2: Planning (Lightweight, includes Test Plan)
- **Executor**: Sub-agent (task-planner), `max_turns=15`, model `opus` (default)
- **Design principle**: Plan provides the **shape** of the work, not the implementation. Implementation Units stay high-level. **Test Plan is the exception** — keep test case enumeration thorough.
- **Output**: `<work-dir>/PLAN.md`
- **Key Sections**: Overview, Affected Files, Implementation Units (high-level), **Test Plan** (detailed), Unresolved Questions, Learnings Applied
- **Implementation Units format**: Each unit includes only Files, Changes (one-line), Dependencies, Dependency Type, Model. No step-by-step implementation or code snippets.
- **Test Plan format**: Test method names grouped by class/method, categorized by Happy Path / Boundary / Edge Cases, with notes on test strategy (data providers, mocks, etc.)

### Phase 3: Approval Gate
- **Executor**: Main agent + Sub-agents (feedback-validator, general-purpose for plan edits)
- **Key Actions**:
  - Resolve unresolved questions
  - Present summary to user (including Test Plan)
  - Open files in IDE
  - Get explicit approval
  - **Feedback validation**: When user requests changes, validate feedback via feedback-validator before applying
  - **Lightweight plan editing**: Uses `general-purpose` (Sonnet, max_turns: 10) for feedback-driven plan updates — fast since only minimal edits are needed

### Phase 4: Implementation
- **Executor**: Multiple sub-agents (tdd-implementer, parallel when possible)
- **Model Selection**: Each Implementation Unit in PLAN.md specifies a `Model` field (haiku/sonnet/opus). Phase 4 reads this field and passes it to tdd-implementer via `Task(model="<value>")`. Interface stub creation uses `haiku` by default. The agent's default model is `sonnet`.
- **Key Actions**:
  - Read plan and analyze dependency graph (independent, contract, implementation dependencies)
  - **Interface stub creation**: If contract dependencies exist, create interface/type stubs first to unblock parallel units (uses haiku)
  - **Parallel batch execution**: Launch independent and contract-unblocked units in parallel (each with its specified model)
  - Implementation-dependent units wait for their dependencies to complete
  - Each unit follows TDD (Red-Green-Refactor)
  - Error handling: failed units don't block parallel siblings

### Phase 5: Quality Checks
- **Executor**: Skill (run-quality-checks)
- **Key Actions**:
  - **Scope reuse** (Step 1): Read `STATE.json.qualityScope`; if non-null, reuse and skip Step 1.1/1.2. Otherwise prompt user and save selection to `qualityScope`.
  - **Failed-category-only retry** (Step 2): Read `STATE.json.qualityFailedCategories`. If non-empty, pass `--categories=<failed>` so only previously-failed categories re-run. Previously-passing `.exitcode` files remain intact for overall state recovery.
  - Create progress tasks via TaskCreate (per detected & filtered category)
  - **3 Sub-step Execution Strategy** (run-quality-checks):
    - **Sub-step A**: Auto-fix (sequential, only for in-scope categories) — format fix → lint fix to avoid file conflicts
    - **Sub-step B**: All in-scope checks in parallel — each Bash call writes raw output directly to `QC_<CATEGORY>.raw` and the exit code to `QC_<CATEGORY>.exitcode` (no markdown wrapping)
    - **Sub-step C**: Trivial summary write — derive `QC_SUMMARY.md` from `.exitcode` files (no content processing)
  - **Auto-fix commit** (Step 2.5): If auto-fix applied changes, commit them via `commit` skill before handling results. Reads `QC_SUMMARY.md` for the `Auto-fix Applied` flag.
  - **Result handling** (Step 3): Read `QC_SUMMARY.md` for status; read specific `QC_<CATEGORY>.raw` for failure details. Update `STATE.json.qualityFailedCategories` after each run.
  - Handle failures (max 3 retries). The FAIL options include a "Change scope" action that resets `qualityScope` to `null`.
- **Task list cache**: First invocation writes `<work-dir>/TASK_LIST.txt`. Subsequent invocations (this skill, sub-agents in Phase 4, etc.) reuse it.
- **Control**: `phase5RetryCount`, `qualityScope`, `qualityFailedCategories` in STATE.json

### Phase 6: User Review
- **Executor**: Skill (difit) + Sub-agent (feedback-validator) + knowledge distillation
- **Model Selection**: Each feedback item is analyzed for complexity before launching tdd-implementer. Simple changes (typos, formatting, method reordering) use haiku; moderate changes (logic modifications, new methods) use sonnet; complex changes (architectural, large refactoring) use opus. Defaults to sonnet when in doubt.
- **Key Actions**:
  - **Review unit selection** (Step 2.5): User chooses between "all changes" (default) or "per-commit" review
  - Launch difit for visual diff review (timeout handling is within difit skill via background execution + polling)
  - Per-commit mode: iterates through commits oldest-first, launching difit for each with resolved parent hash
  - Handle user feedback
  - **USER_FEEDBACK.md uses append mode**: Each round is appended, never overwritten, to preserve full feedback history
  - **Immediate knowledge distillation (Step 5.5)**: Launch distill-knowledge in background immediately after writing feedback (before fixes)
  - **Feedback validation**: When user requests changes, validate feedback via feedback-validator before applying
  - Dynamic model selection for each feedback item based on complexity analysis
  - Return to Phase 5 if fixes needed

### Phase 7: Code Review
- **Executor**: Sub-agent (coderabbit-reviewer, **background execution**) + knowledge distillation
- **Output**: `<work-dir>/REVIEW_RESULT.md`
- **Model Selection**: Each Must Fix item is analyzed for complexity before launching tdd-implementer. Simple changes (typos, formatting, method reordering) use haiku; moderate changes (logic modifications, new methods) use sonnet; complex changes (architectural, large refactoring) use opus. Defaults to sonnet when in doubt.
- **Key Actions**:
  - Launch CodeRabbit review in background (`run_in_background: true`)
  - Poll output_file every ~30 seconds for completion
  - Every 5 minutes, ask user to continue waiting or abort
  - Classify findings (Must Fix, Consider, Ignorable)
  - **Launch distill-knowledge in background (parallel with fixes)**
  - Dynamic model selection for each Must Fix item based on complexity analysis
  - Fix Must Fix items and return to Phase 5 (flow goes 5→6→7, user reviews CodeRabbit fixes)
  - **No Must Fix branch**: pre-launch comprehensive knowledge distillation (background, fire-and-forget) before proceeding to Phase 8, saving `task_id` to `STATE.json.learningDistillTaskId`. This eliminates the wait that was previously required in Phase 8.
- **Control**: `cycleCount` (max 3 cycles)

### Phase 8: Final Report
- **Executor**: Main agent (orchestrator only) + Sub-agent (general-purpose, background) + knowledge-distiller (pre-launched in Phase 7, background)
- **Design principle**: Phase 8 must NOT block the user. All heavy work (report compilation, knowledge distillation) runs in background. The main agent's inline footprint is limited to: optional squash → background launches → minimal summary.
- **Key Actions**:
  - **Step 0 — Squash commits**: Auto-skipped when `COMMIT_COUNT <= 1`. Otherwise ask user (`統合する` / `統合しない`).
  - **Step 1 — Distillation check**: Read `STATE.json.learningDistillTaskId`. Skip re-launching if Phase 7 already pre-launched. If unset (Phase 7 skipped), launch fire-and-forget.
  - **Step 2 — Background final report generation**: Launch `general-purpose` sub-agent with `run_in_background=true` (max_turns=10) to compile FINAL_REPORT.md. Save `task_id` to `STATE.json.finalReportTaskId`. Never awaited.
  - **Step 3 — Minimal inline summary**: Issue parallel `git log --oneline` and `git diff --name-only | wc -l`. Present a short summary (task, commit list, FINAL_REPORT.md / LEARNING_SUMMARY.md path references, next steps). The user can move on immediately.
- **Sub-agent responsibilities**: Read STATE.json, statistics files (EXPLORATION_REPORT.md, PLAN.md, IMPLEMENTATION_STATS.md, QC_SUMMARY.md, REVIEW_RESULT.md, USER_FEEDBACK.md), call TaskList, parse git log, write FINAL_REPORT.md. Never embeds LEARNING_SUMMARY.md content (path reference only).

### Phase 9: PR Review Comments (Optional)
- **Executor**: Main agent + Skills (fetch-pr-review-comments) + Sub-agents (feedback-validator, tdd-implementer, knowledge-distiller)
- **Model Selection**: Each PR review item is analyzed for complexity before launching tdd-implementer. Simple changes (typos, formatting, method reordering) use haiku; moderate changes (logic modifications, new methods) use sonnet; complex changes (architectural, large refactoring) use opus. Defaults to sonnet when in doubt.
- **Key Actions**:
  - Obtain review comments via two methods: auto-fetch from PR or manual user input
  - Write `PR_REVIEW_FEEDBACK.md` (append mode, like USER_FEEDBACK.md)
  - Background knowledge distillation
  - Present comments to user, ask which to address
  - Validate feedback via feedback-validator
  - Dynamic model selection for each PR review item based on complexity analysis
  - Fix each item individually with tdd-implementer, commit each one
  - Return to Phase 5 (no push — full quality loop: 5→6→7)
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
| `phase5RetryCount` | number | Phase 5 retry counter (resets on return from 6, 7, or 9) |
| `cycleCount` | number | Phase 5-7 cycle counter (max 3) |
| `lastReviewCommit` | string/null | HEAD hash at last review completion (Phase 6/7), used as "since last review" diff base option |
| `explorationLevel` | string | quick, focused, full |
| `learningDistillTaskId` | string/null | task_id of the comprehensive knowledge-distiller pre-launched at the end of Phase 7. Phase 8 reads this to skip re-launching. Fire-and-forget (never awaited). |
| `finalReportTaskId` | string/null | task_id of the general-purpose sub-agent launched in Phase 8 Step 2 to generate FINAL_REPORT.md in background. Fire-and-forget (never awaited). |
| `qualityScope` | object/null | Persisted test/target scope selection from Phase 5 Step 1. Shape: `{ test: { scope, args }, target: { mode, paths } }`. Reused on Phase 5 re-entry to skip re-prompting. Reset to null by the "Change scope" FAIL option. |
| `qualityFailedCategories` | array | List of category names (`test`, `lint`, `analyse`, `format`) that failed in the most recent Phase 5 run. Passed as `--categories=<list>` to `run-quality-checks` on retry. Cleared on overall PASS. |

## Loop Control Rules

1. **Phase 5 retries**: Max 3 per cycle
2. **Return from Phase 6**: Resets Phase 5 retry counter, does NOT count against cycleCount
3. **Phase 5-7 cycles**: Max 3 (Must Fix → fix → Phase 5 = 1 cycle)
4. **Phase 7 "No Must Fix"**: Does not count as cycle
5. **Return from Phase 7**: Resets Phase 5 retry counter (flow goes 5→6→7, user reviews CodeRabbit fixes)
6. **Return from Phase 9**: Resets Phase 5 retry counter, does NOT count against cycleCount

## Knowledge & Memory Architecture

### Shared Knowledge (Serena Memory)

Cross-session, cross-agent knowledge is stored in Serena Memory `x-coding-best-practices`. This is the primary store for review and feedback patterns, managed by the `distill-knowledge` skill.

- **Written by**: distill-knowledge sub-agent (Phase 6/7 background, Phase 8 comprehensive)
- **Read by**: All sub-agents (especially `tdd-implementer` in Pre-Implementation Step 2)
- **Scope**: Project-level, persists across sessions

### Agent Memory

All custom sub-agents have `memory: user` configured, providing persistent memory at `~/.claude/agent-memory/<name>/`. This stores agent-specific learnings.

| Agent | Model | Memory Scope | Key Learnings |
|-------|-------|-------------|---------------|
| `codebase-explorer` | sonnet | `user` | Codebase structures, architectural patterns, project conventions |
| `task-planner` | opus | `user` | Planning patterns, decomposition strategies, architectural decisions |
| `unit-test-designer` | opus | `user` | Test patterns, naming conventions, edge cases |
| `tdd-implementer` | sonnet (default; per-unit override) | `user` | Coding patterns, common mistakes, implementation-specific learnings |
| `feedback-validator` | sonnet | `user` | Feedback types, recurring concerns, user preferences |
| `coderabbit-reviewer` | sonnet | `user` | Review patterns, false positives, classification decisions |
| `knowledge-distiller` | haiku | `user` | Pattern extraction (lightweight workload) |

## Common Improvement Areas

### Test Execution Enforcement
- **File**: `ai-agent/agents/tdd-implementer.md`
- **Section**: "Test Execution (CRITICAL — Read Before Writing Any Code)"
- **Key design**: Test Execution section is placed BEFORE TDD Cycle to ensure it's read first
- **Fallback policy**: If `task` command not found, agent must ask user (no silent fallback)
- **Reinforcement**: TDD Cycle steps include inline reminders to use the detected `task` command
- **Disambiguation**: Terminology note distinguishes go-task `task` CLI from Claude Code's `Task` tool

### go-task vs Claude Code Task Disambiguation
- **Files affected**: All files referencing `task` CLI — `tdd-implementer.md`, `run-quality-checks/SKILL.md`, phases 0, 4, 5, 6, 7
- **Convention**: First mention in each file includes terminology note; CRITICAL instructions explicitly say "go-task `task` CLI" and "via the Bash tool"
- **Rationale**: LLMs can confuse go-task CLI `task` with Claude Code's `Task` tool (sub-agent launcher) or `TaskCreate`/`TaskUpdate` (task list management)

### Exploration Level Adjustment
- **File**: `phases/1-exploration.md`
- **Section**: Step 1.3 (Exploration Scope Decision)
- **Parameters**: Level thresholds, default level (currently Light), user override options
- **Section**: Step 1.4 (Parallel Codebase Exploration)
- **Parameters**: Agent configuration per level (which agents to launch, max_turns per agent — currently 10)
- **Section**: Step 1.5 (Integration & Profile Generation)
- **Parameters**: Light skips integration agent; Medium/Full uses general-purpose integrator (max_turns=10)

### Planning Lightening
- **File**: `phases/2-planning.md`
- **Key design**: Implementation Units are HIGH-LEVEL only (Files, Changes one-line, Dependencies, Model). Detailed how-to belongs in Phase 4.
- **Exception**: Test Plan stays thorough (test case enumeration drives TDD).
- **Parameters**: `task-planner` max_turns (currently 15), default model (currently opus)

### Auto-fix Priority & Parallel Execution
- **Files**: `ai-agent/skills/run-quality-checks/SKILL.md`, `phases/5-quality-checks.md`, `ai-agent/skills/run-quality-checks/output-template.md`
- **Execution Strategy**: 3 sub-steps — Sub-step A (auto-fix sequential), Sub-step B (all checks parallel, raw output only), Sub-step C (trivial summary write)
- **Auto-fix**: Detect fix task variants from `task --list-all`, run fix sequentially (format → lint) to avoid file conflicts
- **Parallel checks**: All in-scope check commands issued as parallel Bash tool calls; each writes raw stdout/stderr to `QC_<CATEGORY>.raw` and the single-line exit code to `QC_<CATEGORY>.exitcode`
- **Summary**: `QC_SUMMARY.md` is derived purely from `.exitcode` files; the legacy `QUALITY_RESULT.md` is no longer produced
- **Category filter**: `--categories=<list>` allows running only specified categories; out-of-scope categories' files remain untouched, preserving prior state for the orchestrator
- **Task list cache**: First invocation writes `<work-dir>/TASK_LIST.txt`; subsequent calls (this skill + `tdd-implementer`) reuse it
- **Parameters**: Category-to-fix-task mapping, execution order, commit behavior

### Retry/Cycle Limits
- **Files**: `SKILL.md`, `phases/5-quality-checks.md`, `phases/7-code-review.md`
- **Parameters**: Max retry counts, cycle limits, escalation behavior

### Sub-agent Prompts
- **Files**: All phase files that launch sub-agents
- **Parameters**: max_turns, return directives, context passing

### Learning Capture / Knowledge Distillation
- **Skill**: `ai-agent/skills/distill-knowledge/SKILL.md`
- **Invoked from**:
  - Phase 6 (background, per round of user feedback)
  - Phase 7 (background, per cycle when Must Fix items exist)
  - Phase 7 → Phase 8 transition (background, fire-and-forget, comprehensive — pre-launched in the "No Must Fix" branch)
  - Phase 8 (fire-and-forget; only launches as a fallback when Phase 7 did not pre-launch)
- **Storage**: Serena Memory `x-coding-best-practices` (cross-session, cross-agent)
- **Consumer**: `tdd-implementer` Pre-Implementation Step 2 reads `x-coding-best-practices`
- **Phase 8 design**: Phase 8 NEVER waits for the distiller and NEVER embeds `LEARNING_SUMMARY.md` in the final report. The summary is referenced by file path only.
- **Considerations**: Pattern quality, deduplication, pruning old entries

### Feedback Validation
- **Files**: `phases/3-approval-gate.md`, `phases/6-user-review.md`
- **Agent**: `ai-agent/agents/feedback-validator.md`
- **Parameters**: Evaluation criteria, classification thresholds, output format

### Profile Management
- **File**: `phases/1-exploration.md`
- **Section**: Step 1 (Project Profile Check)
- **Parameters**: Freshness threshold (currently 30 days), update triggers
- **Note**: Profile is generated/updated by the integration sub-agent (Medium/Full) or a lightweight general-purpose sub-agent (Light, only when needed) in Step 1.5

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
    ├── EXPLORATION_REPORT.md   # Integrated exploration report (or copy of EXPLORATION_CODE.md for Light)
    ├── PLAN.md                 # Work plan + Test Plan (merged)
    ├── TASK_LIST.txt           # Cached `task --list-all` output (reused by sub-agents)
    ├── QC_SUMMARY.md           # Quality check summary (PASS/FAIL per category)
    ├── QC_TEST.raw             # Raw output of test run (per-category, only for executed categories)
    ├── QC_TEST.exitcode        # Single-line exit code (0 = PASS)
    ├── QC_LINT.raw / QC_LINT.exitcode
    ├── QC_ANALYSE.raw / QC_ANALYSE.exitcode
    ├── QC_FORMAT.raw / QC_FORMAT.exitcode
    ├── QC_AUTOFIX.md           # Auto-fix command record (only if auto-fix was applied)
    ├── REVIEW_RESULT.md
    ├── FEEDBACK_VALIDATION.md
    ├── LEARNING_SUMMARY.md
    └── PR_REVIEW_FEEDBACK.md   # PR review comments (Phase 9, append mode)
```
