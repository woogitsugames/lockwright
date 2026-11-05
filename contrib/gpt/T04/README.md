# T04 — Sprawdzenie faktów: notki gabloty

**Wykonano:** 2026-11-05. Repozytorium: woogitsugames/lockwright. Zakres zapisu: wyłącznie contrib/gpt/T04/.

## Wykonanie

- Zweryfikowano 20 z 20 notek historycznych w docs/SHOWCASE.md. Oceny: 3 zgodne, 17 do poprawy, 0 nie do zweryfikowania.
- Zweryfikowano 17 z 17 wstępów historycznych i zasad encyklopedycznych rodzin w docs/LOCKS.md. Oceny: 2 zgodne, 11 do poprawy, 4 nie do zweryfikowania.
- Każdy rekord ma dwa odnośniki do źródeł muzealnych, naukowych, współczesnych autorom drukowanych opracowań albo archiwum patentowego. Brak odwołań do współczesnych producentów jako źródeł faktów.
- Przygotowano teksty PL+EN dla wszystkich 20 notek i bezpieczne propozycje PL+EN dla wszystkich 17 wstępów rodzin.
- Zbadano CLAUDE.md, docs/styles/realizm.md, docs/DESIGN.md, docs/HUD.md, docs/SHOWCASE.md i docs/LOCKS.md. Nie modyfikowano nic poza tym katalogiem.

## Pliki

- **FACTCHECK.md** — tabela 20 + 17 ocen, konkretne poprawki, po dwa źródła do każdego rekordu, bibliografia i niepewności.
- **showcase_notes_fixed.md** — komplet poprawionych notek gabloty PL/EN, zachowane identyfikatory i18n, oraz 17 propozycji poprawionych wstępów rodzin PL/EN.
- **README.md** — niniejszy raport przekazania.
- **ASSETS.md** — rejestr zasobów: nie tworzono żadnych grafik, dźwięków, modeli, czcionek ani innych plików multimedialnych.

## Co się nie udało / co pozostaje

- Nie rozstrzygnięto jednoznacznych dat pierwszeństwa dla tubular, magnetic, dimple i sidebar. W notkach nie użyto niepewnych dat.
- Nie porównano dosłownie cytatów literackich o zamku AMEN z krytycznymi wydaniami sztuk i poezji. Zachowano jedynie ostrożne omówienie oraz wyraźne zastrzeżenie.
- W sprawie instytucjonalnej historii Muzeum Ślusarstwa w Świątnikach regionalne materiały nie pozwalają bezspornie wskazać jednej daty. Uniknięto arbitralnej daty w tekście gracza.
- Nie rozstrzygnięto pierwszeństwa starożytnego zamka szyfrowego z Keramejkosu ani szczegółowych dat Cardana; zachowano udokumentowaną tradycję średniowieczną.
- Nie przeniesiono korekt bezpośrednio do docs/SHOWCASE.md i docs/LOCKS.md, ponieważ wyraźny zakres uprawnień T04 zakazuje zapisu poza contrib/gpt/T04/.

## Propozycje wdrożenia

1. Zespół treści: przenieść 20 tekstów PL/EN do i18n pod istniejące identyfikatory; zweryfikować końcową długość w diegetycznym UI.
2. Zespół dokumentacji: osobno zastosować poprawki do sekcji epoki/mechanizmu rodzin, ze szczególnym uwzględnieniem Feltera 1868, Bramaha 1801 i nazewnictwa warded.
3. W razie przygotowania grafik i nagrań prowadzić rejestr pochodzenia i licencji zasobów; w tym zleceniu zasobów nie wytwarzano.

## Uwagi dla innych zespołów (bez ingerencji w cudze pliki)

- **docs/SHOWCASE.md:** liczne gotowe notki cytują źródła zbiorczo, lecz nie wszystkie ich poboczne twierdzenia są z tych źródeł dowodliwe; zalecane zastąpienie wskazanymi tekstami i utrzymanie źródeł przy każdym rekordzie.
- **docs/LOCKS.md:** definicja „warded” jest błędnie zrównana z ruchomymi zapadkami; standardowe nazwy polskie należy uzgodnić. W rodzinach wafer i wafer_double historia jednostronności/dwustronności jest odwrócona.
- **CLAUDE.md / metadane projektu:** istnieją różnice w opisach aktualnego etapu i angielskiego podtytułu w materiałach zadania i repo; nie dotyczy to zakresu T04 i nie korygowano tego.

**Test przekazania:** 20/20 notek; 17/17 rodzin; 2/2 niezależne punkty odniesienia na rekord; każda propozycja w PL i EN; brak zasobów binarnych; brak zmian poza katalogiem T04.
