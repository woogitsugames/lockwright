# Lockwright — Godot project (`game/`)

Engine: **Godot 4.7.2-stable** (MIT), renderer **Mobile**, portrait primary with
landscape supported (`display/window/handheld/orientation=6`, sensor).
Logic timestep: 120 Hz (`common/physics_ticks_per_second=120`, D-07).

## Toolchain install (Linux, headless works)

```bash
# Editor binary (also runs headless)
gh release download 4.7.2-stable --repo godotengine/godot \
  --pattern 'Godot_v4.7.2-stable_linux.x86_64.zip' --dir /tmp/godot-bin
unzip -o /tmp/godot-bin/Godot_v4.7.2-stable_linux.x86_64.zip -d ~/tools/godot
chmod +x ~/tools/godot/Godot_v4.7.2-stable_linux.x86_64

# Export templates 4.7.2 (Android/iOS/Linux/...)
gh release download 4.7.2-stable --repo godotengine/godot \
  --pattern 'Godot_v4.7.2-stable_export_templates.tpz' --dir /tmp/godot-bin
mkdir -p ~/.local/share/godot/export_templates/4.7.2.stable
unzip -o /tmp/godot-bin/Godot_v4.7.2-stable_export_templates.tpz -d ~/.local/share/godot/export_templates/4.7.2.stable
cd ~/.local/share/godot/export_templates/4.7.2.stable && mv templates/* . && rmdir templates
echo "4.7.2.stable.official.ed1daf0bf" > version.txt
```

Direct download URLs (for CI, see `.github/workflows/game-*.yml`):
- `https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64.zip`
- `https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz`

## Run / verify headless

```bash
~/tools/godot/godot --headless --path game --import          # import resources
godot --headless --path game -s tests/smoke.gd               # smoke test
godot --headless --path game --quit-after 30                  # boot the game headless
```

Note: in this Linux sandbox there is no GPU/EGL, so `--headless` uses the dummy
renderer and viewport screenshots come back empty. Real screenshots are taken on
a GPU runner/device; see `docs/handoff/SESSION-B-LOG.md`.

## Layout

- `scenes/` — boot, main_menu, lock, workshop, showcase, settings, dev/haptics_lab
- `scripts/autoload/` — Settings, Save, I18n, Events, Haptics, Sfx singletons
- `scripts/lock/` — lock session (FakeLockSession until the lockcore GDExtension lands)
- `i18n/` — `strings.csv` (UI, keys + `en` + `pl`), `content.csv` (jobs/showcase text)
- `data/` — `haptics_patterns.json` (from `docs/TECH.md` §3), jobs/, showcase/, tools.json, progression.json
- `addons/` — GUT (tests), lockwright_haptics (Android AAR plugin, platform/android/)
- `assets/audio/sfx/` — generated WAVs (audio/tools/synth.py, see docs/ASSETS.md)

## Rules

- Player-facing text only via `I18n.tr()`, PL + EN from day one.
- Lock screen has no UI panels (D-12): only a 48 dp pause affordance in the corner.
- Haptics never the only channel (XAG 103/110); toggle + intensity in Settings.

## Local Android debug build (Linux)

```bash
# JDK 17 (Temurin), Android SDK (platform 36, build-tools 36.1.0, NDK 29.0.14206865), Gradle 8.11.1
# editor settings: ~/.config/godot/editor_settings-4.7.tres with android_sdk_path + java_sdk_path
cd platform/android && ./gradlew :lockwright-haptics:assembleRelease
cp lockwright-haptics/build/outputs/aar/lockwright-haptics-release.aar ../game/addons/lockwright_haptics/android/lockwright_haptics.aar
# android build template into the project (once):
cd game && mkdir -p android/build && unzip -oq ~/.local/share/godot/export_templates/4.7.2.stable/android_source.zip -d android/build && echo "4.7.2.stable" > android/.build_version
# lockcore_gd android .so: build godot-cpp platform=android target=template_debug arch=arm64 (custom_api_file=extension_api-4-7.json),
# then: cd addons/lockcore_gd && GODOT_CPP=/tmp/godot-cpp scons platform=android target=template_debug arch=arm64 custom_api_file=... -j8
keytool -genkeypair -keystore /tmp/debug.keystore -storepass android -alias androiddebugkey -keypass android -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Android Debug,O=Android,C=US"
godot --headless --path . --export-debug "Android" build/lockwright-debug.apk --keystore /tmp/debug.keystore --keystore-user androiddebugkey --keystore-pass android
```
