# Spike 1 i 2 — opóźnienie i ciągłość haptyki (iOS Core Haptics, Android VibrationEffect)

Kryteria: `docs/TECH.md` §4 (spike 1: iPhone, spike 2: Android), warstwy haptyki §2.1–2.2, metoda §2.4.
To aplikacje **pomiarowe**, nie moduł produkcyjny (ten jest w `platform/`). Ten sam efekt jest zaimplementowany w Godocie i w natywnych aplikacjach kontrolnych, żeby oddzielić koszt silnika od kosztu platformy.

| Katalog | Co to jest |
|---|---|
| `shared-android/…/HapticCore.kt` | rdzeń Androida wspólny dla wtyczki Godota i aplikacji natywnej: wykrycie tieru A3→A0, transient (`PRIMITIVE_CLICK`/`TICK` → `createOneShot` → on/off), opór ciągły (A3: obwiednie `BasicEnvelopeBuilder` co 50 ms; A1/A2: segment 40 ms z amplitudą co 100 ms; A0: brak), atrybut `USAGE_MEDIA` lub `USAGE_TOUCH` (przełącznik), `getPrimitiveDurations` |
| `godot-plugin-android/` | wtyczka Godot Android v2 `LockwrightHapticsProbe` (AAR) z tym rdzeniem |
| `godot-ios/` | moduł GDExtension `LockwrightHapticsProbeIOS` (Objective-C++, Core Haptics: `CHHapticAdvancedPatternPlayer` w pętli + `sendParameters` ≤ 60 Hz, transienty w osobnym playerze, `resetHandler`/`stoppedHandler`) |
| `godot/` | projekt Godot: dotyk = transient, przesuw w poziomie = opór (intensywność = x/szerokość × 0,55), błysk ekranu na dotyk, na ekranie i w logu `LW_HAPTICS` czas zdarzenie→API i czas wywołania |
| `native-android/` | aplikacja kontrolna Kotlin + Compose (bez Godota), ten sam `HapticCore.kt`; mierzy `MotionEvent.getEventTimeNanos()` → wywołanie `vibrate()` (log `LWHapticsNative`) |
| `native-ios/` | aplikacja kontrolna SwiftUI + Core Haptics (`HapticCore.swift`, ten sam efekt); `UITouch.timestamp` → wywołanie (zegar `CACurrentMediaTime`) |
| `tools/analyze.py` | analiza nagrań piezo: onset stuknięcia i onset wibracji, p50/p95, różnica Godot − natywna, test ciągłości oporu (`--continuity`), `--selftest` |

Uwaga: moduł Godota na iOS jest w Objective-C++, a nie w Swifcie. Core Haptics ma API w ObjC, a statyczna biblioteka Swift wymagałaby dołączenia runtime'u Swifta do projektu Xcode eksportowanego przez Godota. Kod efektu jest 1:1 z `HapticCore.swift`. Z tego samego powodu co D-29 plik `.gdextension` powstaje tylko w jobie iOS w CI (wpis tylko dla iOS psuje eksport Androida w 4.7.2).

## Instalacja

- Android: GitHub → Actions → **spike-haptics** → artefakt `spike-haptics-android-apks` (dwa APK: `spike-haptics-godot-debug.apk` i natywny `app-release.apk`) → `adb install -r …`.
- iOS: artefakty są **niepodpisane** (`spike-haptics-ios-native-unsigned`, `spike-haptics-ios-godot`). Na iPhone'a trzeba je podpisać własnym kontem (Xcode → otwórz projekt z `native-ios` po `xcodegen generate`, wybierz zespół, Run), albo przez TestFlight, gdy będzie klucz API (TECH §5.4).

## Pomiar

Wspólne (TECH §4): build release, jasność 50%, tryb samolotowy, bateria > 50%, 3 serie × 50 prób, raport p50/p95.

