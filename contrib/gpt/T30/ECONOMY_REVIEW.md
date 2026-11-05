# T30 — druga opinia o ekonomii i progresji Lockwright

**Data oceny:** 2026-11-05  
**Punkt odniesienia repozytorium:** `main` @ `152f95cdda04b17f8554d9f44aa0bbb460c93bbb`  
**Status:** rekomendacje projektowe, **bez** zmian `game/data/`, `docs/`, `tools/` ani kodu gry. Warianty premium i demo są alternatywami; **D-06 pozostaje otwarta**, bez ustalania ceny, daty premiery i dostępności.

## 1. Werdykt

**Obecnie ekonomia blokuje treść fabularną, zamiast nagradzać naukę zawodu.** Problemem nie jest sama stawka `10 × tier` w Trybie Ciągłym, ale połączenie wysokich cen narzędzi, warunków odblokowania wymagających tierów jeszcze niedostępnych w fabule oraz niedopasowania dokumentacji do aktualnych danych. Obniżanie samych cen nie wystarcza: **narzędzie wymagane do kolejnego legalnego zlecenia powinno być zawsze możliwe do wypożyczenia**. Monety mogą służyć do zakupu własnego egzemplarza, napraw, gabloty i warsztatu, nie do płacenia za prawo kontynuowania opowieści.

**Priorytety:** P0 — usunąć obowiązkowy grind i martwe odblokowania; P0 — zsynchronizować symulator z danymi; P1 — rozdzielić nagrodę pieniężną od zaufania i fabuły; P1 — złagodzić skok trudności w wyższych tierach; P2 — przetestować retencję i czas rozdziałów na graczach.

## 2. Stan faktyczny i porównanie z istniejącą symulacją

### 2.1 Liczby źródłowe

| Miernik | Stan źródłowy | Znaczenie |
|---|---:|---|
| Zlecenia w `game/data/jobs/` | **29** | 6 rozdziałów; nagłówek „28” w `docs/JOBS.md` jest nieaktualny. |
| Suma `reward_coins` | **2340 monet** | Sprawdzone z 29 plików JSON; obejmuje **90 monet** w `job.refuse_aunt_alive` mimo odmowy. |
| Suma nagród po proponowanej korekcie tej odmowy | **2250 monet** | Konserwatywny budżet bez napiwków i Trybu Ciągłego. |
| Zakup 9 narzędzi wymaganych w scenach z `JOBS.md` | **6400 monet** | Przy obecnym cenniku `game/data/tools.json`. Narzędzia startowe i `kit_clock` mają cenę 0. |
| Luka: 6400 − 2340 | **4060 monet** | Nawet pełny dochód bazowy nie pokrywa obowiązkowego wyposażenia; po korekcie odmowy luka wynosi 4150. |
| `game/data/progression.json` | współczynnik **1.2**, orientacyjnie **385 monet / 8 min** | `docs/PROGRESSION.md` nadal opisuje współczynnik **0.55** i ~**300 monet / 8 min**. |
| `game/data/tools.json` | naprawa złamanego **15% + 10, limit 150** | `docs/TOOLS.md` i `tools/econ_sim.py` nadal używają **35%**. |

Wartość 6400 wynika z: `tl_shackle` 150 + `pk_lever` 300 + `tl_polar` 700 + `pk_crown` 600 + `tl_cup` 1200 + `tw_bar` 450 + `pk_flag` 900 + `pk_plunger` 1000 + `pk_disc` 1100. **To nie są wszystkie narzędzia w sklepie**, lecz zestaw przypisany przez symulator i biblię zleceń do przejścia kampanii.

### 2.2 Opublikowane wyniki `docs/ECONOMY.md` — historyczny punkt odniesienia

| Scenariusz z raportu | Profil | Zablokowane / 29 | Wymuszony Tryb Ciągły | Czas grindu | Czas samych zleceń |
|---|---|---:|---:|---:|---:|
| B: rodziny wg `JOBS.md`, współczynnik 0.55 | average | **3** | **31 sesji** | **4.3 h** | 40.2 min |
| C: dawne propozycje, współczynnik 1.2 | careful | **0** | **7 sesji** | **1.0 h** | 61.5 min |
| C: dawne propozycje, współczynnik 1.2 | average | **0** | **8 sesji** | **1.1 h** | 46.7 min |
| C: dawne propozycje, współczynnik 1.2 | clumsy | **0** | **12 sesji** | **1.7 h** | 36.0 min |

