# Poziomy — zamki autorskie i profile proceduralne

Status: projekt poziomów, 2026-11-04. Dotyczy rodzin zaimplementowanych w lockcore v0.1: `pin_tumbler` (rules_version 1) i `wafer` (rules_version 1). Powiązane: `ONBOARDING.md` (storyboardy S1–S3), `LOCKS.md` §1.5–1.9 i §2.4/§2.6, `PROGRESSION.md`, `lockcore/README.md`, decyzje D-16, D-17, D-18, D-21–D-23.

Spis treści
1. Konwencje i jak to sprawdzono
2. `pin_tumbler`: samouczek, lekcje wtrącone, zamki testowe A1/A2
3. `pin_tumbler`: 5 zamków mistrzowskich
4. `wafer`: samouczek i 3 zamki mistrzowskie
5. Profile proceduralne (wektor trudności)
6. Wyniki weryfikacji
7. Przykład pliku `lockwright.lock/1`
8. Luki w lockcore v0.1 (prośby do programisty)

---

## 1. Konwencje i jak to sprawdzono

- **Pola** są dokładnie polami bloku `spec` z `lockwright.lock/1` (`params_to_json` w `src/families/pin_tumbler.cpp` i `wafer.cpp`). W tabelach podajemy wartość dziesiętną i w nawiasie liczbę Q16, którą wpisuje się do pliku (`*_q16`, `x · 65536`, zaokrąglenie do najbliższej, jak `q16_milli`). Czasy: `drop_grace_steps` = ms × 0,12 (120 Hz). W tabelach parametrów zamków używam kropki dziesiętnej, jak w danych.
- **Indeks elementu 0 = przód kanału** (wejście), ostatni = najgłębszy. `element_center(i, n)` przypisuje głębokość wytrycha do elementu z „magnesem” ±30% podziałki.
- **`order`** służy w zamkach autorskich tylko do porównań: wiąże nieustawiony element o najmniejszym `order` (dwa równe `order` = para multi-bind, w `pin_tumbler` najwyżej dwa). Wartość `bind_spread` w bloku `difficulty` zamka autorskiego to tylko opis.
- **Pasmo pracy** elementu (to, co gracz musi trafić napięciem): `pin_tumbler` `[max(t_hold, band_lo), min(band_lo + tension_band, tau_safe)]`; `wafer` `[max(t_release, band_lo), min(band_lo + tension_band, tau_safe)]`. Kolumna `band_lo → t_stick` pokazuje dolną i górną granicę „kołek idzie”.
- **Stałe rodzin**, których nie zmieniamy w zamkach autorskich (żeby czucie było wspólne): `pin_tumbler` `t_hold` 0,10, `t_release` 0,05, `bound_speed` 2/s (1092), `spool_speed` 0,6/s (327), `stress_gain` 0,095 (6226), materiał `brass`; `wafer` `t_hold` 0,08, `t_release` 0,16, `bound_speed` 1092, `stress_gain` 0,095, materiał `steel`. Wyjątki są opisane przy zamku (`wafer.s3`: podwójny `stress_gain`, `pin.m1`: węższe pasmo kontrrotacji).
- **`tau_safe`** zamków autorskich = `max(band_lo) + tension_band + 0,06` (jak generator), chyba że zamek celowo uczy górnej granicy (`wafer.s3`) albo nie może łamać (S1/S2: 1,0).
- **Weryfikacja.** Każdy zamek z tego dokumentu wczytałem przez `lock_from_json`, przepuściłem przez `validate()`, wyrocznię (`oracle`) i bota skryptowego (`solver`, 200 seedów bota), a dodatkowo przez bota „niezdarnego” (`clumsy_human_limits`, budżet = pełny `time_limit_s`). Każdy profil z §5 przepuściłem przez `generate()` + wyrocznię + oba boty na 1 000 seedów. Narzędzie było tymczasowe (poza repo). Wyniki są w §6. Docelowo te same sprawdzenia robi CI (§8, prośba 1).
- **Czasy dla człowieka** to cel projektowy (`LOCKS.md` §1.8), a nie pomiar. Boty mieszczą się w 2–12 s, ale grają z planem wyroczni.

## 2. `pin_tumbler`: samouczek, lekcje wtrącone, zamki testowe A1/A2

### 2.1 `pin.s1` — „Jeden kołek” / „One Pin”

- **Cel:** napięcie + unoszenie = ustawienie = otwarcie. Jeden sygnał naraz, nic nie może się nie udać na stałe.
- **Czas (nowicjusz):** 20–40 s. **Pułapka:** brak. Jedyny błąd to za duże napięcie (T > 0,60: kołek „nie idzie”) albo za małe (< 0,15: kołek luźny). Oba mają diagnozę w eskalacji (`ONBOARDING.md` §4, S1 1.3).
- **Prezentacja (poza lockcore):** `fb_gain` ×1,5, pełna kreda.

`win_shear` 0.2 (13107) · `overset_margin` 0.16 (10486) · `tension_band` 0.45 (29491) · `t_hold` 0.1 (6554) · `t_release` 0.05 (3277) · `tau_safe` 1 (65536) · `cr_lo` 0.12 (7864) · `cr_hi` 0.21 (13763) · `s_max` 1 (65536) · `stress_gain` 0.095 (6226) · `noise` 0 (0) · `drop_grace_steps` 72 (600 ms) · `drop_all` false

| # | `target` | okno (lo–hi) | `order` | `band_lo` → `t_stick` | `variant` | `false_gate` | `serrations` |
|---|---|---|---|---|---|---|---|
| 0 | 0.55 (36045) | 0.450–0.650 | 0 (0) | 0.15 (9830) → 0.60 | standard | — | — |

### 2.2 `pin.s2` — „Trzy po kolei” / „Three in Turn”

- **Cel:** wiąże zawsze jeden kołek, trzeba go znaleźć dotykiem. Kolejność od przodu (0 → 1 → 2), żeby pierwsze szukanie było intuicyjne. Łagodny zrzut (`drop_all` false: przy puszczeniu spada tylko ostatni).
- **Czas:** 30–60 s. **Pułapka:** łagodna, zrzut ostatniego kołka po puszczeniu napięcia na 500 ms.
- **Prezentacja:** `fb_gain` ×1,3, kreda tylko na linii podziału i klamra.

`win_shear` 0.16 (10486) · `overset_margin` 0.12 (7864) · `tension_band` 0.4 (26214) · `t_hold` 0.1 (6554) · `t_release` 0.05 (3277) · `tau_safe` 1 (65536) · `cr_lo` 0.12 (7864) · `cr_hi` 0.21 (13763) · `s_max` 1 (65536) · `stress_gain` 0.095 (6226) · `noise` 0 (0) · `drop_grace_steps` 60 (500 ms) · `drop_all` false

