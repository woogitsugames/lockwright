# qa/ — automat kariery (sesja C, etap 3, zadanie 3)

Bot przechodzi całą karierę w Godocie headless: samouczek, wszystkie zlecenia z `data/jobs` (przez listę → przyjazd →
weryfikację → zamek → zapłatę), zakupy w warsztacie i gablotę. Zamki rozwiązuje skryptowany bot lockcore
(`LockcoreSession.solve(family, seed, tier)` z GDExtension), którego wejścia są podawane scenie zamka przez podmieniony
`InputSampler` — jeden wiersz na krok fizyki 120 Hz, czyli dokładnie tą samą drogą co dotyk gracza.

`game/` nie jest zmieniany: skrypt kopiuje projekt do katalogu roboczego, dokłada `res://qa_bot/` i świeży `user://`.

```bash
qa/run_career.sh [godot] [timeout_s]      # domyślnie: godot, 1800 s; QA_WORK=katalog roboczy
QA_STRICT=1 qa/run_career.sh              # kod wyjścia 1, gdy wynik ≠ OK (lokalnie, przed pushem do game/)
QA_FAIL_ON_INFRA=1 qa/run_career.sh       # tak działa CI: kod 2 tylko przy awarii bota/silnika/workflowu
```

Wynik: `qa/out/report.md` (po polsku), `report.json` (`lockwright.qa-report/1`), `career.log`, `verdict.txt`.

| Wykrywa | Jak |
|---|---|
| crash | kod wyjścia, „Program crashed”, brak raportu bota |
| soft-lock | > 60 wejść na ten sam ekran, 15 s bez zmiany i bez akcji, zamek nieotwarty w 300 s symulacji |
| ekran bez wyjścia | brak widocznego, aktywnego przycisku (zamek: także przez pauzę, D-12) |
| brakujące klucze i18n | ostrzeżenia `I18n` w logu |
| błędy skryptów / silnika | `SCRIPT ERROR`, `ERROR:` (zliczone) |
| czas sesji | czas symulowany (120 Hz) i zegarowy, czas każdego zamka |

Polityka bota: przyjmuje każde zlecenie, odmawia zleceniom `job.refuse_*` (JOBS.md §5), każde zlecenie próbuje
najwyżej 2 razy, w warsztacie naciska każdą akcję raz, w gablocie otwiera do 3 notek, odwiedza ustawienia.
Nieznany ekran → przyciski „dalej/OK/Wstecz” i wpis w „Nieznane ekrany” (znak, że trzeba dopisać politykę).

Workflow: `.github/workflows/qa-career.yml` (co noc 02:17 UTC + push do `game/**`, `qa/**`), artefakt `qa-career-report`,
raport w podsumowaniu joba. Znalezione błędy: `docs/handoff/SESSION-C-REVIEW.md` (N-13+).

**CI: błędy gry vs błędy workflowu.** W `qa-career` run jest **czerwony**, gdy zawiódł sam automat (brak
raportu bota `QA_REPORT`, przekroczony czas, crash silnika, błąd kroku workflowu) **albo gra ma bloker**: skrypt GDScript
się nie kompiluje lub w całej karierze nie dało się dojść do żadnego zamka (N-29). Problemy **gry** (soft-locki, ekrany
bez wyjścia, brakujące klucze, błędy skryptów) trafiają do `report.md` w podsumowaniu runu i jako adnotacje ⚠
„QA gry: …”; werdykt „OK / PROBLEMY” jest w `verdict.txt`. Dzięki temu czerwony `qa-career` zawsze znaczy „napraw automat”.

## Część 2 (etap 4): profile graczy, EN, „w ciemności”, ekonomia
```bash
cmake -S lockcore -B lockcore/build && cmake --build lockcore/build --target replay_tool
qa/run_matrix.sh godot lockcore/build/replay_tool     # 5 przebiegów -> qa/out/<przebieg>/, qa/out/matrix.md
```
| Zmienna | Znaczenie |
|---|---|
| `QA_PROFILE=solver\|feel\|clumsy` | ręka gracza: skryptowany solver (`LockcoreSession.solve`) albo natywne boty lockcore `replay_tool record … --feel` („średni”) / `--clumsy` („niezdarny”) dla tego samego zamka (rodzina, seed, tier ze sceny) |
| `QA_REPLAY_TOOL` | ścieżka do `lockcore/build/replay_tool` |
| `QA_LANG=en` | cała kariera po angielsku (`Settings.language` + `I18n.apply_language`) |
| `QA_DARK=1` | tryb „w ciemności” na każdym zamku; raport sprawdza, czy każde zdarzenie zamka ma dźwięk i haptykę |
| `QA_OUT` | katalog raportu |

Raport ma też: **ekonomię** (wypłata w grze vs model `tools/econ_sim.py` dla odpowiadającego profilu: solver→careful,
feel→average, clumsy→clumsy; różnice > 10% oznaczone ⚠), **kanały** (pary zdarzenie/materiał bez dźwięku lub haptyki)
i **zlecenia niewidoczne na liście**. Ucięte teksty EN na ekranach: `qa/bot/a11y_shots.gd -- --lang en` (wymaga X/Xvfb).

## Część 3 (etap 5): zasoby — `qa/assets/check_assets.py`
Statycznie, na danych i kodzie gry (mapowania czytane z `job_arrival.gd` i `sfx.gd`, bez kopii): każde zlecenie
(`data/jobs`, `data/jobs_ch7`) ma tło przyjazdu G07; każda mówiąca postać ma portret G09 i głos S03 w miejscu, w którym
gra go szuka; każdy dźwięk z `data/haptics_patterns.json` (komplet wariantów dla co najmniej jednego materiału),
z `AMBIENCES` i z każdego wywołania `Sfx.play_*(&"…")` istnieje. Raport: `qa/out/assets/report.md`, w CI krok w
`qa-career` (ostrzeżenia ⚠, bez czerwonego runu). Lokalnie: `python3 qa/assets/check_assets.py`.
