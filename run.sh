#!/usr/bin/env bash
# run.sh — Loads .env and runs the app with dart-defines injected.
# Usage:
#   ./run.sh                    # run on default device
#   ./run.sh -d chrome          # run on Chrome (web)
#   ./run.sh -d macos           # run on macOS
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "❌  .env file not found. Copy .env.example to .env and fill in your values."
  exit 1
fi

# Parse .env — skip blank lines and comments
DEFINES=""
while IFS= read -r line || [[ -n "$line" ]]; do
  [[ "$line" =~ ^[[:space:]]*$ ]] && continue   # blank
  [[ "$line" =~ ^[[:space:]]*# ]]  && continue  # comment
  key="${line%%=*}"
  val="${line#*=}"
  DEFINES="$DEFINES --dart-define=$key=$val"
done < "$ENV_FILE"

echo "▶  flutter run $DEFINES $*"
# shellcheck disable=SC2086
flutter run $DEFINES "$@"

