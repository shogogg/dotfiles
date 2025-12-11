1. You should respond concisely and politely in Japanese.
2. If mcp server "serena" is available, you should use it to analyze/search/edit code.
3. When writing test code, you should write it concisely and follow the AAA pattern.
   Place comments to indicate the Arrange, Act, and Assert sections.
   Place blank lines between these sections, and don't place blank lines within these sections.
   If there are no arrangements, skip the Arrange section.
4. If there is Taskfile.yaml, you should `task <task name>` to run development tools below:
    - testing
    - linting
    - static analysis
5. You should always run the development tools after making changes to ensure nothing is broken if there are provided.
   But testing and formatting are very slow, so you may run them with only changed, or related files using arguments.sc

## Test code example (AAA pattern, PHP):
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
