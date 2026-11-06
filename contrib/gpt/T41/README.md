# T41 — kwestie francuskie i hiszpańskie pod lektora

**Repozytorium:** `woogitsugames/lockwright`, `main`.
**Odczytany hash gałęzi `main`:** `a1023176b12bc12bd5a39f5064693c0c241a421a` (6 listopada 2026, przed przygotowaniem plików).
**Plik przekazania:** `lines_fr_es.csv`, nagłówek dokładnie `keys,fr,es`, **181 wierszy danych** (164 kwestie + 17 etykiet UI), UTF-8.

## Wykonanie

- Przejrzano i zredagowano wszystkie **164 kwestie** w obu językach, na podstawie oryginału polskiego i EN, z kontrolą wieku i charakteru postaci.
- **146 francuskich i 133 hiszpańskie kwestie** różnią się od dostarczonego `fr_current` / `es_current`. Wszystkie pozostałe również skontrolowano; zachowano, gdy brzmiały naturalnie.
- **17/17 nowych etykiet UI** przetłumaczono. Kontrola długości: **0 przekroczeń**. Kwestie nie zawierają cyfr, skrótów tytułów, wielokropków ani zakazanych określeń.
- Dodatkowo `supplemental_ui_fr_es.csv` zawiera **19 kluczy** poza briefem: 6 kluczy tutorialowych brakujących w pakietach w chwili rozpoczęcia T41 oraz 13 kluczy pakietów głosowych dodanych równolegle do `main` po pierwszym commicie. Uzupełniono je w obu językach w osobnym commicie `05e2a78fa5a3954de1e2e6d93b6805aab4ca17f4`.

## Konwencje

- **FR:** pełne **Monsieur X / Madame X** w tekście dla lektora. Jest to wypowiadana postać skrótów **M. X / Mme X** stosowanych w pisemnych opisach. Do dorosłych klientów i dorosłych świadków ślusarz mówi **vous**.
- **ES:** konsekwentnie **señor X / señora X**, bez mieszania z `don` / `doña`. Do dorosłego klienta i do ślusarza obowiązuje **usted**; przy parach lub grupach **ustedes**. Brak zaimka w kwestii nie zmienia formalnej formy czasownika.
- **Wyjątki:** Hania używa `tu` / `tú` i ślusarz odpowiada jej poufale; Halina zwraca się do niego `mon petit` / `hijo`. Rodzice, rodzeństwo i znajomi mogą używać `tu` / `tú` między sobą.
- **Pod lektora:** liczby zapisano słownie, włącznie z rokiem „dziewięćdziesiąt cztery” i pokojem „czterysta dwanaście”. Celowo nie stosuje się literowych skrótów tytułów w kwestiach do syntezy mowy.
- **Słownictwo:** `goupille` / `perno`, `paillette` / `lámina`, `gorge` / `palanca`, `cylindre` / `cilindro`, `cadran` / `dial`. „Otwarcie przez uprawnionego ślusarza” to `ouvrir` / `abrir`, bez sugerowania działań nieuprawnionych.

## Integracja z czterema pakietami v2

Repozytoryjny skrypt `apply_to_repo.py` synchronizuje **wyłącznie**:

- `contrib/gpt/T31/content_fr_v2.csv`
- `contrib/gpt/T31/strings_fr_v2.csv`
- `contrib/gpt/T32/content_es_v2.csv`
- `contrib/gpt/T32/strings_es_v2.csv`

Zachowuje kolumny `key,<lang>_old,<lang>_new,note`, dopisuje uzasadnienia każdej faktycznej zmiany i tworzy brakujące wpisy UI. Nie nadpisuje innych języków ani kodu gry. Wykonuje też kontrolę, czy żadnego klucza nie brakuje w aktualnym źródle. Polecenia po rozpakowaniu do repo:

```bash
python contrib/gpt/T41/apply_to_repo.py --dry-run
python contrib/gpt/T41/apply_to_repo.py
python contrib/gpt/validate_v2_localizations.py --json
```

**Ważne:** oryginalnego walidatora na pełnym checkoutcie nie można było uruchomić w środowisku przygotowywania ZIP-a, ponieważ repozytorium jest dostępne przez konektor GitHub, ale nie jako lokalny checkout. Nie podajemy fikcyjnego wyniku. W początkowej migawce `main` źródła zawierały **629** kluczy `content` oraz **218** kluczy `strings`; po równoległym rozszerzeniu pakietu głosowego źródło ma **231** kluczy `strings`. Dostarczone pliki obejmują 164 kwestie, 17 etykiet T41 i 19 etykiet dodatkowych. Integracja z aktualnym repo uzupełnia **231/231** napisów i **629/629** kluczy `content` dla FR/ES (przy niezmienionej liczbie kluczy); walidacja językowa jest osobnym etapem. Nie należy mylić lokalnego testu paczki z uruchomieniem oryginalnego walidatora w checkoutcie.

## Kontrola QA (lokalnie)

`python contrib/gpt/T42/validate_delivery.py` wykonany na plikach paczki: **0 błędów, 0 ostrzeżeń**. Dotyczy ściśle liczebności, limitów znaków, zapisu cyfr, składni, braków i poprawności struktury. Odbiór jakości nagrań wymaga osobnego odsłuchu głosów AI.

## Miejsca wymagające świadomej decyzji

| Klucz | Wątpliwość |
|---|---|
| `job.dollhouse_wooden_lock.line.3` | Odpowiedź ślusarza skierowano do Hani (`te` / `te`) zamiast do ojca, aby zrealizować wyjątek wieku. |
| `job.kiosk_shutter.line.3` | Angielskie `'94` uznano za rok dziewięćdziesiąty czwarty, bez dopisania stulecia. |
| `job.krakow_tenement_gate.line.3` | Pokój `412` jest wypowiadany jako pełna liczba; odmiana liczby może wymagać doboru konkretnego lektora. |
| `tutorial.say_*` | Sześciu kluczy nie ujęto w dostarczonym T41-input.csv. Dodano osobno dla kompletności v2. |
| `receipt.tip` | Wersja ES „Por apertura cuidadosa” sugeruje powód napiwku, nie sztywne wynagrodzenie. Warto zobaczyć w kontekście układu rachunku. |

**Commity wykonane:** początkowy T41 `aec35aa6e029a12183d7adcac372327c922309f8`, rozszerzenie o pakiety głosowe `05e2a78fa5a3954de1e2e6d93b6805aab4ca17f4`. Wszystkie z `[skip ci]`.