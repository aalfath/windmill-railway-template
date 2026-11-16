# Windmill worker, "default" worker group (Python, TypeScript/Bun/Deno, Go, Bash, flows, dependency jobs...).
# Upstream image pinned by version and digest. Keep it in step with server/Dockerfile.
FROM ghcr.io/windmill-labs/windmill:1.875.0@sha256:1b224f32dcb6e4fdbd74ed935ad42ebe4c0ce8c42ff64f63bd59f1907bcb9da6

ENV MODE=worker \
    WORKER_GROUP=default

CMD ["windmill"]
