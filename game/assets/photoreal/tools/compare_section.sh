#!/bin/bash
# Cycles reference vs the photoreal lock screen (section part of a portrait shot).
#   game/assets/photoreal/tools/compare_section.sh SHOT.png OUT_PREFIX [REF=art/renders/section.png]
# The section occupies the top W x W*4/3 of a portrait shot (LockPhotorealView layout).
set -e
SHOT=$1; OUT=$2; REF=${3:-art/renders/section.png}
TMP=$(mktemp -d)
python3 - "$SHOT" "$TMP/section.png" <<'PY'
import sys
from PIL import Image
im = Image.open(sys.argv[1]).convert('RGB'); w = im.size[0]
im.crop((0, 0, w, round(w * 1650 / 1236))).save(sys.argv[2])
PY
python3 "$(dirname "$0")/../../../../spikes/lit-metal/tools/compare.py" "$REF" "$TMP/section.png" "$OUT" --label "Godot (gra)"
rm -rf "$TMP"
