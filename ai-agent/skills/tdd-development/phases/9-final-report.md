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

## Step 1: Collect Session Learnings

Collect learnings from this session.

### 1.1 Extract Learnings from Session Files

Read the following files if they exist and extract patterns:

- `<work-dir>/QUALITY_RESULT.md` — Failure patterns and fixes
- `<work-dir>/REVIEW_RESULT.md` — Must Fix patterns and solutions
- `<work-dir>/USER_FEEDBACK.md` — Feedback patterns

### 1.2 Classify Learning Patterns

Classify extracted patterns into the following categories:

- **CodeRabbit issues**: Security, type safety, null checks, etc.
- **User feedback**: Naming conventions, code style, design patterns
- **Quality checks**: Test failure patterns, lint errors

## Step 2: Update Serena Memory

Persist collected learnings to Serena Memory.

### 2.1 Check Existing Memory

```
mcp__plugin_serena_serena__list_memories()
```

### 2.2 Update Each Memory

**coderabbit-learnings.md**:
```
mcp__plugin_serena_serena__read_memory("coderabbit-learnings.md")
```
Read existing content and add new patterns (check for duplicates):
```
mcp__plugin_serena_serena__edit_memory("coderabbit-learnings.md", ...)
```
Or create new:
```
mcp__plugin_serena_serena__write_memory("coderabbit-learnings.md", content)
```

Update the following similarly:
- `user-feedback-patterns.md`
- `quality-check-learnings.md`

## Step 3: Backup to .ai-workspace/learnings/

Backup updated Memory to files.

### 3.1 Verify Directory

```bash
mkdir -p .ai-workspace/learnings
```

### 3.2 Backup

Backup the following Memories if they exist:
- `coderabbit-learnings.md` → `.ai-workspace/learnings/code-review-insights.md`
- `user-feedback-patterns.md` → `.ai-workspace/learnings/best-practices.md`
- `quality-check-learnings.md` → `.ai-workspace/learnings/common-mistakes.md`

## Step 4: Compile Final Report

Compile and present to the user:

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

## Commits Created
[List of commits created during this session with their messages]

## Learnings Summary
- **New patterns recorded**: X patterns
- **Breakdown by category**:
  - CodeRabbit issues: N items
  - User feedback: N items
  - Quality checks: N items
- **Backup location**: `.ai-workspace/learnings/`

## Next Steps
- [ ] Review the commits in git log
- [ ] Push to remote when ready
- [ ] Create PR if needed
```

## State Update
Update `STATE.json`: set `currentPhase` to `10`.
