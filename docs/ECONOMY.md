# Ekonomia kariery — symulacja (tools/econ_sim.py)

Wygenerowane przez `python3 tools/econ_sim.py` (200 karier na profil i scenariusz, seed deterministyczny). Dane wejściowe: `game/data/jobs/*.json`, `game/data/tools.json`, `game/data/progression.json`, `lockcore/BALANCE.md`, `docs/JOBS.md`. Scenariusz C = dane gry bez zmian (ceny D-62); D = zamrożone ceny sprzed D-62 z narzędziem jako bramką zlecenia; A i B to diagnostyka starej krzywej.

## 1. Wnioski w skrócie

1. **D-62: tańsze narzędzia, nigdy blokada zlecenia.** Ceny w `tools.json` (C) spadły z 10100 do 2820 monet za wszystkie 14 płatne narzędzia, a z 6400 do 1790 za te, które mają użycie w zleceniach (9 szt.). Suma nagród 29 zleceń to 2340 monet, plus napiwki. Gra nie sprawdza narzędzi przy przyjęciu zlecenia; model C też nie: brak narzędzia daje wolniejszy zamek (×1.15) i słabszy feedback, ale nie grind.
2. **Przed (D, stare ceny, narzędzie bramką):** zablokowanych zleceń careful/average/clumsy 0/0/0; sesji grindu 7/8/11; dochód ze zleceń 2774/2555/2385 + grind 4252/4478/5840 monet wobec 6400/6400/6400 wydanych na narzędzia.
3. **Po (C, nowe ceny, narzędzia opcjonalne):** zablokowanych 0/0/0; sesji grindu 0/0/0; dochód ze zleceń 2784/2554/2402 monet, wydane na narzędzia 2320/2320/2080 (kupione: 13/13/12 z 13 osiągalnych płatnych); monety niewydane na koniec kariery 462/219/154; zamków granych bez własnego narzędzia 4/4/5.
4. **Dochód a koszt narzędzi (C):** dochód ze zleceń / łączny koszt wszystkich płatnych narzędzi (2820) = 99%/91%/85% (careful/average/clumsy); wobec stanu sprzed D-62: 27%/25%/24%.
5. **Naprawy (C):** 0/0/47 monet (careful/average/clumsy), złamań 0/1/2; naprawa liczy się od ceny, więc tańsze narzędzia tańsze też w serwisie.
6. **Czas gry:** ścieżka zleceń (C, bez grindu, bo go nie ma) trwa careful/average/clumsy 63/49/39 min. Do 2 h potrzeba więcej zleceń (cel ≥ 60) lub powtórek, nie wyższych cen. Tryb Ciągły (sesja 8 min, start) daje 375/402/385 monet i pozostaje dodatkiem, nie warunkiem postępu.

## 2. Scenariusze i profile

| Scenariusz | Opis |
|---|---|
| A | data as is, old curve (JSON families, tier coef 0.55), tools gate jobs |
| B | JOBS.md families, old curve (coef 0.55), tools gate jobs |
| C | current data (D-62 prices), tools optional, coef 1.2 |
| D | before D-62 (frozen old prices), tools gate jobs, coef 1.2 |

| Profil | czas / bot p50 | wspólczynnik nauki | overset / stress na zamek | czysto | napiwek | skill (Ciągły) | P(złamanie) bazowe |
|---|---|---|---|---|---|---|---|
| careful | ×3.0 | → ×0.65 | 0.5 / 0.2 | 80% | 20% | 1.15 | 1.0% × tier/3 |
| average | ×2.4 | → ×0.6 | 2.0 / 1.0 | 55% | 10% | 1.0 | 4.0% × tier/3 |
| clumsy | ×2.0 | → ×0.6 | 5.0 / 3.0 | 25% | 3% | 0.85 | 8.0% × tier/3 |

## 3. Podsumowanie kariery (mediany)