| # | `target` | okno (lo–hi) | `order` | `band_lo` → `t_stick` | `variant` | `false_gate` | `serrations` |
|---|---|---|---|---|---|---|---|
| 0 | 0.5 (32768) | 0.420–0.580 | 0 (0) | 0.15 (9830) → 0.55 | standard | — | — |
| 1 | 0.58 (38011) | 0.500–0.660 | 0.1 (6554) | 0.16 (10486) → 0.56 | standard | — | — |
| 2 | 0.46 (30147) | 0.380–0.540 | 0.2 (13107) | 0.15 (9830) → 0.55 | standard | — | — |

### 2.3 `pin.s3` — „Nie od przodu” / „Not Front First”

- **Cel:** kolejność nieoczywista (tył → przód → środek) i pierwsza pułapka rodziny: **przepchnięcie**. Zapas do overset tylko 0,08 (w t2 jest 0,10), a okno 0,12 jak w t2. Wyjście z overset to T < 0,05, a to przy `drop_all` true zrzuca wszystko. Gracz uczy się „po kliknięciu przestań pchać” i „za wysoko = od nowa, lżej”. Tu pojawia się lupa.
- **Czas:** 40–90 s. **Pułapka:** overset kołka 2 (pierwszego, najgłębszego) albo 1 (cel 0,55, górna granica przed overset 0,69).
- **Prezentacja:** `fb_gain` ×1,15, kreda tylko jako H3.

`win_shear` 0.12 (7864) · `overset_margin` 0.08 (5243) · `tension_band` 0.3 (19661) · `t_hold` 0.1 (6554) · `t_release` 0.05 (3277) · `tau_safe` 0.57 (37356) · `cr_lo` 0.12 (7864) · `cr_hi` 0.21 (13763) · `s_max` 1 (65536) · `stress_gain` 0.095 (6226) · `noise` 0 (0) · `drop_grace_steps` 42 (350 ms) · `drop_all` true

| # | `target` | okno (lo–hi) | `order` | `band_lo` → `t_stick` | `variant` | `false_gate` | `serrations` |
|---|---|---|---|---|---|---|---|
| 0 | 0.48 (31457) | 0.420–0.540 | 0.1 (6554) | 0.2 (13107) → 0.50 | standard | — | — |
| 1 | 0.55 (36045) | 0.490–0.610 | 0.2 (13107) | 0.21 (13763) → 0.51 | standard | — | — |
| 2 | 0.62 (40632) | 0.560–0.680 | 0 (0) | 0.2 (13107) → 0.50 | standard | — | — |

### 2.4 `pin.l_spool` — lekcja wtrącona „Szpulka” / „The Spool”

- **Kiedy:** przed pierwszym zamkiem serii z profilu P06 (pierwsze zabezpieczenie).
- **Cel:** `false_set` (rdzeń +2 podziałki, głuchy podwójny klik, talia na linii podziału) i `counter_rotate`; wyjście = lekko odpuścić do pasma 0,12–0,21 i dopchnąć. Szpulka jest drugim kołkiem w kolejności (środek), więc gracz najpierw ustawia zwykły kołek i ma porównanie.
- **Czas:** 30–60 s. **Pułapka:** odpuszczenie za mocno (T < 0,10 przez 350 ms) zrzuca wszystko; nieodpuszczenie: szpulka nie idzie, a powyżej 0,21 rośnie naprężenie wytrycha.
- **Wariant „ząbki”** (`pin.l_serrated`): ten sam zamek, stos 1 jako `serrated` z progami 0,30 / 0,38 / 0,46 zamiast szpulki. Uczy: drobne kliknięcie bez obrotu rdzenia to nie `set`. Pokazywany, jeśli pierwszym zabezpieczeniem w serii jest kołek ząbkowany (generator v0.1 losuje 50/50).

`win_shear` 0.12 (7864) · `overset_margin` 0.1 (6554) · `tension_band` 0.26 (17039) · `t_hold` 0.1 (6554) · `t_release` 0.05 (3277) · `tau_safe` 0.53 (34734) · `cr_lo` 0.12 (7864) · `cr_hi` 0.21 (13763) · `s_max` 1 (65536) · `stress_gain` 0.095 (6226) · `noise` 0 (0) · `drop_grace_steps` 42 (350 ms) · `drop_all` true

| # | `target` | okno (lo–hi) | `order` | `band_lo` → `t_stick` | `variant` | `false_gate` | `serrations` |
|---|---|---|---|---|---|---|---|
| 0 | 0.5 (32768) | 0.440–0.560 | 0 (0) | 0.2 (13107) → 0.46 | standard | — | — |
| 1 | 0.6 (39322) | 0.540–0.660 | 0.1 (6554) | 0.21 (13763) → 0.47 | spool | 0.46 (30147) | — |
| 2 | 0.52 (34079) | 0.460–0.580 | 0.2 (13107) | 0.2 (13107) → 0.46 | standard | — | — |

### 2.5 Zamki testowe A1 i A2

- **`pin.a1`** (`ONBOARDING.md` §5, test A1): dokładna kopia `gen.pin_tumbler.t2.1` (generator t2, seed 1, rules_version 1), zapisana jako `source: authored`, `id: pin.a1`, żeby test był powtarzalny po zmianach generatora. Kolejność: środek → tył → przód. `drop_all` false (t2). Czas docelowy: < 90 s (A1).
- **`pin.a2`** (test A2, „w ciemności”): kopia `gen.pin_tumbler.t2.2`. Kolejność: środek → przód → tył (inna niż w A1, żeby gracz nie odtwarzał z pamięci). Stosy (`target / order / band_lo`, Q16): 0: 38823 / 6554 / 15725; 1: 39591 / 0 / 14602; 2: 29131 / 13108 / 15407; `tau_safe` 38007; reszta jak `pin.a1`. Okna w trybie „w ciemności” ×1,15 nakłada warstwa gry (`LOCKS.md` §1.7), nie plik. Czas docelowy: < 3 min (A2).

`win_shear` 0.12 (7864) · `overset_margin` 0.1 (6554) · `tension_band` 0.28 (18350) · `t_hold` 0.1 (6554) · `t_release` 0.05 (3277) · `tau_safe` 0.577 (37843) · `cr_lo` 0.12 (7864) · `cr_hi` 0.21 (13763) · `s_max` 1 (65536) · `stress_gain` 0.095 (6226) · `noise` 0 (0) · `drop_grace_steps` 36 (300 ms) · `drop_all` false

| # | `target` | okno (lo–hi) | `order` | `band_lo` → `t_stick` | `variant` | `false_gate` | `serrations` |
|---|---|---|---|---|---|---|---|
| 0 | 0.651 (42683) | 0.591–0.711 | 0.2 (13108) | 0.234 (15341) → 0.51 | standard | — | — |
| 1 | 0.563 (36887) | 0.503–0.623 | 0 (0) | 0.214 (14009) → 0.49 | standard | — | — |
| 2 | 0.426 (27950) | 0.366–0.486 | 0.1 (6554) | 0.237 (15561) → 0.52 | standard | — | — |

