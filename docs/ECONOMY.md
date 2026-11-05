# Ekonomia kariery — symulacja (tools/econ_sim.py)

Wygenerowane przez `python3 tools/econ_sim.py` (200 karier na profil i scenariusz, seed deterministyczny). Dane wejściowe: `game/data/jobs/*.json`, `game/data/tools.json`, `game/data/progression.json`, `lockcore/BALANCE.md`, `docs/JOBS.md`. Plik danych gry nie jest zmieniany (właściciel `game/data`: sesja B); propozycje są w §6.

## 1. Wnioski w skrócie

1. **Dane zleceń mają błędne rodziny.** W `game/data/jobs` 7 zamków „zapadkowych” (warded) z `JOBS.md` ma `family: lever`, `liege_bakery` (dźwigniowy z detektorem) też `lever`, a `drummer_locker` (rurkowy) `unknown`. Skutek: rozdział 1 zaczyna się od 2 zleceń wymagających korby dźwigniowej (500 monet, warunek `after_t3`), choć rozdział 1 płaci łącznie 350 monet; gracz average gra przed pierwszym zleceniem 3 sesji Trybu Ciągłego. W scenariuszu A gracz average ma zablokowane 6 z 29 zleceń. Do poprawy w danych (sesja B).
2. **Wzór krzywej Trybu Ciągłego nie zgadza się z tabelą.** `1 + 0,55·ln(1+n)·skill` daje tier 2.79 na 25. zamku (tabela: 4–5); t4 wymaga n ≈ 230, t5 n ≈ 1 440. Seria z 3 życiami nigdy tam nie dochodzi, więc warunki `after_t4`…`after_t7` są nieosiągalne w Trybie Ciągłym. Współczynnik 1,2 odtwarza tabelę (n = 25 → 4.9).
3. **Martwa strefa: warunki bez źródła tieru.** Zlecenia otwierają co najwyżej lockcore t5 (dźwigniowy T3, detektor), a `tl_cup` wymaga `after_t8` (w lockcore nie ma t8). W scenariuszu B (poprawione rodziny, stary wzór) zablokowane zostają (average): night_nurse, drummer_locker, uncle_safe_heirs, krakow_antiquarian, brussels_townhouse, bramah_bureau, finnish_sailor. Kolejność narzędzi `TOOLS.md` (t5–t8) jest dłuższa niż kariera zleceń (T1–T3).
4. **Grind: zlecenia nie finansują narzędzi.** Suma nagród 29 zleceń = 2340 monet (+ napiwki), a narzędzia potrzebne zleceniom kosztują 10530. Gracz average w B gra 71 sesji Trybu Ciągłego (9.9 h) tylko po to, by kupić narzędzia do zleceń; clumsy 71. To łamie zasadę „bez grind-to-win” (`TOOLS.md` §1.2). Sesja 8 min przynosi (start, B) careful/average/clumsy: 270/280/270 monet, a nie 300: niski tier = 10–20 monet na zamek, nie 40.
5. **Start i za łatwe odblokowania.** Pierwsze zlecenie (`grandma_broth`, zapadkowy) wymaga sondy `pk_ward` za 80 przy 0 monet: gracz musi najpierw zagrać sesję Trybu Ciągłego (B: mediana 1), zanim przyjmie pierwsze zlecenie. Sondę trzeba dać w samouczku (cena 0). `tl_shackle` (150, `after_first_t2`) i potem korba (C: 300) kupuje się bez decyzji, bo monet z rozdziału 1–2 starcza z zapasem: to formalność, nie wybór. Można je dać jako nagrodę rzeczową zlecenia, a monety zostawić na narzędzia z alternatywą.
6. **Naprawy rozwarstwiają profile.** Koszt napraw przez karierę, B (z grindem): careful 432, average 1334, clumsy 2096 monet (63 złamań); C: 5/150/857. Złamanie drogiego narzędzia (35 % ceny, np. obrotnik 1 800 → 630) zjada 4–6 zleceń, więc gracz niezdarny wpada w pętlę grind → naprawa → grind. Propozycja: naprawa złamanego = 15 % + 10 monet stałe, z limitem 150; uczy ostrożności bez spirali. Narzędzia startowe (cena 0) naprawia się za minimum 5, czyli w praktyce za darmo.
7. **Po zmianach (C)** zablokowanych zleceń: careful/average/clumsy 0/0/0; grind 7/8/12 sesji; koszt narzędzi do zleceń 6400 zamiast 10530. Sesja 8 min (C, start) daje 375/402/385 monet.
8. **Czas gry:** sama ścieżka zleceń (bez grindu) trwa (C) careful/average/clumsy 62/47/36 min. Na grę premium to krótko; Tryb Zleceń potrzebuje więcej zleceń (cel ≥ 60) albo powtórek, a nie grindu monet.

