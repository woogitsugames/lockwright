# Zlecenie T39: teksty kroków samouczka i podpowiedzi kredą (PL/EN/DE)

**Dla:** ChatGPT z dostępem do GitHuba (jedna sesja = jedno zlecenie). Repo `woogitsugames/lockwright`, gałąź `main`.
**Kontekst i zasady obowiązkowe:** jak w `docs/handoff/gpt/G01-enamel-apartment-number-plates.md` §1–§2: legalny ślusarz, fotorealizm, zero marek, lista zakazanych klisz, AI dozwolone (D-42) z wpisem w `ASSETS.md` (narzędzie, data, pełny prompt, edycje). Zapisuj **tylko** w swoim katalogu `contrib/gpt/T39/`. Raport `README.md` po polsku. Commit `contrib/gpt/T39: <opis>`; jeśli nie możesz pisać do `main`, oddaj ZIP właścicielowi.

## Po co
Samouczek ma prowadzić gracza kredowymi napisami na płycie zamka (N-61 i N-58 w `docs/handoff/SESSION-B-LOG.md`, storyboard `docs/ONBOARDING.md` §4). Agent sesji A pisze teraz wersje robocze. Twoje zadanie to dopracowane, krótkie, ciepłe teksty w głosie mistrza Henryka (zeszyt z G10), gotowe do podmiany.

## Zadanie
Przeczytaj `docs/ONBOARDING.md` (§3–§4), `docs/DESIGN.md` §1 (stany: binding, set, overset, false set, bliskie złamanie), `docs/HUD.md` §5–§6 oraz `game/i18n/strings.csv` (ton i istniejące klucze `tutorial.*`).

Napisz `contrib/gpt/T39/tutorial_lines.csv` z nagłówkiem `keys,en,pl,de` i kluczami:
- **kroki S1:**
  - `tutorial.s1.step1`: napięcie lewym kciukiem;
  - `tutorial.s1.step2`: prawy kciuk, w bok wybór pinu, w górę podnoszenie;
  - `tutorial.s1.step3`: pin stawia opór;
  - `tutorial.s1.step4`: klik, pin zatrzaśnięty, szukaj następnego;
  - `tutorial.s1.overset`: za wysoko, zwolnij napięcie;
  - `tutorial.s1.near_break`: za mocne napięcie, napinacz się ugina;
  - `tutorial.s1.done`: zamek otwarty, pochwała;
- **etapy:** `tutorial.s2.intro`, `tutorial.s3.intro` (co nowego w etapie 2 i 3, według ONBOARDING);
- **podpowiedzi:**
  - `tutorial.hint.no_tension`: gracz podnosi piny bez napięcia;
  - `tutorial.hint.flap`: klapka zwijki to pauza;
  - `tutorial.hint.loupe`: lupa pokazuje zbliżenie pinu;
- **wprowadzenie:**
  - `tutorial.intro.frame1`, `tutorial.intro.frame2`, `tutorial.intro.frame3`: podpisy pod kadrami z `docs/handoff/gpt4/G18-tutorial-chalk-frames.md`;
  - `tutorial.intro.note`: „To gra, nie kurs. Mechanizmy są wymyślone.”.

**Zasady:**
- każdy tekst max 2 linie po ok. 28 znaków na ekranie 412 dp, czyli **≤ 56 znaków** w każdym języku;
- jeden wykrzyknik najwyżej, w `step4`;
- bez słowa „włam” i bez instruktażu do realnych zamków;
- DE naturalne, nie dosłowne;
- polskie cudzysłowy „…”.

Dodaj `README.md` z uzasadnieniem i 2 alternatywami dla `step1` i `step4`.

## Kryteria odbioru
- CSV poprawny (UTF-8, pola z przecinkami w cudzysłowie);
- wszystkie klucze obecne;
- limity znaków spełnione (dołącz tabelę długości).
