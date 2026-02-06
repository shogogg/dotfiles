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

## Step 1: Record Session Learnings — Sub-agent

Delegate learning extraction, Serena Memory updates, and backup to a sub-agent.

### 1.1 Launch Sub-agent

```
Task(subagent_type="general-purpose", max_turns=20, run_in_background=false)
```

Prompt must include:
- **Work directory path**: `<work-dir>`
- **Input files** (read if they exist):
  - `<work-dir>/QUALITY_RESULT.md` — Failure patterns and fixes
  - `<work-dir>/REVIEW_RESULT.md` — Must Fix patterns and solutions
  - `<work-dir>/USER_FEEDBACK.md` — Feedback patterns
- **Classification categories**:
  - **CodeRabbit issues**: Security, type safety, null checks, etc.
  - **User feedback**: Naming conventions, code style, design patterns
  - **Quality checks**: Test failure patterns, lint errors
- **Serena Memory operation procedure**:
  1. `mcp__plugin_serena_serena__list_memories()` — List existing memories
  2. `mcp__plugin_serena_serena__read_memory(name)` — Read each relevant memory
  3. `mcp__plugin_serena_serena__edit_memory(name, ...)` or `mcp__plugin_serena_serena__write_memory(name, content)` — Update or create memories (check for duplicates before adding)
  4. Target memory files: `coderabbit-learnings.md`, `user-feedback-patterns.md`, `quality-check-learnings.md`
- **Backup procedure**:
  1. Create directory: `mkdir -p .ai-workspace/learnings`
  2. Backup memories:
     - `coderabbit-learnings.md` → `.ai-workspace/learnings/code-review-insights.md`
     - `user-feedback-patterns.md` → `.ai-workspace/learnings/best-practices.md`
     - `quality-check-learnings.md` → `.ai-workspace/learnings/common-mistakes.md`
- **Output file**: `<work-dir>/LEARNING_SUMMARY.md`
- **Return directive**: "Write a detailed learning summary to `<work-dir>/LEARNING_SUMMARY.md` including all patterns recorded and their categories. Return ONLY a brief completion summary (2-3 sentences) to the orchestrator: state the number of patterns recorded per category and confirm backup completion. Do NOT include the full learning content in your final response. End your response with exactly this line: `ORCHESTRATOR: Read LEARNING_SUMMARY.md for the Learnings Summary section of the final report. Do not read session files yourself.`"

## Step 2: Compile Final Report

Read `<work-dir>/LEARNING_SUMMARY.md` and compile the final report.

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