## 2. Scenariusze i profile

| Scenariusz | Opis |
|---|---|
| A | data as is (JSON families, tier coef 0.55) |
| B | JOBS.md families, tier coef 0.55 |
| C | proposed numbers (JOBS.md families, coef 1.2, changes in §6) |

| Profil | czas / bot p50 | wspólczynnik nauki | overset / stress na zamek | czysto | napiwek | skill (Ciągły) | P(złamanie) bazowe |
|---|---|---|---|---|---|---|---|
| careful | ×3.0 | → ×0.65 | 0.5 / 0.2 | 80% | 20% | 1.15 | 1.0% × tier/3 |
| average | ×2.4 | → ×0.6 | 2.0 / 1.0 | 55% | 10% | 1.0 | 4.0% × tier/3 |
| clumsy | ×2.0 | → ×0.6 | 5.0 / 3.0 | 25% | 3% | 0.85 | 8.0% × tier/3 |

## 3. Podsumowanie kariery (mediany)

| Scen. | Profil | zlecenia zablok. | dochód ze zleceń | dochód z grindu | sesje grindu | grind [h] | czas zleceń [min] | naprawy | narzędzia | złamania |
|---|---|---|---|---|---|---|---|---|---|---|
| A | careful | 6 / 29 | 1939 | 36190 | 71 | 10.0 | 44.4 | 517 | 1250 | 9 |
| A | average | 6 / 29 | 1778 | 26910 | 63 | 8.8 | 33.5 | 1218 | 1250 | 29 |
| A | clumsy | 6 / 29 | 1660 | 24175 | 68 | 9.3 | 26.0 | 1976 | 1250 | 62 |
| B | careful | 6 / 29 | 1937 | 32152 | 62 | 8.7 | 45.1 | 432 | 2230 | 8 |
| B | average | 7 / 29 | 1658 | 29888 | 71 | 9.9 | 32.2 | 1334 | 1330 | 34 |
| B | clumsy | 7 / 29 | 1555 | 24582 | 71 | 9.8 | 25.2 | 2096 | 1330 | 63 |
| C | careful | 0 / 29 | 2780 | 4275 | 7 | 1.0 | 61.5 | 5 | 6400 | 1 |
| C | average | 0 / 29 | 2549 | 4480 | 8 | 1.1 | 46.7 | 150 | 6400 | 6 |
| C | clumsy | 0 / 29 | 2377 | 6225 | 12 | 1.7 | 36.0 | 857 | 6400 | 19 |

Grind = sesje Trybu Ciągłego (8 min), które gracz musi rozegrać, zanim kupi narzędzie potrzebne do następnego zlecenia. Po 60 sesjach na jedno zlecenie liczymy je jako zablokowane i idziemy dalej.

## 4. Przebieg zlecenie po zleceniu (profil average)

### Scenariusz B

