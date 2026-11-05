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
