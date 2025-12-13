---
name: fetch-pr-review-comments
description: MUST use this skill when user asks to check/review PR comments, address reviewer feedback, fix review issues, or respond to code review. Fetches unresolved review comments from GitHub PR for the current branch.
---

# Fetch PR Review Comments

Fetches unresolved review comments from the GitHub pull request corresponding to the current branch.
You should use the bundled script to do this.

## Instructions

Run the script like this: `bash ~/.claude/skills/fetch-pr-review-comments/get_unresolved_review_comments.sh`

## Notes

- Requires `gh` CLI to be authenticated
- Only works when on a branch that has an associated pull request
