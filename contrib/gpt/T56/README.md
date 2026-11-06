# T56 — propozycje osiągnięć

Osiem propozycji dla ośmiu rodzin, po jednym osiągnięciu. Teksty w pięciu językach. Warunki w proposals.json są schematyczne, niewykonane i wymagają sprawdzenia nazw zdarzeń oraz możliwości runtime przed integracją. Punkty są propozycją do oceny balansu.

Kontrola: osobną kopię plików game/i18n uzupełniono o CSV tego zadania i uruchomiono tools/i18n_lint.py: 0 błędów. Dwa ostrzeżenia bazowe dotyczą identycznej treści pola settings.voice_pack.line. Kopia nie zawierała plików GDScript, więc nie sprawdzono odwołań z kodu; linter nie weryfikuje fabuły ani działania gry.

Ponowna walidacja na kopii z kompletem 203 skryptów GDScript: 964 kluczy, 0 błędów, 2 ostrzeżeń. Uruchomiono `python tools/i18n_lint.py` po zastosowaniu propozycji tego zadania; wynik obejmuje sprawdzane przez linter odwołania z kodu, ale nie zastępuje testu w grze. Dwa ostrzeżenia są bazowe (`settings.voice_pack.line`).
