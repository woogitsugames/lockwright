# Spike 3 — kliknięcie < 30 ms na Androidzie (Oboe/AAudio vs Godot)

Cel i kryteria: `docs/TECH.md` §1.6 i §4 (spike 3). Godot 4.7.2 na Androidzie gra przez OpenSL ES z buforem 2 × 1024 ramek przy 44,1 kHz (≈ 46 ms samego bufora). Ten spike sprawdza własną ścieżkę dla krótkich dźwięków zdarzeń: plugin Android v2 **`LockwrightLowLatencyAudio`** na **Oboe 1.9.3** (Apache 2.0).

## Co jest w katalogu

| Ścieżka | Zawartość |
|---|---|
| `plugin-android/plugin/src/main/cpp/click_engine.*` | silnik C++: strumień AAudio `PerformanceMode::LowLatency` + `SharingMode::Exclusive` (fallback `Shared`), natywna częstotliwość urządzenia, bufor 2 × burst (rośnie o burst po underrunie), próbki PCM float prealokowane przy ładowaniu (resampling przy ładowaniu, nie w callbacku), wyzwalanie z wątku gry przez kolejkę SPSC bez blokad i alokacji, 16 głosów miksowanych w callbacku, ponowne otwarcie strumienia po rozłączeniu (słuchawki, zmiana trasy) |
| `plugin-android/plugin/src/main/java/.../LockwrightLowLatencyAudio.kt` | plugin v2: `load_sample(id, pcm_bytes, rate)`, `play(id, gain, pitch)`, `stats()`, `stop()`; zwalnia strumień w tle (`onMainPause`) |
| `addons/lockwright_low_latency_audio/` | wtyczka edytora: dołącza AAR (`bin/…aar`, budowany w CI) do eksportu Androida |
| `scripts/main.gd` | aplikacja testowa: **lewa połowa ekranu = Oboe**, **prawa = `AudioStreamPlayer` Godota**; górny pasek zmienia próbkę; dotknięta połowa błyska przez 1 klatkę (pomiar kamerą); na ekranie statystyki strumienia |
| `samples/*.wav` | własne kliknięcia, synteza modalna (`tools/synth_clicks.py`), 48 kHz 16-bit mono: `set`, `false_set`, `break`, `contact` × mosiądz/stal + `impulse` (1 ms, ostry atak do pomiaru) |
| `tools/measure.py` | analiza nagrania 2-kanałowego: onsety, parowanie dotyk→dźwięk, p50/p95; `--selftest` na nagraniu syntetycznym (błąd < 1 ms) |

Statystyki `stats()`: `sampleRate`, `framesPerBurst`, `bufferSize`, `bufferCapacity`, `performanceModeName`, `sharingModeName`, `audioApiName`, `estimatedLatencyMs` (Oboe `calculateLatencyMillis`, z timestampów AAudio), `callToMixP50Ms/P95Ms` (od `play()` do callbacku, który zaczyna miksować głos), `callbackP95Us`, `xRunCount`, `deviceNativeRate/Burst`, `proAudio`, `lowLatencyFeature`. Co 0,5 s aplikacja wypisuje je też do logu: `adb logcat -s godot | grep LW_AUDIO`.

## Instalacja na telefonie

1. GitHub → Actions → **spike-audio** → ostatni zielony run → artefakt `spike-audio-debug-apk` → rozpakuj.
2. Telefon: Ustawienia → Opcje programisty → Debugowanie USB, albo po prostu otwórz plik APK na telefonie („instaluj z nieznanych źródeł”).
3. `adb install -r spike-audio-debug.apk`.

## Pomiar (zewnętrzny, „prawda”)

Sprzęt: interfejs audio 2-kanałowy 48 kHz (lub więcej), **mikrofon kontaktowy / piezo** (5–15 €) i mały mikrofon pomiarowy (lub drugi piezo).

