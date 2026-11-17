# Macierz stanów zamka — wszystkie rodziny, bez koloru (D-139), 2026-11-17

Pytanie: czy każdy stan zamka (swobodny, wiąże, blisko, ustawiony, fałszywie ustawiony, przepchnięty, blisko złamania,
otwarty) da się odróżnić **kształtem albo położeniem** — w skali szarości, przy deuteranopii i protanopii — w każdej
rodzinie, którą gra ma. Dotąd pełne zrzuty miały `pin_tumbler`, `lever` i `combo` (D-129, D-130); audyt D-90 mierzył
wszystkie rodziny, ale z kredą na ekranie i z progiem liczonym po całym kadrze.

Punkt odniesienia: `docs/DESIGN.md` §1 (kod stanów), `docs/ACCESSIBILITY.md` §3, D-90, D-129, D-130.
Zrzuty: `docs/handoff/device-tests/fixes/lock_states/`.

Czego ten dokument nie zastępuje: oglądu na telefonie. Zrzuty są z renderera programowego (llvmpipe, OpenGL 3,
412×915 = 1 px na 1 dp). Kształty i położenia są te same co na urządzeniu; ostrość i faktura mogą się różnić.

---

## 1. Metoda

- `game/tests/a11y_state_shots.tscn` otwiera prawdziwy ekran każdej rodziny (13 rodzin: `pin_tumbler` i 12 scen planu B)
  i zamraża pozę, w której **wszystkie elementy mają jeden stan**. `qa/a11y/state_report.py` liczy dla pary stanów
  odsetek pikseli obrazu zamka (górne 75 % ekranu w pionie: przekrój i czoło rdzenia z napinaczem), których wartość
  różni się o więcej niż 12/255 — osobno w szarości (Rec. 709), po symulacji deuteranopii i protanopii (Machado 2009).
  Liczy się najmniejsza z trzech wartości. Próg z D-90: **0,25 %** kadru (ok. 700 dp², czyli pole 26 × 26 dp).
- Wszystkie zrzuty z **ograniczeniem ruchu** (`--reduce=1`): żadne drżenie nie pomaga, zostaje nieruchomy obraz.
- **Nowe w tym przebiegu:**
  - `--chalk=off` — bez warstwy kredy i bez linii trenera. Tak gra się większość zleceń: kreda jest tylko w samouczku,
    w pierwszych 3 zleceniach, w pierwszym zleceniu rodziny i przy włączonej „Warstwie kredy”. Stan musi się więc
    bronić samym mechanizmem. (Przebieg z kredą dał dla par poniżej progu te same liczby — patrz §3.)
  - poza `free_lifted` — swobodny element na wysokości pozy „wiąże” (pozycja 0,40). W starych zrzutach „swobodny”
    stał na pozycji 0, więc para swobodny / wiąże mierzyła głównie to, że element stoi gdzie indziej (w rodzinach
    z kółkami: że widać inną cyfrę). W tabelach niżej **„free” to zawsze ta poza**.
  - `--states=` (tylko wybrane pozy) i `qa/a11y/state_matrix.py` — tabela rodzina × para, przed / po, z listą stanów,
    które dana rodzina w ogóle ma, oraz arkusze kolor / szarość do repo.
- **Ograniczenia miary.** Liczy pole zmiany, nie jej czytelność: 0,4° pochylenia pięciu długich suwaków daje 1,5 %,
  a trzy rysy na napinaczu 0,18 %. Dlatego każdą parę poniżej 1 % obejrzałem w powiększeniu, a wynik opisuję słowami.
  Poza „wszystkie elementy w jednym stanie” jest sztuczna (w grze wiąże jeden element), więc różnica na jeden element
  to mniej więcej 1/5 liczby z tabeli (dźwignie: 1/3).

### Które stany ma która rodzina

Z `lockcore/src/families/*.cpp` (`ElementState` i `view.stress`). Par ze stanem, którego rodzina nie ma, nie oceniam („–”).

| Rodzina (moduł lockcore) | Stany | Czego nie ma |
|---|---|---|
| `pin_tumbler`, `dimple`, `magnetic` (pin) | wszystkie 8 | — |
| `wafer` (wafer) | 7 | fałszywego ustawienia |
| `time_lock` (wafer, zegar) | 7 | fałszywego ustawienia |
| `egyptian` (wooden_pin) | 6 | fałszywego ustawienia; narzędzie nie pęka (`stress` zawsze 0) |
| `lever`, `lever_detector`, `axial_slider` (lever) | wszystkie 8 | — |
| `warded` (warded) | 6 | fałszywego ustawienia i przepchnięcia (przeszkody: swobodna / blisko / wiąże; rygiel: swobodny / wiąże / ustawiony) |
| `combo`, `disc_detainer` (ring_combo) | 7 | blisko złamania (`stress` zawsze 0) |
| `dial_safe` (dial_safe) | 6 | przepchnięcia i blisko złamania |

