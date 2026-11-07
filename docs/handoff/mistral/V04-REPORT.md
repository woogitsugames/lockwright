# Raport V04: sceny „dzień po”

**Data:** 2026-11-07 · **Wykonał:** sesja dzień-po (Claude) — dostawa od Mistral Vibe nie przyszła (brak plików V04 w `contrib/mistral/` i `docs/handoff/mistral/` na `origin/main`), więc zlecenie zrobione w domu, według kryteriów z `V04-day-after-scenes.md`. Decyzje: **D-78**.

## Co działa
- Po zakończonym zleceniu (otwarte, naprawione, rozmowa — `JobRun.complete()`; odmowa zamkniętego `job.refuse_*` — `job_verify._refuse()`) zlecenie z `after` trafia do kolejki w Save.
- Przy następnym wejściu w listę zleceń nad listą otwiera się **jedna** scenka (najnowsze niewidziane zlecenie): zdjęcie miejsca za dnia, nagłówek „Następnego dnia” i tytuł zlecenia, portret mówcy, kwestia. Stuknięcie (albo tabliczka „Kontynuuj” / „Wracam do pracy”, albo Back) przechodzi dalej i zamyka. Zlecenie zapisuje się jako widziane i scenka nie wraca.
- Dwie kwestie (8 zleceń): portret zmienia się z mówcą; kwestia ślusarza (`t43_12_08_henryks_bench`) na jasnej emalii, portret klientki zostaje.
- Brak portretu: tabliczka G17 z inicjałem w rozmiarze portretu (jak na przyjeździe, większa).
- Pion: portret nad kwestią; poziom: obok, kolumna ≤ 640 dp. Safe-area i 16 dp przez `ScreenFrame.fit`, cele ≥ 48 dp (tabliczka 56 dp), przejścia 150 ms, wyłączone przy „ograniczeniu ruchu”.
- Głos: jeśli kiedyś powstanie `lines/<lang>/<job_id>.after.N.ogg`, scenka go zagra (Voice, ducking). Dziś same napisy.

## Pliki
| Plik | Zmiana |
|---|---|
| `game/scripts/ui/day_after.gd` (nowy, `class_name DayAfter`) | kolejka (`note_finished`, `next_job`, `mark_seen`, `maybe_show`) + scena |
| `game/scenes/day_after.tscn` (nowy) | układ sceny |
| `game/scripts/ui/jobs_list.gd` | hak `DayAfter.maybe_show(self)` + `go_back()` dla Back |
| `game/scripts/lock/job_run.gd`, `game/scripts/ui/job_verify.gd` | po jednej linii: `DayAfter.note_finished(...)` |
| `game/data/jobs/*.json` (10 zleceń rozdz. 8) | dopisane `after` |
| `game/i18n/content.csv` | 10 kwestii `<job>.after.1` (PL/EN/DE/FR/ES) |
| `game/i18n/strings.csv` | `dayafter.title`, `dayafter.close` (5 języków) |
| `game/tests/gut/test_day_after.gd` (nowy) | 11 testów |
| `game/tests/screens.gd` | zrzut `day_after_<w>x<h>.png` (lista + scenka dla `job.cat_bathroom`) |
| `tools/voice_lines.py`, `contrib/voice/tts_inputs_after.json` | wejścia TTS dla kwestii „dzień po” (bez generowania audio) |
| `docs/DECISIONS.md` (D-78), `docs/JOBS.md` §2.5 | opis |

Odstępstwo od briefu: brief zabraniał ruszania CSV, danych i innych skryptów (podział pracy z zewnętrznym wykonawcą). Robiąc to w domu, dopisałem teksty rozdz. 8 i dwa haki zapisu (zakończenie / odmowa) zamiast zgadywać „ostatnio zakończone” z dwóch niepowiązanych list w Save.

## Testy (`test_day_after.gd`, lokalnie 11/11 zielone, Godot 4.7.2 headless)
- każde zlecenie ma `after`, każda kwestia ma tekst, każdy mówca ma imię w `cast.*`;
- kolejka: bez duplikatów, bez zmian dla zamków dyżuru, limit 3, najnowsze pierwsze;
- `JobRun.complete()` i odmowa kolejkują scenkę;
- scenka pokazuje się raz, stuknięcie zamyka, przeciągnięcie nie; drugi raz `maybe_show` nic nie pokazuje; widzianego zlecenia nie da się zakolejkować ponownie;
- dwie kwestie, ślusarz na emalii, portret klientki zostaje;
- brak portretu → tabliczka, bez błędu;
- Save pamięta kolejkę i „widziane” po `load_save()`;
- lista zleceń otwiera scenkę na wierzchu, Back zamyka ją, drugi Back wychodzi z listy;
- 360×800, 412×915, 915×412: bez przewijania w bok, tabliczka ≥ 48 dp, portret nad / obok kwestii.

Lokalnie zielone też `test_ui_layout`, `test_t43_jobs`, `test_i18n`, `test_save`, `test_job_run`, `test_texts_t54_t73`; `i18n_lint` 0 błędów. Testy zależne od lockcore (brak biblioteki Windows) — tylko CI.

## Otwarte
- **Głosy:** 455 wejść TTS w `contrib/voice/tts_inputs_after.json`; **Lena** (6 kwestii × 5 języków) nie ma głosu w `game/data/voice_cast.json` — najpierw Voice Design. Po nagraniu: `voice_lines.py finish` + paczki głosów (D-63).
- **Scenki z D-74:** dla zleceń ze scenką przyjazdu (`arrival_scenes.json`) można by użyć dziennej płyty zamiast zdjęcia G07; zasoby w `game/assets/arrival/` są w przebudowie, więc zostawione.
- Zrzut ekranu z CI (`game-screens`, `day_after_412x915.png` / `915x412`) — do obejrzenia po przebiegu.