| # | zlecenie | rozdz. | rodzina T | czas [min] | zarobek | sesje grindu | monety po | stan |
|---|---|---|---|---|---|---|---|---|
| 1 | `grandma_broth` | 1 | warded T1 | 1.6 | 89 | 1 | 284 | ok |
| 2 | `cat_bathroom` | 1 | warded T1 | 1.5 | 71 | 0 | 200 | ok |
| 3 | `bike_interview` | 1 | combo T1 | 2.0 | 77 | 0 | 270 | ok |
| 4 | `student_dorm` | 1 | pin_tumbler T1 | 1.3 | 70 | 0 | 346 | ok |
| 5 | `kiosk_shutter` | 1 | wafer T1 | 1.3 | 95 | 0 | 432 | ok |
| 6 | `refuse_ex_partner` | 1 | pin_tumbler T2 | 1.0 | 0 | 0 | 432 | odmowa/bez zamka |
| 7 | `newlyweds_4am` | 2 | pin_tumbler T2 | 1.4 | 177 | 0 | 593 | ok |
| 8 | `pizzeria_pays_pizza` | 2 | lever T1 | 1.5 | 0 | 0 | 92 | ok |
| 9 | `night_nurse` | 2 | magnetic T1 | 0.0 | 0 | 10 | 4010 | zablokowane |
| 10 | `wrong_floor` | 2 | pin_tumbler T1 | 1.0 | 20 | 0 | 4030 | odmowa/bez zamka |
| 11 | `refuse_rush_bribe` | 2 | pin_tumbler T2 | 1.0 | 0 | 0 | 4030 | odmowa/bez zamka |
| 12 | `drummer_locker` | 2 | tubular T1 | 0.0 | 0 | 10 | 8060 | zablokowane |
| 13 | `grandpa_chest` | 3 | warded T3 | 1.5 | 165 | 0 | 8212 | ok |
| 14 | `uncle_safe_heirs` | 3 | dial_safe T2 | 0.0 | 0 | 10 | 12341 | zablokowane |
| 15 | `dollhouse_wooden_lock` | 3 | egyptian T1 | 1.4 | 59 | 0 | 12392 | ok |
| 16 | `allotment_shed` | 3 | wafer T2 | 1.4 | 100 | 0 | 12478 | ok |
| 17 | `widow_bureau` | 3 | lever T2 | 1.4 | 112 | 0 | 12559 | ok |
| 18 | `refuse_aunt_alive` | 3 | lever T2 | 1.0 | 90 | 0 | 12649 | odmowa/bez zamka |
| 19 | `krakow_tenement_gate` | 4 | warded T3 | 1.5 | 189 | 0 | 12814 | ok |
| 20 | `swiatniki_journeyman_padlock` | 4 | warded T3 | 1.5 | 0 | 0 | 12210 | ok |
| 21 | `krakow_antiquarian` | 4 | dial_safe T1 | 0.0 | 0 | 10 | 16338 | zablokowane |
| 22 | `brussels_townhouse` | 5 | dimple T2 | 0.0 | 0 | 10 | 20326 | zablokowane |
| 23 | `ghent_beguinage` | 5 | warded T2 | 1.5 | 118 | 0 | 20440 | ok |
| 24 | `liege_bakery` | 5 | lever_detector T2 | 2.0 | 130 | 0 | 20549 | ok |
| 25 | `charleroi_letters` | 5 | wafer T2 | 1.4 | 0 | 0 | 20549 | ok |
| 26 | `museum_time_lock` | 6 | time_lock T2 | 2.1 | 177 | 0 | 20718 | ok |
| 27 | `bramah_bureau` | 6 | axial_slider T2 | 0.0 | 0 | 10 | 24800 | zablokowane |
| 28 | `finnish_sailor` | 6 | disc_detainer T2 | 0.0 | 0 | 10 | 28854 | zablokowane |
| 29 | `time_capsule` | 6 | combo T3 | 1.8 | 0 | 0 | 28854 | ok |

### Scenariusz C

