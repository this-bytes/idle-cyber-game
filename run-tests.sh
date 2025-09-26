#!/usr/bin/env bash
set -euo pipefail

if ! command -v busted >/dev/null 2>&1; then
  echo "busted is required to run tests. Install with luarocks: luarocks install busted"
  exit 2
fi

echo "Running busted specs..."
busted --verbose spec