| Scen. | Profil | zlecenia zablok. | dochód ze zleceń | dochód z grindu | sesje grindu | grind [h] | czas zleceń [min] | naprawy | narzędzia | złamania |
|---|---|---|---|---|---|---|---|---|---|---|
| A | careful | 2 / 29 | 2568 | 10718 | 22 | 3.1 | 55.1 | 37 | 1170 | 3 |
| A | average | 3 / 29 | 2206 | 12895 | 31 | 4.3 | 39.7 | 224 | 1170 | 15 |
| A | clumsy | 3 / 29 | 2079 | 10612 | 31 | 4.3 | 31.2 | 440 | 1170 | 28 |
| B | careful | 2 / 29 | 2561 | 10708 | 22 | 3.1 | 55.8 | 37 | 1350 | 3 |
| B | average | 3 / 29 | 2204 | 12888 | 31 | 4.3 | 40.2 | 224 | 1350 | 14 |
| B | clumsy | 3 / 29 | 2075 | 10610 | 31 | 4.3 | 31.6 | 442 | 1350 | 28 |
| C | careful | 0 / 29 | 2784 | 0 | 0 | 0.0 | 63.3 | 0 | 2320 | 0 |
| C | average | 0 / 29 | 2554 | 0 | 0 | 0.0 | 48.7 | 0 | 2320 | 1 |
| C | clumsy | 0 / 29 | 2402 | 0 | 0 | 0.0 | 38.7 | 47 | 2080 | 2 |
| D | careful | 0 / 29 | 2774 | 4252 | 7 | 1.0 | 61.5 | 5 | 6400 | 1 |
| D | average | 0 / 29 | 2555 | 4478 | 8 | 1.1 | 46.7 | 155 | 6400 | 6 |
| D | clumsy | 0 / 29 | 2385 | 5840 | 11 | 1.5 | 36.3 | 862 | 6400 | 18 |

Grind = sesje Trybu Ciągłego (8 min), które gracz musi rozegrać, zanim kupi narzędzie potrzebne do następnego zlecenia. Po 60 sesjach na jedno zlecenie liczymy je jako zablokowane i idziemy dalej.

## 4. Przebieg zlecenie po zleceniu (profil average)

### Scenariusz C

| # | zlecenie | rozdz. | rodzina T | czas [min] | zarobek | sesje grindu | monety po | stan |
|---|---|---|---|---|---|---|---|---|
| 1 | `grandma_broth` | 1 | warded T1 | 1.6 | 89 | 0 | 89 | ok |
| 2 | `cat_bathroom` | 1 | warded T1 | 1.5 | 71 | 0 | 149 | ok |
| 3 | `bike_interview` | 1 | combo T1 | 2.2 | 77 | 0 | 223 | ok |
| 4 | `student_dorm` | 1 | pin_tumbler T1 | 1.4 | 70 | 0 | 145 | ok |
| 5 | `kiosk_shutter` | 1 | wafer T1 | 1.5 | 95 | 0 | 232 | ok |
| 6 | `refuse_ex_partner` | 1 | pin_tumbler T2 | 1.0 | 0 | 0 | 117 | odmowa/bez zamka |
| 7 | `newlyweds_4am` | 2 | pin_tumbler T2 | 1.6 | 177 | 0 | 282 | ok |
| 8 | `pizzeria_pays_pizza` | 2 | lever T1 | 1.5 | 0 | 0 | 150 | ok |
| 9 | `night_nurse` | 2 | magnetic T1 | 1.9 | 106 | 0 | 246 | ok |
| 10 | `wrong_floor` | 2 | pin_tumbler T1 | 1.0 | 20 | 0 | 86 | odmowa/bez zamka |
| 11 | `refuse_rush_bribe` | 2 | pin_tumbler T2 | 1.0 | 0 | 0 | 86 | odmowa/bez zamka |
| 12 | `drummer_locker` | 2 | tubular T1 | 1.8 | 130 | 0 | 208 | ok |
| 13 | `grandpa_chest` | 3 | warded T3 | 1.6 | 140 | 0 | 356 | ok |
| 14 | `uncle_safe_heirs` | 3 | dial_safe T2 | 2.3 | 120 | 0 | 295 | ok |
| 15 | `dollhouse_wooden_lock` | 3 | egyptian T1 | 1.7 | 59 | 0 | 232 | ok |
| 16 | `allotment_shed` | 3 | wafer T2 | 1.6 | 100 | 0 | 328 | ok |
| 17 | `widow_bureau` | 3 | lever T2 | 1.7 | 112 | 0 | 428 | ok |
| 18 | `refuse_aunt_alive` | 3 | lever T2 | 1.0 | 90 | 0 | 187 | odmowa/bez zamka |
| 19 | `krakow_tenement_gate` | 4 | warded T3 | 1.6 | 189 | 0 | 347 | ok |
| 20 | `swiatniki_journeyman_padlock` | 4 | warded T3 | 1.5 | 0 | 0 | 66 | ok |
| 21 | `krakow_antiquarian` | 4 | dial_safe T1 | 1.8 | 142 | 0 | 201 | ok |
| 22 | `brussels_townhouse` | 5 | dimple T2 | 2.2 | 124 | 0 | 291 | ok |
| 23 | `ghent_beguinage` | 5 | warded T2 | 1.5 | 118 | 0 | 398 | ok |
| 24 | `liege_bakery` | 5 | lever_detector T2 | 2.0 | 130 | 0 | 538 | ok |
| 25 | `charleroi_letters` | 5 | wafer T2 | 1.6 | 0 | 0 | 196 | ok |
| 26 | `museum_time_lock` | 6 | time_lock T2 | 2.1 | 177 | 0 | 311 | ok |
| 27 | `bramah_bureau` | 6 | axial_slider T2 | 2.1 | 165 | 0 | 316 | ok |
| 28 | `finnish_sailor` | 6 | disc_detainer T2 | 2.1 | 160 | 0 | 274 | ok |
| 29 | `time_capsule` | 6 | combo T3 | 2.2 | 0 | 0 | 219 | ok |

