#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT_DIR/ages_app"
BUILD_DIR="$APP_DIR/build/web"

if [[ ! -d "$BUILD_DIR" ]]; then
  echo "Error: Flutter web build output was not found at $BUILD_DIR."
  exit 1
fi

if [[ -f "$BUILD_DIR/.last_build_id" ]]; then
  CACHE_VERSION="$(tr -cd '[:alnum:]._-' < "$BUILD_DIR/.last_build_id")"
else
  CACHE_VERSION="$(date -u +%Y%m%d%H%M%S)"
fi

sed "s/__AGES_CACHE_VERSION__/$CACHE_VERSION/g" \
  "$APP_DIR/web/ages_service_worker.js" > "$BUILD_DIR/ages_service_worker.js"

if ! grep -q 'ages_service_worker.js' "$BUILD_DIR/flutter_bootstrap.js"; then
  echo "Error: Flutter bootstrap is not configured to register ages_service_worker.js."
  exit 1
fi

if grep -q '__AGES_CACHE_VERSION__' "$BUILD_DIR/ages_service_worker.js"; then
  echo "Error: Ages service worker cache version was not replaced."
  exit 1
fi
