# T28 — Zeszyt mistrza Henryka: 80 nowych wpisów

**Status:** treści gotowe do integracji. **Data:** 2026-11-05.

## Zrobione

- Przygotowano **80 nowych** wpisów zeszytu po polsku i angielsku, po 10 wpisów dla każdego tematu: fałszywy luz, złamania wytrychów, odmowy, otwarcia w ciemności, powracający klienci, zima, noc i deszcz.
- Każdy wpis ma unikatowy klucz `notebook.more.*` oraz deklaratywny warunek wyzwolenia, oparty na zdarzeniach próby lub zakończeniu zlecenia.
- Styl: pierwsza osoba, czas przeszły, spokojny głos warsztatowego zeszytu, dyskretny humor, bez instrukcji otwierania i bez marek.
- Odmowy i weryfikacje przedstawiono jako prawidłowy rezultat. Wpisy o otwartych drzwiach nie oznaczają zgody na wejście bez weryfikacji.

## Pliki

| Plik | Zawartość |
| --- | --- |
| `notebook_more.csv` | 80 wpisów PL/EN z wyzwalaczami, nagłówek: `key,en,pl,trigger`, UTF-8, RFC 4180, CRLF. |
| `README.md` | Raport, kontrakt proponowanych zdarzeń i ograniczenia integracji. |

## Walidacja

- Wiersze danych: **80**; unikalne klucze: **80**; brak duplikatów tekstów.
- Limit z T28: **160 znaków** w każdym języku, przyjęto ostrzejszy limit **130 znaków** z `docs/CLIENTS.md`.
- Maksymalna długość EN: **105** znaków; PL: **93** znaków (liczone jako znaki Unicode).
- Nie dodano nazw producentów, opisów prawdziwych systemów zamknięć ani instrukcji technicznych.
- Zastosowano nazewnictwo `false_set`, `overset`, `drop`, `break`, `wear`, `stress`, `set` i `open` zgodne ze słownikiem `docs/DESIGN.md`.

## Proponowany kontrakt wyzwalaczy

To **deklaracje projektowe**, a nie działające zapytania ani istniejące API. Każdy warunek to koniunkcja fragmentów rozdzielonych średnikami; licznik `count(event)` odnosi się do jednej próby, a `result` do zdarzenia zamykającego wskazany zakres.

- `scope=attempt`: odczyt po zakończeniu próby; `result=open|failed`. `scope=job`: po zamknięciu zlecenia, `result=job_completed|job_refused|job_resolved|job_deferred`. `context=non_tutorial` wyklucza samouczek.
- `first_career(false_set)`: pierwszy taki sygnał w karierze, liczony po próbie spoza samouczka. `milestone(event,N)`: **jednorazowe** przekroczenie wartości N przez licznik kariery. Dla `break` liczy złamania, dla `job_refused` odmowy; `dark_open`, `client_returned`, `winter_job_completed`, `night_job_completed`, `rain_job_completed` to **proponowane agregaty** budowane z metadanych prób/zleceń.
- `previous_attempt_count(break)` i `previous_attempt_result`: stan poprzedniej zakończonej próby tej samej sesji; `attempts` to liczba prób w zleceniu.
- `dark` to tryb bez obrazu; `time=night|late_night|morning`, `season=winter`, `weather=rain`, `delayed`, `damage=none`: **proponowane znaczniki świata i rozliczenia zlecenia**, wymagające podłączenia do logiki gry.
- `client_returned`, `client_visit_number`, `referred_client`, `verified_by=neighbour|manager|documents`, `verification=unconfirmed`, `partial_refusal`, `entry=none`: **proponowane zdarzenia fabularne**. `job_id` identyfikuje znane z `docs/JOBS.md` zlecenie bez prefiksu `job.`.
- Wpisy za otwarcie w zleceniu wolno wyświetlać **wyłącznie po potwierdzeniu uprawnienia do lokalu i zgody**; rezultaty `job_refused` i `job_deferred` nie wymagają otwarcia. `job_resolved;entry=none` oznacza zakończenie bez manipulacji zamkiem.

## Reguły wyświetlania i integracji

- Te wpisy uzupełniają `job.<id>.note` z `docs/CLIENTS.md`, nie zastępują go.
- Dla jednego zakończenia próby albo zlecenia pokazać maksymalnie **jeden** opcjonalny dopisek łącznie z `contrib/gpt/T10/notebook_extra.csv`. Proponowana kolejność: jednorazowy kamień milowy > wpis konkretnego zlecenia > warunek wieloskładnikowy > ogólne tło; remisy rozstrzyga kolejność leksykalna klucza.
- Wpisy dla tego samego klienta powinny być ograniczone na zlecenie, a odczytywane wpisy rotowane, aby nie pokazywać powtórek.
- Wyświetlanie odbywa się po zdarzeniu, na diegetycznej stronie zeszytu; nie podczas manipulacji mechanizmem.
- Dla EN zachowano naturalne, krótkie brzmienie zamiast dosłownych kalek polskich fraz.

## Czego nie wykonano

1. **Nie wdrożono** adaptera zdarzeń, agregatów `milestone(...)`, metadanych pogody/sezonu ani UI zeszytu: zlecenie zabrania zmian poza `contrib/gpt/T28/`.
2. Nie przeprowadzono testów uruchomieniowych Godot ani testów na urządzeniach; wymagają późniejszej integracji.
3. Nie modyfikowano istniejących tekstów, `game/i18n/content.csv`, zadań i plików T10.

**Kontekst:** `CLAUDE.md`, `docs/DESIGN.md`, `docs/CLIENTS.md`, `docs/JOBS.md`, `docs/DECISIONS.md` (D-06, D-51), `contrib/gpt/T10/notebook_extra.csv`.
