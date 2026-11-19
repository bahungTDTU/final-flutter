#!/usr/bin/env bash
set -euo pipefail

revision=${1:?Expected a Git commit SHA}
archive=${2:?Expected an output archive path}
if [[ ! $revision =~ ^[0-9a-f]{40}$ ]]; then
  echo "Invalid release revision." >&2
  exit 1
fi

test -f build/web/index.html
test -f build/web/main.dart.js
printf '%s\n' "$revision" > build/web/deploy-revision.txt
python scripts/prepare_web_offline.py
tar -czf "$archive" .dockerignore compose.yaml backend/Dockerfile backend/requirements.txt \
  backend/schema.sql backend/*.py deploy/azure/compose.yaml deploy/azure/Caddyfile build/web
