# Laravel Docker Template

A ready-to-use Laravel development environment running inside Docker. Everything you need is pre-installed — PHP, Composer, Node, NVM, and the Laravel Installer — so your local machine stays clean and every project is isolated.

---

## What's Inside

| Service | Technology | Purpose |
|---------|-----------|---------|
| App | PHP 8.3-FPM | Runs your Laravel application |
| Web server | Nginx | Serves HTTP requests, forwards PHP to the app |
| Database | MySQL 8 | Stores your application data |
| Cache / Queue | Redis | Sessions, cache, and queue jobs |
| Reverse proxy | Traefik | Routes `yourapp.localhost` to the right container |

### Tools available inside the container
- **PHP 8.3** with common extensions (pdo, mbstring, redis, gd, bcmath, zip)
- **Composer** — PHP package manager
- **Laravel Installer** — create new Laravel projects with `laravel new`
- **Node LTS + npm + npx** — for compiling frontend assets
- **NVM** — switch Node versions if needed
- **Xdebug** — step-through debugging with VS Code

---

## Requirements

You need the following installed on your machine (local or server) before using this template.

### 1. Docker & Docker Compose
Docker runs all the containers. Docker Compose coordinates them together.

- **Install:** https://docs.docker.com/get-docker/
- Verify it works: `docker --version && docker compose version`

### 2. Traefik (reverse proxy)
Traefik is a router that sits in front of your containers. It reads labels on your containers and automatically routes traffic to the right place — so `http://laravel.localhost` goes to your Laravel app without you having to manage ports manually.

> Think of Traefik like a reception desk: requests come in, and Traefik directs them to the right container.

Traefik runs as its own Docker container and must be started **once** on your machine. All your Laravel projects then connect to it automatically.

**Set up Traefik** (only needs to be done once per machine):

```bash
mkdir -p ~/projects/traefik && cd ~/projects/traefik

# Create the Traefik config file
cat > traefik.yml << 'EOF'
log:
  level: DEBUG

api:
  dashboard: true
  insecure: true

entryPoints:
  web:
    address: ":80"

providers:
  docker:
    endpoint: "unix:///var/run/docker.sock"
    exposedByDefault: false
EOF

# Create the docker-compose file
cat > docker-compose.yml << 'EOF'
services:
  traefik:
    image: traefik:latest
    container_name: traefik
    restart: always
    ports:
      - "80:80"
      - "8080:8080"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./traefik.yml:/etc/traefik/traefik.yml
    command:
      - "--api.dashboard=true"
EOF

docker compose up -d
```

Traefik dashboard will be available at `http://localhost:8080`.

### 3. just
`just` is a command runner (a modern alternative to `make`) used to run common project tasks like starting containers, running migrations, and opening a shell.

```bash
# Install on Linux
curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to ~/.local/bin
```

Verify: `just --version`

---

## Starting a New Project

### Step 1 — Clone the template

```bash
git clone https://github.com/tgalanis/laravel-docker-template ~/code/my-project
cd ~/code/my-project
```

### Step 2 — Configure your environment

```bash
cp .env.example .env
```

Open `.env` and update these values for your project:

```env
APP_NAME=MyProject
APP_DOMAIN=myproject.localhost   # the URL you'll use in your browser
DB_DATABASE=myproject
DB_USERNAME=myproject
DB_PASSWORD=secret
```

### Step 3 — Run the setup command

```bash
just init
```

This single command will:
1. Build the Docker containers (installs PHP, Node, Composer, etc.)
2. Install a fresh Laravel application
3. Generate your app key
4. Run the default database migrations

### Step 4 — Open your app

Visit `http://myproject.localhost` (or whatever you set `APP_DOMAIN` to) in your browser.

> **Note:** If the domain doesn't resolve, add it to your `/etc/hosts` file:
> ```
> 127.0.0.1   myproject.localhost
> ```

---

## Daily Development Commands

Run these from your project directory on your **host machine** (not inside the container).

