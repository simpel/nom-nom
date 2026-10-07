#!/usr/bin/env bash
# Starts the web dev server on a free port so parallel workspaces don't collide.
set -euo pipefail

cd "$(dirname "$0")/.."

port_free() { ! lsof -nP -iTCP:"$1" -sTCP:LISTEN >/dev/null 2>&1; }

PORT="${WEB_PORT:-3060}"
while ! port_free "$PORT"; do PORT=$((PORT + 1)); done

echo "$PORT" > .superset/.web-port
echo "Web dev server: http://localhost:$PORT"
exec pnpm --filter web exec next dev --port "$PORT"