---

## 2. Wynik przed poprawkami (pion 412×915, bez kredy, bez ruchu)

Odsetek zmienionych pikseli, minimum z szarości / deuteranopii / protanopii. **Pogrubione: poniżej 0,25 %.**
Szarość, deuteranopia i protanopia różnią się wszędzie o najwyżej 0,3 punktu — kolor nie niesie żadnego stanu.

| para | pin tumbler | dimple | magnetic | wafer | time lock | egyptian | lever | lever detector | axial slider | warded | combo | disc detainer | dial safe |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| free / bound | 1.16 | 1.16 | 1.16 | 1.59 | 2.10 | 0.95 | 4.08 | 2.62 | 1.54 | 1.27 | 0.27 | 0.51 | **0.00** |
| free / near | 6.90 | 6.78 | 5.57 | 4.04 | 5.14 | 2.32 | 5.40 | 3.91 | 2.25 | **0.00** | 0.60 | 0.98 | 8.97 |
| free / set | 6.73 | 6.75 | 5.88 | 5.22 | 6.04 | 1.98 | 8.49 | 6.62 | 1.23 | 1.85 | 2.94 | 2.92 | 10.97 |
| free / false_set | 5.73 | 5.73 | 5.73 | – | – | – | 8.66 | 6.81 | **0.00** | – | 0.94 | 1.35 | 0.25 |
| free / overset | 11.39 | 10.80 | 8.96 | 7.53 | 7.71 | 5.84 | 15.28 | 12.38 | 6.57 | – | 2.25 | 1.29 | – |
| free / stress | 1.89 | 1.35 | 1.35 | 1.77 | 2.29 | – | 4.27 | 2.81 | 1.73 | 1.85 | – | – | – |
| free / open | 18.23 | 19.70 | 18.51 | 14.43 | 8.20 | 4.57 | 9.96 | 6.80 | 2.70 | 6.12 | 4.49 | 3.61 | 16.55 |
| bound / near | 6.08 | 5.95 | 4.74 | 3.50 | 5.23 | 1.50 | 2.69 | 2.18 | 0.87 | 1.27 | 0.33 | 0.47 | 8.97 |
| bound / set | 7.38 | 7.40 | 6.53 | 5.82 | 5.98 | 2.93 | 7.27 | 5.79 | 2.70 | 1.01 | 2.89 | 2.80 | 10.97 |
| bound / false_set | 6.02 | 6.02 | 6.02 | – | – | – | 9.12 | 7.35 | 1.54 | – | 0.79 | 1.10 | 0.25 |
| bound / overset | 11.60 | 11.01 | 9.17 | 7.75 | 7.71 | 5.29 | 14.58 | 11.95 | 6.04 | – | 2.33 | 1.38 | – |
| bound / stress | 0.73 | **0.18** | **0.18** | **0.18** | **0.19** | – | **0.18** | **0.18** | **0.19** | 0.58 | – | – | – |
| bound / open | 18.86 | 20.33 | 19.14 | 14.30 | 8.16 | 5.53 | 9.24 | 6.18 | 4.17 | 5.45 | 4.50 | 3.49 | 16.55 |
| near / set | 7.14 | 7.11 | 6.11 | 4.34 | 4.17 | 1.83 | 6.38 | 4.91 | 2.05 | 1.85 | 2.86 | 3.27 | 1.50 |
| near / false_set | 8.18 | 8.05 | 6.85 | – | – | – | 9.71 | 7.96 | 2.25 | – | 1.12 | 1.57 | 9.21 |
| near / overset | 11.11 | 10.48 | 8.69 | 7.56 | 7.65 | 4.80 | 14.19 | 11.61 | 5.71 | – | 2.32 | 1.85 | – |
| near / stress | 6.41 | 6.14 | 4.93 | 3.69 | 5.42 | – | 2.88 | 2.37 | 1.06 | 1.85 | – | – | – |
| near / open | 18.95 | 19.89 | 18.64 | 14.32 | 7.30 | 4.86 | 8.49 | 5.36 | 3.52 | 6.12 | 4.48 | 3.96 | 7.24 |
| set / false_set | 3.34 | 3.35 | 2.50 | – | – | – | 10.52 | 8.90 | 1.23 | – | 2.71 | 2.66 | 11.01 |
| set / overset | 11.77 | 11.18 | 9.33 | 7.97 | 7.65 | 5.27 | 14.12 | 11.77 | 6.08 | – | 2.90 | 3.39 | – |
| set / stress | 7.59 | 7.39 | 6.53 | 5.82 | 6.17 | – | 7.26 | 5.79 | 2.89 | 1.59 | – | – | – |
| set / open | 14.43 | 14.91 | 14.45 | 14.66 | 6.65 | 3.26 | 4.44 | 1.59 | 1.47 | 4.58 | 2.36 | 0.69 | 5.84 |
| false_set / overset | 11.93 | 11.36 | 9.51 | – | – | – | 17.47 | 14.68 | 6.57 | – | 2.85 | 1.93 | – |
| false_set / stress | 6.56 | 6.02 | 6.02 | – | – | – | 9.12 | 7.35 | 1.73 | – | – | – | – |
| false_set / open | 14.85 | 16.32 | 15.13 | – | – | – | 11.86 | 9.04 | 2.70 | – | 4.26 | 3.35 | 16.58 |
| overset / stress | 11.78 | 11.20 | 9.35 | 7.93 | 7.90 | – | 14.77 | 12.13 | 6.23 | – | – | – | – |
| overset / open | 19.85 | 21.15 | 18.83 | 15.70 | 9.57 | 8.19 | 15.49 | 11.81 | 7.55 | – | 4.12 | 3.87 | – |
| stress / open | 19.03 | 20.33 | 19.14 | 14.30 | 8.16 | – | 9.24 | 6.19 | 4.17 | 5.45 | – | – | – |

