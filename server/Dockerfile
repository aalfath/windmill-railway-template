# Windmill server (API + web UI) for Railway.
# Upstream image pinned by version and digest. To update: bump both, then add a CHANGELOG.md entry.
FROM ghcr.io/windmill-labs/windmill:1.875.0@sha256:1b224f32dcb6e4fdbd74ed935ad42ebe4c0ce8c42ff64f63bd59f1907bcb9da6

ENV MODE=server
COPY start.sh /usr/local/bin/railway-windmill-server
RUN chmod 755 /usr/local/bin/railway-windmill-server

EXPOSE 8000
CMD ["/usr/local/bin/railway-windmill-server"]
