#!/bin/sh
# Railway wrapper for the Windmill server.
#
# Windmill's database migrations seed a superadmin "admin@windmill.dev" with the
# password "changeme". Before the public port opens, this script starts Windmill on
# 127.0.0.1 only, and if that default login still works it:
#   - sets WINDMILL_ADMIN_PASSWORD as the superadmin password (or, when
#     WINDMILL_ADMIN_EMAIL is another address, creates that superadmin and deletes
#     the default one), and
#   - stores BASE_URL as Windmill's base URL.
# Then it stops the local instance and starts Windmill on $PORT for real.
# Once the default password is gone, later boots skip all of this.
set -eu

log() { echo "[railway-bootstrap] $*"; }

: "${DATABASE_URL:?DATABASE_URL must be set}"
: "${WINDMILL_ADMIN_PASSWORD:?WINDMILL_ADMIN_PASSWORD must be set}"
if [ "${#WINDMILL_ADMIN_PASSWORD}" -lt 12 ]; then
  log "WINDMILL_ADMIN_PASSWORD must be at least 12 characters"
  exit 1
fi

export MODE=server
PUBLIC_PORT="${PORT:-8000}"
BOOT_PORT="${WINDMILL_BOOT_PORT:-8079}"
DEFAULT_EMAIL="admin@windmill.dev"
ADMIN_EMAIL="${WINDMILL_ADMIN_EMAIL:-}"
[ -n "$ADMIN_EMAIL" ] || ADMIN_EMAIL="$DEFAULT_EMAIL"
API="http://127.0.0.1:${BOOT_PORT}/api"

login() {
  jq -n --arg e "$1" --arg p "$2" '{email: $e, password: $p}' |
    curl -fsS -X POST -H 'Content-Type: application/json' --data @- "$API/auth/login" 2>/dev/null
}

post_json() { # token path json
  printf '%s' "$3" |
    curl -fsS -X POST -H "Authorization: Bearer $1" -H 'Content-Type: application/json' --data @- "$API$2" >/dev/null
}

log "starting Windmill on 127.0.0.1:${BOOT_PORT} (runs migrations on first boot)"
PORT="$BOOT_PORT" SERVER_BIND_ADDR=127.0.0.1 windmill &
BOOT_PID=$!

stop_boot() {
  kill "$BOOT_PID" 2>/dev/null || true
  wait "$BOOT_PID" 2>/dev/null || true
}

i=0
until curl -fsS -o /dev/null "$API/version" 2>/dev/null; do
  if ! kill -0 "$BOOT_PID" 2>/dev/null; then
    log "Windmill exited during startup"
    exit 1
  fi
  i=$((i + 1))
  if [ "$i" -ge 900 ]; then
    log "Windmill did not answer on the local port within 900 s"
    stop_boot
    exit 1
  fi
  sleep 1
done

if TOKEN="$(login "$DEFAULT_EMAIL" changeme)" && [ -n "$TOKEN" ]; then
  log "default superadmin still has the default password: securing it"
  if [ "$ADMIN_EMAIL" = "$DEFAULT_EMAIL" ]; then
    post_json "$TOKEN" /users/setpassword "$(jq -n --arg p "$WINDMILL_ADMIN_PASSWORD" '{password: $p}')"
  else
    post_json "$TOKEN" /users/create "$(jq -n --arg e "$ADMIN_EMAIL" --arg p "$WINDMILL_ADMIN_PASSWORD" \
      '{email: $e, password: $p, super_admin: true, name: "Admin"}')"
    TOKEN="$(login "$ADMIN_EMAIL" "$WINDMILL_ADMIN_PASSWORD")"
    curl -fsS -X DELETE -H "Authorization: Bearer $TOKEN" "$API/users/delete/$DEFAULT_EMAIL" >/dev/null
  fi
  if [ -n "${BASE_URL:-}" ]; then
    post_json "$TOKEN" /settings/global/base_url "$(jq -n --arg v "$BASE_URL" '{value: $v}')"
    log "base URL set to $BASE_URL"
  fi
  if login "$DEFAULT_EMAIL" changeme >/dev/null; then
    log "the default login still works after the change: refusing to start"
    stop_boot
    exit 1
  fi
  log "superadmin is $ADMIN_EMAIL; its password is the WINDMILL_ADMIN_PASSWORD variable"
else
  log "default login is already disabled: nothing to do"
fi

stop_boot
log "starting Windmill on port ${PUBLIC_PORT}"
export PORT="$PUBLIC_PORT"
export SERVER_BIND_ADDR="${SERVER_BIND_ADDR:-::}"
exec windmill
