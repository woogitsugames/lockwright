# T20 — Tryb Ćwiczeń: 30 zamków

## Raport

Zaprojektowano **30 autorskich zamków treningowych** jako pliki `lockwright.lock/1`, ze stabilnymi identyfikatorami `practice.t01`–`practice.t30`. Każdy uczy jednego wyraźnie nazwanego aspektu mechaniki i ma nazwę, cel oraz krótką uwagę mistrza Henryka w dwóch językach. Wszystkie mechanizmy są wymyślone; to materiał gry, nie instrukcja otwierania rzeczywistych urządzeń.

**Pliki:** `practice/t01.json` … `practice/t30.json` (30), `practice.csv` (90 tłumaczeń, kolumny `key,en,pl`), `README.md` (ten plik).

**Rodziny:** wooden_pin: 2, wafer: 5, warded: 3, pin_tumbler: 9, ring_combo: 3, lever: 5, lever_detector: 3.

## Kolejność

Sześć bloków o **niemalejącym tierze**: t1 (01–06) uczy spokojnego ruchu, kolejności, płytki, bramki i dopasowania; t2 (07–13) dodaje przepchnięcie, naprawę, metalowe stosy, pierścienie i rygiel; t3 (14–19) zawęża okna i wprowadza pary, pozorne rowki, zapadki i sprężynę; t4 (20–24) odróżnia fałszywe osadzenie, kontrrotację, rowek zapadki i ząbkowanie; t5 (25–28) łączy rodzaje sygnałów i wprowadza ostrzeżenie oraz reset detektora; t6 (29–30) sprawdza precyzję przy osłabionych sygnałach i złożony detektor. **Tier nie maleje, choć różne rodziny mogą wymagać innego wysiłku w tym samym tierze** (por. `lockcore/BALANCE.md`).

Każda lekcja ma jeden `focus` w `presentation.practice`; pozostałe elementy spełniają rolę kontekstu i utrwalenia, nie osobnego celu. Zadania `detector_trip` / `detector_reset` uczą rozpoznawać te zdarzenia **gdy wystąpią**; sama definicja zamka nie wymusza błędu gracza ani automatycznego wywołania resetu.

| # | Plik | Tier | Rodzina | Nazwa PL / EN | Jedyny cel (`focus`) |
|---:|---|---:|---|---|---|
| 01 | `practice/t01.json` | 1 | `wooden_pin` | Spokojna ręka / A Steady Hand | `open_hold` |
| 02 | `practice/t02.json` | 1 | `wooden_pin` | Dwa ciche stuknięcia / Two Soft Knocks | `binding_order` |
| 03 | `practice/t03.json` | 1 | `wafer` | Uparta płytka / The Stubborn Plate | `binding` |
| 04 | `practice/t04.json` | 1 | `wafer` | Suchy klik / The Dry Click | `set_cue` |
| 05 | `practice/t05.json` | 1 | `warded` | Smuga światła / A Line of Light | `ward_gap` |
| 06 | `practice/t06.json` | 1 | `warded` | Dobre dopasowanie / A Better Fit | `bit_choice` |
| 07 | `practice/t07.json` | 2 | `wafer` | O krok za daleko / One Step Too Far | `overset` |
| 08 | `practice/t08.json` | 2 | `wafer` | Lekki oddech / An Easy Breath | `overset_recovery` |
| 09 | `practice/t09.json` | 2 | `pin_tumbler` | Pierwszy w kolejce / First in Line | `binding_order` |
| 10 | `practice/t10.json` | 2 | `pin_tumbler` | Utrzymaj chwilę / Keep the Moment | `tension_hold` |
| 11 | `practice/t11.json` | 2 | `ring_combo` | Dziesięć przystanków / Ten Small Stops | `detents` |
| 12 | `practice/t12.json` | 2 | `ring_combo` | Który pierścień? / Which Ring? | `ring_binding` |
| 13 | `practice/t13.json` | 2 | `warded` | Ostatnia sprężyna / The Last Spring | `spring_bolt` |
| 14 | `practice/t14.json` | 3 | `pin_tumbler` | Wąska półka / The Narrow Shelf | `narrow_window` |
| 15 | `practice/t15.json` | 3 | `pin_tumbler` | Zaginiony klik / A Missing Click | `overset_recovery` |
| 16 | `practice/t16.json` | 3 | `wafer` | Para do pary / A Matching Pair | `multi_binding` |
| 17 | `practice/t17.json` | 3 | `ring_combo` | Fałszywy rowek / The Wrong Groove | `false_notch` |
| 18 | `practice/t18.json` | 3 | `lever` | Otwarta bramka / The Open Gate | `lever_gate` |
| 19 | `practice/t19.json` | 3 | `lever` | Pamięć sprężyny / Spring Memory | `spring_return` |
| 20 | `practice/t20.json` | 4 | `pin_tumbler` | Dwa różne kliknięcia / Two Different Clicks | `false_set` |
| 21 | `practice/t21.json` | 4 | `pin_tumbler` | Delikatny powrót / A Gentle Return | `counter_rotation` |
| 22 | `practice/t22.json` | 4 | `lever` | Udawana bramka / The Pretend Gate | `false_gate` |
| 23 | `practice/t23.json` | 4 | `pin_tumbler` | Szorstka nuta / A Rough Note | `serration` |
| 24 | `practice/t24.json` | 4 | `lever` | Jeszcze jedna bramka / One More Gate | `multiple_gates` |
| 25 | `practice/t25.json` | 5 | `pin_tumbler` | Mieszane sygnały / Mixed Signals | `mixed_security` |
| 26 | `practice/t26.json` | 5 | `lever` | Bramka po bramce / Gate After Gate | `two_false_gates` |
| 27 | `practice/t27.json` | 5 | `lever_detector` | Ostrzegawcza zapadka / A Warning Catch | `detector_trip` |
| 28 | `practice/t28.json` | 5 | `lever_detector` | Powrót do kreski / Back to the Mark | `detector_reset` |
| 29 | `practice/t29.json` | 6 | `pin_tumbler` | Cichy warsztat / The Quiet Workshop | `quiet_precision` |
| 30 | `practice/t30.json` | 6 | `lever_detector` | Ostatnia kontrola / The Final Check | `detector_mastery` |

