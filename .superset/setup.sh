#!/bin/sh
# Point `gh pr create` at the newest release/* branch instead of main (AGENTS.md §12).
# Never fails the workspace: offline or no release branch just leaves gh on its default.

git fetch -q origin '+refs/heads/release/*:refs/remotes/origin/release/*' 2>/dev/null
REL=$(git for-each-ref --format='%(refname:lstrip=3)' 'refs/remotes/origin/release/*' | sort -V | tail -n 1)
BRANCH=$(git branch --show-current)

if [ -n "$REL" ] && [ -n "$BRANCH" ]; then
  git config "branch.$BRANCH.gh-merge-base" "$REL"
  echo "PRs from $BRANCH target $REL"
else
  echo "No release/* branch found; PRs fall back to the repo default branch"
fi
