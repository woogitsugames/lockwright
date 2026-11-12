# Krzywa trudności: audyt rodzin i tierów (2026-11)

Status: 2026-11-12, D-116. Dane: `lockcore/build/verify_seeds --seeds 10000` (41 par rodzina × tier, trzy boty na
każdym seedzie, 0 porażek bramki A3) po zmianach z §5; wartości „przed” pochodzą z tego samego przebiegu na kodzie
sprzed zmian. Zlecenia: `game/data/jobs/*.json` (83 pliki, 70 z zamkiem), tryb ciągły: `game/data/progression.json`
i `game/scripts/ui/run_state.gd`.

D-60 odłożyło kalibrację t2/t3 „do testów z graczami”. Testów nadal nie ma, więc ten dokument używa najlepszego
dostępnego zastępnika: bota czującego i bota niezdarnego. To są **dwa modele ręki, nie gracze** — §1 mówi, czego
nie mierzą.

## 1. Metoda i jej granice

| bot | co wie | ręka | co mierzy |
|---|---|---|---|
| skryptowy | plan wyroczni | drżenie ±0,03, reakcja 180 ms, budżet = pół limitu | bramka A3: zamek da się otworzyć (0 porażek) |
| czujący (`--feel`) | tylko zdarzenia i dwa sygnały ciągłe, z opóźnieniem 220 ms | drżenie ±0,04, unoszenie 0,4/s | ile trwa otwarcie „po sygnałach”; czy sygnały wystarczają |
| niezdarny (`--clumsy`) | plan wyroczni, ale bez granicy overset | drżenie ±0,06, unoszenie 0,7/s (0,3/s po `near_shear`), reakcja 250 ms | ile kosztuje szorstka ręka: zrzuty, oversety, fałszywe ustawienia, blokady |

Na potrzeby audytu `verify_seeds` wypisuje dla obu botów miękkich także: fałszywe ustawienia i oversety na zamek,
p90 czasu oraz powód porażki (brak czasu, blokada detektora, złamanie, otwarcie z narzędziem ≥ 0,8 S_max). Te same
liczby są w CSV (nowe kolumny dopisane na końcu wiersza). Boty rodzin pierścieniowych (`ring_combo`, `combo`,
`disc_detainer`) liczą teraz też `combo.slip` i `disc.overturn` jako overset; wynik to nadal 0.

Czego ten zastępnik **nie** mierzy:

- **Łamania narzędzia.** Bot niezdarny bierze napięcie z planu, czujący obniża je przy pierwszym `stress`. Na
  410 000 przebiegów każdego bota: niezdarny 0 złamań, czujący 10 (wszystkie `warded` t2, 0,1 %). Kolumna
  „złamania” jest więc prawie pusta nie dlatego, że narzędzia nie da się złamać, tylko dlatego, że żaden bot nie
  ciągnie za mocno. Brakuje bota „ciężkiej ręki”.
- **Okien pozycji bez zabezpieczeń.** Bot niezdarny po `near_shear` zwalnia do 0,3/s i reaguje po 250 ms, więc
  przejeżdża najwyżej ok. 0,095 skoku. Najmniejsze okno + margines w tabelach to 0,125 (`pin_tumbler` t7), a
  wyrocznia nie przepuszcza mniej niż 0,09. Zwykły element **nie może** więc ukarać tego bota; kary pojawiają się
  tylko tam, gdzie są szpulki, fałszywe bramki albo detektor. Stąd zera w większości tabeli 2.2 (patrz §4.3).
- **Czytania obrazu.** Bot czujący nie widzi zamka; w rodzinach z szukaniem (`warded`, `disc_detainer`, `combo`,
  `ring_combo`, `dial_safe`) jego czas zależy od strategii sondowania, a człowiek widzi wycięcia i tarcze.
- **Uczenia się.** Każdy zamek bot otwiera pierwszy raz.

Czasy to mediany (p50) i p90 udanych przebiegów. Różnice skuteczności rzędu kilku seedów na 10 000 to szum (D-34).

## 2. Wyniki: rodzina × tier

### 2.1 Bot czujący (i skryptowy)

Zrzuty, oversety i fałszywe ustawienia: średnio na zamek. „Brak czasu” i „blokady” (trzeci `detector_trip`):
liczba przebiegów na 10 000.

