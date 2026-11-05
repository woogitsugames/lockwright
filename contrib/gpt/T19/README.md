# T19 — raport przekazania

**Data:** 2026-11-05  
**Repozytorium:** `woogitsugames/lockwright`  
**Jedyny zakres zmian:** `contrib/gpt/T19/`

## Co zrobiono

- Opracowano **20 nowych eksponatów** (od starożytnej Grecji do 1970 r.), bez dublowania 20 istniejących identyfikatorów z `docs/SHOWCASE.md`.
- Każdy eksponat ma nazwę PL i EN, epokę, notkę PL i EN, dwa odnośniki do materiałów muzealnych/naukowych, warunek odblokowania oraz wskazówki dla grafika.
- Zweryfikowano limity znaków: najdłuższa notka PL **294** znaków, EN **271** znaków (limit 400).
- Uwzględniono rozróżnienie niepewnego datowania od pewnego wpisu muzealnego; nie dodano instrukcji otwierania zamków, marek w tekstach dla gracza, terminów premier ani cen.
- Odblokowania opisano jako propozycje, ponieważ obecne dane gry i system eventów mogą wymagać integracji.

## Pliki

- `SHOWCASE_ADD.md` — 20 pełnych kart eksponatów, źródła i briefy dla grafika.
- `showcase_add.csv` — `key,en,pl`, 40 wierszy i18n (20 tytułów + 20 notek), UTF-8.
- `README.md` — raport po polsku.

## Co się nie udało / ograniczenia

- Nie wdrożono tekstów do plików gry ani `docs/SHOWCASE.md` — zlecenie zabrania zmian poza tym katalogiem.
- Nie przygotowano fotografii ani renderów; dostarczono wyłącznie briefy do ich późniejszego wykonania.
- Przy części obiektów drugie źródło ma charakter porównawczy. Pochodzenie kłódki z Kantonu opiera się na opisie katalogowym; przy kluczu greckim nie rozstrzygnięto dokładnego działania mechanizmu. Te ograniczenia zaznaczono w odpowiednich kartach.
- Nie testowano proponowanych triggerów w działającej grze; wymagają połączenia z rzeczywistymi eventami progresji.

## Walidacja

- Liczba nowych wpisów: 20/20.
- Dwa źródła na wpis: 20/20.
- Notki poniżej lub równe 400 znaków: PL 20/20; EN 20/20.
- Klucze i18n: 40 unikalnych (dwa na wpis).
- Zero zmian poza `contrib/gpt/T19/`.
