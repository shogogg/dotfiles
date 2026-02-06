---
name: difit
description: Runs difit to launch a browser-based diff review UI and reports the result. Use when the user wants to review diffs with difit, visually review code changes in a browser, or says "difit でレビュー".
model: haiku
allowed-tools: Bash(npx difit)
context: fork
---

# difit Skill

Launches difit for browser-based diff review and reports the result.

## Arguments

- `$ARGUMENTS`: `<target> <base>`
  - `<target>`: Review target (HEAD, commit hash, branch name, or `.` for uncommitted changes)
  - `<base>`: Review base (HEAD, commit hash, branch name)

## Workflow

### Step 1: Convert Arguments

Replace `HEAD` with `@` in both `<target>` and `<base>` arguments.

Examples:
- `HEAD main` → `@ main`
- `. HEAD` → `. @`
- `HEAD~3 HEAD` → `@~3 @`

### Step 2: Run difit

Execute the following command:

```bash
npx difit --clean <target> <base>
```

Use `timeout: 600000` (10 minutes) in the Bash tool call. Do NOT run in background.

**Important**:
- Do NOT pipe diff to stdin. Always pass arguments directly.
- Always include the `--clean` flag.

### Step 3: Determine Result

Inspect the STDOUT output from difit:

- **If output contains `📝 Comments from review session:`** → User has feedback.
- **Otherwise** → No feedback (APPROVED).

### Step 4: Report Result

#### When feedback exists:

Output:

```
There is user feedback.

<feedback content from difit output>
```

Include the full feedback section from difit STDOUT as-is.

#### When no feedback:

Output only:

```
No user feedback. It is APPROVED.
```

## Error Handling

- If difit fails to start or is not installed, report the error.
- If the command times out, report that the review session timed out.
