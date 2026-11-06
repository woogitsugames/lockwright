# T59 — Dyżur

Przygotowano 20 krótkich kwestii dyspozytora w pięciu językach; każda ma maksymalnie 56 znaków. Klucze są propozycją do integracji i wymagają uzgodnienia z nazwami używanymi w grze. Sprawdzono długość wszystkich kwestii skryptem Python.

Kontrola: osobną kopię plików game/i18n uzupełniono o CSV tego zadania i uruchomiono tools/i18n_lint.py: 0 błędów i dwa ostrzeżenia bazowe dotyczące settings.voice_pack.line. Kopia nie zawierała plików GDScript, więc nie sprawdzono odwołań z kodu; linter nie weryfikuje fabuły ani działania gry.

Ponowna walidacja na kopii z kompletem 203 skryptów GDScript: 968 kluczy, 0 błędów, 2 ostrzeżeń. Uruchomiono `python tools/i18n_lint.py` po zastosowaniu propozycji tego zadania; wynik obejmuje sprawdzane przez linter odwołania z kodu, ale nie zastępuje testu w grze. Dwa ostrzeżenia są bazowe (`settings.voice_pack.line`).