1. Telefon: tryb samolotowy, jasność 50%, bateria > 50%, głośność multimediów 70–100%, wyłączone „dźwięki dotyku” i wibracja przy dotyku, build debug z CI (release zmierzymy później; różnica dotyczy CPU, nie bufora).
2. Piezo przyklej taśmą **na ekranie** (krawędź, blisko miejsca dotyku) → kanał 1 (lewy). Uderzenie palcem/rysikiem w ekran daje szerokopasmowy impuls.
3. Mikrofon 1–2 cm od głośnika telefonu → kanał 2 (prawy).
4. Wybierz w aplikacji próbkę `impulse` (górny pasek).
5. Nagraj w Audacity/Reaperze 48 kHz, 16/24 bit, stereo: **seria A** — 50 stuknięć w lewą połowę (Oboe), ok. 2 na sekundę; zapisz `oboe_1.wav`. **Seria B** — 50 stuknięć w prawą połowę (Godot); zapisz `godot_1.wav`. Powtórz 3 serie każdej ścieżki (wymóg z TECH §4: 3 × 50).
6. Analiza:
   ```bash
   python3 tools/measure.py oboe_1.wav oboe_2.wav oboe_3.wav godot_1.wav godot_2.wav godot_3.wav --csv lat.csv --plot lat.png
   ```
   Skrypt wypisuje dla każdego pliku `taps`, `paired`, `p50_ms`, `p95_ms`, `mean`, `min`, `max`. Stuknięcia bez dźwięku w oknie 3–300 ms są liczone jako `unpaired` (sprawdź, czy nie stukasz w górny pasek).
   Opcje: `--thresh-db -30` (próg onsetu), `--min-ms 3` (pomija akustyczny odgłos stuknięcia w mikrofonie), `--max-ms 300`, `--tap-ch 0 --mic-ch 1`.
7. Dodatkowo (opcjonalnie) kamera 240 fps: film palca i ekranu — błysk połowy ekranu pokazuje opóźnienie obrazu (4,17 ms/klatkę).
8. „Larsen test” samego wyjścia: aplikacja OboeTester (Google, open source) → *Round Trip Latency* na tym samym telefonie; wynik wpisz obok, bo oddziela wyjście od wejścia dotyku.

Wynik wpisz do tabeli w `RESULTS.md` (urządzenie, wersja Androida, tier, p50/p95 A i B, różnica B − A, `estimatedLatencyMs`, `framesPerBurst`, `sharingMode`).

## Kryteria (z `docs/TECH.md` §4, spike 3)

- **Przeszło:** Pixel p95 ≤ 35 ms; Samsung A ≤ 50 ms; tani ≤ 80 ms; iPhone ≤ 30 ms (ścieżka iOS osobno); wariant Oboe poprawia Androida o **≥ 30 ms** względem Godota; |audio − haptyka| ≤ 15 ms; **0 underrunów** w 10 min po rozgrzaniu (`xRunCount` w statystykach).
- **Nie przeszło:** Pixel > 45 ms, albo Oboe w AAR koliduje z OpenSL Godota (dwa strumienie → trzaski, utrata fokusu). Test kolizji: stukaj naprzemiennie lewą i prawą połowę przez 2 min i słuchaj trzasków; `opens` w statystykach > 1 oznacza ponowne otwarcie strumienia.

## Budowanie lokalnie

```bash
cd spikes/audio-latency/plugin-android && gradle :plugin:assembleRelease     # JDK 17, SDK 36, NDK 29.0.14206865, CMake 3.22.1
mkdir -p ../addons/lockwright_low_latency_audio/bin
cp plugin/build/outputs/aar/plugin-release.aar ../addons/lockwright_low_latency_audio/bin/lockwright-low-latency-audio-release.aar
cd .. && godot --headless --path . --import && godot --headless --path . --install-android-build-template
GODOT_ANDROID_KEYSTORE_DEBUG_PATH=~/debug.keystore GODOT_ANDROID_KEYSTORE_DEBUG_USER=androiddebugkey \
GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD=android godot --headless --path . --export-debug Android build/spike-audio-debug.apk
python3 tools/synth_clicks.py samples          # odtwarza próbki bit w bit
```

## Ograniczenia spike'u (świadome)

- `load_sample` podmienia bufor bez synchronizacji z głosem, który go właśnie gra: w spike'u próbki ładujemy raz na starcie. W wersji produkcyjnej: podwójne buforowanie albo wymiana slotu dopiero po wyciszeniu głosów.
- Synchronizacja z haptyką (|Δ| ≤ 15 ms) jest częścią spike'u 2 i FeedbackDirectora w `game/`, nie tego katalogu.
- Wersja iOS ścieżki (AVAudioEngine / `CHHapticAudioResource`) nie jest tu zbudowana — iOS według TECH §1.6 nie wymaga własnego sterownika do progu 30 ms; mierzymy go aplikacją z `spikes/haptics-latency/` (tap → transient + dźwięk).
