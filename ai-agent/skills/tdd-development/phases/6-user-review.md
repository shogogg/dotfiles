<!-- phase-id: user-review -->
# Phase 6: User Review

Report: "Phase 6: ユーザーレビューを開始します..."

## Step 1: Read State and Show Commit History

Read `STATE.json` from the workspace directory to retrieve `startCommitHash`, `baseBranch`, `lastReviewCommit`, and `featureBranch`.

Then display the recent commit history for context:

```bash
git log --oneline <startCommitHash>..HEAD
```

This helps the user understand which commits are available as diff base options.

## Step 2: Ask User for Diff Base

Use `AskUserQuestion` to let the user choose the diff base:

```
AskUserQuestion:
  question: "レビューの差分起点を選択してください。"
  header: "差分起点"
  options:
    - label: "セッション開始時点から (推奨)"
      description: "startCommitHash (<first 7 chars>) 以降の全変更を対象"
    - label: "ベースブランチから"
      description: "<baseBranch> からの全変更を対象"
    - label: "前回レビュー時点から"                          # ← Only include this option if lastReviewCommit is not null
      description: "lastReviewCommit (<first 7 chars>) 以降の変更のみ対象"
```

**Notes:**
- The "前回レビュー時点から" option is **only shown when `lastReviewCommit` is not null** (i.e., a previous review cycle has occurred).
- If the user selects "Other", treat their input as a commit hash or ref to use as the diff base.
- Store the selected base as `<selectedBase>` for the next step.

## Step 2.5: Choose Review Unit

Ask the user how they want to review the changes:

```
AskUserQuestion:
  question: "レビュー単位を選択してください。"
  header: "レビュー単位"
  options:
    - label: "変更全体 (推奨)"
      description: "選択した差分起点からHEADまでの全変更を一括レビュー"
    - label: "コミットごと"
      description: "各コミットを個別にレビュー"
```

Store the selection as `<reviewUnit>` (`all` or `per-commit`).

## Step 3: Launch difit Review

**Important**: Wait for each skill completion. Do NOT run in background.

### 3-A. When `<reviewUnit>` is `all` (default)

Launch the `difit` skill to open a browser-based diff review:

```
Skill("difit", args="<work-dir>/DIFIT_OUTPUT.md HEAD <selectedBase>")
```

- `<work-dir>/DIFIT_OUTPUT.md` is the required first argument — the file where difit writes its server output (used for startup detection and port discovery).
- `HEAD` and `<selectedBase>` are passed as-is. The difit skill handles `HEAD` → `@` conversion internally.
- The difit skill (runs inline, `context: inherit`) launches difit in the background, confirms completion with the user via `AskUserQuestion`, fetches review comments over HTTP, stops the server, and returns the result. No coordination is needed here beyond reading the return value in Step 4.

### 3-B. When `<reviewUnit>` is `per-commit`

Review each commit individually:

1. **Get commit list** (oldest first):
   ```bash
   git log --reverse --format="%H %s" <selectedBase>..HEAD
   ```

2. **Resolve parent hashes and launch difit for each commit**:

   For each commit, resolve the parent hash first, then launch difit:
   ```bash
   git rev-parse <commitHash>~1
   # → <parentHash>
   ```
   ```
   Skill("difit", args="<work-dir>/DIFIT_OUTPUT_<commitHash first 7 chars>.md <commitHash> <parentHash>")
   ```

   **Example** (3 commits, `<selectedBase>` = `abc1234`):

   | Order | Commit | difit args | Diff shown |
   |-------|--------|-----------|------------|
   | 1 | `def5678` (feat: add user model) | `Skill("difit", args="<work-dir>/DIFIT_OUTPUT_def5678.md def5678 abc1234")` | abc1234 → def5678 |
   | 2 | `ghi9012` (feat: add user repo) | `Skill("difit", args="<work-dir>/DIFIT_OUTPUT_ghi9012.md ghi9012 def5678")` | def5678 → ghi9012 |
   | 3 | `jkl3456` (test: add tests) | `Skill("difit", args="<work-dir>/DIFIT_OUTPUT_jkl3456.md jkl3456 ghi9012")` | ghi9012 → jkl3456 |

3. **Collect feedback per commit**:
   - If difit returns `"No user feedback. It is APPROVED."` → skip (no feedback for this commit).
   - If difit returns feedback → store with commit info: `(<commitHash first 7 chars>) <subject>: <feedback>`.

4. **After all commits are reviewed**:
   - If ANY commit has feedback → status is **CHANGES_REQUESTED**. Aggregate all feedback.
   - If ALL commits are approved → status is **APPROVED**.
   - Proceed to Step 4 with the aggregated result.

