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
