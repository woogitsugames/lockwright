# Częściowa korekta dialogów

To nie jest pełna korekta. Poprawiono wybrane liczby i skróty z myślą o lektorze. W pliku źródłowym pozostają kolejne zapisy cyframi i skróty oraz kwestie wymagające sprawdzenia głosów, sensu i naturalności. Nie weryfikowano obsady CAST.md. CSV zawiera tylko zmienione komórki.

Wynik lintera: lint.txt; uruchomiono go na kopii plików z tymi propozycjami.

Aktualizacja: `UZUPELNIENIE.md` i `fixes_dialogues_pl_en.csv` zawierają dodatkowe propozycje; przegląd nadal pozostaje częściowy.

Dalsze propozycje: `KOREKTA2.csv` i `KOREKTA2.md`. Po zastosowaniu obu zestawów liczby w 215 kwestiach i notatkach są zapisane słownie; pozostają skróty grzecznościowe do decyzji produkcyjnej oraz przegląd naturalności i wymowy. Lint wykonano na kopii sparse bez `.gd`, więc nie weryfikuje on wszystkich odwołań z kodu.

Ponowna walidacja na kopii z kompletem 203 skryptów GDScript: 948 kluczy, 0 błędów, 2 ostrzeżeń. Uruchomiono `python tools/i18n_lint.py` po zastosowaniu propozycji tego zadania; wynik obejmuje sprawdzane przez linter odwołania z kodu, ale nie zastępuje testu w grze. Dwa ostrzeżenia są bazowe (`settings.voice_pack.line`).