---

## 3. Znalezione problemy

Dziesięć par poniżej progu, z trzech przyczyn.

### 3.1 „Blisko złamania” poza zamkiem bębenkowym widać tylko na napinaczu (7 rodzin)

`bound / stress`: `dimple` 0,18 %, `magnetic` 0,18 %, `wafer` 0,18 %, `time_lock` 0,19 %, `lever` 0,18 %,
`lever_detector` 0,18 %, `axial_slider` 0,19 % (zamek bębenkowy 0,73 %, `warded` 0,58 %).

`DESIGN.md` §1: „wytrych **i** napinacz wyginają się widocznie”. W zamku bębenkowym wygina się hak w przekroju
(`PICK_BEND_MM`), w `warded` sonda odchyla się o 3° (D-90). W pozostałych rodzinach narzędzie w przekroju stało
sztywno: jedynym nieruchomym sygnałem były rysy i ugięcie ramienia napinacza na czole rdzenia — mały rysunek w HUD
(ok. 500 dp²), poza miejscem, na które gracz patrzy, kiedy pracuje narzędziem. Rysy same w sobie są czytelne
(ciemne kreski na jasnym ramieniu, kształt), ale to jeden mały znak.

Dzisiejszy przebieg **z kredą** (poziom „reduced”, jak w pierwszych zleceniach) dał te same liczby (0,18–0,19 %): kreda
nie rysuje nic dla „blisko złamania”. W zrzutach D-90 (`a11y_2026-11-08/report/report.md`) ta para miała 1,2–11 %, ale
także w rodzinach, w których stresu nie ma (`dial_safe` 11,15 %, `combo` 1,83 %) — tamta liczba mierzyła więc różnice
w kredzie między dwiema pozami, nie znak stresu. Stąd wtedy „0 par poniżej progu”.

### 3.2 Zamek suwakowy: fałszywe nacięcie wygląda jak swobodny suwak

`axial_slider`, `free / false_set` = **0,00 %** — obrazy identyczne co do piksela. `bound / false_set` = 1,54 %, ale to
wyłącznie pochylenie suwaka o 0,4° w pozie „wiąże”; w powiększeniu obie pozy wyglądają tak samo.

`LockLiftLayerView` nie znał stanu `false_set` (rysował suwak na jego pozycji, bez niczego więcej), a czoło rdzenia
w rodzinach „warstwowych” nie liczyło podziałek. Fałszywe nacięcie gracz słyszał i czuł (`slider.false_notch`), ale
bez kredy nie widział. To jedyna rodzina z fałszywym ustawieniem w lockcore (od tieru 2), w której widok go nie miał.

