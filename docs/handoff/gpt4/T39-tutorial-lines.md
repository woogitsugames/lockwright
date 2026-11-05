# Zlecenie T39: teksty kroków samouczka i podpowiedzi kredą (PL/EN/DE)

**Dla:** ChatGPT z dostępem do GitHuba (jedna sesja = jedno zlecenie). Repo `woogitsugames/lockwright`, gałąź `main`.
**Kontekst i zasady obowiązkowe:** jak w `docs/handoff/gpt/G01-enamel-apartment-number-plates.md` §1–§2: legalny ślusarz, fotorealizm, zero marek, lista zakazanych klisz, AI dozwolone (D-42) z wpisem w `ASSETS.md` (narzędzie, data, pełny prompt, edycje). Zapisuj **tylko** w swoim katalogu `contrib/gpt/T39/`. Raport `README.md` po polsku. Commit `contrib/gpt/T39: <opis>`; jeśli nie możesz pisać do `main`, oddaj ZIP właścicielowi.

## Po co
Samouczek ma prowadzić gracza kredowymi napisami na płycie zamka (N-61, N-58 w , storyboard  §4). Agent sesji A pisze teraz wersje robocze. Twoje zadanie to dopracowane, krótkie i ciepłe teksty w głosie mistrza Henryka (zeszyt z G10), gotowe do podmiany.

## Zadanie
Przeczytaj  (§3–§4),  §1 (stany: binding, set, overset, false set, bliskie złamanie),  §5–§6 oraz obecne  (ton i istniejące klucze ).

Napisz plik  z nagłówkiem  i kluczami:
-  napięcie lewym kciukiem;  prawy kciuk: w bok wybór pinu, w górę podnoszenie;  pin stawia opór;  klik, pin zatrzaśnięty, szukaj następnego;  za wysoko, zwolnij napięcie;  za mocne napięcie, napinacz się ugina;  zamek otwarty, pochwała; ,  (co nowego w etapie 2 i 3, według ONBOARDING);
-  podpowiedź, gdy gracz podnosi piny bez napięcia;  „klapka zwijki = pauza”;  lupa pokazuje zbliżenie pinu;
-  podpisy pod trzema kadrami wprowadzenia (patrz );  „To gra, nie kurs. Mechanizmy są wymyślone.”.

**Zasady:**
- każdy tekst max 2 linie po ok. 28 znaków na ekranie 412 dp, czyli **≤ 56 znaków** we wszystkich językach;
- bez wykrzykników poza jednym w ;
- bez słowa „włam” i bez instruktażu do realnych zamków;
- DE naturalne, nie dosłowne;
- polskie cudzysłowy „…”.

Dodaj  z uzasadnieniem wyborów i 2 alternatywami dla  i .

## Kryteria odbioru
- CSV parsuje się poprawnie (UTF-8, przecinki w polach w cudzysłowie);
- wszystkie klucze obecne;
- limity znaków spełnione (dołącz tabelę długości).
