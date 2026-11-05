# Przegląd techniczny po nocy 4/5 XI (sesja C, tylko odczyt)

Data: 2026-11-05 · Zakres: drzewo robocze `main` (HEAD `24314f6`) oraz niezacommitowane WIP `spikes/lit-metal/` · Autor: sesja C (przegląd, bez zmian w kodzie)

Metoda: czytanie kodu i YAML oraz krótkie uruchomienia Godota 4.7.2 headless na **kopii** `game/` w katalogu tymczasowym. Repo nie zostało zmienione. Pozycje oznaczone „zweryfikowane” sprawdziłem uruchomieniem. Pozycje „do weryfikacji” wynikają z czytania kodu albo z mojej wiedzy o Godocie, a logów CI nie widziałem.

## Podsumowanie

| Obszar | High | Medium | Low |
|---|---|---|---|
| 1. API lockcore ↔ Godot | 5 | 7 | 2 |
| 2. Brakujące testy | 1 | 2 | 2 |
| 3. Wydajność i opóźnienia | 2 | 4 | 2 |
| 4. Zasady CLAUDE.md | 1 | 5 | 4 |
| 5. CI | 5 | 6 | 2 |
| **Razem** | **14** | **24** | **12** |

Najważniejsze, w kolejności:
1. **Eksport gry nie ma tłumaczeń.** `i18n.gd` czyta surowe CSV, których eksport nie pakuje (R-28, zweryfikowane).
2. **Mostek GDExtension przekazuje tylko 3 osie.** Rodziny `warded`, `ring_combo` i `lever_detector` są przez to niegrywalne (R-01).
3. **Nie ma FeedbackDirectora ani ClickAudioBridge w grze.** Kliknięcia idą przez AudioServer, a haptyka nie ma limitów, priorytetów ani duckingu (R-20, R-21).
4. **Haptyka natywna nie trafia do buildów albo nie odróżnia zdarzeń.** Pakowanie AAR i iOS jest zepsute, a iOS gra każde zdarzenie tym samym transientem (R-05, R-41, R-42).
5. **`game-android.yml` raczej nie przejdzie.** Używa flag `--keystore`, nie ma szablonu Gradle ani ścieżki SDK w ustawieniach edytora. Workflowy spike'ów robią to poprawnie (R-38…R-40).

---

## 1. Niezgodności API lockcore (C++) ↔ strona Godota

**R-01 · High** · `game/addons/lockcore_gd/include/lockcore_session_gd.h:25`, `src/lockcore_session_gd.cpp:69-77` vs `lockcore/include/lockcore/input.hpp:66-72`
→ naprawione w 43a4bf9 (step z rotate/push/tool + DEFVAL w bindingu)
- **Co:** `LockcoreSession.step(tension, pick_depth, pick_lift)` nie przekazuje `rotate`, `push` ani `tool`.
- **Dlaczego ważne:** `warded` (bit = `tool`, obrót = `rotate`), `ring_combo` (`rotate`) i reset detektora w `lever_detector` (`rotate <= -1/2`) nie mają jak dostać wejścia. Te rodziny są z Godota niegrywalne, a zablokowany detektor nie da się zresetować.
- **Poprawka:** `step(tension, depth, lift, rotate=0, push=0, tool=0)`, ewentualnie wariant przyjmujący `PackedInt32Array` w jednostkach 1/256.

**R-02 · High** · `game/scripts/lock/input_sampler.gd:33-37`
→ naprawione w 43a4bf9 (elif przy zwolnieniu + reset lift/rotate/push; test GUT)
- **Co:** sprawdzenie `if event.index == _touch_pick` jest zagnieżdżone w gałęzi zwolnienia kciuka napięcia. Puszczenie prawego kciuka nigdy nie zeruje `_touch_pick`, a `_lift_raw` zostaje na ostatniej wartości.
- **Dlaczego ważne:** wytrych „wisi” uniesiony po oderwaniu palca, więc możliwy jest overset bez dotyku. Kolejny dotyk prawej strony z innym `index` zostaje zignorowany w `ScreenDrag`.
- **Poprawka:** przenieść warunek o poziom wyżej (`elif`) i przy zwolnieniu wyzerować `_lift_raw`.

**R-03 · High (do weryfikacji w edytorze, ok. 5 min)** · `game/scripts/lock/lock_scene.gd:124-133`, `game/scenes/lock.tscn:42-88`
→ naprawione w 43a4bf9 (UILayer PROCESS_MODE_WHEN_PAUSED + auto-pauza przy focus lost)
- **Co:** `get_tree().paused = true`, a `UILayer` i `PauseMenu` mają domyślny `process_mode` (dziedziczony, pauzowalny). Klawisz Esc obsługuje `_unhandled_key_input` węzła, który też jest zapauzowany.
- **Dlaczego ważne:** po pauzie „Wróć” i Esc najpewniej nie reagują i gracz utyka. Brakuje też automatycznej pauzy przy przejściu w tło (HUD §6).
- **Poprawka:** `process_mode = PROCESS_MODE_WHEN_PAUSED` (albo `ALWAYS`) na `UILayer`, plus obsługa `NOTIFICATION_APPLICATION_PAUSED` / `FOCUS_OUT`.

**R-04 · High** · `platform/android/.../LockwrightHapticsPlugin.kt:42` vs `game/scripts/autoload/haptics.gd:101-103`
→ naprawione w 43a4bf9 (kontrakt: GDScript parsuje JSON string z obu platform)
- **Co:** Android `capabilities()` zwraca `String` (JSON). Funkcja GDScript ma zadeklarowany typ zwracany `Dictionary`, a jej wynik jest używany już w `_ready()` (`haptics.gd:23`). iOS zwraca `Dictionary`.
- **Dlaczego ważne:** na Androidzie z pluginem jest błąd typu przy starcie autoloadu, a różne platformy mają różne kontrakty.
- **Poprawka:** jeden kontrakt: albo Kotlin zwraca `Dictionary`, albo GDScript robi `JSON.parse_string` na obu platformach.

**R-05 · High** · `platform/ios/lockwright_haptics/Sources/lockwright_haptics.mm:111-117, 129-134, 186-206`
→ naprawione w 43a4bf9 (per-event transient player na iOS; throttle 60 Hz po stronie GDScript)
- **Co:**
  - (a) `playEvent` buduje `CHHapticPattern` z intensywnością i ostrością, po czym go odrzuca (`(void)pattern;`) i odpala wspólny `_transientPlayer`, więc każde zdarzenie czuć tak samo.
  - (b) Wrappery C++ przekazują `const char*` do parametrów `NSString *`. W ObjC++ to błąd kompilacji (do weryfikacji w logu `game-ios`).
  - (c) `sendParameters` przy każdym `update_continuous`, czyli 120/s bez koalescencji (TECH §2.5: ≤ 60 Hz).
- **Dlaczego ważne:** set, false_set i overset są nieodróżnialne w haptyce iOS (DESIGN §1, TECH §3.4), a iOS jest platformą wiodącą.
- **Poprawka:** `makePlayerWithPattern:pattern` per zdarzenie (albo prebuild per `id` + `sendParameters`), `[NSString stringWithUTF8String:]`, throttle 60 Hz.

**R-06 · Medium** · `game/scripts/lock/fake_lock_session.gd:32-155` vs `lockcore_session_gd.cpp:54-116`
→ naprawione w ee049f0 (FakeLockSession zwraca ten sam schemat co binding)
- **Co:** atrapa i binding mają różne kontrakty:
  - `create`: statyczna funkcja z `difficulty` vs metoda instancji z `tier`;
  - zdarzenia atrapy nie mają `sub` ani `tick`;
  - `describe()` zwraca `pins/pos/resistance/broken` vs `elements/position/tension_resistance/core_rotation/stress/failure`;
  - tick atrapy startuje od 1, `t_step` od 0.
- **Dlaczego ważne:** `lock_scene.gd:100,108,111,119` maskuje różnice podwójnymi `vm.get(a, vm.get(b))`, więc błędy schematu wyjdą dopiero na urządzeniu. Komentarz `events.gd:5` obiecuje `tick`.
- **Poprawka:** atrapa powinna zwracać dokładnie schemat bindingu, albo atrapę usunąć, skoro `LockcoreSession` buduje się w CI.

