# Ekonomia kariery — symulacja (tools/econ_sim.py)

Wygenerowane przez `python3 tools/econ_sim.py` (200 karier na profil i scenariusz, seed deterministyczny). Dane wejściowe: `game/data/jobs/*.json`, `game/data/tools.json`, `game/data/progression.json`, `lockcore/BALANCE.md`, `docs/JOBS.md`. Scenariusz C = dane gry bez zmian (ceny D-62); D = zamrożone ceny sprzed D-62 z narzędziem jako bramką zlecenia; A i B to diagnostyka starej krzywej.

## 1. Wnioski w skrócie

1. **D-62: tańsze narzędzia, nigdy blokada zlecenia.** Ceny w `tools.json` (C) spadły z 10100 do 2820 monet za wszystkie 14 płatne narzędzia, a z 6400 do 1790 za te, które mają użycie w zleceniach (9 szt.). Suma nagród 123 zleceń to 14103 monet, plus napiwki. Gra nie sprawdza narzędzi przy przyjęciu zlecenia; model C też nie: brak narzędzia daje wolniejszy zamek (×1.15) i słabszy feedback, ale nie grind.
2. **Przed (D, stare ceny, narzędzie bramką):** zablokowanych zleceń careful/average/clumsy 0/0/0; sesji grindu 7/8/11; dochód ze zleceń 16855/15444/14438 + grind 4252/4478/5840 monet wobec 6400/6400/6400 wydanych na narzędzia.
3. **Po (C, nowe ceny, narzędzia opcjonalne):** zablokowanych 0/0/0; sesji grindu 0/0/0; dochód ze zleceń 16867/15428/14462 monet, wydane na narzędzia 2320/2320/2320 (kupione: 13/13/13 z 13 osiągalnych płatnych); monety niewydane na koniec kariery 2949/1388/319; zamków granych bez własnego narzędzia 4/4/5.
4. **Dochód a koszt narzędzi (C):** dochód ze zleceń / łączny koszt wszystkich płatnych narzędzi (2820) = 598%/547%/513% (careful/average/clumsy); wobec stanu sprzed D-62: 167%/153%/143%.
5. **Naprawy (C):** 28/165/554 monet (careful/average/clumsy), złamań 1/4/12; naprawa liczy się od ceny, więc tańsze narzędzia tańsze też w serwisie.
6. **Czas gry:** ścieżka zleceń (C, bez grindu, bo go nie ma) trwa careful/average/clumsy 263/200/159 min (123 zleceń, rozdz. 1–16; do końca rozdz. 12: 176/135/107 min przy celu D-71 ok. 2 h dla average). Długość regulujemy liczbą zleceń, nie cenami. Tryb Ciągły (sesja 8 min, start) daje 375/402/385 monet i pozostaje dodatkiem, nie warunkiem postępu.
7. **Wyposażenie (D-71, D-127):** 15 przedmiotów kosmetycznych za 11550 monet; careful/average/clumsy kupują 10/9/9 z 10 dostępnych do końca rozdz. 12 (zostaje im 641/1342/624 monet) i 15/15/15 z 15 do końca rozdz. 16, wydają 11550/11550/11550 (sekcja 6a).
8. **Monety po rozdz. 12 mają cel (D-127):** 5 przedmiotów za 4800 monet odblokowują rozdz. 13–15; ostatni zakup wypada po zleceniu nr 109/116/123 z 123 (— = mediana: coś zostaje do kupienia po ostatnim zleceniu), a na koniec rozdz. 16 zostaje 2949/1388/319 monet (careful/average/clumsy). Przebieg rozdział po rozdziale: sekcja 6b.
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
| A | careful | 0 / 123 | 16861 | 255 | 1 | 0.1 | 261.8 | 46 | 1610 | 1 |
| A | average | 0 / 123 | 15420 | 270 | 1 | 0.1 | 199.0 | 253 | 1610 | 5 |
| A | clumsy | 0 / 123 | 14438 | 250 | 1 | 0.1 | 159.3 | 830 | 1610 | 17 |
| B | careful | 2 / 123 | 16616 | 10708 | 22 | 3.1 | 254.6 | 82 | 1790 | 3 |
| B | average | 3 / 123 | 15096 | 12888 | 31 | 4.3 | 191.6 | 405 | 1790 | 18 |
| B | clumsy | 3 / 123 | 14150 | 10610 | 31 | 4.3 | 151.9 | 961 | 1790 | 38 |
| C | careful | 0 / 123 | 16867 | 0 | 0 | 0.0 | 262.6 | 28 | 2320 | 1 |
| C | average | 0 / 123 | 15428 | 0 | 0 | 0.0 | 200.1 | 165 | 2320 | 4 |
| C | clumsy | 0 / 123 | 14462 | 0 | 0 | 0.0 | 159.3 | 554 | 2320 | 12 |
| D | careful | 0 / 123 | 16855 | 4252 | 7 | 1.0 | 259.5 | 80 | 6400 | 2 |
| D | average | 0 / 123 | 15444 | 4478 | 8 | 1.1 | 197.1 | 712 | 6400 | 9 |
| D | clumsy | 0 / 123 | 14438 | 5840 | 11 | 1.5 | 155.7 | 2618 | 6400 | 27 |

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
| 13 | `grandpa_chest` | 3 | warded T3 | 1.6 | 140 | 0 | 240 | ok |
| 14 | `uncle_safe_heirs` | 3 | dial_safe T2 | 2.3 | 120 | 0 | 230 | ok |
| 15 | `dollhouse_wooden_lock` | 3 | egyptian T1 | 1.7 | 59 | 0 | 258 | ok |
| 16 | `allotment_shed` | 3 | wafer T2 | 1.6 | 100 | 0 | 186 | ok |
| 17 | `widow_bureau` | 3 | lever T2 | 1.7 | 112 | 0 | 278 | ok |
| 18 | `refuse_aunt_alive` | 3 | lever T2 | 1.0 | 90 | 0 | 220 | odmowa/bez zamka |
| 19 | `krakow_tenement_gate` | 4 | warded T3 | 1.6 | 189 | 0 | 376 | ok |
| 20 | `swiatniki_journeyman_padlock` | 4 | warded T3 | 1.5 | 0 | 0 | 97 | ok |
| 21 | `krakow_antiquarian` | 4 | dial_safe T1 | 1.8 | 142 | 0 | 225 | ok |
| 22 | `brussels_townhouse` | 5 | dimple T2 | 2.2 | 105 | 0 | 302 | ok |
| 23 | `ghent_beguinage` | 5 | warded T2 | 1.5 | 118 | 0 | 256 | ok |
| 24 | `liege_bakery` | 5 | lever_detector T2 | 2.0 | 130 | 0 | 388 | ok |
| 25 | `charleroi_letters` | 5 | wafer T2 | 1.6 | 0 | 0 | 129 | ok |
| 26 | `museum_time_lock` | 6 | time_lock T2 | 2.1 | 177 | 0 | 294 | ok |
| 27 | `bramah_bureau` | 6 | axial_slider T2 | 2.1 | 165 | 0 | 222 | ok |
| 28 | `finnish_sailor` | 6 | disc_detainer T2 | 2.1 | 160 | 0 | 310 | ok |
| 29 | `time_capsule` | 6 | combo T3 | 2.2 | 0 | 0 | 128 | ok |
| 30 | `halina_recipe_box` | 7 | warded T1 | 1.4 | 75 | 0 | 212 | ok |
| 31 | `roman_service_cupboard` | 7 | wafer T2 | 1.5 | 124 | 0 | 282 | ok |
| 32 | `marta_poster_studio` | 7 | pin_tumbler T2 | 1.4 | 124 | 0 | 372 | ok |
| 33 | `zuzanna_catalogue_drawer` | 7 | lever T3 | 1.4 | 124 | 0 | 244 | ok |
| 34 | `refuse_sisters_flat` | 7 | pin_tumbler T2 | 1.0 | 0 | 0 | 196 | odmowa/bez zamka |
| 35 | `stefan_book_tin` | 7 | combo T3 | 2.5 | 171 | 0 | 358 | ok |
| 36 | `edek_rehearsal_store` | 7 | lever T3 | 1.4 | 124 | 0 | 428 | ok |
| 37 | `krystyna_wooden_album` | 7 | egyptian T1 | 1.8 | 89 | 0 | 181 | ok |
| 38 | `refuse_unapproved_stockroom` | 7 | wafer T2 | 1.0 | 0 | 0 | 166 | odmowa/bez zamka |
| 39 | `gosia_workbench_drawer` | 7 | lever T3 | 1.4 | 171 | 0 | 322 | ok |
| 40 | `community_notice_case` | 7 | warded T2 | 1.5 | 105 | 0 | 425 | ok |
| 41 | `shared_room_door` | 7 | pin_tumbler T3 | 1.5 | 171 | 0 | 319 | ok |
| 42 | `frozen_cellar_padlock` | 8 | combo T2 | 1.9 | 118 | 0 | 338 | ok |
| 43 | `halina_christmas_tin` | 8 | warded T1 | 1.4 | 75 | 0 | 416 | ok |
| 44 | `carol_singers_chest` | 8 | egyptian T1 | 1.7 | 89 | 0 | 502 | ok |
| 45 | `refuse_wrong_letterbox` | 8 | wafer T1 | 1.0 | 0 | 0 | 500 | odmowa/bez zamka |
| 46 | `wigilia_table_drawer` | 8 | lever T3 | 1.3 | 171 | 0 | 658 | ok |
| 47 | `heating_service_cupboard` | 8 | pin_tumbler T3 | 1.4 | 145 | 0 | 328 | ok |
| 48 | `refuse_unapproved_repair` | 8 | wafer T2 | 1.0 | 0 | 0 | 223 | odmowa/bez zamka |
| 49 | `warm_room_for_neighbours` | 8 | pin_tumbler T3 | 1.4 | 171 | 0 | 382 | ok |
| 50 | `winter_bicycle_cellar` | 8 | combo T3 | 2.1 | 171 | 0 | 536 | ok |
| 51 | `wooden_winter_village` | 8 | egyptian T1 | 1.7 | 89 | 0 | 618 | ok |
| 52 | `attic_drying_room` | 8 | lever T3 | 1.3 | 171 | 0 | 770 | ok |
| 53 | `christmas_eve_heat` | 8 | lever_detector T5 | 1.9 | 229 | 0 | 961 | ok |
| 54 | `t43_09_01_winter_keys` | 9 | pin_tumbler T2 | 1.3 | 47 | 0 | 164 | ok |
| 55 | `t43_09_02_blanket_cupboard` | 9 | magnetic T2 | 1.9 | 59 | 0 | 212 | ok |
| 56 | `t43_09_03_wooden_postbox` | 9 | egyptian T2 | 1.8 | 71 | 0 | 276 | ok |
| 57 | `t43_09_04_choir_case` | 9 | combo T2 | 1.8 | 70 | 0 | 348 | ok |
| 58 | `t43_09_05_receipt_safe` | 9 | dial_safe T2 | 1.9 | 95 | 0 | 418 | ok |
| 59 | `t43_09_06_draughty_hall` | 9 | dimple T2 | 1.9 | 90 | 0 | 504 | ok |
| 60 | `refuse_t43_09_empty_flat` | 9 | pin_tumbler T3 | 1.0 | 0 | 0 | 142 | odmowa/bez zamka |
| 61 | `t43_09_08_spare_key_hook` | 9 | pin_tumbler T2 | 1.0 | 40 | 0 | 182 | odmowa/bez zamka |
| 62 | `t43_10_01_renovator_bureau` | 10 | axial_slider T2 | 1.9 | 118 | 0 | 245 | ok |
| 63 | `t43_10_02_scaffold_store` | 10 | disc_detainer T2 | 1.9 | 130 | 0 | 357 | ok |
| 64 | `t43_10_03_exhibit_clock` | 10 | time_lock T2 | 1.9 | 142 | 0 | 486 | ok |
| 65 | `t43_10_04_design_cabinet` | 10 | magnetic T2 | 1.8 | 154 | 0 | 632 | ok |
| 66 | `t43_10_05_porters_drawer` | 10 | lever T3 | 1.3 | 165 | 0 | 774 | ok |
| 67 | `t43_10_06_shared_room_entry` | 10 | dimple T3 | 2.1 | 177 | 0 | 923 | ok |
| 68 | `refuse_t43_10_early_clearance` | 10 | lever T3 | 1.0 | 0 | 0 | 181 | odmowa/bez zamka |
| 69 | `t43_11_01_wooden_market` | 11 | egyptian T2 | 1.8 | 177 | 0 | 348 | ok |
| 70 | `t43_11_02_bicycle_stand` | 11 | combo T3 | 2.0 | 189 | 0 | 456 | ok |
| 71 | `t43_11_03_tool_exchange` | 11 | axial_slider T3 | 2.1 | 201 | 0 | 648 | ok |
| 72 | `t43_11_04_sailors_stall` | 11 | disc_detainer T3 | 2.2 | 180 | 0 | 826 | ok |
| 73 | `t43_11_05_rehearsal_chest` | 11 | lever T4 | 1.5 | 219 | 0 | 1025 | ok |
| 74 | `refuse_t43_11_other_stall` | 11 | wafer T3 | 1.0 | 0 | 0 | 1022 | odmowa/bez zamka |
| 75 | `t43_11_07_wrong_delivery` | 11 | pin_tumbler T3 | 1.0 | 40 | 0 | 1062 | odmowa/bez zamka |
| 76 | `t43_12_01_letters_archive` | 12 | dial_safe T3 | 2.0 | 202 | 0 | 1251 | ok |
| 77 | `t43_12_02_detective_cabinet` | 12 | lever_detector T5 | 1.8 | 225 | 0 | 463 | ok |
| 78 | `t43_12_03_community_store` | 12 | pin_tumbler T5 | 1.6 | 230 | 0 | 494 | ok |
| 79 | `t43_12_04_school_box` | 12 | lever T5 | 1.6 | 234 | 0 | 693 | ok |
| 80 | `t43_12_05_tea_fund_case` | 12 | combo T4 | 2.1 | 236 | 0 | 908 | ok |
| 81 | `refuse_t43_12_surprise_key` | 12 | pin_tumbler T6 | 1.0 | 0 | 0 | 908 | odmowa/bez zamka |
| 82 | `t43_12_07_clock_back_home` | 12 | time_lock T2 | 1.9 | 200 | 0 | 1132 | ok |
| 83 | `t43_12_08_henryks_bench` | 12 | pin_tumbler T6 | 1.6 | 236 | 0 | 1342 | ok |
| 84 | `ch13_01_balcony_boxes` | 13 | warded T2 | 1.5 | 177 | 0 | 1512 | ok |
| 85 | `ch13_02_first_ice_cream` | 13 | wafer T2 | 1.5 | 183 | 0 | 371 | ok |
| 86 | `ch13_03_allotment_gate` | 13 | lever T3 | 1.3 | 189 | 0 | 517 | ok |
| 87 | `refuse_ch13_04_winter_bike` | 13 | combo T3 | 1.0 | 0 | 0 | 513 | odmowa/bez zamka |
| 88 | `ch13_05_planted_key` | 13 | egyptian T2 | 1.7 | 165 | 0 | 662 | ok |
| 89 | `ch13_06_bike_repair_stand` | 13 | disc_detainer T3 | 2.0 | 170 | 0 | 838 | ok |
| 90 | `ch13_07_museum_night_case` | 13 | magnetic T2 | 1.8 | 213 | 0 | 1037 | ok |
| 91 | `refuse_ch13_08_found_cashbox` | 13 | lever T3 | 1.0 | 0 | 0 | 1037 | odmowa/bez zamka |
| 92 | `ch13_09_pizzeria_terrace` | 13 | dial_safe T3 | 2.0 | 202 | 0 | 1237 | ok |
| 93 | `ch13_10_courtyard_door` | 13 | pin_tumbler T4 | 1.5 | 236 | 0 | 1458 | ok |
| 94 | `ch14_01_summer_storage` | 14 | wafer T3 | 1.6 | 177 | 0 | 1614 | ok |
| 95 | `ch14_02_ship_time` | 14 | time_lock T2 | 1.8 | 195 | 0 | 462 | ok |
| 96 | `ch14_03_books_under_linden` | 14 | lever T4 | 1.4 | 207 | 0 | 655 | ok |
| 97 | `refuse_ch14_04_paid_week` | 14 | dimple T3 | 1.0 | 0 | 0 | 514 | odmowa/bez zamka |
| 98 | `ch14_05_cat_passport` | 14 | axial_slider T3 | 2.1 | 213 | 0 | 712 | ok |
| 99 | `ch14_06_suitcase_flew_on` | 14 | dimple T3 | 2.1 | 219 | 0 | 481 | ok |
| 100 | `ch14_07_prize_cupboard` | 14 | combo T4 | 2.1 | 225 | 0 | 510 | ok |
| 101 | `refuse_ch14_08_early_present` | 14 | warded T2 | 1.0 | 0 | 0 | 510 | odmowa/bez zamka |
| 102 | `ch14_09_summer_cinema` | 14 | lever_detector T5 | 1.7 | 236 | 0 | 732 | ok |
| 103 | `ch14_10_holiday_keys` | 14 | pin_tumbler T5 | 1.6 | 220 | 0 | 960 | ok |
| 104 | `ch15_01_wrong_envelope` | 15 | dimple T3 | 2.0 | 160 | 0 | 1131 | ok |
| 105 | `ch15_02_apple_press` | 15 | egyptian T2 | 1.7 | 195 | 0 | 1298 | ok |
| 106 | `ch15_03_charleroi_box` | 15 | axial_slider T3 | 2.0 | 175 | 0 | 1394 | ok |
| 107 | `refuse_ch15_04_closed_attic` | 15 | lever T4 | 1.0 | 0 | 0 | 257 | odmowa/bez zamka |
| 108 | `ch15_05_first_vacation` | 15 | dial_safe T3 | 2.0 | 219 | 0 | 470 | ok |
| 109 | `ch15_06_bike_by_train` | 15 | disc_detainer T3 | 2.0 | 225 | 0 | 553 | ok |
| 110 | `ch15_07_skeleton_cupboard` | 15 | lever T5 | 1.6 | 230 | 0 | 750 | ok |
| 111 | `refuse_ch15_08_no_answer` | 15 | warded T2 | 1.0 | 0 | 0 | 749 | odmowa/bez zamka |
| 112 | `ch15_09_key_board` | 15 | lever_detector T5 | 1.7 | 205 | 0 | 958 | ok |
| 113 | `ch15_10_exam_lock` | 15 | pin_tumbler T6 | 1.6 | 240 | 0 | 1212 | ok |
| 114 | `ch16_01_bookmark_key` | 16 | axial_slider T3 | 2.0 | 170 | 0 | 1393 | ok |
| 115 | `ch16_02_auction_safe` | 16 | dial_safe T3 | 1.9 | 213 | 0 | 1575 | ok |
| 116 | `ch16_03_spare_in_the_lake` | 16 | dimple T3 | 2.0 | 219 | 0 | 1562 | ok |
| 117 | `refuse_ch16_04_borrowed_barrow` | 16 | egyptian T2 | 1.0 | 0 | 0 | 288 | odmowa/bez zamka |
| 118 | `ch16_05_wrong_padlock` | 16 | combo T4 | 2.0 | 230 | 0 | 503 | ok |
| 119 | `ch16_06_salt_before_frost` | 16 | disc_detainer T3 | 2.0 | 205 | 0 | 646 | ok |
| 120 | `ch16_07_hour_back` | 16 | lever T5 | 1.6 | 254 | 0 | 858 | ok |
| 121 | `refuse_ch16_08_roommates_room` | 16 | warded T2 | 1.0 | 0 | 0 | 858 | odmowa/bez zamka |
| 122 | `ch16_09_almost_right_key` | 16 | lever_detector T5 | 1.6 | 272 | 0 | 1108 | ok |
| 123 | `ch16_10_thirteenth_envelope` | 16 | pin_tumbler T6 | 1.6 | 307 | 0 | 1388 | ok |

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
| 30 | `halina_recipe_box` | 7 | warded T1 | 1.4 | 89 | 0 | 508 | ok |
| 31 | `roman_service_cupboard` | 7 | wafer T2 | 1.4 | 124 | 0 | 632 | ok |
| 32 | `marta_poster_studio` | 7 | pin_tumbler T2 | 1.3 | 124 | 0 | 740 | ok |
| 33 | `zuzanna_catalogue_drawer` | 7 | lever T3 | 1.3 | 124 | 0 | 848 | ok |
| 34 | `refuse_sisters_flat` | 7 | pin_tumbler T2 | 1.0 | 0 | 0 | 848 | odmowa/bez zamka |
| 35 | `stefan_book_tin` | 7 | combo T3 | 2.5 | 171 | 0 | 1004 | ok |
| 36 | `edek_rehearsal_store` | 7 | lever T3 | 1.3 | 124 | 0 | 1098 | ok |
| 37 | `krystyna_wooden_album` | 7 | egyptian T1 | 1.8 | 89 | 0 | 1186 | ok |
| 38 | `refuse_unapproved_stockroom` | 7 | wafer T2 | 1.0 | 0 | 0 | 1186 | odmowa/bez zamka |
| 39 | `gosia_workbench_drawer` | 7 | lever T3 | 1.3 | 171 | 0 | 1328 | ok |
| 40 | `community_notice_case` | 7 | warded T2 | 1.5 | 124 | 0 | 1442 | ok |
| 41 | `shared_room_door` | 7 | pin_tumbler T3 | 1.4 | 145 | 0 | 1598 | ok |
| 42 | `frozen_cellar_padlock` | 8 | combo T2 | 2.0 | 118 | 0 | 1708 | ok |
| 43 | `halina_christmas_tin` | 8 | warded T1 | 1.4 | 89 | 0 | 1791 | ok |
| 44 | `carol_singers_chest` | 8 | egyptian T1 | 1.7 | 75 | 0 | 1872 | ok |
| 45 | `refuse_wrong_letterbox` | 8 | wafer T1 | 1.0 | 0 | 0 | 1872 | odmowa/bez zamka |
| 46 | `wigilia_table_drawer` | 8 | lever T3 | 1.3 | 171 | 0 | 2022 | ok |
| 47 | `heating_service_cupboard` | 8 | pin_tumbler T3 | 1.4 | 171 | 0 | 2186 | ok |
| 48 | `refuse_unapproved_repair` | 8 | wafer T2 | 1.0 | 0 | 0 | 2186 | odmowa/bez zamka |
| 49 | `warm_room_for_neighbours` | 8 | pin_tumbler T3 | 1.4 | 171 | 0 | 2340 | ok |
| 50 | `winter_bicycle_cellar` | 8 | combo T3 | 2.1 | 171 | 0 | 2507 | ok |
| 51 | `wooden_winter_village` | 8 | egyptian T1 | 1.6 | 89 | 0 | 2589 | ok |
| 52 | `attic_drying_room` | 8 | lever T3 | 1.3 | 171 | 0 | 2744 | ok |
| 53 | `christmas_eve_heat` | 8 | lever_detector T5 | 1.9 | 248 | 0 | 2960 | ok |
| 54 | `t43_09_01_winter_keys` | 9 | pin_tumbler T2 | 1.3 | 47 | 0 | 3000 | ok |
| 55 | `t43_09_02_blanket_cupboard` | 9 | magnetic T2 | 1.9 | 59 | 0 | 3058 | ok |
| 56 | `t43_09_03_wooden_postbox` | 9 | egyptian T2 | 1.8 | 71 | 0 | 3127 | ok |
| 57 | `t43_09_04_choir_case` | 9 | combo T2 | 1.8 | 70 | 0 | 3208 | ok |
| 58 | `t43_09_05_receipt_safe` | 9 | dial_safe T2 | 1.9 | 95 | 0 | 3290 | ok |
| 59 | `t43_09_06_draughty_hall` | 9 | dimple T2 | 1.9 | 106 | 0 | 3377 | ok |
| 60 | `refuse_t43_09_empty_flat` | 9 | pin_tumbler T3 | 1.0 | 0 | 0 | 3377 | odmowa/bez zamka |
| 61 | `t43_09_08_spare_key_hook` | 9 | pin_tumbler T2 | 1.0 | 40 | 0 | 3417 | odmowa/bez zamka |
| 62 | `t43_10_01_renovator_bureau` | 10 | axial_slider T2 | 2.0 | 118 | 0 | 3516 | ok |
| 63 | `t43_10_02_scaffold_store` | 10 | disc_detainer T2 | 2.0 | 130 | 0 | 3624 | ok |
| 64 | `t43_10_03_exhibit_clock` | 10 | time_lock T2 | 2.0 | 142 | 0 | 3766 | ok |
| 65 | `t43_10_04_design_cabinet` | 10 | magnetic T2 | 1.9 | 154 | 0 | 3886 | ok |
| 66 | `t43_10_05_porters_drawer` | 10 | lever T3 | 1.3 | 165 | 0 | 4022 | ok |
| 67 | `t43_10_06_shared_room_entry` | 10 | dimple T3 | 2.1 | 150 | 0 | 4186 | ok |
| 68 | `refuse_t43_10_early_clearance` | 10 | lever T3 | 1.0 | 0 | 0 | 4186 | odmowa/bez zamka |
| 69 | `t43_11_01_wooden_market` | 11 | egyptian T2 | 1.8 | 177 | 0 | 4356 | ok |
| 70 | `t43_11_02_bicycle_stand` | 11 | combo T3 | 2.0 | 189 | 0 | 4526 | ok |
| 71 | `t43_11_03_tool_exchange` | 11 | axial_slider T3 | 2.1 | 201 | 0 | 4701 | ok |
| 72 | `t43_11_04_sailors_stall` | 11 | disc_detainer T3 | 2.1 | 213 | 0 | 4884 | ok |
| 73 | `t43_11_05_rehearsal_chest` | 11 | lever T4 | 1.4 | 185 | 0 | 5084 | ok |
| 74 | `refuse_t43_11_other_stall` | 11 | wafer T3 | 1.0 | 0 | 0 | 5084 | odmowa/bez zamka |
| 75 | `t43_11_07_wrong_delivery` | 11 | pin_tumbler T3 | 1.0 | 40 | 0 | 5124 | odmowa/bez zamka |
| 76 | `t43_12_01_letters_archive` | 12 | dial_safe T3 | 2.1 | 185 | 0 | 5328 | ok |
| 77 | `t43_12_02_detective_cabinet` | 12 | lever_detector T5 | 1.8 | 190 | 0 | 5518 | ok |
| 78 | `t43_12_03_community_store` | 12 | pin_tumbler T5 | 1.5 | 230 | 0 | 5738 | ok |
| 79 | `t43_12_04_school_box` | 12 | lever T5 | 1.6 | 234 | 0 | 5936 | ok |
| 80 | `t43_12_05_tea_fund_case` | 12 | combo T4 | 2.1 | 236 | 0 | 6140 | ok |
| 81 | `refuse_t43_12_surprise_key` | 12 | pin_tumbler T6 | 1.0 | 0 | 0 | 6140 | odmowa/bez zamka |
| 82 | `t43_12_07_clock_back_home` | 12 | time_lock T2 | 1.9 | 236 | 0 | 6360 | ok |
| 83 | `t43_12_08_henryks_bench` | 12 | pin_tumbler T6 | 1.6 | 200 | 0 | 6582 | ok |
| 84 | `ch13_01_balcony_boxes` | 13 | warded T2 | 1.5 | 177 | 0 | 6738 | ok |
| 85 | `ch13_02_first_ice_cream` | 13 | wafer T2 | 1.4 | 155 | 0 | 6918 | ok |
| 86 | `ch13_03_allotment_gate` | 13 | lever T3 | 1.3 | 189 | 0 | 7086 | ok |
| 87 | `refuse_ch13_04_winter_bike` | 13 | combo T3 | 1.0 | 0 | 0 | 7086 | odmowa/bez zamka |
| 88 | `ch13_05_planted_key` | 13 | egyptian T2 | 1.7 | 165 | 0 | 7248 | ok |
| 89 | `ch13_06_bike_repair_stand` | 13 | disc_detainer T3 | 2.0 | 201 | 0 | 7415 | ok |
| 90 | `ch13_07_museum_night_case` | 13 | magnetic T2 | 1.8 | 213 | 0 | 7592 | ok |
| 91 | `refuse_ch13_08_found_cashbox` | 13 | lever T3 | 1.0 | 0 | 0 | 7592 | odmowa/bez zamka |
| 92 | `ch13_09_pizzeria_terrace` | 13 | dial_safe T3 | 2.0 | 219 | 0 | 7755 | ok |
| 93 | `ch13_10_courtyard_door` | 13 | pin_tumbler T4 | 1.5 | 200 | 0 | 7978 | ok |
| 94 | `ch14_01_summer_storage` | 14 | wafer T3 | 1.6 | 177 | 0 | 8138 | ok |
| 95 | `ch14_02_ship_time` | 14 | time_lock T2 | 1.8 | 195 | 0 | 8323 | ok |
| 96 | `ch14_03_books_under_linden` | 14 | lever T4 | 1.4 | 191 | 0 | 8505 | ok |
| 97 | `refuse_ch14_04_paid_week` | 14 | dimple T3 | 1.0 | 0 | 0 | 8505 | odmowa/bez zamka |
| 98 | `ch14_05_cat_passport` | 14 | axial_slider T3 | 2.1 | 213 | 0 | 8696 | ok |
| 99 | `ch14_06_suitcase_flew_on` | 14 | dimple T3 | 2.1 | 185 | 0 | 8878 | ok |
| 100 | `ch14_07_prize_cupboard` | 14 | combo T4 | 2.1 | 225 | 0 | 9092 | ok |
| 101 | `refuse_ch14_08_early_present` | 14 | warded T2 | 1.0 | 0 | 0 | 9092 | odmowa/bez zamka |
| 102 | `ch14_09_summer_cinema` | 14 | lever_detector T5 | 1.7 | 236 | 0 | 9286 | ok |
| 103 | `ch14_10_holiday_keys` | 14 | pin_tumbler T5 | 1.5 | 260 | 0 | 9540 | ok |
| 104 | `ch15_01_wrong_envelope` | 15 | dimple T3 | 2.0 | 189 | 0 | 9678 | ok |
| 105 | `ch15_02_apple_press` | 15 | egyptian T2 | 1.7 | 195 | 0 | 9862 | ok |
| 106 | `ch15_03_charleroi_box` | 15 | axial_slider T3 | 2.0 | 207 | 0 | 10046 | ok |
| 107 | `refuse_ch15_04_closed_attic` | 15 | lever T4 | 1.0 | 0 | 0 | 10046 | odmowa/bez zamka |
| 108 | `ch15_05_first_vacation` | 15 | dial_safe T3 | 2.0 | 185 | 0 | 10216 | ok |
| 109 | `ch15_06_bike_by_train` | 15 | disc_detainer T3 | 2.0 | 225 | 0 | 10414 | ok |
| 110 | `ch15_07_skeleton_cupboard` | 15 | lever T5 | 1.6 | 195 | 0 | 10618 | ok |
| 111 | `refuse_ch15_08_no_answer` | 15 | warded T2 | 1.0 | 0 | 0 | 10618 | odmowa/bez zamka |
| 112 | `ch15_09_key_board` | 15 | lever_detector T5 | 1.7 | 205 | 0 | 10804 | ok |
| 113 | `ch15_10_exam_lock` | 15 | pin_tumbler T6 | 1.6 | 240 | 0 | 11069 | ok |
| 114 | `ch16_01_bookmark_key` | 16 | axial_slider T3 | 2.0 | 201 | 0 | 11232 | ok |
| 115 | `ch16_02_auction_safe` | 16 | dial_safe T3 | 1.9 | 213 | 0 | 11436 | ok |
| 116 | `ch16_03_spare_in_the_lake` | 16 | dimple T3 | 1.9 | 185 | 0 | 11620 | ok |
| 117 | `refuse_ch16_04_borrowed_barrow` | 16 | egyptian T2 | 1.0 | 0 | 0 | 11620 | odmowa/bez zamka |
| 118 | `ch16_05_wrong_padlock` | 16 | combo T4 | 2.0 | 230 | 0 | 11838 | ok |
| 119 | `ch16_06_salt_before_frost` | 16 | disc_detainer T3 | 2.0 | 205 | 0 | 12032 | ok |
| 120 | `ch16_07_hour_back` | 16 | lever T5 | 1.6 | 254 | 0 | 12253 | ok |
| 121 | `refuse_ch16_08_roommates_room` | 16 | warded T2 | 1.0 | 0 | 0 | 12253 | odmowa/bez zamka |
| 122 | `ch16_09_almost_right_key` | 16 | lever_detector T5 | 1.6 | 272 | 0 | 12495 | ok |
| 123 | `ch16_10_thirteenth_envelope` | 16 | pin_tumbler T6 | 1.6 | 307 | 0 | 12768 | ok |

