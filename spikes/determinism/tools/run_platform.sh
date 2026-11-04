#!/usr/bin/env bash
# Runs every determinism check for one build and writes results/<name>.txt (key=value).
#   tools/run_platform.sh <name> <build-dir> <corpus.lwfz> [emulator]
# Exit code != 0 when any hash differs from the reference or a test fails.
set -u
NAME=$1; B=$2; CORPUS=$3; EMU=${4:-}
HERE=$(cd "$(dirname "$0")/.." && pwd)
GOLDEN=$HERE/../../lockcore/tests/golden
OUT=$HERE/results/$NAME.txt
mkdir -p "$HERE/results"
: > "$OUT"
rc=0
put() { echo "$1=$2" >> "$OUT"; echo "$1=$2"; }
run() { if [ -n "$EMU" ]; then "$EMU" "$@"; else "$@"; fi; }

put platform "$(run "$B/replay_fuzz" bench --steps 1 | head -1 | sed 's/^platform //')"
# 1. lockcore's own tests (unit, golden, no-float, 200-seed smoke) through ctest
if (cd "$B" && ctest --output-on-failure > "$HERE/results/$NAME.ctest.log" 2>&1); then put ctest pass; else put ctest FAIL; rc=1; fi
put ctest_summary "$(grep -E 'tests passed|tests failed' "$HERE/results/$NAME.ctest.log" | tail -1)"
# 2. golden replays: event hash per file
for f in "$GOLDEN"/*.replay.json; do
  line=$(run "$B/lockcore/replay_tool" play "$f" 2>&1)
  h=$(echo "$line" | sed -n 's/.*hash \([0-9a-f]*\).*/\1/p')
  put "golden.$(basename "$f" .replay.json)" "$h"
  echo "$line" | grep -q matches || rc=1
done
# 3. verify_seeds: generator + oracle + bot on 1000 seeds per tier; CSV must be identical
run "$B/lockcore/verify_seeds" --seeds 1000 --csv "$HERE/results/$NAME.verify.csv" > "$HERE/results/$NAME.verify.log" 2>&1 || rc=1
put verify_seeds_csv_sha256 "$(sha256sum "$HERE/results/$NAME.verify.csv" | cut -c1-16)"
put verify_seeds_failures "$(sed -n 's/^total failures: \([0-9]*\).*/\1/p' "$HERE/results/$NAME.verify.log")"
# 4. replay_fuzz: 10 000 replays recorded on the reference host
if run "$B/replay_fuzz" check "$CORPUS" --report "$HERE/results/$NAME.mismatch.txt" > "$HERE/results/$NAME.fuzz.log" 2>&1; then
  put fuzz pass
else
  put fuzz FAIL; rc=1
fi
put fuzz_summary "$(tail -1 "$HERE/results/$NAME.fuzz.log")"
# 5. step() cost (meaningless under qemu, reported anyway)
run "$B/replay_fuzz" bench --steps 100000 | tail -n +2 | while read -r l; do
  put "bench.$(echo "$l" | cut -d: -f1 | tr ' ' '_')" "$(echo "$l" | cut -d: -f2- | sed 's/^ //')"
done
put exit "$rc"
exit $rc