| # | zlecenie | rozdz. | rodzina T | czas [min] | zarobek | sesje grindu | monety po | stan |
|---|---|---|---|---|---|---|---|---|
| 1 | `grandma_broth` | 1 | warded T1 | 1.6 | 89 | 0 | 89 | ok |
| 2 | `cat_bathroom` | 1 | warded T1 | 1.5 | 71 | 0 | 149 | ok |
| 3 | `bike_interview` | 1 | combo T1 | 2.0 | 77 | 1 | 447 | ok |
| 4 | `student_dorm` | 1 | pin_tumbler T1 | 1.3 | 76 | 0 | 522 | ok |
| 5 | `kiosk_shutter` | 1 | wafer T1 | 1.3 | 95 | 0 | 607 | ok |
| 6 | `refuse_ex_partner` | 1 | pin_tumbler T2 | 1.0 | 0 | 0 | 307 | odmowa/bez zamka |
| 7 | `newlyweds_4am` | 2 | pin_tumbler T2 | 1.4 | 177 | 0 | 471 | ok |
| 8 | `pizzeria_pays_pizza` | 2 | lever T1 | 1.5 | 0 | 0 | 467 | ok |
| 9 | `night_nurse` | 2 | magnetic T1 | 1.8 | 106 | 1 | 480 | ok |
| 10 | `wrong_floor` | 2 | pin_tumbler T1 | 1.0 | 20 | 0 | 480 | odmowa/bez zamka |
| 11 | `refuse_rush_bribe` | 2 | pin_tumbler T2 | 1.0 | 0 | 0 | 473 | odmowa/bez zamka |
| 12 | `drummer_locker` | 2 | tubular T1 | 1.8 | 110 | 1 | 609 | ok |
| 13 | `grandpa_chest` | 3 | warded T3 | 1.6 | 165 | 0 | 756 | ok |
| 14 | `uncle_safe_heirs` | 3 | dial_safe T2 | 2.1 | 120 | 1 | 518 | ok |
| 15 | `dollhouse_wooden_lock` | 3 | egyptian T1 | 1.6 | 59 | 0 | 570 | ok |
| 16 | `allotment_shed` | 3 | wafer T2 | 1.4 | 100 | 0 | 664 | ok |
| 17 | `widow_bureau` | 3 | lever T2 | 1.4 | 95 | 0 | 770 | ok |
| 18 | `refuse_aunt_alive` | 3 | lever T2 | 1.0 | 90 | 0 | 860 | odmowa/bez zamka |
| 19 | `krakow_tenement_gate` | 4 | warded T3 | 1.5 | 189 | 0 | 1030 | ok |
| 20 | `swiatniki_journeyman_padlock` | 4 | warded T3 | 1.5 | 0 | 0 | 572 | ok |
| 21 | `krakow_antiquarian` | 4 | dial_safe T1 | 1.7 | 120 | 0 | 682 | ok |
| 22 | `brussels_townhouse` | 5 | dimple T2 | 2.1 | 105 | 1 | 454 | ok |
| 23 | `ghent_beguinage` | 5 | warded T2 | 1.5 | 100 | 0 | 572 | ok |
| 24 | `liege_bakery` | 5 | lever_detector T2 | 2.0 | 154 | 0 | 688 | ok |
| 25 | `charleroi_letters` | 5 | wafer T2 | 1.4 | 0 | 0 | 623 | ok |
| 26 | `museum_time_lock` | 6 | time_lock T2 | 2.1 | 177 | 0 | 782 | ok |
| 27 | `bramah_bureau` | 6 | axial_slider T2 | 2.1 | 140 | 1 | 436 | ok |
| 28 | `finnish_sailor` | 6 | disc_detainer T2 | 2.1 | 160 | 2 | 412 | ok |
| 29 | `time_capsule` | 6 | combo T3 | 2.0 | 0 | 0 | 412 | ok |

## 5. Krzywa odblokowań (narzędzie kupione po zleceniu nr, mediana; — = nigdy)

