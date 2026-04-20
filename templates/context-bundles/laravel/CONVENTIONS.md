<!-- bundle: laravel v1 -->
---
abstract: "Laravel PHP conventions: PSR-12, StudlyCase classes, camelCase methods, snake_case DB, authorize in controllers."
---

# Conventions

## Naming
- Classes: `StudlyCase` (`UserController`, `OrderService`, `InvoiceJob`)
- Methods: `camelCase` (`getActiveOrders`, `sendNotification`)
- Database columns: `snake_case` (`first_name`, `created_at`)
- Routes: `kebab-case` slugs, named as `resource.action` (`orders.show`)

## PHP Style
- PSR-12 enforced via Laravel Pint (`./vendor/bin/pint`)
- Type declarations on all method parameters and return types
- No magic strings for permissions — use constants or enums

## Laravel Patterns
- `$this->authorize('action', $model)` in every controller method that touches a resource
- Validation in Form Request classes, not inline in controllers
- Business logic in Service classes, not controllers or models
- No raw SQL; use Eloquent query builder with explicit column selection

## Definition of Done
- [ ] `php artisan test` (or `./vendor/bin/pest`) passes
- [ ] `./vendor/bin/phpstan analyse` at configured level — no errors
- [ ] `./vendor/bin/pint --test` passes (PSR-12 clean)
- [ ] Migrations are reversible (`down()` method implemented)
