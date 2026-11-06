# Lockwright — Android native bridge (`platform/android/`)

Godot Android **plugin v2** (AAR, Kotlin): `LockwrightHaptics` singleton visible in
Godot as `Engine.get_singleton("LockwrightHaptics")` with methods
`play(event, intensity, material)`, `begin_continuous(id)`, `update_continuous(id, intensity, sharpness)`,
`end_continuous(id)`, `capabilities()` (JSON string; GDScript parses it to a Dictionary),
`test_pulse(ms, level)` (Settings test pulse, N-70). GDScript must check methods with
`has_java_method()` — `has_method()` is false for every plugin method of a JNISingleton (N-70).
All vibrations use `USAGE_MEDIA` (API 33+) / `USAGE_GAME` audio attributes, not the implicit TOUCH usage.

## Haptics tiers (docs/TECH.md §2.2)

| Tier | Condition | Behaviour |
|---|---|---|
| A4 Builder | `SDK_INT_FULL >= 370200` (Android 16 QPR / API 37.2) | `VibrationEffect.Builder` presets + `BasicEnvelopeBuilder` when `areEnvelopeEffectsSupported()` |
| A3 Envelope | API 36 + `vibrator.areEnvelopeEffectsSupported()` | continuous resistance as chained 50–80 ms `BasicEnvelopeBuilder` segments |
| A2 Composition | API ≥ 30 + `areAllPrimitivesSupported(CLICK, TICK)` | transient effects from primitives; **each primitive checked via `arePrimitivesSupported`** — one unsupported primitive voids the whole composition, so unsupported ones are replaced/skipped |
| A1 Waveform | `vibrator.hasAmplitudeControl()` | `createWaveform`; resistance as 40 ms segments re-armed every 80–120 ms (each `vibrate()` interrupts the previous) |
| A0 on/off | no amplitude control (cheap ERM) | only events with `a0_ms` (`set`, `false_set`, `overset`, `counter_rotate`, `gate_align` 30 ms; `open` 50 ms; `drop`, `break`, `detector_trip` 60 ms), never < 30 ms (N-70: ERM spin-up), no continuous resistance |
| A– none | `!hasVibrator()` | audio + visuals only |

All calls are non-blocking and marshalled to a `HandlerThread` fed by `VibratorManager`
(API 31+) or `VIBRATOR_SERVICE` (API 30).

## Toolchain (docs/TECH.md §5.1, pinned)

- JDK **Temurin 17**, Android SDK **platform 36**, **build-tools 36.1.0**, **NDK 29.0.14206865**, Gradle wrapper **8.11.1** / AGP **8.6.1** (matches Godot 4.7.2 template), Kotlin 2.1.21.

```bash
# SDK
mkdir -p $ANDROID_HOME/cmdline-tools && cd $ANDROID_HOME/cmdline-tools
# download commandlinetools-linux-*_latest.zip from https://developer.android.com/studio
unzip commandlinetools-linux-*.zip && mv cmdline-tools latest
sdkmanager "platforms;android-36" "build-tools;36.1.0" "platform-tools"
sdkmanager "ndk;29.0.14206865"

# Build the AAR (in a container or locally)
./gradlew :lockwright-haptics:assembleRelease
# artifact: lockwright-haptics/build/outputs/aar/lockwright-haptics-release.aar
# copy to game/addons/lockwright_haptics/android/lockwright_haptics.aar
```

CI builds the AAR (`.github/workflows/game-android.yml`); the sandbox has no
JDK/SDK, so the artifact is produced in CI and copied into the repo by the workflow
or committed after a CI-assisted build (see `docs/handoff/SESSION-B-LOG.md`).
