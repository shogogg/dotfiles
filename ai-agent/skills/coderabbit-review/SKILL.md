---
name: coderabbit-review
description: Perform code review using CodeRabbit.
allowed-tools: Bash, Read, Edit, Write, Glob, Grep
---

# CodeRabbit Review
This skill provides instructions on how to use CodeRabbit CLI for code reviews, and how to handle the feedback received.

## Instructions
1. Check authentication status with `coderabbit auth status`. If not logged in, prompt the user to log in using `coderabbit auth login`.
2. Determine whether to review uncommitted or committed code changes based on the git status.
3. Run the appropriate CodeRabbit command without sandbox:
   - For uncommitted changes: `coderabbit --plain --type uncommitted`
   - For committed changes: `coderabbit --plain --type committed`
4. After receiving the review comments, address the issues as follows:
   - If the comment points out clear bugs, coding standard violations, security issues, or performance improvements, make the necessary changes immediately.
   - If the comment is overly strict, involves trade-offs, or requires significant architectural changes, ask the user for a decision before making any changes.
5. Report back to the user with a summary of the comments received from CodeRabbit and the actions taken for each comment.

## Note
- You should communicate to the user in Japanese.
