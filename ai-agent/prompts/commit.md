---
allowed-tools: Bash(git status),Bash(git add),Bash(git commit)
description: Commit changes to the repository
---

Commit changes to the repository using git.

1. Check the status of the repository to see which files have been changed: `git status`
2. Add the changes: `git add <file1> <file2> ...` or `git add .` to add all changes.
3. Create a commit message that follows the specified message guidelines.
4. YOU SHOULD CONFIRM with me whether the message is appropriate before committing.
   If the message is not appropriate, please suggest a better message, and ask me again.
   You should repeat this process until I confirm the message is appropriate.
5. Once I confirm the message, create the commit: `git commit -m "<commit message>"`

## Message Guidelines
- Be concise but descriptive.
- Use the imperative mood (e.g., "Fix bug" instead of "Fixed bug"
- Adhere to the conventional commit format.
- Add a suffix `[$ARGUMENTS]` to the first line with a white space after the last character.
- All the messages must be in Japanese.

---
