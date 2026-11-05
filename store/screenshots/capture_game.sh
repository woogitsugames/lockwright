#!/usr/bin/env bash
# Store screenshots from the REAL game (session C, stage 3, task 6). Renders game scenes at native store size
# (1320x2868, iPhone 6.9") on a copy of game/, then make_screens.py --from-game adds the caption band.
#   store/screenshots/capture_game.sh [godot] [outdir]      (needs X: Xvfb :99 or a desktop; lockcore_gd built)
# Lock screen: plan B scene with its own dev args (--lw-sim/--lw-shot, lock_photoreal.gd). Menus: --write-movie.
set -euo pipefail
GODOT=${1:-godot}
OUTDIR=${2:-$(cd "$(dirname "$0")" && pwd)/game_raw}
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
WORK=${SHOTS_WORK:-/tmp/lw_store_game}
RES=1320x2868
export DISPLAY=${DISPLAY:-:99}
rm -rf "$WORK" && cp -r "$ROOT/game" "$WORK" && rm -rf "$WORK/.godot"
"$GODOT" --headless --path "$WORK" --import >/dev/null 2>&1 || true
mkdir -p "$OUTDIR"
lock() {  # name, args...
  local name=$1; shift
  timeout 180 "$GODOT" --path "$WORK" --resolution $RES res://scenes/photoreal/lock_photoreal.tscn -- \
    --lw-shot "$OUTDIR/$name.png" --lw-frames 30 "$@" 2>&1 | grep -E "^SHOT|ERROR" || true
}
lock lock_early   --lw-seed 42  --lw-sim 400  --lw-touch 1
lock lock_late    --lw-seed 42  --lw-sim 1100 --lw-touch 1
lock lock_spool   --lw-seed 7   --lw-tier 3 --lw-sim 700
lock lock_dark    --lw-seed 42  --lw-sim 600  --lw-dark 1
lock lock_lastpick --lw-seed 42 --lw-sim 500  --lw-lives 1
menu() {  # name, scene: last frame of a 40-frame movie
  local name=$1 scene=$2 tmp="$WORK/movie_$1"
  mkdir -p "$tmp"
  timeout 180 "$GODOT" --path "$WORK" --resolution $RES --fixed-fps 30 --write-movie "$tmp/f.png" --quit-after 40 "$scene" >/dev/null 2>&1 || true
  local last; last=$(ls "$tmp"/f*.png 2>/dev/null | sort | tail -1)
  [ -n "$last" ] && cp "$last" "$OUTDIR/$name.png" && echo "SHOT $OUTDIR/$name.png"
}
menu jobs_list res://scenes/jobs_list.tscn
menu workshop  res://scenes/workshop.tscn
menu showcase  res://scenes/showcase.tscn