Raport podaje też medianę dochodu pierwszej ośmiominutowej sesji B: **270/280/270**, C: **375/402/385** monet (careful/average/clumsy). **Nie wolno nazywać tych wartości wynikami ponownej symulacji aktualnej wersji.** Obecne JSON-y zawierają już część zmian scenariusza C, zaś kod symulatora nadal stosuje stary koszt naprawy i niezależne od JSON-a współczynniki. Wynik „C = 8 sesji” jest dobrym ostrzeżeniem, ale nie aktualną metryką wydania.

**Ocena:** redukcja obowiązkowego grindu z 31 do 8 sesji jest postępem, nie rozwiązaniem. W grze o spokojnym fachu 64 minuty zbierania monet tylko po to, by ruszyć do następnego klienta, to nadal nieuzasadniony przestój. Co więcej, 29 scen w scenariuszu C trwa średniemu profilowi niespełna 47 minut *w modelu*, a nie w rzeczywistym playteście; symulator pomija wiele etapów poza samym zamkiem i dialogiem.

## 3. Dwie alternatywy liczbowe — bez rozstrzygania D-06

**Obie propozycje**: brak sprzedaży monet, energii, reklam wymuszających postęp i pay-to-win; ceny są w **fikcyjnych monetach gry**. Zakładam 29 aktualnych zleceń, bazowe wypłaty z JSON (z poprawką odmowy za 90 na 0), brak napiwków i brak obowiązkowego Trybu Ciągłego. Zakup osobistego narzędzia jest dobrowolny: do zlecenia można dostać wyposażenie na czas pracy. Nie oznacza to darmowego nabycia całego katalogu.

### 3.1 Ceny narzędzi potrzebnych fabule

| ID | Pierwsze użycie wg `JOBS.md` | Aktualnie | **P — premium** | **D — demo + jednorazowe odblokowanie** |
|---|---|---:|---:|---:|
| `pk_ward` | 1: `grandma_broth` | 0 | **0** | **0** |
| `tl_shackle` | 3: `bike_interview` | 150 | **60** | **40** |
| `pk_lever` | 8: `pizzeria_pays_pizza` | 300 | **120** | **100** |
| `tl_polar` | 9: `night_nurse` | 700 | **180** | **160** |
| `pk_crown` | 12: `drummer_locker` — wg fabuły rurkowy | 600 | **120** | **100** |
| `tl_cup` | 14: `uncle_safe_heirs` | 1200 | **240** | **220** |
| `tw_bar` | 22: `brussels_townhouse` | 450 | **140** | **130** |
| `pk_flag` | 22: `brussels_townhouse` | 900 | **200** | **180** |
| `pk_plunger` | 27: `bramah_bureau` | 1000 | **220** | **200** |
| `pk_disc` | 28: `finnish_sailor` | 1100 | **240** | **220** |
| **Suma 9 płatnych** | | **6400** | **1520** | **1350** |

**Wariant P:** ceny niższe o **76.25%** względem obecnych 6400. Wszystkie rodziny otwierają nową czynność lub sposób obserwacji, nigdy premię do statystyk. Gracz kupuje własny, niezawodny egzemplarz oraz personalizację warsztatu; pożyczony wraca do mentora po zleceniu.

**Wariant D:** ceny niższe o **78.91%** względem obecnych 6400, aby krótszy darmowy początek nie tworzył dodatkowej bariery pieniężnej po odblokowaniu treści. **To osobny wariant balansu, nie równoczesny drugi cennik dla tej samej gry.** Zakup pełnej zawartości nie daje monet ani przewagi mechanicznej — wyłącznie dostęp do kolejnych rozdziałów, rodzin i trybów.

Pozostałe narzędzia (np. `pk_ripple`, `pk_wedge`, `pk_feather`, mikroskop, wziernik, wiertarka) powinny mieć osobny audyt przy ich faktycznym wejściu do gry. **Nie należy** traktować ich ceny jako warunku ukończenia 29 scen, jeżeli nie są do tych scen obowiązkowe.

### 3.2 Jawny test budżetu — nie Monte Carlo

Sprawdziłem arytmetycznie 29 zleceń w kolejności `JOBS.md`, z ich faktycznymi nagrodami w JSON, z korektą `refuse_aunt_alive: 90 → 0`; narzędzia są kupowane **dopiero przy pierwszej potrzebie**, zawsze gdy wystarcza gotówki. Nie doliczam napiwków ani pieniędzy z Trybu Ciągłego. Zakładam odblokowanie przed lekcją danej rodziny oraz interpretację `drummer_locker` jako „rurkowy”, zgodną z fabułą. To **nie** jest ponowne uruchomienie `econ_sim.py`.

