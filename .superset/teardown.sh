#!/usr/bin/env bash
# Stops the dev server this workspace started. The local Supabase stack
# (fixed ports, container supabase_db_food) is shared by all workspaces and is left running.
cd "$(dirname "$0")/.."

if [ -f .superset/.web-port ]; then
  PORT="$(cat .superset/.web-port)"
  # Only kill listeners whose cwd is inside this workspace.
  for pid in $(lsof -nP -tiTCP:"$PORT" -sTCP:LISTEN 2>/dev/null); do
    if lsof -p "$pid" -a -d cwd -Fn 2>/dev/null | grep -q "^n$PWD"; then
      kill "$pid" 2>/dev/null || true
    fi
  done
  rm -f .superset/.web-port
fi
exit 0