Przy okazji: w `axial_slider`, `egyptian` i `time_lock` ustawiony element nie obracał czoła rdzenia o podziałkę, choć
`DESIGN.md` §1 i tabela w `LOCK-FEEL-2026-11-13.md` §3.1 mówią, że robi to każdy ekran z czołem.

### 3.3 Dwie pary, które są takie z natury mechanizmu (bez poprawki, opis w §6)

- `dial_safe`, `free / bound` = 0,00 %: „wiąże” w sejfie znaczy „tarcza kręci się razem z pokrętłem” — stanem jest ruch.
- `warded`, `free / near` = 0,00 %: widok `warded` nie rysuje stanu przeszkody, tylko sondę i przeszkody; „blisko”
  wynika z tego, gdzie sonda stoi, a sztuczna poza trzyma sondę w miejscu. To ograniczenie metody, nie ekranu.

---

## 4. Poprawki

Zasada: najmniejsza zmiana, kształt i położenie, żadnego koloru, blasku ani nowej grafiki. `pin_tumbler` bez zmian.

**A. Narzędzie w przekroju „daje się” blisko złamania** (`LockPhotorealView.tool_strain_deg()`).
Od stresu 0,6 — czyli od pierwszej rysy na napinaczu — do 1,0 narzędzie rodziny odchyla się od swojej linii o 0…3°
wokół końcówki, rękojeścią w dół (`TOOL_STRAIN_DEG`, ta sama wielkość co `STRAIN_DEG` sondy w `warded`). Poniżej 0,6
nic się nie zmienia, więc zwykła praca wygląda jak dotąd. To nieruchoma poza: działa w szarości, przy ograniczeniu
ruchu i bez kredy.

| Rodzina | Co się odchyla | Plik |
|---|---|---|
| `dimple`, `magnetic` | chorągiewka / sonda magnetyczna (warstwa 2D) | `game/scripts/photoreal/pin_family_view.gd` |
| `wafer` | wytrych i jego uchwyt (3D) | `game/scripts/photoreal/wafer_view.gd` |
| `lever`, `lever_detector` | podnośnik dźwigni (3D), w stronę, w którą odskakuje po złamaniu; jest o połowę krótszy od pozostałych narzędzi, więc obraca się o 0…6° (`LIFTER_STRAIN` = 2), co daje to samo ugięcie na końcu (3° dawało 0,28 %) | `game/scripts/photoreal/lever_view.gd` |
| `axial_slider`, `time_lock` (i `egyptian`, gdyby kiedyś miał stres) | popychacz / pęseta (warstwa 2D) | `game/scripts/photoreal/lift_layer_view.gd` |
| wspólne | stała i funkcja | `game/scripts/photoreal/lock_photoreal_view.gd` |

**B. Czoło rdzenia liczy podziałki także w rodzinach warstwowych** (`lift_layer_view.gd`, `_update_l_face`).
Ustawiony element = +1 podziałka (7,5°), fałszywe ustawienie = +2 podziałki — ten sam kod co na ekranach bębenkowym,
płytkowym i dźwigniowym. Przytrzymanie dalej dokręca czoło do 90° (płynnie od stanu podziałek). Dotyczy
`axial_slider` (tu jest fałszywe nacięcie), `egyptian` i `time_lock` (tylko +1 za ustawiony element).

**Narzędzia pomiaru:** `game/tests/a11y_state_shots.gd` (`--chalk`, `--states`, poza `free_lifted`),
`qa/a11y/state_report.py` (zna `free_lifted`), nowy `qa/a11y/state_matrix.py`.

**Nie ruszałem:** reguł i balansu lockcore, danych zleceń, wzorców haptyki, głosu, tekstów, `PlugFace`, kredy,
widoków `pin_tumbler`, `warded`, `combo`, `disc_detainer`, `dial_safe`.

---

## 5. Wynik po poprawkach

### 5.1 Pary, które się zmieniły (pion 412×915)