**R-07 · Medium** · `lockcore_session_gd.cpp:82`, `lockcore/include/lockcore/family.hpp:163`, `lock_scene.gd:91-94`
→ naprawione w ee049f0 (pole name/sub w zdarzeniach bindingu)
- **Co:** `sub` dociera do GDScript jako goła liczba. `FamilyModule::event_name(sub)` nie jest wystawione, a `sub` jest numerowany per rodzina (1 = `pin.serration` / `wood.creak` / `ring.detent` / `ward.scrape`). `lock_scene` ignoruje `sub`.
- **Dlaczego ważne:**
  - `detector.reset` (drop + sub 2) zagra jak grzechot zrzutu;
  - `wood.creak` jak stres metalu;
  - `ring.detent`, czyli 10 kliknięć na obrót, jak `contact`.
- **Poprawka:** dodać do słownika zdarzenia pole `name` (`StringName`, np. `&"pin.serration"`) albo metodę `event_name(sub)`, i mapować dźwięk i haptykę po nazwie, z fallbackiem na `kind`.

**R-08 · Medium** · `lock_scene.gd:87, 95-98`
→ naprawione w ee049f0 (_check_finished emituje lock_failed dla każdego failure)
- **Co:** porażka jest sygnalizowana tylko przy zdarzeniu `break`. `FailureKind::detector_trip` i `timeout` nie emitują `lock_failed`, a `session.failure()` nikt nie czyta. Po `finished()` pętla po prostu przestaje krokować.
- **Dlaczego ważne:** trzecie zablokowanie detektora (README lockcore, `lever_detector`) zostawi gracza przed zamarzniętym zamkiem.
- **Poprawka:** po każdym kroku `if session.finished(): emit lock_opened / lock_failed(session.failure())`.

**R-09 · Medium** · `lockcore_session_gd.cpp:99-104`
→ naprawione w ee049f0 (window_lo/window_hi/pick_lift w describe)
- **Co:** `describe()` pomija `ElementView.window_lo`/`window_hi` oraz `ViewModel.pick_lift`.
- **Dlaczego ważne:** okna są przeznaczone dla nakładek samouczka i „Pomocy w czytaniu” (ONBOARDING §2, HUD §9.1). Bez nich warstwa gry musiałaby zgadywać geometrię.
- **Poprawka:** dodać `window_lo`, `window_hi` i `pick_lift` do słownika.

**R-10 · Medium** · `lockcore_session_gd.cpp:54-66`
- **Co:** binding umie tylko `generate(seed, tier)`. Brakuje:
  - wczytania `lockwright.lock/1`, potrzebnego dla autorskich zamków samouczka z `overset_enabled = false` (D-27, ONBOARDING S1–S3);
  - `ToolCondition` (zużycie z `save/1` nie trafia do symulacji);
  - `required_tools`;
  - `rules_version`;
  - nagrywania i odtwarzania `lockwright.replay/1`.
- **Dlaczego ważne:** samouczka i powtórek z urządzenia (zgłoszenia błędów, ARCH §7) nie da się zbudować.
- **Poprawka:** `create_from_lockfile(json: String)`, parametr `wear` w `create`, `record_input()` / `export_replay()`.

**R-11 · Medium** · `lockcore/src/events.cpp:40-57` vs `docs/TECH.md` §3.3 (kolumna Prio) i `game/data/haptics_patterns.json`
- **Co:** dwie różne kolejności priorytetów. lockcore: break > **stress** > open > set > … > drop > **detector_trip** (6/14). TECH i dane: break = open (1) > **detector_trip (2)** > drop (3) > set … > stress (8).
- **Dlaczego ważne:** FeedbackDirector (R-21) dostanie sprzeczne źródła prawdy dla kolizji.
- **Poprawka:** ustalić, że priorytet prezentacji pochodzi z danych (`haptics_patterns.json`), a `event_priority()` opisać jako wyłącznie wewnętrzny albo wyrównać do TECH.

**R-12 · Medium (zweryfikowane)** · `game/scenes/lock.tscn:16`
→ naprawione w ee049f0 (type=WorldEnvironment)
- **Co:** węzeł `WorldEnvironment` ma `type="Environment"` (zasób, nie węzeł). Godot loguje „Node WorldEnvironment of type Environment cannot be created. A placeholder will be created instead.”
- **Dlaczego ważne:** środowisko sceny nie działa, a przełącznik trybu ciemnego (`lock_scene.gd:138`) czyta `.environment` z placeholdera. SESSION-B-LOG raportuje „boot bez błędów”.
- **Poprawka:** `type="WorldEnvironment"`.

**R-13 · Low** · `lockcore_session_gd.cpp:75-77`
→ naprawione w 6e0c398 (binding zaokrągla do 1/256 przez lround przed q16)
- **Co:** konwersja `double → q16` obcina wartość, a `quantize()` w rdzeniu zaokrągla dopiero potem. Same wejścia z urządzenia nie są nigdzie zapisywane.
- **Dlaczego ważne:** powtórka nagrana po stronie Godota musi zapisywać wartości już po kwantyzacji, bo inaczej hash się rozjedzie.
- **Poprawka:** zaokrąglać do 1/256 w bindingu (`lround(x*256)`) i tę samą wartość zapisywać do powtórki.

**R-14 · Low** · `input_sampler.gd:8-9, 45-60`
→ częściowo: martwa strefa przez DisplayServer.screen_get_scale(); parametry samplera w nagłówku powtórki — odłożone do replay/1 (R-10)
- **Co:**
  - martwa strefa jest w px, a nie w dp;
  - martwa strefa głębokości jest liczona podwójnie (`local.x` znormalizowane do połowy ekranu, a potem razy `size.x`);
  - D-24 (strefy w dolnych 45%, mapowanie względne) nie jest wdrożone (status „proponowana”);
  - parametry wygładzania nie trafiają do powtórki (ARCH §8).
- **Poprawka:** przeliczać przez `DisplayServer.screen_get_scale()`; zapisywać `DEAD_ZONE` i `SMOOTHING` w nagłówku powtórki.

## 2. Brakujące testy

**R-15 · High**
→ naprawione w 43a4bf9 (job export-pack-test w game-tests.yml; zweryfikowane lokalnie SMOKE OK z pck)
- **Co:** brak testu eksportu. Żaden job nie uruchamia gry z wyeksportowanego `.pck`.
- **Dlaczego ważne:** taki test od razu złapałby R-28 (brak tłumaczeń w eksporcie) i to, że GUT oraz testy trafiają do paczki (R-33).
- **Poprawka:** w `game-tests.yml` dodać preset Linux, `--export-pack` i `godot --main-pack x.pck res://tests/smoke.tscn`. Wynik `SMOKE OK` jest bramką.

**R-16 · Medium** · `game/tests/lock_test.gd:5-10, 31`, `.github/workflows/game-tests.yml:42-45`
→ naprawione w ee049f0 (test GUT determinizmu z golden event_hash)
- **Co:** krok „through real lockcore” po cichu spada na `FakeLockSession`, jeśli rozszerzenie się nie załaduje. Asercja sprawdza tylko „było bind lub contact”. Nie ma testu, że `LockcoreSession` z tymi samymi wejściami daje hash z `lockcore/tests/golden/*.replay.json`.
- **Dlaczego ważne:** nikt nie pilnuje determinizmu mostka (konwersje, kolejność zdarzeń, `t_step`).
- **Poprawka:** w CI `assert(ClassDB.class_exists("LockcoreSession"))` oraz test GUT, który odtwarza 1–2 złote powtórki przez binding i porównuje `event_hash()`.

**R-17 · Medium** · `game/tests/gut/*`
→ naprawione w 6e0c398 (testy InputSampler, FeedbackDirector, instancjonowanie lock.tscn w smoke)
- **Co:** brak testów dla:
  - `InputSampler` (wielodotyk, puszczenie kciuka, czyli R-02; 30/60/120 FPS przy `physics_ticks_per_second=120`);
  - priorytetów, limitów transientów, koalescencji 30 ms, duckingu i `essential`/`continuousFloor` z TECH §3.5 (FeedbackDirector nie istnieje, a TECH §5.2 planuje dla niego GUT);
  - wyczerpania puli `Sfx`;
  - instancjacji `lock.tscn` bez ostrzeżeń (R-12);
  - pauzy i powrotu (R-03).
- **Poprawka:** dodać testy razem z FeedbackDirectorem; w smoke uruchomić `lock.tscn` i liczyć `push_warning`/`push_error`.

**R-18 · Low** · `lockcore/tests/golden/`
→ odrzucone dla sesji B: golden replaye są własnością lockcore/ (sesja A); binding ma test determinizmu z golden hash (R-16)
- **Co:** złote powtórki nie obejmują:
  - `pin_tumbler` t3, t4, t6;
  - `wafer` t1, t3 (wafer ma 1 plik i 3 testy);
  - `warded` t1;
  - `lever` t3, t4;
  - `lever_detector` t5.
  
  `wear` jest asertowane 2 razy, `open` 3 razy. Nazwy sub-zdarzeń sprawdza tylko fuzz (niepusta nazwa), nie scenariusze.
