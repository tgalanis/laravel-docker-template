# Laravel Docker justfile
# Usage: just <recipe>

set dotenv-load := true

container := "app"

# List available recipes
default:
    @just --list

# ── Docker ────────────────────────────────────────────────────────────────────

# Start all containers
up:
    docker compose up -d

# Stop all containers
down:
    docker compose down

# Rebuild and start
build:
    docker compose up -d --build

# Tail all logs
logs:
    docker compose logs -f

# Tail a specific service: just logs-service nginx
logs-service service:
    docker compose logs -f {{service}}

# ── App shell ────────────────────────────────────────────────────────────────

# Open a shell in the app container
shell:
    docker exec -it {{container}} bash

# Open a shell as root
shell-root:
    docker exec -it -u root {{container}} bash

# ── Artisan ───────────────────────────────────────────────────────────────────

# Run an artisan command: just artisan "migrate --seed"
artisan cmd="":
    docker exec -it {{container}} php artisan {{cmd}}

# Fresh migration + seed
fresh:
    docker exec -it {{container}} php artisan migrate:fresh --seed

# Run queue worker
worker:
    docker exec -it {{container}} php artisan queue:work

# Clear all caches
clear:
    docker exec -it {{container}} php artisan optimize:clear

# ── Composer ──────────────────────────────────────────────────────────────────

# Run composer: just composer "require spatie/laravel-permission"
composer cmd="install":
    docker exec -it {{container}} composer {{cmd}}

# ── Database ──────────────────────────────────────────────────────────────────

# Open a MySQL shell
db:
    docker exec -it db mysql -u ${DB_USERNAME} -p${DB_PASSWORD} ${DB_DATABASE}

# ── Xdebug ────────────────────────────────────────────────────────────────────

# Enable Xdebug (restart app container with debug mode on)
debug-on:
    XDEBUG_MODE=debug docker compose up -d app

# Disable Xdebug
debug-off:
    XDEBUG_MODE=off docker compose up -d app

# ── Testing ───────────────────────────────────────────────────────────────────

# Run Pest or PHPUnit test suite
test *args:
    docker exec -it {{container}} php artisan test {{args}}

# Run tests with coverage report
test-coverage:
    docker exec -it {{container}} php artisan test --coverage

# Run a specific test filter: just test-filter "UserTest"
test-filter filter:
    docker exec -it {{container}} php artisan test --filter {{filter}}

# ── Setup ─────────────────────────────────────────────────────────────────────

# First-time project setup
init:
    cp -n .env.example .env || true
    UID=$(id -u) GID=$(id -g) docker compose up -d --build
    docker exec -u root {{container}} composer create-project laravel/laravel /tmp/laravel
    docker exec -u root {{container}} bash -c "cp -rn /tmp/laravel/. /var/www/ && rm -rf /tmp/laravel && chown -R $(id -u):$(id -g) /var/www"
    docker exec {{container}} php artisan key:generate
    just fresh
    @echo "Ready at http://laravel.localhost"
