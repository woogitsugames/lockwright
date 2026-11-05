# G17 — puste emaliowane tabliczki (Lockwright)

**Data:** 2026-11-05  
**Zakres:** `contrib/gpt/G17/` — gotowe zasoby UI, niezależne od języka, bez wbudowanych znaków i napisów.

## Oddane

- **8** przycisków poziomych 1600 × 400: granat (`navy`), zieleń butelkowa (`bottle_green`), kość słoniowa (`ivory`) i bordo (`burgundy`), każdy w stanach `normal` / `pressed`.
- **2** duże przyciski granatowe 1500 × 500: `primary_navy_normal.png` i `primary_navy_pressed.png`.
- **4** puste tabliczki 512 × 512 na inicjały: `initial_<kolor>.png`.
- `manifest.json` — wymiary, kolory, stany oraz marginesy 9-slice (osobny wpis dla każdego z 10 przycisków).
- `contact_sheet.jpg` — przegląd 14 grafik.
- `source/` — 2 oryginalne, wygenerowane obrazy wejściowe, pozwalające odtworzyć obróbkę.
- `generate.py` — powtarzalne przetwarzanie w Pillow i NumPy; `ASSETS.md` — pełne prompty, narzędzia, daty i edycje.

## Parametry techniczne

Wszystkie **14 eksportów PNG** mają kanał alfa, 8 bitów na kanał oraz dołączony profil ICC sRGB. Kontur tabliczki jest izolowany od tła, a dodatkowy miękki cień powstaje w alfie z promieniem rozmycia 4 px (`normal`) lub 2,5 px (`pressed`). Wariant wciśnięty zachowuje rozmiar i kadr, przesuwa tabliczkę o 5 px w dół, subtelnie zmniejsza jasność i słabiej rzuca cień.

Przyciski mają **marginesy 9-slice** dobrane tak, by otwory montażowe i obtłuczenia znajdowały się po bokach, poza elastycznym środkiem. Wnętrze środka powstało przez rozciągnięcie wąskiej, czystej próbki emalii, dlatego drobne rysy są wydłużone poziomo. Marginesy w manifeście liczone są od krawędzi pełnego pliku, wraz z alfą i cieniem. **Nie rozciągać** gotowej bitmapy zwykłym `scale` — w UI użyć `NinePatchRect` i pól `patch_margin_*` z manifestu; tekst nakładać dopiero w silniku.

W kolorze kości słoniowej wewnętrzna obwódka jest ciemna. Przyciski zachowują 2 otwory na śruby; na tabliczkach kwadratowych są one pośrodku lewej i prawej krawędzi.

## Odtwarzanie

```bash
python3 -m pip install pillow numpy
python3 contrib/gpt/G17/generate.py
```

Nie modyfikowano plików gry ani innych zadań. Obrazy użyte do generacji zostały wykonane od zera w ChatGPT ImageGen, nie pochodzą od producentów zamków ani z cudzych gier.

## Ograniczenia i uwagi integracyjne

- Zgodność z wyglądem wcześniejszego G01 oparto na opisie materiałów i kolorystyki. Nie wykonano pikselowego porównania z `G01/contact_sheet.png`, ponieważ konektor repozytorium nie udostępnił binarnych referencji do lokalnego porównania.
- Fotorealistyczne obtłuczenia oraz linie obwódek są w oryginalnych marginesach; centralny, pozbawiony detali odcinek uzyskano komputerowo. Przy bardzo długim napisie może być potrzebny szerszy przycisk 9-slice, nie skalowanie całego obrazu.
- W G17 nie zapisano kodu integracji z Godotem — zgodnie z granicami katalogu tego zlecenia.