## 3. `pin_tumbler`: 5 zamków mistrzowskich

Wspólne: materiał `brass`, `drop_all` true, stałe rodziny. Odblokowanie: po ukończeniu profilu z tym samym tierem (§5). Wyzwanie „Mistrz rodziny” (`PROGRESSION.md` §5): wszystkie 5 bez złamania. Każdy mistrzowski uczy jednej rzeczy, której generator v0.1 nie zrobi celowo.

### 3.1 `pin.m1` — „Dwie szpulki” / „Two Spools” (poziom t5)

- **Cel:** dwie szpulki **pod rząd** na początku kolejności (stos 1, potem 2) i pasmo kontrrotacji zwężone do 0,13–0,21 (dokładnie δ_human 0,08). Gracz musi dwa razy z rzędu „oddać” rdzeń bez zrzutu.
- **Czas:** 2–4 min. **Pułapka:** po pierwszym `false_set` rdzeń jest obrócony głęboko, a pozostałe stosy luźne, co wygląda jak postęp. Gracz unosi inne kołki zamiast dokończyć szpulkę. Druga szpulka natychmiast powtarza wzór, a gracz zmęczony pierwszą odpuszcza za mocno (zrzut wszystkiego).

`win_shear` 0.1 (6554) · `overset_margin` 0.08 (5243) · `tension_band` 0.2 (13107) · `t_hold` 0.1 (6554) · `t_release` 0.05 (3277) · `tau_safe` 0.49 (32113) · `cr_lo` 0.13 (8520) · `cr_hi` 0.21 (13763) · `s_max` 1 (65536) · `stress_gain` 0.095 (6226) · `noise` 0.05 (3277) · `drop_grace_steps` 24 (200 ms) · `drop_all` true

| # | `target` | okno (lo–hi) | `order` | `band_lo` → `t_stick` | `variant` | `false_gate` | `serrations` |
|---|---|---|---|---|---|---|---|
| 0 | 0.5 (32768) | 0.450–0.550 | 0.2 (13107) | 0.21 (13763) → 0.41 | standard | — | — |
| 1 | 0.58 (38011) | 0.530–0.630 | 0 (0) | 0.2 (13107) → 0.40 | spool | 0.45 (29491) | — |
| 2 | 0.62 (40632) | 0.570–0.670 | 0.1 (6554) | 0.22 (14418) → 0.42 | spool | 0.48 (31457) | — |
| 3 | 0.47 (30802) | 0.420–0.520 | 0.3 (19661) | 0.2 (13107) → 0.40 | standard | — | — |
| 4 | 0.55 (36045) | 0.500–0.600 | 0.4 (26214) | 0.23 (15073) → 0.43 | standard | — | — |

### 3.2 `pin.m2` — „Ząbki kłamią” / „Lying Teeth” (poziom t5)

- **Cel:** 3 z 5 stosów ząbkowane (3–4 progi każdy), a wiążą na zmianę ze zwykłymi (1 → 2 → 4 → 0 → 3). Uczy: `pin.serration` to drobny klik **bez obrotu rdzenia**. Prawdziwy `set` zawsze przesuwa skalę na czole o podziałkę.
- **Czas:** 2–3 min. **Pułapka:** gracz po pierwszym ząbku uznaje kołek za ustawiony, przechodzi dalej i szuka wiązania, którego nie ma (dalej wiąże ten sam ząbkowany). Ostatni stos (3) ma cztery progi, a ostatni z nich jest 0,02 pod oknem, więc klik ząbka i `set` przychodzą prawie razem.

`win_shear` 0.1 (6554) · `overset_margin` 0.08 (5243) · `tension_band` 0.2 (13107) · `t_hold` 0.1 (6554) · `t_release` 0.05 (3277) · `tau_safe` 0.49 (32113) · `cr_lo` 0.12 (7864) · `cr_hi` 0.21 (13763) · `s_max` 1 (65536) · `stress_gain` 0.095 (6226) · `noise` 0.05 (3277) · `drop_grace_steps` 24 (200 ms) · `drop_all` true

| # | `target` | okno (lo–hi) | `order` | `band_lo` → `t_stick` | `variant` | `false_gate` | `serrations` |
|---|---|---|---|---|---|---|---|
| 0 | 0.6 (39322) | 0.550–0.650 | 0.3 (19661) | 0.2 (13107) → 0.40 | serrated | — | 0.36, 0.43, 0.50 |
| 1 | 0.52 (34079) | 0.470–0.570 | 0 (0) | 0.22 (14418) → 0.42 | standard | — | — |
| 2 | 0.62 (40632) | 0.570–0.670 | 0.1 (6554) | 0.21 (13763) → 0.41 | serrated | — | 0.37, 0.44, 0.51 |
| 3 | 0.58 (38011) | 0.530–0.630 | 0.4 (26214) | 0.2 (13107) → 0.40 | serrated | — | 0.34, 0.40, 0.46, 0.51 |
| 4 | 0.48 (31457) | 0.430–0.530 | 0.2 (13107) | 0.23 (15073) → 0.43 | standard | — | — |

### 3.3 `pin.m3` — „Bliźniaki” / „Twins” (poziom t6)

- **Cel:** dwie pary multi-bind (stosy 1+2 i 4+5 wiążą naraz) i szpulka między nimi, przy szumie kontaktów 0,10. Uczy: „dwa stawiają opór naraz”, trzeba ustawić oba, zanim ruszy kolejny. Szum dodaje fałszywe „tiki” sąsiadów, więc liczy się opór, a nie sam dźwięk kontaktu.
- **Czas:** 3–5 min. **Pułapka:** po ustawieniu jednego z bliźniaków gracz szuka nowego wiązania gdzie indziej, a ono jest tuż obok. Druga para stoi zaraz po szpulce, więc nerwowe odpuszczanie po kontrrotacji zrzuca całą pierwszą parę.

`win_shear` 0.09 (5898) · `overset_margin` 0.07 (4588) · `tension_band` 0.18 (11796) · `t_hold` 0.1 (6554) · `t_release` 0.05 (3277) · `tau_safe` 0.47 (30802) · `cr_lo` 0.12 (7864) · `cr_hi` 0.21 (13763) · `s_max` 1 (65536) · `stress_gain` 0.095 (6226) · `noise` 0.1 (6554) · `drop_grace_steps` 24 (200 ms) · `drop_all` true

