# T78 — dodatkowe notatki gabloty

`notes.csv`: osiem propozycji, po jednej dla każdej rodziny D-59, tytuł i tekst w pięciu językach. To **nowe propozycje uzupełniające**, bez przypisanych kluczy `showcase.*`; integrator powinien nadać osobne ID i warunki odblokowania. Źródłem faktów są katalogi i dokumenty patentowe poniżej. Sam patent dokumentuje opis lub publikację, nie dowodzi, że pomysł był pierwszy, wdrożony czy powszechny. Nie zawarto instrukcji użycia ani nazw marek w tekstach gry.

## Istniejące wpisy — unikanie powtórzeń

Rodziny mają już wpisy: `showcase.yale_dial`, `showcase.combo`, `showcase.dimple`, `showcase.henriksson_disc`, `showcase.egyptian_name` i `showcase.khorsabad_gate`, `showcase.bramah_window`, `showcase.sargent_time_lock`, `showcase.magnetic` w `game/data/showcase/` i `game/i18n/content.csv`. Nowe notatki proponują inne źródło lub kontekst, a nie zamianę tych tekstów. `combo` nadal dotyczy podobnych muzealnych zamków z literami, ale uzupe?nia kontekst tego samego znaleziska; `axial_slider` wraca do tego samego historycznego warsztatu z perspektywy zachowanej tablicy ekspozycyjnej. Przed integracją redakcja powinna zdecydować, czy ten stopień pokrewieństwa uzasadnia dodatkowe wpisy.

## Źródła i zastrzeżenia

- `dial_safe`: [patent amerykański z 1892 roku](https://patents.google.com/patent/US473686A/en) — przykład projektu, nie deklaracja pierwszeństwa.
- `combo`: [Museum Wales: znalezisko Morfa Beach](https://museum.wales/collections/online/object/f33a582e-7d7d-35f0-8011-f0cac35e8aba/Post-Medieval-copper-alloy-combination-lock/) — związek miejsca z wrakiem nie dowodzi przynależności samego zamka do konkretnego pasażera lub statku.
- `dimple`: [publikacja japońska z 2004 roku](https://patents.google.com/patent/JP2004003141A/en) — pojedynczy dokument, nie źródło historii początków typu.
- `disc_detainer`: [amerykański dokument patentowy z 1924 roku](https://patents.google.com/patent/US1514318A/en) — data zgłoszenia 1919 i publikacji 1924, nie data wcześniejszego patentu fińskiego.
- `egyptian`: [Science Museum Group: drewniany zamek z Wysp Owczych](https://collection.sciencemuseumgroup.org.uk/objects/co50290/wooden-door-lock-with-wooden-tumblers-from-the-faroe-islands-early-18th-century) — tytuł katalogu mówi o początku XVIII wieku, pole „Made” o latach 1801–1830. Rok 1821 dotyczy przywiezienia, nie jest pewną datą wykonania.
- `axial_slider`: [Science Museum Group: obiekty w ekspozycji](https://collection.sciencemuseumgroup.org.uk/objects/co50475/bramah-lock-display-board-from-piccadilly-office) — katalog opisuje tablic? z Piccadilly; atrybucja związku z rodziną na podstawie `docs/SHOWCASE.md` i `showcase.bramah_window`.
- `time_lock`: [reedycja patentu zamka czasowego](https://patents.google.com/patent/USRE8035E/en) — opis odstępu dłuższego niż doba; oryginalny patent z 1874, reedycja z 1878.
- `magnetic`: [patent amerykański opublikowany w 1970 roku](https://patents.google.com/patent/US3495425A/en) — opis pojedynczej konstrukcji.

Stan repozytorium: `b50ea45`. Języki obce i dopasowanie tekstów do gabloty wymagają korekty redakcyjnej; historii nie uogólniano z jednego patentu na całą rodzinę.

## Kontrola końcowa źródeł i wersji

Ponownie otwarto wszystkie osiem linków i porównano treść w pięciu językach z przypisanym faktem: daty publikacji, miejsce znaleziska, rodzaj dokumentu i zastrzeżenie braku pierwszeństwa są zgodne między wersjami. Wpis o tablicy opisuje ją jako ekspozycyjną, bez niepotwierdzonego twierdzenia, że była reklamą. Drewniany obiekt z Wysp Owczych to historyczny kontekst rodziny zasuw drewnianych; karta muzealna nie nazywa go wprost modelem egipskim, dlatego nie należy przedstawiać go jako dowodu egipskiego pochodzenia. Muzeum łączy miejsce znaleziska z wrakiem, nie przypisuje z całą pewnością przedmiotu konkretnemu właścicielowi. Weryfikacja nie zastępuje korekty przez native speakerów.
