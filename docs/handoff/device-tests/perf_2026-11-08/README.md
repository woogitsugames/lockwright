# Pomiary wydajności na telefonie — 2026-11-08 (D-87)

Telefon: **Samsung SM-A165F** (Galaxy A16 4G, Helio G99, Mali-G57 MC2, 4 GB RAM, 1080×2340, 60 Hz), Android 16,
po USB (zasilanie z USB, bateria 78–79 %). Zapis właściciela na telefonie przez cały czas (tylko `adb install -r`, bez czyszczenia danych).

| Przebieg | Build | Pliki |
|---|---|---|
| `base` | CI APK **283887e** (zainstalowany przez właściciela) | `base_frames.*`, `base_mem.txt`, `base_godot_logcat.log`, cold start `coldstart.txt` (b1–b3) |
| `probe` | lokalny build = kod 283887e/eb65f1d8 + sama sonda `PerfProbe` (bez poprawek), 13 rodzin + 10 min termiki | `probe_*` |
| `v2` | + limit staging, warsztat, płyty 1x, cache potoków, wczytywanie zamka w tle (zbudowany na fbcbc831) | `v2_*` |
| `v3` | + kliki Sfx w tle, menu wczytywane w czasie bootu | `v3_*`, cold start v3a–d |
| `v4` | wersja finalna kodu D-87 (na fbcbc831; commit różni się tylko rebase'em na 5dbe34e4: nowe płyty lever VA-09 i ich 1x), 13 rodzin, warsztat, scenka „dnia po”, `wrong_floor`, 10 min termiki | `v4_*`, cold start v4a–d |
| `v4r` | diagnostyka skoku pamięci (od `menu` do `lock_pin` z czystego startu poprawne; dalsze etykiety mogą być przesunięte o wiersz listy) | `v4r_*` |

## Metoda

- **Klatki:** `tools/local/sf_timestats.py` — histogram present→present warstwy gry z SurfaceFlinger TimeStats
  (`dumpsys gfxinfo` nie widzi powierzchni Vulkan Godota, a `--latency` jest puste na Androidzie 16). Każdy wiersz `*_frames.txt`
  to okno od poprzedniego pomiaru: FPS, p50/p95/p99/max [ms] (kubełki 1 ms do 34 ms, potem 2–4 ms, od 150 ms co 50 ms;
  „1000” = ≥ 1 s), liczba klatek > 25/33/50 ms. `x` = okno pomocnicze (pomijać). TimeStats wyłączone i wyczyszczone na końcu.
- **Pamięć:** `dumpsys meminfo` po każdym kroku (`*_mem.txt`): PSS całej aplikacji, „Graphics” (GL mtrack + EGL mtrack = pamięć GPU).
- **Sonda gry** (`game/scripts/autoload/perf_probe.gd`, tylko buildy debug): `LW_BOOT` (czas do pierwszej klatki menu i `_ready` każdego
  autoloadu), `LW_SCENE` (ostatnie puszczenie palca → pierwsza narysowana klatka nowej sceny), `LW_HITCH`, `LW_SLOW`, a z plikiem
  `files/perf_probe` także `LW_FRAMES` co 5 s (percentyle klatek, czas GPU, liczniki pamięci Godota). Linia `day_after=<id>` w tym pliku
  pokazuje scenkę „dnia po” nad listą zleceń bez zapisu do save'a (zapis właściciela nie ma kolejki „dnia po”).
- **Ścieżka:** `adb shell input` (tapnięcia w pikselach 1080×2340): menu → Zlecenia → zlecenie → „Sprawdź prawo do lokalu” → „Przyjmij
  zlecenie” → zamek: 9 s bez dotyku (`*_idle`), 18 przeciągnięć kciukami (`*_interact`) → Wstecz → „Wyjdź” → menu.
  Jedno zlecenie na rodzinę: combo „Rozmowa o 9:30”, warded „Ziemniak w łazience”, wafer „Kiosk przed szóstą”, pin „Czwarta nad ranem po
  weselu”, magnetic „Po dwunastu godzinach”, lever „Zapłata w pizzy”, egyptian „Domek pradziadka”, dial_safe „Sejf wujka Bogdana”,
  lever_detector „Piekarnia o czwartej”, dimple „Kamienica w Saint-Gilles”, axial_slider „Angielski sekretarzyk”, disc_detainer „Skrzynia
  marynarza”, time_lock „Zegar, który pilnuje skarbca”; scenka 2.5D: „Piętro niżej” (`wrong_floor`). Żadnego zamka nie otwarto
  (żadne zlecenie nie zostało zakończone); w save przybyło tylko 30 wpisów dziennika `tutorial/hint_history` (log podpowiedzi).
- **Termika:** 10 min w zamku „Sejf wujka Bogdana” (pokrętło — losowe ruchy go nie otworzą) z ciągłym przeciąganiem; co minutę klatki,
  pamięć i temperatury z HAL (`*_thermal.txt`, `*_temps.txt`).
- **Zimny start:** `am start -W` + nagranie ekranu (`cs_analyze`: od okna startowego do w pełni narysowanego menu) + `LW_BOOT`.
- **CPU:** `simpleperf` (task-clock, 10 s, zamek pin bez dotyku): wątek gry `VkThread` 56 % rdzenia, `AudioTrack` 14 %, sterownik Mali 6 %,
  haptyka 4 %; profil płaski (biblioteka Godota bez symboli), ok. 8 % to kod Javy wtyczek (aplikacja debuggable → interpreter).

## Główne wyniki (szczegóły: `table_probe_v4.md`, `python summarize.py probe v4`)

| Miara | Przed (283887e / sonda) | Po (v4) | Próg (POMIARY §8) |
|---|---|---|---|
| Zimny start → menu (nagranie, mediana) | 4,0 s (3,6–4,3) | 3,0 s (2,8–3,2); pierwszy po instalacji 3,5 s | ≤ 4 s ✔ |
| Silnik → pierwsza klatka menu (`LW_BOOT`) | 3,3 s | 2,2–2,5 s (Sfx 340 → 70 ms) | — |
| PSS menu | 417–419 MB | 402 MB | ≤ 300 MB ✘ |
| Lista zleceń: PSS / Graphics | 589 / 330 MB | 420–430 / 170 MB | ≤ 300 MB ✘ (blisko) |
| Warsztat: PSS / zacięcie przy wejściu | 1096 MB / ≥ 1 s | 610 MB (świeżo) / 0,6 s | ≤ 300 MB ✘ |
| Zamek (świeży start): PSS | 852–891 MB | 555–615 MB | ≤ 350 MB ✘ |
| Zamek: zacięcie „Przyjmij” → zamek (max klatka) | 450–1000 ms (śr. 650) | 200–650 ms (śr. 350) | — |
| Zamek w grze (dotyk): FPS, klatki > 25 ms / 18 s | 56,4–58,9, 18–46 | 58,2–60,0, 7–22 | p95 ≤ 16,7 ms ✔ |
| Zamek bez dotyku: FPS | 41–44 | 41–44 (bez zmian) | ✘ (N-33) |
| 10 min gry: FPS 1. / 10. min, klatki > 25 ms / min | 58,4 / 58,5, 104–125 | 60,4 / 60,4, 8–10 | 1 % low ≥ 55 ✔ (po) |
| Termika po 10 min (SKIN / AP, status) | 36,0 / 40,9 °C, 0 | 35,4 / 40,0 °C, 0 | brak dławienia ✔ |
| APK / zasoby (pck w APK) | 168,1 MB / 90,3 MB | 171,9 MB / 93,8 MB (+1,3 MB płyty 1x, reszta to D-84/D-86 z main) | APK ≤ 200 ✔, pck ≤ 150 ✔ |

Uwaga do pamięci: „Graphics” rośnie skokami bloków alokatora Vulkan (128/256 MB) i nie maleje, więc w długiej sesji (13 zamków po kolei)
PSS dochodzi do ~850 MB także po poprawkach (skok przy jednym wczytaniu), ale nie do 1,1 GB jak przed (warsztat).
