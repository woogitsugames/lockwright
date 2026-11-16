# Ekonomia kariery — symulacja (tools/econ_sim.py)

Wygenerowane przez `python3 tools/econ_sim.py` (200 karier na profil i scenariusz, seed deterministyczny). Dane wejściowe: `game/data/jobs/*.json` i `game/packs/<id>/jobs/*.json` (rozdziały 13+ w paczkach do pobrania, D-131), `game/data/tools.json`, `game/data/progression.json`, `lockcore/BALANCE.md`, `docs/JOBS.md`. Scenariusz C = dane gry bez zmian (ceny D-62); D = zamrożone ceny sprzed D-62 z narzędziem jako bramką zlecenia; A i B to diagnostyka starej krzywej.

## 1. Wnioski w skrócie

1. **D-62: tańsze narzędzia, nigdy blokada zlecenia.** Ceny w `tools.json` (C) spadły z 10100 do 2820 monet za wszystkie 14 płatne narzędzia, a z 6400 do 1790 za te, które mają użycie w zleceniach (9 szt.). Suma nagród 123 zleceń to 14103 monet, plus napiwki. Gra nie sprawdza narzędzi przy przyjęciu zlecenia; model C też nie: brak narzędzia daje wolniejszy zamek (×1.15) i słabszy feedback, ale nie grind.
2. **Przed (D, stare ceny, narzędzie bramką):** zablokowanych zleceń careful/average/clumsy 0/0/0; sesji grindu 7/8/12; dochód ze zleceń 16850/15432/14432 + grind 4230/4498/5910 monet wobec 6400/6400/6400 wydanych na narzędzia.
3. **Po (C, nowe ceny, narzędzia opcjonalne):** zablokowanych 0/0/0; sesji grindu 0/0/0; dochód ze zleceń 16855/15417/14462 monet, wydane na narzędzia 2320/2320/2320 (kupione: 13/13/13 z 13 osiągalnych płatnych); monety niewydane na koniec kariery 2936/1392/764; zamków granych bez własnego narzędzia 3/3/4.
4. **Dochód a koszt narzędzi (C):** dochód ze zleceń / łączny koszt wszystkich płatnych narzędzi (2820) = 598%/547%/513% (careful/average/clumsy); wobec stanu sprzed D-62: 167%/153%/143%.
5. **Naprawy (C):** 28/172/552 monet (careful/average/clumsy), złamań 1/4/12; naprawa liczy się od ceny, więc tańsze narzędzia tańsze też w serwisie.
6. **Czas gry:** ścieżka zleceń (C, bez grindu, bo go nie ma) trwa careful/average/clumsy 262/200/159 min (123 zleceń, rozdz. 1–16; do końca rozdz. 12: 176/135/107 min przy celu D-71 ok. 2 h dla average). Długość regulujemy liczbą zleceń, nie cenami. Tryb Ciągły (sesja 8 min, start) daje 375/402/385 monet i pozostaje dodatkiem, nie warunkiem postępu.
7. **Wyposażenie (D-71, D-127):** 15 przedmiotów kosmetycznych za 11550 monet; careful/average/clumsy kupują 10/9/9 z 10 dostępnych do końca rozdz. 12 (zostaje im 628/1344/636 monet) i 15/15/14 z 15 do końca rozdz. 16, wydają 11550/11550/10750 (sekcja 6a).
8. **Monety po rozdz. 12 mają cel (D-127):** 5 przedmiotów za 4800 monet odblokowują rozdz. 13–15; ostatni zakup wypada po zleceniu nr 109/116/— z 123 (— = mediana: coś zostaje do kupienia po ostatnim zleceniu), a na koniec rozdz. 16 zostaje 2936/1392/764 monet (careful/average/clumsy). Przebieg rozdział po rozdziale: sekcja 6b.
9. **Czeka na grafikę (D-127):** 5 z 15 przedmiotów nie ma jeszcze nakładki w `game/assets/ui/workshop/` (`enamel_mugs`, `neighbours_photo`, `postcards`, `key_cabinet`, `exam_lock`); gra nie pokazuje ich w sklepie, dopóki plik nie dojdzie (`docs/handoff/LOCAL-GPU-TASKS.md`). Liczby w tym raporcie opisują stan docelowy, z kompletem przedmiotów.

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
| A | careful | 0 / 123 | 16859 | 0 | 0 | 0.0 | 263.6 | 28 | 1610 | 1 |
| A | average | 0 / 123 | 15418 | 0 | 0 | 0.0 | 200.9 | 239 | 1610 | 4 |
| A | clumsy | 0 / 123 | 14440 | 0 | 0 | 0.0 | 161.4 | 844 | 1610 | 16 |
| B | careful | 2 / 123 | 16630 | 10735 | 22 | 3.1 | 254.4 | 83 | 1790 | 4 |
| B | average | 3 / 123 | 15098 | 12478 | 30 | 4.2 | 191.5 | 376 | 1790 | 17 |
| B | clumsy | 3 / 123 | 14144 | 10248 | 30 | 4.1 | 152.2 | 962 | 1790 | 37 |
| C | careful | 0 / 123 | 16855 | 0 | 0 | 0.0 | 262.2 | 28 | 2320 | 1 |
| C | average | 0 / 123 | 15417 | 0 | 0 | 0.0 | 199.9 | 172 | 2320 | 4 |
| C | clumsy | 0 / 123 | 14462 | 0 | 0 | 0.0 | 159.1 | 552 | 2320 | 12 |
| D | careful | 0 / 123 | 16850 | 4230 | 7 | 1.0 | 259.9 | 100 | 6400 | 2 |
| D | average | 0 / 123 | 15432 | 4498 | 8 | 1.1 | 197.3 | 733 | 6400 | 9 |
| D | clumsy | 0 / 123 | 14432 | 5910 | 12 | 1.6 | 155.9 | 2580 | 6400 | 27 |

Grind = sesje Trybu Ciągłego (8 min), które gracz musi rozegrać, zanim kupi narzędzie potrzebne do następnego zlecenia. Po 60 sesjach na jedno zlecenie liczymy je jako zablokowane i idziemy dalej.

## 4. Przebieg zlecenie po zleceniu (profil average)

### Scenariusz C