| rodzina | tier | limit | skrypt. p50 | czujący ok | p50 | p90 | p90/limit | zrzuty | oversety | fałsz. ustaw. | złamania | brak czasu | blokady |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `pin_tumbler` | t2 | 60 s | 5,2 s | 99,99 % | 11,0 s | 13,3 s | 22 % | 0,00 | 0,01 | 0,00 | 0 | 1 | 0 |
|  | t3 | 120 s | 6,7 s | 100,00 % | 15,4 s | 18,5 s | 15 % | 0,00 | 0,02 | 0,00 | 0 | 0 | 0 |
|  | t4 | 120 s | 8,2 s | 99,98 % | 19,9 s | 23,8 s | 20 % | 0,00 | 0,04 | 0,51 | 0 | 2 | 0 |
|  | t5 | 120 s | 8,6 s | 99,99 % | 22,2 s | 27,9 s | 23 % | 0,00 | 0,07 | 0,77 | 0 | 1 | 0 |
|  | t6 | 150 s | 9,3 s | 100,00 % | 24,6 s | 29,5 s | 20 % | 0,03 | 0,14 | 1,32 | 0 | 0 | 0 |
|  | t7 | 150 s | 10,0 s | 99,94 % | 27,4 s | 35,2 s | 23 % | 0,11 | 0,26 | 2,56 | 0 | 6 | 0 |
| `wafer` | t1 | 60 s | 5,6 s | 100,00 % | 12,0 s | 14,1 s | 24 % | 0,00 | 0,01 | 0,00 | 0 | 0 | 0 |
|  | t2 | 60 s | 7,0 s | 99,96 % | 16,8 s | 19,6 s | 33 % | 0,00 | 0,02 | 0,00 | 0 | 4 | 0 |
|  | t3 | 60 s | 8,1 s | 99,98 % | 21,9 s | 25,5 s | 43 % | 0,00 | 0,03 | 0,00 | 0 | 2 | 0 |
| `wooden_pin` | t1 | 60 s | 6,3 s | 100,00 % | 16,1 s | 21,2 s | 35 % | 0,00 | 0,01 | 0,00 | 0 | 0 | 0 |
| `lever` | t3 | 120 s | 5,6 s | 100,00 % | 12,5 s | 15,2 s | 13 % | 0,00 | 0,01 | 0,00 | 0 | 0 | 0 |
|  | t4 | 120 s | 6,9 s | 100,00 % | 17,6 s | 21,6 s | 18 % | 0,00 | 0,02 | 1,48 | 0 | 0 | 0 |
|  | t5 | 150 s | 10,2 s | 100,00 % | 23,4 s | 29,4 s | 20 % | 0,01 | 0,05 | 6,04 | 0 | 0 | 0 |
| `lever_detector` | t5 | 150 s | 8,7 s | 99,97 % | 23,2 s | 29,3 s | 20 % | 0,00 | 0,05 | 3,97 | 0 | 0 | 3 |
|  | t6 | 180 s | 12,2 s | 99,95 % | 29,1 s | 36,5 s | 20 % | 0,00 | 0,05 | 7,46 | 0 | 0 | 5 |
| `ring_combo` | t2 | 90 s | 9,0 s | 100,00 % | 24,6 s | 35,0 s | 39 % | 0,00 | 0,00 | 0,00 | 0 | 0 | 0 |
|  | t3 | 120 s | 11,6 s | 100,00 % | 33,8 s | 45,2 s | 38 % | 0,00 | 0,00 | 6,36 | 0 | 0 | 0 |
| `warded` | t1 | 60 s | 3,2 s | 99,96 % | 14,6 s | 21,6 s | 36 % | 0,00 | 0,00 | 0,00 | 0 | 4 | 0 |
|  | t2 | 90 s | 3,3 s | 99,90 % | 18,8 s | 37,1 s | 41 % | 0,00 | 0,00 | 0,00 | 10 | 0 | 0 |
| `dial_safe` | t1 | 120 s | 10,7 s | 100,00 % | 9,3 s | 14,2 s | 12 % | 0,00 | 0,00 | 0,00 | 0 | 0 | 0 |
|  | t2 | 150 s | 15,3 s | 100,00 % | 20,2 s | 23,3 s | 16 % | 0,00 | 0,00 | 1,74 | 0 | 0 | 0 |
|  | t3 | 180 s | 17,6 s | 100,00 % | 32,2 s | 38,9 s | 22 % | 0,00 | 0,00 | 4,94 | 0 | 0 | 0 |
| `combo` | t1 | 90 s | 7,9 s | 100,00 % | 21,1 s | 28,0 s | 31 % | 0,00 | 0,00 | 0,00 | 0 | 0 | 0 |
|  | t2 | 100 s | 9,1 s | 100,00 % | 24,7 s | 35,0 s | 35 % | 0,00 | 0,00 | 0,00 | 0 | 0 | 0 |
|  | t3 | 120 s | 10,4 s | 100,00 % | 29,3 s | 37,9 s | 32 % | 0,00 | 0,00 | 2,67 | 0 | 0 | 0 |
|  | t4 | 140 s | 11,6 s | 100,00 % | 34,0 s | 45,5 s | 33 % | 0,00 | 0,00 | 9,53 | 0 | 0 | 0 |
| `dimple` | t1 | 90 s | 7,6 s | 99,98 % | 15,5 s | 18,7 s | 21 % | 0,00 | 0,01 | 0,00 | 0 | 2 | 0 |
|  | t2 | 120 s | 7,4 s | 100,00 % | 17,8 s | 23,0 s | 19 % | 0,01 | 0,02 | 1,01 | 0 | 0 | 0 |
|  | t3 | 120 s | 8,9 s | 99,96 % | 22,4 s | 28,3 s | 24 % | 0,01 | 0,04 | 1,52 | 0 | 4 | 0 |
| `disc_detainer` | t1 | 90 s | 10,8 s | 100,00 % | 28,3 s | 37,4 s | 42 % | 0,00 | 0,00 | 0,00 | 0 | 0 | 0 |
|  | t2 | 120 s | 13,5 s | 100,00 % | 39,7 s | 49,3 s | 41 % | 0,00 | 0,00 | 2,72 | 0 | 0 | 0 |
|  | t3 | 150 s | 14,7 s | 100,00 % | 44,9 s | 57,8 s | 39 % | 0,00 | 0,00 | 5,93 | 0 | 0 | 0 |
| `egyptian` | t1 | 60 s | 6,9 s | 100,00 % | 13,4 s | 16,5 s | 27 % | 0,00 | 0,00 | 0,00 | 0 | 0 | 0 |
|  | t2 | 90 s | 9,5 s | 100,00 % | 21,8 s | 27,5 s | 31 % | 0,00 | 0,01 | 0,00 | 0 | 0 | 0 |
| `axial_slider` | t1 | 90 s | 7,6 s | 100,00 % | 17,5 s | 21,0 s | 23 % | 0,00 | 0,02 | 0,00 | 0 | 0 | 0 |
|  | t2 | 120 s | 8,8 s | 100,00 % | 23,0 s | 27,8 s | 23 % | 0,00 | 0,02 | 1,94 | 0 | 0 | 0 |
|  | t3 | 150 s | 10,6 s | 100,00 % | 28,6 s | 35,1 s | 23 % | 0,01 | 0,03 | 4,74 | 0 | 0 | 0 |
| `time_lock` | t1 | 90 s | 7,5 s | 100,00 % | 12,9 s | 14,3 s | 16 % | 0,00 | 0,01 | 0,00 | 0 | 0 | 0 |
|  | t2 | 120 s | 10,1 s | 100,00 % | 18,5 s | 22,3 s | 19 % | 0,00 | 0,01 | 0,00 | 0 | 0 | 0 |
| `magnetic` | t1 | 90 s | 5,6 s | 100,00 % | 10,7 s | 13,1 s | 15 % | 0,00 | 0,01 | 0,00 | 0 | 0 | 0 |
|  | t2 | 120 s | 7,0 s | 100,00 % | 15,3 s | 18,1 s | 15 % | 0,00 | 0,02 | 0,00 | 0 | 0 | 0 |

Bot czujący otwiera 99,90–100 % w każdym wierszu. Jego porażki to pętle bota, nie zamki: „brak czasu” nie zależy
od limitu (próba z limitem `wafer` 60 → 75 / 90 s dała te same 4 i 2 porażki na 10 000).

### 2.2 Bot niezdarny

Ostatnia kolumna: mediana niezdarnego podzielona przez medianę czującego. Poniżej 1 = szorstka ręka jest szybsza
od ostrożnej.

