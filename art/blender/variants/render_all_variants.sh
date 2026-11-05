#!/usr/bin/env bash
# Single-command batch renderer for Lockwright GEM4 cutaway variants (1, 3, 5, 6, 7 pins + wrench-in-frame + Plan B plates).
# Usage:
#   bash art/blender/variants/render_all_variants.sh
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
BLENDER="${BLENDER:-blender}"

if ! command -v "$BLENDER" >/dev/null 2>&1; then
  if [ -x "/c/Program Files/Blender Foundation/Blender 5.2/blender.exe" ]; then
    BLENDER="/c/Program Files/Blender Foundation/Blender 5.2/blender.exe"
  elif [ -x "/Applications/Blender.app/Contents/MacOS/Blender" ]; then
    BLENDER="/Applications/Blender.app/Contents/MacOS/Blender"
  fi
fi

"$BLENDER" -b -P "$HERE/render_all_variants.py" -- "$@"
