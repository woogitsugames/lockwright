# T52 — kwestie dzień po

Przeanalizowano 41 plików JSON w game/data/jobs i jobs_ch7 na main. Dla 34 bez pola after przygotowano po jednej kwestii PL/EN/DE oraz mapowanie mówców w speakers.csv. Siedem zleceń z istniejącym after pominięto; dopisanie mówców do danych zleceń i włączenie wyświetlania wymaga integracji. FR/ES pozostawiono puste. Kwestie są propozycjami do redakcyjnej weryfikacji szczegółów fabuły.

Kontrola: osobną kopię plików game/i18n uzupełniono o CSV tego zadania i uruchomiono tools/i18n_lint.py: 0 błędów. Cztery ostrzeżenia: dwa bazowe oraz po jednym zbiorczym dla pustych FR i ES. Kopia nie zawierała plików GDScript, więc nie sprawdzono odwołań z kodu; linter nie weryfikuje fabuły ani działania gry.
