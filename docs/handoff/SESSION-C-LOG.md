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
- Kontener (lavapipe): A — 37 draw calli, 118 tys. prymitywów, 228 MB VRAM; B — 36 draw calli, 55 tys. prymitywów, 188 MB VRAM, czas GPU ~17× mniejszy niż A (tylko względnie).
- **Brak FPS z telefonu** (kontener bez GPU) — procedura pomiaru i kryteria TECH §4 w README; wpis do RESULTS po pomiarze. Lightmapa (LightmapGI) nie była potrzebna: plan B zastępuje ją pełnym wypiekiem z Cyclesa.
- Decyzja: D-31 (proponowana).

## 2026-11-05 01:40 — Podsumowanie nocy (sesja C)

| Zadanie | Stan | Liczby | Artefakty CI | Czeka na |
|---|---|---|---|---|
| C1 spike 4 (metal, Godot Mobile) | gotowe w kontenerze | plan B SSIM 0,93 / MAE 3,6; wariant A SSIM 0,80 / MAE 16,7 | `spike-lit-metal-debug-apk` | FPS na tanim Androidzie (README), akceptacja D-31 |
| C2 spike 3 (audio Oboe) | gotowe | selftest analizy: błąd ≤ 0,76 ms | `spike-audio-debug-apk` | pomiar 3×50 stuknięć na telefonach |
| C3 spike 5 (determinizm) | **przeszło** | 10 000/10 000 hashy, 4 buildy lokalnie + macOS arm64 w CI | tabela `determinism-table` | test na fizycznym Androidzie/iPhonie (instrukcja `adb` w README) |
| C4 spike 1–2 (haptyka) | gotowe | selftest analizy: błąd ≤ 0,74 ms | `spike-haptics-android-apks`, `spike-haptics-ios-native-unsigned`, `spike-haptics-ios-godot` | pomiar piezo na urządzeniach; podpis iOS kontem dewelopera |
| C5 sklep | szkic do akceptacji | wszystkie pola w limitach | — | nazwa EN (31 znaków), zakres 1.0, D-06, dane administratora |
| C6 przegląd | gotowy | 50 uwag (14 High) | — | właściciele `game/`, `platform/`, CI |

Decyzje tej sesji: D-30 (GDExtension na iOS działa przy `.gdextension` tworzonym tylko w jobie iOS), D-31 (proponowana: ekran zamka na planie B).
Pytania do właściciela: nazwa EN w sklepie (`store/listing.md` §0), akceptacja D-31, zakup urządzeń/interfejsu audio i piezo do pomiarów spike'ów 1–4 (TECH §6.2), skala świateł w `art/blender/cutaway.py` (D-31).

## 2026-11-05 02:10 — kontrola godzinna
- Repo czyste, wszystkie workflowy sesji C zielone (spike-determinism, spike-audio, spike-haptics z ios-godot, spike-lit-metal run 41947734926).
- Wskazówka dla właściciela `platform/ios` (bez zmian w cudzym kodzie): `game-ios` pada od runu 14 do 20 na kompilacji Core Haptics (ObjC++). Działający wzorzec na Xcode 26.6 / SDK iOS 26.5 jest w `spikes/haptics-latency/godot-ios/src/haptics_probe_ios.mm` (selektory `createAdvancedPlayerWithPattern:error:`, `startAtTime:error:`, `sendParameters:atTime:error:`, stałe `CHHapticEventTypeHapticTransient`, `CHHapticDynamicParameterIDHapticIntensityControl`, ARC przez `-fobjc-arc`) oraz w jobie `ios-godot` w `.github/workflows/spike-haptics.yml` (godot-cpp z API zrzuconym przez `godot --dump-extension-api`, osobne xcframework dla modułu i godot-cpp).

# Etap 2 (`SESSION-C-PROMPT-2.md`)

