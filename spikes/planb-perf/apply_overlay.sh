#!/usr/bin/env bash
# Builds a plan-B performance test project from a COPY of game/ (game/ itself is not modified):
#   spikes/planb-perf/apply_overlay.sh <dest-dir>
# - main scene = res://scenes/photoreal/lock_photoreal.tscn (session A's plan B lock screen, D-31)
# - autoload PerfHud (this directory's perf_hud.gd)
# - Android preset without Gradle/plugins (pure rendering + lockcore_gd .so from the repo)
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)
DEST=$1
rm -rf "$DEST"
cp -r "$ROOT/game" "$DEST"
rm -rf "$DEST/.godot" "$DEST/android"
mkdir -p "$DEST/spike_perf"
cp "$HERE/perf_hud.gd" "$DEST/spike_perf/perf_hud.gd"
P="$DEST/project.godot"
sed -i 's|^run/main_scene=.*|run/main_scene="res://scenes/photoreal/lock_photoreal.tscn"|' "$P"
sed -i 's|^config/name=.*|config/name="LW Plan B Perf"|' "$P"
# drop editor plugins (native AARs need a Gradle build; this APK measures rendering only)
sed -i '/^\[editor_plugins\]/,/^$/d' "$P"
# add the HUD autoload
python3 - "$P" <<'PY'
import sys, re
p = sys.argv[1]; s = open(p).read()
if '[autoload]' in s:
    s = s.replace('[autoload]\n', '[autoload]\n\nPerfHud="*res://spike_perf/perf_hud.gd"\n', 1)
else:
    s += '\n[autoload]\n\nPerfHud="*res://spike_perf/perf_hud.gd"\n'
open(p, 'w').write(s)
PY
cat > "$DEST/export_presets.cfg" <<'CFG'
[preset.0]

name="Android"
platform="Android"
runnable=true
export_filter="all_resources"
include_filter="i18n/*.csv, data/*.json, data/**/*.json"
exclude_filter="addons/gut/*, tests/*, scenes/dev/*"
export_path="build/lw-planb-perf.apk"

[preset.0.options]

gradle_build/use_gradle_build=false
architectures/armeabi-v7a=false
architectures/arm64-v8a=true
architectures/x86=false
architectures/x86_64=false
screen/immersive_mode=true
version/code=1
version/name="0.1.0-planb-perf"
package/unique_name="com.woogitsugames.lockwright.spike.planbperf"
package/name="LW Plan B Perf"
package/signed=true
permissions/vibrate=true
CFG
echo "overlay ready in $DEST"
