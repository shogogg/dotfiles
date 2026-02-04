# Phase 1: Exploration

Report: "Phase 1: Exploring codebase..."

## Step 0: Load Past Learnings

Reference past learnings from Serena Memory to avoid repeating the same issues.

```
mcp__plugin_serena_serena__list_memories()
```

Read the following memories if they exist:
- `coderabbit-learnings.md` — Learnings from CodeRabbit reviews
- `user-feedback-patterns.md` — User feedback patterns
- `quality-check-learnings.md` — Learnings from previous quality checks

```
mcp__plugin_serena_serena__read_memory("<memory-name>")
```

**Ensure that the referenced learnings are conveyed to subsequent phases.**

## Step 1: Project Profile Check

Check for an existing project profile at `.ai-workspace/PROJECT_PROFILE.md`.

### 1.1 Profile Existence Check

Use `Read` tool to check if `.ai-workspace/PROJECT_PROFILE.md` exists.

### 1.2 Profile Status Handling

**If profile does not exist:**
- Inform the user: "プロジェクトプロファイルが見つかりません。初回探索のため、Full レベルで探索を行います。"
- Set exploration level to `full`
- After exploration, generate the project profile (see Step 1.5)

**If profile exists but is outdated (>30 days):**
- Read the `Last Updated` field from the profile
- Inform the user: "プロジェクトプロファイルが古くなっています（最終更新: <date>）。更新を推奨しますか？"
- Use AskUserQuestion:
  - "プロファイルを更新しますか？"
  - Options: "はい（Full 探索）", "いいえ（現在のプロファイルを使用）"

**If profile exists and is recent:**
- Read the profile content
- Proceed to Step 1.3 (Scope Decision)

### 1.3 Exploration Scope Decision

Analyze the task description from `$ARGUMENTS` and recommend an exploration level.

**Recommendation Rules:**
- **Light**: Keywords like "fix", "bug", "typo", "small", "単一ファイル", "修正" → simple fixes
- **Medium**: Keywords like "add", "feature", "refactor", "追加", "機能", "リファクタ" → feature work
- **Full**: Keywords like "new module", "architecture", "大規模", "新規モジュール", "設計変更" → major changes

**Use AskUserQuestion to confirm the exploration scope:**

```
Question: "タスク内容から **<recommended-level>** レベルの探索を推奨します。どのレベルで探索しますか？"

Options:
- Light（関連ファイルのみ）— バグ修正、小さな変更向け
- Medium（関連ディレクトリ）— 機能追加、リファクタリング向け
- Full（全体探索）— 新規モジュール、大規模変更向け
- Skip（プロファイルのみ使用）— プロファイルの情報で十分な場合
```

**Note:** "Skip" option is only available if a valid project profile exists.

### 1.4 Codebase Exploration

Skip this step if `<work-dir>/EXPLORATION_REPORT.md` is present.
MUST USE SUB-AGENT "codebase-explorer", max_turns = 30. NEVER EXPLORE THE CODEBASE YOURSELF.

**Determine exploration parameters based on selected level:**

| Level | exploration_level | Focus |
|-------|-------------------|-------|
| Light | light | Related files + direct dependencies only |
| Medium | medium | Related directories + similar patterns |
| Full | full | Full project structure + test infrastructure |
| Skip | (no exploration) | Use profile only |

**Prompt must include:**
- The task description from `$ARGUMENTS`
- **Exploration level**: `<selected-level>` (light/medium/full)
- **Project profile summary** (if available): key patterns, test infrastructure, naming conventions
- Output file path: `<work-dir>/EXPLORATION_REPORT.md`
- **Past learnings summary** (if any were loaded in Step 0)
- **Return directive**: "Write ALL findings to the output file. Return ONLY a brief completion summary (2-3 sentences) to the orchestrator: confirm the output file path, list the number of key files found, and note any concerns. Do NOT include the full report content in your final response."

**If "Skip" was selected:**
- Create a minimal `EXPLORATION_REPORT.md` from the project profile
- Include only task-relevant sections from the profile

### 1.5 Project Profile Generation/Update

**Trigger conditions:**
- Profile did not exist (new project)
- User requested profile update
- Exploration level was "Full"

**Generate/update `.ai-workspace/PROJECT_PROFILE.md` with the following structure:**

```markdown
# Project Profile

## Directory Structure
<!-- Overview of key directories and their purposes -->

## Tech Stack
<!-- Programming languages, frameworks, major libraries -->

## Test Infrastructure
<!-- Test framework, test directory, helpers, fixtures -->

## Naming Conventions
<!-- File naming, class naming, method naming patterns -->

## Common Patterns
<!-- Design patterns, directory organization rules -->

## Entry Points
<!-- Main entry points (API, CLI, UI, etc.) -->

## Last Updated
<!-- ISO 8601 date: YYYY-MM-DD -->
```

**Extraction from exploration results:**
- Directory Structure: from the exploration report's "Related Files and Directories"
- Tech Stack: from observed imports, config files, package manifests
- Test Infrastructure: from the exploration report's "Test Patterns"
- Naming Conventions: from the exploration report's "Existing Patterns"
- Common Patterns: from the exploration report's "Existing Patterns"
- Entry Points: from main/index files, route definitions, CLI entry points

## Error Handling

If the sub-agent fails or returns no output, report the failure to the user with details and ask whether to retry or abort.

Report: "Phase 1 complete: Exploration report written to `<work-dir>/EXPLORATION_REPORT.md`"

## State Update
Update `STATE.json`: set `currentPhase` to `2`.
