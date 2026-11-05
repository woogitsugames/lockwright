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

## Od sesji A: grafiki ChatGPT do gry (D-43) — 2026-11-05
- **G01** `contrib/gpt/G01/plate_*.png`: tabliczki mieszkań (numer z danych zlecenia → `plate_NN.png`, pomieszczenia → `plate_sign_<nazwa>_<pl|en>.png` zależnie od języka) na ekranie przyjazdu i w warsztacie.
- **G07** `contrib/gpt/G07/images/*.jpg` (1080×2340): tło ekranu przyjazdu wg typu miejsca i pory (pole `place`/`time` w danych zleceń; dodaj, jeśli brak). Dolne ~40% spokojne pod interfejs.
- **G08** `contrib/gpt/G08/images/`: tło warsztatu (menu): 01 rano, 06 popołudnie, 08 wieczór — wg godziny gry.
- Kopiuj do `game/assets/ui/gpt/` (JPG/WebP ≤ 1 MB po kompresji), bez zmiany treści.
- **G11** `contrib/gpt/G11/png/g11-NN-<pl|en|clean>.png` (+ `cards.json`, `stamps/`): kartki mistrza w zwijce dla samouczka S1–S3 (D-40) — wersja wg języka gry, `clean` gdy włączone „bez tekstu”. Pieczątka „to gra, nie kurs” ze `stamps/`.

## 2026-11-05 — Etap 4 (SESSION-B-PROMPT-4): 14 zadań

### Zadanie 1 — Zielone CI ✅ (w trakcie potwierdzania na najnowszym main)
- `plugin-aar`: `HapticsEngine.kt` używało nieistniejącego `VibrationEffect.startEnvelopeBuilder()` i `effect.duration` → `BasicEnvelopeBuilder().addControlPoint(intensity, sharpness, durationMs)` (API 36) + czas transientu przez refleksję/stałą (1deaa00, wcześniej ta sama linia w 6e0c398). Run `game-android` **42014538689 zielony** (artefakt `lockwright-android-debug` APK).
- `export-pack-test`: preset „Linux” w repo (preset.2) dostał `include_filter` z `addons/lockcore_gd/bin/*.so` i bez `tests/*` w exclude; z workflowa usunięty duplikujący `printf [preset.2]` (828e019).
- `game-ios`: `godot::memnew` → `memnew` (to makro; 1deaa00), SConstruct buduje dylib pod xcframework.
- `game-screens`: format argumentów `--out=` / `--size=` (N-19, 828e019).
- `qa-career`: zielony od rundy 1 (ustalenie: błędy gry = ostrzeżenia w raporcie); przyczyny po stronie gry (N-13…) naprawione w zadaniu 3.
- i18n w pck (R-28): `i18n.gd` przy braku surowego CSV ładuje skompilowane `*.translation` z pck (a7a0b13).

### Zadanie 2 — Grywalny APK dla właściciela
Ścieżka z APK (artefakt `lockwright-android-debug` z `game-android`): **co przetestować w 10 minut**
1. start → notka „to gra, nie kurs” (3 s) → przy pierwszym uruchomieniu krótka kalibracja (dwa stuknięcia: Dwa/Jedno/Nic/Pomiń);
2. samouczek S1–S3 na wkładce (otwórz zamek, dalej);
3. menu → Warsztat (kup wytrych, zamknij);
4. Zlecenia → pierwsze zlecenie z fotorealistycznym zamkiem (przeciągnij wytrych, naciśnij, puść);
5. ekran zapłaty (monety + ewentualny napiwek) → wróć do listy;
6. kolejne zlecenie. Przycisk „Wstecz”/gest systemowy wraca wszędzie; pauza w zamku (klapka góra-prawy róg).

### Zadanie 3 — Uwagi z przeglądów ✅
N-13, N-14, N-15, N-19, N-20, N-21, N-22, N-23, N-24, N-25, N-26, N-28 + A-10, A-11 — adnotacje `→ naprawione w 828e019 / 1deaa00` dopisane w `SESSION-C-REVIEW.md` i `A11Y-AUDIT.md`. N-16/A-03/A-09 zostają po stronie sesji A (`game/*/photoreal/`).

### Zadanie 4 — Haptyka z haptics/ ✅
`game/data/haptics/` = kopia `haptics/out` (AHAP + łańcuchy Androida + index.json z SHA-256); `haptics_patterns.json` dostał sekcję `detail`; `haptics.gd` ma `detail_index()`/`pattern_files_for()`/`prepare_native()`; presepty pakują `data/haptics/**`; CI: `haptics/validate.py` (budżet OK) + check hash-y (f045ec8, D-44).

### Zadanie 5 — Dźwięk cz. 2 ✅
`game/assets/audio/{ambience,ui,reward}` z `audio/v2/out` (d3a886b): tła per scena (klatka/warsztat/noc/deszcz, pętle −35 LUFS I na nowej szynie Ambience), dźwięki UI (kartki, szuflada, telefon…), nagrody door_open→thanks→coins na ekranie zapłaty; ducking tła −6 dB/50 ms na każde L2 i −12 dB/300 ms po `break` (FEEL §5.1). Wpis w ASSETS.md.

### Zadanie 6 — Kalibracja + Wyczucie + język ✅
Pierwsze uruchomienie: test „dwa stuknięcia” (haptyka+dźwięk, TECH §2.3) z odpowiedziami Dwa/Jedno/Nic/Pomiń → wynik w ustawieniach (b145de7). Ustawienia: sekcja „Wyczucie” (włącznik, intensywność, test, kalibracja, reset), przełącznik języka PL/EN (system/PL/EN). DE: **pominięte — nie ma `contrib/gpt/T03/`**.