| rodzina | tier | niezdarny ok | p50 | p90 | zrzuty | oversety | fałsz. ustaw. | złamania | brak czasu | blokady | p50 niezd. / p50 czuj. |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `pin_tumbler` | t2 | 100,00 % | 2,9 s | 3,0 s | 0,00 | 0,00 | 0,00 | 0 | 0 | 0 | 0,26 |
|  | t3 | 100,00 % | 3,8 s | 4,0 s | 0,00 | 0,00 | 0,00 | 0 | 0 | 0 | 0,25 |
|  | t4 | 99,99 % | 5,0 s | 24,0 s | 0,86 | 1,24 | 1,75 | 0 | 1 | 0 | 0,25 |
|  | t5 | 99,93 % | 14,0 s | 38,5 s | 1,67 | 2,44 | 3,27 | 0 | 7 | 0 | 0,63 |
|  | t6 | 93,66 % | 33,1 s | 87,3 s | 5,13 | 7,52 | 9,42 | 0 | 631 | 0 | 1,34 |
|  | t7 | 35,97 % | 56,9 s | 124,4 s | 12,97 | 29,41 | 32,03 | 0 | 6402 | 0 | 2,08 |
| `wafer` | t1 | 100,00 % | 3,1 s | 3,2 s | 0,00 | 0,00 | 0,00 | 0 | 0 | 0 | 0,26 |
|  | t2 | 100,00 % | 3,9 s | 4,1 s | 0,00 | 0,00 | 0,00 | 0 | 0 | 0 | 0,23 |
|  | t3 | 100,00 % | 4,7 s | 4,9 s | 0,00 | 0,00 | 0,00 | 0 | 0 | 0 | 0,22 |
| `wooden_pin` | t1 | 100,00 % | 3,7 s | 4,7 s | 0,00 | 0,00 | 0,00 | 0 | 0 | 0 | 0,23 |
| `lever` | t3 | 100,00 % | 3,0 s | 3,2 s | 0,00 | 0,00 | 0,00 | 0 | 0 | 0 | 0,24 |
|  | t4 | 100,00 % | 4,7 s | 5,4 s | 0,00 | 0,00 | 1,98 | 0 | 0 | 0 | 0,27 |
|  | t5 | 99,99 % | 12,1 s | 18,7 s | 0,75 | 1,66 | 11,96 | 0 | 0 | 0 | 0,52 |
| `lever_detector` | t5 | 99,87 % | 11,3 s | 17,5 s | 0,45 | 1,46 | 7,51 | 0 | 0 | 13 | 0,49 |
|  | t6 | 75,42 % | 20,2 s | 28,4 s | 0,35 | 2,54 | 13,98 | 0 | 0 | 2458 | 0,69 |
| `ring_combo` | t2 | 100,00 % | 6,4 s | 8,2 s | 0,00 | 0,00 | 0,00 | 0 | 0 | 0 | 0,26 |
|  | t3 | 100,00 % | 8,2 s | 10,0 s | 0,00 | 0,00 | 0,59 | 0 | 0 | 0 | 0,24 |
| `warded` | t1 | 100,00 % | 2,3 s | 2,5 s | 0,00 | 0,00 | 0,00 | 0 | 0 | 0 | 0,16 |
|  | t2 | 100,00 % | 2,5 s | 2,6 s | 0,00 | 0,00 | 0,00 | 0 | 0 | 0 | 0,13 |
| `dial_safe` | t1 | 100,00 % | 9,8 s | 10,7 s | 0,00 | 0,00 | 0,00 | 0 | 0 | 0 | 1,06 |
|  | t2 | 100,00 % | 13,6 s | 14,6 s | 0,00 | 0,00 | 1,73 | 0 | 0 | 0 | 0,67 |
|  | t3 | 100,00 % | 15,2 s | 19,8 s | 0,00 | 0,00 | 4,92 | 0 | 0 | 0 | 0,47 |
| `combo` | t1 | 100,00 % | 5,6 s | 6,6 s | 0,00 | 0,00 | 0,00 | 0 | 0 | 0 | 0,26 |
|  | t2 | 100,00 % | 6,4 s | 8,2 s | 0,00 | 0,00 | 0,00 | 0 | 0 | 0 | 0,26 |
|  | t3 | 100,00 % | 7,3 s | 8,5 s | 0,00 | 0,00 | 0,25 | 0 | 0 | 0 | 0,25 |
|  | t4 | 100,00 % | 8,2 s | 10,0 s | 0,00 | 0,00 | 0,90 | 0 | 0 | 0 | 0,24 |
| `dimple` | t1 | 100,00 % | 4,2 s | 4,4 s | 0,00 | 0,00 | 0,00 | 0 | 0 | 0 | 0,27 |
|  | t2 | 100,00 % | 7,9 s | 12,6 s | 0,36 | 1,26 | 2,26 | 0 | 0 | 0 | 0,45 |
|  | t3 | 100,00 % | 15,5 s | 24,9 s | 0,89 | 3,03 | 4,62 | 0 | 0 | 0 | 0,69 |
| `disc_detainer` | t1 | 100,00 % | 7,8 s | 8,8 s | 0,00 | 0,00 | 0,00 | 0 | 0 | 0 | 0,27 |
|  | t2 | 100,00 % | 9,7 s | 10,8 s | 0,00 | 0,00 | 0,48 | 0 | 0 | 0 | 0,24 |
|  | t3 | 100,00 % | 10,5 s | 12,3 s | 0,00 | 0,00 | 1,09 | 0 | 0 | 0 | 0,23 |
| `egyptian` | t1 | 100,00 % | 4,0 s | 4,2 s | 0,00 | 0,00 | 0,00 | 0 | 0 | 0 | 0,30 |
|  | t2 | 100,00 % | 5,3 s | 5,8 s | 0,00 | 0,00 | 0,00 | 0 | 0 | 0 | 0,24 |
| `axial_slider` | t1 | 100,00 % | 4,2 s | 4,3 s | 0,00 | 0,00 | 0,00 | 0 | 0 | 0 | 0,24 |
|  | t2 | 100,00 % | 6,1 s | 6,8 s | 0,00 | 0,00 | 2,51 | 0 | 0 | 0 | 0,26 |
|  | t3 | 100,00 % | 8,7 s | 9,2 s | 0,02 | 0,04 | 6,10 | 0 | 0 | 0 | 0,31 |
| `time_lock` | t1 | 100,00 % | 5,0 s | 5,1 s | 0,00 | 0,00 | 0,00 | 0 | 0 | 0 | 0,39 |
|  | t2 | 100,00 % | 7,0 s | 7,8 s | 0,00 | 0,00 | 0,00 | 0 | 0 | 0 | 0,38 |
| `magnetic` | t1 | 100,00 % | 3,0 s | 3,2 s | 0,00 | 0,00 | 0,00 | 0 | 0 | 0 | 0,28 |
|  | t2 | 100,00 % | 4,0 s | 4,2 s | 0,00 | 0,00 | 0,00 | 0 | 0 | 0 | 0,26 |

### 2.3 Krok między tierami

| rodzina | przejście | czujący p50 | niezdarny p50 | niezdarny ok | zrzuty+oversety (niezd.) |
|---|---|---|---|---|---|
| `pin_tumbler` | t2 → t3 | ×1,40 | ×1,33 | 100,0 → 100,0 % | 0,00 → 0,00 |
| `pin_tumbler` | t3 → t4 | ×1,30 | ×1,32 | 100,0 → 99,9 % | 0,00 → 2,11 |
| `pin_tumbler` | t4 → t5 | ×1,11 | ×2,79 | 99,9 → 99,9 % | 2,11 → 4,11 |
| `pin_tumbler` | t5 → t6 | ×1,11 | ×2,37 | 99,9 → 93,6 % | 4,11 → 12,65 |
| `pin_tumbler` | t6 → t7 | ×1,11 | ×1,72 | 93,6 → 35,9 % | 12,65 → 42,37 |
| `wafer` | t1 → t2 | ×1,40 | ×1,26 | 100,0 → 100,0 % | 0,00 → 0,00 |
| `wafer` | t2 → t3 | ×1,30 | ×1,22 | 100,0 → 100,0 % | 0,00 → 0,00 |
| `lever` | t3 → t4 | ×1,41 | ×1,56 | 100,0 → 100,0 % | 0,00 → 0,00 |
| `lever` | t4 → t5 | ×1,33 | ×2,56 | 100,0 → 99,9 % | 0,00 → 2,40 |
| `lever_detector` | t5 → t6 | ×1,25 | ×1,79 | 99,8 → 75,4 % | 1,91 → 2,90 |
| `ring_combo` | t2 → t3 | ×1,37 | ×1,28 | 100,0 → 100,0 % | 0,00 → 0,00 |
| `warded` | t1 → t2 | ×1,29 | ×1,05 | 100,0 → 100,0 % | 0,00 → 0,00 |
| `dial_safe` | t1 → t2 | ×2,18 | ×1,38 | 100,0 → 100,0 % | 0,00 → 0,00 |
| `dial_safe` | t2 → t3 | ×1,60 | ×1,12 | 100,0 → 100,0 % | 0,00 → 0,00 |
| `combo` | t1 → t2 | ×1,17 | ×1,15 | 100,0 → 100,0 % | 0,00 → 0,00 |
| `combo` | t2 → t3 | ×1,19 | ×1,15 | 100,0 → 100,0 % | 0,00 → 0,00 |
| `combo` | t3 → t4 | ×1,16 | ×1,11 | 100,0 → 100,0 % | 0,00 → 0,00 |
| `dimple` | t1 → t2 | ×1,15 | ×1,88 | 100,0 → 100,0 % | 0,00 → 1,62 |
| `dimple` | t2 → t3 | ×1,26 | ×1,95 | 100,0 → 100,0 % | 1,62 → 3,92 |
| `disc_detainer` | t1 → t2 | ×1,40 | ×1,25 | 100,0 → 100,0 % | 0,00 → 0,00 |
| `disc_detainer` | t2 → t3 | ×1,13 | ×1,09 | 100,0 → 100,0 % | 0,00 → 0,00 |
| `egyptian` | t1 → t2 | ×1,62 | ×1,31 | 100,0 → 100,0 % | 0,00 → 0,00 |
| `axial_slider` | t1 → t2 | ×1,31 | ×1,46 | 100,0 → 100,0 % | 0,00 → 0,00 |
| `axial_slider` | t2 → t3 | ×1,24 | ×1,44 | 100,0 → 100,0 % | 0,00 → 0,06 |
| `time_lock` | t1 → t2 | ×1,43 | ×1,40 | 100,0 → 100,0 % | 0,00 → 0,00 |
| `magnetic` | t1 → t2 | ×1,43 | ×1,32 | 100,0 → 100,0 % | 0,00 → 0,00 |

