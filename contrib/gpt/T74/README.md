# T74 — propozycje korekty FR/ES

Punkt odniesienia: `game/i18n/content.csv` z main, commit `96769ea58448dcf3fdb8239c40aed6c7cb530b45` (2026-11-06). Sprawdzono 275 kluczy `job.t43_*` i `job.refuse_t43_*`, czyli 550 pól językowych. CSV zawiera 25 propozycji: FR 7, ES 18. Wiersze bez zmian pominięto. Kolumna `old` zachowuje wartość źródłową do kontroli przed integracją.

Najczęstszy błąd to hiszpański rodzaj i rodzajnik przy *sala común*. Pozostałe propozycje poprawiają naturalność, spójność słownika zamków oraz szczegóły znaczeniowe. Formy oficjalne występują w dialogach; poufałe zwroty między postaciami mogą być uzasadnione kontekstem. Nazwy własne zachowano. W zakresie tych kluczy nie ma limitów 56/28 znaków dla `lock.*`, `tutorial.*` ani `menu.*`; liczby w proponowanych kwestiach są słowne.

Kluczy rozdziałów 7–8 w schemacie T43 w tym pliku nie znaleziono; nie oceniono ich, gdyż nie ustalono odpowiadającego im zakresu. Ocena jest redakcyjną propozycją, nie przeglądem native speakera; zalecana końcowa weryfikacja przez rodzimych użytkowników języka, zwłaszcza fachowych nazw mechanizmów. Plików gry nie zmieniano. `i18n_lint.py` nie uruchomiono: dostawa to tabela poprawek, nie nowy plik z kluczami do dopisania; sprawdzono zgodność wartości `old` i format CSV.
