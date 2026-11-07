#!/usr/bin/env bash
# Build the Android debug APK locally on Windows, reproducing .github/workflows/game-android.yml
# (plugin-aar + export-debug-apk jobs; --aab also reproduces release-aab, unsigned like CI without secrets).
#   1. haptics + click-audio AARs (Gradle 8.11.1)
#   2. lockcore_gd for android arm64 (SCons + NDK 28.1.13356709, CI-pinned godot-cpp)
#   3. Godot Android build template into game/android/build
#   4. import + export "Android" preset, signed with platform/android/debug.keystore (same key as CI,
#      so `adb install -r` over a CI APK keeps the save)
#   5. checks: android.permission.VIBRATE (N-55), signer SHA-256, size vs qa/budget/budgets.json
# Output: build/local/lockwright-debug.apk (+ build/local/lockwright-release.aab with --aab). Never installs.
#
# One-time setup (per-user, no admin) - see docs/handoff/LOCAL-SESSION-LOG.md:
#   JDK 17 in C:\tools\jdk-17, Android SDK in C:\tools\android with
#   sdkmanager "platforms;android-36" "build-tools;36.1.0" "platform-tools" "ndk;28.1.13356709" "ndk;29.0.14206865" "cmake;3.22.1"
#   Gradle 8.11.1 in C:\tools\gradle-8.11.1, Godot 4.7.2 + export templates in %APPDATA%\Godot\export_templates\4.7.2.stable,
#   SCons (pip --user); godot-cpp is cloned at the CI-pinned commit if missing.
#
# Usage (Git Bash): tools/local/build_apk.sh [--aab] [--skip-aar] [--skip-lockcore] [--skip-import]
# Env overrides: JAVA_HOME_W, ANDROID_SDK_W, GRADLE, GODOT, GODOT_CPP, SCONS, JOBS.
# Note: sets the Android SDK/Java paths in %APPDATA%\Godot\editor_settings-4.7.tres (original kept once as .bak-local).
set -euo pipefail

REPO="$(cd "$(dirname "$0")/../.." && pwd)"
JAVA_HOME_W="${JAVA_HOME_W:-C:/tools/jdk-17}"
ANDROID_SDK_W="${ANDROID_SDK_W:-C:/tools/android}"
GRADLE="${GRADLE:-/c/tools/gradle-8.11.1/bin/gradle}"
GODOT="${GODOT:-/c/tools/godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe}"
GODOT_CPP_COMMIT=e103d348c4b2d8df7b819126d855e19381cb9a87
GODOT_CPP="${GODOT_CPP:-/c/tools/godot-cpp-${GODOT_CPP_COMMIT:0:7}}"
NDK_VERSION=28.1.13356709
BUILD_TOOLS=36.1.0
TEMPLATES="$(cygpath -u "$APPDATA")/Godot/export_templates/4.7.2.stable"
EDITOR_SETTINGS="$(cygpath -u "$APPDATA")/Godot/editor_settings-4.7.tres"
EXPECTED_CERT_SHA256=2fda65a371d45bc3ba960290e32f8cb119d6adff66be6f2980a68cad93555cdc  # CI debug APK signer
JOBS="${JOBS:-$(nproc 2>/dev/null || echo 8)}"
OUT="$REPO/build/local"

DO_AAB=0; DO_AAR=1; DO_LOCKCORE=1; DO_IMPORT=1
for a in "$@"; do
  case "$a" in
    --aab) DO_AAB=1 ;;
    --skip-aar) DO_AAR=0 ;;
    --skip-lockcore) DO_LOCKCORE=0 ;;
    --skip-import) DO_IMPORT=0 ;;
    *) echo "unknown option: $a" >&2; exit 2 ;;
  esac
done

SDK_U="$(cygpath -u "$ANDROID_SDK_W")"
for f in "$(cygpath -u "$JAVA_HOME_W")/bin/java.exe" "$SDK_U/build-tools/$BUILD_TOOLS/aapt2.exe" \
         "$SDK_U/ndk/$NDK_VERSION/source.properties" "$GRADLE" "$GODOT" "$TEMPLATES/android_source.zip"; do
  [ -e "$f" ] || { echo "missing prerequisite: $f (see header)" >&2; exit 1; }
