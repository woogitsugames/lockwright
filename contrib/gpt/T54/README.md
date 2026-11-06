# T54 — opisy pozycji rachunku

Propozycje dla rodzin z T43 oraz wcześniejszych rodzin i wariantów, naprawy zegara i odmowy; pięć języków, maksymalnie 32 znaki. Rodzina time_lock oznacza naprawę, nie otwarcie. Przy odmowie tekst opisuje brak usługi, nie pozycję płatną. Nazwy kluczy są propozycją. Obejmuje również warianty rodzin wymienione w tools.json.

Kontrola: osobną kopię plików game/i18n uzupełniono o CSV tego zadania i uruchomiono tools/i18n_lint.py: 0 błędów. Dwa ostrzeżenia bazowe dotyczą identycznej treści pola settings.voice_pack.line. Kopia nie zawierała plików GDScript, więc nie sprawdzono odwołań z kodu; linter nie weryfikuje fabuły ani działania gry.

Ponowna walidacja na kopii z kompletem 203 skryptów GDScript: 969 kluczy, 0 błędów, 2 ostrzeżeń. Uruchomiono `python tools/i18n_lint.py` po zastosowaniu propozycji tego zadania; wynik obejmuje sprawdzane przez linter odwołania z kodu, ale nie zastępuje testu w grze. Dwa ostrzeżenia są bazowe (`settings.voice_pack.line`).