## 2026-11-05 08:15 — postęp godzinny
- **Zadanie 1 (D-33, pomiary):** aplikacja „LW Pomiary” na Androida (Godot + wtyczka Kotlin: akcelerometr do 400+ Hz z `HIGH_SAMPLING_RATE_SENSORS`, mikrofon jako pętla zwrotna, kliknięcie Oboe vs `AudioStreamPlayer`, 20 stuknięć) i na iOS (SwiftUI: Core Haptics, Core Motion, AVAudioEngine). Kreator po polsku, werdykt słowami i kształtem, JSON zapisywany i udostępniany. CI `spike-measure` run [41989748836](https://github.com/woogitsugames/lockwright/actions/runs/41989748836): **android i ios zielone** (artefakty `measure-android-apk`, `measure-ios-unsigned`). Instrukcja: `docs/handoff/POMIARY.md`; skrypt `spikes/measure/tools/ingest.py` dopisuje tabelę do TECH.md (sekcja 8, znaczniki `MEASURE:BEGIN/END`).
- **Zadanie 2 (sklep):** nazwa EN „Lockwright: Locksmith on Call” (D-32), słowa kluczowe EN 99 B, `check_lengths.py` ALL OK; szablon zrzutów iPhone 6,9" / 6,5" / Android z renderami 2160 px, podpisy bez obietnic spoza gry, arkusze `contact_pl/en.png`; `out/` poza repo (44 MB). Manifest prywatności: CI wypisze `PrivacyInfo.xcprivacy` generowany przez Godota (weryfikacja w toku).
- **Zadanie 3 (audio v2):** w toku (subagent).
- **Zadanie 5 (drugi przegląd):** sekcja w `SESSION-C-REVIEW.md` — GUT 34/34 i smoke OK lokalnie; **N-01 High: wszystkie 3 workflowy gry mają niepoprawny YAML od 5bddbd3 i nie uruchamiają się**; N-02 High: na Androidzie segment oporu ucina transient; N-03…N-08.
- Zadania 4 i 6: czekają (4 — na scenę `game/scenes/photoreal/`).

## 2026-11-05 08:25 — Etap 2: podsumowanie

| Zadanie | Stan | Liczby | Artefakty CI | Czeka na |
|---|---|---|---|---|
| 1. Pomiary na telefonach właściciela (D-33) | **gotowe** | kreator 4 kroki (~4 min); akcelerometr + mikrofon + znaczniki; werdykt słowami i kształtem; JSON + udostępnianie; `ingest.py` → TECH.md §8 | `measure-android-apk`, `measure-ios-unsigned` (spike-measure, zielone) | pomiar właściciela według `docs/handoff/POMIARY.md`; iPhone wymaga Maca (darmowe Apple ID, 7 dni) albo konta Apple Developer (TestFlight) |
| 2. Sklep (`store/`) | **gotowe** (poza danymi właściciela) | nazwa EN wg D-32 (29 znaków), słowa kluczowe EN 99 B, `check_lengths.py` ALL OK; zrzuty iPhone 6,9" / 6,5" / Android × 8 kadrów × PL/EN generowane skryptem | — | domena, administrator danych, e-mail do IARC; manifest prywatności — w toku weryfikacji z eksportu Godota |
| 3. Dźwięk realistyczny (`audio/v2/`) | **gotowe** | 464 WAV (20 zdarzeń, 4 materiały, 6 wariantów; 2 pętle × 4 × 4), onset ≤ 0,21 ms, deterministyczne; false_set vs set: centroid −34…−45%, energia po 25 ms +5…+12 dB | — | podmiana w `game/` przez sesję B (instrukcja w `audio/v2/README.md`) |
| 4. Wydajność planu B | **gotowe (APK)** | scena sesji A + HUD: p50/p95/p99, 1% low, GPU, VRAM; werdykt po 10 min | `planb-perf-apk` (spike-planb, zielone) | 10-min test na tanim Androidzie (POMIARY §7a) |
| 5. Drugi przegląd | **gotowe** | ~35 poprawek sprawdzonych (GUT 34/34, smoke OK), nowe N-01…N-12; **N-01 High: workflowy gry to niepoprawny YAML (CI gry nie startuje)**, **N-09 High: samouczek nigdy się nie kończy**, N-02 High: Android ucina transient segmentem oporu | — | poprawki sesji B |
| 6. Audyt dostępności | **gotowe** | cele dotyku ≥ 48 OK; kontrast metal/tło 7,5–7,8:1; braki: safe-area w menu (High), poziom (ucięcia), domyślny font, skalowanie tekstu | — | poprawki sesji B/A |

Decyzje tej części: brak nowych D-NN (wszystkie rozstrzygnięcia mieszczą się w D-31…D-33). Godzinne wznawianie sesji (scheduled task) zaktualizowane na etap 2.

## 2026-11-05 08:35 — manifest prywatności zweryfikowany
- `PrivacyInfo.xcprivacy` z eksportu Godota 4.7.2 (CI `spike-haptics` run 41990034047): FileTimestamp `DDA9.1`+`C617.1`, SystemBootTime `35F9.1`, DiskSpace `E174.1`+`85F4.1`, tracking `false`, bez zbierania danych, **bez UserDefaults**. Rekomendacja w `store/privacy.md`: w presecie iOS zostawić tylko `C617.1`, `35F9.1`, `E174.1` (powody „pokazywania użytkownikowi” nas nie dotyczą). Zadanie 2 domknięte poza danymi właściciela (domena, administrator, e-mail IARC).

# Etap 3 (`SESSION-C-PROMPT-3.md`)

## 2026-11-05 09:25 — postęp godzinny
- **Zadanie 1 (haptyka, `haptics/`):** gotowe, 15a173c. 7 rodzin, 83 pary rodzina×zdarzenie → 116 AHAP + 2 szablony ciągłe, 51 plików modulacji, 75 kompozycji Androida; `build.py` deterministyczny, `validate.py`: schemat i budżet OK (transjenty/10 s: iOS 17–23 / limit 40, A0 1,2–4,4 / 8; RMS ≤ 0,28; wypełnienie 58–65%). Podgląd HTML zsynchronizowany z audio/v2. Niespójności FEEL.md (9 punktów) — w `haptics/README.md`, do przeglądu.
- **Zadanie 3 (QA, `qa/`):** gotowe, 2821bee + 741255b. Bot gra karierę headless (wejścia solvera lockcore przez `InputSampler`, 120 Hz), workflow `qa-career` (noc + push `game/**`, `qa/**`), artefakt `qa-career-report`. Wynik: przed commitami sesji B z 09:00 — 27/29 zleceń, 0 soft-locków; po nich — 16/29 i **N-13 High: ekran planu B nie kończy zlecenia ani samouczka**, N-14 (plan B ignoruje seed/tier zlecenia), N-15 (odmowa nalicza reputację wielokrotnie).
- **Zadanie 4 (przegląd ciągły):** rundy 1 i 2 w `SESSION-C-REVIEW.md` (N-01, N-03, N-05 zweryfikowane naprawione; N-09 nie działa w praktyce przez N-13).
- Następne: zadanie 2 (audio v2, część 2).

## 2026-11-05 10:12 — postęp godzinny i podsumowanie listy etapu 3

Od ostatniego wpisu: zadanie 2 (dźwięk cz. 2, ebae8c2), 5 (strona, f535a8b), 6 (sklep cz. 2: aa30e61, 4b4d4db), 7 (legal, 16c730d),
8 (A11Y runda 2, 0f86d16), 9 (budżety, 2e85d99), 10 (determinizm w APK, 1ac7395), przegląd rundy 3 (N-17…N-20).
**Strona (`site/`): workflow GitHub Pages przygotowany w `site/deploy/pages.yml`, celowo NIEWŁĄCZONY** — wymaga Twojej
zgody i włączenia Pages w ustawieniach repo (instrukcja w nagłówku pliku).

| # | Zadanie | Stan | Liczby | CI / artefakty | Czeka na |
|---|---|---|---|---|---|
| 1 | Haptyka (`haptics/`) | **gotowe** | 7 rodzin, 83 pary zdarzeń → 116 AHAP + 75 kompozycji Androida + 51 modulacji; budżet OK (iOS 17–23 transjentów/10 s przy limicie 40, A0 ≤ 4,4/8) | — (`build.py`, `validate.py` lokalnie) | 9 niespójności FEEL.md do decyzji (README) |
| 2 | Dźwięk cz. 2 (`audio/v2/`) | **gotowe** | 4 pętle otoczenia 30 s, 34 dźwięki UI, 9 nagród; LUFS: zamek open −23,3 M, set −28,9 M, nagrody −25 M, UI −32 M, otoczenie −35 I; onset zdarzeń ≤ 2 ms | `check_v2.py` OK | odsłuch właściciela (lista w README); `break` true peak +0,6 dBTP (WARN) |
| 3 | Automat QA (`qa/`) | **gotowe** | przed 09:00: 27/29 zleceń, 0 soft-locków; teraz 16/29, 10 soft-locków (N-13) | `qa-career` (noc + push), artefakt `qa-career-report`; czerwony do naprawy N-13 | sesja B: N-13, N-14, N-15 |
| 4 | Przegląd ciągły | **trwa** | rundy 1–3, nowe N-13…N-20; zweryfikowane N-01, N-03, N-05 | — | — |
| 5 | Strona (`site/`) | **gotowe** | 8 stron PL/EN, 2,9 MB, sprawdzacz zakazów/linków/alt OK | Pages **niewłączone** | zgoda właściciela, dane kontaktowe, domena |
| 6 | Sklep cz. 2 | **gotowe** (zrzuty: wersja robocza) | 5 z 8 kadrów z prawdziwego ekranu zamka 1320×2868; scenariusz App Preview 30/15 s + 9 ujęć; ankiety przejrzane pod Tryb Zleceń + deklaracje Play/App Store | — | N-13/N-14 (nagranie), menu w domyślnym wyglądzie, dane właściciela |
| 7 | Legal (`store/legal/`) | **gotowe (szkic)** | warunki PL/EN z miejscami D-06, polityka (kopia z kontrolą zgodności), nota „to gra, nie kurs” w 3 długościach | `check_sync.py` OK | prawnik, D-06 |
| 8 | A11Y runda 2 | **gotowe** | naprawione 2/9 (A-06, A-08), częściowo 2, regres 1 (safe-area → A-10 High), nowe A-10…A-12 | `qa/bot/a11y_shots.gd` | sesja B: A-10, A-11 |
| 9 | Budżety wydajności | **gotowe** | POMIARY §8: progi FPS/pamięć/APK ≤ 80 MB/IPA ≤ 100 MB/start; dziś pck 26,5 MB, start headless 0,36 s, RSS 105 MB | `perf-budget` (noc + push `game/**`) | pomiar na telefonach (POMIARY §7a) |
| 10 | Determinizm w APK | **gotowe lokalnie, CI w toku** | host 630/630 zgodnych; APK arm64 z lockcore_gd + korpus zbudowany | `spike-determinism-apk` (emulator x86_64 API 30/34 z translacją ARM) | wynik runu CI; natywnie: Twój telefon (to samo APK) |

Dalej: przegląd ciągły (zadanie 4) co godzinę, sprawdzenie wyników `spike-determinism-apk`, `perf-budget`, `qa-career`.

# Etap 4 (`SESSION-C-PROMPT-4.md`)

## 2026-11-05 10:40 — start etapu 4, pierwsza godzina
- **Etap 3, zadanie 10 (domknięcie):** `spike-determinism-apk` run 1: build + korpus hosta (630/630) + eksport APK arm64 **zielone**; emulatory API 30/34 zainstalowały APK arm64 na obrazie x86_64 (translacja ARM działa), ale `am start` odrzucił niewyeksportowaną aktywność `GodotApp`. Poprawka 1117b9c (start przez intencję LAUNCHER) — czekam na run 2.
- **Zad. 1 (CI):** runda 1 w `SESSION-C-REVIEW.md` — N-22 (`game-tests`: smoke z pck bez `tests/` i bez .so), N-23 (`game-android`: API obwiedni Androida 16 w Kotlinie), N-24 (`game-ios`: `godot::memnew`), N-19 (argumenty `screens.gd`), N-21 (NDK), N-28 (godot-cpp z `master`) — każde z linią logu i diffem. `qa-career` przebudowany: błędy gry → raport i ⚠, czerwony tylko przy awarii automatu.
- **Zad. 2 (contrib/gpt):** 0/30 dostaw; automat odbioru `qa/contrib/check_gpt.py` + tabela `contrib/REVIEW.md`.
- **Zad. 3:** `docs/handoff/TESTY-SKLEPY.md` (Google Play internal testing, TestFlight; koszty, czasy, czego nie zrobię bez Ciebie).
- **Zad. 4:** `docs/handoff/RELEASE-CHECKLIST.md` (43 punkty, stan + odpowiedzialny + dowód).
- **Zad. 5:** bot QA cz. 2 — profile „średni”/„niezdarny” (boty lockcore `--feel`/`--clumsy`), kariera po angielsku, „w ciemności”, ekonomia vs `econ_sim` → N-25 (gra nie wypłaca napiwków, −20% vs model), N-26 (EN: karty dokumentów). Macierz w `qa-career`.
- **Zad. 6:** pomiarów właściciela jeszcze nie ma (`docs/handoff/measurements/` nie istnieje) — czeka.
- **Zad. 7:** strona „Jak gramy uczciwie” PL/EN; G12/G13 czekają na dostawy.
- **Zad. 8:** `store/legal/DEPENDENCIES.md` → N-27 (brak not licencyjnych w aplikacji — High przed wydaniem), N-28.

## 2026-11-05 10:41 — etap 4: tabela statusów (po pierwszym przejściu listy)

| # | Zadanie | Stan | Wynik | Czeka na |
|---|---|---|---|---|
| P3-10 | Determinizm w APK (domknięcie etapu 3) | **w toku** | build + host 630/630 ✅, APK instaluje się na emulatorze; run 2 po poprawce startu | wynik runu |
| 1 | Pilnowanie zielonego CI | **trwa (co godzinę)** | runda 1: N-22, N-23, N-24 (+N-19, N-21, N-28) z diffami; moje workflowy: perf-budget ✅, spike-determinism ✅, qa-career przebudowany | poprawki sesji B |
| 2 | Przegląd dostaw ChatGPT | **gotowe narzędzie, 0/30 dostaw** | `qa/contrib/check_gpt.py`, `contrib/REVIEW.md` | dostawy w `contrib/gpt/` |
| 3 | Instrukcja testów w sklepach | **gotowe** | `docs/handoff/TESTY-SKLEPY.md` | konta i sekrety właściciela |
| 4 | Lista kontrolna wydania | **gotowe (żywy dokument)** | `docs/handoff/RELEASE-CHECKLIST.md` | — |
| 5 | Bot QA cz. 2 | **gotowe** | 5 przebiegów (solver/średni/niezdarny/EN/ciemność), ekonomia vs econ_sim (N-25), EN ucięcia (N-26), kanały 22/22 ✅ | N-13 (sesja B/A) |
| 6 | Pomiary właściciela → TECH §8 | **czeka** | — | pliki `docs/handoff/measurements/*.json` |
| 7 | Strona cz. 2 | **częściowo** | „Jak gramy uczciwie” PL/EN ✅; publikacja wyłączona | G12/G13 przyjęte |
| 8 | Audyt licencji | **gotowe** | `store/legal/DEPENDENCIES.md`, N-27 (High przed wydaniem), N-28 | sesja B: ekran licencji |
| 9 | Ciągły przegląd | **trwa** | rundy co godzinę (scheduled task :06) | — |

## 2026-11-05 10:54 — determinizm w APK: wynik (etap 3, zadanie 10)
- `spike-determinism-apk` run 3 (42012656332, commit 1117b9c): **API 34 — 630/630 powtórek zgodnych**, `LW_DET_DONE platform=Android arch=arm64 replays=630 ok=630 bad=0`, digest urządzenia = digest hosta (`e091167f18b6…`), 5,1 s na odtworzenie korpusu. To `lockcore_gd` arm64 z APK w prawdziwym runtime Godota na Androidzie (na emulatorze x86_64 przez translację ARM).
- API 30: job wciąż trwa (czeka do 900 s na wynik) — sprawdzę w rundzie 11:06.
- Zadanie 10 etapu 3: **gotowe** (API 34); natywny arm64 na telefonie: to samo APK (artefakt `det-apk`) pokaże wynik na ekranie.

## 2026-11-05 11:17 — runda godzinna (etap 4)
- **Dostawy ChatGPT:** 19 z 30 (G03, G07, G08, G10, G15, S01–S04, T01–T10). Przyjęte 17 (w tym warunkowo / z uwagą S01, S02, S03 — odsłuch właściciela), do poprawki 2: G03 (mapy PNG tylko „w ZIP-ie poza repo”), T10 („pin master lock” koliduje z marką Master Lock). Odrzucone 0. Szczegóły: `contrib/REVIEW.md`.
- **Sesja B naprawiła** N-14, N-15, N-22…N-26, A-11 (i N-19/N-21/N-28 w workflowach). **Nowa regresja N-29 (High):** `lock_job.gd` dziedziczy po pliku .tscn → nie kompiluje się, żaden zamek pin_tumbler ani samouczek nie startuje (kariera 0/29). Poprawka (2 linie + scena dziedzicząca) sprawdzona na kopii gry: **19/29, samouczek ukończony po raz pierwszy, 0 soft-locków**.
- **qa-career:** błąd skryptu GDScript albo kariera bez żadnego zamka = czerwony run (bloker); pozostałe problemy gry nadal jako ⚠.
- **Determinizm APK:** API 34 ✅ 630/630; API 30 — aplikacja startuje, ale bez wyniku w 15 min (starsza translacja ARM/GLES w obrazie) → job informacyjny (`continue-on-error`), w logu wydruk logcat.
- RELEASE-CHECKLIST zaktualizowana (T9, T11, C2, C7, A2, A4).

# Etap 5 (`SESSION-C-PROMPT-5.md`)

## 2026-11-05 14:15 — przejęcie sesji C
- Nowa sesja C przejmuje rolę po poprzedniej (limit). Przeczytane: CLAUDE.md, SESSION-C-PROMPT 1–5, ten log (ostatni wpis 11:17).
- Stan na start: `main` @ 094eeb8. CI czerwone: `game-ios` (sesja B, run 42031298421 na 9eca512 w toku), `perf-budget` i `qa-career` (moje) od 11:49. Kolejka runnerów zapchana (`game-tests`/`game-android` queued od ~11:44).
- Kolejność: (1) strażnik CI — perf-budget, qa-career, game-ios; (4) raport z telefonu (`device-tests/REPORT.md`, `measurements/*.json`) → ingest, TECH §8, N-xx; potem (2) dostawy GPT/Magnific/Gemini, (3) sklep cz. 3, (5) bot QA cz. 3, (6) przegląd ciągły. Z etapu 4 otwarte: zad. 2 (dostawy), 6 (= zad. 4 etapu 5), 7 (strona z G12/G13).
- W katalogu roboczym leżą niezacommitowane pliki innej sesji (`docs/ASSETS.md`, `art/marketing/`, `art/blender/marketing/`) — nie dotykam ich, commituję tylko własne ścieżki.

## 2026-11-05 14:33 — przejęcie sesji C (druga zmiana w etapie 5)
- Kolejna nowa sesja C przejmuje rolę po sesji z 14:15 (limit, ostatni commit e0caa51). Przeczytane: CLAUDE.md, SESSION-C-PROMPT 1–5, ten log.
- Środowisko: skrypt startowy kontenera padł na `/opt/node20/bin/node` (obraz ma node22/node24), pracuję na node 22; Godot 4.7.2 i lockcore zbudowane lokalnie.
- **Zad. 1 (strażnik CI), runda 1:** `perf-budget` czerwony przez paczkę 288,9 MB (próg 70). Odtworzyłem lokalnie i znalazłem przyczyny: grafiki GPT importowane bezstratnie (128 MB), zrzuty kontrolne Gemini w `game/` (90 MB) i niepodłączone rodziny GEM2 (35 MB). Poprawka sprawdzona lokalnie (289 → 52,5 MB) jest w **N-30** z gotowym diffem dla B i A. Progów nie podnoszę. `game-ios`: poprawka B 9eca512 w toku. `qa-career`: run po e0caa51 w kolejce, odtwarzam lokalnie.
- **Zad. 4 (raport z telefonu):** `ingest.py` → TECH §8, plus §8.1 (spike 4 na A16: GPU 6,4 ms p95, klatka 18,2 ms przez tempo klatek, RAM 598 MB, start 4,4 s, zero throttlingu) i §8.2: **werdykt GO warunkowy dla Godota** (żaden warunek zmiany z §1.9 nie zachodzi; Oboe +73 ms zysku, więc natywny mostek audio jest obowiązkowy; haptyka i iOS nie rozstrzygnięte). BUG-01/02 już naprawione, BUG-03…14 → **N-31…N-43**; moje (BUG-05 `planb-perf` bez `.so`, BUG-12 klasa urządzenia, BUG-13 PerfHud) naprawione od razu (0ba0931, 184fa84).
- Następne: qa-career lokalnie → dostawy (zad. 2: contrib/gpt, Magnific, Gemini) → sklep cz. 3 → bot QA cz. 3.

## 2026-11-05 15:28 — postęp godzinny (etap 5)
- **Zad. 1 (CI):** wszystkie trzy moje czerwone workflowy mają przyczynę po stronie gry, poprawki zweryfikowane lokalnie. `qa-career`: **N-44** (`workshop_screen.gd`, API Godota 3: warsztat martwy, zero zakupów) i **N-45** (`icon_max_width`). Z obiema poprawkami kariera kończy się `career_complete`, 0 błędów, 0 soft-locków, 17 zakupów. `perf-budget`: **N-30** (289 → 52,5 MB). `game-ios`: B iteruje (afbd957 w kolejce). `release-aab`: N-44 i brak keystore. Zasada nr 1 B: wpisy zadań 3 i 4 bez linku do zielonego runu (zgłoszone). Automat QA zgłasza teraz martwy przycisk wprost i grupuje błędy skryptów.
- **Zad. 2 (dostawy):** `contrib/REVIEW.md`. GPT: przyjęte G01, G03 v2, G09, G10 v2 (brak ASSETS v2), G11, G12 v2 (rekomenduję kierunek 01 „L”), G16 (z uwagami: `yale`/`sargent` w nazwach plików), T10 v2. Do poprawki: G04 (winieta, szwy do 170%), G05 i G14 (czekają na v2), G06 (mory), G13 (v2 zlecone; 16:9 i feature graphic użyteczne). Magnific: 43 zdjęcia przyjęte. Gemini: GEM1 jako animatik, **GEM2 do poprawki (stany nierozróżnialne: lever bound↔overset 0,01% pikseli)**, GEM3 i GEM4 przyjęte. Automat: obsługa 16-bit i miara szwu niskoczęstotliwościowego. S03 (Whisper small, offline): 77/96 plików, **0 ze słowami** (dokańcza się).
- **Zad. 3 (sklep cz. 3):** `store/tools/build_store_set.py`: komplet App Store (6,9" i 6,5", PL/EN × 8, ikona 1024 bez alfy) i Google Play (1080×1920 × 8, ikona 512, feature graphic 1024×500), **57/57 kontroli limitów OK**. Prawdziwe ekrany zamka wyrenderowane lokalnie (Vulkan lavapipe). Słabość: kadry 01–03 i 06 są podobne; kadr z klientką czeka na N-36 i N-47.
- **Zad. 4:** zrobione (wpis 14:33).
- **Zad. 5 (QA cz. 3):** `qa/assets/check_assets.py` w `qa-career`: tła G07 41/41, dźwięki 34/34, portrety G09 12/51 (**N-49**), głosy 0/51, bo **N-48**: `play_voice` nie znajduje żadnego pliku S03.
- **Etap 4, zad. 7 (strona):** ikona G12 v2 i key art G13 na stronie i w press kicie (84211a9), publikacja dalej wyłączona.

| # | Zadanie etapu 5 | Stan |
|---|---|---|
| 1 | Strażnik CI | trwa; 3 rundy, N-30, N-44, N-45 z diffami; czeka na B |
| 2 | Odbiór dostaw (GPT, Magnific, Gemini, S03) | gotowe; S03 Whisper 77/96 bez słów, reszta w toku |
| 3 | Sklep cz. 3 | gotowe (57/57 OK); do podmiany kadr z klientką po N-36 |
| 4 | Raport z telefonu → TECH §8, N-xx | gotowe (GO warunkowo; N-31…N-43) |
| 5 | Bot QA cz. 3 | gotowe (N-48, N-49) |
| 6 | Ciągły przegląd | trwa |
