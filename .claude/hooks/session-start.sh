#!/usr/bin/env bash
set -euo pipefail

git fetch origin main

branch="$(git rev-parse --abbrev-ref HEAD)"

if [ "$branch" = "main" ]; then
  echo "On main — fast-forwarding to origin/main"
  git merge --ff-only origin/main
elif [ "$(git rev-list --count origin/main..HEAD)" = "0" ]; then
  echo "Fresh branch '$branch' — rebasing onto origin/main"
  git rebase origin/main
else
  echo "Branch '$branch' has local commits — leaving history alone"
fi

# Idempotent setup: fetch deps, create+migrate+seed the DB, install/build assets.
mix setup