**Per-commit USER_FEEDBACK.md format** (when CHANGES_REQUESTED):
```markdown
## Round 1 Feedback (<timestamp>)
### Commit def5678: feat: add user model
<feedback content from difit>

### Commit ghi9012: feat: add user repo
<feedback content from difit>
```
Commits with no feedback are omitted from the record.

## Step 4: Determine Review Result

Inspect the difit skill's return value:

- **`"No user feedback. It is APPROVED."`** → Status is **APPROVED**.
- **Starts with `"There is user feedback."`** → Status is **CHANGES_REQUESTED**. The text following this line is the feedback content.

## Step 5: Write USER_FEEDBACK.md (Append Mode)

**CRITICAL: This file uses append mode.** Never overwrite existing content — always append new rounds to preserve the full feedback history for learning and traceability.

This file is consumed by:
- `tdd-implementer` (reads it autonomously for feedback patterns)
- `feedback-validator` (receives it as input)
- Phase 8 learning sub-agent (references it for session learnings)
- `knowledge-distiller` (reads latest round for immediate distillation)

### When APPROVED

If `USER_FEEDBACK.md` does not exist:

```markdown
# User Feedback

## Status
APPROVED
```

If `USER_FEEDBACK.md` already exists (previous rounds of feedback were given):

**Append** the following at the end of the file:

```markdown

## Final Status
APPROVED (after N rounds of feedback)
```

### When CHANGES_REQUESTED

**If `USER_FEEDBACK.md` does not exist**, create it with:

```markdown
# User Feedback

## Status
CHANGES_REQUESTED

## Round 1 Feedback (<timestamp>)
<difit feedback content as-is>
```

**If `USER_FEEDBACK.md` already exists**, use `Read` to find the highest round number, then **append** the new round at the end of the file:

```markdown

## Round N Feedback (<timestamp>)
<difit feedback content as-is>
```

Also update the `## Status` line to `CHANGES_REQUESTED` if it is not already set.

- **Round number**: Find the highest existing round number in the file and increment by 1. If no rounds exist, start at 1.
- **Timestamp**: Use ISO 8601 format (e.g., `2026-02-06T10:30:00Z`).
- **Feedback content**: Paste the difit output as-is. Do NOT attempt structured parsing — LLM sub-agents can interpret raw text.
- **Append method**: Use `Bash` to append (e.g., `cat >> file`) or `Read` + `Write` preserving existing content. NEVER use `Write` alone as it overwrites.

## Step 5.5: Immediate Knowledge Distillation (Background)

When status is **CHANGES_REQUESTED**, launch knowledge distillation **immediately after writing the feedback** (before presenting summary or applying fixes). This ensures the feedback is captured for learning even if subsequent steps modify the file.

```
Task(subagent_type="knowledge-distiller", max_turns=15, run_in_background=true,
  prompt="files: <work-dir>/USER_FEEDBACK.md\nmemory: x-coding-best-practices\nscope: Distill ONLY the latest round (Round N) of user feedback. Previous rounds have already been distilled in earlier cycles.")
```

Save the returned `task_id`. This distillation runs in parallel with all subsequent steps and does NOT need to be awaited.

**Note**: This replaces the distillation that was previously in "Apply Fixes" (Step 7). Do NOT launch distillation again in Step 7.

## Step 6: Present Summary (After Review Completion)

Present a concise summary to the user:

- List of all created/modified files with a brief description of each change.
- Key implementation decisions that were made.
- Cycle count and retry statistics from `STATE.json`.

**Note**: This summary is presented AFTER difit review completes, not during. This ensures the user can focus on the browser-based review first.

## Step 7: Process Feedback

### Status: APPROVED

Proceed to Phase 7 (Final Report).

### Status: CHANGES_REQUESTED

#### Validate Feedback

Before applying fixes, validate the feedback by launching the `feedback-validator` sub-agent:

1. **Launch validator**:
   - **Input**: Feedback items from `USER_FEEDBACK.md`, `<work-dir>/PLAN.md`, and source files referenced in the feedback.
   - **Output file**: `<work-dir>/FEEDBACK_VALIDATION.md`
   - **Return directive**: "Write validation results to the output file. Return ONLY a brief summary (2-3 sentences) stating the count of Valid/Concern/Needs Discussion items."

