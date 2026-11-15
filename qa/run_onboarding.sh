#!/usr/bin/env bash
# Onboarding walk (D-134): a fresh install from boot through the tutorial and the first jobs, measured
# (qa/bot/onboarding.gd). game/ is used in place (it must be imported and have the lockcore
# GDExtension); the save and settings go to a fresh directory, so every run is a first launch.
#   qa/run_onboarding.sh [godot-binary] [out-dir]
# Env: QA_PROFILE feel|clumsy|solver, QA_LANG pl|en, QA_JOBS n, QA_TWO_THUMBS 1, QA_REPLAY_TOOL
#      (lockcore/build/replay_tool, for feel/clumsy), QA_SHOTS dir + QA_WINDOW 412x915 (needs xvfb-run:
#      a PNG of every screen), QA_READ_WPM, QA_TAP_S.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/.." && pwd)
GODOT=${1:-godot}
OUT=${2:-$HERE/out/onboarding}
mkdir -p "$OUT"
DATA=$(mktemp -d)
trap 'rm -rf "$DATA"' EXIT
export XDG_DATA_HOME="$DATA" XDG_CONFIG_HOME="$DATA/config"
# the language is a setting made before the first launch (the phone's language): boot reads it
USERDIR="$DATA/godot/app_userdata/$(sed -n 's/^config\/name="\(.*\)"$/\1/p' "$ROOT/game/project.godot" | head -1)"
mkdir -p "$USERDIR"
if [ -n "${QA_LANG:-}" ]; then
  printf '[settings]\n\nlanguage="%s"\n' "$QA_LANG" > "$USERDIR/settings.cfg"
fi
if [ -z "${QA_REPLAY_TOOL:-}" ] && [ -x "$ROOT/lockcore/build/replay_tool" ]; then
  export QA_REPLAY_TOOL="$ROOT/lockcore/build/replay_tool"
fi
if [ -n "${QA_SHOTS:-}" ]; then
  xvfb-run -a -s "-screen 0 1000x1000x24" "$GODOT" --path "$ROOT/game" --display-driver x11 --rendering-driver opengl3 \
    --resolution "${QA_WINDOW:-412x915}" -s "$HERE/bot/onboarding.gd" > "$OUT/walk.log" 2>&1
else
  "$GODOT" --headless --path "$ROOT/game" --fixed-fps 120 -s "$HERE/bot/onboarding.gd" > "$OUT/walk.log" 2>&1
fi
CODE=$?
grep -E '^ONB_(STEP|TAP|WAIT|MARK|LOCK)' "$OUT/walk.log" > "$OUT/walk.txt" || true
grep '^ONB_REPORT ' "$OUT/walk.log" | sed 's/^ONB_REPORT //' > "$OUT/report.json"
python3 "$HERE/onboarding_report.py" "$OUT/report.json" || CODE=1
exit $CODE