Mediana bota czującego rośnie z tierem w każdej rodzinie (kryterium D-34 spełnione), skuteczność niezdarnego nie
rośnie nigdzie. Jedyny spadek w tabelach: bot skryptowy na `dimple` t1 → t2 (7,6 → 7,4 s), przy rosnących czasach
obu botów miękkich.

## 3. Kontekst progresji

### 3.1 Tier ze zlecenia a tier w grze

`JobRun.tier_for()` przekazuje `tier` z pliku zlecenia, a lockcore przycina go do zakresu rodziny. W 8 zleceniach
z zamkiem (i jednej odmowie) gracz dostaje więc inny tier niż zapisany:

| zapis w danych | w grze | zlecenia |
|---|---|---|
| `pin_tumbler` 1 | t2 | `student_dorm` (r. 1), `wrong_floor` (r. 2) |
| `lever` 1 | t3 | `pizzeria_pays_pizza` (r. 2) |
| `lever` 2 | t3 | `widow_bureau` (r. 3), odmowa `refuse_aunt_alive` |
| `warded` 3 | t2 | `grandpa_chest` (r. 3), `krakow_tenement_gate`, `swiatniki_journeyman_padlock` (r. 4) |
| `lever_detector` 2 | **t5** | `liege_bakery` (r. 5) |

### 3.2 Rozdziały

Zamki z odmów i rozmów pominięte (nie ma sceny zamka). Kolumny czasu: p50 tieru z §2 dla zamków rozdziału.

| rozdz. | zamków | czujący p50: min – mediana – max | niezdarny p50: min – mediana – max | zrzuty+oversety niezd. (średnia tieru): max | najtrudniejszy (niezdarny) | najłatwiejszy (czujący) |
|---|---|---|---|---|---|---|
| 1 | 5 | 11,0 – 14,6 – 21,1 s | 2,3 – 2,9 – 5,6 s | 0,00 | `combo` t1 | `pin_tumbler` t2 |
| 2 | 5 | 10,7 – 11,0 – 12,5 s | 2,9 – 3,0 – 3,1 s | 0,00 | `wafer` t1 | `magnetic` t1 |
| 3 | 5 | 12,5 – 16,8 – 20,2 s | 2,5 – 3,9 – 13,6 s | 0,00 | `dial_safe` t2 | `lever` t3 |
| 4 | 3 | 9,3 – 18,8 – 18,8 s | 2,5 – 2,5 – 9,8 s | 0,00 | `dial_safe` t1 | `dial_safe` t1 |
| 5 | 4 | 16,8 – 18,3 – 23,2 s | 2,5 – 5,9 – 11,3 s | 1,91 | `lever_detector` t5 | `wafer` t2 |
| 6 | 4 | 18,5 – 26,2 – 39,7 s | 6,1 – 7,2 – 9,7 s | 0,00 | `disc_detainer` t2 | `time_lock` t2 |
| 7 | 10 | 11,0 – 15,0 – 29,3 s | 2,3 – 3,4 – 11,3 s | 1,91 | `lever_detector` t5 | `pin_tumbler` t2 |
| 8 | 10 | 12,5 – 15,0 – 29,3 s | 2,3 – 3,9 – 11,3 s | 1,91 | `lever_detector` t5 | `lever` t3 |
| 9 | 6 | 11,0 – 19,0 – 24,7 s | 2,9 – 5,8 – 13,6 s | 1,62 | `dial_safe` t2 | `pin_tumbler` t2 |
| 10 | 6 | 12,5 – 20,5 – 39,7 s | 3,0 – 6,5 – 15,5 s | 3,92 | `dimple` t3 | `lever` t3 |
| 11 | 5 | 17,6 – 28,6 – 44,9 s | 4,7 – 7,3 – 10,5 s | 0,06 | `disc_detainer` t3 | `lever` t4 |
| 12 | 7 | 18,5 – 23,4 – 34,0 s | 7,0 – 12,1 – 33,1 s | 12,65 | `pin_tumbler` t6 | `time_lock` t2 |

Odczyt: do rozdz. 4 szorstka ręka nic nie kosztuje (0 zrzutów i oversetów). Pierwsze kary pojawiają się w rozdz. 5
(`dimple` t2, `lever_detector` t5), znikają w 6, wracają w 7–10, w 11 są bliskie zera i rosną skokowo w 12
(`pin_tumbler` t5/t6, `lever` t5). Czas bota czującego rośnie łagodniej: mediany 11–19 s w rozdz. 1–5, 15–29 s w 6–11, 23 s w 12.
Rozdz. 7 i 8 (po 10 zamków) mają mediany jak rozdz. 2–3, bo zaczynają się od t1/t2.

### 3.3 Zlecenie po zleceniu

Trzy ostatnie kolumny to boty na **tym konkretnym zamku** (seed zlecenia = `fnv1a64(id) % 1 000 000 + 1`, jak w
`JobRun.seed_for`), przez `replay_tool record <rodzina> <tier> <seed> … [--feel|--clumsy]`. Wszystkie 70 zamków
otwiera każdy z trzech botów.