| # | `target` | okno (lo–hi) | `order` | `band_lo` → `t_stick` | `variant` | `false_gate` | `serrations` |
|---|---|---|---|---|---|---|---|
| 0 | 0.52 (34079) | 0.475–0.565 | 0 (0) | 0.21 (13763) → 0.39 | standard | — | — |
| 1 | 0.6 (39322) | 0.555–0.645 | 0.1 (6554) | 0.22 (14418) → 0.40 | standard | — | — |
| 2 | 0.48 (31457) | 0.435–0.525 | 0.1 (6554) | 0.22 (14418) → 0.40 | standard | — | — |
| 3 | 0.57 (37356) | 0.525–0.615 | 0.2 (13107) | 0.2 (13107) → 0.38 | spool | 0.4 (26214) | — |
| 4 | 0.63 (41288) | 0.585–0.675 | 0.3 (19661) | 0.23 (15073) → 0.41 | standard | — | — |
| 5 | 0.54 (35389) | 0.495–0.585 | 0.3 (19661) | 0.23 (15073) → 0.41 | standard | — | — |

### 3.4 `pin.m4` — „Schody” / „Staircase” (poziom t6)

- **Cel:** każdy stos ma **inne pasmo napięcia** (dolne granice 0,12 → 0,18 → 0,24 → 0,30 → 0,36 → 0,42 w kolejności wiązania, każde pasmo szerokie na 0,12). Uczy, że napięcie to nie stała „dobra wartość”, tylko ręka dopasowywana do kołka. Sąsiednie pasma zachodzą na siebie o 0,06, więc spokojny gracz przechodzi płynnie po schodach w górę.
- **Czas:** 3–5 min. **Pułapka:** przy napięciu dobrym dla poprzedniego kołka następny **nie wiąże** (jest luźny i sprężynuje), więc wygląda na ustawiony albo „nieważny”. Gracz, który doda za dużo, przeskakuje schodek (kołek „nie idzie”). Bez szumu i zabezpieczeń, żeby była to czysta lekcja napięcia.

`win_shear` 0.1 (6554) · `overset_margin` 0.08 (5243) · `tension_band` 0.12 (7864) · `t_hold` 0.1 (6554) · `t_release` 0.05 (3277) · `tau_safe` 0.6 (39322) · `cr_lo` 0.12 (7864) · `cr_hi` 0.21 (13763) · `s_max` 1 (65536) · `stress_gain` 0.095 (6226) · `noise` 0 (0) · `drop_grace_steps` 24 (200 ms) · `drop_all` true

| # | `target` | okno (lo–hi) | `order` | `band_lo` → `t_stick` | `variant` | `false_gate` | `serrations` |
|---|---|---|---|---|---|---|---|
| 0 | 0.5 (32768) | 0.450–0.550 | 0.2 (13107) | 0.24 (15729) → 0.36 | standard | — | — |
| 1 | 0.58 (38011) | 0.530–0.630 | 0 (0) | 0.12 (7864) → 0.24 | standard | — | — |
| 2 | 0.47 (30802) | 0.420–0.520 | 0.4 (26214) | 0.36 (23593) → 0.48 | standard | — | — |
| 3 | 0.62 (40632) | 0.570–0.670 | 0.1 (6554) | 0.18 (11796) → 0.30 | standard | — | — |
| 4 | 0.53 (34734) | 0.480–0.580 | 0.5 (32768) | 0.42 (27525) → 0.54 | standard | — | — |
| 5 | 0.56 (36700) | 0.510–0.610 | 0.3 (19661) | 0.3 (19661) → 0.42 | standard | — | — |

### 3.5 `pin.m5` — „Siódemka” / „The Seven” (poziom t7, finał rodziny)

- **Cel:** wszystko naraz w granicach wyroczni: 7 stosów, 4 zabezpieczenia trzech typów (dwie szpulki, ząbkowany, szpulko-ząbkowany), para multi-bind (stosy 2+3, w tym ząbkowany), okno 0,07, zapas 0,05, pasmo 0,12, szum 0,15, `drop_grace` 150 ms. Notka gabloty jako nagroda (Wielka Wystawa 1851, `SHOWCASE.md`).
- **Czas:** 4–8 min. **Pułapka:** stos 4 (szpulko-ząbkowany) ma progi zarówno przed fałszywą bramką (0,30 / 0,36 / 0,42 / 0,46), jak i nad nią (0,56), więc w trakcie kontrrotacji gracz dostaje jeszcze klik ząbka i myśli, że to `set`. Ostatni stos (6) to znowu szpulka, kiedy wszystko inne już stoi, więc zrzut kosztuje najwięcej.

`win_shear` 0.07 (4588) · `overset_margin` 0.05 (3277) · `tension_band` 0.12 (7864) · `t_hold` 0.1 (6554) · `t_release` 0.05 (3277) · `tau_safe` 0.42 (27525) · `cr_lo` 0.12 (7864) · `cr_hi` 0.21 (13763) · `s_max` 1 (65536) · `stress_gain` 0.095 (6226) · `noise` 0.15 (9830) · `drop_grace_steps` 18 (150 ms) · `drop_all` true

| # | `target` | okno (lo–hi) | `order` | `band_lo` → `t_stick` | `variant` | `false_gate` | `serrations` |
|---|---|---|---|---|---|---|---|
| 0 | 0.55 (36045) | 0.515–0.585 | 0 (0) | 0.22 (14418) → 0.34 | standard | — | — |
| 1 | 0.62 (40632) | 0.585–0.655 | 0.1 (6554) | 0.21 (13763) → 0.33 | spool | 0.45 (29491) | — |
| 2 | 0.5 (32768) | 0.465–0.535 | 0.2 (13107) | 0.24 (15729) → 0.36 | serrated | — | 0.30, 0.36, 0.41 |
| 3 | 0.6 (39322) | 0.565–0.635 | 0.2 (13107) | 0.24 (15729) → 0.36 | standard | — | — |
| 4 | 0.66 (43254) | 0.625–0.695 | 0.3 (19661) | 0.2 (13107) → 0.32 | spool_serrated | 0.5 (32768) | 0.30, 0.36, 0.42, 0.46, 0.56 |
| 5 | 0.53 (34734) | 0.495–0.565 | 0.4 (26214) | 0.23 (15073) → 0.35 | standard | — | — |
| 6 | 0.58 (38011) | 0.545–0.615 | 0.5 (32768) | 0.22 (14418) → 0.34 | spool | 0.42 (27525) | — |

## 4. `wafer`: samouczek i 3 zamki mistrzowskie

Wspólne: materiał `steel`, stałe rodziny (§1). W `wafer` v0.1 przepchnięcie powstaje wtedy, gdy gracz pcha **ustawioną** płytkę ponad `okno_hi + overset_margin`. Naprawa: T poniżej `t_release` 0,16, ale nie poniżej `t_hold` 0,08 przez `drop_grace` (wtedy spadają wszystkie). `noise` jest zapisywany, ale rodzina go nie używa (§8).

