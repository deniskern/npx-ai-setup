<!-- bundle: laravel v1 -->
---
abstract: "Laravel 10+ PHP 8.2+ with Composer, MySQL/PostgreSQL, Redis queues. Docker or Sail for local dev."
---

# Stack

## Runtime & Distribution
- PHP 8.2+, Composer 2.x
- MySQL 8 or PostgreSQL 14+, Redis 7+
- Laravel Sail (Docker) or native PHP-FPM + nginx

## Framework & Dependencies
- Laravel 10+ (routing, Eloquent ORM, Blade views, Queue, Events)
- Optional: Livewire, Inertia.js, Laravel Sanctum/Passport
- Queue workers: `php artisan queue:work` (Horizon for monitoring)

## Build & Tooling
- `php artisan` — migrations, queue, cache, key:generate
- PHPStan (level 6+) or Larastan for static analysis
- Laravel Pint for code formatting (PSR-12 compatible)
- Pest or PHPUnit for tests
