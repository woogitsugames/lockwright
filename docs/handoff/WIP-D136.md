# WIP D-136 — wydajność i stabilność przed produkcją (przerwane 2026-11-16)

Gałąź `wip/d136-perf`. **Nie scalać do `main` bez pełnego GUT i bota kariery** — nie zostały uruchomione po zmianach.
Pomiary: kontener chmurowy, Godot 4.7.2, headless albo xvfb + OpenGL (llvmpipe); maszyna była obciążona przez inne sesje, czasy ±20 %.

## Zrobione (kod + testy w gałęzi)

| Obszar | Znalezisko | Poprawka | Liczby |
|---|---|---|---|
| Pamięć | `ArrivalScene`: klatki przejazdu (1080×1920, 8,3 MB RGBA) zamówione w tle i niepokazane (stuknięcie pomija przejazd, Wstecz, ograniczenie ruchu) zostawały w `ResourceLoader` do końca sesji | każde zamówienie jest zapisywane i odbierane przy końcu przejazdu / wyjściu sceny; dekodujące się jeszcze — sprzątane co 0,25 s; przy ograniczeniu ruchu klatki w ogóle się nie wczytują; ostatnia klatka znika po przenikaniu | tekstury bez żadnego ekranu po 13 zleceniach: **88,7 → 7,7 MB**; szczyt na ekranie zamka 123–131 → 33–42 MB (xvfb, 40 cykli) |
| Start | autoloady kompilowały przy starcie cały widok zamka i ekran przyjazdu (`is LockPhotorealView` w `UiA11y`, `DayAfter` w `JobRun`, `TutorialCoach` w `Practice`, 3 klasy w `ContentPacks`) | odwołania przez nazwę skryptu / `load()` w chwili użycia | start → pierwszy autoload 468–559 → 312–401 ms; start → menu 860–950 → 720–790 ms (headless) |
| Start | stałe 100 ms czekania w `boot.gd` przy każdym starcie | czeka tylko, aż skończą się wczytywania menu w tle (maks. 2 s) | w liczbach wyżej |
| Start | `Sfx` kolejkował przy starcie także nagrody, foley i głosy obsady | dwa etapy: menu (ambient, muzyka, UI) od razu, reszta po klikach zamka | Sfx `_ready` ~50 → ~25 ms (headless) |
| Zapis | `save.json` nadpisywany w miejscu (pełny dysk / kill = pusty plik = utrata kariery); uszkodzony plik po cichu zastępowany nową karierą | `SafeFile`: plik tymczasowy + rename, kopia `save.json.bak`, uszkodzony plik odkładany jako `save.corrupt.json`, zły typ wartości → domyślna, nieudany zapis zostaje w pamięci i jest ponawiany (następna zmiana, pauza aplikacji, zamknięcie) | 22 testy |
| Zapis | rozliczenie zlecenia = 4–5 zapisów pliku w jednej klatce | `Save.hold()/release()` — jeden zapis | 1 zapis (test) |
| Ustawienia | to samo co zapis | atomowo + `.bak` + kontrola typów | w testach zapisu |
| Paczki | pełny dysk w trakcie pobierania kończył się „checksum” po pobraniu całości; `installed.json` pisany w miejscu; śmieci `.part` starych buildów | kontrola wolnego miejsca przed startem, błąd „storage” z zachowaniem całych bajtów, atomowe listy, gotowa paczka zapomniana przez listę jest sprawdzana zamiast pobierana, sprzątanie przy starcie | 11 testów |
| Pauza aplikacji | brak obsługi `NOTIFICATION_APPLICATION_PAUSED` | `Save`/`Settings` dopisują zaległy zapis; `Nav` pauzuje otwarty zamek jak przycisk Wstecz | testy w `test_nav_back.gd`, `test_save_robustness.gd` |
| Lista zleceń | po D-132 lista budowała 1159 węzłów przy każdym wejściu (8 na płytkę, ~110 płytek w zwiniętych rozdziałach) | treść płytki powstaje przy pierwszym otwarciu rozdziału; lista składana poza drzewem; znak rodziny nie przerysowuje się bez zmiany | 1159 → 457 węzłów; `_ready` ok. 71–82 → 46–61 ms (headless, zaszumione) |
| Test długiej sesji | — | `game/tests/soak_run.gd` + `soak.tscn` (`-- --cycles=200 --out=…`, `--only=` do szukania winnego ekranu), krótka wersja w GUT `test_soak.gd` | 220 cykli headless i 40 cykli xvfb: obiekty, zasoby, węzły, sieroty, połączenia sygnałów płaskie |

Uwaga do soaka: headless Godot 4.7.2 sam zwiększa pamięć statyczną o ~29 B na każdy utworzony `Control` (sprawdzone na pustym projekcie; z OpenGL 0). Dlatego ścisły limit pamięci statycznej i tekstur działa tylko z prawdziwym rendererem (xvfb).

## Stan testów

- Uruchomione pojedynczo i zielone: `test_save_robustness` (22), `test_pack_store_robustness` (11), `test_nav_back` (6), `test_save`, `test_settings`, `test_arrival_frame_release` (7), `test_arrival_scene` (20), `test_job_list_d132` (16).
- `test_idle_cost`: 6/7 — jedyny czerwony poprawiony (porównanie nazw auto-numerowanych węzłów), **nieuruchomiony ponownie**; tak samo nie uruchomiono go po zmianie „lista składana poza drzewem”.
- `test_soak.gd` (GUT): napisany, **nieuruchomiony**.
- **Pełny GUT: nieuruchomiony. Bot kariery (`qa/run_career.sh`): nieuruchomiony.** Ryzyko: `get_value()` zwraca teraz wartość domyślną przy niezgodnym typie; lista zleceń ma puste płytki w zwiniętych rozdziałach (bot i testy szukają `Job_<id>` — przyciski nadal istnieją).

## Zostaje

1. Pełny GUT + bot kariery, poprawki tego, co wyjdzie.
2. `docs/handoff/PERF-STABILITY-2026-11-16.md` (pełny raport) i wpis D-136 w `docs/DECISIONS.md` — nienapisane; ta notatka jest ich szkicem.
3. Krok soaka w `.github/workflows/perf-budget.yml` (xvfb + llvmpipe jak w `game-screens.yml`) — niedodany.
4. Czyste pomiary przed/po na nieobciążonej maszynie (lista zleceń, start), soak 200 cykli pod xvfb na końcowym kodzie.
5. Niezbadane: czas klatki ekranu zamka (poza istniejącym `test_perf.gd`), start z paczki eksportowanej (I18n z `.translation`), 91 zasobów zostających po pierwszej wizycie w każdej rodzinie zamka (stałe, nie rosną).
6. Na telefonie (SM-A165F): `LW_BOOT`, PSS menu/zamek po poprawce przyjazdu, wejście w listę zleceń.
