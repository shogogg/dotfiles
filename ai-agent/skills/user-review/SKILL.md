---
description: Provide browser-based user review UI using difit
allowed-tools: Bash(npx difit),Bash(git merge-base),Bash(git status),Bash(git rev-parse),Read,Write,AskUserQuestion
context: fork
---

# User Review Skill

Provides a browser-based diff review UI using difit and collects user feedback.

## Arguments

- `$ARGUMENTS`: `<work-dir> [--base-branch=<ref>]`
  - `<work-dir>`: Path to the working directory (where `USER_FEEDBACK.md` is saved)
  - `--base-branch=<ref>`: (Optional) Base branch/commit for comparison. If provided, skip automatic detection.

## Workflow

### Step 1: Identify Base Branch

#### 1.1 Check for Provided Base Branch

If `--base-branch=<ref>` was provided in arguments:

```bash
BASE_REF="<provided-ref>"
# Verify the ref exists
git rev-parse --verify "$BASE_REF" 2>/dev/null
```

If verification succeeds, use this ref and proceed to Step 2.

#### 1.2 Fallback Detection (when --base-branch not provided)

Try detection methods in order until one succeeds:

**Method A: Remote tracking branches (most reliable)**
```bash
git merge-base HEAD origin/main 2>/dev/null
```
If fails, try:
```bash
git merge-base HEAD origin/master 2>/dev/null
```

**Method B: Local branches**
```bash
git merge-base HEAD main 2>/dev/null
```
If fails, try:
```bash
git merge-base HEAD master 2>/dev/null
```

**Method C: User input (last resort)**

If all automatic detection fails, use `AskUserQuestion`:
- Question: "ベースブランチを自動検出できませんでした。比較対象のブランチまたはコミットを指定してください。"
- Header: "Base branch"
- Options:
  1. `origin/main` - "リモートの main ブランチ"
  2. `origin/master` - "リモートの master ブランチ"
  3. `develop` - "develop ブランチ"
  4. (Other) - "カスタム入力"

### Step 2: Check Uncommitted Changes

```bash
git status --porcelain
```

If there are uncommitted changes, present the following options via `AskUserQuestion`:

1. **Review committed changes only** — Run `npx difit HEAD <base-ref>`
2. **Include uncommitted changes in review** — Run `npx difit .` (entire working directory)
3. **Skip review** — Proceed to feedback collection only

### Step 3: Run difit

Run difit based on the selection with **extended timeout** (10 minutes) to allow thorough user review:

```bash
# For committed changes only (timeout: 600000ms = 10 minutes)
npx difit HEAD <base-ref>

# To include uncommitted changes (timeout: 600000ms = 10 minutes)
npx difit .
```

**Important**: 
- difit launches a browser and waits for user interaction
- Use `timeout: 600000` parameter in Bash tool call
- Do NOT run in background — wait for completion

**Timeout Handling**:

If the command times out after 10 minutes, use `AskUserQuestion`:
- Question: "difit のレビューがタイムアウトしました。どうしますか？"
- Header: "Timeout"
- Options:
  1. "レビューを継続する" - "difit を再起動してレビューを続けます"
  2. "レビュー完了として続行" - "現時点でレビューは終了したものとして次に進みます"
  3. "レビューをスキップ" - "レビューせずにフィードバック収集に進みます"

If user selects option 1, re-run difit with another 10-minute timeout.

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
- If base ref verification fails: Fall through to next detection method or ask user
- If all detection methods fail and user cancels: Skip diff review, proceed to feedback collection only
