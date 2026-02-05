---
name: improve-tdd-skill
description: Helps improve the tdd-development skill. Triggers on keywords like "tdd skill improvement", "modify tdd-development", "fix phase N", or "improve tdd workflow".
context: inherit
allowed-tools: Read, Write, Edit, AskUserQuestion, Grep, Glob, mcp__plugin_serena_serena__read_file, mcp__plugin_serena_serena__replace_content, mcp__plugin_serena_serena__search_for_pattern
---

# TDD Skill Improvement Assistant

This skill assists in improving the `tdd-development` skill by providing structured guidance for modifications.

## Trigger Conditions

- "tdd スキルを改善", "tdd-development を修正"
- "Phase N を改善" (any phase reference)
- "tdd workflow の調整"
- "探索レベルの調整", "retry 制御の変更", "learning 記録の改善"

## Workflow

### Step 1: Understand the Request

Clarify what the user wants to improve. If the request is ambiguous, use `AskUserQuestion` with options:

**Japanese message examples:**
- "どのような改善を行いたいですか？"
- "対象のフェーズを選択してください"

### Step 2: Reference Structure

Read `references/structure.md` to understand the tdd-development skill architecture and identify target files.

### Step 3: Analyze Target (if needed)

If the improvement requires understanding the current implementation:
1. Read the target phase file(s) using Serena tools
2. Identify the specific section(s) to modify

### Step 4: Present Plan and Get Approval

Present the improvement plan to the user:

1. **変更対象ファイル**: List files to be modified
2. **変更内容の概要**: Brief description of changes
3. **選択肢（ある場合）**: If there are options, present them using `AskUserQuestion`

**Japanese message for approval:**
- "上記の変更を実施してよろしいですか？"
- Options: "はい、実施してください", "修正が必要です"

### Step 5: Execute Changes

After approval, use Serena tools to make the modifications:

- `mcp__plugin_serena_serena__replace_content` for targeted changes (preferred)
- `Edit` tool for simple text replacements

### Step 6: Report Changes

Present a summary of changes made:

**Japanese report format:**
```
## 変更完了

### 変更されたファイル
- `<file-path>`: <brief description>

### 変更内容
<summary of what was changed>

### 確認事項
<any follow-up actions or recommendations>
```

## Common Improvement Patterns

### Exploration Level Adjustment (Phase 1)
- Target: `phases/1-exploration.md`
- Options: quick, focused, full, custom
- Consider: profile freshness thresholds, scope decision logic

### Retry Control (Phase 6/7)
- Target: `phases/6-quality-checks.md`, `phases/7-code-review.md`, `SKILL.md`
- Parameters: max retries, cycle limits, reset conditions

### Learning Record Improvements
- Target: `phases/9-final-report.md`, various phases
- Consider: what to record, where to store, when to apply

### Sub-agent Prompts
- Target: Any phase file that launches sub-agents
- Consider: return directives, max_turns, context passing

### State Management
- Target: `SKILL.md`, individual phase files
- Consider: STATE.json fields, phase transitions

## File Locations

All tdd-development files are located at:
```
ai-agent/skills/tdd-development/
├── SKILL.md                    # Main skill definition
└── phases/
    ├── 0-pre-checks.md
    ├── 1-exploration.md
    ├── 2-planning.md
    ├── 3-test-design.md
    ├── 4-approval-gate.md
    ├── 5-implementation.md
    ├── 6-quality-checks.md
    ├── 7-code-review.md
    ├── 8-user-review.md
    └── 9-final-report.md
```

## Important Notes

- Use Serena tools for precise content replacement
- Always preserve the existing structure and formatting
- Test changes mentally before applying (consider edge cases)
- Keep prompts in English, user-facing messages in Japanese