done
if [ -z "${SCONS:-}" ]; then
  SCONS="$(command -v scons || ls "$(cygpath -u "$APPDATA")"/Python/Python3*/Scripts/scons.exe 2>/dev/null | sort | tail -1 || true)"
fi
[ -n "$SCONS" ] || { echo "SCons not found: python -m pip install --user scons" >&2; exit 1; }

export JAVA_HOME="$JAVA_HOME_W" ANDROID_HOME="$ANDROID_SDK_W" ANDROID_SDK_ROOT="$ANDROID_SDK_W"
export ANDROID_NDK_ROOT="$ANDROID_SDK_W/ndk/$NDK_VERSION"
export PATH="$(cygpath -u "$JAVA_HOME_W")/bin:$PATH"
# Godot's gradlew would leave a Gradle daemon that inherits the console pipe, so the headless
# export never returns on Windows. Single-use daemons exit with the build.
export GRADLE_OPTS="${GRADLE_OPTS:-} -Dorg.gradle.daemon=false"
BT="$SDK_U/build-tools/$BUILD_TOOLS"
mkdir -p "$OUT" "$REPO/game/build"

# Tracked files touched temporarily; restored on exit so the tree stays clean.
# (platform/android/lockwright-haptics/build/ has tracked Gradle outputs that every build rewrites.)
TRACKED_AAR=game/addons/lockwright_haptics/android/lockwright_haptics.aar
TRACKED_GRADLE_OUT=platform/android/lockwright-haptics/build
UNTRACKED_AAR=game/addons/lockwright_click_audio/android/lockwright_click_audio.aar
PRESETS=game/export_presets.cfg
cleanup() {
  cd "$REPO"
  git checkout -q -- "$TRACKED_AAR" "$TRACKED_GRADLE_OUT" 2>/dev/null || true
  if ! git ls-files --error-unmatch "$UNTRACKED_AAR" >/dev/null 2>&1; then rm -f "$UNTRACKED_AAR"; fi
  if [ -f "$OUT/export_presets.cfg.orig" ]; then mv -f "$OUT/export_presets.cfg.orig" "$PRESETS"; fi
  return 0
}
trap cleanup EXIT

if [ $DO_AAR -eq 1 ]; then
  echo "== AARs (gradle)"
  (cd "$REPO/platform/android" && "$GRADLE" --no-daemon -q :lockwright-haptics:assembleRelease :lockwright-click-audio:assembleRelease)
fi
for pair in "lockwright-haptics:lockwright_haptics" "lockwright-click-audio:lockwright_click_audio"; do
  mod="${pair%%:*}"; addon="${pair##*:}"
  src="$REPO/platform/android/$mod/build/outputs/aar/$mod-release.aar"
  [ -f "$src" ] || { echo "missing $src (run without --skip-aar)" >&2; exit 1; }
  mkdir -p "$REPO/game/addons/$addon/android"
  cp -f "$src" "$REPO/game/addons/$addon/android/$addon.aar"   # R-41e normalized names
done

if [ $DO_LOCKCORE -eq 1 ]; then
  if [ ! -f "$GODOT_CPP/SConstruct" ]; then
    mkdir -p "$GODOT_CPP" && git init -q "$GODOT_CPP"
    git -C "$GODOT_CPP" fetch -q --depth 1 https://github.com/godotengine/godot-cpp.git "$GODOT_CPP_COMMIT"
    git -C "$GODOT_CPP" checkout -q FETCH_HEAD
  fi
  GCPP="$(cygpath -m "$GODOT_CPP")"
  targets="template_debug"
  if [ $DO_AAB -eq 1 ]; then targets="template_debug template_release"; fi
  for t in $targets; do
    echo "== lockcore_gd android arm64 $t"
    (cd "$REPO/game/addons/lockcore_gd" && GODOT_CPP="$GCPP" "$SCONS" -Q platform=android target="$t" arch=arm64 \
       ndk_version=$NDK_VERSION custom_api_file="$GCPP/gdextension/extension_api-4-7.json" -j"$JOBS")
  done
