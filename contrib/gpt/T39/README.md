# T39 — samouczek Lockwright, teksty PL/EN/DE

**Data:** 2026-11-05  
**Plik do importu:** `tutorial_lines.csv` (`UTF-8`, nagłówek **`keys,en,pl,de`**).  
**Skrypt i kontrola:** `build.py` generuje CSV i sprawdza strukturę, unikalność kluczy, limity, znaki wykrzyknika i brak niedozwolonego słowa.

## Zasady redakcyjne

- Głos Henryka: spokojny, ciepły, konkretny, dyskretny humor; żadnego marketingu ani tonu alarmowego. Każda wypowiedź uczy jednego działania lub interpretuje stan.
- **S1:** najpierw delikatne napięcie, wybór/unoszenie, opór, klik; osobne komunikaty dla przepchnięcia, ugięcia napinacza i sukcesu.
- **S2:** trzy kołki, opór tylko jednego w danym momencie (zgodnie z `ONBOARDING.md` §4).
- **S3:** nieoczywista kolejność i potrzeba lżejszej próby po przepchnięciu (zgodnie z §4).
- **Wskazówki:** klapka zwijki jako pauza, lupa jako przybliżenie, lewy kciuk utrzymuje napięcie. Bez instrukcji do marek lub rzeczywistych produktów.
- **DE:** zdania tworzone naturalnie, a nie słowo w słowo. Zachowane znaczenie sterowania i sygnałów gry.
- Jeden wykrzyknik na język i tylko przy `tutorial.s1.step4`; pozostałe linie bez wykrzyknika. Cudzysłowy polskie, gdyby miały wystąpić: „…”.

## Długości (liczba znaków Unicode)

Każda komórka zawiera najwyżej **56 znaków** (bez ręcznego łamania w CSV). W docelowym komponencie gry należy dopuścić **maksymalnie 2 linie** i łamać słowa automatycznie; skrypt nie wkłada znaków nowej linii, żeby nie zaburzać importu CSV.

| Klucz | EN | PL | DE |
|---|---:|---:|---:|
| `tutorial.s1.step1` | 35 | 44 | 38 |
| `tutorial.s1.step2` | 44 | 41 | 43 |
| `tutorial.s1.step3` | 34 | 30 | 38 |
| `tutorial.s1.step4` | 30 | 38 | 38 |
| `tutorial.s1.overset` | 43 | 40 | 43 |
| `tutorial.s1.near_break` | 46 | 38 | 51 |
| `tutorial.s1.done` | 37 | 37 | 32 |
| `tutorial.s2.intro` | 39 | 42 | 39 |
| `tutorial.s3.intro` | 36 | 40 | 41 |
| `tutorial.hint.no_tension` | 44 | 45 | 43 |
| `tutorial.hint.flap` | 37 | 39 | 37 |
| `tutorial.hint.loupe` | 34 | 27 | 39 |
| `tutorial.intro.frame1` | 32 | 36 | 37 |
| `tutorial.intro.frame2` | 44 | 39 | 41 |
| `tutorial.intro.frame3` | 31 | 39 | 39 |
| `tutorial.intro.note` | 45 | 42 | 48 |

## Alternatywy (nie są dodatkowymi kluczami CSV)

### `tutorial.s1.step1`
**Wariant 1:**

- EN: Left thumb up — just a touch. Hold it. (38)
- PL: Lewy kciuk w górę — odrobinę. Trzymaj. (38)
- DE: Links ein wenig hoch. Dann ruhig halten. (40)
**Wariant 2:**

- EN: A little tension with the left thumb. (37)
- PL: Lewym kciukiem dodaj odrobinę napięcia. (39)
- DE: Links sanft spannen. Nicht eilen. (33)

### `tutorial.s1.step4`
**Wariant 1:**

- EN: Click! That one is set. Keep looking. (37)
- PL: Klik! Ten już siedzi. Szukaj dalej. (35)
- DE: Klick! Der sitzt. Weiter zum nächsten. (38)
**Wariant 2:**

- EN: A clean click! Now find another pin. (36)
- PL: Wyraźny klik! Teraz poszukaj kolejnego. (39)
- DE: Ein klarer Klick! Such den nächsten. (36)

## Weryfikacja

- 16 z 16 wymaganych kluczy, dokładnie raz.
- Maksymalna długość: **51 znaków** (`tutorial.s1.near_break`, DE).
- W każdym języku maksymalnie jeden wykrzyknik w całym głównym pakiecie, wyłącznie w `step4`.
- CSV przechodzi odczyt zwrotny przez `csv.reader` z tymi samymi polami; pola zawierające przecinki są automatycznie ujmowane w cudzysłowy.
- Zapis tylko w `contrib/gpt/T39/`. Nie ingerowano w aktualny `game/i18n/strings.csv` ani w zadania sesji A/B.

## Źródła z repozytorium

`docs/ONBOARDING.md` §3–4, `docs/DESIGN.md` §1 i §3, `docs/HUD.md` §5–6, `game/i18n/strings.csv` oraz opis zadania G18. Stare klucze `tutorial.title`, `tutorial.stage`, `tutorial.start`, `tutorial.done` pozostają bez zmian; nowe nazwy są odrębne.