### Scenariusz D

| # | zlecenie | rozdz. | rodzina T | czas [min] | zarobek | sesje grindu | monety po | stan |
|---|---|---|---|---|---|---|---|---|
| 1 | `grandma_broth` | 1 | warded T1 | 1.6 | 89 | 0 | 89 | ok |
| 2 | `cat_bathroom` | 1 | warded T1 | 1.5 | 71 | 0 | 149 | ok |
| 3 | `bike_interview` | 1 | combo T1 | 2.0 | 77 | 1 | 448 | ok |
| 4 | `student_dorm` | 1 | pin_tumbler T1 | 1.3 | 83 | 0 | 524 | ok |
| 5 | `kiosk_shutter` | 1 | wafer T1 | 1.3 | 95 | 0 | 612 | ok |
| 6 | `refuse_ex_partner` | 1 | pin_tumbler T2 | 1.0 | 0 | 0 | 312 | odmowa/bez zamka |
| 7 | `newlyweds_4am` | 2 | pin_tumbler T2 | 1.4 | 177 | 0 | 476 | ok |
| 8 | `pizzeria_pays_pizza` | 2 | lever T1 | 1.5 | 0 | 0 | 470 | ok |
| 9 | `night_nurse` | 2 | magnetic T1 | 1.8 | 106 | 1 | 478 | ok |
| 10 | `wrong_floor` | 2 | pin_tumbler T1 | 1.0 | 20 | 0 | 487 | odmowa/bez zamka |
| 11 | `refuse_rush_bribe` | 2 | pin_tumbler T2 | 1.0 | 0 | 0 | 458 | odmowa/bez zamka |
| 12 | `drummer_locker` | 2 | tubular T1 | 1.8 | 130 | 1 | 595 | ok |
| 13 | `grandpa_chest` | 3 | warded T3 | 1.6 | 165 | 0 | 750 | ok |
| 14 | `uncle_safe_heirs` | 3 | dial_safe T2 | 2.1 | 120 | 1 | 510 | ok |
| 15 | `dollhouse_wooden_lock` | 3 | egyptian T1 | 1.6 | 59 | 0 | 560 | ok |
| 16 | `allotment_shed` | 3 | wafer T2 | 1.4 | 100 | 0 | 655 | ok |
| 17 | `widow_bureau` | 3 | lever T2 | 1.4 | 95 | 0 | 742 | ok |
| 18 | `refuse_aunt_alive` | 3 | lever T2 | 1.0 | 90 | 0 | 832 | odmowa/bez zamka |
| 19 | `krakow_tenement_gate` | 4 | warded T3 | 1.5 | 189 | 0 | 1001 | ok |
| 20 | `swiatniki_journeyman_padlock` | 4 | warded T3 | 1.5 | 0 | 0 | 536 | ok |
| 21 | `krakow_antiquarian` | 4 | dial_safe T1 | 1.7 | 142 | 0 | 656 | ok |
| 22 | `brussels_townhouse` | 5 | dimple T2 | 2.1 | 105 | 1 | 414 | ok |
| 23 | `ghent_beguinage` | 5 | warded T2 | 1.5 | 109 | 0 | 530 | ok |
| 24 | `liege_bakery` | 5 | lever_detector T2 | 2.0 | 154 | 0 | 674 | ok |
| 25 | `charleroi_letters` | 5 | wafer T2 | 1.4 | 0 | 0 | 571 | ok |
| 26 | `museum_time_lock` | 6 | time_lock T2 | 2.1 | 177 | 0 | 734 | ok |
| 27 | `bramah_bureau` | 6 | axial_slider T2 | 2.1 | 152 | 1 | 452 | ok |
| 28 | `finnish_sailor` | 6 | disc_detainer T2 | 2.1 | 160 | 2 | 429 | ok |
| 29 | `time_capsule` | 6 | combo T3 | 2.0 | 0 | 0 | 426 | ok |