## 5. Krzywa odblokowań (narzędzie kupione po zleceniu nr, mediana; — = nigdy)

| narzędzie | cena przed D-62 / dane (C) | warunek | B:car | B:ave | B:clu | C:car | C:ave | C:clu | D:car | D:ave | D:clu |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `tw_bar` | 450 / 150 | after_tier4 | 19 | 19 | 19 | 17 | 17 | 18 | 19 | 19 | 19 |
| `tl_shackle` | 150 / 60 | after_first_t2 | 3 | 3 | 3 | 3 | 3 | 3 | 3 | 3 | 3 |
| `pk_ripple` | 350 / 110 | after_5_locks_t2 | — | — | — | 13 | 13 | 13 | — | — | — |
| `pk_wedge` | 700 / 200 | after_t3 | — | — | — | 14 | 15 | 14 | — | — | — |
| `pk_lever` | 300 / 120 | after_t2 | 5 | 5 | 5 | 4 | 5 | 5 | 5 | 5 | 5 |
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
B   1  1  2  2  3  3  3  3  4  4  4  4  4  4  4  4  4  5  6  6  6  6  6  7  8  9  9  9  9
C   1  1  3  3  4  4  5  5  6  6  6  6  7  7  8  8  9  9 10 10 10 11 11 12 12 14 14 15 15
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

