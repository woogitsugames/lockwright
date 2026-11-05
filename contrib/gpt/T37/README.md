# T37 — niemiecki (de-DE): druga korekta, uzupełnienie szkicu

Sprawdzono **wszystkie** klucze bieżących `game/i18n/strings.csv` i `game/i18n/content.csv` względem kolumn EN/PL i szkicu `contrib/gpt/T03/`. Słownik T02, styleguide T11; język gracza `du`, postaci zwracają się do ślusarza `Sie`, gdy jest to uzasadnione kontekstem.

| Plik | Sprawdzone | Uzupełnione brakujące | Poprawione istniejące | Ostrzeżenia >130% EN |
|---|---:|---:|---:|---:|
| strings | 125 | 20 | 8 | 17 |
| content | 629 | 273 | 53 | 102 |

## Najważniejsze zmiany

- Do szkicu z T03 dopisano **20 brakujących etykiet interfejsu** i **273 wpisy treści** (osiągnięcia, porady, notatki, obsada, zlecenia), z zachowaniem oryginalnych identyfikatorów. Szczegółowe tłumaczenia braków zachowano w `missing_*.json`.
- Skrócono **21 istniejących dialogów** przekraczających 90 znaków. Po korekcie liczba takich przekroczeń wynosi **zero**; żaden wpis do zeszytu nie przekracza 130 znaków.
- Naprawiono krytyczne skróty i zniekształcenia fabuły w opisach sytuacji: np. w wątku listów z Charleroi wcześniejszy tekst sugerował odmowę otwarcia, choć w EN/PL obie właścicielki chcą otworzyć kasetkę razem. Przywrócono szczegóły prawa dostępu, zgody, świadków i rodzinnych historii.
- Przełożono nienaturalne anglicyzmy w tekstach sklepów, doprecyzowano słownictwo narzędzi i poprawiono stwierdzenie o weryfikacji prawa wstępu, unikając przedstawiania go jako bezwzględnej normy ustawowej.
- Sprawdzono spójność placeholderów, unikalność kluczy, kompletność CSV i limity pól sklepowych. Kolumna `note` uzasadnia każdą zmianę i uzupełnienie.

## Ryzyka i granice kontroli

- Względne przekroczenia długości 130% EN pozostają tam, gdzie niemiecki naturalnie wymaga dłuższej frazy; zbyt agresywne skracanie usuwałoby sens. Weryfikacja layoutu na małym ekranie jest nadal wymagana.
- Uzupełnione 293 wpisy są redakcyjnymi tłumaczeniami roboczymi; przed wydaniem wymagają niezależnej recenzji native de-DE i sprawdzenia mechaniki w grze.
- Wariant A opisujący zakup w aplikacji nie jest zatwierdzony w D-06; opisów funkcji, offline i prywatności nie wolno publikować bez weryfikacji faktycznej wersji produktu.
