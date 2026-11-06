# T97 — długości DE/FR nowych tekstów UI

Porównano klucze `game/i18n/strings.csv` w HEAD `b50ea45` z migawką `fe35995` (commit finalizujący T71). Przyjęto „dodane od T71” jako klucze obecne teraz i nieobecne w tamtej migawce; późniejsze zmiany tekstu istniejących kluczy nie wchodzą w zakres. Inwentarz obejmuje wszystkie 144 dodanych kluczy z pliku UI, w tym teksty niekoniecznie widoczne na ekranie. `added_ui.csv` podaje EN, DE, FR, długości Unicode i limity znane ze zlecenia.

Przekroczenia twardych limitów `menu.*` ≤ 28 oraz `tutorial.*`/`lock.*` ≤ 56: **0** (wystąpienia językowe). Wiersze „porównaj w UI” przekraczają 28 znaków oraz 130% długości EN; to heurystyka, nie dowód ucięcia. Pozostałe też wymagają testu układu. Długość kodowych punktów Unicode nie jest pomiarem szerokości tekstu. Brak pomiaru renderowania, weryfikacji wszystkich breakpointów i korekty językowej; limity pozostałych prefiksów nie są tu domniemane. Puste teksty są widoczne w CSV.

Nie zmieniono plików gry.