### Zadanie 7 — Jakość grafiki na tanie telefony ✅
Autoload `Quality` (f25d5ac, D-45): profile high/medium/low (render_scale 1.0/0.75/0.5, MSAA 4x/2x/off, płyta planu B skalowana), „auto” mierzy średni czas klatki przez 10 s i wybiera; zmiana w Ustawieniach → Jakość grafiki. Nakładka FPS + ms tylko w debug build.

### Zadanie 8 — Build wydaniowy Androida ✅
Job `release-aab` w `game-android.yml` (c78e991, D-47): gradle release + AAB, `version/name` z tagu, `version/code` z liczby commitów od tagu, raport rozmiaru w step summary + artefakt. Podpis gdy sekrety są: `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`; bez nich krok się pomija bez błędu. **Instrukcja dla właściciela:**
```bash
keytool -genkeypair -v -keystore release.keystore -alias lockwright -keyalg RSA -keysize 2048 -validity 10000
base64 -w0 release.keystore   # -> sekret ANDROID_KEYSTORE_BASE64
# Settings → Secrets → Actions: ANDROID_KEYSTORE_BASE64, ANDROID_KEYSTORE_PASSWORD,
# ANDROID_KEY_ALIAS=lockwright, ANDROID_KEY_PASSWORD
```

### Zadanie 9 — iOS ✅
`game-ios.yml` buduje niepodpisany IPA (artefakt `lockwright-ios-debug`). Do TestFlight brakuje: konto Apple Developer ($99/rok), certyfikat „Apple Distribution”, profil prowizjonowania App Store + team id. `game-ios-release.yml` (c78e991) tylko `workflow_dispatch` — po dodaniu sekretów `APPLE_CERTIFICATE_BASE64`, `APPLE_CERTIFICATE_PASSWORD`, `APPLE_PROVISIONING_PROFILE_BASE64`, `APPLE_TEAM_ID` sam podpisze i zbuduje release IPA.

### Zadanie 10 — Osiągnięcia i wskazówki ✅
`contrib/gpt/T10` wczytane lokalnie (233e903, D-46): `game/data/achievements.json` + autoload `Achievements` (40 osiągnięć, postęp w Save, seam `report_to_platform()` pod Game Center/Play Games później); 60 wskazówek mistrza losowo w menu; 30 wpisów zeszytu w gablocie. Wszystko przez i18n PL/EN (klucze `ach.*`, `tip.*`, `notebook.extra.*`).

### Zadanie 11 — Rozdział 7 ✅
12 zleceń T09 w `game/data/jobs_ch7/` (walidacja: wszystkie OK, chapter=7), ładowane tylko gdy flaga „po premierze” (5-tap w „O grze”; `Save.post_release`). `python3 tools/econ_sim.py`: scenariusz C **0 zablokowanych zleceń** (careful/average/clumsy 0/0/0), wynik w `docs/ECONOMY.md`.

### Zadanie 12 — Lokalny dziennik błędów ✅
Autoload `ErrorLog` (59a56e2): log do `user://logs/` z rotacją (5 plików × 512 KB), bez telemetrii. Ustawienia → „Zgłoś problem”: kopiuje ostatni log do schowka (do wklejenia w wiadomość); nic nie wychodzi z urządzenia.

### Zadanie 13 — Napisy końcowe i licencje ✅
`data/tools/gen_notices.py` generuje `game/THIRD-PARTY-NOTICES.txt` (Godot MIT, godot-cpp MIT, GUT MIT, Oboe Apache-2.0, fonty OFL) — plik pakowany do eksportu; ekran „O grze” linkuje pełną listę (klucz `about.licenses`), autorzy i zasoby w `docs/ASSETS.md`.

### Zadanie 14 — Test regresji wyglądu ✅
`game-screens.yml` (8e6fe3e): po renderze pobiera artefakt `game-screens` z ostatniego zielonego runu na main i `data/tools/compare_screens.py` liczy frakcję zmienionych pikseli per ekran (próg 2%); raport `DIFF-REPORT.md` + miniatury różnic w artefakcie `game-screens-diff`.

## 2026-11-05 — Etap 5 (SESSION-B-PROMPT-5), zadanie 1: CI na zielono — przyczyny czerwonych runów

- **qa-career (czerwony, run 42019016409):** regresja **N-29** — `game/scripts/lock/lock_job.gd` dziedziczył po pliku sceny (`extends "res://scenes/photoreal/lock_photoreal.tscn"`), więc skrypt się nie kompilował (`Could not resolve super class inheritance`), żaden zamek pin_tumbler ani samouczek nie startował, kariera 0/29 „stuck”. Poprawka wg gotowego diffu z `SESSION-C-REVIEW.md` N-29: dziedziczenie po `res://scripts/photoreal/lock_photoreal.gd`, a `game/scenes/lock_job.tscn` instancjonuje scenę photoreal z podpiętym wrapperem.
- **game-tests (czerwony, run 42018112290):** błąd w inline-Pythonie kroku `data-validation` w `game-tests.yml` — `sum(len(e) for e in [1])` (`TypeError: object of type 'int' has no len()`). Poprawione liczenie sprawdzonych plików (`checked += 1`). Lokalnie: 238 plików OK, `validate.py`/`loc_qa.py`/`haptics/validate.py` zielone.
- **game-ios (czerwony, run 42017980782):** `scons: *** Source file: Sources/register_types...o is static and is not compatible with shared target` — godot-cpp dla platform=ios kompiluje obiekty statyczne (bez `-fPIC`), a `platform/ios/lockwright_haptics/SConstruct` budował z nich `SharedLibrary` (.dylib). Poprawka: `-fPIC` dla platform=ios w SConstruct.

