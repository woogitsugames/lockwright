# Ekonomia kariery — symulacja (tools/econ_sim.py)

Wygenerowane przez `python3 tools/econ_sim.py` (200 karier na profil i scenariusz, seed deterministyczny). Dane wejściowe: `game/data/jobs/*.json`, `game/data/tools.json`, `game/data/progression.json`, `lockcore/BALANCE.md`, `docs/JOBS.md`. Scenariusz C = dane gry bez zmian (ceny D-62); D = zamrożone ceny sprzed D-62 z narzędziem jako bramką zlecenia; A i B to diagnostyka starej krzywej.

## 1. Wnioski w skrócie

1. **D-62: tańsze narzędzia, nigdy blokada zlecenia.** Ceny w `tools.json` (C) spadły z 10100 do 2820 monet za wszystkie 14 płatne narzędzia, a z 6400 do 1790 za te, które mają użycie w zleceniach (9 szt.). Suma nagród 59 zleceń to 5773 monet, plus napiwki. Gra nie sprawdza narzędzi przy przyjęciu zlecenia; model C też nie: brak narzędzia daje wolniejszy zamek (×1.15) i słabszy feedback, ale nie grind.
2. **Przed (D, stare ceny, narzędzie bramką):** zablokowanych zleceń careful/average/clumsy 0/0/0; sesji grindu 7/8/11; dochód ze zleceń 6875/6313/5901 + grind 4252/4478/5840 monet wobec 6400/6400/6400 wydanych na narzędzia.
3. **Po (C, nowe ceny, narzędzia opcjonalne):** zablokowanych 0/0/0; sesji grindu 0/0/0; dochód ze zleceń 6876/6318/5920 monet, wydane na narzędzia 2320/2320/2320 (kupione: 13/13/13 z 13 osiągalnych płatnych); monety niewydane na koniec kariery 4541/3940/3402; zamków granych bez własnego narzędzia 4/4/5.
4. **Dochód a koszt narzędzi (C):** dochód ze zleceń / łączny koszt wszystkich płatnych narzędzi (2820) = 244%/224%/210% (careful/average/clumsy); wobec stanu sprzed D-62: 68%/63%/58%.
5. **Naprawy (C):** 0/47/219 monet (careful/average/clumsy), złamań 0/2/5; naprawa liczy się od ceny, więc tańsze narzędzia tańsze też w serwisie.
6. **Czas gry:** ścieżka zleceń (C, bez grindu, bo go nie ma) trwa careful/average/clumsy 131/101/80 min. Do 2 h potrzeba więcej zleceń (cel ≥ 60) lub powtórek, nie wyższych cen. Tryb Ciągły (sesja 8 min, start) daje 375/402/385 monet i pozostaje dodatkiem, nie warunkiem postępu.

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
| A | careful | 2 / 59 | 6661 | 10718 | 22 | 3.1 | 120.8 | 51 | 1610 | 3 |
| A | average | 3 / 59 | 5964 | 12895 | 31 | 4.3 | 89.7 | 308 | 1610 | 16 |
| A | clumsy | 3 / 59 | 5593 | 10612 | 31 | 4.3 | 71.4 | 646 | 1610 | 32 |
| B | careful | 2 / 59 | 6658 | 10708 | 22 | 3.1 | 123.4 | 51 | 1790 | 3 |
| B | average | 3 / 59 | 5956 | 12888 | 31 | 4.3 | 92.2 | 288 | 1790 | 15 |
| B | clumsy | 3 / 59 | 5595 | 10610 | 31 | 4.3 | 73.1 | 600 | 1790 | 31 |
| C | careful | 0 / 59 | 6876 | 0 | 0 | 0.0 | 131.0 | 0 | 2320 | 0 |
| C | average | 0 / 59 | 6318 | 0 | 0 | 0.0 | 100.6 | 47 | 2320 | 2 |
| C | clumsy | 0 / 59 | 5920 | 0 | 0 | 0.0 | 80.2 | 219 | 2320 | 5 |
| D | careful | 0 / 59 | 6875 | 4252 | 7 | 1.0 | 128.4 | 50 | 6400 | 1 |
| D | average | 0 / 59 | 6313 | 4478 | 8 | 1.1 | 98.1 | 314 | 6400 | 7 |
| D | clumsy | 0 / 59 | 5901 | 5840 | 11 | 1.5 | 77.2 | 1396 | 6400 | 21 |

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
| 30 | `t43_09_01_winter_keys` | 9 | pin_tumbler T2 | 1.4 | 40 | 0 | 264 | ok |
| 31 | `t43_09_02_blanket_cupboard` | 9 | magnetic T2 | 2.0 | 59 | 0 | 314 | ok |
| 32 | `t43_09_03_wooden_postbox` | 9 | egyptian T2 | 2.1 | 71 | 0 | 380 | ok |
| 33 | `t43_09_04_choir_case` | 9 | combo T2 | 2.1 | 83 | 0 | 458 | ok |
| 34 | `t43_09_05_receipt_safe` | 9 | dial_safe T2 | 1.9 | 95 | 0 | 542 | ok |
| 35 | `t43_09_06_draughty_hall` | 9 | dimple T2 | 1.9 | 106 | 0 | 640 | ok |
| 36 | `refuse_t43_09_empty_flat` | 9 | pin_tumbler T3 | 1.0 | 0 | 0 | 640 | odmowa/bez zamka |
| 37 | `t43_09_08_spare_key_hook` | 9 | pin_tumbler T2 | 1.0 | 40 | 0 | 680 | odmowa/bez zamka |
| 38 | `t43_10_01_renovator_bureau` | 10 | axial_slider T2 | 2.0 | 118 | 0 | 787 | ok |
| 39 | `t43_10_02_scaffold_store` | 10 | disc_detainer T2 | 2.0 | 130 | 0 | 904 | ok |
| 40 | `t43_10_03_exhibit_clock` | 10 | time_lock T2 | 2.0 | 142 | 0 | 1038 | ok |
| 41 | `t43_10_04_design_cabinet` | 10 | magnetic T2 | 1.9 | 154 | 0 | 1182 | ok |
| 42 | `t43_10_05_porters_drawer` | 10 | lever T3 | 1.4 | 165 | 0 | 1334 | ok |
| 43 | `t43_10_06_shared_room_entry` | 10 | dimple T3 | 2.1 | 177 | 0 | 1495 | ok |
| 44 | `refuse_t43_10_early_clearance` | 10 | lever T3 | 1.0 | 0 | 0 | 1495 | odmowa/bez zamka |
| 45 | `t43_11_01_wooden_market` | 11 | egyptian T2 | 2.0 | 177 | 0 | 1656 | ok |
| 46 | `t43_11_02_bicycle_stand` | 11 | combo T3 | 2.2 | 189 | 0 | 1834 | ok |
| 47 | `t43_11_03_tool_exchange` | 11 | axial_slider T3 | 2.1 | 186 | 0 | 2020 | ok |
| 48 | `t43_11_04_sailors_stall` | 11 | disc_detainer T3 | 2.1 | 213 | 0 | 2216 | ok |
| 49 | `t43_11_05_rehearsal_chest` | 11 | lever T4 | 1.5 | 219 | 0 | 2418 | ok |
| 50 | `refuse_t43_11_other_stall` | 11 | wafer T3 | 1.0 | 0 | 0 | 2418 | odmowa/bez zamka |
| 51 | `t43_11_07_wrong_delivery` | 11 | pin_tumbler T3 | 1.0 | 40 | 0 | 2458 | odmowa/bez zamka |
| 52 | `t43_12_01_letters_archive` | 12 | dial_safe T3 | 2.1 | 219 | 0 | 2657 | ok |
| 53 | `t43_12_02_detective_cabinet` | 12 | lever_detector T5 | 1.8 | 225 | 0 | 2859 | ok |
| 54 | `t43_12_03_community_store` | 12 | pin_tumbler T5 | 1.7 | 230 | 0 | 3078 | ok |
| 55 | `t43_12_04_school_box` | 12 | lever T5 | 1.7 | 234 | 0 | 3284 | ok |
| 56 | `t43_12_05_tea_fund_case` | 12 | combo T4 | 2.3 | 200 | 0 | 3507 | ok |
| 57 | `refuse_t43_12_surprise_key` | 12 | pin_tumbler T6 | 1.0 | 0 | 0 | 3507 | odmowa/bez zamka |
| 58 | `t43_12_07_clock_back_home` | 12 | time_lock T2 | 1.9 | 236 | 0 | 3724 | ok |
| 59 | `t43_12_08_henryks_bench` | 12 | pin_tumbler T6 | 1.7 | 218 | 0 | 3940 | ok |

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
| 30 | `t43_09_01_winter_keys` | 9 | pin_tumbler T2 | 1.3 | 47 | 0 | 468 | ok |
| 31 | `t43_09_02_blanket_cupboard` | 9 | magnetic T2 | 2.0 | 59 | 0 | 524 | ok |
| 32 | `t43_09_03_wooden_postbox` | 9 | egyptian T2 | 2.1 | 71 | 0 | 588 | ok |
| 33 | `t43_09_04_choir_case` | 9 | combo T2 | 2.1 | 83 | 0 | 665 | ok |
| 34 | `t43_09_05_receipt_safe` | 9 | dial_safe T2 | 1.9 | 95 | 0 | 726 | ok |
| 35 | `t43_09_06_draughty_hall` | 9 | dimple T2 | 2.0 | 106 | 0 | 822 | ok |
| 36 | `refuse_t43_09_empty_flat` | 9 | pin_tumbler T3 | 1.0 | 0 | 0 | 822 | odmowa/bez zamka |
| 37 | `t43_09_08_spare_key_hook` | 9 | pin_tumbler T2 | 1.0 | 40 | 0 | 862 | odmowa/bez zamka |
| 38 | `t43_10_01_renovator_bureau` | 10 | axial_slider T2 | 1.9 | 118 | 0 | 972 | ok |
| 39 | `t43_10_02_scaffold_store` | 10 | disc_detainer T2 | 2.0 | 130 | 0 | 1070 | ok |
| 40 | `t43_10_03_exhibit_clock` | 10 | time_lock T2 | 1.9 | 142 | 0 | 1202 | ok |
| 41 | `t43_10_04_design_cabinet` | 10 | magnetic T2 | 1.9 | 154 | 0 | 1351 | ok |
| 42 | `t43_10_05_porters_drawer` | 10 | lever T3 | 1.3 | 165 | 0 | 1496 | ok |
| 43 | `t43_10_06_shared_room_entry` | 10 | dimple T3 | 2.1 | 177 | 0 | 1652 | ok |
| 44 | `refuse_t43_10_early_clearance` | 10 | lever T3 | 1.0 | 0 | 0 | 1652 | odmowa/bez zamka |
| 45 | `t43_11_01_wooden_market` | 11 | egyptian T2 | 1.9 | 177 | 0 | 1822 | ok |
| 46 | `t43_11_02_bicycle_stand` | 11 | combo T3 | 2.3 | 189 | 0 | 1990 | ok |
| 47 | `t43_11_03_tool_exchange` | 11 | axial_slider T3 | 2.1 | 170 | 0 | 2157 | ok |
| 48 | `t43_11_04_sailors_stall` | 11 | disc_detainer T3 | 2.1 | 213 | 0 | 2341 | ok |
| 49 | `t43_11_05_rehearsal_chest` | 11 | lever T4 | 1.4 | 185 | 0 | 2526 | ok |
| 50 | `refuse_t43_11_other_stall` | 11 | wafer T3 | 1.0 | 0 | 0 | 2526 | odmowa/bez zamka |
| 51 | `t43_11_07_wrong_delivery` | 11 | pin_tumbler T3 | 1.0 | 40 | 0 | 2566 | odmowa/bez zamka |
| 52 | `t43_12_01_letters_archive` | 12 | dial_safe T3 | 2.0 | 219 | 0 | 2735 | ok |
| 53 | `t43_12_02_detective_cabinet` | 12 | lever_detector T5 | 1.9 | 225 | 0 | 2934 | ok |
| 54 | `t43_12_03_community_store` | 12 | pin_tumbler T5 | 1.6 | 230 | 0 | 3144 | ok |
| 55 | `t43_12_04_school_box` | 12 | lever T5 | 1.6 | 198 | 0 | 3360 | ok |
| 56 | `t43_12_05_tea_fund_case` | 12 | combo T4 | 2.3 | 200 | 0 | 3564 | ok |
| 57 | `refuse_t43_12_surprise_key` | 12 | pin_tumbler T6 | 1.0 | 0 | 0 | 3564 | odmowa/bez zamka |
| 58 | `t43_12_07_clock_back_home` | 12 | time_lock T2 | 1.9 | 236 | 0 | 3780 | ok |
| 59 | `t43_12_08_henryks_bench` | 12 | pin_tumbler T6 | 1.6 | 200 | 0 | 3996 | ok |

