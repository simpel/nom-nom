#!/usr/bin/env bash
# Starts the web dev server on a free port so parallel workspaces don't collide,
# and the iOS app in the simulator (scripts/ios-run.sh).
set -euo pipefail

cd "$(dirname "$0")/.."

port_free() { ! lsof -nP -iTCP:"$1" -sTCP:LISTEN >/dev/null 2>&1; }

PORT="${WEB_PORT:-3060}"
while ! port_free "$PORT"; do PORT=$((PORT + 1)); done

echo "$PORT" > .superset/.web-port
echo "Web dev server: http://localhost:$PORT"

# iOS: build, install and launch in the simulator next to the web server.
# A failed iOS build doesn't stop the web server.
# All workspaces share one simulator, so first stop any iOS session another
# workspace (or an earlier run) left streaming, and quit InjectionNext: it adds
# every launching workspace to its watch list until it restarts. ios-run.sh
# starts it again, watching only this workspace.
pkill -f "scripts/ios-run.sh" 2>/dev/null || true
pkill -f "simctl launch --console-pty .* se.joelsanden.nomnom" 2>/dev/null || true
if pgrep -xq InjectionNext; then
  pkill -x InjectionNext || true
  while pgrep -xq InjectionNext; do sleep 0.2; done
fi

./scripts/ios-run.sh &
IOS_PID=$!
# Stop the iOS session's children (simctl launch) too, not just the script.
trap 'pkill -P "$IOS_PID" 2>/dev/null || true; kill "$IOS_PID" 2>/dev/null || true' EXIT

pnpm --filter web exec next dev --port "$PORT"