| rozdz. | zlecenie | rodzina | tier w danych → w grze | czujący p50 (tier) | niezdarny p50 (tier) | ten zamek: skrypt. / czujący / niezdarny | niezdarny na tym zamku: zrzuty / oversety / fałsz. |
|---|---|---|---|---|---|---|---|
| 1 | `bike_interview` | `combo` | t1 | 21,1 s | 5,6 s | 8,6 s / 25,4 s / 5,9 s | 0 / 0 / 0 |
| 1 | `cat_bathroom` | `warded` | t1 | 14,6 s | 2,3 s | 3,2 s / 22,1 s / 2,4 s | 0 / 0 / 0 |
| 1 | `grandma_broth` | `warded` | t1 | 14,6 s | 2,3 s | 3,1 s / 7,1 s / 2,3 s | 0 / 0 / 0 |
| 1 | `kiosk_shutter` | `wafer` | t1 | 12,0 s | 3,1 s | 5,3 s / 13,0 s / 3,0 s | 0 / 0 / 0 |
| 1 | `refuse_ex_partner` | `pin_tumbler` | t2 | – | – | odmowa (bez zamka) | – |
| 1 | `student_dorm` | `pin_tumbler` | 1 → **t2** | 11,0 s | 2,9 s | 5,3 s / 9,7 s / 3,0 s | 0 / 0 / 0 |
| 2 | `drummer_locker` | `wafer` | t1 | 12,0 s | 3,1 s | 5,7 s / 10,7 s / 3,1 s | 0 / 0 / 0 |
| 2 | `newlyweds_4am` | `pin_tumbler` | t2 | 11,0 s | 2,9 s | 5,1 s / 11,0 s / 2,6 s | 0 / 0 / 0 |
| 2 | `night_nurse` | `magnetic` | t1 | 10,7 s | 3,0 s | 5,7 s / 11,1 s / 3,2 s | 0 / 0 / 0 |
| 2 | `pizzeria_pays_pizza` | `lever` | 1 → **t3** | 12,5 s | 3,0 s | 5,8 s / 15,6 s / 3,2 s | 0 / 0 / 0 |
| 2 | `refuse_rush_bribe` | `pin_tumbler` | t2 | – | – | odmowa (bez zamka) | – |
| 2 | `wrong_floor` | `pin_tumbler` | 1 → **t2** | 11,0 s | 2,9 s | 5,3 s / 13,1 s / 2,9 s | 0 / 0 / 0 |
| 3 | `allotment_shed` | `wafer` | t2 | 16,8 s | 3,9 s | 7,0 s / 19,1 s / 3,8 s | 0 / 0 / 0 |
| 3 | `dollhouse_wooden_lock` | `egyptian` | t1 | 13,4 s | 4,0 s | 7,0 s / 15,1 s / 4,1 s | 0 / 0 / 0 |
| 3 | `grandpa_chest` | `warded` | 3 → **t2** | 18,8 s | 2,5 s | 3,2 s / 13,7 s / 2,4 s | 0 / 0 / 0 |
| 3 | `refuse_aunt_alive` | `lever` | 2 → **t3** | – | – | odmowa (bez zamka) | – |
| 3 | `uncle_safe_heirs` | `dial_safe` | t2 | 20,2 s | 13,6 s | 15,4 s / 20,1 s / 13,6 s | 0 / 0 / 0 |
| 3 | `widow_bureau` | `lever` | 2 → **t3** | 12,5 s | 3,0 s | 5,7 s / 13,7 s / 3,2 s | 0 / 0 / 0 |
| 4 | `krakow_antiquarian` | `dial_safe` | t1 | 9,3 s | 9,8 s | 9,5 s / 7,9 s / 9,1 s | 0 / 0 / 0 |
| 4 | `krakow_tenement_gate` | `warded` | 3 → **t2** | 18,8 s | 2,5 s | 3,4 s / 16,5 s / 2,5 s | 0 / 0 / 0 |
| 4 | `swiatniki_journeyman_padlock` | `warded` | 3 → **t2** | 18,8 s | 2,5 s | 3,3 s / 19,4 s / 2,4 s | 0 / 0 / 0 |
| 5 | `brussels_townhouse` | `dimple` | t2 | 17,8 s | 7,9 s | 8,6 s / 20,4 s / 5,1 s | 0 / 0 / 1 |
| 5 | `charleroi_letters` | `wafer` | t2 | 16,8 s | 3,9 s | 6,8 s / 16,9 s / 3,8 s | 0 / 0 / 0 |
| 5 | `ghent_beguinage` | `warded` | t2 | 18,8 s | 2,5 s | 3,2 s / 39,9 s / 2,5 s | 0 / 0 / 0 |
| 5 | `liege_bakery` | `lever_detector` | 2 → **t5** | 23,2 s | 11,3 s | 8,7 s / 27,1 s / 9,3 s | 0 / 1 / 6 |
| 6 | `bramah_bureau` | `axial_slider` | t2 | 23,0 s | 6,1 s | 9,0 s / 19,5 s / 5,4 s | 0 / 0 / 1 |
| 6 | `finnish_sailor` | `disc_detainer` | t2 | 39,7 s | 9,7 s | 13,6 s / 40,0 s / 9,7 s | 0 / 0 / 2 |
| 6 | `museum_time_lock` | `time_lock` | t2 | 18,5 s | 7,0 s | 11,7 s / 20,9 s / 7,7 s | 0 / 0 / 0 |
| 6 | `time_capsule` | `combo` | t3 | 29,3 s | 7,3 s | 8,1 s / 39,7 s / 6,1 s | 0 / 0 / 0 |
| 7 | `halina_recipe_box` | `warded` | t1 | 14,6 s | 2,3 s | 3,1 s / 14,8 s / 2,3 s | 0 / 0 / 0 |
| 7 | `roman_service_cupboard` | `wafer` | t2 | 16,8 s | 3,9 s | 6,9 s / 13,9 s / 3,7 s | 0 / 0 / 0 |
| 7 | `marta_poster_studio` | `pin_tumbler` | t2 | 11,0 s | 2,9 s | 5,2 s / 12,5 s / 2,9 s | 0 / 0 / 0 |
| 7 | `zuzanna_catalogue_drawer` | `lever` | t3 | 12,5 s | 3,0 s | 5,6 s / 16,8 s / 2,8 s | 0 / 0 / 0 |
| 7 | `refuse_sisters_flat` | `pin_tumbler` | t2 | – | – | odmowa (bez zamka) | – |
| 7 | `stefan_book_tin` | `combo` | t3 | 29,3 s | 7,3 s | 8,4 s / 30,6 s / 6,2 s | 0 / 0 / 0 |
| 7 | `edek_rehearsal_store` | `lever_detector` | t5 | 23,2 s | 11,3 s | 8,6 s / 21,3 s / 17,1 s | 1 / 3 / 9 |
| 7 | `krystyna_wooden_album` | `egyptian` | t1 | 13,4 s | 4,0 s | 6,8 s / 17,2 s / 4,0 s | 0 / 0 / 0 |
| 7 | `refuse_unapproved_stockroom` | `wafer` | t2 | – | – | odmowa (bez zamka) | – |
| 7 | `gosia_workbench_drawer` | `lever` | t3 | 12,5 s | 3,0 s | 5,8 s / 10,4 s / 3,2 s | 0 / 0 / 0 |
| 7 | `community_notice_case` | `warded` | t2 | 18,8 s | 2,5 s | 3,3 s / 22,3 s / 2,5 s | 0 / 0 / 0 |
| 7 | `shared_room_door` | `pin_tumbler` | t3 | 15,4 s | 3,8 s | 7,0 s / 16,8 s / 4,0 s | 0 / 0 / 0 |
| 8 | `frozen_cellar_padlock` | `combo` | t2 | 24,7 s | 6,4 s | 7,3 s / 35,5 s / 5,6 s | 0 / 0 / 0 |
| 8 | `halina_christmas_tin` | `warded` | t1 | 14,6 s | 2,3 s | 3,1 s / 7,9 s / 2,2 s | 0 / 0 / 0 |
| 8 | `carol_singers_chest` | `egyptian` | t1 | 13,4 s | 4,0 s | 7,0 s / 11,4 s / 4,0 s | 0 / 0 / 0 |
| 8 | `refuse_wrong_letterbox` | `wafer` | t1 | – | – | odmowa (bez zamka) | – |
| 8 | `wigilia_table_drawer` | `lever` | t3 | 12,5 s | 3,0 s | 5,6 s / 16,2 s / 3,1 s | 0 / 0 / 0 |
| 8 | `heating_service_cupboard` | `pin_tumbler` | t3 | 15,4 s | 3,8 s | 6,9 s / 19,7 s / 3,9 s | 0 / 0 / 0 |
| 8 | `refuse_unapproved_repair` | `wafer` | t2 | – | – | odmowa (bez zamka) | – |
| 8 | `warm_room_for_neighbours` | `pin_tumbler` | t3 | 15,4 s | 3,8 s | 6,7 s / 13,9 s / 3,7 s | 0 / 0 / 0 |
| 8 | `winter_bicycle_cellar` | `combo` | t3 | 29,3 s | 7,3 s | 10,9 s / 28,0 s / 7,6 s | 0 / 0 / 0 |
| 8 | `wooden_winter_village` | `egyptian` | t1 | 13,4 s | 4,0 s | 6,8 s / 12,6 s / 4,0 s | 0 / 0 / 0 |
| 8 | `attic_drying_room` | `lever` | t3 | 12,5 s | 3,0 s | 5,6 s / 12,7 s / 3,1 s | 0 / 0 / 0 |
| 8 | `christmas_eve_heat` | `lever_detector` | t5 | 23,2 s | 11,3 s | 8,7 s / 21,1 s / 14,5 s | 1 / 2 / 9 |
| 9 | `t43_09_01_winter_keys` | `pin_tumbler` | t2 | 11,0 s | 2,9 s | 5,3 s / 10,9 s / 2,9 s | 0 / 0 / 0 |
| 9 | `t43_09_02_blanket_cupboard` | `magnetic` | t2 | 15,3 s | 4,0 s | 7,1 s / 16,8 s / 4,2 s | 0 / 0 / 0 |
| 9 | `t43_09_03_wooden_postbox` | `egyptian` | t2 | 21,8 s | 5,3 s | 9,8 s / 22,3 s / 5,6 s | 0 / 0 / 0 |
| 9 | `t43_09_04_choir_case` | `combo` | t2 | 24,7 s | 6,4 s | 6,2 s / 28,1 s / 4,6 s | 0 / 0 / 0 |
| 9 | `t43_09_05_receipt_safe` | `dial_safe` | t2 | 20,2 s | 13,6 s | 15,5 s / 20,9 s / 13,6 s | 0 / 0 / 1 |
| 9 | `t43_09_06_draughty_hall` | `dimple` | t2 | 17,8 s | 7,9 s | 9,0 s / 17,4 s / 5,5 s | 0 / 0 / 1 |
| 9 | `refuse_t43_09_empty_flat` | `pin_tumbler` | t3 | – | – | odmowa (bez zamka) | – |
| 9 | `t43_09_08_spare_key_hook` | `pin_tumbler` | t2 | – | – | rozmowa (bez zamka) | – |
| 10 | `t43_10_01_renovator_bureau` | `axial_slider` | t2 | 23,0 s | 6,1 s | 9,0 s / 21,8 s / 7,4 s | 0 / 0 / 5 |
| 10 | `t43_10_02_scaffold_store` | `disc_detainer` | t2 | 39,7 s | 9,7 s | 15,0 s / 36,3 s / 10,5 s | 0 / 0 / 1 |
| 10 | `t43_10_03_exhibit_clock` | `time_lock` | t2 | 18,5 s | 7,0 s | 9,9 s / 17,9 s / 6,8 s | 0 / 0 / 0 |
| 10 | `t43_10_04_design_cabinet` | `magnetic` | t2 | 15,3 s | 4,0 s | 7,1 s / 16,6 s / 4,2 s | 0 / 0 / 0 |
| 10 | `t43_10_05_porters_drawer` | `lever` | t3 | 12,5 s | 3,0 s | 5,7 s / 11,5 s / 3,1 s | 0 / 0 / 0 |
| 10 | `t43_10_06_shared_room_entry` | `dimple` | t3 | 22,4 s | 15,5 s | 9,9 s / 26,6 s / 10,9 s | 0 / 2 / 4 |
| 10 | `refuse_t43_10_early_clearance` | `lever` | t3 | – | – | odmowa (bez zamka) | – |
| 11 | `t43_11_01_wooden_market` | `egyptian` | t2 | 21,8 s | 5,3 s | 9,8 s / 22,2 s / 5,5 s | 0 / 0 / 0 |
| 11 | `t43_11_02_bicycle_stand` | `combo` | t3 | 29,3 s | 7,3 s | 10,0 s / 33,9 s / 7,1 s | 0 / 0 / 2 |
| 11 | `t43_11_03_tool_exchange` | `axial_slider` | t3 | 28,6 s | 8,7 s | 10,5 s / 25,6 s / 8,8 s | 0 / 0 / 6 |
| 11 | `t43_11_04_sailors_stall` | `disc_detainer` | t3 | 44,9 s | 10,5 s | 14,6 s / 34,8 s / 10,7 s | 0 / 0 / 2 |
| 11 | `t43_11_05_rehearsal_chest` | `lever` | t4 | 17,6 s | 4,7 s | 6,9 s / 16,8 s / 4,7 s | 0 / 0 / 2 |
| 11 | `refuse_t43_11_other_stall` | `wafer` | t3 | – | – | odmowa (bez zamka) | – |
| 11 | `t43_11_07_wrong_delivery` | `pin_tumbler` | t3 | – | – | rozmowa (bez zamka) | – |
| 12 | `t43_12_01_letters_archive` | `dial_safe` | t3 | 32,2 s | 15,2 s | 20,6 s / 33,7 s / 18,1 s | 0 / 0 / 6 |
| 12 | `t43_12_02_detective_cabinet` | `lever_detector` | t5 | 23,2 s | 11,3 s | 8,3 s / 22,9 s / 6,7 s | 0 / 0 / 5 |
| 12 | `t43_12_03_community_store` | `pin_tumbler` | t5 | 22,2 s | 14,0 s | 7,9 s / 19,2 s / 4,7 s | 0 / 0 / 0 |
| 12 | `t43_12_04_school_box` | `lever` | t5 | 23,4 s | 12,1 s | 9,9 s / 17,1 s / 9,2 s | 0 / 1 / 9 |
| 12 | `t43_12_05_tea_fund_case` | `combo` | t4 | 34,0 s | 8,2 s | 9,1 s / 35,6 s / 6,6 s | 0 / 0 / 1 |
| 12 | `refuse_t43_12_surprise_key` | `pin_tumbler` | t6 | – | – | odmowa (bez zamka) | – |
| 12 | `t43_12_07_clock_back_home` | `time_lock` | t2 | 18,5 s | 7,0 s | 11,9 s / 23,5 s / 8,0 s | 0 / 0 / 0 |
| 12 | `t43_12_08_henryks_bench` | `pin_tumbler` | t6 | 24,6 s | 33,1 s | 9,1 s / 27,9 s / 5,7 s | 0 / 0 / 0 |