| # | zlecenie | rozdz. | rodzina T | czas [min] | zarobek | sesje grindu | monety po | stan |
|---|---|---|---|---|---|---|---|---|
| 1 | `grandma_broth` | 1 | pin_tumbler T1 | 1.5 | 89 | 0 | 89 | ok |
| 2 | `cat_bathroom` | 1 | warded T1 | 1.6 | 71 | 0 | 149 | ok |
| 3 | `student_dorm` | 1 | pin_tumbler T1 | 1.4 | 83 | 0 | 169 | ok |
| 4 | `kiosk_shutter` | 1 | wafer T1 | 1.5 | 95 | 0 | 163 | ok |
| 5 | `bike_interview` | 1 | combo T1 | 2.0 | 77 | 0 | 215 | ok |
| 6 | `refuse_ex_partner` | 1 | pin_tumbler T2 | 1.0 | 0 | 0 | 118 | odmowa/bez zamka |
| 7 | `newlyweds_4am` | 2 | pin_tumbler T2 | 1.5 | 177 | 0 | 282 | ok |
| 8 | `pizzeria_pays_pizza` | 2 | lever T1 | 1.5 | 0 | 0 | 152 | ok |
| 9 | `night_nurse` | 2 | magnetic T1 | 1.9 | 98 | 0 | 244 | ok |
| 10 | `wrong_floor` | 2 | pin_tumbler T1 | 1.0 | 20 | 0 | 84 | odmowa/bez zamka |
| 11 | `refuse_rush_bribe` | 2 | pin_tumbler T2 | 1.0 | 0 | 0 | 84 | odmowa/bez zamka |
| 12 | `drummer_locker` | 2 | tubular T1 | 1.8 | 110 | 0 | 208 | ok |
| 13 | `grandpa_chest` | 3 | warded T3 | 1.7 | 165 | 0 | 254 | ok |
| 14 | `uncle_safe_heirs` | 3 | dial_safe T2 | 2.2 | 142 | 0 | 210 | ok |
| 15 | `dollhouse_wooden_lock` | 3 | egyptian T1 | 1.7 | 59 | 0 | 239 | ok |
| 16 | `allotment_shed` | 3 | wafer T2 | 1.6 | 100 | 0 | 194 | ok |
| 17 | `widow_bureau` | 3 | lever T2 | 1.7 | 112 | 0 | 282 | ok |
| 18 | `refuse_aunt_alive` | 3 | lever T2 | 1.0 | 90 | 0 | 224 | odmowa/bez zamka |
| 19 | `krakow_tenement_gate` | 4 | warded T3 | 1.6 | 189 | 0 | 370 | ok |
| 20 | `swiatniki_journeyman_padlock` | 4 | warded T3 | 1.6 | 0 | 0 | 98 | ok |
| 21 | `krakow_antiquarian` | 4 | dial_safe T1 | 1.8 | 142 | 0 | 226 | ok |
| 22 | `brussels_townhouse` | 5 | dimple T2 | 2.3 | 105 | 0 | 291 | ok |
| 23 | `ghent_beguinage` | 5 | warded T2 | 1.5 | 118 | 0 | 257 | ok |
| 24 | `liege_bakery` | 5 | lever_detector T2 | 2.0 | 130 | 0 | 392 | ok |
| 25 | `charleroi_letters` | 5 | wafer T2 | 1.6 | 0 | 0 | 133 | ok |
| 26 | `museum_time_lock` | 6 | time_lock T2 | 2.1 | 150 | 0 | 291 | ok |
| 27 | `bramah_bureau` | 6 | axial_slider T2 | 2.1 | 140 | 0 | 224 | ok |
| 28 | `finnish_sailor` | 6 | disc_detainer T2 | 2.0 | 135 | 0 | 304 | ok |
| 29 | `time_capsule` | 6 | combo T3 | 2.2 | 0 | 0 | 122 | ok |
| 30 | `halina_recipe_box` | 7 | warded T1 | 1.4 | 89 | 0 | 201 | ok |
| 31 | `roman_service_cupboard` | 7 | wafer T2 | 1.5 | 105 | 0 | 267 | ok |
| 32 | `marta_poster_studio` | 7 | pin_tumbler T2 | 1.3 | 124 | 0 | 368 | ok |
| 33 | `zuzanna_catalogue_drawer` | 7 | lever T3 | 1.4 | 105 | 0 | 240 | ok |
| 34 | `refuse_sisters_flat` | 7 | pin_tumbler T2 | 1.0 | 0 | 0 | 192 | odmowa/bez zamka |
| 35 | `stefan_book_tin` | 7 | combo T3 | 2.4 | 171 | 0 | 356 | ok |
| 36 | `edek_rehearsal_store` | 7 | lever T3 | 1.4 | 124 | 0 | 426 | ok |
| 37 | `krystyna_wooden_album` | 7 | egyptian T1 | 1.8 | 89 | 0 | 180 | ok |
| 38 | `refuse_unapproved_stockroom` | 7 | wafer T2 | 1.0 | 0 | 0 | 162 | odmowa/bez zamka |
| 39 | `gosia_workbench_drawer` | 7 | lever T3 | 1.4 | 171 | 0 | 323 | ok |
| 40 | `community_notice_case` | 7 | warded T2 | 1.5 | 124 | 0 | 433 | ok |
| 41 | `shared_room_door` | 7 | pin_tumbler T3 | 1.5 | 171 | 0 | 304 | ok |
| 42 | `frozen_cellar_padlock` | 8 | combo T2 | 2.0 | 100 | 0 | 342 | ok |
| 43 | `halina_christmas_tin` | 8 | warded T1 | 1.4 | 75 | 0 | 417 | ok |
| 44 | `carol_singers_chest` | 8 | egyptian T1 | 1.7 | 89 | 0 | 500 | ok |
| 45 | `refuse_wrong_letterbox` | 8 | wafer T1 | 1.0 | 0 | 0 | 498 | odmowa/bez zamka |
| 46 | `wigilia_table_drawer` | 8 | lever T3 | 1.4 | 171 | 0 | 657 | ok |
| 47 | `heating_service_cupboard` | 8 | pin_tumbler T3 | 1.4 | 171 | 0 | 312 | ok |
| 48 | `refuse_unapproved_repair` | 8 | wafer T2 | 1.0 | 0 | 0 | 220 | odmowa/bez zamka |
| 49 | `warm_room_for_neighbours` | 8 | pin_tumbler T3 | 1.4 | 171 | 0 | 376 | ok |
| 50 | `winter_bicycle_cellar` | 8 | combo T3 | 2.1 | 171 | 0 | 526 | ok |
| 51 | `wooden_winter_village` | 8 | egyptian T1 | 1.7 | 89 | 0 | 610 | ok |
| 52 | `attic_drying_room` | 8 | lever T3 | 1.3 | 171 | 0 | 764 | ok |
| 53 | `christmas_eve_heat` | 8 | lever_detector T5 | 1.9 | 210 | 0 | 962 | ok |
| 54 | `t43_09_01_winter_keys` | 9 | pin_tumbler T2 | 1.3 | 47 | 0 | 164 | ok |
| 55 | `t43_09_02_blanket_cupboard` | 9 | magnetic T2 | 2.0 | 59 | 0 | 217 | ok |
| 56 | `t43_09_03_wooden_postbox` | 9 | egyptian T2 | 1.8 | 71 | 0 | 282 | ok |
| 57 | `t43_09_04_choir_case` | 9 | combo T2 | 1.8 | 83 | 0 | 358 | ok |
| 58 | `t43_09_05_receipt_safe` | 9 | dial_safe T2 | 1.9 | 95 | 0 | 438 | ok |
| 59 | `t43_09_06_draughty_hall` | 9 | dimple T2 | 2.0 | 106 | 0 | 523 | ok |
| 60 | `refuse_t43_09_empty_flat` | 9 | pin_tumbler T3 | 1.0 | 0 | 0 | 132 | odmowa/bez zamka |
| 61 | `t43_09_08_spare_key_hook` | 9 | pin_tumbler T2 | 1.0 | 40 | 0 | 172 | odmowa/bez zamka |
| 62 | `t43_10_01_renovator_bureau` | 10 | axial_slider T2 | 2.0 | 118 | 0 | 254 | ok |
| 63 | `t43_10_02_scaffold_store` | 10 | disc_detainer T2 | 2.0 | 130 | 0 | 356 | ok |
| 64 | `t43_10_03_exhibit_clock` | 10 | time_lock T2 | 1.9 | 142 | 0 | 484 | ok |
| 65 | `t43_10_04_design_cabinet` | 10 | magnetic T2 | 1.9 | 154 | 0 | 628 | ok |
| 66 | `t43_10_05_porters_drawer` | 10 | lever T3 | 1.3 | 165 | 0 | 782 | ok |
| 67 | `t43_10_06_shared_room_entry` | 10 | dimple T3 | 2.2 | 177 | 0 | 924 | ok |
| 68 | `refuse_t43_10_early_clearance` | 10 | lever T3 | 1.0 | 0 | 0 | 186 | odmowa/bez zamka |
| 69 | `t43_11_01_wooden_market` | 11 | egyptian T2 | 1.8 | 177 | 0 | 356 | ok |
| 70 | `t43_11_02_bicycle_stand` | 11 | combo T3 | 2.0 | 189 | 0 | 457 | ok |
| 71 | `t43_11_03_tool_exchange` | 11 | axial_slider T3 | 2.2 | 201 | 0 | 634 | ok |
| 72 | `t43_11_04_sailors_stall` | 11 | disc_detainer T3 | 2.1 | 180 | 0 | 818 | ok |
| 73 | `t43_11_05_rehearsal_chest` | 11 | lever T4 | 1.5 | 219 | 0 | 1020 | ok |
| 74 | `refuse_t43_11_other_stall` | 11 | wafer T3 | 1.0 | 0 | 0 | 1020 | odmowa/bez zamka |
| 75 | `t43_11_07_wrong_delivery` | 11 | pin_tumbler T3 | 1.0 | 40 | 0 | 1060 | odmowa/bez zamka |
| 76 | `t43_12_01_letters_archive` | 12 | dial_safe T3 | 2.0 | 219 | 0 | 1257 | ok |
| 77 | `t43_12_02_detective_cabinet` | 12 | lever_detector T5 | 1.8 | 190 | 0 | 437 | ok |
| 78 | `t43_12_03_community_store` | 12 | pin_tumbler T5 | 1.6 | 230 | 0 | 488 | ok |
| 79 | `t43_12_04_school_box` | 12 | lever T5 | 1.6 | 198 | 0 | 690 | ok |
| 80 | `t43_12_05_tea_fund_case` | 12 | combo T4 | 2.1 | 200 | 0 | 907 | ok |
| 81 | `refuse_t43_12_surprise_key` | 12 | pin_tumbler T6 | 1.0 | 0 | 0 | 907 | odmowa/bez zamka |
| 82 | `t43_12_07_clock_back_home` | 12 | time_lock T2 | 1.9 | 236 | 0 | 1126 | ok |
| 83 | `t43_12_08_henryks_bench` | 12 | pin_tumbler T6 | 1.6 | 236 | 0 | 1346 | ok |
| 84 | `ch13_01_balcony_boxes` | 13 | warded T2 | 1.5 | 177 | 0 | 1501 | ok |
| 85 | `ch13_02_first_ice_cream` | 13 | wafer T2 | 1.5 | 183 | 0 | 378 | ok |
| 86 | `ch13_03_allotment_gate` | 13 | lever T3 | 1.3 | 189 | 0 | 516 | ok |
| 87 | `refuse_ch13_04_winter_bike` | 13 | combo T3 | 1.0 | 0 | 0 | 510 | odmowa/bez zamka |
| 88 | `ch13_05_planted_key` | 13 | egyptian T2 | 1.8 | 165 | 0 | 670 | ok |
| 89 | `ch13_06_bike_repair_stand` | 13 | disc_detainer T3 | 2.1 | 201 | 0 | 848 | ok |
| 90 | `ch13_07_museum_night_case` | 13 | magnetic T2 | 1.8 | 213 | 0 | 1042 | ok |
| 91 | `refuse_ch13_08_found_cashbox` | 13 | lever T3 | 1.0 | 0 | 0 | 1042 | odmowa/bez zamka |
| 92 | `ch13_09_pizzeria_terrace` | 13 | dial_safe T3 | 2.0 | 219 | 0 | 1242 | ok |
| 93 | `ch13_10_courtyard_door` | 13 | pin_tumbler T4 | 1.5 | 236 | 0 | 1460 | ok |
| 94 | `ch14_01_summer_storage` | 14 | wafer T3 | 1.6 | 150 | 0 | 1600 | ok |
| 95 | `ch14_02_ship_time` | 14 | time_lock T2 | 1.8 | 195 | 0 | 418 | ok |
| 96 | `ch14_03_books_under_linden` | 14 | lever T4 | 1.4 | 175 | 0 | 610 | ok |
| 97 | `refuse_ch14_04_paid_week` | 14 | dimple T3 | 1.0 | 0 | 0 | 539 | odmowa/bez zamka |
| 98 | `ch14_05_cat_passport` | 14 | axial_slider T3 | 2.1 | 213 | 0 | 740 | ok |
| 99 | `ch14_06_suitcase_flew_on` | 14 | dimple T3 | 2.1 | 219 | 0 | 485 | ok |
| 100 | `ch14_07_prize_cupboard` | 14 | combo T4 | 2.1 | 225 | 0 | 496 | ok |
| 101 | `refuse_ch14_08_early_present` | 14 | warded T2 | 1.0 | 0 | 0 | 494 | odmowa/bez zamka |
| 102 | `ch14_09_summer_cinema` | 14 | lever_detector T5 | 1.7 | 236 | 0 | 705 | ok |
| 103 | `ch14_10_holiday_keys` | 14 | pin_tumbler T5 | 1.6 | 220 | 0 | 934 | ok |
| 104 | `ch15_01_wrong_envelope` | 15 | dimple T3 | 2.0 | 189 | 0 | 1104 | ok |
| 105 | `ch15_02_apple_press` | 15 | egyptian T2 | 1.7 | 195 | 0 | 1280 | ok |
| 106 | `ch15_03_charleroi_box` | 15 | axial_slider T3 | 2.0 | 207 | 0 | 1408 | ok |
| 107 | `refuse_ch15_04_closed_attic` | 15 | lever T4 | 1.0 | 0 | 0 | 253 | odmowa/bez zamka |
| 108 | `ch15_05_first_vacation` | 15 | dial_safe T3 | 1.9 | 219 | 0 | 452 | ok |
| 109 | `ch15_06_bike_by_train` | 15 | disc_detainer T3 | 2.0 | 225 | 0 | 546 | ok |
| 110 | `ch15_07_skeleton_cupboard` | 15 | lever T5 | 1.6 | 230 | 0 | 746 | ok |
| 111 | `refuse_ch15_08_no_answer` | 15 | warded T2 | 1.0 | 0 | 0 | 746 | odmowa/bez zamka |
| 112 | `ch15_09_key_board` | 15 | lever_detector T5 | 1.7 | 242 | 0 | 962 | ok |
| 113 | `ch15_10_exam_lock` | 15 | pin_tumbler T6 | 1.6 | 240 | 0 | 1222 | ok |
| 114 | `ch16_01_bookmark_key` | 16 | axial_slider T3 | 2.0 | 201 | 0 | 1404 | ok |
| 115 | `ch16_02_auction_safe` | 16 | dial_safe T3 | 1.9 | 180 | 0 | 1588 | ok |
| 116 | `ch16_03_spare_in_the_lake` | 16 | dimple T3 | 1.9 | 219 | 0 | 1605 | ok |
| 117 | `refuse_ch16_04_borrowed_barrow` | 16 | egyptian T2 | 1.0 | 0 | 0 | 298 | odmowa/bez zamka |
| 118 | `ch16_05_wrong_padlock` | 16 | combo T4 | 2.0 | 195 | 0 | 502 | ok |
| 119 | `ch16_06_salt_before_frost` | 16 | disc_detainer T3 | 2.0 | 205 | 0 | 641 | ok |
| 120 | `ch16_07_hour_back` | 16 | lever T5 | 1.6 | 254 | 0 | 864 | ok |
| 121 | `refuse_ch16_08_roommates_room` | 16 | warded T2 | 1.0 | 0 | 0 | 862 | odmowa/bez zamka |
| 122 | `ch16_09_almost_right_key` | 16 | lever_detector T5 | 1.7 | 272 | 0 | 1112 | ok |
| 123 | `ch16_10_thirteenth_envelope` | 16 | pin_tumbler T6 | 1.6 | 307 | 0 | 1392 | ok |

