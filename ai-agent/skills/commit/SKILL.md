---
name: commit
description: Commits staged changes to the repository with conventional commit format. Use when the user wants to create a git commit, finalize work, or save changes with a structured commit message.
context: fork
allowed-tools: Bash(git status),Bash(git add),Bash(git commit),Bash(git branch),AskUserQuestion
---

# Commit Changes

Commit changes to the repository using git.

## Steps

1. **Check repository status**: Verify changed files with `git status`
2. **Stage changes**: `git add <file1> <file2> ...` or `git add .`
3. **Get issue number**:
   - Get branch name with `git branch --show-current`
   - Match pattern `[A-Z]+-\d+` (e.g., `PRTIMES-123`, `JIRA-456`)
   - If no match, ask user with `AskUserQuestion`
4. **Create commit message**: Follow the guidelines below
5. **User confirmation**: Confirm with user if message is appropriate
   - If not appropriate, propose revised message and confirm again
   - Repeat until user confirms
6. **Execute commit**: `git commit -m "<commit message>"`

## Message Format

```
<type>: <description> [ISSUE-NUMBER]

<WHY - reason/background for the change>
```

### Type List

| Type | Usage |
|------|-------|
| `feat` | Add new feature |
| `fix` | Bug fix |
| `refactor` | Refactoring (no functional change) |
| `test` | Add or modify tests |
| `docs` | Documentation changes |
| `style` | Code style changes (formatting, etc.) |
| `chore` | Build or configuration changes |
| `perf` | Performance improvements |

### Guidelines

- Keep first line concise but descriptive
- Use imperative mood (e.g., "Fix" not "Fixed")
- Follow Conventional Commit format
- Add issue number at the end in `[ISSUE-NUMBER]` format
- **Always include WHY (reason/background) from line 3 onwards**
- All messages should be in Japanese

### Examples

```
feat: Add user authentication feature [PRTIMES-123]

Introduced JWT-based authentication mechanism to meet security requirements.
Changed from session management to token-based as existing approach did not meet requirements.
```

```
fix: Fix validation error on login screen [JIRA-456]

Resolved issue where 500 error occurred when empty string was submitted.
Added server-side validation as frontend validation was insufficient.
```