| Test | P: premium | D: demo + unlock |
|---|---:|---:|
| Dostępna baza nagród po korekcie | 2250 | 2250 |
| Pełen koszt 9 zakupów | 1520 | 1350 |
| Po wszystkich 29 zleceniach, bez kosztów napraw | **730** | **900** |
| Zakupy bez żadnego grindu, bez napiwków, bez napraw | **9/9** | **9/9** |
| Saldo końcowe przy konserwatywnym koszcie **10 monet za każde z 25 zleceń z zamkiem** | **480** | **650** |
| Dodatkowe wypożyczenia w teście 10 monet / zamek | **0** | **0** |

Przy stresie **15 monet naprawy za każdy zamek** wariant P potrzebuje **jednego wypożyczenia** (brak 10 monet na `tl_cup` przy zleceniu 14); wariant D nadal kupuje **9/9** bez wypożyczeń. Ta wersja testu obciąża nawet zamki niezłamane, więc służy wyłącznie sprawdzeniu płynności. Nie modeluje losowych złamań, tipów, rabatów, reputacji ani kolejności przyszłych promocji. **Obie propozycje eliminują wymuszone sesje** dzięki zasadzie wypożyczenia, nie dzięki obietnicy, że każdemu zawsze starczy pieniędzy.

### 3.3 Jak odblokowywać bez „martwych progów”

**Reguła nadrzędna:** fabularne narzędzie otrzymuje gracz przed pierwszą sceną, która go wymaga. Lekcja S1–S3 odbywa się przed tą sceną. Próg tieru może otwierać **wcześniejszy zakup do Trybu Ciągłego**, ale nigdy nie jest jedyną drogą do legalnego zlecenia.

| Narzędzie | Proponowany warunek fabularny | Dlaczego |
|---|---|---|
| `pk_ward` | zestaw na start / po samouczku, **przed zleceniem 1** | Pierwszy klient nie powinien wymagać zakupów ani minigrindu. |
| `tl_shackle` | po scenie 2, przed 3 | Obecne `after_first_t2` jest błędnym kołem w ścieżce samych zleceń (1–2 są T1). |
| `pk_lever` | przed 8 | Nauczyciel demonstruje nową rodzinę; nie wymaga ukończenia innego trybu. |
| `tl_polar` | przed 9 | `after_t4` wymaga poziomu, którego nie ma przed tą sceną bez grindu. |
| `pk_crown` | przed 12 | Najpierw rozstrzygnąć, czy `drummer_locker` ma być „rurkowy” (fabuła), czy „wafer” (JSON). |
| `tl_cup` | przed 14 | `after_t4` jest za późno w przebiegu fabularnym bez Trybu Ciągłego. |
| `tw_bar` + `pk_flag` | przed 22 | `pk_flag.after_t5` jest niedostępny przed pierwszą sceną, która go wymaga; `tw_bar` także potrzebuje lekcji. |
| `kit_clock` | przed 26 jako wyposażenie do zlecenia | Bez wymagania zakupów. |
| `pk_plunger`, `pk_disc` | przed 27 i 28 | Gwarantowany dostęp; mastery tierów może dać wcześniejsze odblokowanie. |

Widziane przez gracza „pożyczenie” może być zwykłą sceną: mistrz kładzie narzędzie na zwijce, pokazuje je przez chwilę, a po zleceniu wraca ono na hak w warsztacie. Nie powinno pojawić się techniczne „nie masz 200 monet, zagraj jeszcze raz”.

## 4. Krzywa trudności i nauka

Współczynnik **0.55** z `docs/PROGRESSION.md` jest zdecydowanie zbyt niski względem tabeli, **1.2** z aktualnego JSON jest bliższy celowi. Proponuję **P: 1.15** oraz **D: 1.10 w darmowym prologu, po odblokowaniu 1.15**. Umiejętność `skill` powinna być liczona z ostatnich 5 ukończonych zamków i ograniczona do 0.8–1.25, nie wpisana na stałe według profilu.

`tier(n) = clamp_to_owned_family(max(1, floor(1 + k × ln(1+n) × skill)))`, z limitem maksymalnie **+1 tier** względem poprzedniego ukończonego zamka. Po dwóch kolejnych złamaniach jawnie obniżyć następny o **1 tier**, zgodnie z `docs/PROGRESSION.md`; ani timer, ani brak haptyki nie może być warunkiem dalszej gry.

