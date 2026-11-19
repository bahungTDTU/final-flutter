#!/usr/bin/env bash
set -euo pipefail
umask 077

revision=${1:?Expected a Git commit SHA}
export NOTETOGETHER_HOST=${2:?Expected the public DNS name}
if [[ ! $revision =~ ^[0-9a-f]{40}$ || ! $NOTETOGETHER_HOST =~ ^[a-z0-9.-]+$ ]]; then
  echo "Invalid release revision or hostname." >&2
  exit 1
fi

base="$HOME/.local/share/notetogether"
env_file="$HOME/.config/notetogether/backend.env"
archive="$base/incoming/$revision.tar.gz"
test -f "$env_file"
mkdir -p "$base/releases"
exec 9>"$base/release.lock"
flock 9

release=$(mktemp -d "$base/releases/$revision.XXXXXXXX")
tar -xzf "$archive" -C "$release"
test "$(cat "$release/build/web/deploy-revision.txt")" = "$revision"

compose_at() {
  local directory=$1
  shift
  docker compose --project-name notetogether --env-file "$env_file" \
    --project-directory "$directory" -f "$directory/compose.yaml" \
    -f "$directory/deploy/azure/compose.yaml" "$@"
}

verify_release() {
  local served
  served=$(curl --fail --silent --show-error --retry 12 --retry-all-errors \
    --retry-delay 5 --max-time 10 "https://$NOTETOGETHER_HOST/deploy-revision.txt") || return
  [[ $served == "$revision" ]] || return 1
  curl --fail --silent --show-error --max-time 10 "https://$NOTETOGETHER_HOST/health" |
    python3 -c 'import json, sys; sys.exit(json.load(sys.stdin).get("status") != "ok")'
}

if ! compose_at "$release" up -d --build --wait --wait-timeout 90 || ! verify_release; then
  if [[ -L "$base/current" ]]; then
    echo "Deployment failed, restoring the previous service revision." >&2
    compose_at "$(readlink "$base/current")" up -d --build --wait --wait-timeout 90
  fi
  exit 1
fi

ln -s "$release" "$release/current-link"
mv -Tf "$release/current-link" "$base/current"
rm -- "$archive"
printf 'Verified %s at https://%s\n' "$revision" "$NOTETOGETHER_HOST"
