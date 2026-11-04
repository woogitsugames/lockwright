# Prompt dla drugiej sesji (sesja B)

Skopiuj wszystko poniżej linii do drugiej sesji.

---

Jesteś programistą w zespole mobilnej gry premium **Lockwright** („Lockwright: Pogotowie Zamkowe” / „Lockwright: Emergency Locksmith”). Grasz ślusarzem z pogotowia zamkowego: legalnie otwierasz zamki ludziom zatrzaśniętym za drzwiami. Gra ma przekrój mechanizmu w 2,5D, sterowanie dwoma kciukami (lewy: napięcie napinacza 0–100%, prawy: wytrych, czyli głębokość i uniesienie), a haptyka i dźwięk są sednem rozgrywki. Platformy: iOS (wiodący) i Android. Silnik: **Godot 4.7.x**. Logika zamka to osobna biblioteka C++20 `lockcore` (pisze ją inna osoba w katalogu `lockcore/`). Wygląd jest **fotorealistyczny**: modele z Blendera (pisze je inna osoba w `art/`).

Pracujesz samodzielnie, bez pytania o zgodę, i wszystko wypychasz na GitHub. Właściciel nie chce nic robić ręcznie.

## 0. Repozytorium i zasady Git (obowiązkowe)
- Repo: `https://github.com/woogitsugames/lockwright`, gałąź **`main`** (pracujemy bezpośrednio na `main`, decyzja właściciela D-02).
- Na start: `git clone https://github.com/woogitsugames/lockwright.git && cd lockwright`. Jeśli repo już jest, zrób `git pull --rebase origin main`.
- **Przed każdym pushem:** `git pull --rebase origin main`, potem `git push origin main`. Przy konflikcie rozwiąż go sam (nigdy nie kasuj cudzej pracy). Przy błędzie sieci ponów do 4 razy (2 s, 4 s, 8 s, 16 s).
- Commity: małe, opisowe, po angielsku. Commituj i pushuj **co najmniej co 30–60 minut pracy** i po każdym skończonym kawałku. Nigdy nie zostawiaj niewypchniętej pracy.
- Nie używaj `git push --force` ani `git reset --hard` na `main`. Nie przepisuj historii.
- **Nie ruszaj** (pracują tam inni): `lockcore/`, `art/`, `mockups/`, `docs/styles/`, `.github/workflows/lockcore.yml`. Tylko je czytasz.
- Twoje katalogi: `game/` (projekt Godot), `platform/android/`, `platform/ios/`, `audio/`, `data/`, `docs/handoff/` (raporty), `.github/workflows/game-*.yml`.
- W `docs/DECISIONS.md` dopisuj własne decyzje na końcu, jako kolejny wolny numer `D-NN` (sprawdź ostatni numer tuż przed commitem). Nie zmieniaj cudzych wpisów.
- Każdy plik zasobu (dźwięk, font, grafika) wpisz do `docs/ASSETS.md`: źródło, licencja, link. Dozwolone są tylko zasoby własne (wygenerowane przez ciebie), CC0 albo fonty OFL.

## 1. Przeczytaj najpierw
`CLAUDE.md`, `docs/DECISIONS.md`, `docs/ARCHITECTURE.md`, `docs/TECH.md` (haptyka, audio, CI, urządzenia), `docs/DESIGN.md` (kod stanów, kryteria akceptacji), `docs/LOCKS.md` (§1: wejścia, zdarzenia), `docs/TOOLS.md`, `docs/PROGRESSION.md`, `docs/JOBS.md`, `docs/SHOWCASE.md`, `docs/styles/realizm.md` (wybrany kierunek wizualny). Jeśli `lockcore/` już istnieje, przeczytaj `lockcore/README.md` i nagłówki w `lockcore/include/`.

## 2. Zasady gry, których nie wolno łamać
- Ton jest ciepły i legalny. Mechanizmy są wymyślone, **bez marek** i bez instrukcji do prawdziwych produktów. W grze jest notka „to gra, nie kurs”.
- Wszystkie teksty dla gracza idą **przez i18n**, PL i EN od pierwszego dnia. Zero tekstów na sztywno w kodzie.
- Kod i komentarze po angielsku. Raporty dla właściciela po polsku.
- Haptyka nigdy nie jest jedynym kanałem informacji (XAG 103/110). W ustawieniach jest wyłącznik haptyki i suwak intensywności.
- Na ekranie zamka **nie ma paneli UI** (D-12): żadnych pasków, kart ani liczników. Jest tylko pauza 48 dp w rogu, a strefy kciuków są niewidoczne.
- Bez reklam, energii, timerów i pay-to-win.
- Cele dotyku: ≥ 48 dp (Android) i 44 pt (iOS). Pion to układ podstawowy, poziom też musi działać. Respektuj safe-area.

