# Zlecenie G17: puste emaliowane tabliczki na przyciski menu i inicjały

**Dla:** ChatGPT z dostępem do GitHuba (jedna sesja = jedno zlecenie). Repo `woogitsugames/lockwright`, gałąź `main`.
**Kontekst i zasady obowiązkowe:** jak w `docs/handoff/gpt/G01-enamel-apartment-number-plates.md` §1–§2: legalny ślusarz, fotorealizm, zero marek, lista zakazanych klisz, AI dozwolone (D-42) z wpisem w `ASSETS.md` (narzędzie, data, pełny prompt, edycje). Zapisuj **tylko** w swoim katalogu `contrib/gpt/G17/`. Raport `README.md` po polsku. Commit `contrib/gpt/G17: <opis>`; jeśli nie możesz pisać do `main`, oddaj ZIP właścicielowi.

## Po co
Menu główne ma wyglądać jak warsztat ślusarza, z przyciskami w postaci emaliowanych tabliczek (D-43, N-54). W rozmowach postać bez portretu dostaje tabliczkę z inicjałem (N-60). Obecne tabliczki z G01 mają wydrukowane cyfry, więc gra nakłada literę na cyfrę. Potrzebne są **puste** tabliczki, na które gra sama nałoży tekst.

## Zadanie
Styl, emalia i światło jak w `contrib/gpt/G01/` (otwórz contact sheet): emalia na stali, lekko wypukła, obtłuczenia na brzegach, odrobina rdzy w odpryskach, dwa otwory na wkręty, frontalnie, miękkie światło z góry z lewej. **Bez żadnych cyfr, liter ani znaków.** Środek tabliczki ma mieć gładkie, równe pole emalii, żeby tekst był czytelny.

1. **Tabliczki przycisków, poziome:**
   - proporcje 4:1, 1600×400, w 4 kolorach: granat, butelkowa zieleń, kość słoniowa (z ciemną obwódką), bordo;
   - dla każdego koloru 2 warianty: `normal` i `pressed`, czyli tabliczka lekko przesunięta w dół z mniejszym cieniem (to samo ujęcie, ten sam kadr);
   - razem 8 plików.
2. **Duża tabliczka „główna”:** 3:1, 1500×500, granat, z grubszą obwódką, dla przycisku „Zacznij dyżur”. `normal` i `pressed`, czyli 2 pliki.
3. **Małe kwadratowe tabliczki na inicjał:** 512×512, w 4 kolorach jak wyżej, puste. Razem 4 pliki.
4. **Marginesy do 9-slice:** dla każdego pliku z pkt 1–2 podaj w `manifest.json` marginesy w px (`left`, `top`, `right`, `bottom`). Środek musi się dać rozciągać w poziomie bez widocznego zniekształcenia, więc obtłuczenia i otwory na wkręty mają leżeć w marginesach.
5. Contact sheet wszystkich plików.

**Format:** PNG z kanałem alfa (przezroczyste tło), 8-bit sRGB. Cień tylko w alfie, miękki, max 12 px. Jeśli alfa się nie uda, użyj neutralnego tła 18% szarości i napisz to w raporcie.

## Kryteria odbioru
- 14 PNG + `manifest.json` + `ASSETS.md` + `README.md` + contact sheet;
- zero tekstu i znaków na tabliczkach;
- `pressed` ma identyczny kadr i rozmiar jak `normal`.
