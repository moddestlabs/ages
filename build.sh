#!/usr/bin/env bash

# Build and serve the LightSword Ages web app.
# Usage: ./build.sh [--clean] [--port PORT]

set -euo pipefail

PORT=8080
CLEAN=false
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$ROOT_DIR/ages_app"
LOCAL_FLUTTER="$ROOT_DIR/.tool/flutter/bin"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --clean)
      CLEAN=true
      shift
      ;;
    --port)
      if [[ $# -lt 2 || ! "$2" =~ ^[0-9]+$ ]]; then
        echo "Error: --port requires a numeric port."
        exit 1
      fi
      PORT="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 [--clean] [--port PORT]"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [--clean] [--port PORT]"
      exit 1
      ;;
  esac
done

if [[ -x "$LOCAL_FLUTTER/flutter" ]]; then
  export PATH="$LOCAL_FLUTTER:$PATH"
fi

if ! command -v flutter >/dev/null 2>&1; then
  echo "Error: flutter was not found. Run scripts/bootstrap-flutter.sh first."
  exit 1
fi

echo "Checking for existing demo servers..."
if pgrep -f "python3? -m http.server" >/dev/null 2>&1; then
  echo "Stopping existing Python HTTP servers..."
  pkill -f "python3? -m http.server" || true
fi

if command -v lsof >/dev/null 2>&1; then
  PORT_PIDS="$(lsof -tiTCP:"$PORT" -sTCP:LISTEN 2>/dev/null || true)"
  if [[ -n "$PORT_PIDS" ]]; then
    echo "Stopping process listening on port $PORT..."
    kill $PORT_PIDS || true
  fi
fi

if command -v fuser >/dev/null 2>&1; then
  fuser -k "$PORT/tcp" >/dev/null 2>&1 || true
fi

cd "$APP_DIR"

echo "Building LightSword Ages web app..."

if [[ "$CLEAN" == true ]]; then
  echo "Cleaning previous build..."
  flutter clean
fi

flutter pub get
flutter build web --release --base-href / --no-wasm-dry-run

if [[ ! -d "build/web" ]]; then
  echo "Error: build failed; ages_app/build/web was not created."
  exit 1
fi

# Local content iteration should not be hidden behind a stale Flutter PWA cache.
rm -f build/web/flutter_service_worker.js
find build/web -name 'flutter_service_worker.js*' -delete
perl -0pi -e 's/_flutter\.loader\.load\(\{\s*serviceWorkerSettings:\s*\{\s*serviceWorkerVersion:\s*"[^"]+"\s*\/\* Flutter.*?\*\/\s*\}\s*\}\);/_flutter.loader.load();/s' build/web/flutter_bootstrap.js

cd build/web

echo "Build complete."
echo "Serving http://localhost:$PORT"
echo "Press Ctrl+C to stop the server."

python3 -m http.server "$PORT"