# Zlecenie V02 (Mistral Vibe): eskalacja wskazówek H0–H4 i „widmo kciuka” + poprawki lintów

**Repo:** `woogitsugames/lockwright`, gałąź `main`. Najpierw przeczytaj `CLAUDE.md`. Kod i komentarze piszesz po angielsku, raport po polsku.
**Zasada pracy:** zrób, wypchnij na `main` małymi commitami i skończ. Wpięcie w samouczek, sprawdzenie i scalanie robi sesja A (Claude).
**Twoje pliki (tylko te):**
- `game/scripts/tutorial/hint_ladder.gd` (nowy),
- `game/scripts/tutorial/ghost_hand.gd` (nowy),
- `game/tests/gut/test_hint_ladder.gd` i `game/tests/gut/test_ghost_hand.gd` (nowe),
- `tools/assets_lint.py`, `tools/i18n_lint.py`, `tools/tests/`,
- `docs/handoff/mistral/V02-REPORT.md`.

**Nie zmieniaj niczego innego.** W szczególności nie ruszaj `game/scripts/lock/**` (w tym `tutorial_coach.gd`), `game/scripts/photoreal*/**`, scen, `game/i18n/*.csv` ani `project.godot`. Równolegle pracują tam inni agenci.

Push: `git -c rebase.autoStash=true pull --rebase origin main && git push origin main`. W wiadomościach commitów, które zmieniają tylko `tools/` i `docs/`, dopisz `[skip ci]`.

## 1. `hint_ladder.gd`: logika eskalacji (bez grafiki)
Specyfikacja: `docs/ONBOARDING.md` §2.1 (tabela H0–H4 i zasady). Krótko:
- `class_name HintLadder extends RefCounted`.
- Licznik utknięcia liczy czas od ostatniego **postępu** w bieżącym kroku, a nie od ostatniego dotyku. API:
  - `start_step(step_id: StringName)` zeruje licznik, poziom i flagę H4;
  - `progress()` zeruje licznik i wraca do H0;
  - `update(delta: float) -> int` zwraca bieżący poziom 0–4;
  - sygnał `level_changed(level: int, step_id: StringName)`, emitowany raz przy każdym wejściu na wyższy poziom.
- Progi domyślne: 15 / 30 / 45 / 60 s. Muszą być konfigurowalne (np. `thresholds: PackedFloat32Array`), bo S2 i S3 skracają drogę „H2 → H4 po 30 s” (ONBOARDING §1.x, wiersz 2.1).
- H4 może się wydarzyć **najwyżej raz na krok**. Po H4 licznik dalej rośnie, ale poziom zostaje na 3.
- `dark_mode: bool`: w trybie „w ciemności” wynik ten sam, ale udostępnij `channels(level) -> Dictionary` z kluczami `{visual, sound, haptic, light}` zgodnie z tabelą i akapitem o trybie w ciemności.
- Telemetria: tablica `history` z wpisami `{step, level, t}` (ONBOARDING §12).
- Determinizm: żadnych wywołań `Time` ani losowości. Czas przychodzi tylko przez `delta`.

## 2. `ghost_hand.gd`: widmo kciuka lub dłoni
Specyfikacja: ONBOARDING §2.2.
- `class_name GhostHand extends Control`, `mouse_filter = IGNORE`. Nie może przechwytywać dotyku.
- `texture: Texture2D` to sylwetka (alfa). Gdy jej brak, rysujesz zastępczy kształt kciuka: zaokrąglony owal ok. 22×56 dp z miękką krawędzią.
- Wygląd: **cień, nie poświata**. Kolor czarny, krycie 35 %, miękka krawędź ok. 12 dp. Rozmycie zrób shaderem `canvas_item` albo przygotuj teksturę wcześniej. Bez obrysu, bez koloru, bez cząsteczek.
- API: `play_gesture(from_dp: Vector2, to_dp: Vector2, duration_s: float, repeats := 2, hold_s := 0.0)`. Widmo pojawia się (fade 150 ms), jedzie po ścieżce z easingiem (przyspiesza, potem zwalnia) i znika. Powtarza się `repeats` razy. `hold_s` służy do gestu „połóż i trzymaj” (1,5 s). Sygnały `gesture_progress(t: float)` (0..1, żeby scena mogła „odpowiedzieć”, np. obrócić napinacz) i `gesture_finished`.
- `mirror: bool` dla leworęcznych (opcja „zamień kciuki”).
- Jednostki w dp: korzystaj z istniejącego mnożnika dp w projekcie, zobacz `game/scripts/autoload/dp_scale.gd` i to, jak inne skrypty UI liczą dp.
- Bez tekstu na ekranie.

## 3. Testy GUT
- `test_hint_ladder.gd`:
  - progi 15/30/45/60;
  - `progress()` zeruje poziom;
  - samo machanie (brak `progress()`) nie zeruje;
  - H4 tylko raz na krok;
  - nowy krok zaczyna od zera;
  - własne progi;
  - kanały w trybie w ciemności.
- `test_ghost_hand.gd`:
  - `mouse_filter` to IGNORE;
  - `play_gesture` kończy się sygnałem po oczekiwanym czasie (symuluj `_process`);
  - `gesture_progress` rośnie od 0 do 1;
  - `mirror` odbija pozycję;
  - bez tekstury nic się nie wysypuje.
- Testy uruchamia CI (`game-tests`). Lokalnie sprawdź je, jeśli masz Godot 4.7.2.

## 4. Poprawki lintów (z przeglądu V01: `contrib/mistral/REVIEW-V01.md`)
- `assets_lint.is_listed` uznaje samą nazwę pliku w dowolnym katalogu. Przez to wpis `mockups/fonts/X` „pokrywa” `game/assets/.../X`. Wymagaj zgodnego katalogu albo sufiksu ścieżki. Dodaj test i popraw ewentualne nowe trafienia **tylko w raporcie**. `docs/ASSETS.md` uzupełni sesja A.
- `i18n_lint`: dla kluczy dynamicznych (`cast.%s.name`, `%s.line.%d`, `verify.card.%s`) sprawdź, czy w CSV istnieje **co najmniej jeden** klucz pasujący do wzorca. Brak takiego klucza ma być błędem. Dodaj test.

## 5. Raport `docs/handoff/mistral/V02-REPORT.md` (po polsku)
- co zrobiłeś;
- API obu klas z przykładem użycia w `TutorialCoach` (pseudokod, bez zmiany `tutorial_coach.gd`);
- wyniki testów;
- nowe trafienia lintów.
