#!/bin/bash
# temps.sh RUN N : every 60 s for N samples, HAL temperatures + thermal status + battery
E=/c/Users/matma/lw-wt-perf/docs/handoff/device-tests/perf_2026-11-08
ADB=/c/tools/android/platform-tools/adb.exe
for i in $(seq 1 $2); do
  t=$($ADB shell dumpsys thermalservice | sed -n '/Current temperatures from HAL/,/Current cooling/p' | grep -oE "mValue=[0-9.]+, mType=[0-9]+, mName=(AP|BAT|SKIN|PA)" | sed 's/mValue=//; s/, mType=[0-9]*, mName=/:/' | tr '\n' ' ')
  st=$($ADB shell dumpsys thermalservice | grep -m1 "Thermal Status")
  b=$($ADB shell dumpsys battery | grep -E "^\s+(level|temperature):" | tr -s ' \n' ' ')
  echo "$(date +%T) $st | $t| battery$b" >> $E/${1}_temps.txt
  sleep 60
done