fi
[ -f "$REPO/game/addons/lockcore_gd/bin/liblockcore_gd.android.template_debug.so" ] || { echo "missing android lockcore .so" >&2; exit 1; }

echo "== Android build template"
if [ "$(cat "$REPO/game/android/build/.local_template_version" 2>/dev/null || true)" != "4.7.2.stable" ]; then
  rm -rf "$REPO/game/android/build" && mkdir -p "$REPO/game/android/build"
  unzip -oq "$TEMPLATES/android_source.zip" -d "$REPO/game/android/build"
  find "$REPO/game/android" -name "*.import" -delete
  echo "4.7.2.stable" > "$REPO/game/android/build/.local_template_version"
fi

echo "== editor settings (SDK/Java paths)"
if [ -f "$EDITOR_SETTINGS" ]; then
  [ -f "$EDITOR_SETTINGS.bak-local" ] || cp "$EDITOR_SETTINGS" "$EDITOR_SETTINGS.bak-local"
  for kv in "android_sdk_path|$ANDROID_SDK_W" "java_sdk_path|$JAVA_HOME_W"; do
    k="${kv%%|*}"; v="${kv##*|}"
    if grep -q "^export/android/$k = " "$EDITOR_SETTINGS"; then
      sed -i "s#^export/android/$k = .*#export/android/$k = \"$v\"#" "$EDITOR_SETTINGS"
    else
      echo "export/android/$k = \"$v\"" >> "$EDITOR_SETTINGS"
    fi
  done
else
  mkdir -p "$(dirname "$EDITOR_SETTINGS")"
  printf '[gd_resource type="EditorSettings" format=3]\n\n[resource]\nexport/android/android_sdk_path = "%s"\nexport/android/java_sdk_path = "%s"\n' \
    "$ANDROID_SDK_W" "$JAVA_HOME_W" > "$EDITOR_SETTINGS"
fi

# N-43/BUG-14: the stable debug key CI falls back to; same signer as the CI APKs.
export GODOT_ANDROID_KEYSTORE_DEBUG_PATH="$(cygpath -m "$REPO/platform/android/debug.keystore")"
export GODOT_ANDROID_KEYSTORE_DEBUG_USER=androiddebugkey
export GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD=android

cd "$REPO"
if [ $DO_IMPORT -eq 1 ]; then
  echo "== import"
  "$GODOT" --headless --path game --import > "$OUT/import.log" 2>&1 || { echo "import failed, see build/local/import.log" >&2; exit 1; }
fi
echo "== export debug APK"
rm -f game/build/lockwright-debug.apk
"$GODOT" --headless --path game --export-debug "Android" build/lockwright-debug.apk > "$OUT/export-apk.log" 2>&1 || true
if [ ! -f game/build/lockwright-debug.apk ]; then
  echo "APK export failed, see build/local/export-apk.log" >&2; tail -30 "$OUT/export-apk.log" >&2; exit 1
fi
cp -f game/build/lockwright-debug.apk "$OUT/lockwright-debug.apk"

