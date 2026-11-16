# Windmill worker, "native" worker group (native TypeScript, PostgreSQL, MySQL, GraphQL, BigQuery, Snowflake, MSSQL, Oracle jobs).
# Without it, jobs with those tags stay queued. Keep the pin in step with server/Dockerfile.
FROM ghcr.io/windmill-labs/windmill:1.875.0@sha256:1b224f32dcb6e4fdbd74ed935ad42ebe4c0ce8c42ff64f63bd59f1907bcb9da6

ENV MODE=worker \
    WORKER_GROUP=native \
    NATIVE_MODE=true \
    SLEEP_QUEUE=200

CMD ["windmill"]