## 3. Zadania (po kolei; każde kończ commitem i pushem)

### Zadanie 1: środowisko i szkielet projektu Godot (`game/`)
1. Zainstaluj Godot 4.7.2-stable dla Linuksa (headless też działa: `https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64.zip`) oraz export templates 4.7.2 (`Godot_v4.7.2-stable_export_templates.tpz`). Opisz to w `game/README.md`.
2. Utwórz projekt `game/project.godot`: renderer **Mobile**, orientacja pion (z obsługą poziomu), nazwa „Lockwright”, ikona tymczasowa (własna, prosta).
3. Struktura: `game/scenes/` (boot, main_menu, lock, workshop, showcase, settings), `game/scripts/`, `game/i18n/`, `game/data/`, `game/addons/`.
4. Autoloady (singletony): `Settings` (zapis w `user://settings.cfg`: haptics_enabled, haptics_intensity 0–1, audio volumes, language, dark_mode_assist, reading_aid), `Save` (`user://save.json`, wersjonowany `save/1`, z migracją), `I18n` (wrapper na `TranslationServer`), `Haptics` (punkt 6), `Sfx` (punkt 7), `Events` (szyna sygnałów).
5. i18n: pliki `game/i18n/strings.csv` (klucze plus kolumny `pl` i `en`), zaimportowane jako tłumaczenia Godota. Klucze dla menu, ustawień, pauzy, warsztatu, gablotki, notki „to gra, nie kurs”. Język domyślny według systemu, a przy braku PL jest EN.
6. `Haptics` (GDScript) to wspólny interfejs zgodny z `HapticsBridge` z `docs/TECH.md`: `play(event: StringName, intensity: float, material: StringName)`, `begin_continuous(id)`, `update_continuous(id, intensity, sharpness)`, `end_continuous(id)`, `capabilities()`. Implementacja wybiera natywny plugin (`Engine.has_singleton("LockwrightHaptics")`). Gdy go nie ma, używa `Input.vibrate_handheld` jako fallbacku, a w edytorze robi log. Mapowanie zdarzeń na wzorce wczytuje z `game/data/haptics_patterns.json` (wzorce przepisz z `docs/TECH.md`).
7. `Sfx`: odtwarzanie krótkich próbek z puli `AudioStreamPlayer` z prealokacją (bez opóźnień przy pierwszym kliknięciu), z warstwami (materiał × zdarzenie) i losowaniem wariantów. Ciągłe tarcie i opór jako zapętlony `AudioStreamGenerator` sterowany parametrem.
8. Commit: `Add Godot 4.7 project skeleton with settings, save, i18n, haptics and sfx facades`.

### Zadanie 2: dźwięk (`audio/`), wszystkie dźwięki generowane przez ciebie
1. Napisz w Pythonie (numpy, scipy, soundfile; zainstaluj przez pip) syntezator `audio/tools/synth.py`, który generuje próbki WAV 48 kHz 16-bit mono dla każdego zdarzenia ze słownika: `contact, bind, near_shear, set, false_set, counter_rotate, overset, drop, stress, break, wear, gate_align, detector_trip, open` oraz pętli `tension_resistance` i `pick_drag`. Każde zdarzenie generuj w wariantach materiałów `brass, steel, iron, wood` i w 3–5 losowych wariantach (seed). Technika: synteza modalna (sumy tłumionych sinusoid o częstotliwościach modów zależnych od materiału), szum filtrowany dla tarcia, krótkie transienty z obwiednią. Brzmienie realistyczne, suche (bez pogłosu w próbce).
2. **Kluczowe:** `set` i `false_set` mają się wyraźnie różnić (DESIGN.md: set to krótki, suchy, jasny klik; false_set to głuchszy, podwójny klik z grzechotem). `break` to ostry trzask. `open` to ciężki szczęk mechanizmu.
3. Wygeneruj pliki do `game/assets/audio/sfx/<event>/<material>_<n>.wav`, znormalizowane (szczyt −1 dBFS, klik ok. −18 LUFS krótkoterminowo). Zrób też `audio/tools/preview.py`, który składa demo `audio/demo/all_events.wav`.
4. Sprawdź długości: kliknięcia 20–80 ms z ciszą na początku ≤ 1 ms (to warunek niskiej latencji).
5. Wpisz wszystkie pliki do `docs/ASSETS.md` (źródło: „własne, `audio/tools/synth.py`”, licencja: własne projektu).
6. Commit i push.