| Zamek `n`, `skill=1` | Stara 0.55: tier po podłodze | Aktualna 1.20 | P 1.15 | D prolog 1.10 |
|---|---:|---:|---:|---:|
| 3 | 1 | 2 | 2 | 2 |
| 8 | 2 | 3 | 3 | 3 |
| 15 | 2 | 4 | 4 | 4 |
| 25 | 2 | 4 | 4 | 4 |
| 40 | 3 | 5 | 5 | 5 |

Sam wzór nie rozwiąże skoków w obrębie rodziny. `lockcore/BALANCE.md`: bot „niezdarny” przechodzi `pin_tumbler` t6 w **93.7%**, t7 tylko w **36.0%**; `lever_detector` t6 w **42.5%**, gdy t5 w **99.87%**. Wysokie tiery powinny być wyzwaniami dobrowolnymi / mistrzowskimi, **nie** progami fabuły. W Trybie Zleceń wprowadzać maksymalnie dwie trudniejsze osie naraz i zawsze po lekcji rodziny. Rozdział 4 używa `warded T3`, ale `lockcore` obsługuje tę rodzinę maksymalnie na t2: obietnica „mistrzowskiego” zadania nie odpowiada parametrom silnika.

**Rytm satysfakcji:** w 1. sesji pierwszy samodzielny zamek, pierwsza uczciwa wycena i pierwsze sprawdzenie prawa do lokalu; potem nowy rodzaj informacji lub istotna reakcja klienta co **2–3 zlecenia**. Po odmowie nagrodą ma być **zaufanie i konsekwencja sceny**, nie monety. Każdy rozdział powinien dać co najmniej jedną nową notkę gabloty / przedmiot albo zmianę warsztatu. Odróżniać *ukończenie*, *bez śladów*, *odmowę zgodną z zasadami* i *mistrzostwo* — cztery typy postępu, zamiast jednej kwoty.

## 5. Tryb Ciągły: nagroda, zmęczenie, użyteczność

| Parametr | Dane / obecny opis | P: premium | D: prolog demo |
|---|---|---|---|
| Sposób gry | 3 ostrza = 3 życia, postój co 5 zamków | **Bez zmian** | **Bez zmian** |
| Wzrost tieru `k` | JSON **1.2**, dokument **0.55** | **1.15** | **1.10**; po odblokowaniu **1.15** |
| Limit rodzin / tierów | Zależny od narzędzi i tutoriali | Wszystkie poznane; narzędzia rzeczywiście sprawdzane | Darmowe rodziny po S3, **maksymalnie tier 3** |
| Dochód za zamek | `10 × tier`, „czysto” +50%, ciemność +20% | **Zostawić**, ale weryfikować oba bonusy i zaokrąglenia | **Te same stawki**, bez „kary za demo” |
| Długość odcinka | Zapis między zamkami, 5–10 min | Cel **6–10 min** na naturalną przerwę | Cel **6–10 min**, brak limitu liczby sesji |
| Obowiązkowe sesje dla fabuły | Historyczne C: **8 mediany average** | **0** | **0** |
| Cel do walidacji, nie wynik pomiaru | W starej C: average **402 / 8 min** | Mediana **300–380 / 8 min** | Mediana **240–330 / 8 min** w puli prologu |

Nie zmniejszać nagrody za porażkę tak, by powstało błędne koło. Monety za faktycznie otwarte zamki zostają graczowi nawet gdy seria skończy się na trzecim złamaniu. Nie karać za brak dźwięku albo haptyki. Postój co 5 zamków ma wyraźnie dawać **możliwość zakończenia i zapisania wyniku**, a nie tylko zakupu.

**Błąd do zweryfikowania w implementacji:** `econ_sim.py` przypisuje `pin_tumbler` tylko `tw_angle` + `pk_hook`, nawet na wysokim tierze. Tymczasem macierz `TOOLS.md` wymaga od t5 w wąskim kanale `tw_bar`. Samo posiadanie `tw_bar` w symulatorze podnosi `tier_max` z 5 do 7, nie zapewnia jednak poprawnego użycia narzędzia. Błędne filtrowanie rodzin i tierów może zawyżać liczbę legalnie dostępnych wyzwań.

## 6. Premium kontra demo: granica treści, nie monety

