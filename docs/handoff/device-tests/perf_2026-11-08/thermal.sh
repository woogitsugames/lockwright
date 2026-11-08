#!/bin/bash
# thermal.sh RUN MINUTES : lock screen already open; swipes for N minutes, per-minute frames + temps + PSS
export MSYS_NO_PATHCONV=1
P=/c/Users/matma/AppData/Local/Temp/claude/C--Users-matma-Documents--claude/dc2c5c31-deae-412e-8803-71ebd1d28346/scratchpad/perf
E=C:/Users/matma/lw-wt-perf/docs/handoff/device-tests/perf_2026-11-08
ADB=/c/tools/android/platform-tools/adb.exe
R=$1
echo "# $R thermal run start $(date +%T)" >> $E/${R}_thermal.txt

python C:/Users/matma/lw-wt-perf/tools/local/sf_timestats.py start
for m in $(seq 1 $2); do
  end=$((SECONDS+60))
  while [ $SECONDS -lt $end ]; do
    $ADB shell input swipe 300 500 330 700 400
    $ADB shell input swipe 540 1700 540 1450 500
  done
  $P/m.sh $R thermal_min$m >/dev/null
  tail -1 $E/${R}_frames.txt >> $E/${R}_thermal.txt
  tail -1 $E/${R}_mem.txt >> $E/${R}_thermal.txt
  echo "min $m $(date +%T)" >> $E/${R}_thermal.txt
done

echo "# end $(date +%T)" >> $E/${R}_thermal.txt
