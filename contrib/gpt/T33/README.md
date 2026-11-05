# T33 — włoski: druga korekta

Źródło: `contrib/gpt/T14/`. Przejrzano wszystkie klucze względem EN i PL `game/i18n/*.csv`; przyjęto it-IT i odpowiednie formy grzecznościowe dla rozmówców. Słownik T02 i styl T11.

| Plik | Klucze | Zmienione | Dłuższe >130% EN | Dialogi >90 |
|---|---:|---:|---:|---:|
| strings | 125 | 9 | 23 | 0 |
| content | 629 | 18 | 96 | 0 |

Sprawdzono kompletność, unikalność i placeholdery. Kolumna `note` dokumentuje zmiany. Priorytetem było usunięcie 13 przekroczeń limitu długości dialogów, spójność nazw i unikanie absolutnych interpretacji procedur dostępu. Pozostałe odchylenia długości >130% EN są ostrzeżeniami UI: ich automatyczne skracanie mogłoby zubożyć naturalny włoski.

**Ryzyka:** brak testu na urządzeniu i niezależnej recenzji it-IT; prawdziwa polityka prywatności, dostępność offline i funkcje gry wymagają kontroli; wariant A pozostaje niepublikowalny przed D-06.
