# T11 — raport z korekty polskich tekstów

## Wynik

Przygotowano korektę **754 kluczy PL**: 629 w `content.csv`, 125 w `strings.csv`. Każdy wiersz ma `pl_old`, `pl_new` i uzasadnienie (lub „Bez zmian.”). Zmieniono 265 wpisów `content` oraz 43 wpisów `strings`, wliczając typografię. Oryginalne pliki i18n i `store/listing.md` pozostają bez zmian.

## Pliki

- `content_pl_reviewed.csv` — 629 rekordów i 265 propozycji zmian;
- `strings_pl_reviewed.csv` — 125 rekordów i 43 propozycji zmian;
- `STYLEGUIDE_PL.md` — zasady redakcji i słownik dla autorów;
- `store_pl_reviewed.md` — gotowe pola PL App Store/Google Play i korekta pełnego opisu Google Play;
- `README.md` — raport.

## Walidacja

- Brak duplikatów i pustych komórek PL; poprawne 4 kolumny i poprawny ponowny odczyt CSV.
- Wszystkie placeholdery zachowane bez zmian; kolejność i liczba kluczy bez zmian.
- Maksymalna długość dialogu i `.after.N`: **80/90**, wpisu zeszytu: **100/130**.
- Spacje nierozdzielające w 265 wierszach; usunięto miękki dywiz w 1 wierszu.
- Polskie pola sklepowe sprawdzono pod kątem limitów, w tym 100 bajtów słów kluczowych; `gp.pl.description` ma 1866/4000 znaków.

## Zmiany redakcyjne

Przetłumaczono „Bailiff”, wyeliminowano błędne `{n} monet`, ujednolicono nazwy trybów, sprzętu, stanów mechanizmów i interpunkcję. Poprawiono m.in. opis Marty („graficzka”), odwołanie do technicznego klucza `job.grandpa_chest`, błąd składni w kapsule czasu oraz niespójność marynarki/krawata Kuby. Uwagi o historii ograniczono do korekty językowej, bez ingerowania w fakty.

## Ograniczenia i uwagi do innych plików

- To pliki **proponowanych** zmian. Wprowadzenie `pl_new` do źródłowej kolumny `pl` i synchronizacja `docs/CLIENTS.md` oraz stron zeszytu wymagają osobnego działania, bo T11 może zapisywać tylko do `contrib/gpt/T11/`.
- `run.lives_left` zaproponowano jako „Pozostałe wytrychy” na podstawie D-12; wymaga sprawdzenia, czy faktycznie wyświetla liczbę narzędzi.
- Nie przeprowadzono wizualnego testu szerokości napisów na urządzeniach, ani niezależnego fact-checkingu notek historycznych.
- W sklepie usunięto zdanie „W grze też.” obiecujące dostępność weryfikacji klientów, podczas gdy `docs/JOBS.md` umieszcza Tryb Zleceń po MVP. Do potwierdzenia przed publikacją: funkcje 1.0, prywatność i model biznesowy. D-06/D-51: **bez deklarowania ceny, daty i dostępności**.
