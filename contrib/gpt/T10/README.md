# Zlecenie T10 — osiągnięcia, wskazówki Henryka, wpisy zeszytu

**Stan:** przygotowano komplet treści PL/EN do integracji. **Nie wdrożono** logiki osiągnięć ani wyzwalaczy w grze — zadanie ograniczało zapis do `contrib/gpt/T10/`.
**Data:** 2026-11-05.

## Wynik i zawartość

| Plik | Zawartość |
| --- | --- |
| `achievements.csv` | 40 osiągnięć: nazwy i opisy PL/EN, warunki, fazy wdrożenia, punkty, jawność. |
| `tips.csv` | 60 krótkich wskazówek PL/EN w głosie mistrza Henryka, w tym dokładnie 10 etycznych. |
| `notebook_extra.csv` | 30 krótkich notatek PL/EN po nietypowych zdarzeniach w mechanizmie. |
| `README.md` | Raport, walidacja, instrukcja podłączenia danych. |
| `ASSETS.md` | Rejestr pochodzenia tekstów i potwierdzenie braku plików graficznych/dźwiękowych. |

## Potwierdzona walidacja

| Parametr | Wynik |
| --- | --- |
| Liczba osiągnięć | **40/40** |
| Maksymalna nazwa osiągnięcia EN / PL (limit 30) | **22 / 22** |
| Maksymalny opis osiągnięcia EN / PL (limit 100) | **65 / 72** |
| Liczba wskazówek | **60/60** |
| Wskazówki etyczne | **10/10** (`category=ethics`) |
| Maksymalna wskazówka EN / PL (limit 110) | **73 / 71** |
| Liczba wpisów zeszytu | **30/30** |
| Maksymalny wpis zeszytu EN / PL (limit 130 z `docs/CLIENTS.md`) | **90 / 93** |
| Łączna punktacja osiągnięć | **1000** (10 × 10, 20 × 25, 10 × 40) |

Walidowano liczbę znaków Unicode osobno w obu językach, rozkład punktów i unikatowość kluczy. CSV: **UTF-8**, **RFC 4180**, przecinki jako separatory, cudzysłowy przy wszystkich wartościach, zakończenia wierszy CRLF. Kolumny każdego CSV zaczynają się od `key,en,pl`.

Osiągnięcia nagradzają odkrywanie mechanik, poprawne ukończenie prób i etyczne decyzje; **brak celów typu „otwórz 100 zamków” czy „zaloguj się przez 30 dni”**. Nie ma nazw handlowych ani instrukcji do realnych zamków.

## Kontrakt danych

### `achievements.csv`

Nagłówek: `key,en,pl,description_en,description_pl,trigger,phase,category,hidden,points`.

- `hidden` to tekstowe `true` albo `false`, przeznaczone do konwersji na boolean. Ukryte są przede wszystkim spoilery i wyzwania zaawansowane.
- `phase`: `mvp` — zakres obecnego planu MVP, `phase1` — Tryb Zleceń i opowieść, `extended` — kolejne rodziny zamków. **MVP to plan treści, a nie gwarancja istniejącego endpointu.** `docs/PROGRESSION.md` §7 ogranicza obecnie w MVP rodzinę symulacji do `pin_tumbler` i `wafer`. Inne rodziny nie powinny trafić do katalogu osiągnięć przed zaimplementowaniem.
- `trigger` jest czytelną **deklaracją warunku do zaimplementowania**, nie gotowym kodem Godot ani typem zdarzenia `lockcore`.
  Przykład: `result=open;count(drop)=0;count(break)=0` oznacza, że w jednej próbie nastąpiło otwarcie bez zrzutu i złamania.
- Zapis `count(x)>=N` dotyczy liczby zdarzeń danej próby, `profile=x` profilu z `docs/LEVELS.md`, a `context=non_tutorial` wyłącza lekcje i samouczek.
- `result=job_completed`, `job_refused`, `job_resolved` to **proponowane sygnały warstwy fabularnej**; `verified` i `verified_by` muszą pochodzić z końcowego stanu legalności i zgody w zleceniu, nie z napisu czy niezależnej animacji.
- `challenge_complete`, `workshop_stop`, `tool_repaired` są sygnałami warstwy meta, które trzeba zintegrować oddzielnie od `lockcore`.
- Każde osiągnięcie odblokowuje się **raz na konto**; lokalny zapis ma być idempotentny, a synchronizacja Game Center / Google Play Games może nastąpić po odzyskaniu połączenia. Warunki otwarcia na zleceniu wymagają przejścia weryfikacji — nigdy nie przyznawać nagrody za otwarcie bez zgody.

