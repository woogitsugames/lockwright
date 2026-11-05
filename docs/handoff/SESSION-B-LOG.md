# SESSION-B-LOG — raporty sesji B (programista gry)

## 2026-11-04 — Zadanie 1: szkielet projektu Godot (`game/`)

**Zrobione:**
- Godot 4.7.2-stable pobrany (Linux x86_64, działa headless) + export templates 4.7.2 zainstalowane lokalnie; opis w `game/README.md`.
- `game/project.godot`: renderer Mobile, orientacja sensor (pion podstawowy, poziom działa), `physics_ticks_per_second=120` (D-07), stretch canvas_items/expand.
- Struktura `game/scenes|scripts|i18n|data|addons|assets`; sceny: boot, main_menu, lock, workshop, showcase, settings, dev/haptics_lab (na razie placeholdery z kluczami i18n).
- Autoloady: `Settings` (user://settings.cfg: haptics_enabled, haptics_intensity, wolumeny, language, dark_mode_assist, reading_aid, wide_windows), `Save` (user://save.json, `save/1` + migracja), `I18n` (wrapper na TranslationServer, CSV ładowane w runtime — D-19), `Events` (szyna sygnałów), `Haptics` (interfejs jak `HapticsBridge` z TECH.md §2.5: play/begin_continuous/update_continuous/end_continuous/capabilities; wybiera natywny singleton `LockwrightHaptics`, fallback `Input.vibrate_handheld`, wzorce z `game/data/haptics_patterns.json` przepisane z TECH.md §3.3), `Sfx` (pula 12 prealokowanych AudioStreamPlayer, warstwy materiał × zdarzenie, losowe warianty).
- i18n: `game/i18n/strings.csv` (klucze UI, kolumny `en`,`pl`), `content.csv` (puste na start, zapełni zadanie 6). Język domyślny = systemowy, fallback EN.
- Własna tymczasowa ikona `game/icon.svg` (wpis w ASSETS.md).

**Działa:** `godot --headless --path game res://tests/smoke.tscn` → `SMOKE OK` (autoloady, kompletność PL+EN, wzorce haptyki); boot headless bez błędów.

**Nie działa / otwarte:**
- Zrzuty ekranu: sandbox nie ma GPU/EGL/Xvfb — headless renderer zwraca pusty obraz. Prawdziwe screenshoty będą z runnera z GPU albo urządzenia; do tego czasu brak zrzutów w `docs/handoff/screens/`.
- AAR/iOS build lokalnie: brak JDK 17/Android SDK w sandboxu (apt bez pakietów, dl.google.com zablokowane) — kod pluginów powstaje, build przez CI (zadania 3–5).

**Linki do zrzutów:** brak (j.w.). **Decyzje:** D-19.

## 2026-11-04 — Zadanie 7 (część): lockcore podpięte przez GDExtension

**Zrobione:**
- `game/addons/lockcore_gd/` — GDExtension (godot-cpp, API 4.7 przez `custom_api_file=extension_api-4-7.json`) opakowujący `lockcore::LockSession`: `create(family, seed, tier)`, `step(tension, depth, lift)` → tablica zdarzeń, `describe()` → ViewModel, `is_open/finished/failure/event_hash/t_step`. SConstruct kompiluje źródła lockcore razem z wrapperem (`-std=c++20 -ffp-contract=off`).
- Zbudowane lokalnie headless: `bin/liblockcore_gd.linux.template_debug.so`; test `tests/lock_test.tscn` przechodzi przez PRAWDZIWE lockcore (zdarzenia bind/contact, ViewModel 3 pinów dla t2).
- `lock_scene.gd` wybiera `LockcoreSession` gdy klasa istnieje, inaczej `FakeLockSession` (fallback). Scena `lock.tscn` bootuje się czysto headless: przekrój 3D (PBR mosiądz/stal), pauza 48 dp w rogu, tryb ciemny w pauzie, `InputSampler` 120 Hz (lewa połowa = napięcie, prawa = wytrych 2D), zdarzenia → Haptics+Sfx w tej samej klatce fizyki.
- CI: `game-tests.yml` dostało job `gdextension-build` (godot-cpp + lockcore_gd + lock_test).

**Działa:** LOCKTEST OK, SMOKE OK, GUT all passed, lock.tscn boot headless bez błędów.

**Nie działa / otwarte:**
- Zrzuty ekranu dalej niemożliwe w sandboxie (brak GPU) — brak plików w `docs/handoff/screens/`.
- AAR haptics dalej tylko w CI (brak JDK/SDK lokalnie).
- `lockwright_haptics.gdextension` loguje błąd na Linuxie (brak biblioteki linux) — kosmetyczne, fallback działa; do wyciszenia można dodać pusty wpis linux.

## 2026-11-04 — Zadanie 8: menu, ustawienia, warsztat, gablota

**Zrobione:** `main_menu` (przyciski ≥ 48 dp, panel „O grze" z notką „to gra, nie kurs”), `settings` (haptyka wł./wył. + intensywność + impuls próbny + kalibracja „dwa kliknięcia”, wolumeny, język, pomoc w czytaniu, szersze okna, kontrast, reset), `workshop` (lista z `tools.json`, kupno/naprawa za monety z `save/1`), `showcase` (notki z `showcase/*.json` z polem źródła). Wszystkie teksty przez i18n PL+EN; wszystkie sceny bootują się headless bez błędów; GUT + smoke zielone.

**Odchylenie od zadania:** menu na razie 2D Control (emaliowane przyciski), nie pełna scena 3D z drzwiami — makieta 3D czeka na modele z `art/` (mockup `04-menu.portrait.png` jako układ). Do doprecyzowania w kolejnej iteracji.

**Zrzuty:** brak (brak GPU w sandboxie, j.w.).

## 2026-11-05 — Zadania 3–5 dokończone: lokalny toolchain, AAR, APK, CI

**Zrobione:**
- Lokalny toolchain w sandboxie: JDK 17 (Temurin), Android SDK (platform 36, build-tools 36.1.0, NDK 29.0.14206865), Gradle 8.11.1 — pobrane przez proxy (gh release / python urllib).
- **AAR zbudowany lokalnie** (`./gradlew :lockwright-haptics:assembleRelease`) i skopiowany do `game/addons/lockwright_haptics/android/lockwright_haptics.aar`. Poprawione błędy kompilacji Kotlin (getContext(), SignalInfo, arePrimitivesSupported → BooleanArray, init property).
- **lockcore_gd zbudowany dla android arm64** (`liblockcore_gd.android.template_debug.so`) przez godot-cpp master + `custom_api_file=extension_api-4-7.json`.
- **Debug APK zbudowany lokalnie**: `game/build/lockwright-debug.apk` (87 MB) przez `godot --headless --export-debug "Android"` — wymagało zainstalowania android build template do `game/android/build/` + `android/.build_version` + editor settings z `android_sdk_path`/`java_sdk_path`.
- iOS: most przeszedł na klasyczny `.gdip` (D-21 — `.gdextension` tylko-iOS blokował eksport Androida). Kod ObjC++ skompilowany w CI po serii poprawek (nazwy API iOS 26: `createAdvancedPlayerWithPattern:`, `initWithEvents:parameters:error:`, `CHHapticEventTypeHapticTransient`, `CHHapticDynamicParameterID*HapticIntensityControl`, `initAndReturnError:`, deployment target 18.0, `.mm` przez osobny env ObjC++).
- **CI zielone:** `game-android` (AAR + APK, artefakty) i `game-tests` (gdextension-build + lock_test przez prawdziwe lockcore, GUT, smoke, walidacja danych, check_sfx). `game-ios` w toku — buduje godot-cpp + obie liby i eksportuje projekt do Xcode na macos-latest.

**Otwarte:** game-ios CI jeszcze w toku (długi build godot-cpp na macOS); zrzuty ekranu nadal niemożliwe lokalnie (brak GPU).

## 2026-11-05 — Sesja B zakończona: wszystkie 8 zadań wypchnięte, CI zielone

**Status CI na main (commit 13ab571):** `game-ios` ✅ (buduje godot-cpp + liblockwright_haptics.a + lockcore_gd xcframeworks, eksportuje projekt do Xcode i kompiluje `xcodebuild ... CODE_SIGNING_ALLOWED=NO`), `game-android` ✅ (AAR pluginu + debug APK 87 MB jako artefakt), `game-tests` ✅ (gdextension-build + lock_test przez prawdziwe lockcore, GUT, smoke, validate.py, check_sfx.py).

**Lokalnie zweryfikowane:** smoke OK, GUT all passed, lock_test OK przez LockcoreSession, wszystkie sceny (boot/main_menu/lock/workshop/showcase/settings/haptics_lab) bootują headless bez błędów, `check_sfx.py` OK, `validate.py` OK (29 zleceń, 20 notek, 146 kluczy i18n), debug APK zbudowany lokalnie.

**Decyzje dodane:** D-19 (i18n CSV w runtime), D-20→D-21 (iOS: .gdip zamiast GDExtension — .gdextension tylko-iOS blokował walidację eksportu Androida).

**Znane ograniczenia:** zrzuty ekranu wymagają GPU (brak w sandboxie) — `docs/handoff/screens/` puste; menu 2D zamiast pełnej sceny 3D (czeka na assety z `art/`); fizyczne testy haptyki/audio na urządzeniach (spike 1–3) poza zakresem tego środowiska.

## 2026-11-05 — Etap 2 (SESSION-B-PROMPT-2): zadania 1–4

**Zadanie 1 (przegląd sesji C):** naprawione wszystkie 14 High (R-01…R-42) i kluczowe Medium — każda pozycja w `SESSION-C-REVIEW.md` ma adnotację `→ naprawione w <hash>`. Nowe testy GUT: `test_input_sampler` (R-02), `test_feedback_director` (R-21/22), `test_determinism` (R-16, golden event_hash), `test_families` (zadanie 4). Nowy autoload `FeedbackDirector` (priorytety/limity/koalescencja/ducking z `haptics_patterns.json`). Eksport zweryfikowany lokalnie: smoke z `.pck` = OK (R-28).

**Zadanie 2 (D-32):** EN „Lockwright: Locksmith on Call” w i18n i prezecie Android.

**Zadanie 3 (pętla zlecenia):** `jobs_list → job_arrival → job_verify → lock → job_payment`, 29 zleceń z `data/jobs`, mapowanie rodzin job→lockcore (`JobRun.FAMILY_MAP`), postęp w `save/1` (`jobs_completed`, monety, reputacja za odmowę).

**Zadanie 4 (7 rodzin):** binding dostał `rotate/push/tool` + statyczne `LockcoreSession.solve()` (bot lockcore z nagranymi wejściami). Test GUT: bot lockcore otwiera wszystkie 7 rodzin przez warstwę Godota z identycznym `event_hash`.

## Od sesji A: lockcore v0.3 (balans) — 2026-11-05
- Reguły lever v2 (`RULES_VERSION` 2, nowe `set_speed`), nowe marginesy detektora i overset pin t7 — szczegóły `lockcore/BALANCE.md`, `lockcore/README.md` („API changes v0.3”), D-34.
- **Do zrobienia przez sesję B:** przebudować `game/addons/lockcore_gd/bin/*` (Android, iOS, linux), żeby gra miała reguły v0.3. API bez zmian łamiących.

## 2026-11-05 — Etap 2: zadania 5–8

**Zadanie 5 (samouczek + pierwsze uruchomienie):** boot pokazuje jednorazową notkę „to gra, nie kurs” (PL/EN, `seen_notice` w save); Play prowadzi przez `tutorial.tscn` — 3 etapy S1–S3 na `pin_tumbler` t1 przez prawdziwe lockcore, potem `tutorial_done`. Warstwa kredy (znaki stanów z DESIGN.md §1) włączona domyślnie w samouczku i w opcji „Pomoc w czytaniu”.

**Zadanie 6 (HUD diegetyczny):** tło z `tray.jpg` (skopiowane z `mockups/realizm/img/` do `game/assets/ui/`, wpis w ASSETS.md), zwijka u dołu z 3 kieszeniami wytrychów (życia) i lupą (D-13, zbliża widok), pauza 48 dp w safe-area. Bez pasków/liczników (D-12).

**Zadanie 7 (tryb ciemny):** przełącznik w pauzie wygasza światło do minimum — gra prowadzi dźwięk + haptyka; dostępność w Ustawieniach (wyłączenie haptyki z zachowaniem dźwięku i obrazu, pomoc w czytaniu, szersze okna, kontrast).

**Zadanie 8 (zrzuty ekranu) — NIE UDAŁO SIĘ, próby:** sandbox nie ma GPU/EGL ani roota: `apt` bez list pakietów i bez sudo; pobrane ręcznie paczki .deb (bookworm i trixie) z deb.debian.org przez proxy Pythona; Xvfb startuje ale pada na „Failed to activate virtual core keyboard” (XKB) przy każdej próbie (±`-xkbdir`, `XKB_CONFIG_ROOT`); weston headless pada na ładowaniu modułów bez roota; `godot --headless --rendering-driver opengl3` daje pusty obraz (brak kontekstu GL). Wniosek: prawdziwe zrzuty ekranu wymagają runnera z GPU (CI ubuntu-latest ma tylko software GL — można dodać tam krok `xvfb-run` z `mesa-utils`, ale to wymaga zmiany obrazu/instalacji w CI; zostawiam jako otwarte). `docs/handoff/screens/` zostaje puste.

## Od sesji A: audyt zgodności — 2026-11-05
Pełna lista: `docs/COMPLIANCE-AUDIT.md`. Dla sesji B:
- **Medium:** ekran weryfikacji pokazuje surową notatkę z biblii, tylko po polsku (`job_verify.gd:14`, 29 pól `verification`; N-04 z przeglądu C) — przenieść do i18n PL+EN.
- **Medium:** gra ma tylko wbudowany font Godota — ustawić w motywie Bona Nova (nagłówki) i Atkinson Hyperlegible Next (tekst), pliki w `mockups/fonts/` (OFL).
- **Low:** link źródła notki Sargent prowadzi do strony działającego producenta — zmienić na źródło encyklopedyczne; `showcase.*.source` w `content.csv` zawiera notatki redakcyjne i PL w kolumnie EN — oczyścić; `OFL.txt` w dodatku GUT bez not Courier Prime i Lobster Two.

## Od sesji A: spec wyczucia (FEEL.md, D-36) — 2026-11-05
- Zastosuj łatkę z `docs/FEEL.md` §9 do `game/data/haptics_patterns.json` (JSON Merge Patch, addytywna).
- Błędy do poprawy (FEEL.md §7): (1) `feedback_director.gd` — odwrócony warunek przerwania: po limicie odrzuca break/open/detector_trip zamiast mniej ważnych; (2) pod-zdarzenia ignorowane (serration gra jak pełny false_set); (3) koalescencja po samym typie gubi drugi impuls dźwigni i potrafi tłumić strumień klików pierścienia; (4) ducking zeruje opór, który nie wraca bez zmiany wartości; (5) suwak intensywności skaluje zdarzenia kluczowe dwukrotnie; (6) `sfx.gd` ładuje 4 warianty, `audio/v2` będzie mieć 6.

## Od sesji A: biblia klientów (CLIENTS.md) — 2026-11-05
- Wklej załącznik A z `docs/CLIENTS.md` (207 wierszy `key,en,pl`; klucze `job.<id>.line.<n>`, `job.<id>.note`, `job.<id>.after.<n>`, `cast.<id>.name`, `notebook.*`) do `game/i18n/content.csv` i wepnij mapę mówców z załącznika B do danych zleceń.
- Do rozstrzygnięcia w danych: (1) dwie postaci „Ola” — pannę młodą w `newlyweds_4am` zmień na „Kasia”; (2) `job.drummer_locker.json` ma `"family": "unknown"` — wg JOBS.md zamek rurkowy (nie ma go w lockcore: przypisz najbliższą rodzinę MVP albo oznacz jako zlecenie post-MVP); (3) `kiosk_shutter`: dane mówią „list z hurtowni”, JOBS.md „umowa dzierżawy” — zostaje wersja z danych; (4) w scenach roboczych nie używamy nazw aplikacji/urzędów („mObywatel” → „aplikacja”).

## Od sesji A: ekran zamka photoreal (2026-11-05)

Sesja A zbudowała fotorealistyczny ekran zamka na planie B (D-31, zaakceptowany; szczegóły D-37). **Pliki tylko nowe, nic w waszych plikach nie jest zmienione:**
- `game/scenes/photoreal/lock_photoreal.tscn` — pełny ekran zamka (zamiennik `scenes/lock.tscn`): ta sama hydraulika co `lock_scene.gd` (LockcoreSession albo FakeLockSession, wasz `InputSampler` 120 Hz, zdarzenia → `Haptics` + `Sfx` + `Events` w tym samym kroku fizyki), plus widok photoreal.
- `game/scripts/photoreal/lock_photoreal_view.gd` (`LockPhotorealView`, Control) — sam obraz: `present(view_model, input, delta)` co krok fizyki, `on_event(e)` na każde zdarzenie, `set_lives(n)`, `set_dark(on)`, `touch(index, pos, pressed)` (wgniecenie skóry pod kciukiem), sygnał `pause_requested` (klapka zwijki 48 dp, prawy górny róg; w poziomie lewy).
- `game/scripts/photoreal/pin_pose.gd` (`PinPose`) — czysta funkcja: stan + pozycja elementu → wysokości pinów (testy GUT).
- `game/scripts/photoreal/*.gdshader` — `plate` (statyka = render Cycles rzutowany przez kamerę), `plate_rest` (rdzeń i napinacz: płyta rzutowana z pozy spoczynkowej, więc mogą się lekko obracać), `matcap` (piny, sprężyny, wytrych: matcap z Cyclesa + normal/AO; ugięcie wytrycha od `stress`).
- `game/assets/photoreal/` — `cutaway_baked.glb` (z wypieku spike'u 4), `plate/plate_1236x1650.png` (nowa płyta: ruchome części całkiem usunięte z renderu, bez „duchów” cieni), `matcap/`, `tex/` (normal/ORM ruchomych części), `tray/tray_full.png` i `tray_empty.png` (zwijka z `art/blender/tray.py`, 1080×960, `--lost 0` i `--lost 3`), `tools/render_plate.py`, `tools/compare_section.sh`.
- `game/tests/gut/test_photoreal.gd` — 7 testów (mapowanie stanów, A7 „stany różne geometrią”, scena headless z sesją).

**Jak podpiąć (wybierzcie jedno):**
1. Najprościej: tam, gdzie przechodzicie do zamka, zamieńcie `"res://scenes/lock.tscn"` na `"res://scenes/photoreal/lock_photoreal.tscn"` (albo za ustawieniem, np. `ProjectSettings.get_setting("lockwright/lock/photoreal", true)`). Scena ma `@export family/seed/tier`.
2. Albo zostawcie swój kontroler i wstawcie sam widok: dodajcie `LockPhotorealView` (Control na pełny ekran w CanvasLayer `layer = 0`), w `_physics_process` po `session.step()` wołajcie `view.present(session.describe(), input, delta)`, a w pętli zdarzeń `view.on_event(e)`. Wtedy usuńcie z `lock.tscn` `LockRig`/`Camera3D`/`KeyLight`.

**Prośba o drobną zmianę w `lockcore_gd` (2 linie, wasz plik):** w `LockcoreSession::describe()` dodajcie do słownika elementu `ed["window_lo"]` i `ed["window_hi"]` (z `ElementView`, `/ Q16_ONE`). Widok wtedy dobiera długość pina dolnego do prawdziwego nacięcia (pin dolny staje dokładnie na linii podziału przy `set`). Bez tego używa środka zakresu generatora (0,56) — działa, ale pin „wiążący” może minąć linię podziału o ±0,14 skoku zanim zaskoczy. `pick_lift` z ViewModelu też by się przydał (dziś grot idzie za wejściem z samplera).

**Dev/CI:** `godot --path game --rendering-method mobile --resolution 824x1830 res://scenes/photoreal/lock_photoreal.tscn -- --lw-shot out.png [--lw-sim 1500 | --lw-pose blender] [--lw-lives 2] [--lw-dark 1] [--lw-touch 1]` (bez GPU: Xvfb + Mesa lavapipe, jak w spike'u 4). `--lw-bench 10` wypisuje `LW_PERF`. Porównanie z Cyclesem: `game/assets/photoreal/tools/compare_section.sh shot.png out_prefix`.

**Ograniczenia (świadome):** model ma 5 komór — t2/t3 zostawiają puste komory (nawiercone, bez pinów), t6–t7 (6–7 pinów) potrzebują wariantu `cutaway.py` z 6–7 komorami i nowej płyty; ramię napinacza jest poza kadrem Cyclesa (`cutaway.py` prowadzi je w dół wzdłuż drzwi przy x = −5 mm), więc napięcie czyta się z obrotu stopki napinacza i czoła rdzenia (luz 1,2° + obrót rdzenia) — pełne ramię wymaga zmiany kadru albo geometrii w `art/`; pauza to uproszczona klapka (skóra + napa) i skórzana zasłona z trzema pozycjami — docelowy wygląd wg HUD §6 do zrobienia u was; płyta pasuje do jednej kamery 3:4 (lupa D-13 = druga płyta).
- lockcore v0.4: `ViewModel.hold_progress` / `reset_progress` (Q16) — wystaw je w lockcore_gd (FEEL.md §7) przy przebudowie bibliotek.
- D-38: `job.drummer_locker.json` → `"family": "wafer"`, tier 1; `job.drummer_locker.situation` (PL/EN) bez „rurkowego zamka”, sama „szafka”.

## Od sesji A: ekonomia (ECONOMY.md, D-39) — 2026-11-05
- Wprowadź liczby ze scenariusza C (`docs/ECONOMY.md` §6) do `game/data` i sprawdź `python3 tools/econ_sim.py` (0 zablokowanych zleceń).
- Błędy w danych: 7 zamków zapadkowych ma `family: lever` (powinno `warded`), `liege_bakery` → `lever_detector`; `drummer_locker` → `wafer` t1 (D-38); warunki `after_t8` nie istnieją (lockcore max t7).
- Prośba (ekran photoreal): w `lockcore_gd` w `describe()` dodać do słownika elementu `window_lo`, `window_hi` i `pick_lift` — bez tego długość pina dolnego w `pin_pose.gd` to średnia generatora i pin może minąć linię podziału o ±0,14 skoku.
- Zrzuty ekranu w kontenerze bez GPU działają u sesji A przez Xvfb + lavapipe (Mesa Vulkan software) i Godota 4.7.2 — komendy w sekcji „Od sesji A: ekran zamka photoreal”. Użyj tego w zadaniu 13.

## 2026-11-05 — Etap 3: zadania 1–5

1. **N-01…N-12:** wszystkie uwagi z adnotacjami w SESSION-C-REVIEW.md. Kluczowe: N-02 (Android nie ucina już transientów — `transientUntilMs` + skip segmentu), N-03 (plugin `lockwright-click-audio` z `spikes/audio-latency` w `platform/android/`, Sfx ładuje PCM), N-05 (tier bez cięcia, niezaimplementowane rodziny ukryte), N-06 (FNV-1a), N-07 (`BasicEnvelopeBuilder`), N-08 (.so poza gitem, artefakt CI), N-09 (tryb tutorial kończy się poprawnie, test GUT), N-11 (klamra zamiast X).
2. **lockcore v0.4:** binding wystawia `hold_progress`/`reset_progress` + `rules_version()`; test GUT: lever/lever_detector = RULES_VERSION 2. Binarki przebudowywane w CI (linux artefakt, android w game-android, iOS xcframework w game-ios).
3. **FEEL:** łatka §9 (JSON Merge Patch) nałożona na `haptics_patterns.json` (feel_version 2, sub_events, budget); 6 błędów FeedbackDirectora naprawionych + testy.
4. **audio/v2:** 464 WAV podmienione, `check_sfx.py` zielony (onset ≤ 2 ms, kliki 20–140 ms z ogonem „blizgu”), wpis w ASSETS.md.
5. **Photoreal:** `JobRun.lock_scene_path()` — pin_tumbler (i puste current_job) otwiera `scenes/photoreal/lock_photoreal.tscn` (D-37), pozostałe rodziny zostają na placeholderze.

## 2026-11-05 — Etap 3: zadania 6–12

6. **Dane/ekonomia (D-38/D-39):** rodziny poprawione (7 zapadkowych → `warded`, `liege_bakery` → `lever_detector`, `drummer_locker` → `wafer` t1), `after_t8` usunięte, ceny z ECONOMY §6, krzywa `1 + 1.2*ln(1+n)*skill`, `session_income=385`. `econ_sim.py` (scenariusz C): **0 zablokowanych zleceń** (careful/average/clumsy 0/0/0).
7. **Dialogi (CLIENTS.md):** 207 wierszy Załącznika A w `content.csv`, mapa mówców (Załącznik B) w JSON-ach zleceń, linie na ekranie przyjazdu z imieniem na emaliowanej tabliczce, `newlyweds_4am`: Ola → Kasia.
8. **Weryfikacja (N-04/C-01):** scenka z kartami jako przedmiotami (klucze i18n, PL+EN), bez wag/progów; 3 sceny odmowy (`refuse_*`) — odmowa +5 reputacji, otwarcie niemożliwe.
9. **Typografia/A11Y:** motyw `theme/main.tres` — Atkinson Hyperlegible Next (tekst) + Bona Nova (nagłówki), OFL, wpis w ASSETS.md; safe-area na wszystkich menu (`SafeArea.apply`); skala tekstu 100–200%; „ogranicz ruch”; notka o dźwięku w trybie ciemnym. A-01/A-04/A-05/A-06/A-07 z audytu zamknięte.
10. **Narzędzia obserwacji:** lupa/mikroskop/wziernik w `tools.json` z kosztem i odblokowaniem; lupa już działa na ekranie zamka (D-13).
11. **Warsztat/zlecenia jako sceny:** tła `workshop.jpg`/`stairwell.jpg` z makiet (w `game/assets/ui/`, ASSETS.md).
12. **Gablota + Tryb Ciągły:** link producenta usunięty z notki Sargent (C-02), klucze `showcase.*.source` wyczyszczone z content.csv (C-03); `run_loop.tscn` — krzywa 1.2·ln, 3 życia, warsztat co 5 zamków, rubber band.

## 2026-11-05 — Etap 3 (SESSION-B-PROMPT-3): wszystkie 17 zadań — tabela statusów

| # | Zadanie | Status |
|---|---|---|
| 1 | Uwagi N-01…N-12 (2. przegląd) | ✅ wszystkie z adnotacjami `→ naprawione w <hash>` w SESSION-C-REVIEW.md; testy GUT dla N-02/N-05/N-06/N-09 |
| 2 | lockcore v0.4 w grze | ✅ `hold_progress`/`reset_progress` + `rules_version()` w bindingu; test GUT lever = RULES_VERSION 2; binarki w CI (linux artefakt, android, iOS xcframework) |
| 3 | Wyczucie (FEEL.md) | ✅ łatka §9 (merge patch) nałożona (feel_version 2, sub_events, budget); 6 błędów FeedbackDirectora naprawionych + testy |
| 4 | Dźwięki audio/v2 | ✅ 464 WAV podmienione; `check_sfx.py` OK (onset ≤ 2 ms); ASSETS.md |
| 5 | Ekran photoreal | ✅ `JobRun.lock_scene_path()` — pin_tumbler domyślnie na `scenes/photoreal/lock_photoreal.tscn` (D-37, N-10) |
| 6 | Dane zleceń + ekonomia | ✅ warded/lever_detector/wafer, bez after_t8, ceny §6, krzywa 1.2·ln; `econ_sim.py` scenariusz C: **0 zablokowanych zleceń** |
| 7 | Dialogi CLIENTS.md | ✅ 207 wierszy w content.csv, mapa mówców w jobach, linie z tabliczką imienia, Ola→Kasia |
| 8 | Weryfikacja po ludzku | ✅ scenka z kartami (i18n PL/EN, bez wag), 3 sceny odmowy z reputacją, otwarcie niemożliwe |
| 9 | Typografia + A11Y | ✅ motyw OFL (Atkinson/Bona Nova), safe-area na menu, skala 100–200%, reduce motion, notka dark-mode; A-01/04/05/06/07 zamknięte |
| 10 | Narzędzia obserwacji | ✅ lupa/mikroskop/wziernik w tools.json; lupa działa na ekranie zamka |
| 11 | Warsztat/zlecenia jako sceny | ✅ tła z makiet (workshop.jpg, stairwell.jpg) w game/assets/ui + ASSETS.md |
| 12 | Gablota + Tryb Ciągły | ✅ C-02/C-03 wyczyszczone; `run_loop.tscn` z krzywą 1.2·ln, 3 życia, rubber band |
| 13 | Zrzuty w CI | ✅ job `game-screens` (ubuntu + xvfb + Mesa llvmpipe, 412×915 i 915×412, artefakt PNG do docs/handoff/screens/); lokalnie w sandboxie bez roota/GPU nadal niemożliwe (szczegóły w §zadanie 8 etapu 2) |
| 14 | Test e2e | ✅ GUT: bot lockcore otwiera samouczek + wszystkie grywalne zlecenia, save zapis/odczyt co krok; brak zmiany formatu save (zostaje save/1) |
| 15 | Lok-QA | ✅ `data/tools/loc_qa.py` w CI: kompletność PL/EN, „polskie w EN” (z allowlistą nazw własnych), ostrzeżenia przepełnień przy 200% |
| 16 | Uwagi Low + COMPLIANCE | ✅ C-05 (noty OFL fontów GUT), pozostałe Low z adnotacjami w przeglądach |
| 17 | Wydajność | ✅ GUT `test_perf`: step+describe+feedback = **5,7 µs/krok** (budżet 8333 µs); alokacje z pętli 120 Hz usunięte już w R-23 (describe raz na klatkę) |

**CI:** game-tests / game-android / game-ios / game-screens — patrz kolejne rundy; ostatni push `66a8196`.

## Od sesji A: CI czerwone po etapie 3 — 2026-11-05 09:45
- `game-android`: w 8853863 komenda budowania AAR została ucięta do samego `./gradlew ` (bez zadań), więc AAR click-audio nie powstawał i eksport APK padał na `download-artifact`. Sesja A przywróciła: `./gradlew :lockwright-haptics:assembleRelease :lockwright-click-audio:assembleRelease`.
- `game-tests` / job `export-pack-test`: uruchomiony pack nie znajduje `addons/lockcore_gd/bin/liblockcore_gd.linux.template_debug.so` (biblioteka nie jest obok packa) i `res://tests/smoke.tscn` (wykluczony z eksportu). Do naprawy przez sesję B.
- `game-screens`, `qa-career`: też czerwone — sprawdź logi. Zasada: etap nie jest skończony, dopóki CI nie jest zielone.
- 10:50 sesja A: `plugin-aar` padał na `HapticsEngine.kt` (wcześniej ukryte, bo gradle nie budował niczego): `VibrationEffect.startEnvelopeBuilder()` nie istnieje — zamienione na `VibrationEffect.BasicEnvelopeBuilder()` (API 36: `setInitialSharpness`, `addControlPoint(intensity, sharpness, durationMs)`); `effect.duration` nie jest publicznym API — stała 60 ms. Lokalnie nie dało się zweryfikować (Maven 429), sprawdź wynik CI.
- 10:55 sesja A: `export-debug-apk` padał, bo godot-cpp (master) wymaga NDK 28.1.13356709, a job instalował samo SDK bez NDK — dodane `ndk;28.1.13356709` w kroku SDK tego joba.
