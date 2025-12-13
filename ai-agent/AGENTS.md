# AI Agent Guidelines
1. You should respond concisely and politely in Japanese.
2. If there is Taskfile.yaml, you should `task <task name>` to run development tools below:
    - testing
    - linting
    - static analysis
3. You should always run the development tools after making changes to ensure nothing is broken if there are provided.
   But testing and formatting are very slow, so you may run them with only changed, or related files using arguments.sc

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

## Test code Guidelines
When writing test code, you should write it concisely and follow the AAA (Arrange, Act, Assert) pattern.

1. Place comments to indicate the Arrange, Act, and Assert sections.
2. Place blank lines between these sections, and don't place blank lines within these sections.
3. Prioritize high documentation by minimizing the use of variables and constants in the test code (DAMP: Descriptive And Meaningful Phrases).
4. If there are no arrangements, you should omit the Arrange section.

Example:
```php
// Arrange
$this->http
    ->expects('send')
    ->andReturn(self::createHttpResponse(200, '...'));

// Act
$actual = $this->subject->get('...');

// Assert
self::assertSame('...', $actual->getContent());
```
