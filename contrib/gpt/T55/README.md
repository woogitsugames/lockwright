# T55 — cele ćwiczeń

Dwa cele dla każdej z ośmiu rodzin, pięć języków. Cele rozróżniają sygnały, ustawienie elementów i powrót po pułapce, zgodnie z tekstami i specyfikacjami lekcji rodzin. Identyfikatory t31–t46 są propozycją, a nie istniejącymi lekcjami: plik families.csv mapuje je na rodziny. Brak plików zamków i zdarzeń lesson_target; te cele wymagają zaprojektowania i testu osiągalności, zgodnie z D-54, przed integracją. W time_lock przewidziano naprawę, nie otwarcie.

Kontrola: osobną kopię plików game/i18n uzupełniono o CSV tego zadania i uruchomiono tools/i18n_lint.py: 0 błędów. Dwa ostrzeżenia bazowe dotyczą identycznej treści pola settings.voice_pack.line. Kopia nie zawierała plików GDScript, więc nie sprawdzono odwołań z kodu; linter nie weryfikuje fabuły ani działania gry.

Ponowna walidacja na kopii z kompletem 203 skryptów GDScript: 964 kluczy, 0 błędów, 2 ostrzeżeń. Uruchomiono `python tools/i18n_lint.py` po zastosowaniu propozycji tego zadania; wynik obejmuje sprawdzane przez linter odwołania z kodu, ale nie zastępuje testu w grze. Dwa ostrzeżenia są bazowe (`settings.voice_pack.line`).
