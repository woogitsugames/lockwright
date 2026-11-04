# Lockwright — iOS native bridge (`platform/ios/`)

**Wybrana ścieżka (D-20): GDExtension (godot-cpp) jako xcframework z kodem ObjC++** —
jedna technologia z lockcore/Androidem, stabilne ABI; klasyczny plugin `.gdip`
zostaje jako fallback, gdyby eksport GDExtension na iOS w 4.7 zawodził (spike 1, TECH.md §1.2).

- `lockwright_haptics/` — źródła GDExtension: `Sources/lockwright_haptics.mm` (ObjC++),
  `Sources/register_types.cpp`, `SConstruct` (buduje przez godot-cpp 4.7.2-stable).
- Most wystawia singleton `LockwrightHaptics` z metodami 1:1 jak `HapticsBridge`
  (TECH.md §2.5): `play(event, intensity, material)`, `begin_continuous(id)`,
  `update_continuous(id, intensity, sharpness)`, `end_continuous(id)`, `capabilities()`, `stop_all()`.
- Core Haptics (H3): opór ciągły jako `CHHapticAdvancedPatternPlayer` w pętli +
  `CHHapticDynamicParameter` (`hapticIntensityControl`/`hapticSharpnessControl`)
  wysyłane co klatkę (≤ 60 Hz, `sendParameters`); kliknięcia jako transienty w
  **osobnym** playerze. Obsługa `stoppedHandler`/`resetHandler` (restart silnika).
- Fallback H1: `UIImpactFeedbackGenerator`; bez haptyki (iPad, H0): tylko log —
  gra i tak ma dźwięk + obraz (XAG 103/110).
- Audio niskiej latencji: `AVAudioSession` kategoria `.ambient`,
  `setPreferredIOBufferDuration(0.005)` (TECH.md §1.6).

## Budowanie (tylko macOS, patrz CI `.github/workflows/game-ios.yml`)

```bash
git clone --depth 1 --branch 4.7.2-stable https://github.com/godotengine/godot-cpp.git
godot-cpp: scons platform=ios target=template_release arch=arm64   # device
godot-cpp: scons platform=ios target=template_debug arch=x86_64     # simulator
cd platform/ios/lockwright_haptics
GODOT_CPP_SCONSTRUCT=../../godot-cpp/SConstruct scons platform=ios target=template_release arch=arm64
xcodebuild -create-xcframework -library bin/*.a -output liblockwright_haptics.ios.release.xcframework
# wynik → game/addons/lockwright_haptics/ios/
```
