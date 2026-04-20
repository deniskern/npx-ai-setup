<!-- bundle: laravel v1 -->
---
abstract: "Laravel MVC: Controllers, Models, Services, Blade views. Service Container for DI. Jobs for async work."
---

# Architecture

## Directory Structure
- `app/Http/Controllers/` — thin controllers; delegate to Services
- `app/Models/` — Eloquent models with relationships and scopes
- `app/Services/` — business logic layer (not a Laravel default, but conventional)
- `app/Jobs/` — queued jobs dispatched via `dispatch(new MyJob(...))`
- `resources/views/` — Blade templates (`layouts/`, `components/`, `partials/`)
- `routes/` — `web.php`, `api.php`, `console.php`
- `database/migrations/` — schema versioning; `seeders/` for fixtures

## Data Flow
1. HTTP Request → `routes/web.php` or `routes/api.php`
2. Middleware stack (auth, throttle, CORS)
3. Controller resolves dependencies via Service Container, calls Service
4. Service returns data → Controller returns JSON or Blade view
5. Jobs dispatched to Redis queue, processed by `queue:work`

## Key Patterns
- Service Container: bind interfaces in `AppServiceProvider`
- Form Requests for validation (`php artisan make:request`)
- Policies for authorization (`$this->authorize('update', $model)`)