Karta `LOCKS.md` §2.4 mówiła „mistrzowskie: nie dotyczy (przechodzi w wersję dwustronną)”. Zmieniam to: `wafer_double` nie istnieje w v0.1, a wyzwanie „Mistrz rodziny” potrzebuje zestawu dla każdej rodziny w puli MVP. Zamki mistrzowskie płytkowej są krótsze (1–3 min) niż pinowej.

### 4.1 `wafer.s1` — „Lżejsze kliknięcia” / „Lighter Clicks”

- **Cel:** przeniesienie znanego ruchu na nową rodzinę. Płytka to ramka, kliknięcia są wyższe, luźne płytki grzechoczą. Kolejność środek → przód → tył.
- **Czas:** 15–30 s. **Pułapka:** brak (`tau_safe` 1,0, zapas do overset 0,16).

`win_shear` 0.18 (11796) · `overset_margin` 0.16 (10486) · `tension_band` 0.36 (23593) · `t_hold` 0.08 (5243) · `t_release` 0.16 (10486) · `tau_safe` 1 (65536) · `s_max` 1 (65536) · `stress_gain` 0.095 (6226) · `noise` 0 (0) · `drop_grace_steps` 60 (500 ms)

| # | `target` | okno (lo–hi) | `order` | `band_lo` → `t_stick` |
|---|---|---|---|---|
| 0 | 0.52 (34079) | 0.430–0.610 | 0.1 (6554) | 0.22 (14418) → 0.58 |
| 1 | 0.6 (39322) | 0.510–0.690 | 0 (0) | 0.22 (14418) → 0.58 |
| 2 | 0.48 (31457) | 0.390–0.570 | 0.2 (13107) | 0.24 (15729) → 0.60 |

### 4.2 `wafer.s2` — „Za wysoko i co dalej” / „Too High, Now What”

- **Cel:** overset płytki naprawia się **lekkim** odpuszczeniem (0,08–0,16), bez zrzutu pozostałych. Zapas do overset tylko 0,06, więc przepchnięcie jest prawie pewne po pierwszym kliknięciu.
- **Czas:** 25–50 s. **Pułapka:** nawyk z pinowej, czyli puszczenie do zera, zrzuca wszystkie płytki.

`win_shear` 0.12 (7864) · `overset_margin` 0.06 (3932) · `tension_band` 0.3 (19661) · `t_hold` 0.08 (5243) · `t_release` 0.16 (10486) · `tau_safe` 1 (65536) · `s_max` 1 (65536) · `stress_gain` 0.095 (6226) · `noise` 0 (0) · `drop_grace_steps` 48 (400 ms)

| # | `target` | okno (lo–hi) | `order` | `band_lo` → `t_stick` |
|---|---|---|---|---|
| 0 | 0.55 (36045) | 0.490–0.610 | 0 (0) | 0.22 (14418) → 0.52 |
| 1 | 0.62 (40632) | 0.560–0.680 | 0.2 (13107) | 0.23 (15073) → 0.53 |
| 2 | 0.5 (32768) | 0.440–0.560 | 0.1 (6554) | 0.22 (14418) → 0.52 |

### 4.3 `wafer.s3` — „Za mocno” / „Too Hard” (zamiast „falownik kontra haczyk”, D-22)

- **Cel:** górna granica pasma. `tau_safe` 0,44, a płytki idą aż do 0,52–0,54, więc między 0,44 a ~0,53 płytki dalej się ustawiają, ale wytrych się wygina (`stress`) i w końcu pęka. `stress_gain` ×2 (0,19), żeby ugięcie było szybkie i czytelne. W samouczku złamanie nie kosztuje wytrycha.
- **Czas:** 30–60 s. **Pułapka:** „mocniej = szybciej”.

`win_shear` 0.12 (7864) · `overset_margin` 0.1 (6554) · `tension_band` 0.3 (19661) · `t_hold` 0.08 (5243) · `t_release` 0.16 (10486) · `tau_safe` 0.44 (28836) · `s_max` 1 (65536) · `stress_gain` 0.19 (12452) · `noise` 0 (0) · `drop_grace_steps` 42 (350 ms)

| # | `target` | okno (lo–hi) | `order` | `band_lo` → `t_stick` |
|---|---|---|---|---|
| 0 | 0.58 (38011) | 0.520–0.640 | 0.2 (13107) | 0.22 (14418) → 0.52 |
| 1 | 0.5 (32768) | 0.440–0.560 | 0 (0) | 0.24 (15729) → 0.54 |
| 2 | 0.62 (40632) | 0.560–0.680 | 0.3 (19661) | 0.22 (14418) → 0.52 |
| 3 | 0.54 (35389) | 0.480–0.600 | 0.1 (6554) | 0.23 (15073) → 0.53 |

### 4.4 `wafer.m1` — „Pary” / „Pairs” (poziom t3)

- **Cel:** dwie pary płytek wiążących naraz (0+2, potem 1+4) i ostatnia pojedyncza (3). W `wafer` v0.1 równe `order` wiążą razem bez limitu, a generator tego nie robi, więc to wyłącznie zamek autorski.
- **Czas:** 1–2 min. **Pułapka:** po ustawieniu jednej z pary gracz szuka gdzie indziej. Druga z pary siedzi obok i stawia ten sam opór.

`win_shear` 0.1 (6554) · `overset_margin` 0.08 (5243) · `tension_band` 0.22 (14418) · `t_hold` 0.08 (5243) · `t_release` 0.16 (10486) · `tau_safe` 0.52 (34079) · `s_max` 1 (65536) · `stress_gain` 0.095 (6226) · `noise` 0 (0) · `drop_grace_steps` 30 (250 ms)

| # | `target` | okno (lo–hi) | `order` | `band_lo` → `t_stick` |
|---|---|---|---|---|
| 0 | 0.52 (34079) | 0.470–0.570 | 0 (0) | 0.22 (14418) → 0.44 |
| 1 | 0.6 (39322) | 0.550–0.650 | 0.1 (6554) | 0.24 (15729) → 0.46 |
| 2 | 0.48 (31457) | 0.430–0.530 | 0 (0) | 0.22 (14418) → 0.44 |
| 3 | 0.64 (41943) | 0.590–0.690 | 0.2 (13107) | 0.23 (15073) → 0.45 |
| 4 | 0.56 (36700) | 0.510–0.610 | 0.1 (6554) | 0.24 (15729) → 0.46 |

### 4.5 `wafer.m2` — „Drabina” / „Ladder” (poziom t3)

- **Cel:** schody napięcia jak w `pin.m4` (pasma 0,16 → 0,22 → 0,28 → 0,34 → 0,40, każde 0,10), połączone z płytkową naprawą overset. Naprawa wymaga zejścia z 0,34–0,50 do 0,08–0,16 i powrotu w górę, a ustawione płytki trzymają przez cały czas.
- **Czas:** 2–3 min. **Pułapka:** po overset na wysokim schodku gracz schodzi za nisko (zrzut wszystkiego) albo za mało (płytka dalej zablokowana, bo 0,16 to granica).

