# Phase 6: Quality Checks

## Step 1: Propose Test Execution Scope

Analyze the changes made during implementation and propose the test execution scope to the user via `AskUserQuestion`:

1. **Changed test files only** — List the specific changed test files.
2. **Specific namespace or directory** — Suggest 1-3 namespace/directory patterns as candidates.
3. **Full test suite** — Run all tests.
4. **User-specified** — User specifies the arguments to pass to the test runner (command is not specified, only arguments).

## Step 2: Run Quality Checks

Launch the `run-quality-checks` skill with the selected scope:

```
Skill("run-quality-checks", args="<work-dir> --test-scope=<scope> --test-args=<args>")
```

**CRITICAL**: The `run-quality-checks` skill MUST use `task` commands if a Taskfile is available. Verify this in the skill's output — if you see `composer`, `npm`, or `make` commands when a Taskfile exists, the skill is not working correctly.

Scope argument examples:
- `--test-scope=changed --test-args=tests/Unit/FooTest.php tests/Unit/BarTest.php`
- `--test-scope=directory --test-args=tests/Unit/Services/`
- `--test-scope=full` (default, same as no scope specified)
- `--test-scope=custom --test-args=--filter=testMethodName`

## Step 3: Handle Results

Read `<work-dir>/QUALITY_RESULT.md` and evaluate the results.

**Verify task usage**: Check that the executed commands in QUALITY_RESULT.md use `task` (e.g., `task test`, `task lint`). If fallback commands were used despite a Taskfile being present, report this as an issue.

### PASS

Proceed to Step 4.

### FAIL

Report the failure details to the user and use `AskUserQuestion` to determine the next action:

1. **AI auto-fix** — Launch `tdd-implementer` sub-agent to fix the issues (provide `<work-dir>/QUALITY_RESULT.md` and `<work-dir>/PLAN.md`). Include **return directive**: "Return ONLY a brief summary (2-3 sentences) of what was fixed. Do NOT include full file contents in your final response." After the fix, return to Step 2 to re-run quality checks. Maximum 3 automatic retry attempts. If the limit is reached, present the remaining options to the user.
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

## Step 5: Record Learnings (Optional)

If learnings were gained during Quality Checks, record them in Serena Memory:

- Test failure patterns and their solutions
- Project-specific notes

```
mcp__plugin_serena_serena__write_memory("quality-check-learnings.md", content)
```

## State Update

Update `STATE.json`: set `currentPhase` to `7`.
