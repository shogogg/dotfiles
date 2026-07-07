---
name: re-run
description: Re-runs failed CI checks on a GitHub pull request. Use when CI checks have failed and need to be retried, or when asked to re-run CI, retry failed checks, or rerun workflows.
model: haiku
allowed-tools: Bash(git branch), Bash(gh pr checks), Bash(gh run rerun), Bash(gh pr view)
---

# Re-run Failed CI Checks

Re-runs all failed CI checks on the pull request corresponding to the current branch (or the specified PR).

## Arguments

- `$ARGUMENTS` (optional): PR identifier — a PR number, URL, or branch name.
  If omitted, defaults to the pull request associated with the current branch.

## Workflow

### Step 1: Determine Target PR

- If `$ARGUMENTS` is provided, use it as the PR identifier for subsequent `gh` commands.
- If `$ARGUMENTS` is empty, leave the PR identifier blank (the `gh` CLI automatically resolves the current branch's PR).

### Step 2: Fetch Failed Checks

Run the following command to get all failed checks for the PR:

```bash
gh pr checks [<PR identifier>] --json name,link,bucket
```

- Omit `[<PR identifier>]` when `$ARGUMENTS` is empty.
- If the command fails (e.g., no PR found for the current branch), report the error and stop.
- Parse the JSON output and filter entries where `bucket == "fail"`.
- If there are no failed checks, report:
  ```
  失敗している CI チェックはありません。
  ```
  and stop.

### Step 3: Extract Unique Run IDs

For each failed check, extract the GitHub Actions run ID from the `link` field.

The link format is:
```
https://github.com/<owner>/<repo>/actions/runs/<run-id>/jobs/<job-id>
```

Extract `<run-id>` and deduplicate the list (multiple failed jobs may share the same run).

### Step 4: Re-run Failed Jobs

For each unique run ID, execute:

```bash
gh run rerun <run-id> --failed
```

Collect the result (success or error) for each run ID.

### Step 5: Report Results

After processing all run IDs, output a summary:

```
## CI Re-run Results

再実行対象: <N> 件の失敗チェック (<M> ワークフロー実行)

| Run ID | ワークフロー名 | 結果 |
|--------|--------------|------|
| <id>   | <name>       | ✅ 再実行開始 / ❌ エラー: <message> |
```

List each unique run ID with the names of the failed checks that belonged to it, and the result of the rerun command.

## Notes

- Requires `gh` CLI to be authenticated with appropriate permissions.
- Only re-runs jobs with `bucket == "fail"` (not `cancel`, `pending`, or `skipping`).
- Uses `--failed` flag to rerun only the failed jobs within a run (not the entire run from scratch).
