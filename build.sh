#!/usr/bin/env bash
# build.sh — Loads .env and builds the app with dart-defines injected.
# Usage:
#   ./build.sh web              # build for web
#   ./build.sh apk              # build Android APK
#   ./build.sh ios              # build iOS
#   ./build.sh macos            # build macOS
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "❌  .env file not found. Copy .env.example to .env and fill in your values."
  exit 1
fi

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  echo "Usage: ./build.sh [web|apk|ios|macos|appbundle] [additional flutter build flags]"
  exit 0
fi

TARGET="${1:-web}"
shift || true   # allow no extra args

DEFINES=""
while IFS= read -r line || [[ -n "$line" ]]; do
  [[ "$line" =~ ^[[:space:]]*$ ]] && continue
  [[ "$line" =~ ^[[:space:]]*# ]]  && continue
  key="${line%%=*}"
  val="${line#*=}"
  DEFINES="$DEFINES --dart-define=$key=$val"
done < "$ENV_FILE"

echo "▶  flutter build $TARGET $DEFINES $*"
# shellcheck disable=SC2086
flutter build "$TARGET" $DEFINES "$@"