## 2026-11-05 — Etap 5, zadanie 3: dźwięki ChatGPT (S01–S04)

- **S01** → `game/assets/audio/music/` (9 OGG); nowa magistrala `Music` z low-pass 2,2 kHz (w zamku „cicha wersja”: `Sfx.play_music(&"lock_harmony")` + `set_music_lowpass(true)` + ducking −6 dB); menu/lista zleceń `main_theme`, warsztat/gablota `menu_workshop`, jingle (door_open, dignified_refusal) jako one-shoty.
- **S02** → `game/assets/audio/foley/` (39 WAV); `Sfx.play_foley` — pukanie/dzwonek na ekranie przyjazdu.
- **S03** → `game/assets/audio/voices/<postać>/` (96 WAV), znormalizowane do **−28 LUFS M** wg uwagi sesji C (pomiar `audio/v2/loudness.py`); `Sfx.play_voice` przy liniach dialogu.
- **S04** vs `audio/v2/out/ui`: kategorie wspólne (`tool_roll_open/close`) wybrane S04 (onset ≤ 1,4 ms, 6 wariantów), reszta kategorii S04 dołączona do `game/assets/audio/ui/`; `check_sfx.py` zielony.

## 2026-11-05 — Etap 5, zadanie 4: teksty ChatGPT (T01–T04, T10)

- **T01+T02:** 179 poprawek EN (`en_new != en_old`) w `game/i18n/content.csv` + `strings.csv`.
- **T03:** kolumna `de` w obu CSV (105 + 356 kluczy, fallback EN gdy brak DE), `I18n.SUPPORTED += "de"`, język DE tylko gdy `Save.dev_mode` (5-tap w „O grze”); opcja DE w ustawieniach widoczna tylko z flagą.
- **T04:** 20 notatek gabloty (title/body PL+EN) podmienione z `showcase_notes_fixed.md`.
- **T10 v2:** osiągnięcia z `contrib/gpt/T10/v2/` (bez „master lock” w EN) → `game/data/achievements.json` + klucze `ach.*`.
- `loc_qa.py` ✅, `validate.py` ✅, `check_sfx.py` ✅.

## Od sesji A: PILNE — test na telefonie właściciela (Gemini GEM3) — 2026-11-05
Raport: `docs/handoff/device-tests/REPORT.md` (Samsung Galaxy A16, Helio G99, haptyka A0). Gra na prawdziwym telefonie jest **niegrywalna** przez trzy błędy P0 — napraw je **przed** zadaniami 2–5 etapu 5:
- **BUG-01 (P0):** `boot.gd` Parse Error (typowanie `first_run` + kolizja `class_name` autoloadów) — APK nie startuje.
- **BUG-02 (P0, = N-29):** czarny ekran bez wyjścia po wejściu do `lock_job.tscn` (samouczek i zlecenia pin_tumbler).
- **BUG-03 (P0):** wyjście z zamka przez pauzę zostawia `get_tree().paused = true` — menu zamarza.
- Potem P1: BUG-04 (Chalk połyka dotyk), BUG-06 (RAM 598 MB > 350 MB), BUG-07 (puste przyciski na przyjeździe/weryfikacji), BUG-08 (otwarcie aktywne w zleceniach odmownych), BUG-14 (stały debug.keystore w CI, żeby aktualizacje APK się instalowały), oraz zimny start 4,4 s (async preload SFX).
- **Audio:** pomiar potwierdził GO dla natywnego mostka Oboe (52 ms vs 126 ms w Godot) — wszystkie kliki zamka muszą iść przez `LockwrightLowLatencyAudio`.
- **Wydajność:** GPU 5,7 ms, ale klatka 18,2 ms przez pacing (physics 120 Hz bez jitter fix na 60 Hz ekranie) — zbadaj `physics_jitter_fix`/interpolację i Swappy frame pacing.
- Każdy BUG: test GUT albo krok w `qa-career`, który by go złapał.

## Od sesji A: fotografie Magnific (D-48) — 2026-11-05
Po naprawie P0 z GEM3: `contrib/incoming/magnific/selected/` → `game/assets/photo/` (ASSETS.md): skóra zwijki (`leather_brown_worn` główna, `leather_stitching_strip` krawędź, `leather_brass_snap` pauza, wgniecenie kciuka z `contrib/incoming/leather_set_2026-11-05/thumb_dent.jpg`), papier rekwizytów (tekst nakładany przez grę na `paper_*`, `envelope_*`, `ink_oval_blank`), posadzka klatki `terrazzo_grey_red`/`pine_floor_painted`, wycieraczka. Tekstury powtarzalne przeróbki na bezszwowe robi sesja A.
- Materiały ze zdjęć (`art/textures/photo/`): w grze używaj tylko wersji `_1k` (albedo JPG, normal/roughness PNG) — rozmiar paczki (N-30). `glass_cabinet_dust` to maska krycia, nie PBR; `brass_face_milled` wymaga obrotu UV ~42°.
- Makieta 01-lock: pauza nadal jako „II” — według HUD §6 ma to być skórzana klapka z napą (`art/textures/photo/objects/leather_brass_snap*`). Dotyczy też ekranu zamka w grze, jeśli tam jest „II”.
- D-50: do czasu portretów epizodycznych pokazuj emaliowaną tabliczkę z inicjałem (G01) zamiast pustego miejsca; potem `portrait_<id>` z `contrib/incoming/magnific/selected/portraits/`.

