---
description: Provide browser-based user review UI using difit
allowed-tools: Bash(npx difit),Bash(git merge-base),Bash(git status),Bash(git rev-parse),Read,Write
context: fork
---

# User Review Skill

Provides a browser-based diff review UI using difit and collects user feedback.

## Arguments

- `$ARGUMENTS`: `<work-dir>` — Path to the working directory (where `USER_FEEDBACK.md` is saved)

## Workflow

### Step 1: Identify Base Branch

Identify the base branch and determine the comparison reference point.

```bash
# Get current branch name
git rev-parse --abbrev-ref HEAD

# Calculate merge-base with main branch (main or master)
git merge-base HEAD main || git merge-base HEAD master
```

### Step 2: Check Uncommitted Changes

```bash
git status --porcelain
```

If there are uncommitted changes, present the following options via `AskUserQuestion`:

1. **Review committed changes only** — Run `npx difit HEAD <base-ref>`
2. **Include uncommitted changes in review** — Run `npx difit .` (entire working directory)
3. **Skip review** — Proceed to feedback collection only

### Step 3: Run difit

Run difit based on the selection:

```bash
# For committed changes only
npx difit HEAD <base-ref>

# To include uncommitted changes
npx difit .
```

**Note**: difit launches a browser, so wait for user interaction after execution.

### Step 4: Collect Feedback

After review completion in difit, collect feedback via `AskUserQuestion`:

1. **Approve (no feedback)** — Create empty `USER_FEEDBACK.md` and finish
2. **Request changes** — Have user enter specific feedback

### Step 5: Save Feedback

Save user feedback to `<work-dir>/USER_FEEDBACK.md`:

```markdown
# User Feedback

## Date
[timestamp]

## Status
APPROVED / CHANGES_REQUESTED

## Feedback Items
### 1. [Category]
- **File**: [target file (if any)]
- **Issue**: [issue description]
- **Request**: [change request]

## Raw Feedback
[user's original comments]
```

## Output

- `<work-dir>/USER_FEEDBACK.md` — User feedback record

## Error Handling

- If difit is not installed: Suggest `npm install -g difit`
- If not a Git repository: Report error and exit
- If merge-base not found: Ask user for the branch/commit to compare against
