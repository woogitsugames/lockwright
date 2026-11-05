# T31 — francuski: druga korekta

Źródło: `contrib/gpt/T12/`, porównanie wszystkich kluczy EN/PL `game/i18n/*.csv`; słownik `contrib/gpt/T02/GLOSSARY.md` oraz `contrib/gpt/T11/STYLEGUIDE_PL.md`.

| Plik | Sprawdzone klucze | Poprawione | Dłuższe >130% EN | Dialogi >90 |
|---|---:|---:|---:|---:|
| strings | 125 | 11 | 17 | 0 |
| content | 629 | 8 | 114 | 0 |

Każdy klucz przeszedł kontrolę kompletności i placeholderów. Kolumna `note` dokumentuje wprowadzone zmiany. Przy krótkich angielskich nazwach tekst francuski bywa naturalnie dłuższy, dlatego pozostałe ostrzeżenia >130% nie były obcinane automatycznie.

Korekty: skrócone trzy dialogi, komunikaty i nazwy; zachowano formalny rejestr wobec klienta. W opisie sklepowym usunięto absolutne `toujours`, żeby nie przedstawiać zwyczaju weryfikacji uprawnień jako uniwersalnej normy prawnej.

**Ryzyka:** pozostałe długie etykiety wymagają sprawdzenia na urządzeniu; brak zewnętrznej recenzji native fr-FR/fr-BE; publikacja wariantu A wymaga decyzji D-06; zgodność deklaracji o prywatności, offline i funkcjach musi być potwierdzona przed wydaniem.