## 5. Krzywa odblokowań (narzędzie kupione po zleceniu nr, mediana; — = nigdy)

| narzędzie | cena przed D-62 / dane (C) | warunek | B:car | B:ave | B:clu | C:car | C:ave | C:clu | D:car | D:ave | D:clu |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `tw_bar` | 450 / 150 | after_tier4 | 19 | 19 | 19 | 17 | 17 | 17 | 19 | 19 | 19 |
| `tl_shackle` | 150 / 60 | after_first_t2 | 3 | 3 | 3 | 3 | 3 | 3 | 3 | 3 | 3 |
| `pk_ripple` | 350 / 110 | after_5_locks_t2 | — | — | — | 13 | 13 | 13 | — | — | — |
| `pk_wedge` | 700 / 200 | after_t3 | — | — | — | 12 | 14 | 14 | — | — | — |
| `pk_lever` | 300 / 120 | after_t2 | 5 | 5 | 5 | 4 | 5 | 5 | 5 | 5 | 5 |
| `pk_crown` | 600 / 180 | after_t3 | 9 | 9 | 9 | 9 | 9 | 9 | 12 | 12 | 12 |
| `tl_polar` | 700 / 200 | after_t4 | — | — | — | 17 | 17 | 18 | 9 | 9 | 9 |
| `pk_flag` | 900 / 240 | after_t5 | — | — | — | 24 | 27 | — | 22 | 22 | 22 |
| `pk_plunger` | 1000 / 260 | after_t5 | 24 | 24 | 24 | 24 | 24 | 24 | 26 | 27 | 24 |
| `pk_disc` | 1100 / 280 | after_t5 | 25 | 25 | 25 | 26 | 26 | 26 | 28 | 28 | 25 |
| `pk_feather` | 2000 / 500 | after_t7_F3 | — | — | — | — | — | — | — | — | — |
| `tl_cup` | 1200 / 300 | after_t4 | 14 | 18 | 18 | 18 | 19 | 21 | 14 | 14 | 14 |
| `ob_microscope` | 250 / 90 | after_t2 | — | — | — | 3 | 3 | 3 | — | — | — |
| `ob_borescope` | 400 / 130 | after_t3 | — | — | — | 7 | 7 | 7 | — | — | — |

Krzywa (average): liczba posiadanych narzędzi płatnych po każdym zleceniu, mediana.

```
B   1  1  2  2  3  3  3  3  4  4  4  4  4  4  4  4  4  5  6  6  6  6  6  7  8  9  9  9  9
C   1  1  3  3  4  4  5  5  6  6  6  6  7  8  8  8 10 10 11 11 11 11 11 12 12 14 15 15 15
D   1  1  2  2  3  3  3  3  4  4  4  5  5  6  6  6  6  6  7  7  7  8  8  8  8  9 10 11 11
    1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29   <- zlecenie nr
```

### Krzywa trudności Trybu Ciągłego: wzór a tabela (§2.2 PROGRESSION)

| zamek n | tabela §2.2 | wzór 0,55 (skill 1,0) | wzór 0,55 (skill 1,25) | wzór 1,2 (skill 1,0) |
|---|---|---|---|---|
| 3 | 1–2 | 1.76 | 1.95 | 2.66 |
| 8 | 2–3 | 2.21 | 2.51 | 3.64 |
| 15 | 3–4 | 2.52 | 2.91 | 4.33 |
| 25 | 4–5 | 2.79 | 3.24 | 4.91 |
| 40 | 5–6 | 3.04 | 3.55 | 5.46 |