### Scenariusz D

| # | zlecenie | rozdz. | rodzina T | czas [min] | zarobek | sesje grindu | monety po | stan |
|---|---|---|---|---|---|---|---|---|
| 1 | `grandma_broth` | 1 | pin_tumbler T1 | 1.4 | 89 | 0 | 89 | ok |
| 2 | `cat_bathroom` | 1 | warded T1 | 1.6 | 71 | 0 | 149 | ok |
| 3 | `student_dorm` | 1 | pin_tumbler T1 | 1.4 | 70 | 0 | 216 | ok |
| 4 | `kiosk_shutter` | 1 | wafer T1 | 1.5 | 80 | 0 | 161 | ok |
| 5 | `bike_interview` | 1 | combo T1 | 2.0 | 77 | 0 | 229 | ok |
| 6 | `refuse_ex_partner` | 1 | pin_tumbler T2 | 1.0 | 0 | 0 | 229 | odmowa/bez zamka |
| 7 | `newlyweds_4am` | 2 | pin_tumbler T2 | 1.5 | 177 | 0 | 398 | ok |
| 8 | `pizzeria_pays_pizza` | 2 | lever T1 | 1.5 | 0 | 0 | 97 | ok |
| 9 | `night_nurse` | 2 | magnetic T1 | 1.8 | 106 | 2 | 437 | ok |
| 10 | `wrong_floor` | 2 | pin_tumbler T1 | 1.0 | 20 | 0 | 438 | odmowa/bez zamka |
| 11 | `refuse_rush_bribe` | 2 | pin_tumbler T2 | 1.0 | 0 | 0 | 434 | odmowa/bez zamka |
| 12 | `drummer_locker` | 2 | tubular T1 | 1.8 | 110 | 1 | 584 | ok |
| 13 | `grandpa_chest` | 3 | warded T3 | 1.6 | 165 | 0 | 742 | ok |
| 14 | `uncle_safe_heirs` | 3 | dial_safe T2 | 2.1 | 142 | 1 | 461 | ok |
| 15 | `dollhouse_wooden_lock` | 3 | egyptian T1 | 1.6 | 59 | 0 | 516 | ok |
| 16 | `allotment_shed` | 3 | wafer T2 | 1.5 | 100 | 0 | 609 | ok |
| 17 | `widow_bureau` | 3 | lever T2 | 1.4 | 112 | 0 | 704 | ok |
| 18 | `refuse_aunt_alive` | 3 | lever T2 | 1.0 | 90 | 0 | 794 | odmowa/bez zamka |
| 19 | `krakow_tenement_gate` | 4 | warded T3 | 1.5 | 160 | 0 | 975 | ok |
| 20 | `swiatniki_journeyman_padlock` | 4 | warded T3 | 1.5 | 0 | 0 | 515 | ok |
| 21 | `krakow_antiquarian` | 4 | dial_safe T1 | 1.8 | 142 | 0 | 642 | ok |
| 22 | `brussels_townhouse` | 5 | dimple T2 | 2.1 | 105 | 1 | 425 | ok |
| 23 | `ghent_beguinage` | 5 | warded T2 | 1.5 | 118 | 0 | 536 | ok |
| 24 | `liege_bakery` | 5 | lever_detector T2 | 2.0 | 154 | 0 | 660 | ok |
| 25 | `charleroi_letters` | 5 | wafer T2 | 1.5 | 0 | 0 | 578 | ok |
| 26 | `museum_time_lock` | 6 | time_lock T2 | 2.1 | 177 | 0 | 750 | ok |
| 27 | `bramah_bureau` | 6 | axial_slider T2 | 2.0 | 165 | 1 | 414 | ok |
| 28 | `finnish_sailor` | 6 | disc_detainer T2 | 2.1 | 160 | 2 | 442 | ok |
| 29 | `time_capsule` | 6 | combo T3 | 1.9 | 0 | 0 | 436 | ok |
| 30 | `halina_recipe_box` | 7 | warded T1 | 1.4 | 89 | 0 | 521 | ok |
| 31 | `roman_service_cupboard` | 7 | wafer T2 | 1.4 | 105 | 0 | 632 | ok |
| 32 | `marta_poster_studio` | 7 | pin_tumbler T2 | 1.3 | 124 | 0 | 746 | ok |
| 33 | `zuzanna_catalogue_drawer` | 7 | lever T3 | 1.3 | 124 | 0 | 856 | ok |
| 34 | `refuse_sisters_flat` | 7 | pin_tumbler T2 | 1.0 | 0 | 0 | 856 | odmowa/bez zamka |
| 35 | `stefan_book_tin` | 7 | combo T3 | 2.4 | 171 | 0 | 1016 | ok |
| 36 | `edek_rehearsal_store` | 7 | lever T3 | 1.3 | 124 | 0 | 1124 | ok |
| 37 | `krystyna_wooden_album` | 7 | egyptian T1 | 1.8 | 89 | 0 | 1209 | ok |
| 38 | `refuse_unapproved_stockroom` | 7 | wafer T2 | 1.0 | 0 | 0 | 1209 | odmowa/bez zamka |
| 39 | `gosia_workbench_drawer` | 7 | lever T3 | 1.3 | 171 | 0 | 1365 | ok |
| 40 | `community_notice_case` | 7 | warded T2 | 1.5 | 124 | 0 | 1486 | ok |
| 41 | `shared_room_door` | 7 | pin_tumbler T3 | 1.4 | 171 | 0 | 1635 | ok |
| 42 | `frozen_cellar_padlock` | 8 | combo T2 | 1.9 | 118 | 0 | 1747 | ok |
| 43 | `halina_christmas_tin` | 8 | warded T1 | 1.4 | 89 | 0 | 1824 | ok |
| 44 | `carol_singers_chest` | 8 | egyptian T1 | 1.7 | 89 | 0 | 1913 | ok |
| 45 | `refuse_wrong_letterbox` | 8 | wafer T1 | 1.0 | 0 | 0 | 1913 | odmowa/bez zamka |
| 46 | `wigilia_table_drawer` | 8 | lever T3 | 1.3 | 171 | 0 | 2066 | ok |
| 47 | `heating_service_cupboard` | 8 | pin_tumbler T3 | 1.4 | 171 | 0 | 2225 | ok |
| 48 | `refuse_unapproved_repair` | 8 | wafer T2 | 1.0 | 0 | 0 | 2225 | odmowa/bez zamka |
| 49 | `warm_room_for_neighbours` | 8 | pin_tumbler T3 | 1.4 | 171 | 0 | 2380 | ok |
| 50 | `winter_bicycle_cellar` | 8 | combo T3 | 2.2 | 145 | 0 | 2542 | ok |
| 51 | `wooden_winter_village` | 8 | egyptian T1 | 1.7 | 89 | 0 | 2626 | ok |
| 52 | `attic_drying_room` | 8 | lever T3 | 1.3 | 171 | 0 | 2777 | ok |
| 53 | `christmas_eve_heat` | 8 | lever_detector T5 | 1.9 | 210 | 0 | 2984 | ok |
| 54 | `t43_09_01_winter_keys` | 9 | pin_tumbler T2 | 1.3 | 47 | 0 | 3024 | ok |
| 55 | `t43_09_02_blanket_cupboard` | 9 | magnetic T2 | 1.9 | 59 | 0 | 3076 | ok |
| 56 | `t43_09_03_wooden_postbox` | 9 | egyptian T2 | 1.8 | 71 | 0 | 3144 | ok |
| 57 | `t43_09_04_choir_case` | 9 | combo T2 | 1.8 | 83 | 0 | 3218 | ok |
| 58 | `t43_09_05_receipt_safe` | 9 | dial_safe T2 | 1.8 | 95 | 0 | 3301 | ok |
| 59 | `t43_09_06_draughty_hall` | 9 | dimple T2 | 1.9 | 106 | 0 | 3373 | ok |
| 60 | `refuse_t43_09_empty_flat` | 9 | pin_tumbler T3 | 1.0 | 0 | 0 | 3373 | odmowa/bez zamka |
| 61 | `t43_09_08_spare_key_hook` | 9 | pin_tumbler T2 | 1.0 | 40 | 0 | 3413 | odmowa/bez zamka |
| 62 | `t43_10_01_renovator_bureau` | 10 | axial_slider T2 | 1.9 | 118 | 0 | 3528 | ok |
| 63 | `t43_10_02_scaffold_store` | 10 | disc_detainer T2 | 1.9 | 130 | 0 | 3646 | ok |
| 64 | `t43_10_03_exhibit_clock` | 10 | time_lock T2 | 2.0 | 142 | 0 | 3784 | ok |
| 65 | `t43_10_04_design_cabinet` | 10 | magnetic T2 | 1.9 | 154 | 0 | 3912 | ok |
| 66 | `t43_10_05_porters_drawer` | 10 | lever T3 | 1.3 | 165 | 0 | 4062 | ok |
| 67 | `t43_10_06_shared_room_entry` | 10 | dimple T3 | 2.1 | 177 | 0 | 4212 | ok |
| 68 | `refuse_t43_10_early_clearance` | 10 | lever T3 | 1.0 | 0 | 0 | 4212 | odmowa/bez zamka |
| 69 | `t43_11_01_wooden_market` | 11 | egyptian T2 | 1.8 | 150 | 0 | 4376 | ok |
| 70 | `t43_11_02_bicycle_stand` | 11 | combo T3 | 2.0 | 189 | 0 | 4555 | ok |
| 71 | `t43_11_03_tool_exchange` | 11 | axial_slider T3 | 2.1 | 201 | 0 | 4728 | ok |
| 72 | `t43_11_04_sailors_stall` | 11 | disc_detainer T3 | 2.1 | 213 | 0 | 4892 | ok |
| 73 | `t43_11_05_rehearsal_chest` | 11 | lever T4 | 1.4 | 219 | 0 | 5100 | ok |
| 74 | `refuse_t43_11_other_stall` | 11 | wafer T3 | 1.0 | 0 | 0 | 5100 | odmowa/bez zamka |
| 75 | `t43_11_07_wrong_delivery` | 11 | pin_tumbler T3 | 1.0 | 40 | 0 | 5140 | odmowa/bez zamka |
| 76 | `t43_12_01_letters_archive` | 12 | dial_safe T3 | 2.1 | 219 | 0 | 5298 | ok |
| 77 | `t43_12_02_detective_cabinet` | 12 | lever_detector T5 | 1.8 | 225 | 0 | 5502 | ok |
| 78 | `t43_12_03_community_store` | 12 | pin_tumbler T5 | 1.6 | 195 | 0 | 5710 | ok |
| 79 | `t43_12_04_school_box` | 12 | lever T5 | 1.6 | 198 | 0 | 5896 | ok |
| 80 | `t43_12_05_tea_fund_case` | 12 | combo T4 | 2.1 | 236 | 0 | 6110 | ok |
| 81 | `refuse_t43_12_surprise_key` | 12 | pin_tumbler T6 | 1.0 | 0 | 0 | 6110 | odmowa/bez zamka |
| 82 | `t43_12_07_clock_back_home` | 12 | time_lock T2 | 1.9 | 236 | 0 | 6328 | ok |
| 83 | `t43_12_08_henryks_bench` | 12 | pin_tumbler T6 | 1.6 | 200 | 0 | 6558 | ok |
| 84 | `ch13_01_balcony_boxes` | 13 | warded T2 | 1.5 | 177 | 0 | 6728 | ok |
| 85 | `ch13_02_first_ice_cream` | 13 | wafer T2 | 1.4 | 169 | 0 | 6890 | ok |
| 86 | `ch13_03_allotment_gate` | 13 | lever T3 | 1.3 | 189 | 0 | 7060 | ok |
| 87 | `refuse_ch13_04_winter_bike` | 13 | combo T3 | 1.0 | 0 | 0 | 7060 | odmowa/bez zamka |
| 88 | `ch13_05_planted_key` | 13 | egyptian T2 | 1.7 | 140 | 0 | 7216 | ok |
| 89 | `ch13_06_bike_repair_stand` | 13 | disc_detainer T3 | 2.1 | 201 | 0 | 7376 | ok |
| 90 | `ch13_07_museum_night_case` | 13 | magnetic T2 | 1.8 | 213 | 0 | 7554 | ok |
| 91 | `refuse_ch13_08_found_cashbox` | 13 | lever T3 | 1.0 | 0 | 0 | 7554 | odmowa/bez zamka |
| 92 | `ch13_09_pizzeria_terrace` | 13 | dial_safe T3 | 2.0 | 219 | 0 | 7742 | ok |
| 93 | `ch13_10_courtyard_door` | 13 | pin_tumbler T4 | 1.5 | 218 | 0 | 7968 | ok |
| 94 | `ch14_01_summer_storage` | 14 | wafer T3 | 1.6 | 177 | 0 | 8138 | ok |
| 95 | `ch14_02_ship_time` | 14 | time_lock T2 | 1.8 | 195 | 0 | 8310 | ok |
| 96 | `ch14_03_books_under_linden` | 14 | lever T4 | 1.4 | 207 | 0 | 8512 | ok |
| 97 | `refuse_ch14_04_paid_week` | 14 | dimple T3 | 1.0 | 0 | 0 | 8512 | odmowa/bez zamka |
| 98 | `ch14_05_cat_passport` | 14 | axial_slider T3 | 2.1 | 213 | 0 | 8678 | ok |
| 99 | `ch14_06_suitcase_flew_on` | 14 | dimple T3 | 2.0 | 219 | 0 | 8852 | ok |
| 100 | `ch14_07_prize_cupboard` | 14 | combo T4 | 2.0 | 225 | 0 | 9076 | ok |
| 101 | `refuse_ch14_08_early_present` | 14 | warded T2 | 1.0 | 0 | 0 | 9076 | odmowa/bez zamka |
| 102 | `ch14_09_summer_cinema` | 14 | lever_detector T5 | 1.7 | 218 | 0 | 9274 | ok |
| 103 | `ch14_10_holiday_keys` | 14 | pin_tumbler T5 | 1.6 | 260 | 0 | 9523 | ok |
| 104 | `ch15_01_wrong_envelope` | 15 | dimple T3 | 2.0 | 189 | 0 | 9691 | ok |
| 105 | `ch15_02_apple_press` | 15 | egyptian T2 | 1.7 | 195 | 0 | 9862 | ok |
| 106 | `ch15_03_charleroi_box` | 15 | axial_slider T3 | 2.0 | 207 | 0 | 10042 | ok |
| 107 | `refuse_ch15_04_closed_attic` | 15 | lever T4 | 1.0 | 0 | 0 | 10042 | odmowa/bez zamka |
| 108 | `ch15_05_first_vacation` | 15 | dial_safe T3 | 2.0 | 185 | 0 | 10220 | ok |
| 109 | `ch15_06_bike_by_train` | 15 | disc_detainer T3 | 2.0 | 225 | 0 | 10410 | ok |
| 110 | `ch15_07_skeleton_cupboard` | 15 | lever T5 | 1.6 | 195 | 0 | 10616 | ok |
| 111 | `refuse_ch15_08_no_answer` | 15 | warded T2 | 1.0 | 0 | 0 | 10616 | odmowa/bez zamka |
| 112 | `ch15_09_key_board` | 15 | lever_detector T5 | 1.7 | 205 | 0 | 10810 | ok |
| 113 | `ch15_10_exam_lock` | 15 | pin_tumbler T6 | 1.6 | 240 | 0 | 11060 | ok |
| 114 | `ch16_01_bookmark_key` | 16 | axial_slider T3 | 2.0 | 201 | 0 | 11222 | ok |
| 115 | `ch16_02_auction_safe` | 16 | dial_safe T3 | 1.9 | 213 | 0 | 11427 | ok |
| 116 | `ch16_03_spare_in_the_lake` | 16 | dimple T3 | 1.9 | 185 | 0 | 11639 | ok |
| 117 | `refuse_ch16_04_borrowed_barrow` | 16 | egyptian T2 | 1.0 | 0 | 0 | 11639 | odmowa/bez zamka |
| 118 | `ch16_05_wrong_padlock` | 16 | combo T4 | 2.0 | 230 | 0 | 11850 | ok |
| 119 | `ch16_06_salt_before_frost` | 16 | disc_detainer T3 | 2.0 | 242 | 0 | 12079 | ok |
| 120 | `ch16_07_hour_back` | 16 | lever T5 | 1.6 | 254 | 0 | 12298 | ok |
| 121 | `refuse_ch16_08_roommates_room` | 16 | warded T2 | 1.0 | 0 | 0 | 12298 | odmowa/bez zamka |
| 122 | `ch16_09_almost_right_key` | 16 | lever_detector T5 | 1.7 | 230 | 0 | 12540 | ok |
| 123 | `ch16_10_thirteenth_envelope` | 16 | pin_tumbler T6 | 1.6 | 307 | 0 | 12830 | ok |