| Rodzina | Para | Przed % | Po % | Co widać |
|---|---|---|---|---|
| `dimple` | bound / stress | **0,18** | 1,39 | chorągiewka opada rękojeścią w kanale klucza |
| `magnetic` | bound / stress | **0,18** | 1,56 | sonda opada rękojeścią |
| `wafer` | bound / stress | **0,18** | 1,02 | wytrych schodzi z linii |
| `time_lock` | bound / stress | **0,19** | 0,78 | pęseta odchylona |
| `lever` | bound / stress | **0,18** | 0,32 | podnośnik odsunięty od brzucha dźwigni — **tuż nad progiem**, patrz §6 |
| `lever_detector` | bound / stress | **0,18** | 0,33 | jw. |
| `axial_slider` | bound / stress | **0,19** | 0,40 | popychacz opada przed ramką |
| `axial_slider` | free / false_set | **0,00** | 0,86 | czoło rdzenia o 2 podziałki na suwak |
| `axial_slider` | bound / false_set | 1,54 | 2,41 | jw. |
| `axial_slider` | set / false_set | 1,23 | 1,99 | czoło: 1 podziałka kontra 2, plus nacięcie na sztabie albo obok |
| `axial_slider` | free / set, bound / set | 1,23 / 2,70 | 1,98 / 3,45 | czoło +1 podziałka |
| `egyptian` | free / set, bound / set | 1,98 / 2,93 | 2,73 / 3,69 | czoło +1 podziałka |
| `time_lock` | free / set, bound / set | 6,04 / 5,98 | 6,80 / 6,74 | czoło +1 podziałka |

Pozostałe pary tych rodzin ze stanem `stress`, `set` albo `false_set` zmieniły się o tyle samo (0,1–1,4 punktu w górę;
pary z `open` o −0,06…−0,19, bo ustawione czoło stoi bliżej pozycji otwarcia). Pełna tabela: `state_matrix.py`.

**Bez zmian co do piksela** (9 póz każda): `pin_tumbler`, `warded`, `combo`, `disc_detainer`, `dial_safe`.
Tylko poza `stress`: `lever`, `lever_detector`, `dimple`, `magnetic`, `wafer`. `axial_slider`: `set`, `false_set`, `stress`.
`egyptian`: `set` (oraz sztuczne pozy `false_set` i `stress`, których ta rodzina w grze nie ma). `time_lock`: `set`, `stress`
(i `open`, ale tam kręci się pociąg kół, więc kadr zależy od chwili zrzutu).

### 5.2 Wiersz „blisko złamania” i pary poniżej 1 % po poprawkach

| para | pin tumbler | dimple | magnetic | wafer | time lock | egyptian | lever | lever detector | axial slider | warded | combo | disc detainer | dial safe |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| bound / stress | 0.73 | 1.39 | 1.56 | 1.02 | 0.78 | – | 0.32 | 0.33 | 0.40 | 0.58 | – | – | – |
| free / false_set | 5.73 | 5.73 | 5.73 | – | – | – | 8.66 | 6.81 | 0.86 | – | 0.94 | 1.35 | 0.25 |
| bound / false_set | 6.02 | 6.02 | 6.02 | – | – | – | 9.12 | 7.35 | 2.41 | – | 0.79 | 1.10 | 0.25 |
| free / bound | 1.16 | 1.16 | 1.16 | 1.59 | 2.10 | 0.95 | 4.08 | 2.62 | 1.54 | 1.27 | 0.27 | 0.51 | **0.00** |
| free / near | 6.90 | 6.78 | 5.57 | 4.04 | 5.14 | 2.32 | 5.40 | 3.91 | 2.25 | **0.00** | 0.60 | 0.98 | 8.97 |
| bound / near | 6.08 | 5.95 | 4.74 | 3.50 | 5.23 | 1.50 | 2.69 | 2.18 | 0.87 | 1.27 | 0.33 | 0.47 | 8.97 |

Poniżej progu zostają dwie pary z §3.3. Z pięciu stanów głównych (wiąże, ustawiony, fałszywie ustawiony, przepchnięty,
blisko złamania) **żadna para nie jest poniżej progu w żadnej rodzinie** (przed: 7).

### 5.3 Poziom 915×412

Spot-check całej macierzy po poprawkach (117 póz) i przed poprawkami dla rodzin zdjętych przed zmianą kodu
(`pin_tumbler`, `warded`, `wafer`, `lever`, `lever_detector`). W poziomie przekrój jest rysowany w skali ok. 0,74 pionu,
a miara liczy odsetek **całego** kadru 915×412, więc liczby są ok. 2,3 raza mniejsze niż w pionie. Tej samej powierzchni
co próg w pionie (ok. 700 dp²) odpowiada tu **0,19 %**.