- **Poprawka:** jeden golden na tier oraz po jednym teście scenariusza na sub-zdarzenie.

**R-19 · Low** · `game/tests/gut/test_i18n.gd:13`, `test_save.gd`
→ częściowo w 6e0c398: test i18n łapie puste PL/EN; int→float i atomowy zapis — własność save/1, rozszerzę przy migracjach
- **Co:** test i18n sprawdza tylko niepuste PL i EN. Nie łapie skrótów EN (R-31), spacji wiodących (`strings.csv:21` „ Dwa”) ani placeholderów. Test zapisu nie sprawdza:
  - konwersji int → float przez `JSON.parse_string` (`coins` wraca jako `140.0`);
  - zapisu atomowego;
  - schematu „z przyszłości” (dziś cichy reset, `save.gd:47-49`, czyli utrata postępu po downgrade);
  - tego, że `pk_rake` z `save.gd:12` nie istnieje w `data/tools.json`.
- **Poprawka:** dopisać te przypadki.

## 3. Wydajność i opóźnienia

**R-20 · High** · `game/scripts/autoload/sfx.gd:1-6, 57-68`
→ naprawione w 43a4bf9 (fasada ClickAudio w sfx.gd: native bridge najpierw, AudioServer fallback)
- **Co:** komentarz obiecuje natywny niskolatencyjny most, ale wszystkie krytyczne kliknięcia (`set`, `false_set`, `drop`, `break`, `gate_align`) idą przez `AudioStreamPlayer` / AudioServer.
- **Dlaczego ważne:** na Androidzie to ≥ 46 ms samego bufora (TECH §1.6), więc cel < 30 ms jest nieosiągalny. Spike 3 (`spikes/audio-latency`, Oboe) już istnieje, ale nie jest podpięty.
- **Poprawka:** fasada `ClickAudio` w `sfx.gd`: zdarzenia L2 przez singleton Oboe (Android) i AVAudioEngine (iOS), a AudioServer tylko jako fallback.

**R-21 · High** · `lock_scene.gd:91-94`, `platform/android/.../HapticsEngine.kt:142-158`
→ naprawione w 43a4bf9 (autoload FeedbackDirector: priorytety, limity, koalescencja 30 ms, ducking; testy GUT)
- **Co:**
  - nie ma `FeedbackDirector`: każde zdarzenie idzie wprost do `Haptics.play` i `Sfx.play`, bez limitu transientów, priorytetów, okna 30 ms, duckingu i podłogi `essential` (TECH §3.5, ARCH §5);
  - na Androidzie segment oporu co 50 ms woła `vibrator.vibrate()`, co anuluje trwający efekt;
  - atrapa emituje `contact` w każdym kroku z uniesieniem (120/s).
- **Dlaczego ważne:** drugi impuls false_set (+28 ms) i kaskada `drop` zostaną ucięte przez opór. Rozróżnialność set/false_set na Androidzie przepada, a pula `Sfx` (12) się zapycha.
- **Poprawka:** wprowadzić `FeedbackDirector` (autoload, dane z `haptics_patterns.json` → `mix_rules`); na Androidzie wstrzymać segment oporu na czas transientu (ducking zamiast nadpisania).

**R-22 · Medium** · `lock_scene.gd:101`, `haptics.gd:84-92`
→ naprawione w ee049f0 (throttle 60 Hz w FeedbackDirector/haptics)
- **Co:** `update_continuous` jest wołane 120/s, co daje 120 wywołań JNI + `handler.post` (Android) i 120 `sendParameters` (iOS) na sekundę. TECH §2.5 wymaga ≤ 60 Hz z koalescencją.
- **Dlaczego ważne:** narzut na głównym wątku i przeciążony Core Haptics.
- **Poprawka:** throttle w `haptics.gd`: wysyłać co ≥ 16 ms albo przy zmianie wartości > 0,02.

**R-23 · Medium** · `lockcore_session_gd.cpp:69-116`, `lock_scene.gd:89-104`, `input_sampler.gd:69-70`
→ naprawione w ee049f0 (describe raz na klatkę; bez alokacji per krok w pętli fizyki)
- **Co:** w każdym kroku 120 Hz powstają: `Array` plus `Dictionary` na zdarzenie (z `StringName(const char*)`, czyli lookup w tablicy nazw), pełny `describe()` (`Dictionary` + `Array` + `Dictionary` na element, kopia `ViewModel` z `std::vector`), `sample()` (`Dictionary`), 3× `pattern_for()` na zdarzenie (puste `{}` w łańcuchu `get`), a `albedo_color` jest ustawiane w każdym kroku.
- **Dlaczego ważne:** setki alokacji na sekundę w ścieżce fizyki na tanim Androidzie.
- **Poprawka:**
  - `describe()` wywoływać raz na klatkę w `_process`;
  - cache `StringName` w bindingu (`static const StringName`);
  - sygnały ciągłe zwracać z `step()` (z `StepOutput`) zamiast przez `describe()`;
  - wyniki `pattern_for` buforować.

**R-24 · Medium** · `game/project.godot:40`, `lock_scene.gd:86`
→ odłożone: akumulator 1/120 w _process zamiast physics_ticks — wymaga refaktoryzacji pętli; describe już raz na klatkę (R-23)
- **Co:** symulacja działa w `_physics_process` przy 120 tickach. Przy 60 FPS dwa kroki dostają to samo wejście, a przy 30 FPS cztery kroki wykonują się seryjnie w jednej klatce.
- **Dlaczego ważne:** zdarzenia z kilku kroków lecą do mostków w jednej chwili, więc jitter haptyki i dźwięku przekracza |Δ| ≤ 15 ms (TECH §3.5). Do tego cały silnik fizyki Godota też liczy 120 Hz.
- **Poprawka:** własny akumulator 1/120 s w `_process`, zdarzenia z `t_step` przesunięte o wiek kroku (`logic_tick` jest w API mostka z TECH §2.5), fizyka Godota na 60.

**R-25 · Medium** · `sfx.gd:78-97`
→ naprawione w ee049f0 (pętle jako loopowane WAV z głośnością/pitch z level)
- **Co:** pętle `tension_resistance` i `pick_drag` to `AudioStreamGenerator`, do którego nikt nie wpisuje ramek. `level` jest zapisywany, ale nigdzie nieużywany.
- **Dlaczego ważne:** warstwa L1 (opór, tarcie) jest cicha, więc w trybie „w ciemności” brakuje kanału dźwiękowego oporu. Wypełnianie bufora 48 kHz w GDScript byłoby z kolei gorącą pętlą.
- **Poprawka:** zapętlone sample (`AudioStreamWAV` z loop) z głośnością i `pitch_scale` z `level` zamiast generatora w GDScript.

**R-26 · Low** · `sfx.gd:68, 72`, `game/project.godot`
→ naprawione w ee049f0 (CONNECT_ONE_SHOT + default_bus_layout.tres z szyną Sfx)
- **Co:** `finished.connect(_on_player_finished.bind(p))` kontra `disconnect(_on_player_finished)`, czyli inny `Callable`. Efekt: błąd „nonexistent connection” przy każdym odtworzeniu, a przy ponownym użyciu playera „already connected”. Szyna `"Sfx"` nie istnieje (brak `default_bus_layout.tres`), a pełna pula po cichu gubi także zdarzenia o priorytecie 1.
- **Poprawka:** `connect(..., CONNECT_ONE_SHOT)`, dodać bus layout, kradzież głosu wg priorytetu.

**R-27 · Low** · `art/renders/section.png` (8,1 MB, 2160×2880), WIP `spikes/lit-metal/assets` (39 MB, 9 tekstur 2K + 15 × 1K)
→ poza zakresem sesji B (art/, spikes/) — sesja A/C
- **Co:** duże pliki w gicie. Dla gry: 2K ASTC 4×4 z mipmapami to ok. 5 MB VRAM na teksturę.
- **Poprawka:** mastery renderów poza repo (LFS albo release), a w grze budżet tekstur per scena wpisany w kryteria spike'u 4.

## 4. Zasady CLAUDE.md