## 5. Krzywa odblokowań (narzędzie kupione po zleceniu nr, mediana; — = nigdy)

| narzędzie | cena przed D-62 / dane (C) | warunek | B:car | B:ave | B:clu | C:car | C:ave | C:clu | D:car | D:ave | D:clu |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `tw_bar` | 450 / 150 | after_tier4 | 19 | 19 | 19 | 17 | 17 | 18 | 19 | 19 | 19 |
| `tl_shackle` | 150 / 60 | after_first_t2 | 2 | 2 | 2 | 2 | 2 | 2 | 2 | 3 | 3 |
| `pk_ripple` | 350 / 110 | after_5_locks_t2 | — | — | — | 12 | 12 | 13 | — | — | — |
| `pk_wedge` | 700 / 200 | after_t3 | — | — | — | 14 | 13 | 14 | — | — | — |
| `pk_lever` | 300 / 120 | after_t2 | 5 | 5 | 5 | 4 | 5 | 5 | 7 | 7 | 7 |
| `pk_crown` | 600 / 180 | after_t3 | 9 | 9 | 9 | 9 | 9 | 9 | 12 | 12 | 12 |
| `tl_polar` | 700 / 200 | after_t4 | 52 | 52 | 52 | 17 | 22 | 21 | 9 | 9 | 9 |
| `pk_flag` | 900 / 240 | after_t5 | 56 | 56 | 56 | 30 | 28 | 28 | 22 | 22 | 22 |
| `pk_plunger` | 1000 / 260 | after_t5 | 24 | 24 | 24 | 24 | 24 | 26 | 26 | 27 | 24 |
| `pk_disc` | 1100 / 280 | after_t5 | 25 | 25 | 25 | 27 | 26 | 31 | 28 | 28 | 25 |
| `pk_feather` | 2000 / 500 | after_t7_F3 | — | — | — | — | — | — | — | — | — |
| `tl_cup` | 1200 / 300 | after_t4 | 14 | 18 | 18 | 19 | 19 | 23 | 14 | 14 | 14 |
| `ob_microscope` | 250 / 90 | after_t2 | — | — | — | 3 | 3 | 3 | — | — | — |
| `ob_borescope` | 400 / 130 | after_t3 | — | — | — | 7 | 7 | 7 | — | — | — |

