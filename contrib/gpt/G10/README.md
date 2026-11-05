# G10 — Zeszyt mistrza Henryka

## Status
Przygotowano 20 samodzielnych ilustracji SVG (wymiary 1600 × 2200, pion) oraz arkusz zbiorczy `contact-sheet.svg`. Wszystkie materiały znajdują się wyłącznie w `contrib/gpt/G10/`.

## Pliki
- `pages/01-cover.svg` — wytarta płócienna okładka z etykietą.
- `pages/02-endpaper.svg` — wyklejka z podpisem „H.”.
- `pages/03-five-rules-pl.svg` — pięć zasad w brzmieniu `docs/CLIENTS.md` (§6).
- `pages/04-five-rules-en.svg` — dokładne odpowiedniki angielskie z `game/i18n/content.csv`.
- `pages/05-diagram-01.svg` – `pages/14-diagram-10.svg` — dziesięć dwujęzycznych, wymyślonych przekrojów i znaków stanów: swobodny, binding, klin, stopka, talia, kontrrotacja, klamra, zrzut, stress i atlas.
- `pages/15-blank-lined.svg` – `pages/20-blank-graph.svg` — sześć kart do nakładania tekstów przez silnik gry (na przemian linie / kratka).
- `contact-sheet.svg` — arkusz przeglądowy 5 × 4.
- `ASSETS.md` — rejestr proweniencji wszystkich ilustracji.
- `README.md` — niniejszy raport.

## Zgodność
- Zasady PL/EN przepisano z repozytorium, nie z niewiarygodnego generowanego pisma.
- Znak set to pełna stopka i jedna podziałka; false set to talia i obrys przerywany; binding oznaczają trzy kreski; overset dwie kreski nad komorą. Kod stanów na podstawie `docs/DESIGN.md` §1.
- Materiał jest fikcyjnym szkicem encyklopedycznym, bez marek, instrukcji obchodzenia zabezpieczeń i podobieństwa do nazwanych produktów.
- Puste strony nie mają napisów ani pól interfejsu, zachowują margines.

## Ograniczenia i propozycje
- SVG to niezależne, rozdzielczościowo skalowalne **plansze proceduralne** o stylizowanym papierze. Nie są to fizyczne renderingi fotograficzne wykonane w Blenderze. Do docelowego *maksymalnego fotorealizmu* zalecana dodatkowa sesja look-dev z proceduralnym materiałem PBR w Blenderze lub wymiana podkładu na fotografię papieru i płótna.
- Przed importem do Godot 4.7 warto przetestować rasteryzację filtrów SVG, polskich znaków i czytelność w rozdzielczości telefonu; w razie potrzeby eksportować do PNG 1600 × 2200. Kroje: preferowany Comic Neue z licencją OFL albo fallback urządzenia, font nie jest dołączony.
- Początkowy arkusz koncepcyjny wygenerowany generatorem obrazów ChatGPT miał przekłamania w ręcznych napisach. Dlatego znaki i teksty naniesiono osobną metodą programową, nie przekopiowano ich z wygenerowanych grafik.
- Zlecenie nie określało osobnych dziesięciu kompletów rysunków w dwóch językach — każdy szkic ma jednocześnie PL i EN, tytuły zasad mają oddzielne warianty.
- Odrębny, gotowy do użycia pakiet renderów PNG i podgląd JPG może być przekazany poza repozytorium; niniejszy commit obejmuje pierwotne SVG i arkusz SVG.

## Uwagi do innych zespołów
- `docs/CLIENTS.md` zawiera aktualną narrację Henryka. PL/EN tytułów sklepów różnią się między zleceniem i `CLAUDE.md`; zasób G10 używa neutralnej etykiety „Zeszyt warsztatowy”.
- Szkice nie opisują faktycznej metody otwierania. Są pomocniczym kodem wizualnym, zgodnie z `docs/DESIGN.md`; nie wolno traktować ich jako instrukcji do realnych mechanizmów.