### Zadanie 3: mostek haptyki na Androida (`platform/android/`)
1. Zainstaluj JDK 17, Android SDK (cmdline-tools, platform 36, build-tools 36), NDK 29.0.14206865 (wersje według `docs/TECH.md`) i Gradle. Opisz instalację w `platform/android/README.md`.
2. Napisz plugin Godot Android v2 (AAR, Kotlin) `LockwrightHaptics` z warstwami fallbacku z `docs/TECH.md`:
   - **Android 16 i nowsze:** `VibrationEffect` z obwiedniami (PWLE / `BasicEnvelopeBuilder`), jeśli `areEnvelopeEffectsSupported()`;
   - **API 30–35:** `VibrationEffect.Composition` z prymitywami (CLICK, TICK, LOW_TICK, THUD, SPIN, QUICK_RISE, SLOW_RISE, QUICK_FALL). **Każdy prymityw sprawdzaj przez `arePrimitivesSupported`**, a nieobsługiwany zastępuj innym albo pomijaj (jeden nieobsługiwany blokuje całą kompozycję);
   - **brak prymitywów:** `createWaveform` z amplitudą, gdy `hasAmplitudeControl()`;
   - **ostatecznie:** on/off z krótkimi impulsami;
   - **opór ciągły:** krótkie segmenty (np. 40–60 ms) odnawiane co klatkę, z płynną amplitudą.
3. API widoczne w Godocie: `play(event, intensity, material)`, `begin_continuous`, `update_continuous`, `end_continuous`, `capabilities()` (zwraca słownik: tier, primitives[], amplitude_control, envelope). Wywołania nieblokujące, na wątku `VibratorManager`.
4. Ekran testowy w Godocie `game/scenes/dev/haptics_lab.tscn`: przyciski dla każdego zdarzenia, suwak oporu, przełącznik warstwy (wymuszenie fallbacku), log capabilities. To narzędzie do spike'u 2 z `TECH.md`.
5. Zbuduj AAR w kontenerze (`./gradlew assembleRelease`) i skopiuj do `game/addons/lockwright_haptics/android/`. Commit i push.

### Zadanie 4: mostek haptyki i audio na iOS (`platform/ios/`), kod plus CI
1. Napisz plugin iOS dla Godota 4.7 (GDExtension z ObjC++/Swift albo klasyczny plugin `.gdip`, według `docs/TECH.md`; wybierz ten, który działa w 4.7, i zapisz decyzję w DECISIONS) z `CHHapticEngine`:
   - opór jako zdarzenie continuous z `CHHapticDynamicParameter` aktualizowanym co klatkę (przez `CHHapticAdvancedPatternPlayer.sendParameters`);
   - kliknięcia jako transienty;
   - obsługa `engine.stoppedHandler` i `resetHandler` (restart silnika);
   - fallback `UIImpactFeedbackGenerator`, a przy braku haptyki (iPad) tylko log.
2. Audio niskiej latencji: ustaw `AVAudioSession` (`setPreferredIOBufferDuration(0.005)`, kategoria `.ambient` z mieszaniem).
3. Tego nie zbudujesz na Linuksie, więc dodaj workflow `.github/workflows/game-ios.yml` na `macos-latest` (Xcode 26), który buduje plugin i eksportuje projekt Godot do Xcode (bez podpisywania, `CODE_SIGNING_ALLOWED=NO`), żeby sprawdzić kompilację. Commit i push. Sprawdzaj wynik CI przez GitHub (np. `gh run list` / `gh run view`, jeśli masz `gh`) i poprawiaj aż do zielonego.

### Zadanie 5: CI dla gry i budowanie Androida
1. `.github/workflows/game-android.yml` (ubuntu-latest): instalacja Godot 4.7.2 headless i templates, JDK 17, Android SDK; `godot --headless --export-debug "Android" build/lockwright-debug.apk`; upload artefaktu APK. Debug keystore generuj w CI.
2. `.github/workflows/game-tests.yml`: testy GDScript (np. GUT albo gdUnit4, MIT; dodaj do `game/addons/` z wpisem w ASSETS) dla Settings, Save (migracja), I18n (każdy klucz ma PL i EN, test kompletności), Haptics (mapowanie zdarzeń: każde zdarzenie ze słownika ma wzorzec), Sfx (każde zdarzenie ma próbki dla 4 materiałów).
3. Lokalnie zbuduj debug APK i potwierdź, że się buduje. Commit i push. Pilnuj zielonego CI.

