# T58

Przygotowano propozycję tekstów CSV w pięciu językach. Klucze są propozycją do integracji. Teksty oparto na opisie fabuły T43; nazwy i opisy dzielnic są propozycją, nie ustalonym kanonem.

Kontrola: osobną kopię plików game/i18n uzupełniono o CSV tego zadania i uruchomiono tools/i18n_lint.py: 0 błędów i dwa ostrzeżenia bazowe dotyczące settings.voice_pack.line. Kopia nie zawierała plików GDScript, więc nie sprawdzono odwołań z kodu; linter nie weryfikuje fabuły ani działania gry.

Ponowna walidacja na kopii z kompletem 203 skryptów GDScript: 956 kluczy, 0 błędów, 2 ostrzeżeń. Uruchomiono `python tools/i18n_lint.py` po zastosowaniu propozycji tego zadania; wynik obejmuje sprawdzane przez linter odwołania z kodu, ale nie zastępuje testu w grze. Dwa ostrzeżenia są bazowe (`settings.voice_pack.line`).