`win_shear` 0.1 (6554) · `overset_margin` 0.08 (5243) · `tension_band` 0.1 (6554) · `t_hold` 0.08 (5243) · `t_release` 0.16 (10486) · `tau_safe` 0.56 (36700) · `s_max` 1 (65536) · `stress_gain` 0.095 (6226) · `noise` 0 (0) · `drop_grace_steps` 30 (250 ms)

| # | `target` | okno (lo–hi) | `order` | `band_lo` → `t_stick` |
|---|---|---|---|---|
| 0 | 0.55 (36045) | 0.500–0.600 | 0 (0) | 0.16 (10486) → 0.26 |
| 1 | 0.5 (32768) | 0.450–0.550 | 0.2 (13107) | 0.28 (18350) → 0.38 |
| 2 | 0.62 (40632) | 0.570–0.670 | 0.1 (6554) | 0.22 (14418) → 0.32 |
| 3 | 0.58 (38011) | 0.530–0.630 | 0.4 (26214) | 0.4 (26214) → 0.50 |
| 4 | 0.47 (30802) | 0.420–0.520 | 0.3 (19661) | 0.34 (22282) → 0.44 |

### 4.6 `wafer.m3` — „Osiem płytek” / „Eight Wafers” (poziom t3, finał rodziny)

- **Cel:** wytrzymałość i precyzja: 8 płytek (przy podziałce 56 dp z `LOCKS.md` §2.4 nie mieszczą się w 412 dp, więc ten zamek używa podziałki 44 dp jak pinowa: 8 × 44 = 352 dp, płytki 28 dp), okno 0,08, zapas 0,05, `drop_grace` 150 ms, kolejność przeskakująca po całym kanale (1 → 3 → 5 → 0 → 7 → 4 → 2 → 6).
- **Czas:** 2–4 min. **Pułapka:** krótki `drop_grace` przy długim kanale: przeniesienie wytrycha z przodu na tył z jednoczesnym „odpoczynkiem” lewego kciuka zrzuca wszystko.

`win_shear` 0.08 (5243) · `overset_margin` 0.05 (3277) · `tension_band` 0.2 (13107) · `t_hold` 0.08 (5243) · `t_release` 0.16 (10486) · `tau_safe` 0.52 (34079) · `s_max` 1 (65536) · `stress_gain` 0.095 (6226) · `noise` 0 (0) · `drop_grace_steps` 18 (150 ms)

| # | `target` | okno (lo–hi) | `order` | `band_lo` → `t_stick` |
|---|---|---|---|---|
| 0 | 0.55 (36045) | 0.510–0.590 | 0.3 (19661) | 0.22 (14418) → 0.42 |
| 1 | 0.62 (40632) | 0.580–0.660 | 0 (0) | 0.24 (15729) → 0.44 |
| 2 | 0.48 (31457) | 0.440–0.520 | 0.6 (39322) | 0.22 (14418) → 0.42 |
| 3 | 0.58 (38011) | 0.540–0.620 | 0.1 (6554) | 0.25 (16384) → 0.45 |
| 4 | 0.66 (43254) | 0.620–0.700 | 0.5 (32768) | 0.23 (15073) → 0.43 |
| 5 | 0.51 (33423) | 0.470–0.550 | 0.2 (13107) | 0.24 (15729) → 0.44 |
| 6 | 0.6 (39322) | 0.560–0.640 | 0.7 (45875) | 0.22 (14418) → 0.42 |
| 7 | 0.53 (34734) | 0.490–0.570 | 0.4 (26214) | 0.26 (17039) → 0.46 |

## 5. Profile proceduralne (wektor trudności)

Profil to **blok `difficulty`** z `lockwright.lock/1` (pola `DifficultyVector`), z którego `generate(seed, d)` losuje zamek. Seria Trybu Ciągłego wybiera profil według tieru docelowego `tier(n)` (`PROGRESSION.md` §2.2). Zasada wyboru: najniższy nieukończony profil rodziny o `tier ≤ tier(n)`. Gdy wszystkie z danego tieru są ukończone, losowy z nich. Między kolejnymi profilami rośnie najwyżej **dwie osie** (`LOCKS.md` §1.8): **Z** złożoność (`n`, `sec`), **P** precyzja (`win`, `band`, `margin`), **C** czytelność (`noise`), **K** kolejność (`spread`, `mbp`), **R** zasoby (`grace`, `s_max`).

### 5.1 `pin_tumbler` (17 profili)

Kolumny w jednostkach dziesiętnych. Q16 = `x · 65536` (np. 0,12 → 7864, 0,28 → 18350). `time_limit_s` to budżet człowieka tieru (bot dostaje połowę).

| Profil | `tier` | `n_min–n_max` | `sec_min–sec_max` | `win_shear` | `tension_band` | `overset_margin` | `noise` | `bind_spread` | `multi_bind_p` | `drop_grace_ms` | `s_max` | `time_limit_s` | Osie ↑ | Czas człowieka |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| P01 | 2 | 3 | 0 | 0,12 | 0,28 | 0,10 | 0 | 1,0 | 0 | 300 | 1,0 | 60 | (= t2) | 30–60 s |
| P02 | 2 | 4 | 0 | 0,12 | 0,28 | 0,10 | 0 | 1,0 | 0 | 300 | 1,0 | 60 | Z | 40–70 s |
| P03 | 3 | 4 | 0 | 0,11 | 0,24 | 0,09 | 0 | 1,0 | 0 | 300 | 1,0 | 90 | P | 45–80 s |
| P04 | 3 | 4 | 0 | 0,11 | 0,24 | 0,09 | 0,05 | 0,8 | 0 | 300 | 1,0 | 90 | C, K | 45–90 s |
| P05 | 3 | 5 | 0 | 0,11 | 0,24 | 0,09 | 0,05 | 0,8 | 0 | 250 | 1,0 | 120 | Z, R | 60–100 s |
| P06 | 4 | 5 | 1 | 0,11 | 0,24 | 0,09 | 0,05 | 0,8 | 0 | 250 | 1,0 | 120 | Z (1. zabezpieczenie, lekcja `pin.l_spool`) | 60–120 s |
| P07 | 4 | 5 | 1 | 0,10 | 0,20 | 0,08 | 0,05 | 0,8 | 0 | 250 | 1,0 | 120 | P | 60–120 s |
| P08 | 4 | 5 | 1 | 0,10 | 0,20 | 0,08 | 0,08 | 0,6 | 0,05 | 250 | 1,0 | 120 | C, K | 70–120 s |
| P09 | 4 | 5 | 1 | 0,10 | 0,20 | 0,08 | 0,08 | 0,6 | 0,05 | 200 | 1,0 | 120 | R (= t4) | 70–120 s |
| P10 | 5 | 5 | 1–2 | 0,09 | 0,18 | 0,07 | 0,08 | 0,6 | 0,05 | 200 | 1,0 | 120 | Z, P | 80–130 s |
| P11 | 5 | 5 | 1–2 | 0,09 | 0,18 | 0,07 | 0,10 | 0,5 | 0,10 | 200 | 1,0 | 120 | C, K (= t5) | 80–130 s |
| P12 | 5 | 5 | 1–2 | 0,09 | 0,18 | 0,07 | 0,10 | 0,5 | 0,10 | 200 | 0,85 | 120 | R | 80–130 s |
| P13 | 6 | 6 | 2–3 | 0,08 | 0,15 | 0,06 | 0,10 | 0,5 | 0,10 | 200 | 0,85 | 150 | Z, P | 90–150 s |
| P14 | 6 | 6 | 2–3 | 0,08 | 0,15 | 0,06 | 0,12 | 0,4 | 0,15 | 200 | 0,85 | 150 | C, K | 90–150 s |
| P15 | 6 | 6 | 2–3 | 0,08 | 0,15 | 0,06 | 0,12 | 0,4 | 0,15 | 170 | 0,80 | 150 | R (≈ t6) | 90–150 s |
| P16 | 7 | 6–7 | 3–4 | 0,07 | 0,12 | 0,05 | 0,12 | 0,4 | 0,15 | 170 | 0,80 | 150 | Z, P | 100–180 s |
| P17 | 7 | 6–7 | 3–4 | 0,07 | 0,12 | 0,05 | 0,15 | 0,3 | 0,20 | 150 | 0,80 | 150 | C, K, R* (≈ t7) | 100–180 s |

