#!/usr/bin/env bash
# QA career run (session C, stage 3, task 3). Builds a COPY of game/ (game/ is not modified) with the bot
# under res://qa_bot, isolates user:// in a fresh directory, runs Godot headless with a fixed 120 FPS
# step, then writes qa/out/report.{json,md} and the full log.
#   qa/run_career.sh [godot-binary] [timeout-seconds]
# Env: QA_PROFILE, QA_LANG, QA_DARK (qa/run_matrix.sh), QA_PACKS=download|bundled (default download, D-131).
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/.." && pwd)
GODOT=${1:-godot}
TIMEOUT=${2:-1800}
WORK=${QA_WORK:-/tmp/lw_qa_game}
OUT=${QA_OUT:-$HERE/out}
rm -rf "$WORK" && cp -r "${QA_GAME:-$ROOT/game}" "$WORK" && rm -rf "$WORK/.godot"
mkdir -p "$WORK/qa_bot" "$OUT"
cp "$HERE/bot/"*.gd "$WORK/qa_bot/"
cp "$ROOT/lockcore/tiers.json" "$WORK/qa_bot/tiers.json"  # D-118/D-120: the bot clamps job tiers to lockcore's ranges
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
# D-131: chapters 13+ are content packs (game/packs/<id>/). Build them from the copy with the real
# Godot export, pin their size and SHA-256 in the copy's list (data/content_packs.json), then remove
# the source folders and their imported files: the career starts like an exported build without the
# packs, and the bot fetches each chapter through the job list's Download plate (a file copy from
# QA_PACKS_DIR instead of HTTPS; hash check and mount are the game's own code).
# QA_PACKS=bundled keeps the source folders in the copy (editor behaviour: nothing is fetched).
if [ "${QA_PACKS:-download}" != "bundled" ] && ls "$WORK"/packs/*/pack.json > /dev/null 2>&1; then
  PACKS_OUT="${WORK}_packs"
  rm -rf "$PACKS_OUT"
  if ! python3 "$ROOT/tools/build_content_packs.py" --game "$WORK" --godot "$GODOT" --out "$PACKS_OUT" --write-game-manifest > "$OUT/packs.log" 2>&1; then
    echo "::error title=QA workflow::content packs did not build (qa/out/.../packs.log)"; tail -20 "$OUT/packs.log"; exit 3
  fi
  python3 - "$WORK" <<'PY'
import glob, hashlib, os, shutil, sys
work = sys.argv[1]
packs = os.path.join(work, "packs")
for base, _dirs, files in os.walk(packs):
    for f in files:
        res = "res://" + os.path.relpath(os.path.join(base, f), work).replace(os.sep, "/")
        for imported in glob.glob(os.path.join(work, ".godot", "imported", "%s-%s.*" % (f, hashlib.md5(res.encode()).hexdigest()))):
            os.remove(imported)
shutil.rmtree(packs)
PY
  export QA_PACKS_DIR="$PACKS_OUT"
fi
START=$(date +%s)
timeout "$TIMEOUT" "$GODOT" --headless --path "$WORK" --fixed-fps 120 -s res://qa_bot/career.gd > "$OUT/career.log" 2>&1
CODE=$?
END=$(date +%s)
echo "exit_code=$CODE wall_s=$((END-START))" >> "$OUT/career.log"
python3 "$HERE/report.py" "$OUT/career.log" "$OUT" "$CODE"