Krzywa (average): liczba posiadanych narzędzi płatnych po każdym zleceniu, mediana.

```
B   1  2  2  2  3  3  3  3  4  4  4  4  4  4  4  4  4  5  6  6  6  6  6  7  8  9  9  9  9
C   1  2  3  3  4  4  5  5  6  6  6  7  8  8  8  8  9  9 10 10 10 11 11 12 12 14 14 15 15
D   1  1  2  2  2  2  3  3  4  4  4  5  5  6  6  6  6  6  7  7  7  8  8  8  8  9 10 11 11
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

## 6a. Wyposażenie warsztatu (D-71, D-127, `game/data/furnishings.json`, scenariusz C)

15 przedmiotów kosmetycznych (bez wpływu na trudność), razem 11550 monet. Gracz w modelu kupuje je po narzędziach: każdy przedmiot z osiągniętego rozdziału, najpierw starsze rozdziały i tańsze, z rezerwą 50 monet na naprawy. Ostatni przedmiot odblokowuje rozdz. 15.

| Profil | stan na koniec rozdz. | monety przed wyposażeniem | wydane na wyposażenie | kupione (mediana) / dostępne | wszystkie dostępne [% karier] | monety zostają |
|---|---|---|---|---|---|---|
| careful | 12 | 7378 | 6750 | 10 / 10 | 100% | 628 |
| careful | 16 | 14486 | 11550 | 15 / 15 | 100% | 2936 |
| average | 12 | 6496 | 5150 | 9 / 10 | 0% | 1344 |
| average | 16 | 12942 | 11550 | 15 / 15 | 100% | 1392 |
| clumsy | 12 | 5786 | 5150 | 9 / 10 | 0% | 636 |
| clumsy | 16 | 11598 | 10750 | 14 / 15 | 50% | 764 |

| przedmiot | cena | od rozdz. | kupiony po zleceniu nr (careful) | kupiony po zleceniu nr (average) | kupiony po zleceniu nr (clumsy) |
|---|---|---|---|---|---|
| `plant` | 150 | 1 | 7 (2; 100%) | 14 (3; 100%) | 16 (3; 100%) |
| `rug` | 300 | 1 | 23 (5; 100%) | 32 (7; 100%) | 35 (7; 100%) |
| `shelf_light` | 400 | 2 | 33 (7; 100%) | 37 (7; 100%) | 40 (7; 100%) |
| `radio` | 600 | 3 | 42 (8; 100%) | 46 (8; 100%) | 50 (8; 100%) |
| `certificate` | 350 | 4 | 36 (7; 100%) | 40 (7; 100%) | 42 (8; 100%) |
| `case_velvet` | 900 | 5 | 62 (10; 100%) | 53 (8; 100%) | 71 (11; 100%) |
| `clock` | 800 | 6 | 50 (8; 100%) | 66 (10; 100%) | 64 (10; 100%) |
| `thanks_cards` | 450 | 9 | 54 (9; 100%) | 59 (9; 100%) | 54 (9; 100%) |
| `vise` | 1200 | 10 | 71 (11; 100%) | 76 (12; 100%) | 80 (12; 100%) |
| `exhibit_shelf` | 1600 | 11 | 80 (12; 100%) | 94 (14; 0%) | 113 (15; 0%) |
| `enamel_mugs` | 500 | 13 | 84 (13; 0%) | 84 (13; 0%) | 84 (13; 0%) |
| `neighbours_photo` | 800 | 13 | 88 (13; 0%) | 84 (13; 0%) | 89 (13; 0%) |
| `postcards` | 700 | 14 | 94 (14; 0%) | 98 (14; 0%) | 94 (14; 0%) |
| `key_cabinet` | 1200 | 14 | 99 (14; 0%) | 105 (15; 0%) | 103 (14; 0%) |
| `exam_lock` | 1600 | 15 | 109 (15; 0%) | 116 (16; 0%) | — |

Komórka: mediana numeru zlecenia, po którym przedmiot jest kupiony (rozdział; odsetek karier, w których kupiono go do końca rozdz. 12; — = mediana: nie kupiony). Cel D-71: przeciętny gracz kupuje większość do końca rozdz. 12, staranny wszystko, a najdroższa półka zostaje celem na końcówkę. D-127: to samo dla przedmiotów z rozdz. 13+ na koniec kariery (staranny kupuje komplet, pozostałym zostaje najdroższy).

## 6b. Monety rozdział po rozdziale (scenariusz C, careful / average / clumsy, mediany)

| rozdz. | zleceń | suma nagród | dochód z napiwkami | wydane w rozdziale (narzędzia, wyposażenie, naprawy) | monety na koniec | wyposażenie posiadane (z 15) |
|---|---|---|---|---|---|---|
| 1 | 6 | 350 | 420 / 388 / 359 | 270 / 270 / 270 | 150 / 118 / 89 | 0 / 0 / 0 |
| 2 | 6 | 370 | 436 / 406 / 381 | 460 / 420 / 352 | 142 / 101 / 118 | 1 / 0 / 0 |
| 3 | 6 | 580 | 678 / 626 / 591 | 700 / 500 / 610 | 148 / 198 / 130 | 1 / 1 / 1 |
| 4 | 3 | 280 | 350 / 309 / 280 | 300 / 300 / 200 | 179 / 184 / 168 | 1 / 1 / 1 |
| 5 | 4 | 335 | 418 / 372 / 347 | 560 / 460 / 342 | 64 / 133 / 188 | 2 / 1 / 1 |
| 6 | 4 | 425 | 498 / 452 / 441 | 520 / 520 / 500 | 220 / 122 / 156 | 2 / 1 / 1 |
| 7 | 12 | 1110 | 1334 / 1214 / 1140 | 990 / 1055 / 974 | 563 / 234 / 321 | 4 / 4 / 3 |
| 8 | 12 | 1260 | 1503 / 1378 / 1294 | 1400 / 1500 / 997 | 626 / 120 / 606 | 6 / 6 / 5 |
| 9 | 8 | 430 | 509 / 469 / 440 | 450 / 450 / 459 | 685 / 146 / 566 | 7 / 7 / 6 |
| 10 | 7 | 750 | 903 / 826 / 764 | 900 / 800 / 877 | 752 / 186 / 473 | 8 / 8 / 7 |
| 11 | 7 | 885 | 1056 / 974 / 905 | 1200 / 0 / 905 | 604 / 1051 / 470 | 9 / 8 / 8 |
| 12 | 8 | 1368 | 1661 / 1509 / 1392 | 1600 / 1205 / 1227 | 628 / 1344 / 636 | 10 / 9 / 9 |
| 13 | 10 | 1340 | 1602 / 1466 / 1378 | 1300 / 1300 / 1305 | 934 / 1438 / 683 | 12 / 11 / 11 |
| 14 | 10 | 1465 | 1777 / 1600 / 1505 | 1905 / 1927 / 1910 | 786 / 934 / 288 | 14 / 13 / 13 |
| 15 | 10 | 1515 | 1813 / 1656 / 1558 | 1612 / 1291 / 1605 | 991 / 1222 / 316 | 15 / 14 / 14 |
| 16 | 10 | 1640 | 1954 / 1790 / 1671 | 0 / 1605 / 1702 | 2936 / 1392 / 764 | 15 / 15 / 14 |

Rozdział, w którym „wydane” spada do kosztu napraw, a „monety na koniec” rosną o cały dochód, to rozdział bez celu dla monet: wszystkie narzędzia i całe wyposażenie są już kupione.

## 7. Model i założenia

- Kolejność zleceń jak w `docs/JOBS.md` (rozdz. 1–6), dalsze rozdziały wg pól `chapter` i `order` w danych. Odmowy (`refuse_*`) i `wrong_floor` grane najlepszą ścieżką, bez zamka.
- Rodzina i tier zlecenia → lockcore: wkładka T1/T2/T3 → t2/t3/t4, płytkowy → t1/t2/t3, zapadkowy → t1/t2/t2 (lockcore nie ma t3), dźwigniowy → t3/t4/t5, z detektorem → t5, szyfrowa → `ring_combo` t2/t2/t3, egipski → `wooden_pin` t1.
- Rodziny bez modułu lockcore (magnetic, tubular, dial_safe, time_lock, dimple, axial_slider, disc_detainer): czas bota szacowany 20/26/34 s dla T1/T2/T3, niezdarny 95 % sukcesu.
- Czas gracza = p50 bota czującego × współczynnik profilu × nauka (od ×1 do ×asymptota, stała 3 zamki rodziny) × szum 0,8–1,25, plus scena zlecenia (dialog, dowody, wycena) 45–80 s.
- Zużycie wg `TOOLS.md` §2: kontakt pod napięciem (max −2), overset −1, stress −2, detektor −1/−3. Złamanie: I → 0, czas ×1,5, naprawa 35 % ceny; zużyte poniżej progu profilu: 15 % ceny (min. 5).
- P(złamanie) = bazowe × tier/3 (+ porażki bota niezdarnego dla profilu clumsy) × do +43 % przy I = 0.
- Warunki `after_tN` = gracz otworzył zamek lockcore tieru ≥ N w dowolnym trybie. `tw_bar` podnosi tier_max Trybu Ciągłego z 5 do 7. `kit_clock` (wydarzenie F2) przyjęty jako nagroda rozdziału 6.
- Napiwek tylko przy otwarciu czystym; oczekiwana wartość = udział profilu × nagroda.
- Scenariusz C (D-62): narzędzia opcjonalne. Gracz kupuje, co pozwalają monety (zlecenia z wyprzedzeniem 3, potem wszystko odblokowane od najtańszego, z rezerwą 50 monet na naprawy); zamek rodziny bez jej narzędzia trwa ×1.15; brak grindu i blokad.
- To model, nie pomiar: liczby profili trzeba zastąpić danymi z playtestów (telemetria czasu i zdarzeń `wear`).