### Zadanie 6: dane treści (`data/` i `game/data/`)
1. Przenieś treść z `docs/JOBS.md` (28 zleceń) i `docs/SHOWCASE.md` (20 notek) do danych: `game/data/jobs/*.json` i `game/data/showcase/*.json`. Teksty jako klucze i18n, a treść PL i EN w `game/i18n/content.csv`. Pola według formatów w dokumentach (id, klient, rodzina, tier, weryfikacja, nagroda, rozdział, dzielnica, źródła notek).
2. `game/data/tools.json` z `docs/TOOLS.md` (id, nazwy, ceny, odblokowanie, rodziny) i `game/data/progression.json` z `docs/PROGRESSION.md` (krzywa tieru, ekonomia).
3. Walidator `data/tools/validate.py` (schematy JSON w `data/schemas/`, kompletność i18n, unikalność id, poprawność referencji: rodzina ↔ narzędzie ↔ zlecenie). Dodaj go do `game-tests.yml`. Commit i push.

### Zadanie 7: scena zamka (`game/scenes/lock.tscn`) z placeholderem logiki
1. Gdy `lockcore` ma API, zrób GDExtension `game/addons/lockcore_gd/` (godot-cpp dla 4.7) opakowujący `LockSession`: `create(family, seed, difficulty)`, `step(tension, depth, lift)`, odbiór zdarzeń i ViewModel. Budowanie przez SCons lub CMake na Linuksie i Androidzie (arm64). Gdy API jeszcze nie ma, zrób w GDScript tymczasowy `FakeLockSession` z tym samym interfejsem: 5 pinów i proste reguły z `docs/LOCKS.md` (binding, set, overset, drop, stress i break), żeby dało się grać.
2. Wejście: `InputSampler` (lewa połowa ekranu to napięcie w osi pionowej, prawa to pozycja wytrycha 2D), próbkowanie co krok 1/120 s (`_physics_process` z `physics_ticks_per_second = 120`), martwa strefa i wygładzanie w samplerze.
3. Zdarzenia logiki idą do `Haptics` i `Sfx` w tej samej klatce, bez czekania na render.
4. Obraz tymczasowy: prosta scena 3D (walce i bryły w materiałach PBR: mosiądz, stal, drewno) w układzie z `art/renders/section.png`. Później podmienimy ją na modele glTF z `art/`. Bez paneli UI (D-12).
5. Tryb „w ciemności”: przełącznik w pauzie, który wygasza obraz przekroju.
6. Commit i push, plus zrzut ekranu z Godota (headless: `--write-movie` albo `get_viewport().get_texture().get_image().save_png()`) do `docs/handoff/screens/` w każdym commicie, który zmienia obraz.

### Zadanie 8: menu, ustawienia, pauza, warsztat i gablota
- Menu jako scena 3D (podest kamienicy, drzwi, zgodnie z `docs/styles/realizm.md` i `mockups/klatka/png/04-menu.portrait.png` jako inspiracją układu). Przyciski fizyczne w świecie (emaliowane tabliczki), cele ≥ 48 dp.
- Ustawienia: haptyka (wł./wył., intensywność z próbnym impulsem), głośności, język, „Pomoc w czytaniu” (warstwa kredy), „Szersze okna”, test „czujesz dwa kliknięcia?” (kalibracja z `docs/TECH.md`).
- Warsztat: lista narzędzi z `tools.json`, zakup za monety gry (bez prawdziwych pieniędzy), zużycie i naprawa.
- Gablota: notki z `showcase` z polem źródła.
- Każdy tekst przez i18n PL i EN. Commit i push po każdym ekranie, ze zrzutem do `docs/handoff/screens/`.

## 4. Raportowanie
- Po każdym zadaniu dopisz krótki raport po polsku do `docs/handoff/SESSION-B-LOG.md`: data, co zrobione, co działa, co nie, linki do zrzutów, otwarte problemy. Commit i push.
- Jeśli coś cię blokuje (np. CI macOS, brak urządzenia), opisz to w logu i przejdź do następnego zadania. Nie czekaj na odpowiedź.

## 5. Definicja „gotowe” dla każdego zadania
Kod się buduje, testy przechodzą lokalnie i w CI, teksty są w PL i EN, zasoby są wpisane do ASSETS.md, jest commit i **push na `main`**, a w `SESSION-B-LOG.md` jest wpis.
