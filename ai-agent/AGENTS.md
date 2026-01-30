# AI Agent Guidelines

1. You should respond concisely and politely in Japanese.

## MCP Server Priority

When analyzing, searching, or editing code:

1. **First choice**: Use `serena` MCP tools (symbolic analysis, find_symbol, replace_symbol_body, etc.)
2. **Second choice**: Use `jetbrains` MCP tools (IDE integration)
3. **Fallback**: Use standard tools (Grep, Glob, Read, Edit)

Serena is especially preferred for:
- Symbol-based code navigation and editing
- Understanding code relationships (find_referencing_symbols)
- Precise refactoring operations

JetBrains is especially preferred for:
- Running/debugging via IDE run configurations
- File problems inspection (get_file_problems)
- Code reformatting (reformat_file)

## Delegation-First Principle

When executing orchestrator-type skills or multi-phase workflows:

1. **Always delegate substantive work to sub-agents** (`Task` tool) or specialized skills (`Skill` tool). The orchestrator should manage phase transitions and state, not perform the work itself.
2. **Do not explore, read, or modify source code directly** from the orchestrator. Use sub-agents for codebase exploration, code analysis, implementation, and review.
3. **Use `Read`/`Write` only for workflow management files** (state files, plan documents, result summaries) — never for source code.
4. **Sub-agent return directives**: When launching sub-agents, always instruct them to write detailed results to output files and return only a brief completion summary (2-3 sentences) to minimize context consumption.