**P (pełna gra od startu):** od początku dostęp do warsztatu i drogi fabularnej. Tryb Ciągły jest *alternatywą* (ćwiczenie, ranking lokalny, rzadkie kosmetyki), nie drugim etatem potrzebnym do zapłacenia za klienta. Zakupy służą kolekcjonowaniu i decyzji „własny egzemplarz czy narzędzie od mistrza”.

**D (demo z jednorazowym odblokowaniem):** proponowana bezpłatna część to **6 zleceń rozdziału 1**, wraz z pierwszą odmową, początkowymi lekcjami, warsztatem i powtarzalnym Trybem Ciągłym na znanych rodzinach do **t3**. Po zakończeniu rozdziału gra jasno informuje, jakie **treści** otworzy pełna wersja; nie pokazuje kosztów IAP jako „ceny brakujących monet”. **Stan zapisany w demo, zarobione monety i postępy samouczka zostają.** Odblokowanie nie daje bonusu do prawdopodobieństwa otwarcia zamka, lives, napiwków ani przyspieszenia zarobków.

W obu wersjach warto oddzielić nagrody *z opowieści* (gablota, list, pamiątka, zaufanie) od zasobów powtarzalnych. To szczególnie ważne w `pizzeria_pays_pizza` oraz `time_capsule`: **0 monet** może być dobrym zakończeniem tylko wtedy, gdy gracz widzi pełnoprawną nagrodę rzeczową/narracyjną.

**Przykładowe teksty dla gracza (PL / EN):**

| Moment | PL | EN |
|---|---|---|
| Uczciwa odmowa | „Dziś bez rachunku. Ale zaufanie zostaje.” | “No invoice today. But the trust stays.” |
| Narzędzie na czas pracy | „Pożyczę panu to na zlecenie. Potem wróci na hak.” | “Take this for the job. It goes back on the hook afterwards.” |
| Koniec serii | „Tyle na dziś. Wynik zapisany w zeszycie.” | “That will do for today. I've noted the result.” |

Wszystkie komunikaty na przedmiotach, kartach zleceń, w zeszycie i warsztacie, **nie** na pływających panelach podczas otwierania.

## 7. Usterki i ryzyka w obecnym modelu obliczeniowym

1. **Nieaktualna etykieta „A = data as is”.** W kodzie scenariusz A zawsze wymusza `coef=0.55`, chociaż aktualny `progression.json` ma `1.2`. Część cen/families z dawnej propozycji C już jest w JSON, więc A/B nie są dawnym baseline'em.
2. **Niespójne źródła rodziny.** `drummer_locker`: fabuła `JOBS.md` i mapowanie symulatora B/C mówią „tubular”, obecny JSON ma `family: wafer`. Pozostałe „warded” i `liege_bakery: lever_detector` zostały już poprawione w JSON. Stary punkt §1 `ECONOMY.md` o 7 błędnych `lever` nie jest już opisem bieżących danych.
3. **Naprawy:** `repair_all()` liczy 35% ceny przy złamaniu, ignorując `wear_model.repair_broken_pct=0.15`, `repair_broken_extra_coins=10` i limit 150. Dodatkowo `cost = min(cost, coins)` **przywraca I=100 wszystkim kwalifikującym się narzędziom nawet przy braku pieniędzy na pełen rachunek**. To ukryty darmowy remont, który zniekształca obciążenie słabego gracza.
4. **Odmowa z wypłatą.** `NO_LOCK_JOBS` obejmuje `refuse_aunt_alive`, lecz w JSON nagroda to **90**, którą symulator wypłaca za samą odmowę; narusza to `CLIENTS.md` („odmowa nie przynosi monet”). `wrong_floor` ma 20 monet; przed zmianą trzeba rozstrzygnąć, czy to jawna opłata za dojazd.
5. **Odblokowania nie są grafem zależności.** `unlock_ok()` odczytuje `after_t7_F3` regexem `after_t(\d)` i ignoruje sufiks `_F3`; podobne warunki i wymóg `after_first_t2` trzeba przetestować na pustym zapisie. Symulator nie modeluje pełnego samouczka, a aktualne `pk_ward: price=0, unlock=after_t1` „kupuje” automatycznie ze startowym `max_tier=1`.
6. **Waluta i czas Trybu Ciągłego nie są dokładnie ośmiominutowe.** Pętla `while elapsed < 480` kończy ostatni zamek **po przekroczeniu** 480 sekund, a wynik opisuje jako 8 minut. Po trzecim złamaniu rozpoczyna nowy bieg w tej samej sesji. Potrzeba oddzielnej metryki *bieg*, *sesja*, *czas faktyczny*.
7. **Niewalidowana trudność części rodzin.** Magnetyczny, rurkowy, tarczowy, czasowy, dimple, suwakowy i obrotnik tarcz mają w symulatorze szacowane czasy **20/26/34 s**, nie pomiary `lockcore`. Nie wyciągać z nich twierdzeń o realnej retencji.
8. **„Clumsy jest szybszy” wynika z definicji profilu.** `human_x` wynosi 2.0 dla clumsy, 2.4 dla average, 3.0 dla careful; stąd w dawnym C odpowiednio **36 / 47 / 62 min** treści. To założenie, nie obserwacja zachowań graczy.
9. **Próg zakupu i wypożyczenia nie są modelowane.** Symulator wymusza grind do zakupów i zakłada naprawy, ale nie umie zasymulować poprawnej ścieżki fabularnej z narzędziami wypożyczonymi; nowych wariantów P/D nie wolno odtwarzać samą podmianą cen.

