# T53 — wpisy do zeszytu

Po dwa wpisy dla każdej z ośmiu rodzin, w pięciu językach. Limit 130 znaków sprawdzono skryptem Python. Teksty inspirowane głosem zeszytu w docs/CLIENTS.md; nazwy kluczy są propozycją.

Kontrola: osobną kopię plików game/i18n uzupełniono o CSV tego zadania i uruchomiono tools/i18n_lint.py: 0 błędów. Dwa ostrzeżenia bazowe dotyczą identycznej treści pola settings.voice_pack.line. Kopia nie zawierała plików GDScript, więc nie sprawdzono odwołań z kodu; linter nie weryfikuje fabuły ani działania gry.

Ponowna walidacja na kopii z kompletem 203 skryptów GDScript: 964 kluczy, 0 błędów, 2 ostrzeżeń. Uruchomiono `python tools/i18n_lint.py` po zastosowaniu propozycji tego zadania; wynik obejmuje sprawdzane przez linter odwołania z kodu, ale nie zastępuje testu w grze. Dwa ostrzeżenia są bazowe (`settings.voice_pack.line`).
