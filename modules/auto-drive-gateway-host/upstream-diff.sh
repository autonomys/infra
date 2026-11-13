#!/usr/bin/env bash
# Shows what has changed in autonomys/auto-files-gateway since the commit the
# gateway role's compose file mirrors, in the files it follows: the compose files
# and the apps' settings and migrations. Reads only.
# Usage: ./upstream-diff.sh [upstream branch, tag or commit; default main]
# Exits 1 when something has changed, like diff.
set -euo pipefail

REPO="https://github.com/autonomys/auto-files-gateway.git"
COMPOSE_FILE="$(dirname "$0")/docker-compose.yml"
TARGET="${1:-main}"
PATHS=(docker/file-retriever docker/object-mapping-indexer 'services/*/src/config.ts' 'services/*/migrations')

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
  echo "Nothing the compose file follows has changed."
  exit 0
fi
echo "$changes"
echo ""
git -C "$tmp" --no-pager diff "$mirrored" "$target" -- "${PATHS[@]}"
exit 1
