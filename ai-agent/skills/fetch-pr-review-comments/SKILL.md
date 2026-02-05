---
name: fetch-pr-review-comments
description: Fetches unresolved review comments from the GitHub PR for the current branch. Use when checking PR comments, addressing reviewer feedback, fixing review issues, or responding to code review.
---

# Fetch PR Review Comments

Fetches unresolved review comments from the GitHub pull request corresponding to the current branch.
You should use the bundled script to do this.

## Instructions

Run the script: `bash ~/.claude/skills/fetch-pr-review-comments/get_unresolved_review_comments.sh`

## Notes
-
- Requires `gh` CLI to be authenticated
- Only works when on a branch that has an associated pull request