if [ $DO_AAB -eq 1 ]; then
  echo "== export release AAB (unsigned, like CI without release secrets)"
  cp -f "$PRESETS" "$OUT/export_presets.cfg.orig"
  TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.1.0"); VER=${TAG#v}
  CODE=$(git rev-list --count "$TAG..HEAD" 2>/dev/null || echo 1); CODE=$((1000 + CODE))
  INC=$(awk -F'"' '/^\[preset.0\]/{f=1} f&&/^include_filter=/{print $2; exit}' "$PRESETS")
  EXCL=$(awk -F'"' '/^\[preset.0\]/{f=1} f&&/^exclude_filter=/{print $2; exit}' "$PRESETS")
  {
    printf '\n[preset.3]\nname="AndroidRelease"\nplatform="Android"\nrunnable=false\nexport_filter="all_resources"\n'
    printf 'include_filter="%s"\nexclude_filter="%s"\n' "$INC" "$EXCL"
    printf 'export_path="build/lockwright-release.aab"\nencrypt_pck=false\nencrypt_directory=false\n\n[preset.3.options]\n'
    printf 'gradle_build/use_gradle_build=true\ngradle_build/export_format=1\ngradle_build/min_sdk="30"\ngradle_build/target_sdk="36"\n'
    printf 'architectures/arm64-v8a=true\narchitectures/armeabi-v7a=false\narchitectures/x86=false\narchitectures/x86_64=false\n'
    printf 'keystore/debug=""\nkeystore/debug_user=""\nkeystore/debug_password=""\npackage/signed=false\n'
    printf 'version/code=%s\nversion/name="%s"\n' "$CODE" "$VER"
    printf 'package/unique_name="com.woogitsugames.lockwright"\npackage/name="Lockwright: Locksmith on Call"\n'
    printf 'graphics/opengl_debug=false\nxr_features/xr_mode=0\npermissions/vibrate=true\n'
  } >> "$PRESETS"
  rm -f game/build/lockwright-release.aab
  "$GODOT" --headless --path game --export-release "AndroidRelease" build/lockwright-release.aab > "$OUT/export-aab.log" 2>&1 || true
  mv -f "$OUT/export_presets.cfg.orig" "$PRESETS"
  if [ ! -f game/build/lockwright-release.aab ]; then
    echo "AAB export failed, see build/local/export-aab.log" >&2; tail -30 "$OUT/export-aab.log" >&2; exit 1
  fi
  cp -f game/build/lockwright-release.aab "$OUT/lockwright-release.aab"
fi

echo "== checks"
FAIL=0
if "$BT/aapt2.exe" dump permissions "$OUT/lockwright-debug.apk" | grep -q "android.permission.VIBRATE"; then
  echo "APK manifest: android.permission.VIBRATE present"
else
  echo "ERROR: android.permission.VIBRATE missing from APK manifest (N-55)"; FAIL=1
fi
CERT=$("$BT/apksigner.bat" verify --print-certs "$(cygpath -m "$OUT/lockwright-debug.apk")" | sed -n 's/.*certificate SHA-256 digest: //p' | head -1 | tr -d '\r')
if [ "$CERT" = "$EXPECTED_CERT_SHA256" ]; then
  echo "APK signer SHA-256 matches CI debug key ($CERT)"
else
  echo "ERROR: APK signer SHA-256 '$CERT' != CI $EXPECTED_CERT_SHA256"; FAIL=1
fi
size_mb() { python -c "import os,sys; print(round(os.path.getsize(sys.argv[1])/1e6,1))" "$(cygpath -m "$1")"; }
APK_MB=$(size_mb "$OUT/lockwright-debug.apk")
python -c "
import json, sys
v = float(sys.argv[1]); b = json.load(open(sys.argv[2]))['ci']['apk_mb']
st = 'OK' if v <= b['warn'] else ('WARN' if v <= b['fail'] else 'FAIL')
print('APK %s MB (budget warn %s / fail %s): %s' % (v, b['warn'], b['fail'], st))
sys.exit(1 if st == 'FAIL' else 0)
" "$APK_MB" "$(cygpath -m "$REPO/qa/budget/budgets.json")" || FAIL=1
if [ $DO_AAB -eq 1 ]; then
  if unzip -p "$OUT/lockwright-release.aab" base/manifest/AndroidManifest.xml | grep -aq "android.permission.VIBRATE"; then
    echo "AAB manifest: android.permission.VIBRATE present"
  else
    echo "ERROR: VIBRATE missing from AAB manifest"; FAIL=1
  fi
  echo "AAB $(size_mb "$OUT/lockwright-release.aab") MB (Play base module limit 200 MB, D-64)"
fi
echo "output: $OUT"
exit $FAIL
