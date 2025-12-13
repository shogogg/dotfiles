#!/bin/bash
#
# Fetches unresolved review comments from the PR corresponding to the current branch.
#
set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

# Get the current branch name
BRANCH=$(git branch --show-current)

# Get the PR number for the current branch
PR_NUMBER=$(gh pr view "$BRANCH" --json number --jq '.number' 2>/dev/null)

if [ -z "$PR_NUMBER" ]; then
    echo "Error: No pull request found for branch '$BRANCH'" >&2
    exit 1
fi

# Get the repository owner and name
REPO_INFO=$(gh repo view --json owner,name --jq '"\(.owner.login)/\(.name)"')
OWNER=$(echo "$REPO_INFO" | cut -d'/' -f1)
REPO=$(echo "$REPO_INFO" | cut -d'/' -f2)

# GraphQL query to fetch review threads
GRAPHQL_QUERY='query($owner: String!, $repo: String!, $pr: Int!) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $pr) {
      reviewThreads(first: 100) {
        nodes {
          isResolved
          comments(first: 100) {
            nodes {
              author { login }
              body
              createdAt
              path
              line
            }
          }
        }
      }
    }
  }
}'

# jq filter to extract and format unresolved comments
JQ_FILTER='[.data.repository.pullRequest.reviewThreads.nodes[]
  | select(.isResolved == false)
  | .comments.nodes[0]]
  | to_entries[]
  | .key as $idx
  | .value
  | "## Comment \($idx + 1)",
    "Reviewer: \(.author.login)",
    "Date: \(.createdAt)",
    "File: \(.path):\(.line // "N/A")",
    ((.body | capture("_(?<severity>⚠️[^_]+)_\\s*\\|\\s*_(?<level>[^_]+)_") // {}) | if .severity then "Severity: \(.level)" else empty end),
    "",
    .body,
    ""
'

# Fetch unresolved review comments via GraphQL API
OUTPUT=$(gh api graphql -f query="$GRAPHQL_QUERY" -f owner="$OWNER" -f repo="$REPO" -F pr="$PR_NUMBER" \
  | jq -r "$JQ_FILTER" \
  | "$SCRIPT_DIR/clean_review_comment.pl" \
  | cat -s) # Squeeze multiple blank lines into one

if [ -z "$OUTPUT" ]; then
    echo "No unresolved review comments found for PR #$PR_NUMBER."
    exit 0
fi

cat << __OUTPUT__
$OUTPUT

## IMPORTANT NOTES
After reporting the comments, STOP and WAIT for user instructions.

DO NOT:
- Create todo lists for fixing the comments
- Read or edit the mentioned files
- Start implementing any fixes

## Next Actions
1. Report the fetched unresolved review comments in a clear format. Do not use table format.
2. **STOP HERE** - Do not proceed to fix or address the comments yet.
3. Wait for user to explicitly request fixes.
__OUTPUT__
