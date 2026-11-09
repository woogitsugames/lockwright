#!/usr/bin/env bash
# Run the game test pipeline locally on Windows, mirroring .github/workflows/game-tests.yml:
#   1. headless import   2. lock_test (real lockcore)   3. smoke   4. full GUT suite
# Optional: --screens renders the game-screens capture (412x915 + 915x412). That one opens a real
# window with the opengl3 driver, i.e. it USES THE GPU - do not run it while the GPU is busy.
#
# Needs the Windows lockcore DLL first: tools/local/win_build_lockcore.sh
#
# Usage (Git Bash):
#   tools/local/run_gut.sh                       # import + lock_test + smoke + all GUT tests
#   tools/local/run_gut.sh --skip-import         # reuse the existing game/.godot import cache
#   tools/local/run_gut.sh -- -gselect=test_save # extra args after -- go to GUT (e.g. -gselect, -gunit_test_name)
#   tools/local/run_gut.sh --gut-only            # just GUT (implies --skip-import)
#   tools/local/run_gut.sh --screens [--out=DIR] # also capture screens (GPU!); default DIR=qa/out/screens
#   tools/local/run_gut.sh --gut-only --repeat 10 -- -gselect=test_arrival_scene   # flake check (D-105):
#                                                # GUT N times, fresh user:// each time, then a table of
#                                                # every test that went red and how often
# Env: GODOT (default C:\tools\godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe)
# Logs: qa/out/local/*.log (gitignored; --repeat: gut_repeat_<i>.log). Exit code is non-zero if any step fails.
# user:// (qa/out/appdata/Godot/app_userdata) is wiped at the start of every run and every --repeat
# iteration, like the fresh CI runner: a save or settings file left by an earlier run cannot change results.
set -uo pipefail

REPO="$(cd "$(dirname "$0")/../.." && pwd)"
GODOT="${GODOT:-/c/tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe}"
DO_IMPORT=1; DO_PRE=1; DO_SCREENS=0; OUT="$REPO/qa/out/screens"; GUT_EXTRA=(); REPEAT=0
while [ $# -gt 0 ]; do
  case "$1" in
    --skip-import) DO_IMPORT=0 ;;
    --gut-only) DO_IMPORT=0; DO_PRE=0 ;;
    --screens) DO_SCREENS=1 ;;
    --out=*) OUT="${1#--out=}" ;;
    --repeat) shift; REPEAT="${1:-}" ;;
    --repeat=*) REPEAT="${1#--repeat=}" ;;
    --) shift; GUT_EXTRA=("$@"); break ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done

case "$REPEAT" in ''|*[!0-9]*) echo "--repeat needs a number" >&2; exit 2 ;; esac
if [ ! -x "$GODOT" ]; then echo "Godot not found at $GODOT (set GODOT)" >&2; exit 1; fi
if [ ! -f "$REPO/game/addons/lockcore_gd/bin/liblockcore_gd.windows.template_debug.dll" ]; then
  echo "Missing lockcore DLL - run tools/local/win_build_lockcore.sh first" >&2; exit 1
fi

LOGS="$REPO/qa/out/local"; mkdir -p "$LOGS"
# Per-checkout user:// so parallel runs in several worktrees don't share one save dir
# (Godot on Windows puts user:// under %APPDATA%\Godot\app_userdata\<project>).
export APPDATA="$(cygpath -w "$REPO/qa/out/appdata" 2>/dev/null || echo "$REPO/qa/out/appdata")"
mkdir -p "$REPO/qa/out/appdata"
fresh_userdir() { rm -rf "$REPO/qa/out/appdata/Godot/app_userdata"; }
fresh_userdir
cd "$REPO"
FAIL=0
step() {  # step <name> <godot args...>
  local name="$1"; shift
  echo "== $name"
  "$GODOT" "$@" > "$LOGS/$name.log" 2>&1
  local rc=$?
  if [ $rc -ne 0 ]; then echo "   FAILED (exit $rc) - see qa/out/local/$name.log"; FAIL=1; else echo "   ok"; fi
  return $rc
}

if [ $DO_IMPORT -eq 1 ]; then
  step import --headless --path game --import
  # Godot exits 0 even when the extension fails to load; surface that explicitly.
  if grep -q "lockcore_gd" "$LOGS/import.log" && grep -qi "error.*lockcore_gd\|lockcore_gd.*error" "$LOGS/import.log"; then
    echo "   lockcore_gd errors during import - see qa/out/local/import.log"; FAIL=1
  fi
fi
if [ $DO_PRE -eq 1 ]; then
  step lock_test --headless --path game res://tests/lock_test.tscn
  step smoke --headless --path game res://tests/smoke.tscn
fi

GUT_ARGS=(--headless --path game -s res://addons/gut/gut_cmdln.gd -gdir=res://tests/gut -gexit "${GUT_EXTRA[@]}")
# "script::test" for every failing test of a GUT log (its run summary lists them).
nocolor() { sed 's/\x1b\[[0-9;]*m//g' "$1"; }
failing_tests() {
  nocolor "$1" | awk '/^= Run Summary/ {s=1} s && /^res:\/\// {f=$0} s && /^- test/ {sub(/^- /, ""); print f "::" $0}'
}

if [ "$REPEAT" -gt 0 ]; then
  echo "== gut x$REPEAT (flake check: ${GUT_EXTRA[*]:-all scripts})"
  RED=0; : > "$LOGS/gut_repeat_failures.txt"
  for i in $(seq 1 "$REPEAT"); do
    fresh_userdir
    "$GODOT" "${GUT_ARGS[@]}" > "$LOGS/gut_repeat_$i.log" 2>&1
    rc=$?
    t="$(nocolor "$LOGS/gut_repeat_$i.log" | grep -E '^(Tests|Passing Tests|Time) ' | tr -s ' ' | tr '\n' ' ')"
    if [ $rc -ne 0 ]; then
      RED=$((RED + 1)); echo "   run $i: RED (exit $rc) $t- qa/out/local/gut_repeat_$i.log"
      failing_tests "$LOGS/gut_repeat_$i.log" | tee -a "$LOGS/gut_repeat_failures.txt" | sed 's/^/      /'
    else
      echo "   run $i: green $t"
    fi
  done
  echo "== flake check: $RED/$REPEAT runs red"
  if [ -s "$LOGS/gut_repeat_failures.txt" ]; then
    sort "$LOGS/gut_repeat_failures.txt" | uniq -c | sort -rn | sed 's/^/   /'
  fi
  [ $RED -ne 0 ] && FAIL=1
else
  echo "== gut"
  "$GODOT" "${GUT_ARGS[@]}" 2>&1 | tee "$LOGS/gut.log"
  rc=${PIPESTATUS[0]}
  [ $rc -ne 0 ] && { echo "   GUT FAILED (exit $rc) - see qa/out/local/gut.log"; FAIL=1; }
fi

if [ $DO_SCREENS -eq 1 ]; then
  mkdir -p "$OUT"; W_OUT="$(cygpath -m "$OUT")"
  for size in 412x915 915x412; do
    step "screens_$size" --path game --rendering-driver opengl3 res://tests/screens.tscn -- --out="$W_OUT" --size=$size
  done
  echo "   screens in $OUT"
fi
exit $FAIL