## Kontrakt danych

- Każdy JSON ma standardowe klucze `schema`, `family`, `rules_version`, `id`, `source`, `seed`, `difficulty`, `spec`, `presentation`.
- `rules_version=2` dla `lever`/`lever_detector`, a `1` dla pozostałych pięciu rodzin. `source=authored`; `seed` jest **łańcuchem dziesiętnym**.
- Każdy `*_q16` to **liczba całkowita** (jednostka 65536 = 1), czasy w `spec` w krokach @120 Hz. Blok `difficulty` jest opisem autorskiego poziomu; `spec` zawiera rzeczywiste parametry modelu.
- `presentation.practice` to **dodatkowa metadana wyłącznie dla warstwy gry**: `order`, `focus`, `title_key`, `goal_key`, `hint_key`. Obecny parser `lockcore` czyta tylko `presentation.material` i **ignoruje** inne pola. Uwaga: `lock_to_json()` przy ponownym serializowaniu tych dodatkowych danych nie zachowa. Odczyt lokalizacji powinien korzystać z pliku źródłowego lub osobnej warstwy metadanych, nie z `LockSpec`.
- W `practice.csv` są dokładnie trzy klucze na zamek (`title`, `goal`, `hint`), każdy z PL i EN; zaimportować do systemu i18n gry. Nie zapisano żadnych tekstów dla gracza w polach `spec`.
- Pliki nie tworzą jeszcze osobnego interfejsu wyboru Trybu Ćwiczeń; to komplet danych do integracji z ekranem gry.

## Sprawdzenie

Przed zapisem przeprowadzono **statyczną weryfikację dla 30/30 JSON**:
1. Wymagane pola i typy, integer-only, unikalność ID, zgodność deklarowanej rodziny, tieru i `rules_version`; dokładnie 30 poziomów.
2. Zgodność nazw kluczy i struktur `spec` z `params_to_json` / `params_from_json` siedmiu rodzin w `lockcore/src/families/`.
3. Granice i inwarianty odwzorowane z `validate()` oraz najważniejsze ograniczenia `oracle()`: pozycje elementów, szerokość okien, pasma napięcia, porządek i liczebność elementów, kolejność bramek, marginesy detektora, wykonalny grot w rodzinie `warded`, odstępy pierścieni.
4. Każdy z 90 kluczy i18n ma oba języki; każda podpowiedź mieści się w 130 znakach; globalny tier jest niemalejący.

**Nie wykonano** binarnego `lock_from_json()` ani bota wyroczni / feeling-bota w tym środowisku GitHub Connector; sama walidacja statyczna nie zastępuje uruchomienia `lockcore`. Do pełnej bramki integracyjnej potrzebne jest narzędzie `replay_tool check <file>` lub `verify_seeds --authored <dir>` (luka opisana także w `docs/LEVELS.md` §8). Nie należy raportować wyników botów jako zaliczonych bez tego testu.

## Co się nie udało / zakres ograniczeń

- Brak uruchomienia bota na 30 autorskich konfiguracjach — wymaga dodania obsługi sprawdzania plików `authored` do CLI (poza zakresem katalogu T20).
- `lockcore` nie serializuje dodatkowej metadanej `presentation.practice`; potrzebna warstwa gry do jej odczytu (bez zmian poza `contrib/gpt/T20/`).
- Nie uruchamiano playtestu na urządzeniu z dźwiękiem/haptyką; odróżnialność sygnałów wymaga oceny w trybie Ćwiczeń.

Źródła projektowe: `CLAUDE.md`, `docs/DESIGN.md`, `docs/CLIENTS.md`, `docs/JOBS.md`, `docs/DECISIONS.md` (D-06, D-51), `docs/LOCKS.md`, `docs/LEVELS.md`, `lockcore/README.md`, `lockcore/BALANCE.md` i rzeczywiste nagłówki/serializatory `lockcore`.
