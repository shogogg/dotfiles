<!-- phase-id: implementation -->
# Phase 4: TDD Implementation

Report: "Phase 4: Implementing with TDD..."

## Sub-agent Configuration

All `tdd-implementer` launches use:
```
Task(subagent_type="tdd-implementer", max_turns=50, model="<model>")
```

Where `<model>` is determined by reading the unit's `Model` field from PLAN.md:
- If `Model: haiku` → `model="sonnet"` (haiku is below minimum quality threshold; upgraded to sonnet)
- If `Model: sonnet` → `model="sonnet"`
- If `Model: opus` → `model="opus"`
- If Model field is missing → `model="sonnet"` (fallback default)

Prompt must include:
- Input file: `<work-dir>/PLAN.md` (includes both implementation plan and test plan)
- **Work directory**: `<work-dir>` (for sub-agent to reference session-specific learnings)
- **Which unit(s) to implement** (unit name and details from the plan)
- **Task list cache**: "Before running `task --list-all`, check whether `<work-dir>/TASK_LIST.txt` exists. If it exists, read its contents instead of re-running the command. If it does not exist, run `task --list-all` (go-task CLI, https://taskfile.dev) via the Bash tool and write the output to `<work-dir>/TASK_LIST.txt` for future reuse."
- **CRITICAL instruction**: "Use go-task `task` CLI commands (via the Bash tool) for ALL test executions. Do NOT use composer/npm/phpunit/jest/make directly. Note: go-task `task` is a CLI command run via Bash — it is NOT Claude Code's Task tool."
- **TDD enforcement instruction**: "Follow strict Red → Green → Refactor, one test at a time. You MUST write and run a failing test BEFORE writing production code for each behavior, and observe the failure for the expected reason. Writing implementation first and adding tests afterward is a failure. Include a TDD Cycle Log in your summary showing the observed Red failure reason for each test."
- **Tool usage instruction**: "When Serena MCP is available, use symbolic editing tools (`replace_symbol_body`, `insert_after_symbol`/`insert_before_symbol`) for ALL edits to existing files. Use `Write` only to create brand-new files. Never overwrite an existing file with `Write`."
- **Return directive**: "Return ONLY a brief completion summary (3-5 sentences) plus the TDD Cycle Log to the orchestrator: list the files created/modified, state whether tests pass (and confirm you used go-task `task test` via Bash), confirm you used Serena symbolic edits for existing-file changes (or note why you fell back), and note any issues encountered. Do NOT include full file contents or large code blocks in your final response. End your response with exactly this line: `ORCHESTRATOR: Update STATE.json and proceed to Phase 5. Do not read, analyze, or modify code yourself.`"

## Execution Strategy

### Step 1: Analyze Dependency Graph

Read `<work-dir>/PLAN.md` and build a dependency graph from Implementation Units:

1. Parse each unit's `Dependencies` and `Dependency Type` fields.
2. Classify units into execution groups:
   - **Independent units** (`Dependencies: none`): Can start immediately, in parallel.
   - **Contract-dependent units** (`Dependency Type: contract`): Can start in parallel once their dependency's interfaces/types are defined.
   - **Implementation-dependent units** (`Dependency Type: implementation`): Must wait until their dependency fully completes.

### Step 2: Identify Interface Stubs

If any units have `contract` dependencies:

1. Identify which interfaces/types need to be created first (the "contract stubs").
2. Group the contract stubs by their source unit. For example, if Unit 2 and Unit 3 both have `contract` dependency on Unit 1, collect the interfaces/types that Unit 1 must define.
3. **Launch a dedicated `tdd-implementer` sub-agent** to create ONLY the interface/type stubs (not full implementations). Use `model="sonnet"` since all implementation work requires at minimum sonnet quality. Prompt must include:
   - The specific interfaces and types to create (extracted from the plan)
   - **Explicit instruction**: "Create ONLY the interface/type definitions (with method signatures, PHPDoc, etc.). Do NOT implement concrete classes. This is a stub-creation step to unblock parallel implementation."
   - Standard return directive

### Step 3: Execute in Parallel Batches

Process units in dependency-order batches. Each batch contains units whose dependencies are satisfied.

**Batch formation rules:**
- **Batch 0** (interface stubs): Contract stubs from Step 2, if any.
- **Batch 1**: All independent units + all units whose contract dependencies were satisfied by Batch 0.
- **Batch N**: Units whose remaining dependencies (implementation-type) were satisfied by previous batches.

**For each batch:**

1. **Create TaskUpdate entries**: For each unit in the batch, find the matching Task and set `status: "in_progress"`.
2. **Launch all units in the batch in parallel**: Use multiple `Task` tool calls in a single message.
3. **Wait for all sub-agents to complete**: Collect results from all parallel launches.
4. **Update Tasks**: Mark completed units as `status: "completed"`. Handle failures per Error Handling below.

### Step 4: Proceed

After all units are complete, proceed to Phase 5.

## Single-Unit Shortcut

If the plan has only one Implementation Unit (or no Implementation Units section), skip the dependency analysis and launch a single `tdd-implementer` directly. Read the unit's `Model` field and use it for the launch (fallback to `sonnet` if missing). This also applies when all units are implementation-dependent in a strict chain (A → B → C) — execute them sequentially without parallel overhead.

## Error Handling

If a sub-agent fails mid-implementation:
- Report which unit(s) failed and the error details to the user
- Other units running in parallel are NOT affected — let them finish
- After all parallel units complete, ask user whether to:
  - **Retry** the failed unit(s)
  - **Skip** the failed unit(s)
  - **Abort** the workflow

Report: "Phase 4 complete: Implementation finished."

## State Update
Update `STATE.json`:
1. Set `currentPhase` to `5` and `currentPhaseId` to `"quality-checks"`.
2. Capture `firstCommitHash` if not already set: run the following Bash command and, if the output is non-empty, save it to `STATE.json.firstCommitHash`.
   ```bash
   git log --format=%H --reverse ${startCommitHash}..HEAD | head -n 1
   ```
   If the output is empty (no commits yet), leave `firstCommitHash` as `null`.