### 3.4 Tryb ciągły

`RunState.tier_for(n) = clamp(int(1 + 1,2·ln(1 + n)), 1, 6)`: t2 od 3. zamka, t3 od 6., t4 od 13., t5 od 29.,
t6 od 65. Rodziny idą po kolei z `PHOTOREAL_READY` + `lever_detector`, tier przycięty do zakresu rodziny. Na t6
gracz dostaje więc `pin_tumbler` t6 (niezdarny 93,7 %), `lever` t5, `lever_detector` t6, a pozostałe rodziny na
swoim maksimum t2–t4, gdzie bot niezdarny nie myli się wcale. `pin_tumbler` t7 nie występuje nigdzie (zlecenia
kończą się na t6, tryb ciągły też).

## 4. Odstające

### 4.1 Uskoki między tierami

1. **`lever_detector` t5 → t6: niezdarny 99,87 % → 42,45 %** (5755 zablokowanych zamków na 10 000), przy czym
   bot czujący prawie się nie zmienia (99,97 → 99,96 %, 23 → 29 s; po zmianie 99,95 %). To największy uskok w danych i jedyny tier ≤ 6,
   w którym szorstka ręka przegrywa częściej niż wygrywa; sąsiad z tego samego tieru w trybie ciągłym,
   `pin_tumbler` t6, ma 93,7 %. Uskok jest progiem, nie stopniem trudności: ustawiona dźwignia idzie za podnośnikiem
   0,6/s, przez 250 ms reakcji to 0,15 + drżenie, a zapas t6 (bramka 0,08 + margines detektora 0,083) to 0,163.
   Czułość na samą szerokość bramki (10 000 seedów; ostatnia wartość 3000): 0,080 → 42 %, 0,083 → 64 %,
   0,085 → 75 %, 0,087 → 86 %, 0,090 (jak t5) → 93,5 %. Sam margines detektora 0,083 → 0,090 / 0,100 daje 72 / 82 %
   (3000 seedów), ale wymagałby nowej złotej powtórki. **Zmienione, §5.**