| Scen. | Profil | monety / sesja 8 min (start: narzędzia startowe) | max tier w sesji |
|---|---|---|---|
| B | careful | 270 | 2 |
| B | average | 280 | 2 |
| B | clumsy | 270 | 2 |
| C | careful | 375 | 4 |
| C | average | 402 | 4 |
| C | clumsy | 385 | 3 |
| D | careful | 365 | 4 |
| D | average | 395 | 4 |
| D | clumsy | 375 | 3 |

`progression.json` zakłada 385 monet na sesję i ok. 40 na zamek w środku serii.

## 6. Ceny narzędzi: przed i po D-62 (zastosowane w `game/data/tools.json`)

| narzędzie | przed | po | warunek |
|---|---|---|---|
| `tl_shackle` | 150 | 60 | `after_first_t2` |
| `pk_lever` | 300 | 120 | `after_t2` |
| `tw_bar` | 450 | 150 | `after_tier4` |
| `pk_crown` | 600 | 180 | `after_t3` |
| `tl_polar` | 700 | 200 | `after_t4` |
| `pk_flag` | 900 | 240 | `after_t5` |
| `pk_plunger` | 1000 | 260 | `after_t5` |
| `pk_disc` | 1100 | 280 | `after_t5` |
| `tl_cup` | 1200 | 300 | `after_t4` |
| `pk_ripple` | 350 | 110 | `after_5_locks_t2` |
| `pk_wedge` | 700 | 200 | `after_t3` |
| `pk_feather` | 2000 | 500 | `after_t7_F3` |
| `ob_microscope` | 250 | 90 | `after_t2` |
| `ob_borescope` | 400 | 130 | `after_t3` |
| `tl_drill` | 1000 | 300 | `jobs_mode_only` |

Warunki odblokowania bez zmian (tylko pacing sklepu; zlecenie nigdy nie wymaga narzędzia). Naprawa: 15 % ceny (złamane: 15 % + 10, maks. 150), więc spada razem z cenami.

## 7. Model i założenia

- Kolejność zleceń jak w `docs/JOBS.md`. Odmowy (`refuse_*`) i `wrong_floor` grane najlepszą ścieżką, bez zamka.
- Rodzina i tier zlecenia → lockcore: wkładka T1/T2/T3 → t2/t3/t4, płytkowy → t1/t2/t3, zapadkowy → t1/t2/t2 (lockcore nie ma t3), dźwigniowy → t3/t4/t5, z detektorem → t5, szyfrowa → `ring_combo` t2/t2/t3, egipski → `wooden_pin` t1.
- Rodziny bez modułu lockcore (magnetic, tubular, dial_safe, time_lock, dimple, axial_slider, disc_detainer): czas bota szacowany 20/26/34 s dla T1/T2/T3, niezdarny 95 % sukcesu.
- Czas gracza = p50 bota czującego × współczynnik profilu × nauka (od ×1 do ×asymptota, stała 3 zamki rodziny) × szum 0,8–1,25, plus scena zlecenia (dialog, dowody, wycena) 45–80 s.
- Zużycie wg `TOOLS.md` §2: kontakt pod napięciem (max −2), overset −1, stress −2, detektor −1/−3. Złamanie: I → 0, czas ×1,5, naprawa 35 % ceny; zużyte poniżej progu profilu: 15 % ceny (min. 5).
- P(złamanie) = bazowe × tier/3 (+ porażki bota niezdarnego dla profilu clumsy) × do +43 % przy I = 0.
- Warunki `after_tN` = gracz otworzył zamek lockcore tieru ≥ N w dowolnym trybie. `tw_bar` podnosi tier_max Trybu Ciągłego z 5 do 7. `kit_clock` (wydarzenie F2) przyjęty jako nagroda rozdziału 6.
- Napiwek tylko przy otwarciu czystym; oczekiwana wartość = udział profilu × nagroda.
- Scenariusz C (D-62): narzędzia opcjonalne. Gracz kupuje, co pozwalają monety (zlecenia z wyprzedzeniem 3, potem wszystko odblokowane od najtańszego, z rezerwą 50 monet na naprawy); zamek rodziny bez jej narzędzia trwa ×1.15; brak grindu i blokad.
- To model, nie pomiar: liczby profili trzeba zastąpić danymi z playtestów (telemetria czasu i zdarzeń `wear`).
