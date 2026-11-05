#!/usr/bin/env bash
# QA part 2 (session C, stage 4, task 5): the career under several player profiles and settings.
#   qa/run_matrix.sh [godot] [replay_tool]     -> qa/out/<run>/report.{md,json}, qa/out/matrix.md
# Runs: solver (PL), feel = "average" player, clumsy player (lockcore native bots via replay_tool --feel/--clumsy),
# English (QA_LANG=en) and "in the dark" (QA_DARK=1). Needs lockcore/build/replay_tool for feel/clumsy.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/.." && pwd)
GODOT=${1:-godot}
RT=${2:-$ROOT/lockcore/build/replay_tool}
export QA_REPLAY_TOOL=$RT
declare -A RUNS=(
  [solver]="QA_PROFILE=solver"
  [feel]="QA_PROFILE=feel"
  [clumsy]="QA_PROFILE=clumsy"
  [en]="QA_PROFILE=solver QA_LANG=en"
  [dark]="QA_PROFILE=feel QA_DARK=1"
)
worst=0
for name in solver feel clumsy en dark; do
  echo "== $name (${RUNS[$name]})"
  env ${RUNS[$name]} QA_OUT="$HERE/out/$name" QA_WORK="${QA_WORK:-/tmp/lw_qa_game}_$name" \
    "$HERE/run_career.sh" "$GODOT" "${QA_TIMEOUT:-1500}" | sed -n '3p;7,8p'
  rc=${PIPESTATUS[0]}; [ "$rc" -gt "$worst" ] && worst=$rc
done
python3 "$HERE/matrix.py" "$HERE/out"
exit $worst