| para | pin tumbler | dimple | magnetic | wafer | time lock | egyptian | lever | lever detector | axial slider | warded | combo | disc detainer | dial safe |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| free / bound | 0.48 | 0.48 | 0.48 | 0.63 | 0.90 | 0.44 | 1.71 | 1.13 | 0.73 | 0.53 | 0.06 | 0.14 | 0.00 |
| bound / near | 2.54 | 2.47 | 1.96 | 1.45 | 2.27 | 0.60 | 1.14 | 0.93 | 0.36 | 0.53 | 0.11 | 0.18 | 3.80 |
| bound / set | 3.34 | 3.33 | 2.96 | 2.70 | 3.15 | 1.85 | 3.34 | 2.69 | 1.77 | 0.43 | 0.98 | 0.85 | 4.60 |
| free / false_set | 2.67 | 2.66 | 2.67 | – | – | – | 3.96 | 3.17 | 0.64 | – | 0.29 | 0.41 | 0.11 |
| bound / false_set | 2.78 | 2.78 | 2.78 | – | – | – | 4.14 | 3.41 | 1.37 | – | 0.28 | 0.34 | 0.11 |
| set / false_set | 1.65 | 1.64 | 1.27 | – | – | – | 4.77 | 4.03 | 1.08 | – | 0.92 | 0.81 | 4.61 |
| bound / overset | 4.85 | 4.57 | 3.82 | 3.19 | 3.35 | 2.27 | 6.18 | 5.07 | 2.56 | – | 0.80 | 0.48 | – |
| bound / stress | 0.37 | 0.62 | 0.72 | 0.49 | 0.40 | – | 0.19 | 0.20 | 0.24 | 0.34 | – | – | – |
| set / open | 6.26 | 6.44 | 6.27 | 6.29 | 2.91 | 1.55 | 2.05 | 0.86 | 0.79 | 2.10 | 1.00 | 0.48 | 2.85 |

- `bound / stress` przed → po: `wafer` 0,14 → 0,49; `lever` 0,14 → 0,19; `lever_detector` 0,14 → 0,20; `pin_tumbler` 0,37 i
  `warded` 0,34 bez zmian. Układ żadnej rodziny nie gubi w poziomie znaku, który ma w pionie: te same kształty, mniejsze.
- **Poniżej 0,19 % zostają w poziomie delikatne pary rodzin z kółkami i sejfu:** `combo` swobodne / wiąże 0,06 i
  wiąże / blisko 0,11; `disc_detainer` 0,14 i 0,18; `dial_safe` wiąże / fałszywe nacięcie 0,11. Zamek z kółkami jest
  szeroki i płaski, więc w poziomie jego przekrój ma ok. 275 dp szerokości i szczelina zęba nad tuleją (0,22 mm) to
  ok. 1,5 dp — mniej niż 2–3 dp z `DESIGN.md` §1. To sprawa układu ekranu w poziomie, nie kodu stanów (sprawa otwarta 5).
- `lever` / `lever_detector` są w poziomie dokładnie na równoważnym progu (0,19–0,20 %).

---

## 6. Co zostaje i dlaczego

| Rodzina | Para | % | Dlaczego zostaje |
|---|---|---|---|
| `dial_safe` | swobodna / wiąże | 0,00 | W lockcore tarcza „wiąże”, kiedy zabierak ją niesie, czyli kiedy się kręci. Nieruchomy kadr tarczy niesionej i stojącej w tym samym miejscu jest tym samym obrazem; sygnałem jest ruch tarczy razem z pokrętłem, klik zabrania (`safe.pickup`) i haptyka. Nieruchomy znak wymagałby narysowania zabieraka — nowa warstwa grafiki (sprawa otwarta 1). |
| `warded` | swobodna / blisko | 0,00 | Ograniczenie metody: widok rysuje sondę i przeszkody, a „blisko” to położenie sondy w prześwicie przeszkody. Poza trzyma sondę w miejscu. W grze stan widać jako sondę w prześwicie (D-90: 0,59–1,9 % dla pozostałych par). |
| `dial_safe` | wiąże / fałszywe nacięcie | 0,25 | Czujnik opada o 1 mm (ok. 4 dp) w płytkie nacięcie zamiast o 3 mm w bramkę; nacięcie jest narysowane przy czubku czujnika. Kształt jest, mały. Dokładnie na progu. |
| `combo` | swobodne / wiąże | 0,27 | Ząb nad tuleją (szczelina 0,22 mm ≈ 2 dp) kontra ząb na tulei. To wielkość z `DESIGN.md` §1 dla „wiąże” (2–3 dp); wiązanie w tej rodzinie jest z założenia do wyczucia, nie do zobaczenia z daleka. |
| `combo`, `disc_detainer` | wiąże / blisko | 0,33 / 0,47 | „Blisko” to otwierająca się pod zębem szczelina bramki — rośnie płynnie z obrotem kółka. |
| `lever`, `lever_detector` | wiąże / blisko złamania | 0,32 / 0,33 | Powyżej progu, ale ledwo: podnośnik jest prawie czarny na czarnym wnętrzu skrzynki, więc jego odchylenie zmienia mało pikseli o więcej niż 12/255. Główny nieruchomy znak to dalej rysy na napinaczu. Jaśniejszy podnośnik to nowy render (sprawa otwarta 2). |
| `axial_slider` | swobodny / fałszywe nacięcie | 0,86 | Znak jest tylko na czole rdzenia (HUD). W samym przekroju suwak w fałszywym nacięciu dalej wygląda jak suwak w drodze: warstwy `slider*.png` nie mają narysowanych fałszywych nacięć (sprawa otwarta 3). |
| `axial_slider` | wiąże / blisko | 0,87 | Suwak przesunięty o 0,10 drogi; „blisko” to położenie nacięcia tuż przed sztabą. |
| `disc_detainer` | ustawiony / otwarty | 0,69 | Rygiel na końcu rdzenia jest mały w kadrze; otwarcie to też obrót czoła o 90°, dźwięk, haptyka i 850 ms pauzy przed zmianą ekranu (D-130). |
| wszystkie z kołkami | wiąże / blisko | 3,5–6,1 | Ten sam kształt (pochylenie 2,2°), inna wysokość: „blisko” to położenie względem linii podziału, zgodnie z `DESIGN.md` §1. Bez kredy nie ma klina szczeliny. |