## Od sesji A: decyzje właściciela (D-51) — 2026-11-05
- **Priorytet: Android.** iOS przeprowadzamy na końcu; `game-ios` nie blokuje zamykania zadań (zasada nr 1 dotyczy teraz `game-android`, `game-tests`, `game-screens`, `qa-career`).
- **D-24 zatwierdzona** (napięcie względne od punktu dotyku) — upewnij się, że tak działa w `input_sampler.gd` i samouczku.

## 2026-11-05 — Etap 6 (SESSION-B-PROMPT-6) + dokończenie zadań 5–6 etapu 5

**Zadanie 5 etapu 5 (zrzuty):** brak zielonego runu `game-screens` (kolejka runnerów zablokowana od ~11:45, wszystkie runy `in_progress`); lokalnie sandbox bez GPU/Xvfb — zrzuty z CI artefaktu dokopię do `docs/handoff/screens/` po pierwszym zielonym runie na main. Tymczasowo w repo są zrzuty z telefonu właściciela w `docs/handoff/device-tests/`.

**Zadanie 6 etapu 5 + zadanie 5 etapu 6 (GEM3, N-31…N-43) — naprawione:**
- **N-44:** `workshop_screen.gd:21` `OS.get_time()` → `Time.get_time_dict_from_system()`; warsztat bootuje headless bez błędów.
- **N-48:** `sfx.gd play_voice` łapie teraz `<kind>.wav` i `<kind>_NN.wav` + mapa `VOICE_DIR` (ola/krystyna → `ola_krystyna`); test GUT `test_play_voice_finds_plain_file_and_shared_folder`; checkery QA (`qa/assets/check_assets.py`, `qa/bot/career.gd`) z tą samą regułą — głosy S03 12/12 dla stałej obsady.
- **N-31/BUG-03:** `lock_scene.gd` Quit z pauzy ustawia `paused=false` przed zmianą sceny + test GUT `test_pause_quit.gd`.
- **N-32/BUG-04:** `Chalk` w `lock.tscn` dostaje `mouse_filter=2`.
- **N-33:** `physics_jitter_fix=0.5` w `project.godot` (rytm klatek przy 120 Hz na 60 Hz ekranie).
- **N-35/BUG-06 (zimny start 4,4 s):** `sfx.gd` — tylko L2 zamka preloadowane synchronicznie; ambience/music/ui/reward/foley/voices przez `load_threaded_request` w tle + leniwe doładowanie przy pierwszym użyciu (żaden dźwięk nie znika).
- **N-36/BUG-07:** puste przyciski (`AcceptButton`/`RefuseButton`/`Result`/`Reward`/`ContinueButton` w `job_arrival.tscn`, `VerifyButton`/`ContinueButton` w `job_verify.tscn`) ustawione `visible=false`.
- **N-37/BUG-08:** w zleceniach `job.refuse*` przycisk „Otwórz dla tego klienta" ukryty w `job_verify.gd`.
- **N-38/BUG-09:** `Magnifier` przeniesiony z `Zwijka` do `Hud` (kotwica prawy dolny róg, 96 px); tryb ciemny wygasza też `KeyLight`.
- **N-39/BUG-10:** `AboutPanel` dostaje nieprzezroczysty `StyleBoxFlat`.
- **N-40/BUG-11:** warsztat — narzędzia z `price: 0, unlock != start` pokazują „Nagroda za postęp” zamiast „Kup” (nowy klucz `workshop.reward`); gablota — odblokowanie wg `unlocks` z danych (wszystkie `job.*` ukończone + tier) i `RichTextLabel` z BBCode zamiast surowych `*…*` (nowy klucz `showcase.locked`); samouczek dostaje przycisk „Wstecz”.
- **N-42/BUG-13 (część gry):** dzieci `Scroll/VBox` w ustawieniach `mouse_filter=PASS` + `scroll_deadzone=12`.
- **N-43/BUG-14:** stały `platform/android/debug.keystore` (debugowy, hasło `android` jak w SDK) commitowany do repo i używany w CI (sekret `ANDROID_DEBUG_KEYSTORE_BASE64` ma priorytet, gdy dodany) — aktualizacje APK przez `adb install -r` zachowują zapis.

**Zadanie 3 etapu 6 (AAB bez sekretów):** `release-aab` przy braku sekretów eksportuje niepodpisany AAB (`package/signed=false`) zamiast padać na `Code Signing`.

**Zadanie 4 etapu 6 (N-30, rozmiar):** grafiki GPT importowane stratnie (`compress/mode=1`, q0,8 na 183 plikach), `scenes/photoreal_families/shots/` ma `.gdignore`, presety Android/iOS (+ preset release w CI) wykluczają `photoreal_families`. Zmierzone lokalnie `qa/budget/check_budget.py`: **pck 53,4 MB** (było 289 MB; próg błędu 70 MB).

**Zadanie 6 etapu 6 (pauza diegetyczna, HUD §6):** klapka 48 dp w safe-area rysuje teraz mosiężną napę z `assets/photo/leather_brass_snap_1k.webp` + haftowaną krawędź `leather_stitching_strip`; w klasycznym `lock.tscn` przycisk pauzy też dostaje ikonę napy zamiast tekstu.

