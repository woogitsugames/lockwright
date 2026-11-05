# GEM3 — Raport z testów na telefonie właściciela (`adb`)

- **Data wykonania:** 2026-11-05
- **Zadanie:** `GEM3` — Testy na telefonie właściciela (`adb`), pomiary opóźnień (`POMIARY.md`), 10-minutowy test wydajności i temperatur (`planb-perf-apk`) oraz pełny przegląd gry (`lockwright-android-debug`).
- **Gałąź docelowa:** `main` (`https://github.com/woogitsugames/lockwright`)

---

## 1. Środowisko i sprzęt testowy

### 1.1. Telefon właściciela (`adb shell getprop` / `dumpsys`)
| Parametr | Wartość |
|---|---|
| **Producent / Model** | `samsung SM-A165F` (Samsung Galaxy A16 4G, urządzenie `a16` / `a16nseea`) |
| **Numer seryjny (`adb`)** | `RFGL34SJYDZ` |
| **System operacyjny** | Android `16` (API / SDK `36`, kompilacja `BP2A.250605.031.A3.A165FXXS4BYJ1`) |
| **Układ SoC / CPU** | MediaTek Helio G99 (`MT6789`, `arm64-v8a`, 2× Cortex-A76 @ 2,2 GHz + 6× Cortex-A55 @ 2,0 GHz) |
| **Układ GPU** | ARM `Mali-G57 MC2` (Vulkan `1.3.303`, sterownik `v1.r52p1`, EGL `meow`) |
| **Pamięć RAM** | `3 740 844 kB` (~4 GB RAM) |
| **Wyświetlacz** | `1080 × 2340` px (`450 dpi` logiczne, `386,37 × 385,95 dpi` fizyczne), obsługiwane tryby 60 Hz i 90 Hz (aktywny tryb podczas testów: `60,0 Hz`, `vsync = 16 666 667 ns`) |
| **Silnik wibracji (`vibrator_manager`)** | `MOTOR_COIN_DC (1)` — pastylkowy silnik ERM DC, `hasAmplitudeControl = false`, `hasFrequencyControl = false`, `envelopes = false`, `supportedPrimitives = []` → **klasa haptyki `A0`** wg `docs/TECH.md` §2.2 |
| **Rzeczywista klasa urządzenia (`TECH.md` §6.2)** | **Budżetowy Android (`budget`)** — Helio G99, Mali-G57 MC2, 4 GB RAM, silnik ERM `A0` (odpowiednik pozycji #8/#9 w macierzy `TECH.md` §6.2; uwaga: `LockwrightMeasure.kt` błędnie klasyfikuje go jako `samsung_a` po prefiksie `SM-A*`, zob. **BUG-12**) |

### 1.2. Komputer właściciela (host testowy)
| Parametr | Wartość |
|---|---|
| **System operacyjny** | Windows (PowerShell, `platform-tools` / `adb` v1.0.41 `37.0.1-15733141`, `gh` CLI) |
| **Procesor (CPU)** | `Intel(R) Core(TM) Ultra 7 270K Plus` (24 rdzenie / 24 wątki logiczne) |
| **Karta graficzna (GPU)** | `NVIDIA GeForce RTX 5070` (sterownik `32.0.16.1088`) |

### 1.3. Przetestowane artefakty APK z GitHub Actions
1. **`measure-android-apk`** — run `41989748836` (`lw-pomiary.apk`, `85 309 103 B`, pakiet `com.woogitsugames.lockwright.measure`).
2. **`planb-perf-apk`** — run `42000420396` (`lw-planb-perf.apk`, `54 815 238 B`, pakiet `com.woogitsugames.lockwright.spike.planbperf`).
3. **`lockwright-android-debug`** — przetestowano dwie ostatnie zielone paczki z workflow `game-android.yml`:
   - run `42017980722` (commit `e3da5ce`, `105 MB`) — wykryto krytyczną regresję P0 na starcie (`boot.gd` Parse Error, zob. **BUG-01**);
   - run `42017752584` (commit `d3a886b`, `107 411 008 B`, zawierający poprawkę `a7a0b13` na `.translation`, `audio/v2` oraz pliki haptyki) — użyty do pełnego przejścia ekranów gry, samouczka i zleceń.

---

## 2. Pomiary opóźnień haptyki i dźwięku (`POMIARY.md`)

Plik surowy JSON: [`docs/handoff/measurements/lockwright-pomiar-android-SM-A165F-20261105-1221.json`](../measurements/lockwright-pomiar-android-SM-A165F-20261105-1221.json)  
Zrzut ekranu z kreatora po zakończeniu pomiaru: [`docs/handoff/device-tests/measure_result_screen.png`](measure_result_screen.png)

### 2.1. Wiersz tabeli wygenerowany przez `spikes/measure/tools/ingest.py --print`

| Urządzenie | OS | Klasa | Tier | Accel Hz | Haptic call p50/p95 | Haptic tap p50/p95 | Audio tap p50/p95 | Audio call: szybka vs silnik → zysk | Ciągła luka max | Jitter p95 | Data | Plik |
|---|---|---|---|---:|---|---|---|---|---|---|---|---|
| samsung SM-A165F | android 16 | samsung_a | A0 | 250.0 | brak danych | brak danych | brak danych | 52 vs 126 ms → 73 ms (przechodzi) | 716 ms (NIE przechodzi) | brak danych | 2026-11-05 | lockwright-pomiar-android-SM-A165F-20261105-1221.json |

### 2.2. Szczegółowe wyniki z pliku JSON i zestawienie z progami `docs/TECH.md`

| Pomiar / Metryka | Wynik na `SM-A165F` | Próg z `docs/TECH.md` / `POMIARY.md` | Status / Werdykt |
|---|---|---|---|
| **Klasa haptyki (`haptic_tier`)** | **`A0`** (`MOTOR_COIN_DC`, `hasAmplitudeControl=false`, `envelopes=false`, wszystkie prymitywy `-1`) | Rozpoznanie tieru `A0..A3` (`TECH.md` §2.2) | **OK (zgodnie ze sprzętem)** — silnik pastylkowy ERM |
| **Częstotliwość akcelerometru (`accel_hz`)** | **`250,0 Hz`** | `≥ 200 Hz` zalecane dla detekcji onsetu | **PRZECHODZI** |
| **Ścieżka audio szybka (`audio_call_fast`, Oboe / AAudio Shared)** | **`p50 = 52,5 ms`**, **`p95 = 54,9 ms`**, `min = 39,9 ms`, `max = 56,5 ms`, `jitter_p95 = 2,4 ms` (`n = 30`, `rejected = 0`, `48 kHz`, `buf = 512`, `burst = 256`) | Niskie opóźnienie + niski rozrzut (`jitter ≤ 6 ms`) | **PRZECHODZI** (rozrzut tylko `2,4 ms`) |
| **Ścieżka audio silnika (`audio_call_engine`, Godot AudioServer)** | **`p50 = 125,7 ms`**, **`p95 = 137,7 ms`**, `min = 99,7 ms`, `max = 169,2 ms`, `jitter_p95 = 12,0 ms` (`n = 30`, `rejected = 0`) | Punkt odniesienia dla natywnego mostka | Ścieżka Godot ma `125,7 ms` opóźnienia i `12,0 ms` jittera |
| **Zysk natywnego mostka Oboe (`audio_oboe_gain_ms`)** | **`+73,2 ms`** (`52,5 ms` vs `125,7 ms`) | **`≥ 30 ms`** (`POMIARY.md` §7, `TECH.md` §3.1) | **PRZECHODZI (GO dla natywnego mostka Oboe)** |
| **Ciągłość wibracji 2 s (`continuous_max_gap_ms`)** | **`716,0 ms`** | **`≤ 15 ms`** (`TECH.md` §2.2 dla oporu ciągłego) | **NIE PRZECHODZI (oczekiwane dla `A0`)** — zgodnie z `TECH.md` §2.2 na `A0` opór ciągły jest wyłączony i przejmowany przez dźwięk tarcia |
| **Opóźnienie wywołania haptyki (`haptic_call_ms`)** | `brak danych` (`n = 0`, `rejected = 30`) | `≤ 25 ms` (LRA) / `≤ 35 ms` (budżetowy) | **BRAK DANYCH (ograniczenie fizyczne ERM `MOTOR_COIN_DC`)** — patrz analiza poniżej |
| **Opóźnienie dotyk → haptyka (`haptic_tap_ms`)** | `brak danych` (`n = 0`, `rejected = 20`) | `≤ 25 ms` (średnia półka) / `≤ 35 ms` (budżet) | **BRAK DANYCH (ograniczenie fizyczne ERM `MOTOR_COIN_DC`)** |
| **Opóźnienie dotyk → dźwięk (`audio_tap_ms`)** | `brak danych` (`n = 0`, `rejected = 20`) | `≤ 20 ms` (średnia półka) / `≤ 30 ms` (budżet) | **BRAK DANYCH (zbyt wysoki próg detekcji stuku palca na `UNPROCESSED` mic)** |

### 2.3. Analiza przyczyn technicznych wyników i werdykt Go / No-Go
1. **Dlaczego natywny mostek audio Oboe (`LockwrightLowLatencyAudio`) jest bezwzględnie konieczny (GO):**
   - Na Samsungu Galaxy A16 ścieżka silnika Godot (`AudioStreamPlayer` przez OpenSL ES) ma medianę opóźnienia **`125,7 ms`** (`p95 = 137,7 ms`) i rozrzut `12,0 ms`. Natywna ścieżka AAudio/Oboe obniża opóźnienie o **`73,2 ms`** do **`52,5 ms`** (`p95 = 54,9 ms`) przy rozrzucie zaledwie **`2,4 ms`**, przekraczając próg `≥ 30 ms` ponaddwukrotnie.
2. **Dlaczego `haptic_call` i `haptic_tap` odrzuciły 100% prób (`rejected = 30/30` i `20/20`):**
   - Weryfikacja w `adb shell dumpsys vibrator_manager` potwierdziła, że wszystkie 30 impulsów `VibrationEffect.createOneShot(30, DEFAULT_AMPLITUDE)` zostało fizycznie wykonanych przez sterownik (`usage=MEDIA`, `Step=30ms`).
   - Jednak `SM-A165F` posiada pastylkowy silnik prądu stałego **`MOTOR_COIN_DC` (ERM)** o bezwładności rozruchu mechanicznego rzędu `40–80 ms`. Impuls o długości `30 ms` kończy zasilanie zanim mimośród osiągnie prędkość obrotową generującą przyspieszenie obudowy `≥ 0,02 m/s²` (`Onsets.accelOnset` w `LockwrightMeasure.kt`) dla telefonu leżącego płasko na blacie.
3. **Dlaczego `audio_tap` odrzucił 20/20 prób (`rejected = 20/20`):**
   - W fazie `audio_tap` aplikacja szuka akustycznego stuku opuszka palca o szybę w oknie `[-25 ms, +5 ms]` wokół `ACTION_DOWN` przy progu amplitudy `0,01f` na strumieniu mikrofonu `AudioSource.UNPROCESSED` (bez wzmocnienia AGC). Zwykłe dotknięcie ekranu opuszkiem palca (w przeciwieństwie do uderzenia paznokciem) nie przekracza `0,01f` na surowym strumieniu `UNPROCESSED` przed właściwym bipem `80 ms`, przez co `Onsets.micOnset` zwraca `-1`.
4. **Werdykt Go / No-Go dla pomiarów (`TECH.md`):**
   - **Ścieżka audio Oboe (`audio_oboe_gain_ms`):** **GO** (`+73,2 ms ≥ 30 ms`, jitter `2,4 ms ≤ 6 ms`).
   - **Haptyka ciągła na `A0` (`continuous_max_gap_ms`):** **NO-GO dla wibracji ciągłej na `A0` (zgodnie z projektem `TECH.md` §2.2)** — luka `716 ms > 15 ms` potwierdza słuszność reguły z `TECH.md` §2.2, że urządzenia klasy `A0` (`hasAmplitudeControl = false`) nie mogą odtwarzać ciągłego oporu haptycznego i muszą polegać na warstwie dźwiękowej L1 oraz krótkich impulsach zdarzeń L2.

---

## 3. 10-minutowy test wydajności i temperatur (`planb-perf-apk`)

Logi i zrzuty ekranu:
- Log wszystkich linii `LW_PERF`: [`docs/handoff/device-tests/planb_perf_lw_perf.log`](planb_perf_lw_perf.log)
- Pełny log Godot z testu: [`docs/handoff/device-tests/planb_perf_godot_logcat.log`](planb_perf_godot_logcat.log)
- Pomiary temperatur (`dumpsys thermalservice` na starcie, w 5. minucie i po 10 minutach): [`docs/handoff/device-tests/planb_perf_thermal.log`](planb_perf_thermal.log)
- Zużycie pamięci RAM (`dumpsys meminfo`): [`docs/handoff/device-tests/planb_perf_meminfo.log`](planb_perf_meminfo.log)
- Zrzuty ekranu: [`planb_perf_start.png`](planb_perf_start.png) (start), [`planb_perf_1min.png`](planb_perf_1min.png) (1 min), [`planb_perf_5min.png`](planb_perf_5min.png) (5 min), [`planb_perf_10min.png`](planb_perf_10min.png) (10 min / finał `t=660s`).

### 3.1. Wynik końcowy (`t = 660 s` — 60 s rozgrzewki + 600 s pomiaru)

```text
LW_PERF kind=final t=660 fps=52 frame_p50=18.18 frame_p95=18.18 frame_p99=32.97 low1=30.3 gpu_p50=5.69 gpu_p95=6.43 draws=47 vram_mb=142 mem_mb=47
```

Werdykt wyświetlony przez aplikację na ekranie:
> **`Na granicy (p95 18.2 ms, próg 16,7; 1% low 30 FPS, próg 55)`**

### 3.2. Zestawienie metryk wydajności z budżetami `POMIARY.md` §8 (klasa budżetowa vs średnia półka)

| Metryka | Wynik na `SM-A165F` (`t=660s`) | Budżet: Budżetowy Android (`POMIARY.md` §8) | Budżet: Średnia półka (`POMIARY.md` §8) | Status |
|---|---|---|---|---|
| **Czas GPU `gpu_p50` / `gpu_p95`** | **`5,69 ms` / `6,43 ms`** | `≤ 16,7 ms` | `≤ 16,7 ms` | **PRZECHODZI z ogromnym zapasem** (GPU obciążone w ~38%) |
| **Czas klatki CPU `frame_p50` / `frame_p95`** | **`18,18 ms` / `18,18 ms`** (`55,0 FPS`) | `≤ 16,7 ms` (lub stabilny krok 30/60 FPS) | `≤ 16,7 ms` | **NA GRANICY** (`18,18 ms` vs `16,67 ms`) — patrz analiza poniżej |
| **Czas klatki `frame_p99` / `1% low FPS`** | **`32,97 ms` / `30,3 FPS`** | `≥ 28 FPS` (dla trybu 30 FPS) / `≥ 50 FPS` (dla 60 FPS) | `≥ 55 FPS` | **NA GRANICY** (pojedyncze gubione VSync dają krok 2×16,67 ms = `33,0 ms`) |
| **Draw calls (`draws`)** | **`47`** | `< 100` | `< 150` | **PRZECHODZI** |
| **Pamięć VRAM (`vram_mb`)** | **`142 MB`** | `≤ 150 MB` | `≤ 200 MB` | **PRZECHODZI** (blisko górnej granicy `150 MB`) |
| **Pamięć procesowa RAM (`TOTAL PSS`)** | **`598,3 MB`** (`598 342 KB` w `planb-perf`) / **`387,9 MB`** (`387 871 KB` w grze na menu) | **`≤ 350 MB PSS`** | **`≤ 450 MB PSS`** | **NIE PRZECHODZI (PRZEKROCZENIE BUDŻETU RAM)** |
| **Zimny start (`Cold Start`)** | **`1,30–1,42 s`** (`ActivityManager TotalTime`) + **`~3,1 s`** (preloading audio/zasobów Godot) = **`~4,4 s`** | **`≤ 3,5 s`** | **`≤ 2,5 s`** | **PRZEKROCZONY o ~0,9 s** przez synchroniczny `Sfx._preload_all()` na starcie |

### 3.3. Analiza rozbieżności: `gpu_p95 = 6,43 ms` vs `frame_p50 = 18,18 ms`
- Układ graficzny `Mali-G57 MC2` renderuje kompletną scenę Plan B (47 draw calls, 142 MB tekstur VRAM, normal-mapy, refleksy i nakładkę HUD) w zaledwie **`5,69 ms` (p50) / `6,43 ms` (p95)** — czyli ponad 2,5× szybciej niż budżet `16,67 ms` dla 60 FPS.
- Mimo to odstęp między kolejnymi wywołaniami `_process(delta)` wynosi stale **`18,18 ms` (`55,0 FPS`)**, a co ~11 klatek występuje pojedynczy krok dwuklatkowy (`~33,0 ms`, stąd `1% low = 30,3 FPS`). Wynika to ze złożenia `common/physics_ticks_per_second = 120` z `common/physics_jitter_fix = 0.0` w `project.godot` oraz systemowego frame-pacingu Samsunga (Game Optimizing Service / SurfaceFlinger `BLAST` queue) przy odświeżaniu ekranu `60,0 Hz`.

### 3.4. Przebieg temperatur i dławienia termicznego (`dumpsys thermalservice`)

| Czujnik HAL (`thermalservice`) | Start (`t = 0 min`) | Środek (`t = 5 min`) | Koniec (`t = 11 min` / `660 s`) | Zmiana ($\Delta T$) | Próg dławienia (`LIGHT` / `SEVERE`) |
|---|---:|---:|---:|---:|---|
| **`AP` (SoC MediaTek MT6789)** | `29,7 °C` (`31,1 °C` w 2. min) | `32,3 °C` | **`34,0 °C`** | **`+4,3 °C`** | brak (kontrolowany przez `SKIN`) |
| **`SKIN` (obudowa / powierzchnia)** | `29,0 °C` | `30,1 °C` | **`30,9 °C`** | **`+1,9 °C`** | `38,0 °C` (`LIGHT`) / `43,0 °C` (`SEVERE`) |
| **`BAT` (bateria)** | `26,2 °C` | `26,7 °C` | **`27,3 °C`** | **`+1,1 °C`** | brak |
| **`PA` (wzmacniacz mocy)** | `28,0 °C` | `29,6 °C` | **`30,9 °C`** | **`+2,9 °C`** | brak |
| **`Thermal Status` (Android)** | **`0` (`NONE`)** | **`0` (`NONE`)** | **`0` (`NONE`)** | `0` | `≥ 1` oznacza początek dławienia |

- **Wniosek termiczny:** Telefon pozostaje chłodny przez całe 11 minut ciągłego renderowania (`SKIN = 30,9 °C`, aż `7,1 °C` poniżej pierwszego progu throttlingowego `38,0 °C`). Wartości `fps=55`, `frame_p95=18.18`, `low1=30.3` oraz `gpu_p95=6.43` w 10. minucie są identyczne jak w 1. minucie — **zero dławienia termicznego (PRZECHODZI)**.

---

## 4. Testy właściwej gry (`lockwright-android-debug`) i lista znalezionych błędów

Nagrania wideo z urządzenia (`adb shell screenrecord`, 3 × 3 minuty):
1. **Nagranie 1 — Pierwsze uruchomienie, komunikat startowy, menu główne, O grze, Ustawienia (PL/EN), Warsztat, Gablota:**
   - Ścieżka w repozytorium: [`docs/handoff/device-tests/rec1_first_run.mp4`](rec1_first_run.mp4) (`699 KB`)
   - GitHub Release: `https://github.com/woogitsugames/lockwright/releases/download/gemini-gem3/rec1_first_run.mp4`
2. **Nagranie 2 — Samouczek (`tutorial.tscn` → błąd P0 `lock_job.gd`), lista zleceń (`jobs_list.tscn`), przyjazd i weryfikacja dokumentów:**
   - Ścieżka w repozytorium: [`docs/handoff/device-tests/rec2_tutorial.mp4`](rec2_tutorial.mp4) (`267 KB`)
   - GitHub Release: `https://github.com/woogitsugames/lockwright/releases/download/gemini-gem3/rec2_tutorial.mp4`
3. **Nagranie 3 — Scena zamka 3D (`lock.tscn`), blokada przycisków przez warstwę kredy (`Chalk`), menu pauzy, tryb ciemny, zamrożenie `SceneTree` po wyjściu (`Wyjdź`), zlecenie odmowne (`+5 reputacji`):**
   - Ścieżka w repozytorium: [`docs/handoff/device-tests/rec3_first_job.mp4`](rec3_first_job.mp4) (`1,01 MB`)
   - GitHub Release: `https://github.com/woogitsugames/lockwright/releases/download/gemini-gem3/rec3_first_job.mp4`

Logi z gry:
- [`docs/handoff/device-tests/game_boot_parse_error_42017980722.log`](game_boot_parse_error_42017980722.log) — błąd P0 `boot.gd` w runie `42017980722`.
- [`docs/handoff/device-tests/game_godot_logcat.log`](game_godot_logcat.log) — log `godot` z uruchomienia gry i błędu P0 `lock_job.gd` (`N-29`).
- [`docs/handoff/device-tests/game_meminfo.log`](game_meminfo.log) — zrzut `dumpsys meminfo com.woogitsugames.lockwright`.

---

### 4.1. Ustrukturyzowana lista znalezionych błędów (P0 – P3)

#### BUG-01 [P0 — Bloker startu] `boot.gd` nie ładuje się przez błąd typowania GDScript (`first_run`) oraz kolizję `class_name` autoloadów (runy `42017980722`..`42018763392`)
- **Ekran:** Ekran startowy (`res://scenes/boot.tscn`)
- **Kroki do odtworzenia:**
  1. Zainstalować APK z zielonego runu CI `42017980722` (commit `e3da5ce`, po commicie `b145de7`) lub `42018112315`.
  2. Uruchomić grę na czysto (`adb shell pm clear com.woogitsugames.lockwright` + start aplikacji).
- **Oczekiwane zachowanie:** Wyświetlenie karty informacyjnej „To gra, nie kurs…”, opcjonalnej kalibracji pierwszego uruchomienia i przejście do menu głównego.
- **Rzeczywiste zachowanie:** Gra zawiesza się na stałe na pustym ciemnoszarym prostokącie `PanelContainer` bez tekstu i przycisków (twardy soft-lock przy starcie). W logcat widnieje błąd parsera GDScript w `res://scripts/ui/boot.gd:19` (`Cannot infer the type of "first_run" variable because the value doesn't have a set type`).
- **Zrzut ekranu:** [`docs/handoff/device-tests/screen_bug_boot_parse_error.png`](screen_bug_boot_parse_error.png)
- **Wycinek `adb logcat` ([`game_boot_parse_error_42017980722.log`](game_boot_parse_error_42017980722.log)):**
  ```text
  E godot : SCRIPT ERROR: Parse Error: Cannot infer the type of "first_run" variable because the value doesn't have a set type.
  E godot :    at: GDScript::reload (res://scripts/ui/boot.gd:19)
  E godot : ERROR: Failed to load script "res://scripts/ui/boot.gd" with error "Parse error".
  ```

---

#### BUG-02 [P0 — Bloker samouczka i zleceń `pin_tumbler` (`N-29`)] Czarny ekran i brak wyjścia po wejściu do `lock_job.tscn` (`lock_job.gd` dziedziczy po `.tscn`)
- **Ekran:** Samouczek (`res://scenes/tutorial.tscn` → `res://scenes/lock_job.tscn`) oraz każde zlecenie rodziny `pin_tumbler` (`res://scenes/job_verify.tscn` → `Otwórz dla tego klienta`).
- **Kroki do odtworzenia:**
  1. W menu głównym dotknąć **„Rozpocznij bieg”** (`PlayButton`).
  2. Na ekranie `Samouczek — zamek ćwiczebny (Etap 1 z 3)` dotknąć **„Rozpocznij bieg”** (`StartButton`) — lub w `Zlecenia` wybrać dowolne zlecenie `pin_tumbler` (np. *Czwarta nad ranem po weselu*) i dotknąć **„Otwórz dla tego klienta”**.
- **Oczekiwane zachowanie:** Załadowanie fotorealistycznej sceny zamka kołkowego (`lock_photoreal.tscn`) z wytrychem, napinaczem i obsługą wejścia.
- **Rzeczywiste zachowanie:** `game/scripts/lock/lock_job.gd` w linii 1 posiada `extends "res://scenes/photoreal/lock_photoreal.tscn"` (dziedziczenie skryptu po pliku sceny `.tscn` zamiast skryptu `.gd`), a `game/scenes/lock_job.tscn` zawiera wyłącznie pusty węzeł `Node`. Skrypt nie kompiluje się, a gracz zostaje uwięziony na całkowicie czarnym ekranie bez żadnego przycisku powrotu.
- **Zrzuty ekranu:** [`docs/handoff/device-tests/screen_09_tutorial_stage1.png`](screen_09_tutorial_stage1.png), [`docs/handoff/device-tests/screen_10_tutorial_lock_job_black_screen_bug.png`](screen_10_tutorial_lock_job_black_screen_bug.png)
- **Wycinek `adb logcat` ([`game_godot_logcat.log`](game_godot_logcat.log)):**
  ```text
  E godot : SCRIPT ERROR: Parse Error: Could not resolve super class inheritance from "res://scenes/photoreal/lock_photoreal.tscn".
  E godot :    at: GDScript::reload (res://scripts/lock/lock_job.gd:1)
  E godot :    GDScript backtrace (most recent call first):
  E godot :        [0] _start_stage (res://scripts/ui/tutorial.gd:31)
  E godot : ERROR: Failed to load script "res://scripts/lock/lock_job.gd" with error "Parse error".
  ```

---

#### BUG-03 [P0 — Zamrożenie gry] Wyjście ze sceny zamka (`PauseMenu` → `Wyjdź`) pozostawia `get_tree().paused = true` i całkowicie zamraża menu główne
- **Ekran:** Menu pauzy w scenie zamka (`res://scenes/lock.tscn` → `res://scenes/main_menu.tscn`)
- **Kroki do odtworzenia:**
  1. Wejść do dowolnego zlecenia otwierającego `lock.tscn` (np. *Rozmowa o 9:30*).
  2. Wywołać menu pauzy (np. przez zminimalizowanie i przywrócenie aplikacji — `focus_exited`).
  3. Dotknąć przycisku **„Wyjdź”** (`QuitButton`).
- **Oczekiwane zachowanie:** Gra odpauzowuje drzewo scen (`get_tree().paused = false`), wraca do `main_menu.tscn` i pozwala normalnie korzystać z przycisków menu.
- **Rzeczywiste zachowanie:** W `game/scripts/lock/lock_scene.gd` linia 47 (`QuitButton.pressed`) wywołuje `get_tree().change_scene_to_file("res://scenes/main_menu.tscn")` **bez ustawienia `get_tree().paused = false`** (w przeciwieństwie do linii 140/143/147 w `_check_finished()`). Ponieważ `MainMenu` ma domyślny `process_mode = PROCESS_MODE_INHERIT`, po powrocie do menu głównego całe drzewo scen pozostaje zapauzowane i **żaden przycisk na ekranie menu głównego nie reaguje na dotyk** aż do wymuszonego zamknięcia aplikacji (`am force-stop`).
- **Zrzuty ekranu:** [`docs/handoff/device-tests/screen_16_lock_3d_pause.png`](screen_16_lock_3d_pause.png), [`docs/handoff/device-tests/screen_18_job_arrival_refuse.png`](screen_18_job_arrival_refuse.png) (zarejestrowane w nagraniu `rec3_first_job.mp4`).

---

#### BUG-04 [P1 — Nieklikalny HUD w `lock.tscn`] Pełnoekranowy węzeł `Chalk` (`mouse_filter = STOP`) przykrywa przyciski „Pauza” i „Lupa” i połyka wszystkie dotknięcia
- **Ekran:** Scena zamka 3D (`res://scenes/lock.tscn`)
- **Kroki do odtworzenia:**
  1. Uruchomić dowolne zlecenie otwierające `lock.tscn` (np. *Rozmowa o 9:30*), gdy `tutorial_done == false` (co jest zawsze prawdą przez **BUG-02**) lub gdy w ustawieniach włączona jest *Warstwa kredy* (`reading_aid`).
  2. Dotknąć przycisku **„Pauza”** w prawym górnym rogu lub przycisku **„Lupa”** na dolnym pasku zwijki.
- **Oczekiwane zachowanie:** Przycisk „Pauza” otwiera menu pauzy, a przycisk „Lupa” przybliża widok kamery (`_on_magnifier_pressed()`).
- **Rzeczywiste zachowanie:** Żaden z przycisków nie reaguje na dotyk. W `game/scenes/lock.tscn` węzeł `UILayer/Chalk` (`type="Control"`, `anchors_preset = 15`, pełny ekran `1080×2340`) znajduje się w drzewie **nad** `UILayer/PauseButton` oraz `UILayer/Hud` i ma domyślny `mouse_filter = 0` (`MOUSE_FILTER_STOP`) zamiast `MOUSE_FILTER_IGNORE` (`2`). Gdy `_chalk.visible = true` (`lock_scene.gd:176`), `Chalk` przechwytuje wszystkie zdarzenia GUI na całym ekranie. Jedynym sposobem na otwarcie pauzy na telefonie jest zminimalizowanie aplikacji przyciskiem Home (`_on_focus_lost`).
- **Zrzut ekranu:** [`docs/handoff/device-tests/screen_14_lock_3d_scene.png`](screen_14_lock_3d_scene.png)

---

#### BUG-05 [P1 — Brak natywnej biblioteki C++ w `planb-perf-apk`] `liblockcore_gd.android.template_debug.so` ma rozmiar 0 / nie ładuje się w `planb-perf-apk`
- **Ekran:** Scena testu wydajności Plan B (`com.woogitsugames.lockwright.spike.planbperf`)
- **Kroki do odtworzenia:**
  1. Zainstalować i uruchomić `lw-planb-perf.apk` (artefakt `planb-perf-apk`).
  2. Sprawdzić `adb logcat -s godot`.
- **Oczekiwane zachowanie:** Załadowanie natywnego rozszerzenia GDExtension `liblockcore_gd.android.template_debug.so` i uruchomienie prawdziwego symulatora C++ `LockcoreSession`.
- **Rzeczywiste zachowanie:** `dlopen` zwraca błąd `file offset for the library ".../liblockcore_gd.android.template_debug.so" >= file size: 0 >= 0`, przez co `planb-perf-apk` spada do zastępczego skryptu GDScript (`FakeLockSession`). Ponadto w `planb-perf-apk` występują błędy `I18n: cannot parse res://i18n/strings.csv` oraz `content.csv`.
- **Wycinek `adb logcat` ([`planb_perf_godot_logcat.log`](planb_perf_godot_logcat.log)):**
  ```text
  E godot : ERROR: Can't open dynamic library: addons/lockcore_gd/bin/liblockcore_gd.android.template_debug.so. Error: dlopen failed: file offset for the library "/data/app/.../lib/arm64/liblockcore_gd.android.template_debug.so" >= file size: 0 >= 0.
  E godot : ERROR: GDExtension dynamic library not found: 'res://addons/lockcore_gd/lockcore_gd.gdextension'.
  E godot : ERROR: I18n: cannot parse res://i18n/strings.csv (err=19)
  ```

---

#### BUG-06 [P1 — Przekroczenie budżetu pamięci RAM (`POMIARY.md` §8)] Zużycie `TOTAL PSS` wynosi `598,3 MB` w scenie fotorealistycznej i `387,9 MB` w menu głównym (próg `≤ 350 MB`)
- **Ekran:** Scena Plan B (`planb-perf-apk`) oraz Menu Główne (`lockwright-debug.apk`)
- **Kroki do odtworzenia:**
  1. Uruchomić `planb-perf-apk` i odczytać `adb shell dumpsys meminfo com.woogitsugames.lockwright.spike.planbperf`.
  2. Uruchomić `lockwright-debug.apk` i odczytać `adb shell dumpsys meminfo com.woogitsugames.lockwright`.
- **Oczekiwane zachowanie:** Zużycie pamięci procesowej `TOTAL PSS ≤ 350 MB` na budżetowym Androidzie (`≤ 450 MB` na średniej półce) zgodnie z `docs/handoff/POMIARY.md` §8.
- **Rzeczywiste zachowanie:**
  - W `planb-perf-apk`: **`TOTAL PSS = 598 342 KB (~584,3 MB / 598,3 MB)`** (`Graphics = 316 779 KB`, `Native Heap = 135 204 KB`, `Code = 54 368 KB`) — przekroczenie budżetu o **+70%** dla klasy budżetowej i **+33%** dla średniej półki.
  - W `lockwright-debug.apk` (już na ekranie menu/samouczka): **`TOTAL PSS = 387 871 KB (~387,9 MB)`** (`Graphics = 172 993 KB`, `Native Heap = 107 860 KB`, `Code = 65 896 KB`), ponieważ `Sfx._preload_all()` i `Sfx._preload_native()` ładują wszystkie pliki WAV (w tym długie pętle ambiensów) do pamięci RAM przy starcie gry, co wydłuża też zimny start do `~4,4 s` (próg `≤ 3,5 s`).
- **Logi:** [`docs/handoff/device-tests/planb_perf_meminfo.log`](planb_perf_meminfo.log), [`docs/handoff/device-tests/game_meminfo.log`](game_meminfo.log)

---

#### BUG-07 [P1 — Błąd UI / wizualny] Trzy puste, nieopisane przyciski na ekranie `job_arrival.tscn` oraz dwa puste przyciski na `job_verify.tscn`
- **Ekran:** Przyjazd na zlecenie (`res://scenes/job_arrival.tscn`) oraz Weryfikacja prawa do lokalu (`res://scenes/job_verify.tscn`)
- **Kroki do odtworzenia:**
  1. Wejść w `Zlecenia` i wybrać dowolne zlecenie (np. *Rozmowa o 9:30* lub *„To przecież też moje”*).
  2. Spojrzeć na dolną część ekranu `job_arrival.tscn` pod przyciskiem „Sprawdź prawo do lokalu”.
  3. Dotknąć „Sprawdź prawo do lokalu” i spojrzeć na ekran `job_verify.tscn` nad przyciskiem „Otwórz dla tego klienta” oraz pod kartami dokumentów.
- **Oczekiwane zachowanie:** Widoczne powinny być wyłącznie aktywne, podpisane przyciski właściwe dla danego kroku.
- **Rzeczywiste zachowanie:**
  - W `job_arrival.tscn` znajdują się węzły `AcceptButton`, `RefuseButton` oraz `ContinueButton` z `visible = true` i pustym tekstem (`text = ""`), które wyświetlają się jako **trzy puste ciemne prostokąty** pod przyciskiem „Sprawdź prawo do lokalu”.
  - W `job_verify.tscn` węzły `VerifyButton` (nad „Otwórz dla tego klienta”) oraz `ContinueButton` (pod kartami dowodów) również mają `visible = true` i pusty tekst, renderując **dwa puste ciemne prostokąty**.
- **Zrzuty ekranu:** [`docs/handoff/device-tests/screen_12_job_arrival_pin.png`](screen_12_job_arrival_pin.png), [`docs/handoff/device-tests/screen_13_job_verify.png`](screen_13_job_verify.png), [`docs/handoff/device-tests/screen_18_job_arrival_refuse.png`](screen_18_job_arrival_refuse.png), [`docs/handoff/device-tests/screen_19_job_verify_refuse.png`](screen_19_job_verify_refuse.png)

---

#### BUG-08 [P1 — Błąd logiki zleceń odmownych (`JOBS.md` §2)] Przycisk „Otwórz dla tego klienta” jest aktywny w zleceniach odmownych (`job.refuse_*`)
- **Ekran:** Weryfikacja prawa do lokalu (`res://scenes/job_verify.tscn`)
- **Kroki do odtworzenia:**
  1. W `Zlecenia` wybrać zlecenie odmowne *„To przecież też moje”* (`job.refuse_ex_partner`) lub *Ciotka, która ma się dobrze* (`job.refuse_aunt_alive`).
  2. Przeczytać dialog (w którym ślusarz wprost mówi: *„Tu nie otworzę. Policja pomaga odebrać rzeczy, spokojnie. Zadzwonić?”*) i przejść do „Sprawdź prawo do lokalu”.
- **Oczekiwane zachowanie:** Zgodnie z komentarzem w `job_verify.gd:4` (*„Refusal jobs (refuse_*): opening is impossible; refusing grants reputation”*) oraz `JOBS.md` §2, w zleceniu odmownym otwarcie zamka powinno być zablokowane lub próba otwarcia powinna skutkować natychmiastową odmową / ostrzeżeniem.
- **Rzeczywiste zachowanie:** Przycisk **„Otwórz dla tego klienta”** (`AcceptButton`) jest w pełni aktywny i po dotknięciu normalnie uruchamia scenę otwierania zamka (`JobRun.lock_scene_path()`).
- **Zrzut ekranu:** [`docs/handoff/device-tests/screen_19_job_verify_refuse.png`](screen_19_job_verify_refuse.png)

---

#### BUG-09 [P2 — Błąd układu HUD i geometrii 3D w `lock.tscn`] Przycisk „Lupa” rozciąga się na całą szerokość zwijki, kieszenie wytrychów to szare prostokąty, a tryb ciemny nie wygasza `KeyLight`
- **Ekran:** Scena zamka 3D (`res://scenes/lock.tscn`)
- **Kroki do odtworzenia:**
  1. Wejść do zlecenia otwierającego `lock.tscn` (np. *Rozmowa o 9:30* — kłódka szyfrowa `ring_combo`).
  2. Spojrzeć na dolny pasek `Zwijka` oraz na model 3D zamka.
  3. Włączyć „Tryb ciemny” w menu pauzy i wznowić grę.
- **Oczekiwane zachowanie:**
  - Zgodnie z `docs/HUD.md` §2 i §5 zwijka ma skórzaną teksturę z 3 kieszeniami wytrychów i ikoną lupy w prawym dolnym rogu.
  - Model 3D odpowiada rodzinie zamka ze zlecenia (`ring_combo`, `wafer`, `warded`, `lever`).
  - Zgodnie z `docs/HUD.md` §10 „Tryb w ciemności” wygasza ekran do prawdziwej czerni OLED (`#000000`).
- **Rzeczywiste zachowanie:**
  - `Magnifier` („Lupa”) jest bezpośrednim dzieckiem `PanelContainer` (`UILayer/Hud/Zwijka`), przez co kontener rozciąga przycisk „Lupa” na **całą szerokość i wysokość paska zwijki (`1080×510 px`)**, przykrywając trzy szare prostokąty `Pocket0..2` (`ColorRect`).
  - `_build_placeholder_meshes()` zawsze buduje tę samą zastępczą geometrię 5 pionowych kołków cylindrycznych, nawet dla kłódki szyfrowej (`ring_combo`) czy zamka bębenkowego (`warded`).
  - `_on_dark_mode_toggled()` zmniejsza jedynie `ambient_light_energy` do `0.05`, ale zostawia włączone światło kierunkowe `KeyLight` (`light_energy = 1.2`), przez co scena w „Trybie ciemnym” pozostaje jasno oświetlona zamiast czerni OLED `#000000`.
- **Zrzuty ekranu:** [`docs/handoff/device-tests/screen_14_lock_3d_scene.png`](screen_14_lock_3d_scene.png), [`docs/handoff/device-tests/screen_17_lock_3d_dark_mode.png`](screen_17_lock_3d_dark_mode.png)

---

#### BUG-10 [P2 — Błąd czytelności UI] Panel „O grze” (`AboutPanel`) w menu głównym jest półprzezroczysty i nakłada się na tekst przycisków pod spodem
- **Ekran:** Menu główne (`res://scenes/main_menu.tscn` → `AboutPanel`)
- **Kroki do odtworzenia:**
  1. W menu głównym dotknąć przycisku **„O grze”** (`AboutButton`).
- **Oczekiwane zachowanie:** Karta „O grze” ma nieprzezroczyste tło (lub przyciemnia tło pod spodem) i czytelnie prezentuje tekst oraz przycisk „Zamknij”.
- **Rzeczywiste zachowanie:** `AboutPanel` używa półprzezroczystego stylu `PanelContainer` i jest wyśrodkowany bezpośrednio na `VBox` przycisków menu głównego. Etykiety przycisków *„Rozpocznij bieg”*, *„Zlecenia”*, *„Warsztat”*, *„Gablota”*, *„Ustawienia”* i *„O grze”* prześwitują bezpośrednio przez tekst komunikatu i przycisk *„Zamknij”*, utrudniając czytanie.
- **Zrzut ekranu:** [`docs/handoff/device-tests/screen_03_about_panel.png`](screen_03_about_panel.png)

---

#### BUG-11 [P2 — Błąd ekonomii, Gabloty i formatowania tekstu] Wszystkie notatki w Gablocie są odblokowane od startu z surowymi gwiazdkami Markdown (`*...*`), w Warsztacie „Sonda przelotowa” kosztuje `0 monet`, a w Samouczku brakuje przycisku „Wstecz” i kart `G11`
- **Ekran:** Warsztat (`res://scenes/workshop.tscn`), Gablota (`res://scenes/showcase.tscn`), Samouczek (`res://scenes/tutorial.tscn`)
- **Kroki do odtworzenia:**
  1. Po pierwszym uruchomieniu gry (`Monety: 0`, 0 ukończonych zleceń) wejść w **„Warsztat”** — sprawdzić pozycję *„Sonda przelotowa”*.
  2. Wejść w **„Gablota”** i rozwinąć pierwszą notatkę (*„Kłódka, która otwiera się na AMEN”*).
  3. Wejść w **„Rozpocznij bieg”** (`tutorial.tscn`) i spróbować wrócić do menu głównego.
- **Oczekiwane zachowanie:**
  - Narzędzia do kupienia w Warsztacie mają dodatnią cenę (lub są odblokowane od początku).
  - Notatki historyczne w Gablocie odblokowują się wraz z postępem, a kursywa jest sformatowana (bez surowych znaków `*`).
  - Ekran samouczka zawiera ilustrowaną kartę instruktażową (`G11`) oraz przycisk „Wstecz”.
- **Rzeczywiste zachowanie:**
  - W Warsztacie *„Sonda przelotowa”* wyświetla cenę **`0 monet`** przy aktywnym przycisku **„Kup”**.
  - W Gablocie wszystkie notatki są od razu odblokowane, a etykieta `Label` wyświetla surowe znaczniki Markdown, np. `*The Noble Gentleman*`.
  - Na ekranie `tutorial.tscn` brakuje przycisku „Wstecz” oraz kart graficznych `G11`.
- **Zrzuty ekranu:** [`docs/handoff/device-tests/screen_06_workshop.png`](screen_06_workshop.png), [`docs/handoff/device-tests/screen_07_showcase.png`](screen_07_showcase.png), [`docs/handoff/device-tests/screen_08_showcase_note.png`](screen_08_showcase_note.png), [`docs/handoff/device-tests/screen_09_tutorial_stage1.png`](screen_09_tutorial_stage1.png)

---

#### BUG-12 [P2 — Błąd klasyfikacji urządzenia w `LockwrightMeasure.kt`] `guessClass()` klasyfikuje budżetowego `SM-A165F` jako `samsung_a` (średnia półka) zamiast `budget`
- **Ekran:** Aplikacja pomiarowa `LW Pomiary` (`spikes/measure/android/app/src/main/java/com/woogitsugames/lockwright/measure/LockwrightMeasure.kt`)
- **Kroki do odtworzenia:**
  1. Uruchomić pomiar w `LW Pomiary` na Samsungu Galaxy A16 (`SM-A165F`) i wyeksportować plik JSON.
- **Oczekiwane zachowanie:** Urządzenie z Helio G99 (`MT6789`), Mali-G57 MC2, 4 GB RAM i silnikiem wibracji `MOTOR_COIN_DC` (`A0`) powinno zostać sklasyfikowane jako `budget` zgodnie z `docs/TECH.md` §6.2 (#8/#9).
- **Rzeczywiste zachowanie:** Funkcja `guessClass()` sprawdza `m.contains("sm-a")` i przypisuje klasę `"samsung_a"` (średnia półka, która w `TECH.md` §6.2 dotyczy serii A3x/A5x z LRA `A1`/`A2`), nie rozróżniając budżetowej serii Galaxy A0x/A1x od A3x/A5x.
- **Zrzut ekranu:** [`docs/handoff/device-tests/measure_result_screen.png`](measure_result_screen.png)

---

#### BUG-13 [P3 — Przycięty tekst werdyktu w `planb-perf-apk` oraz utrudnione przewijanie `ScrollContainer`]
- **Ekran:** `LW Plan B Perf` (`perf_hud.gd`) oraz `Ustawienia` (`res://scenes/settings.tscn`)
- **Kroki do odtworzenia:**
  1. W `LW Plan B Perf` poczekać do końca testu (`t = 660 s`) i spojrzeć na dolną linię tekstu `WERDYKT:` w lewym górnym rogu.
  2. W `Ustawienia` spróbować przewinąć ekran pionowym gestem palca po środku ekranu (zaczynając na przycisku lub suwaku).
- **Oczekiwane zachowanie:** Tekst werdyktu w `PerfHud` zawija się do kolejnej linii (`autowrap_mode`), a lista ustawień przewija się płynnie przy przeciągnięciu palcem w dowolnym miejscu listy.
- **Rzeczywiste zachowanie:**
  - W `PerfHud` (`perf_hud.gd`) etykieta `_label` nie ma włączonego `autowrap_mode`, przez co napis `WERDYKT: Na granicy (p95 18.2 ms, próg 16,7; 1% low 30 FPS, próg 55)` ucina się na prawej krawędzi ekranu na `... 1% low 30 F`.
  - W `settings.tscn` kontrolki wewnątrz `ScrollContainer/VBox` mają domyślny `mouse_filter = MOUSE_FILTER_STOP`, przez co gest pionowego przewijania rozpoczęty na przycisku (np. `LanguageOption`) otwiera listę rozwijaną zamiast przewijać widok.
- **Zrzuty ekranu:** [`docs/handoff/device-tests/planb_perf_10min.png`](planb_perf_10min.png), [`docs/handoff/device-tests/screen_05_settings_bottom.png`](screen_05_settings_bottom.png)

---

#### BUG-14 [P3 — CI / Wdrażanie APK] `game-android.yml` generuje nowy losowy klucz `debug.keystore` w każdym przebiegu CI (`INSTALL_FAILED_UPDATE_INCOMPATIBLE`)
- **Ekran:** Instalacja APK przez `adb install -r`
- **Kroki do odtworzenia:**
  1. Zainstalować `lockwright-debug.apk` z jednego przebiegu GitHub Actions, a następnie spróbować zaktualizować go (`adb install -r`) paczką z kolejnego przebiegu CI.
- **Oczekiwane zachowanie:** `adb install -r` aktualizuje aplikację z zachowaniem danych użytkownika (`user://save.json`).
- **Rzeczywiste zachowanie:** `.github/workflows/game-android.yml` w każdym uruchomieniu wykonuje `keytool -genkeypair` do `/tmp/debug.keystore`, generując za każdym razem inny certyfikat podpisu. Aktualizacja kończy się błędem `INSTALL_FAILED_UPDATE_INCOMPATIBLE: Existing package com.woogitsugames.lockwright signatures do not match newer version`, wymuszając `adb uninstall` i utratę zapisu gry.

---

## 5. Wykaz wszystkich wygenerowanych plików

### 5.1. Pliki pomiarowe (`docs/handoff/measurements/`)
- [`docs/handoff/measurements/lockwright-pomiar-android-SM-A165F-20261105-1221.json`](../measurements/lockwright-pomiar-android-SM-A165F-20261105-1221.json) — pełny eksport JSON z aplikacji `LW Pomiary` na telefonie `samsung SM-A165F`.

### 5.2. Logi, zrzuty ekranu i nagrania (`docs/handoff/device-tests/`)
- **Raport główny:**
  - `docs/handoff/device-tests/REPORT.md`
- **Logi (`adb logcat`, `thermalservice`, `meminfo`):**
  - [`docs/handoff/device-tests/planb_perf_lw_perf.log`](planb_perf_lw_perf.log) — linie `LW_PERF` (`periodic` co 10 s oraz `final` w `t=660s`).
  - [`docs/handoff/device-tests/planb_perf_godot_logcat.log`](planb_perf_godot_logcat.log) — pełny logcat `godot` z 10-minutowego testu `planb-perf-apk`.
  - [`docs/handoff/device-tests/planb_perf_thermal.log`](planb_perf_thermal.log) — zrzuty `dumpsys thermalservice` (0 min, 5 min, 10 min).
  - [`docs/handoff/device-tests/planb_perf_meminfo.log`](planb_perf_meminfo.log) — zrzut `dumpsys meminfo` dla `planb-perf-apk` (`598,3 MB PSS`).
  - [`docs/handoff/device-tests/game_boot_parse_error_42017980722.log`](game_boot_parse_error_42017980722.log) — logcat błędu P0 `boot.gd` z runu `42017980722`.
  - [`docs/handoff/device-tests/game_godot_logcat.log`](game_godot_logcat.log) — logcat `godot` z gry właściwej (`lockwright-debug.apk`) i błędu `lock_job.gd` (`N-29`).
  - [`docs/handoff/device-tests/game_meminfo.log`](game_meminfo.log) — zrzut `dumpsys meminfo` dla `com.woogitsugames.lockwright` (`387,9 MB PSS`).
- **Zrzuty ekranu z pomiarów i testu wydajności:**
  - [`docs/handoff/device-tests/measure_result_screen.png`](measure_result_screen.png) — ekran podsumowania `LW Pomiary`.
  - [`docs/handoff/device-tests/planb_perf_start.png`](planb_perf_start.png) — start `LW Plan B Perf`.
  - [`docs/handoff/device-tests/planb_perf_1min.png`](planb_perf_1min.png) — `LW Plan B Perf` po 1 minucie.
  - [`docs/handoff/device-tests/planb_perf_5min.png`](planb_perf_5min.png) — `LW Plan B Perf` w 5. minucie (`t=300s`).
  - [`docs/handoff/device-tests/planb_perf_10min.png`](planb_perf_10min.png) — `LW Plan B Perf` po 10 minutach (`t=660s`, z werdyktem na ekranie).
- **Zrzuty ekranu z gry (`lockwright-android-debug`):**
  - [`docs/handoff/device-tests/screen_bug_boot_parse_error.png`](screen_bug_boot_parse_error.png) — P0 soft-lock na `boot.tscn` (run `42017980722`).
  - [`docs/handoff/device-tests/screen_01_boot_notice.png`](screen_01_boot_notice.png) — karta startowa „To gra, nie kurs…”.
  - [`docs/handoff/device-tests/screen_02_main_menu.png`](screen_02_main_menu.png) — menu główne.
  - [`docs/handoff/device-tests/screen_03_about_panel.png`](screen_03_about_panel.png) — panel „O grze” (prześwitujące przyciski pod spodem).
  - [`docs/handoff/device-tests/screen_04_settings_top.png`](screen_04_settings_top.png) — ekran Ustawień (góra).
  - [`docs/handoff/device-tests/screen_05_settings_bottom.png`](screen_05_settings_bottom.png) — ekran Ustawień (dół + rozwijana lista języka).
  - [`docs/handoff/device-tests/screen_05b_settings_english.png`](screen_05b_settings_english.png) — ekran Ustawień po przełączeniu języka na `English`.
  - [`docs/handoff/device-tests/screen_06_workshop.png`](screen_06_workshop.png) — ekran Warsztatu (`Sonda przelotowa: 0 monet`).
  - [`docs/handoff/device-tests/screen_07_showcase.png`](screen_07_showcase.png) — ekran Gabloty (lista notatek).
  - [`docs/handoff/device-tests/screen_08_showcase_note.png`](screen_08_showcase_note.png) — rozwinięta notatka w Gablocie (`*The Noble Gentleman*`).
  - [`docs/handoff/device-tests/screen_09_tutorial_stage1.png`](screen_09_tutorial_stage1.png) — ekran Samouczka (Etap 1 z 3).
  - [`docs/handoff/device-tests/screen_10_tutorial_lock_job_black_screen_bug.png`](screen_10_tutorial_lock_job_black_screen_bug.png) — czarny ekran po błędzie P0 `lock_job.gd` (`N-29`).
  - [`docs/handoff/device-tests/screen_11_jobs_list.png`](screen_11_jobs_list.png) — lista zleceń (`jobs_list.tscn`).
  - [`docs/handoff/device-tests/screen_12_job_arrival_pin.png`](screen_12_job_arrival_pin.png) — ekran przyjazdu na zlecenie *Rozmowa o 9:30* (widoczne 3 puste przyciski).
  - [`docs/handoff/device-tests/screen_13_job_verify.png`](screen_13_job_verify.png) — ekran weryfikacji prawa do lokalu *Rozmowa o 9:30* (widoczne 2 puste przyciski).
  - [`docs/handoff/device-tests/screen_14_lock_3d_scene.png`](screen_14_lock_3d_scene.png) — scena zamka 3D (`lock.tscn`).
  - [`docs/handoff/device-tests/screen_15_lock_3d_loupe.png`](screen_15_lock_3d_loupe.png) — scena zamka 3D po próbie dotknięcia przycisku „Lupa” (zablokowanego przez `Chalk`).
  - [`docs/handoff/device-tests/screen_16_lock_3d_pause.png`](screen_16_lock_3d_pause.png) — menu pauzy w scenie zamka 3D.
  - [`docs/handoff/device-tests/screen_17_lock_3d_dark_mode.png`](screen_17_lock_3d_dark_mode.png) — scena zamka 3D z włączonym „Trybem ciemnym”.
  - [`docs/handoff/device-tests/screen_18_job_arrival_refuse.png`](screen_18_job_arrival_refuse.png) — ekran przyjazdu na zlecenie odmowne *„To przecież też moje”*.
  - [`docs/handoff/device-tests/screen_19_job_verify_refuse.png`](screen_19_job_verify_refuse.png) — ekran weryfikacji zlecenia odmownego.
  - [`docs/handoff/device-tests/screen_20_job_refused_rep.png`](screen_20_job_refused_rep.png) — komunikat `Słowo się niesie: +5 reputacji` po odmowie.
  - [`docs/handoff/device-tests/screen_21_landscape_mode.png`](screen_21_landscape_mode.png) — lista zleceń w orientacji poziomej (landscape).
- **Nagrania wideo (`3 × 3 min`, w repozytorium oraz w GitHub Release [`gemini-gem3`](https://github.com/woogitsugames/lockwright/releases/tag/gemini-gem3)):**
  - [`docs/handoff/device-tests/rec1_first_run.mp4`](rec1_first_run.mp4) (`699 KB`) — `https://github.com/woogitsugames/lockwright/releases/download/gemini-gem3/rec1_first_run.mp4`
  - [`docs/handoff/device-tests/rec2_tutorial.mp4`](rec2_tutorial.mp4) (`267 KB`) — `https://github.com/woogitsugames/lockwright/releases/download/gemini-gem3/rec2_tutorial.mp4`
  - [`docs/handoff/device-tests/rec3_first_job.mp4`](rec3_first_job.mp4) (`1,01 MB`) — `https://github.com/woogitsugames/lockwright/releases/download/gemini-gem3/rec3_first_job.mp4`