Stany, których w ogóle nie widać inaczej niż ruchem albo dźwiękiem, są dwa i oba opisane wyżej (`dial_safe` wiąże,
`warded` blisko w sztucznej pozie). Wszystkie pozostałe mają nieruchomy znak kształtu albo położenia.

---

## 7. Sprawy otwarte dla właściciela

Żadnej nie rozstrzygałem: każda wymaga nowej grafiki albo zmiany znaczenia istniejącego znaku.

1. **`dial_safe`: zabierak.** Czy dorobić warstwę z zabierakiem (kołek na tarczy napędowej i na każdej tarczy), żeby
   „ta tarcza jest teraz niesiona” było widać w nieruchomym kadrze? Rekomendacja: tak, przy najbliższym przerenderowaniu
   płyt sejfu; do tego czasu ruch + klik + haptyka wystarczają (trzy kanały są).
2. **`lever` / `lever_detector`: podnośnik i napinacz w przekroju są prawie czarne na czarnym tle** — kontrast
   metal / tło wygląda na dużo poniżej 3:1 z `CLAUDE.md`. To sprawa renderu części (`parts.png`), nie kodu.
   Rekomendacja: jaśniejsza stal narzędzi w następnym przebiegu Cycles; wtedy odchylenie z poprawki A zrobi swoje.
   Podobnie ciemne w szarości są całe ekrany `wafer` i `warded` (widać na arkuszach) — do tej samej tury.
3. **`axial_slider`: fałszywe nacięcia na suwakach.** Warstwy suwaków mają tylko prawdziwe nacięcie. Rekomendacja:
   dorysować w renderze płytkie nacięcia (1–3 na suwak, wg `false_gates` zamka) albo zgodzić się na rysowane w kodzie
   ciemne wcięcie pod sztabą, jak robi to `combo_view.gd` dla fałszywych nacięć kółek. Nie zrobiłem tego sam, bo to
   już dorabianie grafiki mechanizmu.
4. **Rysy na napinaczu znaczą dwie rzeczy.** W `combo` / `disc_detainer` (poślizg przy zbyt szybkim kręceniu) i w
   `dial_safe` (zacięcie przy zbyt mocnej klamce) widok ustawia `PlugFace.tremor`, więc na ramieniu pojawiają się te
   same 1→3 rysy, które wszędzie indziej znaczą „narzędzie zaraz pęknie” — a w tych rodzinach nic nie pęka.
   Rekomendacja: zostawić ugięcie ramienia, a rysy zarezerwować dla prawdziwego stresu. To zmiana znaczenia znaku,
   więc pytam, zanim ruszę.