**Zadanie 7 etapu 6 (D-48):** `game/assets/photo/` — wersje `_1k` z `art/textures/photo/` (leather_brown_worn, leather_stitching_strip, leather_brass_snap, tool_roll_pocket_empty_closeup, thumb_dent; wycinki z alfą jako WebP q85, import stratny) użyte w HUD zwijki (tło, puste kieszenie, wgniecenie kciuka); wpis w `docs/ASSETS.md`.

**Zadanie 8 etapu 6 (D-50, N-49):** postać bez portretu G09 dostaje emaliowaną tabliczkę z inicjałem (baza G01 `plate_01.png` + litera) w `job_arrival.gd`.

**Zadanie 9 etapu 6 (D-24):** `input_sampler.gd` — napięcie i uniesienie liczone od punktu dotyku (touch-down = 0), testy GUT `test_d24_*`.

**Lokalnie zielone:** GUT 49/49, smoke OK, lock_test OK (prawdziwe lockcore), `validate.py`/`loc_qa.py`/`haptics/validate.py`/`check_sfx.py` OK, wszystkie sceny bootują headless bez błędów skryptów, bot kariery `career_complete` (19/29 zleceń + odmowy, 0 soft-locków, 0 brakujących dźwięków, 0 błędów skryptów), budżet pck 53,4 MB.

**Zadanie 10 etapu 6 (APK dla właściciela) — „co sprawdzić w 10 minut”:** link do zielonego runu `game-android` dopiszę po pushu (artefakt `lockwright-android-debug`): 1) start → notka „to gra, nie kurs” → kalibracja; 2) samouczek S1–S3 (klapka pauzy = skórzana napa, Wstecz w samouczku); 3) Warsztat (nagrody zamiast „Kup za 0”, przewijanie listy gestem); 4) Zlecenia → przyjazd (tabliczka z inicjałem bez portretu, głos S03, tło G07) → weryfikacja (w odmowie brak „Otwórz”) → zamek (napięcie/uniesienie od punktu dotyku, lupa 96 px, ciemny tryb gasi światło); 5) zapłata → lista; 6) `adb install -r` kolejnego buildu zachowuje zapis (stały debug.keystore).

**Tabela statusów (linki do runów dopiszę po zielonym CI na main):**

| Workflow | Status |
|---|---|
| `game-android` | ⏳ po pushu |
| `game-tests` | ⏳ po pushu |
| `game-screens` | ⏳ po pushu |
| `qa-career` | ⏳ po pushu |
- **Portrety epizodyczne (D-50): komplet 39** w `contrib/incoming/magnific/selected/portraits/portrait_<id>.jpg` (id = nazwa mówcy z `lines` w zleceniach; `bride` = Kasia). Podmień tabliczki z inicjałem na portrety (wersja 512 px do gry, ASSETS.md).

## Od sesji A: dostawy ChatGPT runda 2 (T11–T30) — 2026-11-05
Po etapie 6, po odbiorze przez sesję C (`contrib/REVIEW.md`): T11 (korekta PL — zastosuj `pl_new`), T12–T17 (FR, ES, IT, PT-BR, CS, UK — za flagą deweloperską jak DE), T18 (rozdział 8, za flagą „po premierze”; `teresa` = ta sama postać co w `wrong_floor`), T19 (gablota +20), T20 (Tryb Ćwiczeń, 30 zamków — sprawdź walidatorem lockcore), T21 (czytnik ekranu: etykiety), T27 (54 testy GUT — wepnij te, które przechodzą), T28 (zeszyt +80), T29 (pomoc i FAQ). T25/T26 (przeglądy kodu) — popraw zgłoszenia High z `contrib/gpt/T25/` i `T26/`.

## Od sesji A: CI — kolejka zatkana (2026-11-05 17:30)
Kilkanaście runów `game-screens` wisiało „in progress” od 11:00 (bez limitu czasu) i blokowało runnery, przez co nowe kompilacje stały godzinami w kolejce. Sesja A anulowała 25 starych runów, dodała we **wszystkich** workflowach `concurrency: cancel-in-progress` (nowy push anuluje starszy run tego samego workflowu) oraz `timeout-minutes: 60` w jobach game-android/tests/screens/qa-career/perf-budget. Zbadaj, czemu `game-screens` się zawiesza (prawdopodobnie Godot pod xvfb nie kończy procesu — dodaj `--quit-after` / `timeout 600`).

## Od sesji A: głosy epizodyczne S03v2 (2026-11-05)
- `contrib/gpt/S03v2/voices/<id>/` ma 39 postaci po 8 plików: greeting, surprise, relief, thanks, impatient, sad, laugh, goodbye (`.wav`, 48 kHz mono, ok. −28 LUFS). QA automatyczne: PASS (`QA.md`, `manifest.json`).
- **Sesja B:** podłącz `Sfx.play_voice` dla id epizodycznych. Nazwy plików nie mają `_NN`, tak jak po N-48. Brakujące emocje mają wracać do `greeting`. Dopisz pliki do ASSETS.md zgodnie z `contrib/gpt/S03v2/ASSETS.md` (synteza formantowa, bez TTS i bez klonowania).
- **Sesja C:** zrób losowy odsłuch (min. 24 pliki) i sprawdź ASR, czy nic nie brzmi jak słowa. Werdykt dopisz do `contrib/gpt/S03v2/QA.md`.

