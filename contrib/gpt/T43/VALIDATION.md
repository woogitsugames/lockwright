# T43 — wyniki kontroli, 6 listopada 2026

## Kontrola treści i danych: PASS

Polecenie: `python3 contrib/gpt/T43/validate_t43.py /ścieżka/do/kopii/repo`.

- Trzydzieści poprawnych JSON-ów; rozdziały: osiem, siedem, siedem, osiem.
- Dwieście osiemdziesiąt cztery unikatowe klucze i18n, kompletne PL/EN, bez kolizji z odczytanym głównym content.csv.
- Pięć nowych postaci z wiekiem, charakterem, opisem głosu i wyglądu. Dodatkowo cztery istniejące nazwy przeniesione z T18, bez zmiany pisowni.
- Wszyscy mówcy mają nazwy w głównym content.csv lub w dodatku. Karty mają istniejące etykiety w strings.csv.
- Cztery kwestie na zlecenie, co najmniej jedna kwestia ślusarza; jedna–dwie kwestie „dzień po”.
- Dialogi i kwestie „dzień po” nie przekraczają dziewięćdziesięciu znaków; notatki nie przekraczają stu trzydziestu. Brak cyfr i wykrzykników w kwestiach czytanych przez lektora. Zbiory placeholderów PL/EN są zgodne.
- Wszystkie tiery mieszczą się w granicach rodzin BALANCE. Każda z ośmiu nowych rodzin ma co najmniej dwa grywalne zlecenia; odmów nie zaliczano do pokrycia.
- Każdy rozdział ma jedną odmowę oraz jedną interwencję bez otwierania. Cztery odmowy mają zero monet i jednokrotną nagrodę reputacji w specyfikacji przepływu.
- Nagrody bazowe dodatku: trzy tysiące czterysta trzydzieści trzy monety. Wartości dodatku wymagają ponownego sprawdzenia ekonomii całej kariery; nie są zbalansowane symulacją gracza po scaleniu.

Pełny wynik maszynowy: `qa/validation_t43.json`. Walidator kontroluje strukturę i ograniczenia tekstowe, nie gwarantuje poprawności językowej ani czasu gry. Teksty PL/EN przejrzano także redakcyjnie.

## Oryginalny lint i18n: jawny brak DE

Uruchomiono niezmieniony `tools/i18n_lint.py` z repozytorium na lokalnej kopii odczytanych plików; następnie dopisano nowe klucze do kopii `game/i18n/content.csv` i uruchomiono skrypt ponownie.

| wariant | klucze | błędy | ostrzeżenia | exit code |
|---|---:|---:|---:|---:|
| kopia przed dopisaniem | 860 | 0 | 2 | 0 |
| kopia po dopisaniu T43 | 1144 | 284 | 2 | 1 |

Wszystkie nowe błędy mają tę samą przyczynę: `empty value in column 'de'`. Brief pozwalał pominąć DE, więc pozostawiono tę kolumnę pustą. Nie podstawiano angielskiego jako pozornego tłumaczenia. Dwa ostrzeżenia sprzed zmian dotyczą `settings.voice_pack.line`, identycznego wzorca placeholderów w PL/DE i EN. Żaden inny błąd nie pojawił się po dopisaniu danych.

Zakres kopii: oba pełne CSV i18n oraz sześć odczytanych plików GDScript: `job_arrival.gd`, `job_verify.gd`, `job_payment.gd`, `jobs_list.gd`, `dialogue_player.gd`, `job_run.gd`. Nie skopiowano wszystkich skryptów i testów silnika. Kontrola kodowych odwołań i18n jest zatem ograniczona do tych sześciu plików. Nie przedstawiamy tego jako pełnego lint całego repozytorium.

Surowe logi: `qa/i18n_baseline.log` i `qa/i18n_merged.log`. Identyfikatory odczytanych źródeł i portretów zapisano w `qa/source_snapshot.json`.

## Niewykonane testy

Nie uruchamiano Godota, C++ ani rzeczywistej kariery. Nie scalono katalogów produkcyjnych, nie dodano niemieckiego i nowych nagrań głosowych. Przed uruchomieniem wymagana jest implementacja rozstrzygnięć opisanych w `INTEGRATION.md`, zwłaszcza bez otwierania, napraw zegara, scen następczych i jednokrotnego zapisu nagród.
