# Zlecenie G19: dwa szkice do ekranu wyboru sterowania

**Dla:** ChatGPT z dostępem do GitHuba (jedna sesja = jedno zlecenie). Repo `woogitsugames/lockwright`, gałąź `main`.
**Kontekst i zasady obowiązkowe:** jak w `docs/handoff/gpt/G01-enamel-apartment-number-plates.md` §1–§2: legalny ślusarz, fotorealizm, zero marek, lista zakazanych klisz, AI dozwolone (D-42) z wpisem w `ASSETS.md` (narzędzie, data, pełny prompt, edycje). Zapisuj **tylko** w swoim katalogu `contrib/gpt/G19/`. Raport `README.md` po polsku. Commit `contrib/gpt/G19: <opis>`; jeśli nie możesz pisać do `main`, oddaj ZIP właścicielowi.

## Po co
Przy pierwszym uruchomieniu gracz wybiera sterowanie (decyzja właściciela D-52 w `docs/DECISIONS.md`):
- **„Napięcie automatyczne — dla zaczynających”**: gra trzyma napięcie, a gracz prowadzi wytrych jednym kciukiem;
- **„Dwa kciuki — pełne wyczucie”**: lewy kciuk daje napięcie, prawy podnosi piny.

Każda opcja to duża emaliowana tabliczka z małym szkicem obok. Styl szkicu jak w zeszycie mistrza Henryka z G10 (`contrib/gpt/G10/v2/contact-sheet.jpg`): ołówek i kreda, oszczędnie.

## Zadanie
Dwa szkice, każdy 768×768, **bez tekstu**, wymyślony uproszczony telefon trzymany pionowo (bez marki, bez realnego modelu), na ekranie zarys przekroju zamka:
1. `controls_auto.png`: jedna dłoń, prawy kciuk na prawej połowie ekranu ze strzałką w górę. Przy napinaczu mała kredowa „kłódka czasu” albo kotwica oznaczająca, że napięcie trzyma się samo (wymyśl prosty, czytelny znak, nie emoji).
2. `controls_two_thumbs.png`: dwie dłonie, lewy kciuk po lewej ze strzałką w górę (napięcie), prawy po prawej ze strzałką w górę i podwójną w bok.

Oba w dwóch wariantach: na kremowym papierze i z alfą (`*_alpha.png`). Ten sam kadr i skala. Dołącz contact sheet.

## Kryteria odbioru
- 4 PNG + contact sheet + `ASSETS.md` + `README.md`;
- zero tekstu w obrazach;
- czytelne przy 96×96 dp. Dołącz podgląd obu szkiców pomniejszonych do 192×192 px.