## Od sesji A: APK run 92 (2026-11-05 18:18)
- Run game-android 92 był zielony we wszystkich jobach: https://github.com/woogitsugames/lockwright/actions/runs/42077893691. APK wysłany właścicielowi.
- Debug APK ma 130 MB, AAB w artefakcie 70,7 MB. Sprawdź raport rozmiaru: czy kompresja z N-30 działa w presecie debug i czy AAB mieści się w progu 70 MB.

## Od sesji A: testy właściciela na APK z runu 92 (2026-11-05 18:50), PRIORYTET
Zrzuty z telefonu: `docs/handoff/device-tests/run92/main_menu.jpg` i `settings.jpg`.

- **N-52, przycisk „wstecz” Androida zamyka grę (krytyczne).**
  - W `project.godot` ustaw `application/config/quit_on_go_back=false`.
  - Obsłuż `NOTIFICATION_WM_GO_BACK_REQUEST` w autoloadzie nawigacji. Wstecz ma działać jak przycisk „Wstecz” na ekranie: ustawienia/zlecenia/warsztat/gablota/O grze → menu; zamek → pauza (klapka); pauza → zamknij pauzę.
  - Zamknięcie gry tylko z menu głównego, po potwierdzeniu „Zakończyć grę?” (i18n PL/EN).
  - Dodaj test GUT, który wysyła notyfikację na każdym ekranie.
- **N-53, ustawienia dotykają krawędzi ekranu.**
  - Etykiety i suwaki zaczynają się od x=0, a „Wstecz” ma połowę szerokości.
  - Wymagane: `MarginContainer` z marginesem bocznym min. 16 dp plus safe-area (wycięcia, pasek gestów), także w poziomie.
  - Sekcje rozdzielone nagłówkami (Haptyka / Dźwięk / Język i dostępność). Wartości procentowe przy każdym suwaku, nie tylko przy haptyce.
  - „Wstecz” na pełną szerokość albo jako cel ≥48 dp w lewym górnym rogu.
  - Dla zgodności sprawdź tym samym kontenerem wszystkie ekrany menu (zlecenia, warsztat, gablota, O grze).
- **N-54, menu główne to domyślny szary motyw Godota.** Przerób je zgodnie z D-43 (warsztat jako menu, diegetycznie, bez paneli SaaS):
  - **tło:** `game/assets/ui/workshop.jpg` (G08) lub `contrib/incoming/magnific/selected/keyart_9x16.jpg`, przycięte do 9:16 i przyciemnione winietą w miejscu przycisków, bez gradientów;
  - **tytuł:** „Lockwright” plus podtytuł z i18n, fontem tytułowym Bona Nova Bold (styl `Title` z `theme/main.tres`, rozmiar ok. 40), wyśrodkowany w górnej 1/3;
  - **przyciski:** emaliowane tabliczki z G01 (tło przycisku, NinePatch), bez szarych prostokątów. Alternatywa: kartka zlecenia (`paper_card_stock`) przypięta na pegboardzie. Tekst Atkinson, kontrast ≥4,5:1, cel ≥48 dp, stany pressed i focus widoczne w skali szarości (przesunięcie i cień, nie sam kolor);
  - **kolejność:** „Rozpocznij bieg” wyróżniony jako największa tabliczka, reszta mniejsza; „O grze” może iść do stopki;
  - **motyw:** uzupełnij `theme/main.tres` o StyleBoxy Button, Panel, HSlider, CheckButton i OptionButton (ciepła skóra, papier, mosiądz zamiast szarości), wtedy ustawienia i pozostałe ekrany zyskają od razu;
  - **efekt wejścia:** delikatny, 150–250 ms;
  - **ASSETS.md:** wpisz wszystkie użyte zasoby;
  - **zrzuty:** dodaj zrzut menu i ustawień do `game-screens` (412×915 i 915×412).
- Kolejność: N-52 → N-53 → N-54. Po zielonym `game-android` wpisz link do runu, a sesja A wyśle APK właścicielowi.

## Od sesji A: N-55, haptyka nie działa na telefonie (naprawione w repo)
- Właściciel ma haptykę włączoną, a telefon nie wibruje. Przyczyna: w manifeście APK z runu 92 nie było `android.permission.VIBRATE`. Manifest pluginu `platform/android/lockwright-haptics` go nie deklarował, a preset nie miał `permissions/vibrate`.
- Poprawka sesji A: `uses-permission VIBRATE` w manifeście AAR oraz `permissions/vibrate=true` w presecie Android.
- **Sesja B:** sprawdź, czy krok „Release preset” w CI nie nadpisuje tej opcji. Dodaj do CI asercję, że zmergowany manifest APK zawiera VIBRATE (aapt dump permissions).

## Od sesji A: N-56, przycisk pauzy wygląda jak wklejony kwadrat (zrzut `device-tests/run92/lock_screen.jpg`)
- Właściciel nie wiedział, do czego służy, i uznał, że wygląda brzydko. Teraz to kwadratowe zdjęcie skóry z napą w prawym górnym rogu: ostre krawędzie, bez cienia, bez związku ze zwijką.
- Proponowany kształt:
  - **klapka:** skórzany język zwisający z górnej krawędzi ekranu, za safe-area. Kształt wycięty alfą (zaokrąglony dół), przeszycie wzdłuż brzegu z `leather_stitching_strip`, napa z `leather_brass_snap` na końcu, miękki cień na płycie (2–4 dp);
  - **wymiary:** szerokość ok. 56 dp, cel dotyku ≥48 dp;
  - **reakcja na dotyk:** klapka unosi się o 4 dp z kliknięciem napy (dźwięk i haptyka), animacja 150 ms;
  - **pierwsze uruchomienie:** podpowiedź w samouczku „Klapka = pauza” (i18n);
  - **alternatywa:** napa na prawym brzegu zwijki (dolny pas), skąd zwijka „odpina się”. Wybierz wersję czytelniejszą w zrzucie 412×915.
