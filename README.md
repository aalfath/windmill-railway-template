# Windmill on Railway

Deploys [Windmill](https://www.windmill.dev) **v1.875.0**, the open-source platform that turns scripts (Python, TypeScript, Go, Bash, SQL and more) into workflows, scheduled jobs, webhooks and internal UIs, on [Railway](https://railway.com).

Every service is built from this repository. The Dockerfiles pin the official image `ghcr.io/windmill-labs/windmill:1.875.0` by digest (`sha256:1b224f32dcb6e4fdbd74ed935ad42ebe4c0ce8c42ff64f63bd59f1907bcb9da6`).

## What it deploys

| Service | Source | What it does |
|---|---|---|
| `Windmill` | `server/` | API and web UI, public on a Railway domain, health check `/api/version` |
| `Worker` | `worker/` | Runs jobs of the `default` worker group: Python, Bun, Deno, Go, Bash, PowerShell, flows and dependency installs. Volume at `/tmp/windmill/cache` keeps installed packages across redeploys |
| `Native Worker` | `native-worker/` | Runs `native` jobs in-process: native TypeScript, PostgreSQL, MySQL, GraphQL, BigQuery, Snowflake, MSSQL and Oracle scripts |
| `Postgres` | Railway's PostgreSQL | All of Windmill's data: users, workspaces, scripts, flows, schedules, job history |

## First login

Windmill's migrations create a superadmin `admin@windmill.dev` with the password `changeme`. This template never exposes that login. On every boot, `server/start.sh` first starts Windmill on `127.0.0.1` only. If the default password still works, it replaces it, sets the base URL and checks that the old login fails. Only then does it start Windmill on the public port.

- Log in as `admin@windmill.dev`, or as `WINDMILL_ADMIN_EMAIL` if you set one, with the value of `WINDMILL_ADMIN_PASSWORD` from the `Windmill` service's variables.
- Then create your first workspace. You can change the admin's email and password in the UI afterwards. Changing the variables later has no effect, because the bootstrap only runs while the default password is still in place.

## Variables

| Service | Variable | Default | Notes |
|---|---|---|---|
| Windmill | `DATABASE_URL` | `${{Postgres.DATABASE_URL}}?sslmode=disable` | Private network |
| Windmill | `PORT` | `8000` | |
| Windmill | `BASE_URL` | `https://${{RAILWAY_PUBLIC_DOMAIN}}` | Stored as Windmill's base URL on first boot |
| Windmill | `WINDMILL_ADMIN_PASSWORD` | generated secret | First superadmin password |
| Windmill | `WINDMILL_ADMIN_EMAIL` | empty (optional) | Empty keeps `admin@windmill.dev` |
| Worker, Native Worker | `DATABASE_URL` | `${{Postgres.DATABASE_URL}}?sslmode=disable` | |
| Worker, Native Worker | `BASE_INTERNAL_URL` | `http://${{Windmill.RAILWAY_PRIVATE_DOMAIN}}:${{Windmill.PORT}}` | Lets jobs call the Windmill API (`wmill` client) |

`MODE`, `WORKER_GROUP`, `NATIVE_MODE` and `SLEEP_QUEUE` are set in the Dockerfiles. The server binds `::` so the workers can reach it over Railway's private network.

## Scaling

Add replicas to `Worker` for more parallel jobs. Each replica runs one job at a time. `Native Worker` runs 8 native jobs at once. Extra worker groups (for example a `reports` group with Chromium) are another service built from `worker/` with a different `WORKER_GROUP`, set up under Workers in the UI.

## Not included

The optional LSP / multiplayer sidecar (`windmill-extra`) isn't included. The editor works without it but has no Python/Go autocompletion. Enterprise features (indexer, S3 log storage) aren't included either. SMTP, SSO and OAuth are set in the instance settings in the UI.

## Updates

When a new Windmill version is tested, the digest pins in `server/`, `worker/` and `native-worker/` are bumped together, with an entry in [CHANGELOG.md](CHANGELOG.md). Railway then shows deployers of the template an "update available" notice, and each deployer chooses when to apply it. Windmill runs its database migrations on start. Read the changelog and the [Windmill changelog](https://www.windmill.dev/changelog) before you update.

## Run it locally

```sh
docker build -t wm-server server && docker build -t wm-worker worker && docker build -t wm-native native-worker
```

Then run them against any PostgreSQL 14+ with the variables above (`SERVER_BIND_ADDR=0.0.0.0` if your Docker network has no IPv6).

Windmill is © Windmill Labs, licensed under AGPLv3 (see the [upstream repository](https://github.com/windmill-labs/windmill)). This repository only contains the Railway wrapper.