| narzędzie | cena dane / C | warunek dane / C | A:car | A:ave | A:clu | B:car | B:ave | B:clu | C:car | C:ave | C:clu |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `tw_bar` | 600 / 450 | after_tier4 / after_tier4 | 19 | 19 | 19 | 19 | 19 | 19 | 19 | 19 | 19 |
| `tl_shackle` | 150 / 150 | after_first_t2 / after_first_t2 | 1 | 1 | 1 | 1 | 1 | 1 | 3 | 3 | 3 |
| `pk_ward` | 80 / 0 | after_t1 / after_t1 | — | — | — | 1 | 1 | 1 | 1 | 1 | 1 |
| `pk_ripple` | 350 / 350 | after_5_locks_t2 / after_5_locks_t2 | — | — | — | — | — | — | — | — | — |
| `pk_wedge` | 700 / 700 | after_t3 / after_t3 | — | — | — | — | — | — | — | — | — |
| `pk_lever` | 500 / 300 | after_t3 / after_t2 | 1 | 1 | 1 | 7 | 7 | 7 | 5 | 5 | 5 |
| `pk_crown` | 900 / 600 | after_t4 / after_t3 | — | — | — | 12 | — | — | 12 | 12 | 12 |
| `tl_polar` | 1200 / 700 | after_t5 / after_t4 | — | — | — | — | — | — | 9 | 9 | 9 |
| `pk_flag` | 1500 / 900 | after_t6 / after_t5 | — | — | — | — | — | — | 22 | 22 | 22 |
| `pk_plunger` | 1600 / 1000 | after_t6 / after_t5 | — | — | — | — | — | — | 26 | 27 | 24 |
| `pk_disc` | 1800 / 1100 | after_t7 / after_t5 | — | — | — | — | — | — | 28 | 28 | 25 |
| `pk_feather` | 2000 / 2000 | after_t7_F3 / after_t7_F3 | — | — | — | — | — | — | — | — | — |
| `tl_cup` | 2200 / 1200 | after_t8 / after_t4 | — | — | — | — | — | — | 14 | 14 | 14 |

Krzywa (average): liczba posiadanych narzędzi płatnych po każdym zleceniu, mediana.

