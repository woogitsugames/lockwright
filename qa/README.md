# qa/ — automat kariery (sesja C, etap 3, zadanie 3)

Bot przechodzi całą karierę w Godocie headless: samouczek, wszystkie zlecenia z `data/jobs` (przez listę → przyjazd →
weryfikację → zamek → zapłatę), zakupy w warsztacie i gablotę. Zamki rozwiązuje skryptowany bot lockcore
(`LockcoreSession.solve(family, seed, tier)` z GDExtension), którego wejścia są podawane scenie zamka przez podmieniony
`InputSampler` — jeden wiersz na krok fizyki 120 Hz, czyli dokładnie tą samą drogą co dotyk gracza.

`game/` nie jest zmieniany: skrypt kopiuje projekt do katalogu roboczego, dokłada `res://qa_bot/` i świeży `user://`.

```bash
qa/run_career.sh [godot] [timeout_s]      # domyślnie: godot, 1800 s; QA_WORK=katalog roboczy
QA_STRICT=1 qa/run_career.sh              # kod wyjścia 1, gdy wynik ≠ OK (tak działa CI)
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