2. **`pin_tumbler` t6 → t7: 93,66 % → 35,97 %**, wszystkie porażki to brak czasu (6402), 29 oversetów na zamek.
   Tier nie jest używany w grze (§3.4). Bez zmian; zostaje jako tier „mistrzowski” do decyzji przy treści t7.
3. `pin_tumbler` t4 → t5 (czas niezdarnego ×2,8) i t5 → t6 (×2,4, brak czasu 7 → 631), `lever` t4 → t5 (×2,6):
   to wejście szpulek i fałszywych bramek. W zleceniach trafia na rozdz. 11 → 12 (finał), więc skok jest w dobrym
   miejscu.
4. `dimple` t2 → t3: czas niezdarnego ×2,3 przed zmianą (7,9 → 18,1 s), zrzuty 0,36 → 1,72. Patrz 4.2.
5. `dial_safe` t1 → t2: największy krok bota czującego (×2,2; 9,3 → 20,2 s). t1 ma 2 koła i 20 działek: bot
   słuchający jest tam szybszy od skryptowego (9,3 s wobec 10,7 s), czyli szukania prawie nie ma.

### 4.2 Na tle sąsiadów z rozdziału

1. **`dimple` t3 w rozdz. 10** (`t43_10_06_shared_room_entry`). Przed zmianą: niezdarny p50 18,1 s, p90 30,7 s,
   1,72 zrzutu i 3,04 oversetu na zamek. Pozostałe zamki rozdziału: 3,0–9,7 s i 0 zrzutów. To było więcej niż
   `pin_tumbler` t5 z rozdz. 12 (14,0 s; 1,67; 2,44) i więcej niż wszystko w rozdz. 11. Przyczyny: (a) w `dimple`
   każdy kołek zabezpieczony jest teleskopowy (reguła szpulki), w `pin_tumbler` t4–t6 połowa to ząbkowane; t3 ma
   ich 1–2, średnio 1,5 — więcej niż `pin_tumbler` t6 (1,25 szpulki); (b) generator włącza „zrzut wszystkich
   kołków” od tieru 3 (reguła pisana pod tabelę `pin_tumbler` t2–t7), więc w `dimple` trafia dokładnie w t3;
   (c) `drop_grace` 220 ms jest krótszy niż reakcja bota (250 ms), więc poprawka oversetu kosztowała zrzut całości.
   **Zmienione, §5.**
2. **`lever_detector` t5 w rozdz. 5, 7 i 8.** `liege_bakery` ma w danych tier 2, w grze t5 (§3.1); `edek_rehearsal_store`
   i `christmas_eve_heat` mają t5 wprost. Niezdarny: 11,3 s, 7,5 fałszywego ustawienia i 1,9 zrzutu + oversetu na
   zamek; mediany tych rozdziałów to 3,4–5,9 s i 0. To też jedyny zamek przed rozdz. 12, który bot potrafi
   zablokować na stałe (13 / 10 000 niezdarny, 3 / 10 000 czujący). `lever` t5 — ta sama mechanika bez detektora —
   pojawia się dopiero w rozdz. 12. Tabelą tierów nie da się tego poprawić (rodzina zaczyna się na t5); §6.
3. **`disc_detainer` (rozdz. 6, 10, 11).** Bot czujący: 28 / 40 / 45 s — najdłużej w każdym rozdziale, w którym
   jest (rozdz. 6: reszta 18,5–29,3 s; rozdz. 10: 12,5–23,0 s; rozdz. 11: 17,6–29,3 s), p90 to 39–42 % limitu
   (najwyżej w tabeli razem z `warded` t2 i `wafer` t3). Skryptowy też najdłużej (13,5–14,7 s). Brak porażek, brak
   kar dla niezdarnego. Czas to liczba tarcz × 8 pozycji i sondowanie oporu, którego człowiek nie musi robić na
   ślepo. Bez zmian; do sprawdzenia w testach z graczami (§6).
4. **Dołek w rozdz. 4.** Dwa `warded` „tier 3” (w grze t2) i `dial_safe` t1 po `dial_safe` t2 z rozdz. 3:
   mediana niezdarnego 2,5 s (rozdz. 3: 3,9 s), najłatwiejszy zamek bota czującego 9,3 s (rozdz. 3: 12,5 s).
   `warded` jest najszybszą rodziną dla każdego bota (niezdarny 2,3–2,5 s, krok t1 → t2 ×1,05) i nie ma tieru 3.

### 4.3 Tiery, w których szorstka ręka nic nie kosztuje

Kryterium: niezdarny 100 %, 0,00 zrzutu i oversetu na zamek, czas niezdarnego ≤ 0,4 czasu czującego. Spełnia je
**28 z 41** wierszy: `pin_tumbler` t2–t3, `wafer` t1–t3, `wooden_pin` t1, `lever` t3–t4, `ring_combo` t2–t3,
`warded` t1–t2, `combo` t1–t4, `dimple` t1, `disc_detainer` t1–t3, `egyptian` t1–t2, `axial_slider` t1–t2,
`time_lock` t1–t2, `magnetic` t1–t2. Blisko: `axial_slider` t3 (0,06 kary na zamek), `dial_safe` t1–t3 (0 kar,
stosunek czasów 0,47–1,06).

W tych tierach bot niezdarny jest 2,5–8 razy szybszy od czującego i nie płaci nic. Częściowo to cecha miernika
(§1: zwykłe okno nie może go ukarać, napięcie bierze z planu). Rzetelny wniosek jest węższy: **w tych tierach
jedynym kosztem szorstkiej gry jest złamanie narzędzia, a tego żaden bot nie sprawdza.** W rozdz. 9–11 dotyczy to
większości zamków: `magnetic` t2, `egyptian` t2, `time_lock` t2, `combo` t2–t3, `disc_detainer` t2–t3, `lever`
t3–t4, `axial_slider` t2–t3. Bez zmian w tabelach: dane nie mówią, czy i w którą stronę je ruszyć; §6.

## 5. Zmiany (D-116)

Tylko tabele tierów (`difficulty_for_tier`), po jednej liczbie w dwóch wierszach. Reguły, generator,
`rules_version` i model stałoprzecinkowy bez zmian.

