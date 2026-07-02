#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="TuckBar"
DIST_DIR="$ROOT_DIR/dist"

"$ROOT_DIR/script/build_and_run.sh" --verify
pkill -x "$APP_NAME" >/dev/null 2>&1 || true

cd "$DIST_DIR"
ditto -c -k --keepParent "$APP_NAME.app" "$APP_NAME.zip"
echo "$DIST_DIR/$APP_NAME.zip"
