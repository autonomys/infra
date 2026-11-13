#!/usr/bin/env bash
# Shows what has changed in autonomys/auto-drive since the commit the backend
# role's compose file mirrors, in the files the role follows: the compose file
# and nginx configs it copies, the playbook that deploys them, and what decides
# the backend image's settings, layout and migrations. Reads only.
# Usage: ./upstream-diff.sh [upstream branch, tag or commit; default main]
# Exits 1 when something has changed, like diff.
set -euo pipefail

REPO="https://github.com/autonomys/auto-drive.git"
COMPOSE_FILE="$(dirname "$0")/compose/docker-compose.yml"
TARGET="${1:-main}"
PATHS=(
  docker-compose.prod.yml
  ansible/auto-drive-deployment.yml
  nginx
  .dockerignore
  apps/backend/Dockerfile
  apps/backend/package.json
  apps/backend/src/config.ts
  apps/backend/.env.sample
  apps/hasura/config.yaml
  apps/hasura/migrations
)

mirrored="$(sed -n 's/^# upstream: \([0-9a-f]\{40\}\)$/\1/p' "$COMPOSE_FILE")"
if [ -z "$mirrored" ]; then
  echo "No '# upstream: <full commit SHA>' line in $COMPOSE_FILE" >&2
  exit 2
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
git clone -q --filter=blob:none --no-checkout "$REPO" "$tmp"
git -C "$tmp" fetch -q origin "$TARGET"
target="$(git -C "$tmp" rev-parse FETCH_HEAD)"

echo "Compose file mirrors ${mirrored:0:8}; upstream $TARGET is ${target:0:8}"
changes="$(git -C "$tmp" log --oneline "$mirrored..$target" -- "${PATHS[@]}")"
if [ -z "$changes" ]; then
  echo "Nothing the role follows has changed."
  exit 0
fi
echo "$changes"
echo ""
git -C "$tmp" --no-pager diff "$mirrored" "$target" -- "${PATHS[@]}"
exit 1
