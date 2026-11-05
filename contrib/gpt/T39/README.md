# T39 — samouczek Lockwright, teksty PL/EN/DE

**Data:** 2026-11-05  
**Plik do importu:** `tutorial_lines.csv` (UTF-8, nagłówek `keys,en,pl,de`).

## Zasady redakcyjne

- Teksty są krótkie, spokojne, w głosie mistrza Henryka: jeden sygnał lub jedno działanie na komunikat.
- S1 opisuje sterowanie lewym/prawym kciukiem, opór, prawidłowy klik, przepchnięcie, ugięcie napinacza i otwarcie.
- S2: trzy kołki, tylko jeden wiąże naraz. S3: zmienna kolejność i ponowna łagodniejsza próba po przepchnięciu.
- Podpowiedzi dotyczą pauzy pod klapką zwijki, lupy i braku napięcia; introdukcje odpowiadają trzem kadrom z G18.
- Brak nazw producentów i instrukcji do rzeczywistych wyrobów; niemiecki jest idiomatyczny, nie mechanicznie dosłowny.
- W każdej wersji językowej jeden wykrzyknik, wyłącznie w `tutorial.s1.step4`; polskie cudzysłowy, jeśli używane, to „…”.

## Długości Unicode

Każde pole ma do 56 znaków; grafika 412 dp powinna automatycznie zawijać do maksymalnie dwóch linijek. Bez osadzonych nowych linii dla zgodności z importerem CSV.

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

## Walidacja

- 16 unikalnych wymaganych kluczy; odrębne od istniejących `tutorial.title`, `tutorial.stage`, `tutorial.start`, `tutorial.done`.
- Maksimum 51 znaków (`tutorial.s1.near_break`, DE).
- CSV zgodny z RFC 4180: wartości z przecinkami ujęte w cudzysłowy.
- Materiały źródłowe: `docs/ONBOARDING.md` §3–4, `docs/DESIGN.md` §1, `docs/HUD.md` §5–6, `game/i18n/strings.csv`, brief G18.
- Zmiany ograniczone do `contrib/gpt/T39/`.

## Regeneracja

`python3 contrib/gpt/T39/build.py`
