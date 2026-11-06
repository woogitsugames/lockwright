# T52 — kwestie dzień po

Przeanalizowano 41 plików JSON w game/data/jobs i jobs_ch7 na main. Dla 34 bez pola after przygotowano po jednej kwestii PL/EN/DE oraz mapowanie mówców w speakers.csv. Siedem zleceń z istniejącym after pominięto; dopisanie mówców do danych zleceń i włączenie wyświetlania wymaga integracji. FR/ES pozostawiono puste. Kwestie są propozycjami do redakcyjnej weryfikacji szczegółów fabuły.

Kontrola pokrycia wszystkich `game/data/jobs*/*.json`: 41 zleceń, z czego 34 bez `after` i 7 z istniejącym `after`. Każde z 34 ma jedną kwestię i jedno przypisanie mówcy; nie ma nadmiarowych wpisów ani duplikatów. Żaden nowy klucz nie koliduje z istniejącymi kluczami obu CSV gry. Każdy wskazany mówca występuje w dialogu danego zlecenia i w `voice_cast.json`; zgodność z treścią wieloosobowych scen sprawdzono dla wybranych przykładów, nie wszystkich.

Kontrola: osobną kopię plików game/i18n uzupełniono o CSV tego zadania i uruchomiono tools/i18n_lint.py: 0 błędów. Cztery ostrzeżenia: dwa bazowe oraz po jednym zbiorczym dla pustych FR i ES. Kopia nie zawierała plików GDScript, więc nie sprawdzono odwołań z kodu; linter nie weryfikuje fabuły ani działania gry.

Ponowna walidacja na kopii z kompletem 203 skryptów GDScript: 982 kluczy, 0 błędów, 4 ostrzeżeń. Uruchomiono `python tools/i18n_lint.py` po zastosowaniu propozycji tego zadania; wynik obejmuje sprawdzane przez linter odwołania z kodu, ale nie zastępuje testu w grze. Dwa ostrzeżenia dotyczą celowo pustych kolumn FR/ES, dwa są bazowe.
