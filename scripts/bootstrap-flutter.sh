#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
flutter_dir="$repo_root/.tool/flutter"
flutter_bin="$flutter_dir/bin/flutter"

if [[ ! -x "$flutter_bin" ]]; then
  mkdir -p "$(dirname "$flutter_dir")"
  git clone --depth 1 --branch stable https://github.com/flutter/flutter.git "$flutter_dir"
fi

export PATH="$flutter_dir/bin:$PATH"

flutter config --no-analytics
flutter --version
flutter doctor

cat <<EOF

Flutter is available for this shell at:
  $flutter_bin

For future terminal sessions, run:
  export PATH="$flutter_dir/bin:\$PATH"
EOF