### `tips.csv`

Nagłówek: `key,en,pl,category,context`.

- `category=ethics` obejmuje dokładnie 10 wskazówek dotyczących prawa do lokalu, weryfikacji, odmowy, dyskrecji i wyceny.
- `context`: `loading` — kartka podczas przejścia; `pre_job` — przed zleceniem; `workshop` — warsztat; `mode_dark` — odpowiedni tryb.
- Zgodnie z `docs/HUD.md`, **nie wyświetlać pływających paneli w czasie manipulacji mechanizmem**. Teksty umieszczać w momentach przerywnika, na kartce lub innym diegetycznym nośniku.
- Uwzględnić niedawno używane klucze przy losowaniu (ogranicznik powtórek), a wskazówki odnoszące się do klientów i postaci pokazywać dopiero po ich wprowadzeniu fabularnym.

### `notebook_extra.csv`

Nagłówek: `key,en,pl,trigger,scope,family,priority,phase`.

- Wpisy pokazują się **po** próbie (otwarcie lub porażka) albo po zakończeniu dyżuru. Nie zastępują `job.<id>.note` z `docs/CLIENTS.md` — stanowią opcjonalny drugi, krótszy dopisek.
- `scope=attempt` ogranicza historię do bieżącego zamka; `scope=run` obejmuje cały dyżur. `family=any` oznacza brak filtra rodziny.
- Warunek w `trigger` jest listą porównań oddzielonych `;`. `count(event)` liczy zdarzenia; `max_streak(event)` maksymalną liczbę kolejnych zdarzeń tego typu; `sequence(a,b,c)` wymaga zdarzeń w tej kolejności (nie muszą sąsiadować). `dark=true` pochodzi z ustawienia próby; `failure` z finalnej przyczyny niepowodzenia. Kolejność wydarzeń i podzdarzenia trzeba agregować ze strumienia `lockcore`.
- W przypadku kilku pasujących warunków dopisać **maksymalnie jeden wpis** na zamkniętą próbę. Wygrywa wyższe `priority`; remis rozstrzyga leksykalna kolejność `key`.
- `wear` bywa raportowane po próbie. Trzeba przypisać to zdarzenie do właśnie zakończonej próby przed sprawdzeniem warunków. Liczniki `attempt` wyzerować przy ponownym wejściu do zamka.

## Zgodność i uwagi

- W tekstach nie ma instruktażu do realnych zamków ani marek producentów, a ton pozostał spokojny, z odrobiną suchego humoru.
- Nazwy sygnałów w warunkach odwołują się do słownika `docs/DESIGN.md` i `docs/FEEL.md`; opisane meta-sygnały i agregaty **nie zostały potwierdzone jako istniejące w kodzie gry**.
- Zeszyt jest pisany w pierwszej osobie, w czasie przeszłym, bez przypisywania klientom nieznanych historii, zgodnie z `docs/CLIENTS.md`.
- Wcześniejsze założenia o rodzinach w `docs/PROGRESSION.md` skorygowano według §7 tego dokumentu.

## Czego nie wykonano i kolejne kroki

1. **Nie wdrożono kodu** przyznawania osiągnięć, analityki wyzwalaczy ani połączeń Apple/Google, gdyż zapis poza `contrib/gpt/T10/` jest zabroniony.
2. Nie przeprowadzono testów runtime w iOS/Android — są do wykonania po integracji adaptera i18n i odczytu CSV.
3. Potrzebne uzgodnienie z zespołem silnika dotyczące stabilnych sygnałów `job_refused`, `challenge_complete`, sposobu zapisu historii zdarzeń i synchronizacji osiągnięć. Następnie test automatyczny: każdy klucz dostaje nagrodę maksymalnie raz, tryb samouczka nie daje niedozwolonych nagród, nieudana weryfikacja nigdy nie prowadzi do osiągnięcia za otwarcie.

Dokumenty referencyjne: `CLAUDE.md`, `docs/styles/realizm.md`, `docs/DESIGN.md`, `docs/HUD.md`, `docs/PROGRESSION.md`, `docs/CLIENTS.md`, `docs/FEEL.md`.
