# T47

Przejrzano wszystkie 310 rekordów UI. CSV zawiera proponowane poprawki, tabela changes.md opisuje zmiany. Niezmieniane kolumny są puste. Wynik walidacji na kopii z poprawkami: lint.txt.

Dalsza propozycja i tabela zmiany: `KOREKTA2.csv` i `KOREKTA2.md`. Lint dotyczy kopii sparse bez skryptów `.gd`, dlatego nie zastępuje pełnej kontroli odwołań z kodu.

Ponowna walidacja na kopii z kompletem 203 skryptów GDScript: 948 kluczy, 0 błędów, 2 ostrzeżeń. Uruchomiono `python tools/i18n_lint.py` po zastosowaniu propozycji tego zadania; wynik obejmuje sprawdzane przez linter odwołania z kodu, ale nie zastępuje testu w grze. Dwa ostrzeżenia są bazowe (`settings.voice_pack.line`).