## 6a. Wyposażenie warsztatu (D-71, D-127, `game/data/furnishings.json`, scenariusz C)

15 przedmiotów kosmetycznych (bez wpływu na trudność), razem 11550 monet. Gracz w modelu kupuje je po narzędziach: każdy przedmiot z osiągniętego rozdziału, najpierw starsze rozdziały i tańsze, z rezerwą 50 monet na naprawy. Ostatni przedmiot odblokowuje rozdz. 15.

| Profil | stan na koniec rozdz. | monety przed wyposażeniem | wydane na wyposażenie | kupione (mediana) / dostępne | wszystkie dostępne [% karier] | monety zostają |
|---|---|---|---|---|---|---|
| careful | 12 | 7391 | 6750 | 10 / 10 | 100% | 641 |
| careful | 16 | 14499 | 11550 | 15 / 15 | 100% | 2949 |
| average | 12 | 6492 | 5150 | 9 / 10 | 0% | 1342 |
| average | 16 | 12938 | 11550 | 15 / 15 | 100% | 1388 |
| clumsy | 12 | 5774 | 5150 | 9 / 10 | 0% | 624 |
| clumsy | 16 | 11603 | 11550 | 15 / 15 | 52% | 319 |

| przedmiot | cena | od rozdz. | kupiony po zleceniu nr (careful) | kupiony po zleceniu nr (average) | kupiony po zleceniu nr (clumsy) |
|---|---|---|---|---|---|
| `plant` | 150 | 1 | 7 (2; 100%) | 12 (2; 100%) | 16 (3; 100%) |
| `rug` | 300 | 1 | 23 (5; 100%) | 32 (7; 100%) | 35 (7; 100%) |
| `shelf_light` | 400 | 2 | 35 (7; 100%) | 37 (7; 100%) | 40 (7; 100%) |
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
| `exam_lock` | 1600 | 15 | 109 (15; 0%) | 116 (16; 0%) | 123 (16; 0%) |