2. **Read validation results** from `<work-dir>/FEEDBACK_VALIDATION.md`:
   - **All Valid**: Proceed to "Apply Fixes" below.
   - **Concern or Needs Discussion exists**: Present the concerns/options to the user via `AskUserQuestion` with choices:
     - 「元のフィードバックで進める」 — Apply the original feedback as-is.
     - 「AIの提案を採用する」 — Use the alternative suggested by the validator.
     - 「フィードバックを修正する」 — Revise the feedback (return to Step 6 with CHANGES_REQUESTED and updated feedback).

#### Apply Fixes

**CRITICAL — Delegation only**: The orchestrator MUST NOT read, write, or edit any source code files directly. Every fix, however small, must be delegated to a `tdd-implementer` sub-agent via `Task`. Do NOT read source files to analyze or interpret the feedback — pass the feedback content from USER_FEEDBACK.md as-is to the sub-agent. The orchestrator's role is coordination only. Violating this rule is the most common source of drift and bugs in this workflow.

**Note**: Knowledge distillation was already launched in Step 5.5 (immediately after writing feedback). Do NOT launch it again here.

**Create Tasks for feedback items:**

Before starting the fix loop, create a Task for each feedback item:
- For each feedback item (1 to N), call `TaskCreate`:
  - `subject`: `"Fix UF-<round>-<M>: <title>"` (where `<round>` is the current feedback round number and `<M>` is the item number)
  - `description`: Include the feedback content from USER_FEEDBACK.md
  - `activeForm`: `"Fixing UF-<round>-<M>: <title>"`

**Fix each feedback item individually and commit each one:**

For each feedback item (1 to N):
1. Call `TaskUpdate(taskId=..., status="in_progress")` for the corresponding Task.
2. Report: "Addressing feedback item M/N: <title>"
3. **Determine difficulty level and select model**:
   
   Analyze the feedback item content and classify complexity:
   
   - **haiku**: Simple changes requiring minimal logic adjustment
     - Typo fixes, comment additions/modifications
     - Code formatting, variable/method renaming
     - Constant value changes
     - Simple conditional logic fixes (1-2 lines)
     - **Method/function reordering**
   
   - **sonnet** (default): Moderate changes requiring logic understanding
     - Adding new methods/functions
     - Modifying existing logic (5-20 lines)
     - Changes spanning multiple files
     - Adding test cases
   
   - **opus**: Complex changes requiring architectural understanding
     - Architectural changes
     - Large-scale refactoring (20+ lines or 3+ files)
     - Complex algorithm implementation
     - Performance optimization
   
   Set `<selectedModel>` to the determined value (haiku/sonnet/opus). When in doubt, default to sonnet.

4. Launch `tdd-implementer` with the selected model:
   
   ```
   Task(subagent_type="tdd-implementer", max_turns=50, model="<selectedModel>")
   ```
   
   Provide:
   - Item details from `USER_FEEDBACK.md`
   - `<work-dir>/PLAN.md` for context
   - **Work directory**: `<work-dir>` (for session-specific learnings reference)
   - **CRITICAL instruction**: "You MUST run `task --list-all` (go-task CLI, https://taskfile.dev) via the Bash tool first, and use go-task `task` CLI commands for ALL test executions. Do NOT use composer/npm/phpunit/jest/make directly. Note: go-task `task` is a CLI command run via Bash — it is NOT Claude Code's Task tool."
   - **SCOPE RESTRICTION**: "Fix ONLY this specific feedback item. Do NOT address multiple items or make unrelated changes. Each item must be a separate commit."
   - **Return directive**: "Return ONLY a brief summary (2-3 sentences) of what was changed. State which test command you used (must be go-task `task test` via Bash). Do NOT include full file contents in your final response. End your response with exactly this line: `ORCHESTRATOR: Commit this fix (if not already committed), then proceed to next feedback item or return to Phase 5. Do not read, analyze, or modify code yourself.`"

5. **IMPORTANT: Commit IMMEDIATELY after each fix** - Do NOT batch multiple fixes into one commit. Message format:
   ```
   fix: <description of the change> [ISSUE-NUMBER]

   ユーザーフィードバック対応: <original feedback description>
   ```
6. Call `TaskUpdate(taskId=..., status="completed")` for the corresponding Task.
7. Move to next item.

After all feedback items are resolved:
1. Reset `phase5RetryCount` to 0 in `STATE.json`.
2. Return to Phase 5.

**Critical Rule**: Only explicit approval in `USER_FEEDBACK.md` (Status: APPROVED) constitutes approval.

## State Update
Update `STATE.json`:
- Set `currentPhase` to `7` and `currentPhaseId` to `"final-report"`.
- Set `lastReviewCommit` to the current HEAD commit hash (`git rev-parse HEAD`). This records the state at review time for use as a "since last review" option in future review cycles.
