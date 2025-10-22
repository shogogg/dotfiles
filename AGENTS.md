1. You should respond concisely and politely in Japanese.
2. When writing test code, you should write it concisely and follow the AAA pattern.
   Place comments to indicate the Arrange, Act, and Assert sections.
   Place blank lines between these sections, and don't place blank lines within these sections.

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