Komórka: mediana numeru zlecenia, po którym przedmiot jest kupiony (rozdział; odsetek karier, w których kupiono go do końca rozdz. 12; — = mediana: nie kupiony). Cel D-71: przeciętny gracz kupuje większość do końca rozdz. 12, staranny wszystko, a najdroższa półka zostaje celem na końcówkę. D-127: to samo dla przedmiotów z rozdz. 13+ na koniec kariery (staranny kupuje komplet, pozostałym zostaje najdroższy).

## 6b. Monety rozdział po rozdziale (scenariusz C, careful / average / clumsy, mediany)

| rozdz. | zleceń | suma nagród | dochód z napiwkami | wydane w rozdziale (narzędzia, wyposażenie, naprawy) | monety na koniec | wyposażenie posiadane (z 15) |
|---|---|---|---|---|---|---|
| 1 | 6 | 350 | 420 / 388 / 359 | 270 / 270 / 270 | 150 / 117 / 88 | 0 / 0 / 0 |
| 2 | 6 | 370 | 458 / 406 / 381 | 460 / 460 / 310 | 122 / 82 / 156 | 1 / 1 / 0 |
| 3 | 6 | 580 | 681 / 626 / 594 | 660 / 610 / 610 | 150 / 200 / 136 | 1 / 1 / 1 |
| 4 | 3 | 280 | 350 / 309 / 280 | 300 / 300 / 205 | 182 / 190 / 171 | 1 / 1 / 1 |
| 5 | 4 | 335 | 393 / 366 / 347 | 560 / 460 / 306 | 64 / 129 / 200 | 2 / 1 / 1 |
| 6 | 4 | 425 | 498 / 475 / 441 | 520 / 520 / 500 | 213 / 128 / 150 | 2 / 1 / 1 |
| 7 | 12 | 1110 | 1331 / 1214 / 1140 | 990 / 1055 / 971 | 570 / 230 / 327 | 4 / 4 / 3 |
| 8 | 12 | 1260 | 1513 / 1382 / 1290 | 1400 / 1500 / 992 | 628 / 122 / 616 | 6 / 6 / 5 |
| 9 | 8 | 430 | 507 / 466 / 440 | 450 / 450 / 455 | 684 / 135 / 580 | 7 / 7 / 6 |
| 10 | 7 | 750 | 904 / 834 / 767 | 900 / 800 / 884 | 740 / 181 / 493 | 8 / 8 / 7 |
| 11 | 7 | 885 | 1054 / 975 / 905 | 1200 / 0 / 909 | 594 / 1057 / 470 | 9 / 8 / 8 |
| 12 | 8 | 1368 | 1661 / 1508 / 1392 | 1600 / 1200 / 1226 | 641 / 1342 / 624 | 10 / 9 / 9 |
| 13 | 10 | 1340 | 1598 / 1468 / 1378 | 1300 / 1305 / 1310 | 928 / 1456 / 654 | 12 / 11 / 11 |
| 14 | 10 | 1465 | 1777 / 1602 / 1506 | 1900 / 1921 / 1918 | 792 / 960 / 276 | 14 / 13 / 13 |
| 15 | 10 | 1515 | 1812 / 1653 / 1554 | 1618 / 1291 / 1605 | 991 / 1210 / 265 | 15 / 14 / 14 |
| 16 | 10 | 1640 | 1959 / 1790 / 1671 | 0 / 1609 / 1698 | 2949 / 1388 / 319 | 15 / 15 / 15 |

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