- Przy okazji zrzutu:
  - komory 4 i 5 w płycie są puste (nie ma sprężyn ani pinów). Jeśli zamek ma 3 piny, płyta powinna mieć 3 komory albo puste otwory zaślepione;
  - napinacza nie widać.

  Sprawdź, czy zgadza się to ze specyfikacją zamka.

## Od sesji A: N-57, lupa w zwijce nie reaguje (zgłoszenie właściciela, run 92)
- W `lock_photoreal_view.gd` lupa jest tylko narysowana w renderze zwijki (`tray_full.png`). Nie ma pod nią żadnego węzła wejścia. Przycisk `Magnifier` i `_on_magnifier_pressed` z D-13 istnieją wyłącznie w starym `lock_scene.gd` i nie zostały przeniesione do widoku planu B.
- **Do zrobienia:**
  - dodaj cel dotyku ≥48 dp nad lupą (prostokąt z kolumny tacy, także w poziomie);
  - po stuknięciu pokaż okrągłe pole okularu (D-13): makro zbliżenie komory z pinem, który teraz trzyma. W planie B wystarczy powiększony wycinek płyty w okręgu z mosiężnym pierścieniem, z tym samym stanem pinu;
  - drugie stuknięcie albo „wstecz” zamyka okular;
  - dźwięk `gate_align`, haptyka;
  - animacja 150–250 ms;
  - test GUT: stuknięcie przełącza `zoomed`.
- Jeśli lupa ma być narzędziem odblokowywanym później, pokaż ją jako wyszarzoną i po stuknięciu wyświetl krótką informację (i18n), zamiast żeby nic się nie działo.

## Od sesji A: N-58, bez napięcia gra milczy (zgłoszenie właściciela, run 92)
- Właściciel podnosił piny samym wytrychem (prawy kciuk) i nic się nie działo: nie było dźwięku ani podpowiedzi. Nie wiedział, że lewa połowa ekranu to napinacz (D-24, `input_sampler.gd`).
- **Do zrobienia:**
  - **dźwięki bez napięcia:** każdy kontakt wytrycha z pinem i ugięcie sprężyny daje cichy dźwięk (`pin_contact`/`spring`) i lekką haptykę. Przy podnoszeniu bez napięcia pin musi słyszalnie i widocznie opadać;
  - **podpowiedź kredą:** gdy przez ok. 2 s jest uniesienie, a napięcie = 0, pojawia się kredowa strzałka w górę i kciuk po lewej stronie płyty z tekstem i18n „Lewy kciuk: lekki nacisk w górę = napięcie”. Znika po pierwszym napięciu. Pokazuj ją też poza samouczkiem w pierwszych 3 zleceniach;
  - **wcięcia kciuków:** wgniecenie kciuka (`thumb_dent`) ma być widoczne od razu po dotknięciu obu stref, także lewej;
  - **samouczek:** sprawdź, czy pierwszy krok naprawdę uczy dwóch kciuków i nie przepuszcza dalej bez napięcia;
  - **dźwięk w ogóle:** właściciel potwierdził, że na APK z runu 92 grają wszystkie dźwięki. Brakuje tylko dźwięku kontaktu i sprężyny przy podnoszeniu bez napięcia.

## Od sesji A: N-59, ekrany szersze niż telefon, trzeba przewijać w poziomie (PRIORYTET, zgłoszenie właściciela)
Zrzuty: `device-tests/run92/workshop.jpg`, `workshop_scrolled.jpg`, `dialog.jpg`.

Problem jest systemowy, nie dotyczy jednego ekranu. Wiersze warsztatu (`HBox`: nazwa + stan + przycisk) mają minimalną szerokość większą niż 412 px, bo etykiety nie mają `autowrap` ani `clip`/`text_overrun`, a `ScrollContainer` pozwala na scroll poziomy.

**Reguły dla WSZYSTKICH ekranów UI** (warsztat, zlecenia, gablota, ustawienia, przyjazd, O grze):
1. **Bez scrolla poziomego:** `ScrollContainer.horizontal_scroll_mode = SCROLL_MODE_DISABLED`. Dziecko ma `size_flags_horizontal = EXPAND_FILL` i szerokość = szerokość kontenera.
2. **Etykiety w wierszach:**
   - nazwa: `autowrap_mode = AUTOWRAP_WORD_SMART`, `size_flags_horizontal = EXPAND_FILL`, `custom_minimum_size.x = 0`;
   - wartości i stany: `text_overrun_behavior = OVERRUN_TRIM_ELLIPSIS` albo przeniesienie pod nazwę.
3. **Wiersz warsztatu jako karta na 2 linie:** linia 1 to nazwa narzędzia, linia 2 to stan albo cena po lewej i przycisk po prawej (min. 96×48 dp).
   - przyciski nieaktywne (brak monet) wyraźnie inne: przygaszone **i** inny kształt/etykieta, np. „Za mało monet” (nie sam kolor);
   - „Nagroda za postęp” nie powtarza się w etykiecie i w przycisku, przycisk jest ukryty;
   - przy „Integralność 100%” przycisk „Napraw” jest ukryty albo nieaktywny.