\* P17 podnosi trzy osie (czytelność, kolejność, zasoby), bo jest odpowiednikiem tieru t7 z `LOCKS.md` §2.6. Seria nigdy nie podaje P17 bezpośrednio po P16: między nimi wstawia zamek mistrzowski albo zamek innej rodziny (zasada „rodziny nie powtarzają się więcej niż 2 razy z rzędu”). To jedyny wyjątek od reguły dwóch osi.

Uwagi:
- `s_max` < 1,0 (P12+) działa tylko przy napięciu powyżej `tau_safe`, więc to oś „mniej wybacza przesadę”, a nie „łamie się samo”. Zużycie narzędzia dalej obniża pojemność (`TOOLS.md` §2).
- Od P13 tier ≥ 5 wymaga napinacza listwowego w kanałach „wąskich” (`TOOLS.md` §3.1). Atrybut „wąski kanał” nie istnieje jeszcze w lockcore (§8, prośba 4), więc w v0.1 profile P13–P17 działają z napinaczem kątowym.

### 5.2 `wafer` (12 profili)

Generator `wafer` v0.1 używa tylko `n`, `win_shear`, `tension_band`, `overset_margin`, `bind_spread`, `drop_grace_ms`, `s_max` i `time_limit_s`. Pola `sec_*`, `noise` i `multi_bind_p` są zerowe. `tier` jest obcinany do 1–3 (D-17), a profile ponad t3 tylko zaostrzają parametry w obrębie t3.

| Profil | `tier` | `n` | `win_shear` | `tension_band` | `overset_margin` | `bind_spread` | `drop_grace_ms` | `s_max` | `time_limit_s` | Osie ↑ | Czas człowieka |
|---|---|---|---|---|---|---|---|---|---|---|---|
| W01 | 1 | 3 | 0,14 | 0,30 | 0,12 | 1,0 | 300 | 1,0 | 60 | (= t1) | 20–40 s |
| W02 | 1 | 4 | 0,14 | 0,30 | 0,12 | 1,0 | 300 | 1,0 | 60 | Z | 25–50 s |
| W03 | 2 | 4 | 0,12 | 0,26 | 0,10 | 1,0 | 300 | 1,0 | 60 | P (= t2) | 30–60 s |
| W04 | 2 | 4 | 0,12 | 0,26 | 0,10 | 0,8 | 250 | 1,0 | 60 | K, R | 30–60 s |
| W05 | 2 | 5 | 0,12 | 0,26 | 0,10 | 0,8 | 250 | 1,0 | 90 | Z | 40–70 s |
| W06 | 3 | 5 | 0,10 | 0,22 | 0,08 | 0,8 | 250 | 1,0 | 90 | P (≈ t3) | 45–80 s |
| W07 | 3 | 5 | 0,10 | 0,22 | 0,08 | 0,6 | 200 | 1,0 | 90 | K, R | 45–90 s |
| W08 | 3 | 6 | 0,10 | 0,22 | 0,08 | 0,6 | 200 | 1,0 | 90 | Z | 50–90 s |
| W09 | 3 | 6 | 0,09 | 0,20 | 0,07 | 0,6 | 200 | 1,0 | 90 | P | 55–100 s |
| W10 | 3 | 6 | 0,09 | 0,20 | 0,07 | 0,5 | 170 | 0,85 | 90 | K, R | 55–100 s |
| W11 | 3 | 7 | 0,09 | 0,20 | 0,07 | 0,5 | 170 | 0,85 | 120 | Z | 60–110 s |
| W12 | 3 | 7 | 0,08 | 0,18 | 0,06 | 0,5 | 170 | 0,85 | 120 | P | 60–120 s |

Uwaga: `bind_spread` w `wafer` v0.1 zmienia tylko odstęp `order`, a ten służy wyłącznie do porównań, więc oś K jest w tej rodzinie na razie **niewyczuwalna** (gracz nie czuje różnicy między 1,0 a 0,5). Zostawiam ją w profilach, bo zacznie działać, gdy generator dostanie pary multi-bind (§8, prośba 3).

## 6. Wyniki weryfikacji

### 6.1 Zamki autorskie (200 przebiegów bota na zamek)

`pasmo` = najwęższe pasmo napięcia planu wyroczni (≥ 0,08 wymagane), `okno` = `win_shear`. Bot skryptowy: budżet połowa `time_limit_s`. Bot niezdarny: pełny `time_limit_s`.

