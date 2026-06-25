<!-- phase-id: quality-checks -->
# Phase 5: Quality Checks

## Step 1: Determine Quality Check Scope

Read `<work-dir>/STATE.json` and inspect the `qualityScope` field:

- **`qualityScope` is non-null and complete** (has both `test` and `target` sub-objects):
  - **Reuse the saved scope.** Skip Step 1.1 and Step 1.2.
  - Briefly inform the user in Japanese: `前回のスコープを再利用します: test=<scope> target=<mode>`
  - Proceed directly to Step 2.
- **`qualityScope` is null or incomplete**:
  - Proceed with Step 1.1 and Step 1.2 to collect the user's choice, then **save the result** to `STATE.json.qualityScope` before continuing to Step 2.

Analyze the changes made during implementation using `git diff --name-only` against the base branch (or against `lastReviewCommit` when returning from Phase 6/7/9) to identify changed files. Classify them into two groups:

- **Source files**: Production code files (e.g., `src/`, `app/`, `lib/`)
- **Test files**: Test code files (e.g., `tests/`, `test/`, `spec/`)

### Step 1.1: Propose Test Execution Scope

Propose the test execution scope to the user via `AskUserQuestion`:

1. **Changed test files only** — List the specific changed test files.
2. **Specific namespace or directory** — Suggest 1-3 namespace/directory patterns as candidates.
3. **Full test suite** — Run all tests.
4. **User-specified** — User specifies the arguments to pass to the test runner (command is not specified, only arguments).

Save the selection to `STATE.json.qualityScope.test = { scope: "<full|changed|directory|custom>", args: "<args-string>" }`.

### Step 1.2: Propose Lint/Analysis/Format Target Scope

From the changed source files, determine the minimal target paths for lint, static analysis, and formatting. Propose the scope to the user via `AskUserQuestion`:

1. **Changed source files only** — List the specific changed source files as `--target` paths.
2. **Changed directories** — Suggest the parent directories of changed files (deduplicated) as `--target` paths.
3. **Full project** — Run lint/analysis/format on the entire project (no `--target`).
4. **User-specified** — User specifies the target paths manually.

Save the selection to `STATE.json.qualityScope.target = { mode: "<full|files|directories|custom>", paths: [<paths>] }`.

## Step 2: Run Quality Checks

Read `STATE.json.qualityFailedCategories`:

- **Empty or absent** (first run, or last run was PASS): Run ALL categories (no `--categories` filter).
- **Non-empty** (retry after partial failure): Pass `--categories=<comma-separated list>` so only the previously-failed categories re-run. Previously-passed categories' `QC_<CATEGORY>.exitcode` files remain intact, so the overall state is still recoverable from disk.

Launch the `run-quality-checks` skill with the resolved scope and category filter:

```
Skill("run-quality-checks", args="<work-dir> --test-scope=<scope> --test-args=<args> --target=<paths> [--categories=<failed>]")
```

**CRITICAL**: The `run-quality-checks` skill MUST use go-task `task` CLI commands (via Bash) if a Taskfile is available. Verify this in the skill's output — if you see `composer`, `npm`, or `make` commands when a Taskfile exists, the skill is not working correctly.

Test scope argument examples:
- `--test-scope=changed --test-args=tests/Unit/FooTest.php tests/Unit/BarTest.php`
- `--test-scope=directory --test-args=tests/Unit/Services/`
- `--test-scope=full` (default, same as no scope specified)
- `--test-scope=custom --test-args=--filter=testMethodName`

Target argument examples (for lint/analysis/format):
- `--target=src/Services/FooService.php src/Models/Bar.php`
- `--target=src/Services/`
- (omitted for full project scope)

Categories argument examples (for retry):
- `--categories=test,lint` (re-run only test and lint after a fix)
- `--categories=analyse` (re-run only static analysis)
- (omitted on first run — runs all detected categories)

## Step 2.5: Commit Auto-fix Changes (if applicable)

After quality checks complete, read `<work-dir>/QC_SUMMARY.md` and check the `Auto-fix Applied` field in the Summary section.

**If `Auto-fix Applied: YES`:**

1. Check for uncommitted changes:
   ```bash
   git diff --stat
   ```

