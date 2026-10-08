#!/usr/bin/env bash
# Stops the dev server this workspace started and removes its Xcode build products.
# The local Supabase stack (fixed ports, container supabase_db_food) is shared by all
# workspaces and is left running.
cd "$(dirname "$0")/.."
here="$(pwd -P)"

if [ -f .superset/.web-port ]; then
  PORT="$(cat .superset/.web-port)"
  # Only kill listeners whose cwd is inside this workspace.
  for pid in $(lsof -nP -tiTCP:"$PORT" -sTCP:LISTEN 2>/dev/null); do
    if lsof -p "$pid" -a -d cwd -Fn 2>/dev/null | grep -q "^n$here"; then
      kill "$pid" 2>/dev/null || true
    fi
  done
  rm -f .superset/.web-port
fi

# Xcode keeps one DerivedData folder per project path (1–3 GB each) and never removes
# it. Delete only the ones whose recorded project lives inside this workspace.
for dd in "$HOME"/Library/Developer/Xcode/DerivedData/NomNom-*; do
  [ -f "$dd/info.plist" ] || continue
  project="$(plutil -extract WorkspacePath raw "$dd/info.plist" 2>/dev/null || true)"
  if [[ -n "$project" && "$project" == "$here/"* ]]; then
    rm -rf "$dd"
    echo "removed $dd"
  fi
done
exit 0
