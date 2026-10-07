#!/usr/bin/env bash
# Runs once when a Superset workspace is created. Keep it fast.
set -euo pipefail

: "${SUPERSET_ROOT_PATH:?SUPERSET_ROOT_PATH is not set}"

# Untracked files the app needs (secrets, signing assets). Missing ones are skipped.
FILES=(
  "apps/web/.env.local"
  "apps/supabase/functions/.env"
  "apps/ios/NomNom.mobileprovision"
  ".claude/settings.local.json"
)
for f in "$SUPERSET_ROOT_PATH"/apps/ios/AuthKey_*.p8; do
  [ -e "$f" ] && FILES+=("${f#"$SUPERSET_ROOT_PATH"/}")
done

for f in "${FILES[@]}"; do
  src="$SUPERSET_ROOT_PATH/$f"
  if [ -f "$src" ]; then
    mkdir -p "$(dirname "$f")"
    cp "$src" "$f"
    echo "copied $f"
  else
    echo "skipped $f (not in root)"
  fi
done

pnpm install --frozen-lockfile