## 8. Kryteria odbioru po ewentualnej implementacji

- **100%** obowiązkowych zleceń dostępnych w kolejności na świeżym zapisie bez Trybu Ciągłego, dla profili careful/average/clumsy; **0** wymuszonych sesji i **0** niedostępnych narzędzi fabularnych.
- Pomiary łącznego czasu ukończenia zadań osobno od tutoriali, dialogów i warsztatu; **p50 / p90**, nie sama mediana z 200 karier. Obecne ~47 min z symulatora to sygnał, że przed sprzedażą jako pełna gra potrzeba więcej *treści*, a nie wydłużania zakupów: do decyzji cel **90–150 min** pierwszego przejścia oraz **co najmniej 60** różnorodnych zleceń/scen lub porównywalna wartość powtórek.
- Dla każdej rodziny pomiar: odsetek ukończeń, p50/p90 czasu, liczba złamań, przerywania sesji, przejścia z S3 do pierwszego zlecenia, częstość wyboru wypożyczenia, poziom środków przed zakupem.
- W Trybie Ciągłym: rozkład tierów po zamkach **3/8/15/25/40** dla wszystkich trzech profili i sprawdzenie, że żaden tier nie wymaga narzędzia, którego system faktycznie nie dopuścił.
- Test przy **0 napiwków**, wysokich kosztach napraw, kilku kolejnych odmowach, wyłączonej haptyce i dźwięku, przerwaniu biegu przy przystanku, odtworzeniu zapisu demo po odblokowaniu.
- Przed aktualizacją dokumentacji i symulatora wymagane są właścicielskie decyzje D-06 oraz rozstrzygnięcie: „rurkowy” czy „płytkowy” w `drummer_locker`, opłata 20 za pomylone piętro i narracyjny status narzędzi wypożyczonych.

## 9. Materiał źródłowy i ograniczenia

Analiza opiera się na `CLAUDE.md`, `docs/DESIGN.md`, `docs/CLIENTS.md`, `docs/JOBS.md`, `docs/DECISIONS.md` (D-06 i D-51), `docs/ECONOMY.md`, `tools/econ_sim.py`, `docs/PROGRESSION.md`, `docs/TOOLS.md`, `lockcore/BALANCE.md` oraz **29** `game/data/jobs/*.json`, `game/data/tools.json` i `game/data/progression.json` z podanego commita.

**Metodologia:** w repo istnieje opublikowana symulacja 200 karier/profil/scenariusz; jej historyczne mediany przytoczono wyraźnie jako historyczne. Nowe liczby P/D pochodzą z **niezależnego deterministycznego testu salda** (kolejność 29 zleceń, zakupy przy pierwszym wymaganym użyciu, bez napiwków, dwie stawki kosztów napraw); nie są nową symulacją Monte Carlo ani pomiarem czasu gry. Nie udało się uruchomić `tools/econ_sim.py` w tej sesji: repozytorium było dostępne przez połączenie GitHub do odczytu i zapisu, ale lokalny kontener nie miał dostępu do sieci, a kod i wszystkie dane repozytorium nie były zmaterializowane w lokalnym systemie plików. Nie deklaruję zatem nowych wyników losowej symulacji.

**Wniosek projektowy:** wybrać wariant **P** w wypadku gry premium, **D** w wypadku dema z odblokowaniem. W obu ważniejsza od obniżki cen jest reguła *„klient może poczekać na fachowca, ale nie na farmienie monet”*.