```
A   2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  2  3  3  3  3  3  3  3  4  4  4  4
B   2  2  2  2  2  2  3  3  3  3  3  3  3  3  3  3  3  3  4  4  4  4  4  4  4  5  5  5  5
C   1  1  2  2  3  3  3  3  4  4  4  5  5  6  6  6  6  6  7  7  7  8  8  8  8  9 10 11 11
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

`progression.json` zakłada 300 monet na sesję i ok. 40 na zamek w środku serii.

## 6. Proponowane zmiany liczb (do decyzji; danych nie zmieniam)

| gdzie | pole | jest | propozycja | po co |
|---|---|---|---|---|
| `game/data/jobs/*.json` | `family` 7 zleceń „zapadkowych” | `lever` | `warded` | zgodność z `JOBS.md`; rozdział 1 bez korby za 500 |
| `job.liege_bakery.json` | `family` | `lever` | `lever_detector` | `JOBS.md`: „dźwigniowy z detektorem, T2” |
| `job.drummer_locker.json` | `family` | `unknown` | `tubular` | `JOBS.md`: „rurkowy, T1” |
| `progression.json` | `tier_curve.formula` | `0.55 * ln(1+n)` | `1.2 * ln(1+n)` | wzór zgodny z tabelą §2.2 |
| `tools.json` | `pk_ward.price` | 80 | 0 | dar w samouczku: pierwsze zlecenie bez grindu |
| `tools.json` | `pk_lever.price` | 500 | 300 | narzędzie do zleceń za ok. 2–3 zlecenia rozdziału + 1–2 sesje Trybu Ciągłego |
| `tools.json` | `tl_polar.price` | 1200 | 700 | narzędzie do zleceń za ok. 2–3 zlecenia rozdziału + 1–2 sesje Trybu Ciągłego |
| `tools.json` | `pk_crown.price` | 900 | 600 | narzędzie do zleceń za ok. 2–3 zlecenia rozdziału + 1–2 sesje Trybu Ciągłego |
| `tools.json` | `tw_bar.price` | 600 | 450 | narzędzie do zleceń za ok. 2–3 zlecenia rozdziału + 1–2 sesje Trybu Ciągłego |
| `tools.json` | `pk_flag.price` | 1500 | 900 | narzędzie do zleceń za ok. 2–3 zlecenia rozdziału + 1–2 sesje Trybu Ciągłego |
| `tools.json` | `pk_plunger.price` | 1600 | 1000 | narzędzie do zleceń za ok. 2–3 zlecenia rozdziału + 1–2 sesje Trybu Ciągłego |
| `tools.json` | `pk_disc.price` | 1800 | 1100 | narzędzie do zleceń za ok. 2–3 zlecenia rozdziału + 1–2 sesje Trybu Ciągłego |
| `tools.json` | `tl_cup.price` | 2200 | 1200 | narzędzie do zleceń za ok. 2–3 zlecenia rozdziału + 1–2 sesje Trybu Ciągłego |
| `tools.json` | `tl_cup.unlock` | `after_t8` | `after_t4` | osiągalne przed pierwszym zleceniem rodziny (tiery zleceń i Trybu Ciągłego) |
| `tools.json` | `pk_disc.unlock` | `after_t7` | `after_t5` | osiągalne przed pierwszym zleceniem rodziny (tiery zleceń i Trybu Ciągłego) |
| `tools.json` | `tl_polar.unlock` | `after_t5` | `after_t4` | osiągalne przed pierwszym zleceniem rodziny (tiery zleceń i Trybu Ciągłego) |
| `tools.json` | `pk_crown.unlock` | `after_t4` | `after_t3` | osiągalne przed pierwszym zleceniem rodziny (tiery zleceń i Trybu Ciągłego) |
| `tools.json` | `pk_lever.unlock` | `after_t3` | `after_t2` | osiągalne przed pierwszym zleceniem rodziny (tiery zleceń i Trybu Ciągłego) |
| `tools.json` | `pk_flag.unlock` | `after_t6` | `after_t5` | osiągalne przed pierwszym zleceniem rodziny (tiery zleceń i Trybu Ciągłego) |
| `tools.json` | `pk_plunger.unlock` | `after_t6` | `after_t5` | osiągalne przed pierwszym zleceniem rodziny (tiery zleceń i Trybu Ciągłego) |
| `tools.json` | `wear_model.repair_broken_pct` | 0.35 | 0.15 + 10 monet, max 150 | bez spirali naprawa → grind u gracza niezdarnego |
| `JOBS.md` / dane | zapadkowy T3 (3 zlecenia) | lockcore t2 max | dodać `warded` t3 albo zmienić na T2 | dziś T3 = t2, „mistrzowskie” zlecenie jest łatwiejsze od rozdziału 1 wkładki |
| `progression.json` | `economy.session_income` | 300 | wartość z symulacji C (tabela §5) | dokument ma mówić prawdę o tempie |

Ceny w tabeli §5 (kolumna „dane / C”) pokazują stan dzisiejszy i propozycję obok siebie.

## 7. Model i założenia

- Kolejność zleceń jak w `docs/JOBS.md`. Odmowy (`refuse_*`) i `wrong_floor` grane najlepszą ścieżką, bez zamka.
- Rodzina i tier zlecenia → lockcore: wkładka T1/T2/T3 → t2/t3/t4, płytkowy → t1/t2/t3, zapadkowy → t1/t2/t2 (lockcore nie ma t3), dźwigniowy → t3/t4/t5, z detektorem → t5, szyfrowa → `ring_combo` t2/t2/t3, egipski → `wooden_pin` t1.
- Rodziny bez modułu lockcore (magnetic, tubular, dial_safe, time_lock, dimple, axial_slider, disc_detainer): czas bota szacowany 20/26/34 s dla T1/T2/T3, niezdarny 95 % sukcesu.
- Czas gracza = p50 bota czującego × współczynnik profilu × nauka (od ×1 do ×asymptota, stała 3 zamki rodziny) × szum 0,8–1,25, plus scena zlecenia (dialog, dowody, wycena) 45–80 s.
- Zużycie wg `TOOLS.md` §2: kontakt pod napięciem (max −2), overset −1, stress −2, detektor −1/−3. Złamanie: I → 0, czas ×1,5, naprawa 35 % ceny; zużyte poniżej progu profilu: 15 % ceny (min. 5).
- P(złamanie) = bazowe × tier/3 (+ porażki bota niezdarnego dla profilu clumsy) × do +43 % przy I = 0.
- Warunki `after_tN` = gracz otworzył zamek lockcore tieru ≥ N w dowolnym trybie. `tw_bar` podnosi tier_max Trybu Ciągłego z 5 do 7. `kit_clock` (wydarzenie F2) przyjęty jako nagroda rozdziału 6.
- Napiwek tylko przy otwarciu czystym; oczekiwana wartość = udział profilu × nagroda.
- To model, nie pomiar: liczby profili trzeba zastąpić danymi z playtestów (telemetria czasu i zdarzeń `wear`).
