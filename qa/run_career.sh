#!/usr/bin/env bash
# QA career run (session C, stage 3, task 3). Builds a COPY of game/ (game/ is not modified) with the bot
# under res://qa_bot, isolates user:// in a fresh directory, runs Godot headless with a fixed 120 FPS
# step, then writes qa/out/report.{json,md} and the full log.
#   qa/run_career.sh [godot-binary] [timeout-seconds]
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/.." && pwd)
GODOT=${1:-godot}
TIMEOUT=${2:-1800}
WORK=${QA_WORK:-/tmp/lw_qa_game}
OUT="$HERE/out"
rm -rf "$WORK" && cp -r "$ROOT/game" "$WORK" && rm -rf "$WORK/.godot"
mkdir -p "$WORK/qa_bot" "$OUT"
cp "$HERE/bot/"*.gd "$WORK/qa_bot/"
# fresh user:// (custom user dir name) so every run starts a new career
python3 - "$WORK/project.godot" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
if '[application]' in s:
    s = s.replace('[application]\n', '[application]\n\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="lockwright_qa"\n', 1)
open(p, 'w').write(s)
PY
rm -rf "$HOME/.local/share/lockwright_qa"
"$GODOT" --headless --path "$WORK" --import > "$OUT/import.log" 2>&1
START=$(date +%s)
timeout "$TIMEOUT" "$GODOT" --headless --path "$WORK" --fixed-fps 120 -s res://qa_bot/career.gd > "$OUT/career.log" 2>&1
CODE=$?
END=$(date +%s)
echo "exit_code=$CODE wall_s=$((END-START))" >> "$OUT/career.log"
python3 "$HERE/report.py" "$OUT/career.log" "$OUT" "$CODE"
