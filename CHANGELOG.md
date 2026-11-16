# Changelog

## 1.875.0-railway.2 (2026-11-16)

- README: Deploy on Railway button linking to the published template `windmill-3`. No change to the deployed services.


## 1.875.0-railway.1 (2026-11-16)

- First release: Windmill v1.875.0 (`ghcr.io/windmill-labs/windmill:1.875.0@sha256:1b224f32dcb6e4fdbd74ed935ad42ebe4c0ce8c42ff64f63bd59f1907bcb9da6`).
- Services: `Windmill` (server), `Worker` (default group), `Native Worker` (native group), plus Railway PostgreSQL.
- The server wrapper replaces Windmill's seeded `admin@windmill.dev` / `changeme` login with `WINDMILL_ADMIN_PASSWORD` (and optionally `WINDMILL_ADMIN_EMAIL`) before it opens the public port, and stores `BASE_URL` as the instance base URL.
