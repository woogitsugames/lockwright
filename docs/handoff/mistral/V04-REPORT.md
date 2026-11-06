# V04 — sceny „dzień po” (raport)

Data: 2026-11-06. Zakres: `game/scripts/ui/day_after.gd`, `game/scenes/day_after.tscn`, `game/tests/gut/test_day_after.gd`, 3-linijkowy hook w `game/scripts/ui/jobs_list.gd`. CSV, dane zleceń i pozostałe skrypty nietknięte.

## Co zrobione

1. **`DayAfter.pending_job()`** (`day_after.gd`) — wybiera jedno z ostatnio zakończonych zleceń (od najświeższego; `jobs_completed` + `jobs_refused`, obie listy są appendowane w kolejności kończenia), które ma niepuste `after`, klucz `<job_id>.after.1` w i18n i nie jest jeszcze na liście `day_after_shown` w Save. Zwraca `{}` gdy nic nie ma.
2. **Scena `day_after.tscn`** — portret mówcy przez `job_arrival.gd:portrait_for()` (slot obsady G09 → portret episodic), fallback: enamelowa tabliczka z inicjałem (`initial_plate()`, G17, 48 dp), imię spikeru (`cast.<id>.name`) nad kwestią (`<job_id>.after.N`, same napisy, bez głosu). Cały ekran to cel stuknięcia (childy mają `MOUSE_FILTER_PASS`, root dostaje `gui_input`); stuknięcie zamyka scenę, zapisuje `day_after_shown` w Save i wraca do `jobs_list.tscn`. Styl jak w innych ekranach menu: `ScreenFrame.fit` (16 dp + safe-area przez `SafeArea`), backdrop `stairwell.jpg`, `Title`/`Caption` z motywu, bez kart SaaS.
3. **Hook w `jobs_list.gd:_ready()`** — 3 linie na końcu: gdy `DayAfter.pending_job()` niepuste, przejście do `res://scenes/day_after.tscn`. Po zamknięciu sceny lista wchodzi ponownie, ale zlecenie jest już oznaczone — pokazuje się dokładnie raz na zlecenie.
4. **Testy `test_day_after.gd` (GUT)** — 8 testów: brak pending gdy nic nie skończone; wybór skończonego zlecenia z `after` (pominięcie nieznanego id); uwzględnienie odmów (`jobs_refused`); pokazanie raz na zlecenie + idempotentny `mark_shown`; pamięć Save po `Save.load_save()`; scena z wierszami kwestii i zamknięcie stuknięciem; scena sama się zwalnia gdy brak pending; brak portretu (locksmith) → tabliczka z inicjałem zamiast błędu.

## Weryfikacja

- `python3 tools/i18n_lint.py` — OK (tylko pre-existing warningi); `python3 tools/assets_lint.py` — OK.
- Testy GUT (`Godot_v4.7.2 --headless --path game -s res://addons/gut/gut_cmdln.gd -gdir=res://tests/gut -gexit`) uruchamiane w CI `game-tests.yml` — w sandboxie brak binarnego Godota i sieci, więc lokalnie nie odpalone; składnia zgodna z wzorcami z `job_arrival.gd` / `test_nav_back.gd` / `test_dialogue_player.gd`.

## Uwagi

- Wszystkie 71 zleceń ma pełne pokrycie kluczy `<id>.after.N` w `content.csv` (sprawdzone skryptem), więc guard `I18n.has_key` to tylko zabezpieczenie na przyszłość.
- `DayAfter.change_scenes` (jak `Nav.change_scenes`) pozwala testom wyłączyć realną zmianę sceny, żeby nie rozwalić drzewa GUT.