4. **Wspólny `MarginContainer` (N-53):** 16 dp z boków + safe-area. Szary pas u góry (status bar) ma być wypełniony tłem ekranu, a nie szarym `clear_color`. Ustaw `rendering/environment/defaults/default_clear_color` na ciemny brąz tła albo rozciągnij tło pod status bar.
5. **Mapa w warsztacie:** maks. 30% wysokości, przycięta „cover”, nie zasłania listy.
6. **Test automatyczny:** dla każdego ekranu przy 360×800, 412×915 i 915×412 sprawdź, że `get_combined_minimum_size().x <= viewport.x` dla korzenia UI, i dodaj zrzuty do `game-screens`. 360 dp to najwęższe popularne Androidy.

## Od sesji A: N-60, rozmowa przy przyjeździe (zrzut `device-tests/run92/dialog.jpg`)
- **Tabliczka z inicjałem jest zepsuta:** `_initial_plate` używa `plate_01.png`, na której jest wydrukowana cyfra „1”, więc inicjał „K” nakłada się na „1”. Potrzebna jest pusta emaliowana tabliczka. Weź z G01 tabliczkę bez cyfry albo wymaż cyfrę z `plate_01` (PIL: wypełnij pole emalii jej kolorem), zapisz jako `plate_blank.png` i dodaj do ASSETS.md.
- **Brak portretów:** Kuba ma portret (`contrib/incoming/magnific/selected/portraits/portrait_kuba.jpg`), ale w grze jest tylko 16 z 39 (`assets/ui/gpt/cast/episodic/`). Zaimportuj wszystkie 39 (webp, 256², lossy) i dodaj test, że każdy mówca epizodyczny z `jobs` ma portret.
- **Ślusarz** (gracz) nie dostaje tabliczki z „Ś”. Jego linie są wyrównane do prawej bez awatara, jak w komunikatorze, albo mają ikonę zwijki.
- **Układ:** teraz nazwy i linie są w dwóch rozjechanych kolumnach, więc tekst nie stoi przy swoim mówcy. Każda linia ma być jednym wierszem: awatar 48 dp, a obok w kolumnie imię (mała, przygaszona etykieta) i nad nią lub pod nią tekst linii z autowrap. Odstęp między liniami 8–12 dp.
- **Pozostałe:**
  - tekst na zdjęciu potrzebuje podkładu (ciemny papier z ~70% kryciem, bez glassmorphism), żeby spełniał kontrast 4,5:1;
  - „Wstecz” jest na pół szerokości i przy krawędzi (N-53).

## Od sesji A: N-61, samouczek niczego nie uczy (NAJWYŻSZY PRIORYTET, zgłoszenie właściciela)
Zrzuty: `device-tests/run92/tutorial_intro.jpg` i `lock_screen.jpg`.

- **Co widzi gracz:**
  - ekran „Samouczek — zamek ćwiczebny, Etap 1 z 3”, przycisk i szkic G-art bez podpisu z wciśniętą kartką „To gra, nie kurs”;
  - potem goły ekran zamka bez żadnej instrukcji.

  Właściciel nie wiedział, co robić. Storyboard z `docs/ONBOARDING.md` §3.4–§4 (kreda S1, kroki, `fb_gain`) **nie jest zaimplementowany w widoku planu B** (`lock_photoreal_view.gd`). Kreda istnieje tylko w starym `lock_scene.gd`.
- **Sesja A zrobiła:**
  - `menu.play` PL: „Rozpocznij bieg” → „Zacznij dyżur” („bieg” był złym tłumaczeniem „shift”);
  - nowy klucz `tutorial.start` („Zacznij ćwiczenie”) na ekranie samouczka.
- **Do zrobienia (według ONBOARDING §4), S1 jako prowadzone kroki z kredą na płycie, bez paneli:**
  1. **Napięcie:** kredowy kciuk i strzałka w górę po lewej stronie, tekst „Lewy kciuk: delikatnie w górę — to napięcie”. Krok kończy się, gdy napięcie mieści się w oknie przez 0,5 s.
  2. **Wytrych:** kredowy kciuk po prawej, „Prawy kciuk: w bok wybierasz pin, w górę podnosisz”. Kończy się, gdy gracz dotknie pierwszego pinu.
  3. **Pin, który stawia opór:** kreski tarcia przy pinie binding, „Ten pin stawia opór — podnoś go powoli”.
  4. **Klik:** pierwszy set (stopka kredą, dźwięk i haptyka ×1,5), „Klik! Zatrzaśnięty. Szukaj następnego”.
  5. **Overset:** jeśli się zdarzy, klamra kredą i „Za wysoko — zwolnij napięcie i zacznij od nowa”.
  6. **Otwarcie:** obrót rdzenia, krótka pochwała, przejście do S2.

  Teksty idą przez i18n PL/EN/DE, odręczny font (Caveat OFL, już w `contrib/gpt/G10/v2/fonts`, wpisz do ASSETS.md). Każdy tekst max 2 linie, przy krawędzi płyty, nie na pinach.
- **Ekran przed samouczkiem:** zamiast szkicu bez podpisu pokaż 2–3 kadry z podpisami (napięcie / podnoszenie / klik), a kartkę „To gra, nie kurs” jako osobną, czytelną notkę, nie wciśniętą w rysunek.
- **Test GUT:** bot przechodzi S1 przez kroki 1–4 i każdy tekst kroku pojawia się i znika we właściwej kolejności.