1. **Piezo na tylnej ściance** telefonu (taśma dwustronna, środek obudowy, blisko silnika wibracji) → kanał 1 interfejsu audio 48 kHz. Opcjonalnie drugie piezo na szkle przy miejscu dotyku → kanał 2 (czystszy onset stuknięcia; bez niego użyj `--single`).
2. Nagrywaj stereo 48 kHz. Stukaj opuszką lub rysikiem ok. 2 razy na sekundę w środek ekranu: 50 stuknięć w aplikacji Godota (`godot_<telefon>_1.wav`), 50 w natywnej (`native_<telefon>_1.wav`). Powtórz 3 serie.
3. `python3 tools/analyze.py godot_pixel_1.wav native_pixel_1.wav … --csv lat.csv`
   - dla każdego pliku: `p50_ms`, `p95_ms`, `missing_haptic` (stuknięcie bez wibracji w oknie 5–250 ms);
   - dla par `godot_X` / `native_X`: `godot_minus_native_p95_ms` i werdykt kryterium 8 ms.
4. **Ciągłość oporu** (spike 2): przytrzymaj palec i powoli przesuwaj w poziomie przez 10 s; nagraj tylko kanał piezo z tyłu; `python3 tools/analyze.py --continuity drag.wav` → liczba przerw > 15 ms (kryterium: 0 na A3+).
5. **Obraz** (opcjonalnie): kamera 240 fps (4,17 ms/klatkę) filmuje palec i ekran; ekran błyska na dotyk — daje opóźnienie obrazu do porównania z haptyką.
6. **Część programowa** (bez sprzętu): na ekranie i w logu (`adb logcat -s godot | grep LW_HAPTICS`, `adb logcat -s LWHapticsNative`, w Xcode konsola `LWHapticsNative`): czas od zdarzenia wejścia do wywołania API i sam czas wywołania. W natywnych aplikacjach mierzymy od znacznika dotyku systemu (`MotionEvent`/`UITouch`); w Godocie od odebrania `InputEvent` (Godot nie przekazuje znacznika czasu dotyku) — różnicę „dotyk → InputEvent” daje dopiero pomiar piezo.

`tools/analyze.py --selftest` sprawdza detekcję na nagraniu syntetycznym (30 stuknięć, opóźnienia 8–60 ms): błąd ≤ 0,8 ms, bias +0,6 ms (próg onsetu na narastającym burście).

## Kryteria (TECH §4)

**Spike 1 (iPhone)** — przeszło: dotyk→transient p95 ≤ 25 ms (iPhone 12+), ≤ 30 ms (SE 3); zmiana napięcia→zmiana intensywności p95 ≤ 40 ms; Godot − natywna ≤ 8 ms p95; 10 min gry bez zerwania engine (reset < 200 ms; licznik `resets`/`stops` na ekranie); CPU wątku haptyki < 3%; eksport GDExtension przechodzi walidację App Store Connect. Nie przeszło: p95 > 35 ms, różnica > 12 ms albo odczuwalne „schodki” przy 60 Hz (≥ 3/5 testerów).

**Spike 2 (Android)** — przeszło: dotyk→transient p95: Pixel ≤ 35 ms, Samsung A ≤ 50 ms, tani ≤ 100 ms; ciągły opór na A3+ bez przerw > 15 ms i oceniony „ciągły” przez ≥ 4/5 testerów; test „dwa kliknięcia” ≥ 80% po kalibracji; żadna kompozycja nie zawodzi po cichu (tier i lista prymitywów z czasami są na ekranie). Nie przeszło: Pixel > 45 ms p95, opór „rwany” na Pixelu, albo brak rozróżnienia set/false_set w samej haptyce na Samsungu A (wtedy dopuszczalne, ale zapisujemy ograniczenie).

Wyniki wpisujemy do `RESULTS.md` (urządzenie, OS, tier, p50/p95 Godot i natywnie, różnica, ciągłość, uwagi testerów).
