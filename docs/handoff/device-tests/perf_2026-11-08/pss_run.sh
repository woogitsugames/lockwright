#!/bin/bash
# pss_run.sh RUN : fresh start; PSS + frames per screen; idle/interact frames in combo and wafer locks
P=/c/Users/matma/AppData/Local/Temp/claude/C--Users-matma-Documents--claude/dc2c5c31-deae-412e-8803-71ebd1d28346/scratchpad/perf
ADB=/c/tools/android/platform-tools/adb.exe
R=$1
lock() {  # name row
  $ADB shell input tap 540 $2; sleep 5; $ADB shell input tap 540 2236; sleep 4
  $P/m.sh $R x >/dev/null; $ADB shell input tap 540 1900; sleep 7
  $P/m.sh $R open_lock_$1; $P/shot.sh ${R}_$1 >/dev/null
  $P/m.sh $R x >/dev/null; sleep 9; $P/m.sh $R idle_lock_$1
  for i in 1 2 3 4 5 6; do $ADB shell input swipe 300 500 330 700 500; $ADB shell input swipe 540 1700 540 1450 600; $ADB shell input swipe 800 900 700 600 400; done
  $P/m.sh $R touch_lock_$1
  $ADB shell input keyevent KEYCODE_BACK; sleep 1.5; $ADB shell input tap 540 1464; sleep 4
}
$ADB shell am force-stop com.woogitsugames.lockwright; $ADB shell am start -n com.woogitsugames.lockwright/com.godot.game.GodotAppLauncher >/dev/null
sleep 10; python C:/Users/matma/lw-wt-perf/tools/local/sf_timestats.py start; sleep 4; $P/m.sh $R menu
$ADB shell input tap 381 900; sleep 6; $P/m.sh $R jobs
lock combo 567
$ADB shell input tap 381 900; sleep 5
lock wafer 1044
$P/m.sh $R x >/dev/null; $ADB shell input tap 411 1050; sleep 7; $P/m.sh $R workshop; $ADB shell input keyevent KEYCODE_BACK; sleep 3
$ADB shell am force-stop com.woogitsugames.lockwright; $ADB shell am start -n com.woogitsugames.lockwright/com.godot.game.GodotAppLauncher >/dev/null
sleep 10; $P/m.sh $R x > /dev/null; $ADB shell input tap 411 1050; sleep 7; $P/m.sh $R workshop_fresh
python C:/Users/matma/lw-wt-perf/tools/local/sf_timestats.py stop