5. **Poziom, rodziny z kółkami.** W 915×412 przekrój `combo` / `disc_detainer` jest na tyle mały, że „wiąże” to ok.
   1,5 dp ruchu zęba (§5.3). Czy w poziomie powiększyć przekrój tych dwóch rodzin kosztem skórzanych pól pod kciuki,
   czy przyjąć, że w poziomie wiązanie w tych zamkach jest wyłącznie do usłyszenia i wyczucia? Rekomendacja: powiększyć
   przy najbliższej turze układu poziomego; zmiana układu ekranu to nie jest poprawka „stanu”, więc jej tu nie robiłem.
6. **Do potwierdzenia na telefonie:** czy 3° odchylenia narzędzia czyta się jako „za mocno”, a nie jako błąd rysunku
   (w `dimple` rękojeść chorągiewki schodzi o ok. 10 dp przy lewej krawędzi przekroju).
7. **Poza zakresem, ale wyszło w pełnym GUT:** samouczek, etap 1, tryb „dwa kciuki”, 412×915 z paskiem gestów 34 dp —
   przycisk „Start” wychodzi 7 dp pod bezpieczny obszar, a test `test_tutorial_respects_the_safe_area` nie ustawia sobie
   trybu sterowania (bierze go z `user://settings.cfg`), więc jest zielony albo czerwony zależnie od maszyny.
   Do poprawienia osobno (układ ekranu samouczka + test, który sprawdza oba tryby).

---

## 8. Testy i powtórzenie

- `game/tests/gut/test_lock_states_d139.gd` (8 testów): odchylenie zaczyna się od pierwszej rysy (0 poniżej stresu 0,6,
  3° przy 1,0), jest jedną nieruchomą pozą przy ograniczeniu ruchu, rękojeść idzie w dół (popychacz, pęseta),
  podnośnik dźwigni i wytrych płytkowy nie ruszają się poniżej 0,6; czoło rodzin warstwowych: 0 / +1 / +2 podziałki
  i 90° po przytrzymaniu; zamek bębenkowy zachowuje własne wygięcie haka i nic w nim się nie obraca.
- Pełny GUT (kod końcowy): **687 testów, 686 zielonych, 1 czerwony, 76 721 / 76 722 asercji, 0 `SCRIPT ERROR`.**
  Czerwony to `test_visual_qa_d129.gd` → `test_tutorial_respects_the_safe_area` („StartButton [P: (16, 832), S: (376, 56)]
  in the safe area”): **nie pochodzi z tej zmiany** — ten sam komunikat na `b2667e4c` z widokami zamków cofniętymi do
  `HEAD`. Wynik zależy od `auto_tension` w `user://settings.cfg` maszyny: przy `false` (tak było tutaj) ekran samouczka
  w trybie „dwa kciuki” ma trzy klatki i przycisk „Start” kończy się 7 dp pod bezpiecznym obszarem (pasek gestów 34 dp,
  412×915); przy `true` test przechodzi. Ustawienie przywróciłem do zastanego. Sprawa otwarta 7.
- Zrzuty przed / po: `pin_tumbler`, `warded`, `combo`, `disc_detainer`, `dial_safe` identyczne co do piksela (45 póz).

```bash
# zrzuty (pod llvmpipe ok. 12 s na pozę, 25 min na 13 rodzin; na GPU sekundy)
xvfb-run -a -s "-screen 0 1000x1000x24" env LIBGL_ALWAYS_SOFTWARE=1 GALLIUM_DRIVER=llvmpipe <godot> --path game \
  --display-driver x11 --rendering-driver opengl3 res://tests/a11y_state_shots.tscn -- \
  --out=<dir> --size=412x915 --reduce=1 --chalk=off
python3 qa/a11y/state_report.py <dir>                      # arkusze kolor / szarość / deutan / protan + report.md
python3 qa/a11y/state_matrix.py <dir> --before <dir_przed> --sheets <dir_arkuszy>   # tabela rodzina × para
```

## 9. Zrzuty

`docs/handoff/device-tests/fixes/lock_states/`:
- `<rodzina>_after_412x915.jpg` — 13 rodzin, wiersze kolor / szarość, kolumny: stany, które rodzina ma;
- `<rodzina>_before_412x915.jpg` — to samo przed poprawkami dla 8 rodzin, których dotyczą zmiany;
- `stress_before_after_gray_412x915.jpg`, `…_colour_…` — przekrój: wiąże / blisko złamania przed / po (7 rodzin);
- `axial_slider_false_set_before_after_gray.jpg`, `…_colour.jpg` — ustawiony i fałszywe nacięcie, przed / po;
- `<rodzina>_after_915x412.jpg` — poziom, po poprawkach (13 rodzin).
