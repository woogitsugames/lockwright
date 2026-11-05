# Sesja C — log nocny (spike'i, sklep)

Format: data i godzina (UTC), zadanie, co zrobione, liczby, linki, blokady.

## 2026-11-04 23:30 — C5: sklep i marka (`store/`)
- `store/listing.md`: nazwa, podtytuł, tekst promocyjny, słowa kluczowe, krótki i pełny opis, „Co nowego” — PL i EN, App Store i Google Play. Limity sprawdza `store/tools/check_lengths.py` (wszystkie pola mieszczą się).
- **Do decyzji właściciela:** „Lockwright: Emergency Locksmith” ma **31 znaków** (limit 30 w obu sklepach). Rekomendacja: „Lockwright Emergency Locksmith” (30). Alternatywa: „Lockwright: Locksmith on Call” (29). PL „Lockwright: Pogotowie Zamkowe” = 29, bez zmian.
- `store/rating.md`: kwestionariusz Apple (cel 4+) i IARC (PEGI 3 / ESRB E / USK 0), ryzyko odbioru tematu, notatka dla recenzenta.
- `store/privacy.md`: polityka prywatności PL/EN (offline, brak danych), App Privacy „Data Not Collected”, Data safety, manifest prywatności (powody API do weryfikacji na eksporcie Godota).
- `store/screenshots/`: plan 8 kadrów + generator Pillow; 32 makiety (PL/EN × iPhone 6,9" 1320×2868 i Android 1080×1920), 24,8 MB (wersje 256-kolorowe; do wysyłki generować pełne RGB bez `--quantize`). Kadry 06 i 07 to zaślepki — potrzebne nowe rendery (lista w `PLAN.md`).
- Otwarte pytania: nazwa EN, zakres 1.0, model biznesowy (D-06), dane administratora i domena, iPad (D-10), grupa docelowa Play (rekomendacja 13+, bez programu rodzinnego).

## 2026-11-04 23:55 — C3: spike 5, determinizm na ARM (`spikes/determinism/`)
- `lockcore/` budowany z zewnątrz (`add_subdirectory`), bez zmian w katalogu. Buildy: x86_64 gcc 13.3, x86_64 clang 18.1, Linux aarch64 gcc 13.3 (statycznie, qemu-user), Android arm64 NDK 29 clang 21 (statycznie z bionic, qemu-user).
- Wynik lokalny: **100% zgodności** — `ctest` zielony na 4 buildach, 5 złotych powtórek z identycznym hashem (np. `pin_tumbler_t7_s4242` = `6179e59ebde7514b`), CSV `verify_seeds --seeds 1000` identyczny (`c9e38026f430bbc7`), `replay_fuzz` **10 000/10 000** (13,9 mln kroków, hash zdarzeń i stanu co 60 kroków).
- `step()` natywnie x86_64: p99 118–161 ns; Android arm64 w emulacji p99 2,3 µs (kryterium 0,2 ms).
- Rozjazdów brak. Brak pokrycia `gate_align` / `detector_trip` (nie ma jeszcze takich rodzin w lockcore v0.1).
- Workflow `spike-determinism.yml` (ubuntu + qemu, macOS arm64 natywnie). Szczegóły: `spikes/determinism/RESULTS.md`.
- CI C3: run [41933859403](https://github.com/woogitsugames/lockwright/actions/runs/41933859403) zielony — x86_64 gcc/clang, Linux aarch64 (qemu), Android arm64 NDK (qemu) i **macOS arm64 natywnie (Apple clang)**: 10 000/10 000 zgodnych. Pierwsze runy padły na braku pakietu `qemu-user-static` w nowym obrazie runnera; fallback na `qemu-user`. Korpus generuje się z rejestru rodzin, więc nowe rodziny lockcore v0.2 (lever, ring_combo, warded) wchodzą do testu automatycznie.

## 2026-11-05 00:10 — C2: spike 3, dźwięk kliknięcia na Androidzie (`spikes/audio-latency/`)
- Plugin Godot Android v2 **`LockwrightLowLatencyAudio`** (AAR): Oboe 1.9.3 ze źródeł, statycznie (`liblwaudio.so` 1,2 MB, arm64). AAudio `LowLatency` + `Exclusive` z fallbackiem `Shared`, natywna częstotliwość urządzenia, bufor 2 × burst (+1 burst po underrunie), próbki float prealokowane, wyzwalanie przez kolejkę SPSC bez blokad i alokacji, miks 16 głosów w callbacku, ponowne otwarcie po rozłączeniu. API: `load_sample`, `play`, `stats` (framesPerBurst, bufferSize, sampleRate, performanceMode, sharingMode, xRunCount, estimated latency, play→mix p50/p95, czas callbacku).
- Aplikacja testowa: lewa połowa ekranu = Oboe, prawa = `AudioStreamPlayer` Godota; błysk połowy na dotyk (kamera 240 fps); statystyki na ekranie i w `logcat` (`LW_AUDIO`).
- Próbki własne (synteza modalna, 48 kHz): set/false_set/break/contact × mosiądz/stal + impuls 1 ms. CI sprawdza, że generują się bit w bit.
- `tools/measure.py`: detekcja onsetów (piezo na ekranie + mikrofon), p50/p95; selftest na nagraniu syntetycznym: 32/32 stuknięć, błąd maks. 0,76 ms, średni 0,08 ms.
- CI: run [41935782743](https://github.com/woogitsugames/lockwright/actions/runs/41935782743) zielony, artefakt **`spike-audio-debug-apk`** (APK 85 MB debug, w nim `liblwaudio.so`).
- **Brak liczb z telefonu** — wymaga urządzenia i interfejsu audio (instrukcja w README). Do zrobienia przez właściciela: 3 × 50 stuknięć na ścieżkę na Pixelu / Samsungu A / tanim telefonie.
- Lokalnie Maven Central odpowiada 429 (limit z kontenera); lokalne buildy przez mirror Google w `~/.gradle/init.d` (poza repo). W CI bez obejść.
- Ograniczenie spike'u: `load_sample` w trakcie grania tej samej próbki nie jest bezpieczny (opisane w README).

## 2026-11-05 00:10 — C4: spike 1 i 2, aplikacje pomiarowe haptyki (`spikes/haptics-latency/`)
- Android: wspólny `HapticCore.kt` (tiery A3→A0: obwiednie `BasicEnvelopeBuilder` co 50 ms / prymitywy CLICK–TICK / waveform z amplitudą co 100 ms / on-off; `USAGE_MEDIA` lub `USAGE_TOUCH`; lista prymitywów z `getPrimitiveDurations`) używany przez wtyczkę Godota `LockwrightHapticsProbe` (AAR) i natywną aplikację Compose — jedyną różnicą jest silnik przed wywołaniem.
- iOS: natywna aplikacja SwiftUI + Core Haptics (`HapticCore.swift`: player ciągły w pętli + `sendParameters` ≤ 60 Hz, transienty w osobnym playerze, reset/stop handler) i moduł GDExtension `LockwrightHapticsProbeIOS` w Objective-C++ (ten sam efekt; Swift w statycznej bibliotece wymagałby runtime'u Swifta w projekcie Xcode z Godota).
- `tools/analyze.py`: piezo z tyłu (+ opcjonalnie na szkle) → onset stuknięcia (2–12 kHz) i wibracji (przyczynowy band-pass 100–400 Hz, bez „wyprzedzania”), p50/p95, różnica Godot − natywna (kryterium 8 ms), test ciągłości oporu (przerwy > 15 ms). Selftest: 30/30, błąd ≤ 0,74 ms, bias +0,62 ms.
- CI `spike-haptics.yml`, run [41936610943](https://github.com/woogitsugames/lockwright/actions/runs/41936610943): **android zielony** (artefakt `spike-haptics-android-apks`: APK Godota i natywny), **ios-native zielony** (artefakt `spike-haptics-ios-native-unsigned`, `.ipa` bez podpisu, Xcode 26.6). **ios-godot** (eksperymentalny, `continue-on-error`): godot-cpp z API zrzuconym z silnika 4.7.2 i moduł ObjC++ budują się, xcframework powstaje, eksport Godota doszedł do projektu Xcode, ale przerwał go brak ikon („Invalid icon settings_58x58”) → dodana własna ikona; run [41938562206](https://github.com/woogitsugames/lockwright/actions/runs/41938562206): **ios-godot zielony** (eksport GDExtension + `xcodebuild` bez podpisu), zapis w D-30.
- Brak liczb z urządzeń (wymaga telefonów i piezo; instrukcja w README).

## 2026-11-05 00:15 — C6: przegląd techniczny i ryzyka (`docs/handoff/SESSION-C-REVIEW.md`)
- 50 uwag (14 High, 24 Medium, 12 Low), tylko raport, bez zmian w cudzym kodzie. Najważniejsze: eksport gry nie zawiera tłumaczeń CSV (R-28, zweryfikowane na `.pck`), binding `lockcore_gd` bez osi `rotate`/`push`/`tool` (R-01), puszczenie kciuka nie zwalnia wytrycha (R-02), brak FeedbackDirectora i ClickAudioBridge w grze (R-20/21), mostki haptyki nie trafiają do buildów (R-41/42), `game-android.yml` z nieistniejącymi flagami `--keystore` i bez ścieżki SDK w ustawieniach edytora (R-38…40 — działające kroki są w workflowach spike'ów).
- Dopisane do ASSETS: HDRI `interior.hdr` (licencja do weryfikacji) i wypieki/rendery spike'u 4.

## 2026-11-05 01:00 — C1: spike 4, fotorealistyczny metal w Godot 4.7 Mobile (`spikes/lit-metal/`)
- Narzędzia: Blender 4.2.9 LTS, Godot 4.7.2 + szablony, Xvfb + Mesa lavapipe (Vulkan na CPU).
- Eksport glTF (`cutaway.glb`, opcja `--glb` skryptu `art/`) i **wypiek** (`tools/bake.py`, `art/` bez zmian): atlasy UV na materiał, albedo/roughness/normal/AO → `*_albedo.png`, `*_normal.png`, `*_orm.png`; 2K mosiądz/nikiel/drewno, 1K stal/kołki/sprężyny/wytrych/żelazo; 15 min na 4 rdzeniach.
- Projekt Godot (renderer Mobile): wariant A (PBR w czasie rzeczywistym) i plan B (płyta Cycles rzutowana przez kamerę + matcap), przełączanie dotknięciem prawego górnego rogu; animacja kołków 1 Hz i wytrycha; nakładka FPS / czas GPU / draw calle; log `LW_PERF` co 10 s.
- **Zgodność z Cyclesem** (`tools/compare.py`, lewa połowa Cycles / prawa Godot):
  - 1236×1650: A — MAE 16,7, PSNR 21,0 dB, SSIM 0,80; **B — MAE 3,65, PSNR 25,7 dB, SSIM 0,93**;
  - 2160×2880: A — MAE 16,8, PSNR 20,9 dB, SSIM 0,79; **B — MAE 3,61, PSNR 25,6 dB, SSIM 0,93**.
  - Zrzuty: `spikes/lit-metal/screens/compare.png`, `compare_*`, `godot_{a,b}_*`, `cycles_*`. Tabela iteracji: `spikes/lit-metal/RESULTS.md`.
- Kluczowe ustalenia: (1) wygląd Cyclesa daje HDRI, a nie lampy (jednostki mm vs m) — zgłoszone dla sesji art w D-31; (2) obrót nieba Blender→Godot = +90° (zmierzony; zły znak: MAE 66–78); (3) ReflectionProbe bez okluzji pogarsza wynik — odbicia z nieba + AO w albedo metali; (4) import tekstur musi mieć VRAM + mipmapy (domyślnie Godot dał nieskompresowane 2K bez mipmap).
- Co odstaje w A: brak cieni od jasnego punktu HDRI (sprężyny i dno komór jaśniejsze), brak odbić wielokrotnych na fazkach, ciemniejszy wytrych.
- CI `spike-lit-metal.yml`: run [41938834569](https://github.com/woogitsugames/lockwright/actions/runs/41938834569) zielony — artefakt **`spike-lit-metal-debug-apk`** (arm64) i zrzuty smoke z lavapipe.
- **Brak FPS z telefonu** (kontener bez GPU) — procedura pomiaru i kryteria TECH §4 w README; wpis do RESULTS po pomiarze. Lightmapa (LightmapGI) nie była potrzebna: plan B zastępuje ją pełnym wypiekiem z Cyclesa.
- Decyzja: D-31 (proponowana).