```bash
just up              # start all containers
just down            # stop all containers
just build           # rebuild containers (after Dockerfile changes)
just logs            # tail all container logs
just logs-service nginx   # tail a specific service
```

### Working inside the container

```bash
just shell           # open a bash shell in the app container
just shell-root      # open a shell as root (for admin tasks)
```

Once inside the container you have full access to:
```bash
php artisan make:model Post -mcr   # create model, migration, controller
npm install && npm run dev          # install and compile frontend assets
composer require spatie/laravel-permission
laravel new               # create a new Laravel project
nvm install 20            # install a different Node version
```

### Artisan shortcuts

```bash
just artisan migrate
just artisan "migrate --seed"
just artisan "make:controller PostController"
just fresh               # migrate:fresh --seed (wipes and rebuilds the database)
just worker              # start the queue worker
just clear               # clear all Laravel caches
```

### Composer

```bash
just composer install
just composer "require spatie/laravel-permission"
just composer "remove some/package"
```

### Database

```bash
just db                  # opens a MySQL shell inside the db container
```

---

## Testing

```bash
just test                        # run the full test suite
just test-coverage               # run tests with a coverage report
just test-filter "UserTest"      # run a specific test class or method
```

---

## Debugging with VS Code

This template includes full Xdebug support. You can pause execution and step through your code line by line.

### Setup (one time)

1. Install the **PHP Debug** extension in VS Code (`xdebug.php-debug`)
2. VS Code will also suggest all recommended extensions when you open the project — click **Install All**

### Starting a debug session

```bash
just debug-on        # enables Xdebug and restarts the app container
```

Then in VS Code:
1. Open the **Run and Debug** panel (Ctrl+Shift+D)
2. Select **Listen for Xdebug (Docker)**
3. Press **F5** to start listening
4. Set a breakpoint by clicking the gutter next to a line number
5. Visit your app in the browser — VS Code will pause at your breakpoint

```bash
just debug-off       # disable Xdebug when done (keeps things fast)
```

> Xdebug is **off by default** so there is no performance impact during normal development.

---

## VS Code Tasks

Common commands are wired into VS Code's task runner. Press `Ctrl+Shift+P` → **Tasks: Run Task** to access:

- `just up` — start containers
- `just down` — stop containers
- `just logs` — tail logs
- `just test` — run tests
- `just fresh` — reset the database

---

## Project Structure

```
my-project/
├── app/                    # Laravel application code
├── docker/
│   └── php/
│       ├── Dockerfile      # builds the app container
│       └── xdebug.ini      # Xdebug configuration
├── nginx/
│   └── conf.d/
│       └── default.conf    # Nginx site config
├── .vscode/
│   ├── extensions.json     # recommended VS Code extensions
│   ├── launch.json         # Xdebug debug configuration
│   ├── settings.json       # workspace settings
│   └── tasks.json          # VS Code task shortcuts
├── docker-compose.yml      # defines all containers and how they connect
├── justfile                # all project commands
└── .env                    # your local environment config (never commit this)
```

---

## How It All Fits Together

```
Your Browser
     │
     ▼
  Traefik (port 80)
  "laravel.localhost? → nginx container"
     │
     ▼
  Nginx container
  "*.php? → app container:9000"
  "static files? → serve directly"
     │
     ▼
  App container (PHP-FPM)
  runs your Laravel code
     │         │
     ▼         ▼
  MySQL      Redis
  (data)   (cache/queues)
```

---

## Common Problems

**`laravel.localhost` doesn't open in the browser**
- Make sure Traefik is running: `docker ps | grep traefik`
- Add `127.0.0.1 laravel.localhost` to `/etc/hosts`

**Permission errors on files**
- The container runs as your host user UID, so this should be rare
- If it happens: `docker exec -u root app chown -R 1000:1000 /var/www`

**Port 80 already in use**
- Something else is using port 80 (Apache, another Nginx, etc.)
- Find it: `sudo lsof -i :80` and stop that service

**Changes to the Dockerfile not taking effect**
- You need to rebuild: `just build`

---

## License

MIT