2. If there are changes, commit them automatically using the `commit` skill:
   ```
   Skill("commit")
   ```
   The commit message should indicate these are auto-fix changes (e.g., `style: apply auto-fix (lint/format)`).

3. Record `firstCommitHash` if not yet set (same logic as Step 4.1).

**If `Auto-fix Applied: NO`:** Skip this step.

**Note**: This commit is separate from the Step 4 commit. Auto-fix changes are committed immediately so that subsequent quality check results reflect the fixed state.

## Step 3: Handle Results

Read `<work-dir>/QC_SUMMARY.md` to get the overall PASS/FAIL state and per-category status. When investigating failure details, read the specific raw output file `<work-dir>/QC_<CATEGORY>.raw`. Exit codes can also be read directly from `<work-dir>/QC_<CATEGORY>.exitcode` (single-line file).

**Verify go-task usage**: Check that the executed commands recorded in `QC_SUMMARY.md` (and the raw outputs) use go-task `task` CLI (e.g., `task test`, `task lint`). If fallback commands were used despite a Taskfile being present, report this as an issue.

### Update Failed Category Tracking (REQUIRED)

After reading results, update `STATE.json.qualityFailedCategories`:

- **Overall PASS**: Set `qualityFailedCategories = []` (cleared).
- **Overall FAIL**: Set `qualityFailedCategories = [<list of categories whose .exitcode is non-zero>]`. Use the per-category `.exitcode` files (not just the current invocation's results — pre-existing failing categories that were not re-run this round retain their failing state).

### Error Classification

When reading `QC_<CATEGORY>.raw` for failure details, classify errors as follows:

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

Report the failure details to the user (read excerpts from the relevant `QC_<CATEGORY>.raw` files) and use `AskUserQuestion` to determine the next action:

1. **AI auto-fix** — Launch knowledge distillation in background (parallel with fixes), then fix:

   **Background distillation:**
   ```
   Task(subagent_type="knowledge-distiller", max_turns=15, run_in_background=true,
     prompt="files: <work-dir>/QC_SUMMARY.md <work-dir>/QC_TEST.raw <work-dir>/QC_LINT.raw <work-dir>/QC_ANALYSE.raw <work-dir>/QC_FORMAT.raw\nmemory: x-coding-best-practices")
   ```
   (Include only the raw files that exist and correspond to failed categories.) This captures static analysis errors, test failure patterns, and lint issues into Serena Memory for future sessions.

   **Launch `tdd-implementer`** sub-agent to fix the issues. Provide:
   - `<work-dir>/QC_SUMMARY.md` (overall status)
   - `<work-dir>/QC_<CATEGORY>.raw` for each failed category (detailed errors)
   - `<work-dir>/PLAN.md`
   - **Work directory**: `<work-dir>` (for session-specific learnings reference)
   - **Task list cache**: "If `<work-dir>/TASK_LIST.txt` exists, read it instead of running `task --list-all` again."
   - **CRITICAL instruction**: "You MUST use go-task `task` CLI commands (via the Bash tool) for ALL test executions. Do NOT use composer/npm/phpunit/jest/make directly. Note: go-task `task` is a CLI command run via Bash — it is NOT Claude Code's Task tool."
   - **Return directive**: "Return ONLY a brief summary (2-3 sentences) of what was fixed. State which test command you used (must be go-task `task test` via Bash). Do NOT include full file contents in your final response. End your response with exactly this line: `ORCHESTRATOR: Return to Phase 5 Step 2 to re-run quality checks (only failed categories will be re-run). Do not read, analyze, or modify code yourself.`"

   After the fix, return to Step 2 to re-run quality checks. Maximum 3 automatic retry attempts **for code quality errors only**. Infrastructure errors do not count toward the retry limit. If the limit is reached, present the remaining options to the user.

2. **Analyze errors and confirm approach** — Perform detailed analysis of the failure causes, present a proposed fix strategy, and ask the user to confirm the approach before proceeding.

3. **Change scope** — Reset `STATE.json.qualityScope` to `null`, then return to Step 1 to re-select the test execution scope and target scope.

4. **Fix manually** — Pause the workflow and wait for the user to signal readiness to continue.

## Step 4: Commit Changes

After Quality Checks PASS, commit changes before proceeding to Phase 6 (User Review).

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

Update `STATE.json`: set `currentPhase` to `6` and `currentPhaseId` to `"user-review"`.
