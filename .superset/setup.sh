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

# Base branch (AGENTS.md §11): the one picked when the workspace was created (Superset's base
# picker or `--base-branch`, saved as branch.<name>.base), else the newest release/*.
# Offline or no base: the workspace keeps what it has and setup carries on.
git fetch -q origin 2>/dev/null || true
branch=$(git branch --show-current)
base=$(git config "branch.$branch.base" 2>/dev/null || true)
if [ -z "$base" ] || [ "$base" = main ]; then
  base=$(git for-each-ref --format='%(refname:lstrip=3)' 'refs/remotes/origin/release/*' | sort -V | tail -n 1)
fi
if [ -n "$base" ] && [ -n "$branch" ] && git rev-parse -q --verify "origin/$base" >/dev/null; then
  # Superset can fork from a stale local ref. Catch a fresh branch up to origin/<base>, but only
  # when that is a fast-forward and the tree is clean, so no work is ever dropped.
  if [ -z "$(git status --porcelain --untracked-files=no)" ] && git merge-base --is-ancestor HEAD "origin/$base"; then
    git merge -q --ff-only "origin/$base"
    echo "$branch starts from origin/$base"
  fi
  git config "branch.$branch.gh-merge-base" "$base"
  echo "PRs from $branch target $base"
fi

pnpm install --frozen-lockfile
