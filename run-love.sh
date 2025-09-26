#!/usr/bin/env bash
set -euo pipefail

# Helper to run LÖVE correctly from the project root.
# LÖVE expects a directory (containing main.lua), not a path to main.lua itself.

ROOT_DIR=$(cd "$(dirname "$0")" && pwd)

if ! command -v love >/dev/null 2>&1; then
  echo "Error: 'love' (LÖVE 2D) is not installed or not on PATH."
  echo "Visit https://love2d.org/ to install LÖVE for your platform."
  exit 2
fi

echo "Starting LÖVE from: $ROOT_DIR"
love "$ROOT_DIR"
