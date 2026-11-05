# G12 — ikona aplikacji Lockwright

**Status:** komplet 12 propozycji wizualnych, 2026-11-05. Opracowanie koncepcyjne do wyboru przez właściciela; to nie jest jeszcze zatwierdzona identyfikacja sklepu.

## Wyniki

Przygotowano **12 niezależnych, oryginalnych kierunków ikon** zgodnych z wersją 2 zlecenia: bez scen ingerencji w mechanizm, bez postaci sprawcy, bez realnych marek i bez zakazanych estetyk. Styl: **półrealistyczna ilustracja materiałowa**, z proceduralnymi fakturami drewna, emalii, skóry i metalu; nie należy opisywać tych renderów jako fotografia.

Dla każdego wariantu znajdują się:

- `ios/NN_slug_1024.png` — gotowy, nieprzezroczysty PNG **1024 × 1024 px** (RGB).
- `previews/NN_slug_sizes.png` — pięć miniaturek o **rzeczywistych** wymiarach **180, 120, 60, 48 i 29 px** obok siebie, z podpisami PL.
- `android/NN_slug_foreground_432.png` — **432 × 432 px RGBA**, sam centralny przedmiot na przezroczystym tle, z marginesem strefy bezpiecznej maski adaptive.
- `android/NN_slug_background_432.png` — **432 × 432 px RGB**, pełne tło materiałowe; nie używać w nim przezroczystości.

`previews/contact_sheet.png` — zbiorcza plansza 4 × 3, opisy **PL + EN**, oraz miniatury 48 px. Oryginalne pliki (nie zrzuty planszy) są źródłem eksportów sklepowych.

| ID | Wariant (PL / EN) | Rozpoznawalny motyw | Ocena 48 px |
|---|---|---|---|
| 01 | Tabliczka „L” / Enamel L plate | Litera, emalia, cztery śruby | **bardzo czytelny** |
| 02 | Czoło wkładki / Brass cylinder face | Duża mosiężna tarcza | **bardzo czytelny** |
| 03 | Zwijka / Closed leather tool roll | Skórzana klapa i napa | **czytelny** |
| 04 | Stary klucz / Old key | Jeden duży klucz | czytelny, ogólny symbol |
| 05 | Dzwonek / Apartment doorbell | Jasny przycisk na zielonej lamperii | bardzo czytelny |
| 06 | Numer 12 / Number 12 plate | Emalia i duża cyfra | bardzo czytelny, słabsza marka |
| 07 | Wkładka ze skalą / Cylinder and dial | Pierścień podziałki | czytelny; drobne kreski znikają |
| 08 | Drzwi kamienicy / Tenement door | Drzwi dwuskrzydłowe, naświetle | czytelny |
| 09 | Klamka / Door handle and plate | Uchwyt, pionowy szyld | czytelny |
| 10 | Lampa warsztatowa / Workshop lamp | Duża lampa nad stołem | czytelny, nie mówi „ślusarz” |
| 11 | Pęk kluczy / Keys on a ring | Trzy klucze na kole | czytelny, zwyczajny motyw |
| 12 | Fasada / Tenement facade | Jasne okno z kamienną oprawą | słabszy w 29 px |

Oceny czytelności są oceną **wizualną**, bez testu użytkowników. Nie są wynikiem pomiaru A7 gry.

## Trzy rekomendacje

**1. Wariant 01 — emaliowane „L” (najlepszy znak marki).** Litera zachowuje zarys w 29–48 px; emalia i granat bezpośrednio przypominają stare oznaczenia mieszkań. Znak daje się powtarzać na materiałach sklepu, stronie i grafice promocyjnej. Ryzyko: bez podpisu nie komunikuje mechaniki zamków.

**2. Wariant 02 — czoło mosiężnej wkładki (najlepszy temat gry).** Jedna duża, symetryczna bryła i drobny centralny detal; wygląda jak starannie obrobiony przedmiot. W 48 px może jednak przypominać monetę, więc warto zbadać identyfikację w badaniu A/B.

**3. Wariant 03 — zamknięta zwijka skórzana (najlepszy klimat).** Oddaje fach, przygotowanie do legalnego zlecenia i warsztatowość bez pokazywania czynności przy drzwiach. Mniej jednoznaczny jako ikona gry o zamkach, ale dobrze odróżnia się od typowych ikon gier logicznych.

**Rekomendacja do pierwszego testu sklepowego:** 01 vs 02, z 03 jako odrębnym kierunkiem. Nie wprowadzać jednej z ikon jako finalnej bez akceptacji właściciela.

## Weryfikacja i odtwarzanie

```bash
python3 -m pip install Pillow numpy
python3 contrib/gpt/G12/generate_icons.py
python3 contrib/gpt/G12/validate.py
```

Kod (`generate_icons.py`) jest jedynym źródłem proceduralnym. Nie pobiera zdjęć ani innych zasobów z internetu. Używa czcionek Noto Serif i Noto Sans (OFL) z systemu, bez kopiowania fontów do repo; w środowiskach bez Noto używa fontu zastępczego, co może minimalnie zmienić literę i podpisy.

**Wykonane QA:** 12 PNG iOS ma RGB 1024×1024; 12 zestawień zawiera pięć wymaganych rozmiarów; 24 warstwy Android mają 432×432 i przezroczystość foreground. Alfa foreground zachowuje margines maski adaptive. Wszystkie pliki mają mniej niż 20 MB. Wersje materiałowe w skali 48 px sprawdzone na planszy.

**Czego nie udało się zrobić w tym etapie:** nie wykonano realnego testu rozpoznawalności z graczami ani renderów Cycles o jakości fotograficznej. Przed publikacją warto wyrenderować zatwierdzony projekt w silniku docelowym i powtórzyć test na fizycznych ekranach w różnych trybach wyglądu.

## Zmiany poza G12

Brak. W tym pakiecie nie modyfikowano `CLAUDE.md`, `docs/ASSETS.md`, interfejsu gry ani listingu sklepowego.
