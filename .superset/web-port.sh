#!/usr/bin/env bash
# Prints this workspace's web dev server port. The first call claims the lowest port
# from 3060 up that no other worktree has claimed and nothing listens on, and saves it
# in .superset/.web-port, so a workspace keeps the same port across runs.
set -euo pipefail
cd "$(dirname "$0")/.."

if [ -s .superset/.web-port ]; then cat .superset/.web-port; exit 0; fi

here="$(pwd -P)"
claimed=" "
while IFS= read -r wt; do
  [ "$wt" = "$here" ] && continue
  [ -s "$wt/.superset/.web-port" ] && claimed+="$(cat "$wt/.superset/.web-port") "
done < <(git worktree list --porcelain | sed -n 's/^worktree //p')

port="${WEB_PORT:-3060}"
while [[ "$claimed" == *" $port "* ]] || lsof -nP -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1; do
  port=$((port + 1))
done

echo "$port" > .superset/.web-port
echo "$port"
