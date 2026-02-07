# Phase 9: Final Report

Report: "Phase 9: Generating final report..."

## Step 0: Squash Commits

Consolidate all commits created during this session into a single commit.

### 0.1 Read State Information

Read `STATE.json` and retrieve:
- `startCommitHash`: HEAD at session start
- `firstCommitHash`: Hash of the first commit created in this session

If `firstCommitHash` does not exist (no commits were made), skip to Step 1.

### 0.2 Check Commit Count

```bash
COMMIT_COUNT=$(git rev-list --count ${startCommitHash}..HEAD)
```

- If `COMMIT_COUNT <= 1`: No squash needed, skip to Step 1
- If `COMMIT_COUNT >= 2`: Proceed with squash confirmation

### 0.3 Get First Commit Message

```bash
FIRST_COMMIT_MSG=$(git log --format=%B -n 1 ${firstCommitHash})
```

### 0.4 User Confirmation

Use `AskUserQuestion` to confirm squash operation:

**Options** (user-facing, in Japanese):
1. **統合する** — Squash commits using the first commit message
2. **統合しない** — Keep the current commit history

### 0.5 Execute Squash (if user selected "統合する")

```bash
# Soft reset to preserve changes while undoing commits
git reset --soft ${startCommitHash}

# Re-commit with the first commit message
git commit -m "${FIRST_COMMIT_MSG}"
```

### 0.6 Report Result

Report to user:
- Number of commits before squash
- Final commit message used

## Step 1: Comprehensive Knowledge Distillation (Background)

Launch the `knowledge-distiller` sub-agent **in background** to distill all session learnings into Serena Memory (`x-coding-best-practices`) while compiling the final report in parallel.

### 1.1 Invoke Sub-Agent

```
Task(subagent_type="knowledge-distiller", max_turns=15, run_in_background=true,
  prompt="files: <work-dir>/QUALITY_RESULT.md <work-dir>/REVIEW_RESULT.md <work-dir>/USER_FEEDBACK.md\nmemory: x-coding-best-practices\noutput: <work-dir>/LEARNING_SUMMARY.md")
```

Save the returned `task_id` for later retrieval.

The sub-agent will:
- Read all available session files (skips any that do not exist)
- Merge with any patterns already added during Phase 6/7/8 distillation cycles
- Write consolidated patterns to Serena Memory `x-coding-best-practices`
- Write `<work-dir>/LEARNING_SUMMARY.md`

## Step 2: Compile Final Report (Parallel with Step 1)

Begin compiling the final report immediately — do NOT wait for the knowledge distiller to finish.

### 2.0 Gather Tasks Summary

Call `TaskList` to retrieve all Tasks. Group them by naming prefix to populate the "Work Items (Tasks)" section:
- **Implementation Units**: Tasks with subject starting with `"Implement Unit"` or `"Implement:"`
- **Code Review Fixes**: Tasks with subject starting with `"Fix CR-"`
- **User Feedback Fixes**: Tasks with subject starting with `"Fix UF-"`

Count completed vs total for each group.

### 2.1 Wait for Knowledge Distiller

After assembling all other sections of the report, wait for the background distiller to complete:

```
TaskOutput(task_id=..., block=true, timeout=120000)
```

Then read `<work-dir>/LEARNING_SUMMARY.md` and embed it in the report.

Present to the user:

```markdown
## Implementation Summary
- **Task**: [original task description]
- **Files changed**: [list of created/modified files]
- **Key changes**: [brief summary of what was implemented]

## Test Results
- **Status**: PASS / FAIL
- **Details**: [pass/fail counts from last quality check]

## Review Record
- **Must Fix**: [count and resolution status]
- **Consider**: [count and brief notes]
- **Ignorable**: [count]
- **User Review**: Approved / Approved after N revision(s)
- **Cycles used**: N/3

## Work Items (Tasks)
- **Implementation Units**: <completed>/<total>
- **Code Review Fixes**: <completed>/<total>
- **User Feedback Fixes**: <completed>/<total>

## Commits Created
[List of commits created during this session with their messages]

## Learnings Summary
[Embed contents of LEARNING_SUMMARY.md here]

## Next Steps
- [ ] Review the commits in git log
- [ ] Push to remote when ready
- [ ] Create PR if needed
```

## State Update
Update `STATE.json`: set `currentPhase` to `10`.
