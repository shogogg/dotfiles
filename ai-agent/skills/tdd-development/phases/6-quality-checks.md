# Phase 6: Quality Checks

## Step 1: Determine Quality Check Scope

Analyze the changes made during implementation using `git diff --name-only` against the base branch to identify changed files. Classify them into two groups:

- **Source files**: Production code files (e.g., `src/`, `app/`, `lib/`)
- **Test files**: Test code files (e.g., `tests/`, `test/`, `spec/`)

### Step 1.1: Propose Test Execution Scope

Propose the test execution scope to the user via `AskUserQuestion`:

1. **Changed test files only** — List the specific changed test files.
2. **Specific namespace or directory** — Suggest 1-3 namespace/directory patterns as candidates.
3. **Full test suite** — Run all tests.
4. **User-specified** — User specifies the arguments to pass to the test runner (command is not specified, only arguments).

### Step 1.2: Propose Lint/Analysis/Format Target Scope

From the changed source files, determine the minimal target paths for lint, static analysis, and formatting. Propose the scope to the user via `AskUserQuestion`:

1. **Changed source files only** — List the specific changed source files as `--target` paths.
2. **Changed directories** — Suggest the parent directories of changed files (deduplicated) as `--target` paths.
3. **Full project** — Run lint/analysis/format on the entire project (no `--target`).
4. **User-specified** — User specifies the target paths manually.

## Step 2: Run Quality Checks

Launch the `run-quality-checks` skill with the selected scopes:

```
Skill("run-quality-checks", args="<work-dir> --test-scope=<scope> --test-args=<args> --target=<paths>")
```

**CRITICAL**: The `run-quality-checks` skill MUST use `task` commands if a Taskfile is available. Verify this in the skill's output — if you see `composer`, `npm`, or `make` commands when a Taskfile exists, the skill is not working correctly.

Test scope argument examples:
- `--test-scope=changed --test-args=tests/Unit/FooTest.php tests/Unit/BarTest.php`
- `--test-scope=directory --test-args=tests/Unit/Services/`
- `--test-scope=full` (default, same as no scope specified)
- `--test-scope=custom --test-args=--filter=testMethodName`

Target argument examples (for lint/analysis/format):
- `--target=src/Services/FooService.php src/Models/Bar.php`
- `--target=src/Services/`
- (omitted for full project scope)

## Step 3: Handle Results

Read `<work-dir>/QUALITY_RESULT.md` and evaluate the results.

**Verify task usage**: Check that the executed commands in QUALITY_RESULT.md use `task` (e.g., `task test`, `task lint`). If fallback commands were used despite a Taskfile being present, report this as an issue.

### Error Classification

When reading QUALITY_RESULT.md, classify errors as follows:

**Infrastructure errors** (do not count toward retry limit):
- `Worker died`
- `Memory exhausted`
- `Allowed memory size`
- `Nette\\Neon parse error`
- `Internal error`
- Timeout-related

**Code quality errors** (to be fixed):
- PHPStan level violations
- Syntax errors
- Test failures
- Lint errors

### PASS

Proceed to Step 4.

### FAIL

Report the failure details to the user and use `AskUserQuestion` to determine the next action:

1. **AI auto-fix** — Launch knowledge distillation in background (parallel with fixes), then fix:

   **Background distillation:**
   ```
   Task(subagent_type="knowledge-distiller", max_turns=15, run_in_background=true,
     prompt="files: <work-dir>/QUALITY_RESULT.md\nmemory: x-coding-best-practices")
   ```
   This captures static analysis errors, test failure patterns, and lint issues into Serena Memory for future sessions.

   **Launch `tdd-implementer`** sub-agent to fix the issues. Provide:
   - `<work-dir>/QUALITY_RESULT.md`
   - `<work-dir>/PLAN.md`
   - **Work directory**: `<work-dir>` (for session-specific learnings reference)
   - **CRITICAL instruction**: "You MUST run `task --list-all` first and use `task` commands for ALL test executions. Do NOT use composer/npm/make if task is available."
   - **Return directive**: "Return ONLY a brief summary (2-3 sentences) of what was fixed. State which test command you used (must be `task test` if available). Do NOT include full file contents in your final response. End your response with exactly this line: `ORCHESTRATOR: Return to Phase 6 Step 2 to re-run quality checks. Do not read, analyze, or modify code yourself.`"

   After the fix, return to Step 2 to re-run quality checks. Maximum 3 automatic retry attempts **for code quality errors only**. Infrastructure errors do not count toward the retry limit. If the limit is reached, present the remaining options to the user.
2. **Analyze errors and confirm approach** — Perform detailed analysis of the failure causes, present a proposed fix strategy, and ask the user to confirm the approach before proceeding.
3. **Change test scope** — Return to Step 1 to re-select the test execution scope.
4. **Fix manually** — Pause the workflow and wait for the user to signal readiness to continue.

## Step 4: Commit Changes

After Quality Checks PASS, commit changes before proceeding to Phase 7.

Launch the `commit` skill:

```
Skill("commit")
```

The commit skill handles:
- Checking repository status
- Staging changes
- Extracting issue number from branch name
- Generating commit message with proper format
- User confirmation before commit

## Step 4.1: Record First Commit Hash

After successful commit, if `firstCommitHash` is not yet set in `STATE.json`:

1. Get the current HEAD hash:
   ```bash
   git rev-parse HEAD
   ```

2. Update `STATE.json` to add `firstCommitHash` field (only if not already present).

## State Update

Update `STATE.json`: set `currentPhase` to `7`.