## 5. Krzywa odblokowań (narzędzie kupione po zleceniu nr, mediana; — = nigdy)

| narzędzie | cena przed D-62 / dane (C) | warunek | B:car | B:ave | B:clu | C:car | C:ave | C:clu | D:car | D:ave | D:clu |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `tw_bar` | 450 / 150 | after_tier4 | 19 | 19 | 19 | 17 | 17 | 17 | 19 | 19 | 19 |
| `tl_shackle` | 150 / 60 | after_first_t2 | 3 | 3 | 3 | 3 | 3 | 3 | 3 | 3 | 3 |
| `pk_ripple` | 350 / 110 | after_5_locks_t2 | — | — | — | 13 | 13 | 13 | — | — | — |
| `pk_wedge` | 700 / 200 | after_t3 | — | — | — | 12 | 14 | 14 | — | — | — |
| `pk_lever` | 300 / 120 | after_t2 | 5 | 5 | 5 | 4 | 5 | 5 | 5 | 5 | 5 |
| `pk_crown` | 600 / 180 | after_t3 | 9 | 9 | 9 | 9 | 9 | 9 | 12 | 12 | 12 |
| `tl_polar` | 700 / 200 | after_t4 | 28 | 28 | 28 | 17 | 17 | 18 | 9 | 9 | 9 |
| `pk_flag` | 900 / 240 | after_t5 | 32 | 32 | 32 | 24 | 27 | 30 | 22 | 22 | 22 |
| `pk_plunger` | 1000 / 260 | after_t5 | 24 | 24 | 24 | 24 | 24 | 24 | 26 | 27 | 24 |
| `pk_disc` | 1100 / 280 | after_t5 | 25 | 25 | 25 | 26 | 26 | 26 | 28 | 28 | 25 |
| `pk_feather` | 2000 / 500 | after_t7_F3 | — | — | — | — | — | — | — | — | — |
| `tl_cup` | 1200 / 300 | after_t4 | 14 | 18 | 18 | 18 | 19 | 21 | 14 | 14 | 14 |
| `ob_microscope` | 250 / 90 | after_t2 | — | — | — | 3 | 3 | 3 | — | — | — |
| `ob_borescope` | 400 / 130 | after_t3 | — | — | — | 7 | 7 | 7 | — | — | — |

Krzywa (average): liczba posiadanych narzędzi płatnych po każdym zleceniu, mediana.

```
B   1  1  2  2  3  3  3  3  4  4  4  4  4  4  4  4  4  5  6  6  6  6  6  7  8  9  9 10 10
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
