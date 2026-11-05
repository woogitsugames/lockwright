#!/usr/bin/env bash
# Determinism of lockcore_gd inside Godot builds (session C, stage 3, task 10).
#   godot_det.sh prepare <godot> <workdir> [seeds_per_tier]   copy project + addon, record corpus on the host, self-check
#   godot_det.sh apk     <godot> <workdir>                      export the arm64 APK (needs the android .so in game/addons)
#   godot_det.sh device  <apk> <host_result.txt> [timeout_s]    install + run on adb device/emulator, compare digests
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
cmd=$1; shift
case "$cmd" in
prepare)
  G=$1 W=$2 N=${3:-10}
  rm -rf "$W" && cp -r "$ROOT/spikes/determinism/godot" "$W"
  mkdir -p "$W/addons/lockcore_gd/bin"
  cp "$ROOT/game/addons/lockcore_gd/lockcore_gd.gdextension" "$W/addons/lockcore_gd/"
  cp "$ROOT"/game/addons/lockcore_gd/bin/*.so "$W/addons/lockcore_gd/bin/"
  "$G" --headless --path "$W" --import >/dev/null 2>&1 || true
  "$G" --headless --path "$W" -- --gen "$N" --out res://corpus.json | grep LW_DET_GEN
  "$G" --headless --path "$W" | grep -E "LW_DET_(DONE|MISMATCH)" | tee "$W/host_result.txt"
  grep -q " bad=0 " "$W/host_result.txt"
  ;;
apk)
  G=$1 W=$2
  mkdir -p "$W/build"
  "$G" --headless --path "$W" --import >/dev/null 2>&1 || true
  "$G" --headless --path "$W" --export-debug "Android" build/lw-determinism.apk 2>&1 | grep -E "^ERROR" || true
  unzip -l "$W/build/lw-determinism.apk" | grep -E "liblockcore_gd|corpus.json"
  ;;
device)
  APK=$1 HOST=$2 T=${3:-900}
  PKG=com.woogitsugames.lockwright.spike.det
  adb wait-for-device
  adb shell getprop ro.product.cpu.abilist
  adb install -r "$APK"
  adb logcat -c
  # launcher activity name differs between Godot templates: start whatever the LAUNCHER intent resolves to
  adb shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1
  end=$(( $(date +%s) + T ))
  while [ "$(date +%s)" -lt "$end" ]; do
    if adb logcat -d | grep -q "LW_DET_DONE"; then break; fi
    sleep 5
  done
  adb logcat -d > device_logcat.txt
  grep -E "LW_DET_(DONE|MISMATCH)" device_logcat.txt | sed 's/^.*\(LW_DET_\)/\1/' | tee device_result.txt
  host_digest=$(grep -o "digest=[0-9a-f]*" "$HOST")
  dev_digest=$(grep -o "digest=[0-9a-f]*" device_result.txt || true)
  echo "host   $host_digest"; echo "device $dev_digest"
  [ -n "$dev_digest" ] && [ "$host_digest" = "$dev_digest" ] && grep -q " bad=0 " device_result.txt
  ;;
*) echo "usage: see header"; exit 2 ;;
esac
