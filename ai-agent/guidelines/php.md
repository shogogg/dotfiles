# PHP Coding Guidelines

Guidelines to follow when writing PHP code.

## strict_types

Every file must begin with `declare(strict_types=1);`.

```php
<?php

declare(strict_types=1);
```

## final Classes

Add `final` to all concrete classes that are not intended for inheritance.

- Test classes must also be marked `final`.
- Exclude `abstract` classes and base classes that are explicitly extended.

```php
final class UserService
{
    // ...
}
```

## Type Declarations

- Use typed properties, parameter types, and return types wherever possible.
- Prefer the strictest type declarations available for the PHP version (e.g., union types, intersection types, `never`, `true`, `false`, etc.).

## PHPDoc

### Classes

Every class must have a PHPDoc comment describing its purpose.

```php
/**
 * ユーザーに関するビジネスロジックを提供するサービス。
 */
final class UserService
{
    // ...
}
```

### Methods

Every method (`public`, `protected`, `private`) must have a PHPDoc comment. Include `@param`, `@return`, and `@throws` as appropriate.

However, PHPDoc that merely repeats type declarations without adding information is prohibited. PHPDoc must describe information that cannot be conveyed by type declarations alone (descriptions, constraints, exception conditions, etc.).

**Good example:**

```php
/**
 * 指定されたIDのユーザーを取得する。
 *
 * @param positive-int $id ユーザーID
 * @return User 見つかったユーザー
 * @throws UserNotFoundException ユーザーが見つからない場合
 */
public function find(int $id): User
```

**Bad example (no information beyond type repetition):**

```php
/**
 * @param int $id
 * @return User
 */
public function find(int $id): User
```

### Properties

Data classes (DTOs, Value Objects, Entities, etc.) must have PHPDoc for their properties.
For classes with constructor promoted properties, include PHPDoc for each parameter
as `@param` tags in the constructor's PHPDoc.

As with methods, PHPDoc that merely repeats type declarations is prohibited.
Describe the meaning, constraints, units, etc. of each property.

**Good example (constructor promoted properties):**

```php
/**
 * 注文データを表すDTO。
 *
 * @param positive-int $id 注文ID
 * @param non-empty-string $customerName 顧客名
 * @param positive-int $amount 注文金額（税込、円単位）
 * @param \DateTimeImmutable $orderedAt 注文日時
 */
final class OrderDto
{
    public function __construct(
        public readonly int $id,
        public readonly string $customerName,
        public readonly int $amount,
        public readonly \DateTimeImmutable $orderedAt,
    ) {}
}
```

**Good example (regular properties):**

```php
final class UserProfile
{
    /** ユーザーの表示名。空文字列不可。 */
    public readonly string $displayName;

    /** プロフィール画像のURL。未設定の場合はnull。 */
    public readonly ?string $avatarUrl;
}
```

### Test Methods

Do not write PHPDoc for test methods. The test method name itself serves as documentation.

## Test Code

- Test classes must also be marked `final`.
- Do not write PHPDoc for test methods (the method name is the documentation).
- Test method names must follow the convention: `test_{methodName}_{testCaseName}`.
