#!/usr/bin/env bash
# Compares the migrations applied to the local Supabase database with the ones in this
# checkout. All workspaces share one local stack, so a migration from another branch can
# already be applied here, or one of this branch's can be missing. Warns, never changes
# anything. Exits 1 on drift, 0 when in sync or when the stack isn't running.
#
#   scripts/db-drift.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MIGRATIONS="$ROOT/apps/supabase/migrations"
PROJECT_ID="$(sed -n 's/^project_id = "\(.*\)"/\1/p' "$ROOT/apps/supabase/config.toml")"
CONTAINER="supabase_db_$PROJECT_ID"

if ! docker ps --format '{{.Names}}' 2>/dev/null | grep -qx "$CONTAINER"; then
  echo "db-drift: $CONTAINER is not running, skipped."
  exit 0
fi

applied="$(docker exec "$CONTAINER" psql -U postgres -d postgres -t -A \
  -c "SELECT version FROM supabase_migrations.schema_migrations ORDER BY 1;")"
local_versions="$(for f in "$MIGRATIONS"/*.sql; do basename "$f" | cut -d_ -f1; done | sort)"

missing="$(comm -13 <(echo "$applied" | sort) <(echo "$local_versions"))"
foreign="$(comm -23 <(echo "$applied" | sort) <(echo "$local_versions"))"

[ -z "$missing" ] && [ -z "$foreign" ] && { echo "db-drift: local database matches this branch."; exit 0; }

if [ -n "$missing" ]; then
  echo "db-drift: in this branch but not applied (run ./scripts/seed.sh):"
  echo "$missing" | sed 's/^/  /'
fi
if [ -n "$foreign" ]; then
  echo "db-drift: applied but not in this branch (another workspace's migrations; ./scripts/seed.sh --reset to drop them):"
  echo "$foreign" | sed 's/^/  /'
fi
exit 1