| Zamek | pasmo | okno | Bot skryptowy | Czas bota | Bot niezdarny | `false_set` / przebieg |
|---|---|---|---|---|---|---|
| `pin.s1` | 0,450 | 0,20 | 200/200 | 2,1 s | 200/200 | 0 |
| `pin.s2` | 0,400 | 0,16 | 200/200 | 5,9 s | 200/200 | 0 |
| `pin.s3` | 0,300 | 0,12 | 200/200 | 5,2 s | 200/200 | 0 |
| `pin.l_spool` | 0,090 | 0,12 | 200/200 | 4,8 s | 200/200 | 1 |
| `pin.a1` (= t2 seed 1) | 0,280 | 0,12 | 200/200 | 5,2 s | 200/200 | 0 |
| `pin.a2` (= t2 seed 2) | 0,280 | 0,12 | 200/200 | 5,3 s | 200/200 | 0 |
| `pin.m1` | 0,080 | 0,10 | 200/200 | 7,7 s | 199/200 | 2 |
| `pin.m2` | 0,200 | 0,10 | 200/200 | 8,2 s | 200/200 | 0 |
| `pin.m3` | 0,090 | 0,09 | 200/200 | 9,3 s | 198/200 | 1 |
| `pin.m4` | 0,120 | 0,10 | 200/200 | 9,9 s | 200/200 | 0 |
| `pin.m5` | 0,090 | 0,07 | 200/200 | 10,8 s | 195/200 | 3 |
| `wafer.s1` | 0,360 | 0,18 | 200/200 | 6,5 s | 200/200 | — |
| `wafer.s2` | 0,300 | 0,12 | 200/200 | 5,2 s | 200/200 | — |
| `wafer.s3` | 0,200 | 0,12 | 200/200 | 7,1 s | 200/200 | — |
| `wafer.m1` | 0,220 | 0,10 | 200/200 | 8,1 s | 200/200 | — |
| `wafer.m2` | 0,100 | 0,10 | 200/200 | 8,0 s | 200/200 | — |
| `wafer.m3` | 0,200 | 0,08 | 200/200 | 12,2 s | 200/200 | — |

(`pin.l_serrated` z §2.4 nie był osobno sprawdzany; to wariant `pin.l_spool` z kołkiem ząbkowanym, do sprawdzenia przy wpisaniu do danych.)

### 6.2 Profile (1 000 seedów na profil)

Wszystkie 29 profili: wyrocznia akceptuje 1000/1000 (po ponowieniach generatora), bot skryptowy otwiera 1000/1000. Bot niezdarny (miara miękka, D-18):

| Profile | Bot niezdarny | Czas bota skr. (mediana zakresu) | `false_set` / zamek (niezdarny) |
|---|---|---|---|
| P01–P05 | 100% | 5,2–8,5 s | 0 |
| P06–P09 | 100% | 8,2–8,5 s | ≈ 0,47 (połowa zabezpieczeń to szpulki) |
| P10–P12 | 99,9–100% | 7,9 s | ≈ 0,79 |
| P13–P15 | 99,6–99,7% | 9,3 s | ≈ 1,25 |
| P16–P17 | 98,8–98,9% | 10,0 s | ≈ 2,3 |
| W01–W12 | 100% | 5,6–11,0 s | — |

Wniosek: żaden profil ani zamek nie jest „nieotwieralny”, a bot niezdarny słabnie monotonicznie z profilem pinowej. Boty nie słuchają zdarzeń (wiedzą z planu, gdzie jest okno), więc **czytelność** (`noise`, podobieństwo set/false_set) zmierzy dopiero bot czujący (etap 3 weryfikatora, dodany w lockcore równolegle z tym dokumentem: zamki z §2–4 trzeba przez niego przepuścić) i playtesty.

## 7. Przykład pliku `lockwright.lock/1` (`pin.s1`)

```json
{
  "schema": "lockwright.lock/1",
  "family": "pin_tumbler",
  "rules_version": 1,
  "id": "pin.s1",
  "source": "authored",
  "seed": "0",
  "difficulty": {
    "tier": 1,
    "n_min": 1,
    "n_max": 1,
    "sec_min": 0,
    "sec_max": 0,
    "win_shear_q16": 13107,
    "tension_band_q16": 29491,
    "overset_margin_q16": 10486,
    "noise_q16": 0,
    "bind_spread_q16": 65536,
    "multi_bind_p_q16": 0,
    "drop_grace_ms": 600,
    "s_max_q16": 65536,
    "time_limit_s": 120
  },
  "spec": {
    "win_shear_q16": 13107,
    "overset_margin_q16": 10486,
    "tension_band_q16": 29491,
    "t_hold_q16": 6554,
    "t_release_q16": 3277,
    "tau_safe_q16": 65536,
    "cr_lo_q16": 7864,
    "cr_hi_q16": 13763,
    "drop_grace_steps": 72,
    "drop_all": false,
    "s_max_q16": 65536,
    "stress_gain_q16": 6226,
    "noise_q16": 0,
    "bound_speed_q16": 1092,
    "spool_speed_q16": 327,
    "stacks": [
      {
        "target_q16": 36045,
        "order_q16": 0,
        "band_lo_q16": 9830,
        "variant": "standard"
      }
    ]
  },
  "presentation": {
    "material": "brass"
  }
}
```

Proponowane miejsce danych: `game/data/locks/authored/<id>.lock.json` (zamki autorskie, w tym S1–S3, lekcje, A1/A2, mistrzowskie) i `game/data/locks/profiles/<family>.json` (lista profili z §5 jako bloki `difficulty` plus `id` profilu). Obie ścieżki nie istnieją jeszcze w repo. Wpisuje je programista razem z prośbą 1 z §8.

## 8. Luki w lockcore v0.1 (prośby do programisty)

1. **Sprawdzanie zamków autorskich w CI.** `verify_seeds` sprawdza tylko zamki generowane. Potrzebne `replay_tool check <plik.lock.json>` (albo `verify_seeds --authored DIR`): `validate` + wyrocznia + bot skryptowy + bot niezdarny, z wynikiem jak w §6.1. Bramka: 100% bota skryptowego.
2. **Wybór rodzaju zabezpieczenia w profilu.** Generator `pin_tumbler` losuje w t4–t6 szpulkę albo ząbkowany po równo (t7: trzy rodzaje). Profil P06 powinien móc wymusić „pierwsze zabezpieczenie = szpulka” (pole np. `sec_kinds` w `difficulty`). Do tego czasu gra obsługuje obie kolejności lekcji (§2.4).
3. **Pary multi-bind w generatorze `wafer`.** `multi_bind_p` jest ignorowane. Model kroku już obsługuje równe `order` (patrz `wafer.m1`). Bez tego oś K tej rodziny nie działa (§5.2).
4. **Atrybut „wąski kanał”** (`TOOLS.md` §3.1) dla `pin_tumbler` t5+ i wymaganie `tw_bar`. Dziś nie ma go w spec.
5. **`noise` w `wafer`** jest zapisywany, ale niewykorzystany. Albo usunąć z walidacji rodziny, albo podpiąć pod fałszywe kontakty jak w `pin_tumbler`.
6. **`fb_gain`** (siła sygnałów w samouczku, `LOCKS.md` §1.8 oś czytelności) nie jest polem lockcore i nie powinno być: to parametr warstwy prezentacji. Proponuję trzymać go w bloku `presentation` pliku zamka (`"fb_gain_q16"`), który lockcore ignoruje przy symulacji.
