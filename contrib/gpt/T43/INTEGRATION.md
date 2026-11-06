# T43 — integracja przed uruchomieniem

Pakiet jest dostawą treści w zakresie `contrib/gpt/T43/`, nie wdrożeniem. JSON-y zachowują istniejący schemat, a dodatkowy `flow_t43.json` jest specyfikacją dla integratora. Silnik obecnie go nie wczytuje. Nie kopiować samych JSON-ów na produkcję bez poniższych zmian.

## Kolejność i rozdziały

1. Scalić `content_t43.csv` z `game/i18n/content.csv` przez klucz `keys`; zachować UTF-8 i cztery kolumny. Pięć nowych nazw postaci oraz cztery nazwy przejęte z T18 są w pakiecie. Jeśli T18 już scalono, istniejące `cast.janka/leon/mila/oskar.name` należy zachować i nie dopisywać ich drugi raz. Nazwy są zgodne z T18. W przypadku rozbieżnych tłumaczeń przerwać automatyczne scalanie i wybrać świadomie.
2. Dodać rozdziały dziewiąty–dwunasty do właściwego rejestru po scaleniu rozdziałów siódmego i ósmego. Obecny `jobs_list.gd` zna osobny katalog `jobs_ch7`, a T18 znajduje się w `contrib`. Nie zakładać, że opublikowany runtime wczytuje rozdział ósmy.
3. W `jobs_list.gd` sortowanie składa tekst z numeru rozdziału i id. Dla wielocyfrowych numerów da dziesiąty przed dziewiątym. Porównywać `chapter` jako liczbę; wewnątrz rozdziału użyć `chapter_order` z manifestu. Prefiks odmów musi nadal zaczynać się od `job.refuse`, więc samo sortowanie alfabetyczne przesuwa odmowy na początek.

## Rozstrzygnięcia scen

| kind w flow_t43.json | zachowanie | zakończenie |
|---|---|---|
| open | weryfikacja i właściwa minigra rodziny | zapłata po sukcesie |
| refusal | akceptacja otwarcia niedostępna | zapis odmowy, pięć reputacji raz, zero monet |
| no_open | weryfikacja i rozwiązanie rozmową, bez wejścia do sceny zamka | konsultacja czterdzieści monet raz |
| clock_repair | minigra naprawy odłączonego zegara na stole | zapłata za serwis, bez otwarcia i zwolnienia rygla |

`job_verify.gd` rozpoznaje odmowy po prefiksie id i blokuje akceptację. Nie ma ogólnego rozstrzygnięcia rozmowy bez otwierania; akceptacja zawsze przechodzi do `JobRun.lock_scene_path()`. Trzeba dodać jawne rozgałęzienie, zanim udostępni się dwa zlecenia `no_open`. Nie używać w nich rodziny `unknown`: ukryłoby to zlecenia, zamiast rozwiązać ich przebieg. Rodzina w JSON-ie opisuje oglądany przedmiot; manifest definiuje, że go nie otwieramy.

Dwie sceny `time_lock` naprawiają wymontowane zespoły zegarowe. Konfiguracja sceny nie może pokazać otwierania skarbca ani przyspieszać czasu blokady. `job_payment.gd` ma stały komunikat `job.opened`, dźwięk otwierania i obliczanie napiwku za czyste otwarcie. Dla rozpoznania i naprawy zastąpić komunikat odpowiednio rozpoznaniem lub naprawą, nie odtwarzać otwarcia drzwi i nie naliczać automatycznego napiwku za otwarcie. Zapis wyniku i wypłata muszą być jednokrotne także po cofnięciu, wznowieniu i ponownym wejściu.

## Weryfikacja i prezentacja

- `cards` używa wyłącznie typów obecnych w danych gry. `verification` opisuje uprawnienie do konkretnego obiektu i ustalenie ceny, bez instrukcji otwierania. Progi dwa–trzy zachowują skalę istniejących JSON-ów; nie są nową punktacją prawa dostępu.
- Obecny `job_verify.gd` renderuje dwie karty, ale nie sumuje ich wag ani nie egzekwuje `threshold`. Zlecenia weryfikacji wymagają faktycznej obsługi tego pola albo jawnie napisanej decyzji, zamiast sugerowania graczowi działającego automatycznego scoringu. Nowe dane nie naprawiają tego braku.
- Cztery kwestie na zlecenie mieszczą się w obecnym `MAX_LINES = 4` w `job_arrival.gd`. Mówca `locksmith` pozostaje po prawej dzięki istniejącej regule UI.
- Obsłużyć `after` także po odmowie i rozwiązaniu bez otwarcia. Obecna gałąź odmowy odsyła bezpośrednio do listy. Sceny „dzień po” nie mogą wypłacać drugi raz nagrody.
- Dodać pięć portretów i głosów do nowych identyfikatorów z `cast_t43.csv`. Portrety nie są częścią tekstowego T43. Istniejący fallback inicjału pozwala wyświetlić nowe postacie bez portretu; brak nagrania ma dać napisy, bez audio w innym języku.
- Sprawdzić dostępność `lever_detector` w wersji przeznaczonej do integracji. W odczytanym `JobRun` lista `PHOTOREAL_READY` pomija tę rodzinę; nie zmieniać jej na zwykły `lever` wyłącznie po to, żeby wyświetlić zlecenie.

## Odbiór po scaleniu

Uruchomić pełny lint i18n, test przejścia kariery i próby czterech zakończeń, w tym wznowienie zapisu bez podwójnej zapłaty lub reputacji. Dodać niemiecki przed wymagającym go pełnym lintem. Sprawdzić rzeczywisty czas kariery na graczach; boty i liczba JSON-ów nie potwierdzają dwóch godzin zabawy.