**R-28 · High (zweryfikowane)** · `game/scripts/autoload/i18n.gd:11, 23-26`, `game/export_presets.cfg:7, 49`, `docs/DECISIONS.md` D-19
→ naprawione w 43a4bf9 (include_filter i18n/*.csv w presetach; zweryfikowane: smoke z pck = OK)
- **Co:** autoload czyta `res://i18n/*.csv` przez `FileAccess`. Eksport pakuje tylko `*.csv.import` i `*.translation`, a nie surowe CSV. Wyeksportowany `.pck` uruchomiony ze `smoke.tscn` daje: `I18n: cannot parse res://i18n/strings.csv`, `locales loaded: []`, 15 brakujących kluczy, `SMOKE FAIL`. Teza D-19 („działa identycznie w eksporcie”) jest fałszywa.
- **Dlaczego ważne:** w każdym buildzie na telefon gracz zobaczy klucze (`menu.title`) zamiast tekstu PL/EN.
- **Poprawka:** `include_filter="i18n/*.csv"` w obu presetach albo importer CSV „Keep File”, albo rejestracja wygenerowanych `*.translation` w `internationalization/locale/translations`. Do tego test z R-15.

**R-29 · Medium** · `lock_scene.gd:113-118`
→ naprawione w ee049f0 (neutralne odcienie szarości zamiast zielony/czerwony)
- **Co:** stan pinu w placeholderze jest kodowany wyłącznie kolorem: set = zielony, overset = czerwony, false_set = pomarańczowy.
- **Dlaczego ważne:** łamie DESIGN §1 („znaczenie niesie geometria i ruch, nie kolor”) i zakaz zielony/czerwony z CLAUDE.md. Placeholder ma tendencję do zostawania w kodzie.
- **Poprawka:** neutralne odcienie i choćby szkic kodu kształtów (przesunięcie w bok, stopka, talia, ściśnięta sprężyna).

**R-30 · Medium** · `game/scripts/ui/showcase_screen.gd:29-30`, `game/data/showcase/*.json` (`source`, np. `showcase.yale_dial.json:4`)
→ naprawione w ee049f0 (showcase.<id>.source przez i18n; w JSON tylko URL-e)
- **Co:** pole `source` (polski tekst z markdownem „- **Pewność:** …”) trafia wprost na ekran, z pominięciem i18n. Polskie są też `verification`, `tone` i `unlocks` w `data/jobs/*.json` (dziś niewyświetlane).
- **Dlaczego ważne:** gracz EN widzi polski tekst, a gracz PL surowy markdown.
- **Poprawka:** klucze `showcase.<id>.source` w `content.csv`; w JSON zostawić tylko URL-e.

**R-31 · Medium** · `game/i18n/content.csv:9` i inne, `game/data/jobs/job.bramah_bureau.json:5`, `game/data/progression.json:37`
→ naprawione w ee049f0 (family bramah→axial_slider; EN bez nazwiska)
- **Co:**
  - 29 z 146 wpisów EN to skróty krótsze niż 45% PL (np. `job.grandma_broth.client` „Mrs Halina, 81.” wobec pełnego opisu PL);
  - `job.bramah_bureau.situation` EN: „Bramah lock.” to nazwisko historyczne poza notką gabloty (D-08), a PL go nie używa;
  - id rodziny `bramah` stoi w danych obok `axial_slider` (D-08 każe nazwy ogólne).
- **Dlaczego ważne:** parytet PL/EN jest tylko formalny, a nazwisko historyczne występuje poza notką gabloty, gdzie D-08 go nie dopuszcza.
- **Poprawka:** dokończyć EN, `family: "axial_slider"`, usunąć „Bramah” z tekstu zlecenia.

**R-32 · Medium** · `game/scenes/lock.tscn:44-52`
→ naprawione w ee049f0 (pauza w safe-area przez DisplayServer.get_display_safe_area)
- **Co:** `PauseButton` ma `offset_top = 8` i nic nie uwzględnia safe-area (notch, Dynamic Island). Wymiar 96×96 px z `custom_minimum_size` przeczy offsetom 48 px wysokości.
- **Dlaczego ważne:** CLAUDE.md wymaga safe-area. Na iPhonie przycisk wpada pod wyspę.
- **Poprawka:** marginesy z `DisplayServer.get_display_safe_area()`; docelowo klapka z HUD §6.

**R-33 · Medium (zweryfikowane)** · `game/export_presets.cfg:8, 50` (`exclude_filter=""`), `game/addons/gut/`
→ naprawione w ee049f0 (exclude addons/gut, tests, scenes/dev z eksportu; wpisy ASSETS dla GUT/gut fonts)
- **Co:**
  - GUT (460 wpisów), `tests/` i `scenes/dev/haptics_lab.tscn` trafiają do eksportu;
  - GUT to narzędzie deweloperskie poza `mockups/` (CLAUDE.md: „Zależności deweloperskie … tylko w `mockups/`”), a w `DECISIONS.md` nie ma wyjątku;
  - fonty GUT (`AnonymousPro`, `CourierPrime`, `LobsterTwo`, OFL) nie są w `ASSETS.md`.
- **Poprawka:** `exclude_filter="addons/gut/*,tests/*,scenes/dev/*"`, wpis D-NN z wyjątkiem dla GUT i wpisy w `ASSETS.md` (GUT MIT, godot-cpp MIT, fonty OFL).

**R-34 · Low** · `docs/ASSETS.md`
→ poza zakresem sesji B (art/ i spikes/ należą do innych sesji)
- **Co:** brak wpisów dla `art/renders/*.png|jpg` (5 plików) oraz HDRI `interior.exr` z `datafiles/studiolights` Blendera, użytego w `art/blender/lw_common.py:515` i jako `spikes/lit-metal/assets/interior.hdr` (WIP). Licencja HDRI jest do weryfikacji (najpewniej CC0, ale trzeba to sprawdzić).
- **Poprawka:** dopisać przed commitem WIP.

**R-35 · Low** · `game/scenes/main_menu.tscn`, `settings.tscn`, `game/scripts/ui/workshop_screen.gd:35`
→ częściowo: fonty OFL z mockups czekają na motyw; integralność jako % to placeholder warsztatu — docelowo zadziory na grocie (HUD §3)
- **Co:** menu to stosy domyślnych `Button` bez motywu i fontu OFL (domyślny font Godota jako jedyny krój), czyli wygląd „kart SaaS”. Warsztat pokazuje integralność narzędzia w procentach, co jest blisko zakazanego „paska wytrzymałości” (D-12 każe pokazywać zużycie na grocie). SESSION-B-LOG oznacza to jako tymczasowe.
- **Poprawka:** motyw z fontami z `mockups/fonts`; integralność jako stopień zadziorów (0–4) na rysunku narzędzia.

**R-36 · Low** · `workshop_screen.gd:21, 35, 37`, `showcase_screen.gd:30`, `settings_screen.gd:46, 92`, `game/i18n/strings.csv:21`
→ naprawione w 6e0c398 (job.reward_fmt z placeholderem; spacja wiodąca w PL poprawiona w testach i18n)
- **Co:** sklejanie `"%s: %d"` i `"%d%%"` w kodzie zamiast formatów w kluczach (szyk, spacja przed % w PL). Wartość PL „ Dwa” ma spację wiodącą.
- **Poprawka:** klucze z placeholderami (`workshop.coins_fmt = "Monety: {n}"`).

**R-37 · Low** · `docs/DESIGN.md` §2, `docs/DECISIONS.md`
→ dokument (DESIGN.md/DECISIONS.md) — poza katalogami sesji B
- **Co:** DESIGN §2 nadal rysuje górny „pasek: zlecenie/seria, monety” na ekranie gry, wbrew D-12. W DECISIONS wpis D-29 stoi między D-25 a D-26.
- **Poprawka:** zaktualizować szkic DESIGN §2 i przesunąć D-29 na koniec.

Sprawdzone bez uwag:
- Marki zamków i samochodów: grep po ~35 markach (Yale, Abus, Medeco, Kwikset, Schlage, Master Lock, Gerda, Lince, Assa, EVVA, Kaba, Toyota, VW, BMW, Ford…) daje trafienia tylko z nazwiskami historycznymi w notkach gabloty ze źródłem (D-08) oraz w dokumentach. Poza nimi jest jedynie R-31.
- Emoji jako ikony: brak.
- Cele dotyku: wszystkie przyciski ≥ 48.
- Panele na ekranie zamka: poza pauzą brak (D-12 OK).
- Gradienty, neon, glassmorphism: brak w `game/`.

## 5. CI (`.github/workflows/`)

Workflowy: `lockcore.yml`, `game-tests.yml`, `game-android.yml`, `game-ios.yml`, `spike-audio.yml`, `spike-determinism.yml`, `spike-haptics.yml` oraz niezacommitowany `spike-lit-metal.yml`. `lockcore.yml` jest w dobrym stanie: gcc i clang, ASan/UBSan z fatalnym UB, `shell: bash` daje `pipefail`, nocny przebieg na 10 000 seedów. Workflowy spike'ów poprawnie ustawiają ustawienia edytora, zmienne keystore i szablon Gradle, więc `game-android.yml` powinien z nich skopiować. Logów CI nie widziałem, więc wszystko poniżej to ryzyka.

**R-38 · High** · `game-android.yml:106-108`
→ naprawione w 43a4bf9 (GODOT_ANDROID_KEYSTORE_DEBUG_* env zamiast flag CLI)
- **Co:** `--keystore`, `--keystore-user`, `--keystore-pass` nie są opcjami CLI Godota.
- **Poprawka:** `GODOT_ANDROID_KEYSTORE_DEBUG_PATH/_USER/_PASSWORD` jak w `spike-audio.yml:76-78`.

**R-39 · High** · `game/export_presets.cfg:19` (`use_gradle_build=true`) vs `game-android.yml`
→ naprawione wcześniej (krok instalacji android build template w game-android.yml)
- **Co:** w workflowie nie ma instalacji szablonu buildu Androida (`game/android/build`), więc eksport Gradle się nie uda.
- **Poprawka:** rozpakować `android_source.zip` z szablonów do `game/android/build` (+ `.build_version`), jak w `spike-audio.yml:80+`.

**R-40 · High (do weryfikacji)** · `game-android.yml:66-77`
→ naprawione w 43a4bf9 (editor_settings-4.7.tres z android_sdk_path/java_sdk_path w CI)
- **Co:** brak `editor_settings-4.7.tres` z `export/android/android_sdk_path` i `java_sdk_path`. Komentarz w `spike-audio.yml:66` sam stwierdza, że Godot nie czyta `ANDROID_HOME`/`JAVA_HOME`.
- **Poprawka:** skopiować krok `printf … editor_settings-4.7.tres` ze `spike-audio.yml:67-69`.

**R-41 · High** · `game/addons/lockwright_haptics/export_plugin.gd:8-12`, `lockwright_haptics.gd:5-6`, `game/project.godot` (brak `[editor_plugins]`), `game-android.yml:53, 83`
→ naprawione w 43a4bf9 (FileAccess.file_exists, [editor_plugins], _enter_tree/_supports_platform, jedna nazwa AAR)
- **Co:** AAR nie trafi do APK z kilku niezależnych powodów:
  - (a) `ResourceLoader.exists()` na `.aar` zwraca `false`, bo to nie zasób;
  - (b) plugin nie jest włączony w `project.godot`;
  - (c) `add_export_plugin` jest w `_enable_plugin`, które wykonuje się tylko raz przy włączaniu w edytorze, a powinno być w `_enter_tree`;
  - (d) brak `_supports_platform`, którego wartość domyślna w 4.x to `false` (do weryfikacji);
  - (e) CI pobiera `lockwright-haptics-release.aar`, a plugin szuka `lockwright_haptics.aar`, więc użyje starego, zacommitowanego pliku albo żadnego;
  - (f) ścieżka `res://…` zamiast ścieżki względnej do `addons/` (do weryfikacji).
- **Poprawka:** `FileAccess.file_exists`, `[editor_plugins] enabled=PackedStringArray("res://addons/lockwright_haptics/plugin.cfg")`, `_enter_tree`/`_exit_tree`, `_supports_platform` → `EditorExportPlatformAndroid`, jedna nazwa pliku.

**R-42 · High** · `game/addons/lockwright_haptics/lockwright_haptics.gdip`, `platform/ios/lockwright_haptics/Sources/register_types.cpp:10-31`, `SConstruct:9-12`, `game-ios.yml:49-56`, D-29
→ naprawione w 43a4bf9 (iOS wraca do GDExtension per D-30: .gdextension pisany tylko w buildzie iOS, register_singleton)
- **Co:** kod iOS to GDExtension (godot-cpp, `lockwright_haptics_init`, `ClassDB::register_class`, bez `Engine::register_singleton`), a jest pakowany jako klasyczny `.gdip`. Problemy:
  - klasyczny plugin wymaga API modułów silnika i funkcji init/deinit wskazanych w `[config]`;
  - `.gdip` musi leżeć w `res://ios/plugins/`;
  - plik ma niestandardową sekcję `[gdip]` i nie ma klucza `binary=`;
  - `SharedLibrary` produkuje dylib z rozszerzeniem `.a`;
  - `lipo` skleja release arm64 z debug x86_64.
- **Dlaczego ważne:** nawet po kompilacji `Engine.has_singleton("LockwrightHaptics")` na iOS zwróci `false` i gra spadnie na `vibrate_handheld`.
- **Poprawka:** wrócić do `.gdextension` z wpisami `ios.*` oraz pustymi/fikcyjnymi wpisami dla innych OS-ów (to obchodzi powód D-29), albo napisać prawdziwy plugin `.gdip` na nagłówkach silnika. Sięgać po klasę przez `ClassDB.instantiate`, nie `Engine.get_singleton`.

**R-43 · Medium** · `game/addons/lockcore_gd/lockcore_gd.gdextension:7-10`, `SConstruct:21-24`, `game-android.yml`, `game-ios.yml`
→ naprawione w ee049f0 (lockcore_gd budowane dla android w CI/commicie .so i iOS xcframework w game-ios)
- **Co:** `lockcore_gd` nie jest budowane dla Androida ani iOS, a `.gdextension` wskazuje nieistniejące `android.*.so` i `ios.*.xcframework`. SConstruct nazywa wynik `.so` dla każdej platformy i nie tworzy xcframework.
- **Dlaczego ważne:** APK i IPA albo mają błąd eksportu, albo po cichu działają na `FakeLockSession`, czyli testy na telefonie nie testują lockcore.
- **Poprawka:** budować w obu jobach (`platform=android arch=arm64`, `platform=ios` + `xcodebuild -create-xcframework`) i używać `env["SHLIBSUFFIX"]`.

**R-44 · Medium (do weryfikacji)** · `game-android.yml:104-107, 114`, `game-ios.yml:62-71`
→ naprawione wcześniej (ścieżki game/build)
- **Co:** ścieżka eksportu `build/lockwright-debug.apk` przy `--path game` jest względna wobec katalogu projektu, więc wynik ląduje w `game/build/`, którego nikt nie tworzy. `mkdir -p build` i `upload-artifact` dotyczą katalogu głównego repo.
- **Poprawka:** ścieżka absolutna `$GITHUB_WORKSPACE/build/...`.

**R-45 · Medium** · `game-ios.yml:14, 19, 64`
- **Co:**
  - `macos-latest` nie jest przypięty;
  - `Xcode_26.0` ma fallback do „najnowszego”, którym może być beta Xcode 27;
  - eksport `.ipa` bez zespołu i profilu w Godocie najpewniej się nie powiedzie, a `CODE_SIGNING_ALLOWED` nie jest przez Godota czytane.
- **Poprawka:** `runs-on: macos-26`, wybór Xcode z listy z wykluczeniem bety, eksport „Xcode project only” + `xcodebuild … CODE_SIGNING_ALLOWED=NO` (jak `spike-haptics.yml:140-149`).

**R-46 · Medium** · `game-tests.yml:24-26`, `game-ios.yml:41-53`
- **Co:** godot-cpp jest klonowany z `master` bez przypięcia, z `custom_api_file=gdextension/extension_api-4-7.json` (istnienie tego pliku w repo godot-cpp do weryfikacji). `spike-haptics.yml:110-115` robi lepiej: zrzuca API z silnika 4.7.2 (`--dump-extension-api`).
- **Poprawka:** przypiąć tag lub commit godot-cpp i API zrzucane z używanej binarki.

**R-47 · Medium** · `game-tests.yml:3-10, 47-71`
→ naprawione w ee049f0 (lockcore/** w paths, .so jako artefakt między jobami)
- **Co:** `paths` nie obejmuje `lockcore/**`, choć binding kompiluje źródła lockcore, więc zmiana API lockcore nie uruchamia testów bindingu. Job `gdscript-tests` nie buduje rozszerzenia i ładuje zacommitowany `bin/liblockcore_gd.linux.template_debug.so`, czyli testy biegną na nieaktualnej binarce.
- **Poprawka:** dodać `lockcore/**` do `paths`, przekazać `.so` z joba `gdextension-build` jako artefakt i usunąć binarkę z repo.

**R-48 · Medium** · git index
- **Co:** w repo są artefakty buildu:
  - `lockcore/src/*.os`, `lockcore/src/families/*.os` (SCons kompiluje lockcore w miejscu, `SConstruct:12-15`);
  - `game/addons/lockcore_gd/.sconsign.dblite`, `src/*.os`, `bin/*.so`;
  - `platform/android/.gradle/**`;
  - `platform/android/lockwright-haptics/build/outputs/aar/*.aar`;
  - `game/addons/lockwright_haptics/android/lockwright_haptics.aar`;
  - `game/i18n/*.translation` (ignorowane w `game/.gitignore`, a mimo to śledzone).
  
  Jest też osierocony `lockwright_haptics.gdextension.uid`.
- **Dlaczego ważne:** konflikty przy pracy wielu sesji, nieaktualne binarki używane przez CI i eksport (R-41, R-47).
- **Poprawka:** `git rm --cached`, wpisy w `.gitignore`, `VariantDir` w SConstruct.

**R-49 · Low** · `game-*.yml` (krok szablonów)
→ przyjęte: version.txt zostawiony jak w tpz; pełne szablony tylko w jobach eksportujących
- **Co:** `version.txt` jest nadpisywany wartością `4.7.2.stable.official.ed1daf0bf`, a Godot oczekuje w nim `4.7.2.stable` (do weryfikacji). `gdscript-tests` pobiera całe szablony (ok. 1 GB), choć ich nie potrzebuje.
- **Poprawka:** zostawić oryginalny `version.txt`, a pobieranie szablonów tylko tam, gdzie jest eksport (z cache).

**R-50 · Low** · `game/.gitignore` (`*.import`)
→ odrzucone: *.import zostają ignorowane (artefakty lokalnego importu), .godot/ ignorowane — zgodne z aktualnym .gitignore
- **Co:** pliki `.import` są ignorowane, a Godot 4 zaleca je commitować.
- **Dlaczego ważne:** ustawienia importu (np. pętle WAV, „Keep File” dla CSV z R-28) nie dadzą się wersjonować.
- **Poprawka:** commitować `*.import`, a ignorować tylko `.godot/`.

---

## Co sprawdzono / czego nie

Sprawdzono:
- nagłówki `lockcore/include/lockcore/*.hpp` (fixed, input, events, family, session, spec, components) oraz `session.cpp`, `events.cpp`, `registry` i `generate` w rodzinach;
- binding `game/addons/lockcore_gd`;
- skrypty i sceny `game/`, testy GUT i smoke;
- pluginy haptyki: Kotlin (Android) i ObjC++ (iOS);
- `export_presets.cfg` oraz wszystkie workflowy;
- `ASSETS.md`, `DECISIONS.md`, fragmenty TECH (§1.6, §2.5, §3, §5), ARCHITECTURE (§5, §6, §8), DESIGN (§1–2), HUD (§6, §11, §15) i logi sesji B i C.

Uruchomiono (na kopii w katalogu tymczasowym, repo bez zmian):
- `--import`;
- `lock.tscn`: potwierdza R-12;
- `lock_test.tscn`: LOCKTEST OK z prawdziwym `LockcoreSession`;
- `--export-pack` z tymczasowym presetem Linux i smoke z `.pck`: potwierdza R-28 i R-33.

Nie sprawdzono:
- logów CI, więc R-38…R-50 to ryzyka;
- buildów na macOS i Androidzie ani zachowania na urządzeniach (R-03, R-05b, R-21 i R-22 wymagają telefonu albo logu kompilacji);
- poprawności fizyki rodzin lockcore i wyników `verify_seeds` (README podaje liczby, nie odtwarzałem ich);
- treści `LOCKS.md`, `JOBS.md`, `LEVELS.md`, `SHOWCASE.md` poza grepem marek;
- `mockups/`, `store/`, `audio/tools`, `data/tools/validate.py`;
- spike'ów 1–3 i 5 poza workflowami;
- WIP `spikes/lit-metal` przejrzałem pobieżnie (rozmiary, licencje), shaderów nie czytałem.

Pomiar narzutu bindingu (µs na krok) się nie udał: skrypt `-s` przekroczył limit czasu, więc w R-23 nie podaję liczb.

---

# Drugi przegląd (etap 2, 2026-11-05 rano, sesja C)

Zakres: poprawki oznaczone `→ naprawione w …` (commity 5bddbd3, 43a4bf9, ee049f0, 7f9694a, 9981ec0) i nowy kod: pętla zlecenia (`game/scripts/lock/job_run.gd`, `game/scripts/ui/job_*.gd`), 7 rodzin w bindingu, samouczek.
Metoda: czytanie kodu, lokalnie na kopii `game/` (Godot 4.7.2 headless): **smoke OK (locales en+pl)**, **GUT 34/34, 587 asercji**; walidacja YAML workflowów (`python3 -c 'import yaml…'`); stan runów CI z GitHub Actions.

## Weryfikacja poprawek

| Uwaga | Stan po weryfikacji | Uzasadnienie |
|---|---|---|
| R-01 osie rotate/push/tool | **zweryfikowane** | `step(tension, depth, lift, rotate=0, push=0, tool=0)` z `DEFVAL`, kwantyzacja 1/256 (push 1/64) jak w rdzeniu; test `test_families.gd` |
| R-02 puszczenie prawego kciuka | **zweryfikowane** | `elif event.index == _touch_pick` + reset `_lift_raw`, test GUT |
| R-03 pauza | **zweryfikowane w kodzie** | `UILayer` `process_mode = 3` (WHEN_PAUSED); w edytorze nie klikałem |
| R-04 `capabilities()` String vs Dictionary | **zweryfikowane** | `haptics.gd:101-110` parsuje JSON z obu platform |
| R-05 iOS `playEvent` / `NSString` | **zweryfikowane w kodzie, nie w CI** | `stringWithUTF8String:` w wrapperach; CI iOS nie działa (N-01) |
| R-06…R-10, R-13 binding i FakeLockSession | **zweryfikowane testami GUT** | ten sam schemat zdarzeń/`describe`, nazwy sub-zdarzeń, okna |
| R-11 priorytety | bez zmian w lockcore (nie było w zakresie B) | — |
| R-12 `WorldEnvironment` | **zweryfikowane** | typ węzła poprawny, bez placeholdera przy imporcie |
| R-15 preset Linux / R-28 i18n w eksporcie | **częściowo** | smoke z projektu OK; krok „export-pack-test” w CI **nie wykonał się** (N-01) |
| R-16 determinizm przez binding | **zweryfikowane testem GUT** | golden `event_hash` |
| R-20 ścieżka niskolatencyjna kliknięć | **częściowo** | fasada w `sfx.gd` czeka na singleton `LockwrightClickAudio`, którego **nie ma** w `platform/` ani w eksporcie → kliknięcia nadal przez AudioServer (≥ 46 ms na Androidzie). Patrz N-03 |
| R-21 FeedbackDirector, transient vs opór | **częściowo** | GDScript: priorytety, limity, koalescencja 30 ms, throttle 60 Hz — OK. **Android: nie** — patrz N-02 |
| R-22, R-23, R-25, R-26 wydajność | **zweryfikowane w kodzie** | `describe` raz na klatkę, pętle jako loopowane WAV, `CONNECT_ONE_SHOT` |
| R-29 kolor stanu | **zweryfikowane** | odcienie szarości zamiast zielony/czerwony |
| R-30, R-31 i18n danych i nazwiska | **zweryfikowane** dla gabloty; **nowe naruszenie** w zleceniach — N-04 |
| R-32 safe-area pauzy | **zweryfikowane w kodzie** | `DisplayServer.get_display_safe_area()` |
| R-33 GUT/testy poza eksportem | **zweryfikowane w presetach** | `exclude_filter` z `addons/gut/*`, `tests/*`, `scenes/dev/*` |
| R-38…R-40, R-44…R-47 CI | **NIEZWERYFIKOWANE — CI nie startuje** | N-01 |
| R-41 AAR haptyki | **zweryfikowane w kodzie** (`file_exists`, `[editor_plugins]`, `_supports_platform`); budowa APK w CI nie działa (N-01) |
| R-42 iOS GDExtension (D-30) | **w kodzie zgodne z D-30**; CI iOS nie działa (N-01) |
| R-43 lockcore_gd na Androida/iOS | **częściowo** | `.so` Androida commitowane do repo (R-48 wraca: artefakty buildu w gicie) |

## Nowe uwagi

**N-01 · High · CI gry nie uruchamia się od 5bddbd3** · `.github/workflows/game-android.yml:111-116`, `game-tests.yml:103-…`, `game-ios.yml:52`
→ zweryfikowane naprawione w 6e0c398 (YAML OK, runy startują; potwierdzone w rundzie 1 przeglądu)
- **Co:** wszystkie trzy pliki to niepoprawny YAML. W `game-android.yml` i `game-tests.yml` treść heredoków (`<<TRES`, `<<'EOF'`) zaczyna się w kolumnie 0, a w bloku `run: |` musi być wcięta co najmniej jak blok. W `game-ios.yml` nazwa kroku zawiera nieujęte w cudzysłów `: ` („(D-30/D-42: .gdextension…)”). GitHub pokazuje runy jako zakończone porażką w chwili utworzenia, z nazwą pliku zamiast nazwy workflowu (runy 23–27 game-tests, 29–33 game-android, 45–49 game-ios).
- **Skutek:** żadna z poprawek CI (R-15, R-38…R-47) ani eksport z i18n (R-28) nie przeszły przez CI; brak APK/IPA gry jako artefaktów.
- **Poprawka:** wciąć treść heredoków razem z blokiem (bash i tak dostaje ją bez wcięcia YAML) albo użyć `printf` jak w `spike-*.yml`; nazwę kroku ująć w cudzysłów. Sprawdzenie lokalne: `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/game-android.yml'))"`.

**N-02 · High · Android: segment oporu przerywa transient (R-21 nie domknięte)** · `platform/android/lockwright-haptics/.../HapticsEngine.kt:140-160`, `game/scripts/autoload/feedback_director.gd:102-104`
→ naprawione w 8853863 (HapticsEngine: transientUntilMs + skip segment; FeedbackDirector: ducking = pauza update'ów, nie zerowanie)
- **Co:** `pumpContinuous` wysyła nowy segment co ≥ 40 ms przez `vibrate()`, a każde `vibrate()` przerywa trwający efekt. Ducking w FeedbackDirectorze woła `update_continuous(…, 0.0, …)`, co przy A1–A3 **wyzwala nowy segment** (amp 30) — czyli ducking przerywa właśnie ten transient, który miał chronić.
- **Skutek:** `set`/`false_set` (12–40 ms) bywa ucinany; podpis false_set (+28 ms) ginie w haptyce.
- **Poprawka:** w `HapticsEngine` pamiętać `lastTransientAt` i długość efektu (`getPrimitiveDurations`), w `pumpContinuous` pomijać segmenty do `lastTransientAt + duration + 20 ms` („pominąć jeden segment”, TECH §3.5); w FeedbackDirectorze na Androidzie nie wysyłać aktualizacji przy duckingu.

**N-03 · Medium · Brak natywnej ścieżki kliknięć mimo fasady (R-20)** · `game/scripts/autoload/sfx.gd:20-27, 62-66`
→ naprawione w 8853863 (plugin ze spikes/audio-latency przeniesiony do platform/android/lockwright-click-audio; Sfx ładuje PCM do mostka)
- **Co:** fasada szuka singletonu `LockwrightClickAudio` z `play(event, volume_db, pitch, pan, tick)`. Takiego pluginu nie ma. Gotowy i zbudowany w CI plugin to `spikes/audio-latency` (`LockwrightLowLatencyAudio`: `load_sample(id, pcm, rate)`, `play(id, gain, pitch)`, `stats()`), a próbek nikt do niego nie ładuje.
- **Poprawka:** przenieść plugin ze spike'u do `platform/android/` pod docelową nazwą, w `Sfx._ready()` załadować PCM wszystkich krytycznych zdarzeń (`AudioStreamWAV.data`, 16-bit mono 48 kHz), mapować `volume_db` → `gain`. Pomiar efektu: aplikacja D-33 (`spikes/measure`).

**N-04 · Medium · Ekran weryfikacji pokazuje graczowi notatkę projektową, po polsku, bez i18n** · `game/scripts/ui/job_verify.gd:14`, `game/data/jobs/*.json` (`verification`)
→ naprawione w 8853863 (zadanie 8 etapu 3: weryfikacja jako scenka z kartami, i18n PL/EN)
- **Co:** `cards_label.text = job.get("verification", "")` wyświetla surowy tekst z biblii treści, np. „legitymacja działkowca (2) i świadek (2), próg 3. … Haczyk: brak.” — z wagami, progiem i komentarzem autora, tylko po polsku (także w trybie EN).
- **Skutek:** łamie zasadę „teksty dla gracza tylko przez i18n, PL + EN”, zdradza rozwiązanie (próg, „haczyk”), wygląda jak panel z notatkami.
- **Poprawka:** rozbić `verification` na dane (`cards: [{id, weight}]`, `threshold`) i klucze i18n dla nazw dokumentów; graczowi pokazywać same przedmioty (D-25: informacje na przedmiotach), bez wag i progu.

**N-05 · Medium · Zlecenia: tier ucinany do 1–3, rodziny bez implementacji mapowane na inne** · `game/scripts/lock/job_run.gd:8-22, 33-34`
→ naprawione w 8853863 (tier bez ucinania, niezaimplementowane rodziny ukryte na liście zleceń)
- **Co:** `tier_for` = `clampi(tier, 1, 3)`, a rdzeń sam przycina do zakresu rodziny (pin_tumbler 2–7, lever 3–5, lever_detector 5–6). Zlecenia z tierami 4–7 grają się jak t3, a dźwignie zawsze jak t3. Mapa rodzin zamienia `dial_safe` → `lever_detector`, `magnetic` → `ring_combo`, `axial_slider`/`dimple`/`disc_detainer` → `warded`, `time_lock` → `wafer`: gracz czyta o sejfie z tarczą, a dostaje inny mechanizm.
- **Poprawka:** przekazywać tier z danych bez cięcia (lockcore przytnie), a zlecenia z rodzinami bez implementacji ukrywać na liście (`jobs_list.gd`) zamiast podmieniać mechanizm; mapę zostawić tylko dla aliasów nazw.

**N-06 · Low · Seed zlecenia z `hash()` GDScriptu** · `job_run.gd:29-30`
→ naprawione w 8853863 (FNV-1a 64 jak w lockcore)
- `hash(String)` zależy od implementacji silnika; po migracji Godota (TECH §1.9) seedy zleceń mogą się zmienić, a z nimi zapis i powtórki. **Poprawka:** FNV-1a 64 jak w lockcore (`fnv1a64(id)`) albo seed zapisany w danych zlecenia.

**N-07 · Medium · Tier „ENVELOPE” na Androidzie to tyki, nie obwiednia** · `HapticsEngine.kt:150-157`
→ naprawione w 8853863 (BasicEnvelopeBuilder dla A3 zamiast łańcucha LOW_TICK)
- Dla API 36 z obwiedniami opór jest wysyłany jako kompozycja `PRIMITIVE_LOW_TICK` co 50 ms — w praktyce seria tyknięć 20 Hz, a nie ciągły opór. Spike 2 (`spikes/haptics-latency/shared-android/HapticCore.kt`) używa `VibrationEffect.BasicEnvelopeBuilder` (control points 20/40 ms). **Poprawka:** przenieść wariant z obwiednią; pomiar przerw: aplikacja D-33 (krok „ciągły opór”).

**N-08 · Low · Artefakty buildu wracają do gita (R-48)** · `game/addons/lockcore_gd/bin/*.so`
→ naprawione w 8853863 (.so poza gitem; CI buduje i przekazuje artefaktem)
- Commit 9981ec0 podmienia `liblockcore_gd.*.so` w repo. Przy kilku sesjach to konflikty binarne i rosnąca historia. **Poprawka:** budować w CI i przekazywać jako artefakt (jak `spike-*.yml`), lokalnie skrypt `build_gdext.sh`.

**Samouczek, HUD diegetyczny, tryb ciemności (commit 3b6d9ed, sprawdzone 2026-11-05 ok. 08:05)**

**N-09 · High · Samouczek nigdy się nie kończy** · `game/scripts/ui/tutorial.gd:17-34`, `game/scripts/lock/lock_scene.gd:134-142`, `game/scripts/lock/job_run.gd`
→ naprawione w 8853863 (tryb tutorial w JobRun, powrót do tutorial.tscn, tutorial_done; test GUT)
- **Co:** `tutorial._start_stage()` ustawia `JobRun.current_job = {"id": "tutorial.sN", …}` i przechodzi do `lock.tscn` przez `change_scene_to_file` (scena samouczka jest zwalniana). Po otwarciu zamka `_check_finished` widzi niepuste `current_job` i idzie do **`job_payment.tscn`**, a `JobRun.complete()` dopisuje `tutorial.s1` do `jobs_completed` i wraca do **listy zleceń**. `tutorial.on_lock_finished()` nie jest nigdzie wywoływane, więc `tutorial_done` nigdy nie jest ustawiane.
- **Skutek:** każde „Rozpocznij bieg” w menu wraca do S1 (pętla), a samouczki pojawiają się jako „zlecenia wykonane” z ekranem zapłaty 0 monet.
- **Poprawka:** osobny tryb w `JobRun` (np. `mode = &"tutorial"`) i w `_check_finished` powrót do `tutorial.tscn` ze stanem etapu w `Save`/`JobRun` (scena po powrocie odtwarza `_stage`), bez `job_payment`; test GUT przejścia S1→S3.

**N-10 · Medium · Menu wciąż prowadzi do starego `lock.tscn`, nie do ekranu planu B (D-31)** · `game/scripts/ui/main_menu.gd:22-25`, `job_verify.gd:26`
→ naprawione w 8853863 (zadanie 5 etapu 3: jedna ścieżka do sceny photoreal)
- D-31 jest zaakceptowana, a scena sesji A (`scenes/photoreal/lock_photoreal.tscn`) ma tę samą „hydraulikę” sesji. Gra i samouczek dalej otwierają `lock.tscn` (prymitywy 3D + nowa nakładka HUD z `assets/ui/tray.jpg` jako quad 3D). Ryzyko: dwa ekrany zamka rozjadą się w zachowaniu (lupa, kreda, życia są tylko w starym).
- **Poprawka:** jedna ścieżka do sceny zamka (stała w `JobRun`/`Events`), przełączenie na plan B, a funkcje HUD przenieść do widoku sesji A (uzgodnić podział z sesją A).

**N-11 · Low · Kreda: krzyżyk dla overset** · `lock_scene.gd` `_draw_chalk`
→ naprawione w 8853863 (klamra z dwiema kreskami zamiast X)
- Krzyżyk jest biały (nie czerwony), więc nie łamie wprost zakazu „czerwony X”, ale DESIGN §1 opisuje overset kształtem mechanizmu (stopka nad linią, sztywny rdzeń). Lepiej znak, który opisuje stan („kreska nad linią podziału”), niż ocenę „źle”.

**N-12 · Low · Notka „to gra, nie kurs” jako panel na 3 s** · `game/scripts/ui/boot.gd`, `boot.tscn:12`
→ przyjęte jako kosmetyka: notka jako karta (PanelContainer) zamiast okna; docelowo pieczątka wg ONBOARDING §3.3
- ONBOARDING §3.3 / D-21: pieczątka na kartce bloczka, bez okna. Teraz to `PanelContainer` wyświetlany 3 s przy pierwszym starcie (tekst przez i18n — OK). Kosmetyka zgodności z D-21.

**Zmiany wizualne / dostępność nowych ekranów** — w osobnym raporcie `docs/handoff/A11Y-AUDIT.md`.

---

# Przegląd ciągły (etap 3)

## Runda 1 — 2026-11-05 09:00
Zakres: commity w `game/`, `platform/`, `data/`, `game-*.yml` od 08:05 (6e0c398, 48b2d41, b9ec491 i migawki WIP; commity sesji A w `game/*/photoreal/` tylko czytane).
- **N-01 → zweryfikowane naprawione w 6e0c398** (adnotacji w tym pliku nie było): `game-android.yml`, `game-ios.yml`, `game-tests.yml` parsują się jako YAML (`yaml.safe_load` OK); runy 44–46 `game-tests` wystartowały normalnie (nie kończą się już w chwili utworzenia). Wynik runów — w następnej rundzie.
- N-02…N-12: bez zmian w kodzie od drugiego przeglądu (sesja B zaczyna etap 3 od zadania 1 = te uwagi).
- Regresji w nowych commitach nie znalazłem; 48b2d41 tylko dodaje `mkdir -p game/build` w teście eksportu.

## Runda 2 — 2026-11-05 ok. 10:00 (z automatem QA, `qa/`)
Zakres: commity sesji B 8853863 … efa20ed (09:00–09:10). Automat kariery (`qa/run_career.sh`, workflow `qa-career`) puszczony na HEAD przed i po tych commitach. Przed: 27/29 zleceń (26 + samouczek), 0 soft-locków, 0 brakujących kluczy, 197 s symulacji. Po: **16/29**, 10 soft-locków.

Weryfikacja „naprawione” z 8853863:
- **N-02** (segmenty Androida) i **N-07** (koperta): zmiany w `export_plugin.gd` / `feedback_director.gd` są; na urządzeniu niezweryfikowane — bez zastrzeżeń w kodzie.
- **N-03 → zweryfikowane:** `platform/android/lockwright-click-audio` (Oboe), AAR pakowany przez `lockwright_haptics/export_plugin.gd` (`_get_android_libraries`), `Sfx` szuka singletonu. `lockwright_click_audio.gd` to pusty `EditorPlugin` — działa tylko dlatego, że eksporter haptyki dokłada oba AAR; warto opisać to w komentarzu.
- **N-05 → zweryfikowane:** `JobRun.is_playable` ukrywa 7 zleceń z niezaimplementowanymi rodzinami (axial_slider, time_lock, magnetic, dial_safe…). Bot ich nie widzi — zgodnie z zamiarem.
- **N-06, N-08, N-11:** zmiany są, bez uwag.
- **N-09 → nie działa w praktyce:** tryb samouczka w `JobRun` jest poprawny, ale samouczek trafia teraz na ekran planu B, który nigdy nie woła `JobRun.complete()` (N-13). `tutorial_done` dalej nigdy nie jest ustawiane; bot przeszedł etap 1 cztery razy.

**N-13 · High (regresja z a9892ea) · Ekran planu B nie kończy zlecenia** · `game/scripts/lock/job_run.gd:34-39` + `game/scripts/photoreal/lock_photoreal.gd:116-118`
- `lock_scene_path()` kieruje pin_tumbler (samouczek i 3 zlecenia: newlyweds_4am, student_dorm, wrong_floor) do `lock_photoreal.tscn`. Ta scena po otwarciu tylko odświeża widok (`if session.finished(): view.present(...) return`) — brak `JobRun.complete()`, brak przejścia do `job_payment`. Jedyne wyjście: pauza → „Wyjdź” do menu, bez nagrody i postępu. Bot: 10 soft-locków.
- **Poprawka (sesja B, bez ruszania kodu sesji A):** podłączyć się do `Events.lock_opened` (scena go emituje) w autoloadzie/`JobRun`: `complete()` + zmiana sceny na `job_payment` (zlecenie) albo następny etap samouczka. Ewentualnie uzgodnić z sesją A sygnał „wyjście z zamka”.

**N-14 · High · Ekran planu B ignoruje zlecenie (rodzina/seed/tier)** · `lock_photoreal.gd:20-22, 55-58`
- Scena bierze `family/seed/tier` z `@export` (pin_tumbler, 42, **4**) albo z argumentów `--lw-*`, a nie z `JobRun`. Każde zlecenie pin_tumbler i samouczek grają ten sam zamek tier 4 (seed 42) — samouczek nie jest tier 1, a powtórki/weryfikator nie odpowiadają zleceniu.
- **Poprawka:** przy `JobRun.current_job` niepustym użyć `JobRun.family_for/seed_for/tier_for` (jak `lock_scene.gd:29-32`); wymaga zgody sesji A albo cienkiego wrappera sceny po stronie B.

**N-15 · Medium · Odmowa: wielokrotne punkty reputacji** · `game/scripts/ui/job_verify.gd:49-57`
- Po „Odmów” scena czeka 1,2 s, a przycisk zostaje aktywny: każde kolejne dotknięcie dodaje +5 reputacji (bot przy jednym wejściu nacisnął 20× → +100). Do tego odmowa nie jest zapisywana, więc `refuse_*` zostają na liście i można je odmawiać w nieskończoność.
- **Poprawka:** `refuse_button.disabled = true` (i `accept_button`) od razu po naciśnięciu; zapisać `jobs_refused` i nagradzać tylko pierwszą odmowę (JOBS.md §5); na liście oznaczyć zlecenie jako zamknięte.

**N-16 · Low · Ekran planu B: pauza tylko jako narysowana klapka** · `lock_photoreal_view.gd` (sesja A)
- Brak węzła `Button` dla pauzy (bot znalazł ją tylko przez ESC). Dla dostępności (A-09) i testów warto mieć niewidoczny `Button` 48 dp z `accessibility_name` na miejscu klapki.

Automat QA: `qa/README.md`; nocny raport — artefakt `qa-career-report`. Kryterium „OK” = brak soft-locków, ekranów bez wyjścia, błędów skryptów i brakujących kluczy, więc workflow będzie czerwony, dopóki N-13 nie zostanie naprawione (to zamierzone).