| rodzina | tier | parametr | było | jest | dlaczego |
|---|---|---|---|---|---|
| `dimple` | t3 | `drop_grace` | 220 ms | 250 ms (jak t2) | 4.2.1: poprawka oversetu nie zrzuca już wszystkich kołków przy reakcji 250 ms |
| `lever_detector` | t6 | okno bramki (`win_shear`) | 0,080 | 0,085 | 4.1.1: zapas na reakcję 0,163 → 0,168; uskok t5 → t6 z −57 do −24 pkt proc. |

| rodzina | tier | bot | przed | po |
|---|---|---|---|---|
| `dimple` | t3 | skryptowy | porażki 0, p50 8,9 s, max 10,7 s | porażki 0, p50 8,9 s, max 10,7 s |
| | | czujący | 9996/10000, p50 22,4 s, p90 28,2 s, oversety 0,04, fałsz. 1,52, brak czasu 4, blokady 0 | 9996/10000, p50 22,4 s, p90 28,3 s, oversety 0,04, fałsz. 1,52, brak czasu 4, blokady 0 |
| | | niezdarny | 100,0 %, p50 18,1 s, p90 30,7 s, zrzuty 1,72, oversety 3,04, fałsz. 4,70, brak czasu 0, blokady 0 | 100,0 %, p50 15,5 s, p90 24,9 s, zrzuty 0,89, oversety 3,03, fałsz. 4,62, brak czasu 0, blokady 0 |
| `lever_detector` | t6 | skryptowy | porażki 0, p50 12,2 s, max 14,8 s | porażki 0, p50 12,2 s, max 14,8 s |
| | | czujący | 9996/10000, p50 29,1 s, p90 36,7 s, oversety 0,05, fałsz. 7,47, brak czasu 0, blokady 4 | 9995/10000, p50 29,1 s, p90 36,5 s, oversety 0,05, fałsz. 7,46, brak czasu 0, blokady 5 |
| | | niezdarny | 42,4 %, p50 21,9 s, p90 30,4 s, zrzuty 0,35, oversety 3,18, fałsz. 11,75, brak czasu 0, blokady 5755 | 75,4 %, p50 20,2 s, p90 28,4 s, zrzuty 0,35, oversety 2,54, fałsz. 13,98, brak czasu 0, blokady 2458 |

- `dimple` t3: zrzuty o połowę (1,72 → 0,89, poziom `pin_tumbler` t4: 0,86), p90 30,7 → 24,9 s. Bot czujący bez
  zmian, więc zamek nie jest łatwiejszy dla uważnego gracza. Nadal jest najtrudniejszym zamkiem rozdz. 10 dla
  niezdarnego (15,5 s) — reszta to szpulki i zrzut wszystkich kołków, czyli generator, nie tabela. `drop_grace`
  nie może być dłuższy niż w t2 (250 ms). Próby na 10 000 seedów: 270 ms → 14,3 s i 0,44 zrzutu; 300 ms → 13,1 s
  i 0,05; jeden kołek teleskopowy zamiast 1–2 (przy 250 ms) → 14,2 s, 0,76 zrzutu, 2,48 oversetu.
- `lever_detector` t6: 42,4 → 75,4 %. Każdy parametr t6 pozostaje nie łatwiejszy niż w t5 (bramka 0,085 < 0,090,
  margines detektora 0,083 < 0,10, 6 dźwigni, reset 2,5 s). Tier nie występuje w zleceniach; w trybie ciągłym od
  65. zamka. Margines detektora (0,083, D-34) bez zmian, więc overset nadal ostrzega przed detektorem.
- **Złote powtórki bez zmian.** Powtórka niesie własny wektor trudności, a generator i `rules_version` są te
  same, więc `dimple_t3_s21_feel` (zapis z `drop_grace` 220 ms) i `lever_detector_t6_s8_feel_reset` (bramka 0,080)
  odtwarzają się z tym samym hashem. Ślady lockviz też.
- Zamek zlecenia `t43_10_06_shared_room_entry` (`dimple` t3) ma te same kołki, okna i szpulki; zmienia się tylko
  czas łaski zrzutu.

Sprawdzone i odrzucone: limit czasu `wafer` 60 / 60 / 60 s → 60 / 75 / 90 s (jedyna rodzina z płaskim limitem,
p90 bota czującego 43 % limitu na t3). Zero wpływu na wyniki, a limitu gra nie egzekwuje — to tylko budżet botów.

## 6. Rekomendacje (bez zmian w kodzie)

Decyzje o treści i zakresie należą do właściciela; dane zleceń są poza tym zadaniem.

1. **`liege_bakery` (rozdz. 5): `lever_detector` „tier 2” to w grze t5.** Albo zamienić na `lever` t3/t4, albo
   świadomie zostawić jako pierwszy trudny zamek i dopisać w danych tier 5. Podobnie `edek_rehearsal_store`
   (rozdz. 7, środek rozdziału). `christmas_eve_heat` jako finał rozdz. 8 jest na miejscu.
2. **Zapis tieru spoza zakresu rodziny** (§3.1) powinien być błędem walidatora danych (`data/tools/validate.py`),
   żeby tier w pliku znaczył to, co gracz dostaje. `warded` 3 w rozdz. 3–4 sugeruje, że autor chciał czegoś
   trudniejszego niż t2.
3. **`dial_safe` t1 w rozdz. 4 po t2 w rozdz. 3** — kolejność odwrócona względem trudności.
4. **`dimple` t3**: jeśli w testach z graczami nadal będzie odstawał w rozdz. 10, następny krok to jeden kołek
   teleskopowy (liczby w §5) albo przeniesienie zlecenia do rozdz. 11–12.
5. **`disc_detainer`**: w testach zmierzyć czas na t2. Jeśli ludzie też potrzebują ok. 1,5× więcej niż na
   sąsiednich zamkach, t2 4–5 tarcz zamiast 5.
6. **Bot „ciężkiej ręki”** (napięcie ponad `tau_safe`, bez reakcji na `stress`) jako czwarty miernik w
   `verify_seeds`. Bez niego nie da się kalibrować tierów z §4.3 ani `S_max`.
7. **`pin_tumbler` t7** (36 %) i ewentualne wejście `lever_detector` t6 do zleceń: zdecydować przy treści tych
   tierów; czułość z 4.1.1 daje gotowe liczby.

## 7. Jak powtórzyć

```bash
cmake -S lockcore -B lockcore/build && cmake --build lockcore/build
lockcore/build/verify_seeds --seeds 10000 --csv out.csv         # ok. 3 min na 1 rdzeniu; tabele 2.1–2.3
lockcore/build/verify_seeds --seeds 10000 --family dimple --tier 3
lockcore/build/replay_tool record dimple 3 <seed> out.replay.json --clumsy   # jeden zamek zlecenia (§3.3)
```

Kolumny CSV dopisane w D-116: `clumsy_p50`, `clumsy_p90`, `clumsy_drops`, `clumsy_oversets`, `clumsy_false_sets`,
`clumsy_breaks`, `clumsy_timeouts`, `clumsy_overstress`, `clumsy_trips`, `feel_drops`, `feel_oversets`,
`feel_false_sets`, `feel_breaks`, `feel_timeouts`, `feel_trips`, `time_limit_steps`, `clumsy_ok`, `feel_ok`
(sumy po wszystkich przebiegach danego bota; czasy w krokach 1/120 s).
