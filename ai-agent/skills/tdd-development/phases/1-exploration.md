# Phase 1: Exploration

Report: "Phase 1: Exploring codebase..."

## Step 1: Project Profile Check

Check for an existing project profile at `.ai-workspace/PROJECT_PROFILE.md`.

### 1.1 Profile Existence Check

Use `Read` tool to check if `.ai-workspace/PROJECT_PROFILE.md` exists.

### 1.2 Profile Status Handling

**If profile does not exist:**
- Inform the user: "プロジェクトプロファイルが見つかりません。探索後に自動生成します。"
- Proceed to Step 1.3 (Scope Decision)
- After exploration, generate the project profile (see Step 1.5)

**If profile exists but is outdated (>30 days):**
- Read the `Last Updated` field from the profile
- Inform the user: "プロジェクトプロファイルが古くなっています（最終更新: <date>）。更新を推奨しますか？"
- Use AskUserQuestion:
  - "プロファイルを更新しますか？"
  - Options: "はい（探索後に更新）", "いいえ（現在のプロファイルを使用）"

**If profile exists and is recent:**
- Read the profile content
- Proceed to Step 1.3 (Scope Decision)

### 1.3 Exploration Scope Decision

Analyze the task description from `$ARGUMENTS` and recommend an exploration level.

**Recommendation Rules:**
- **Light**: Keywords like "fix", "bug", "typo", "small", "single file" → simple fixes
- **Medium**: Keywords like "add", "feature", "refactor" → feature work
- **Full**: Keywords like "new module", "architecture", "large-scale", "design change" → major changes

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

### 1.4 Parallel Codebase Exploration

Skip this step if `<work-dir>/EXPLORATION_REPORT.md` is present.
NEVER EXPLORE THE CODEBASE YOURSELF. All exploration is done by sub-agents.

**Agent configuration by exploration level:**

| Level | Agent A (Code) | Agent B (Test/Quality) | Agent C (Patterns) |
|-------|:-:|:-:|:-:|
| Light | O (max_turns=15) | - | - |
| Medium | O (max_turns=15) | O (max_turns=15) | - |
| Full | O (max_turns=15) | O (max_turns=15) | O (max_turns=15) |
| Skip | - | - | - |

**If "Skip" was selected:**
- Create a minimal `EXPLORATION_REPORT.md` from the project profile
- Include only task-relevant sections from the profile
- Proceed directly to Step 1.5 (skip parallel exploration and integration)

#### Agent A: Task-Related Code Exploration

**Sub-agent type**: `codebase-explorer`

**Prompt must include:**
- The task description from `$ARGUMENTS`
- **Focus**: Identify files and symbols directly related to the task. Trace dependencies (imports, call chains). Find the entry points relevant to the task.
- **Project profile summary** (if available): key patterns, tech stack info
- Output file path: `<work-dir>/EXPLORATION_CODE.md`
- **Return directive**: "Write ALL findings to the output file. Return ONLY a brief completion summary (2-3 sentences): confirm the output file path, list the number of key files found, and note any concerns. Do NOT include the full report content in your final response."

#### Agent B: Test & Quality Infrastructure Exploration

**Sub-agent type**: `codebase-explorer`

**Prompt must include:**
- The task description from `$ARGUMENTS`
- **Focus**: Investigate the test framework, test directory structure, test helpers, fixtures, and mocking patterns. Check lint/format configuration. Find existing tests for related code.
- **Project profile summary** (if available): test infrastructure info
- Output file path: `<work-dir>/EXPLORATION_TEST.md`
- **Return directive**: "Write ALL findings to the output file. Return ONLY a brief completion summary (2-3 sentences): confirm the output file path, summarize test infrastructure, and note any concerns. Do NOT include the full report content in your final response."

#### Agent C: Patterns & Conventions Exploration

**Sub-agent type**: `codebase-explorer`

**Prompt must include:**
- The task description from `$ARGUMENTS`
- **Focus**: Analyze naming conventions (files, classes, methods), directory organization rules, common design patterns, and similar existing implementations that can serve as references.
- **Project profile summary** (if available): naming conventions, common patterns
- Output file path: `<work-dir>/EXPLORATION_PATTERNS.md`
- **Return directive**: "Write ALL findings to the output file. Return ONLY a brief completion summary (2-3 sentences): confirm the output file path, list key patterns found, and note any concerns. Do NOT include the full report content in your final response."

#### Launching Agents

Launch all applicable agents **in parallel** using multiple `Task` tool calls in a single message. Wait for all agents to complete before proceeding to Step 1.5.

### 1.5 Integration & Profile Generation

After all exploration agents complete, launch an integration sub-agent.

**Sub-agent type**: `general-purpose`, max_turns = 15

**Prompt must include:**
- The task description from `$ARGUMENTS`
- List of exploration output files to read and integrate:
  - `<work-dir>/EXPLORATION_CODE.md` (always present for non-Skip)
  - `<work-dir>/EXPLORATION_TEST.md` (present for Medium/Full)
  - `<work-dir>/EXPLORATION_PATTERNS.md` (present for Full)
- **Integration task**: "Read all the exploration output files listed above. Synthesize them into a single unified exploration report."
- Output file path: `<work-dir>/EXPLORATION_REPORT.md`
- **Report format**: The integrated report MUST include these sections:
  - **Task Summary**: Brief description of the task
  - **Related Files and Directories**: Key files identified, organized by relevance
  - **Dependencies**: Import chains, call relationships
  - **Test Patterns**: Test framework, existing tests, helpers (if available)
  - **Existing Patterns**: Naming conventions, design patterns, reference implementations (if available)
  - **Key Concerns**: Any potential issues or risks identified
- **Profile generation**: "Also generate/update `.ai-workspace/PROJECT_PROFILE.md` using the following template. Fill in as much as you can from the integrated exploration results."

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

- **Return directive**: "Write the integrated report and generate/update the project profile. Return ONLY a brief completion summary (2-3 sentences): confirm both output file paths, note the number of key files in the report, and flag any concerns. Do NOT include the full report content in your final response."

### Post-Integration Verification

After the integration agent returns:
1. Verify that `<work-dir>/EXPLORATION_REPORT.md` exists (Read tool)
2. Verify that `.ai-workspace/PROJECT_PROFILE.md` exists (Read tool)
3. If either file is missing, report the failure to the user and ask whether to retry or abort

## Error Handling

If any sub-agent fails or returns no output:
- **Exploration agent failure**: Report which agent failed to the user. Ask whether to retry the failed agent or proceed with available results.
- **Integration agent failure**: Report the failure. Ask whether to retry integration or abort.
- **Partial results**: If some exploration agents succeeded and others failed, the integration agent should work with whatever results are available.

Report: "Phase 1 complete: Exploration report written to `<work-dir>/EXPLORATION_REPORT.md`"

## State Update
Update `STATE.json`: set `currentPhase` to `2`.
