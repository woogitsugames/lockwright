# LOCKS — biblia rodzin zamków

Status: szkic etapu researchu (2026-11-04). Dokument opisuje **logikę zagadek**, nie budowę realnych zamków.
Wszystkie mechanizmy są uogólnione i częściowo wymyślone; tolerancje dobrano pod grywalność.
Nazwy osób w kartach (wynalazcy) to wyłącznie kontekst historyczny tego dokumentu. W grze rodziny noszą
nazwy ogólne (np. „zamek suwakowy”), bez nazwisk i bez marek. Powiązane: `docs/TOOLS.md`, `docs/DESIGN.md`,
`docs/ARCHITECTURE.md`, `docs/PROGRESSION.md`.

Spis treści
1. Wspólny model
2. Karty rodzin (17)
3. Tabela zbiorcza
4. Ryzyka projektowe
5. Wzór karty
6. Źródła

---

## 1. Wspólny model

### 1.1 Moduł rodziny (interfejs)

Każda rodzina to moduł za tym samym interfejsem. Pseudo-sygnatury (to opis kontraktu, nie kod gry):

```
LockFamily {
  id, version                         // np. "pin_tumbler", gen v3
  generate(seed, tier, overrides) -> LockDef      // czysta funkcja, deterministyczna
  init(LockDef) -> State
  step(State, Input) -> (State, Event[])          // jeden krok 1/120 s
  verify(LockDef, ToolSet, Budget) -> Verdict     // weryfikator otwieralności (1.7)
  view(State) -> ViewModel                        // tylko dane do rysowania, bez logiki
}
```

Zasady:
- `step` jest jedynym miejscem zmiany stanu. Obraz, dźwięk i haptyka tylko czytają zdarzenia i `ViewModel`.
- Arytmetyka stałoprzecinkowa (int32, pozycje w Q16: 0..65535 = pełny skok elementu). Bez `sin/cos/pow` z biblioteki
  systemowej w logice (tablice lub wielomiany na liczbach całkowitych). Powód: identyczny wynik na iOS/Android/CI,
  powtórki (replay) i weryfikator zgodny z grą.
- Losowość tylko z PRNG zainicjowanego seedem (np. PCG32 / xoshiro). Seed zamka:
  `seed_lock = hash64(run_seed, lock_index, family_id, family_gen_version)`. Wersja generatora w seedzie gwarantuje, że
  aktualizacja rodziny nie zmienia starych zapisów (stare seedy grają starą wersją albo są jawnie migrowane).
- Powtórka = `LockDef` + log wejść (po kwantyzacji). Hash stanu co 120 kroków służy do testów determinizmu.

### 1.2 Stały krok czasu: 120 Hz (decyzja proponowana)

Zostawiamy sugerowane **120 Hz (krok 8,33 ms)**. Uzasadnienie:
- ekrany 120 Hz są standardem w telefonach z wyższej półki; na 60 Hz wykonujemy 2 kroki na klatkę, na 90 Hz
  naprzemiennie 1–2 kroki (akumulator czasu), obraz interpolujemy;
- 8,33 ms to rozdzielczość wystarczająca do rozróżnienia „kliknięć” (set kontra false_set kontra serration) w dźwięku
  i haptyce; opóźnienie silników haptycznych telefonu i tak jest rzędu kilkunastu ms, więc 240 Hz nic nie daje graczowi;
- logika jest tania (≤ 64 elementy, proste reguły), koszt kroku docelowo < 50 µs na słabym urządzeniu;
- wszystkie czasy w danych zapisujemy **w krokach (tickach)**, w dokumentach podajemy ms dla czytelności
  (np. `drop_grace` 200 ms = 24 kroki).

Wejście dotykowe jest próbkowane asynchronicznie; na początku kroku bierzemy ostatnią znaną wartość
(sample-and-hold), kwantyzujemy i zapisujemy do logu. Gdyby testy na urządzeniach pokazały problemy z baterią,
alternatywą jest 60 Hz logiki z podziałem zdarzeń na pół-kroki — ale nie zalecamy, bo komplikuje weryfikator.

### 1.3 Wejścia

| Wejście | Kciuk | Zakres | Kwantyzacja | Uwagi |
|---|---|---|---|---|
| `tension` | lewy (pionowy suwak/łuk) | 0..1 | 1/256 | moment na rdzeń / ciąg zasuwy / ciąg kabłąka, zależnie od rodziny |
| `pick_depth` | prawy (oś X pola) | 0..1 | 1/256 | który element (pozycja wzdłuż kanału); przyciągany „magnesem” do najbliższego elementu ± 30% podziałki |
| `pick_lift` | prawy (oś Y pola) | -1..1 | 1/256 | uniesienie; ujemne = nacisk w dół (rodziny dwustronne, dźwignie z tyłu) |
| `rotate` | prawy, gest obrotu lub drugi tryb pola | -1..1 (prędkość) | 1/256 | tarcze, pierścienie, pokrętło sejfu, wkręt sondy |
| `push` | prawy, docisk/przytrzymanie | 0..1 | 1/64 | wciśnięcie (suwaki osiowe, rurkowe, dimple) |
| `tool_swap` | przycisk | dyskretne | — | zmiana narzędzia; kosztuje 0,5 s (60 kroków) i, jeśli `tension` < `t_hold`, powoduje `drop` |

Moduł deklaruje, których wejść używa (`input_mask`). UI pokazuje tylko te kontrolki.

### 1.4 Stany elementu (wspólne)

```
free        – element luźny, sprężyna dociska go do spoczynku
bound       – element wiąże (blokuje obrót) i stawia opór ruchowi
near        – bound i w pobliżu linii podziału / bramki (sygnał near_shear)
set         – prawdziwie ustawiony; trzyma, dopóki tension ≥ t_hold
false_set   – ustawiony fałszywie (element zabezpieczający); rdzeń drgnął, ale zagadka trwa
overset     – przepchnięty; blokuje, dopóki gracz nie zwolni napięcia (lub dana rodzina nie ma innego wyjścia)
jammed      – zablokowany przez mechanizm specjalny (np. detektor); wymaga sekwencji resetu
```

Rodzina może dodać własne podstany (np. `lever.in_false_gate`), ale musi je odwzorować na jeden ze stanów wspólnych
dla warstwy prezentacji (kod stanów w `docs/DESIGN.md`).

### 1.5 Model napięcia (wspólny rdzeń)

Wszystkie rodziny „z napięciem” korzystają z tego samego modelu; rodziny bez napięcia (np. zegar) go nie używają.

- `T = tension × k_tool` — efektywny moment; `k_tool` zależy od napinacza (1,0 dla podstawowego).
- **Kolejność wiązania (binding order):** generator nadaje każdemu elementowi przesunięcie tolerancji `o_i`.
  Spośród nieustawionych elementów wiąże ten z najmniejszym `o_i`, gdy `T ≥ t_bind`. Na wyższych tierach z
  prawdopodobieństwem `multi_bind_p` wiążą dwa naraz (gracz musi wyczuć, który jest „twardszy”).
- **Tarcie wiązania:** element `bound` rusza dopiero, gdy siła uniesienia > `μ × T`. Za duże napięcie = element
  „nie chce iść”; to naturalnie tworzy **pasmo napięcia** (sweet spot).
- **Trzymanie i zrzut:** ustawione elementy trzymają, gdy `T ≥ t_hold`. Gdy `T < t_hold` nieprzerwanie przez
  `drop_grace` kroków → zdarzenie `drop` (w samouczku spada tylko ostatni element, od tieru 3 wszystkie).
- **Naprężenie narzędzia (stress):** gdy narzędzie dociska element `bound` przy `T > τ_safe(tool)`, akumulator
  `S += (T − τ_safe) × |Δlift| × k_s`. Poniżej progu `S` maleje (`decay` na krok). `S ≥ 0,6·S_max` → `stress`
  (powtarzane z rosnącą intensywnością), `S ≥ S_max` → `break`. Zużycie obniża `S_max` (patrz `docs/TOOLS.md`).
- **Set:** element `bound` w oknie linii podziału przy `T ≥ t_hold` → `set`, rdzeń obraca się o mikrokąt
  (widoczny, ≥ 2 dp ruchu), kolejny element zaczyna wiązać.
- **Overset:** element `bound` przepchnięty powyżej okna o `overset_margin` → `overset`. Wyjście: obniżyć napięcie
  poniżej `t_release` (najczęściej kosztem `drop`).

Efektywne pasmo pracy dla elementu i: `[max(t_hold, t_bind_i), min(τ_safe, t_stick_i)]`, gdzie `t_stick_i` to napięcie,
przy którym siła maksymalnego uniesienia przestaje pokonywać tarcie. Jego szerokość to główne pokrętło trudności.

### 1.6 Słownik zdarzeń

Zdarzenie: `{tick, type, element_id?, intensity 0..1, dir?, meta?}`. Logika emituje wszystko; warstwa prezentacji
filtruje (np. max 1 zdarzenie haptyczne na element na 30 ms; priorytet: `break` > `stress` > `open` > `set` >
`false_set` > `counter_rotate` > `overset` > `drop` > `detector_trip` > `gate_align` > `near_shear` > `bind` > `contact` > `wear`).

| Zdarzenie | Znaczenie | Typowe `intensity` |
|---|---|---|
| `contact` | narzędzie dotyka elementu | twardość materiału (drewno 0,2 … stal 0,8) |
| `bind` | element zaczyna trzymać/wiązać | proporcjonalna do T |
| `near_shear` | element w pobliżu linii podziału/bramki (do 1,5 × okna) | rośnie przy zbliżaniu |
| `set` | prawdziwe ustawienie | stała, wyraźna |
| `false_set` | fałszywe ustawienie (element zabezpieczający, fałszywa bramka) | nieco słabsza niż `set`, inna barwa |
| `counter_rotate` | rdzeń cofa się pod naciskiem (szpulka, fałszywa bramka) | proporcjonalna do nacisku |
| `overset` | przepchnięcie | ostra, krótka |
| `drop` | zrzut ustawionych elementów | liczba spadłych / n |
| `stress` | narzędzie blisko złamania | S / S_max |
| `break` | złamanie | 1 |
| `wear` | narzędzie zyskało zużycie (próg co 10 pkt) | — |
| `gate_align` | dźwignia/tarcza/pierścień w bramce | 1 |
| `detector_trip` | detektor zablokował zamek | 1 |
| `open` | zamek otwarty | 1 |

Zdarzenia rodzinne mają prefiks `rodzina.` (np. `pin.serration`). Każde jest opisane w karcie i musi mieć mapowanie
„najbliższego zdarzenia wspólnego” — warstwa prezentacji może je zagrać jak to wspólne, jeśli nie ma dedykowanego zasobu.

### 1.7 Okno tolerancji i strojenie pod grywalność

**Okno tolerancji** = zakres wartości wejścia (lub pozycji elementu), w którym akcja się udaje. Każda rodzina ma
co najmniej trzy okna:
1. **okno pozycji** (`win_shear`, % skoku elementu) — gdzie element się ustawia;
2. **pasmo napięcia** (`tension_band`, szerokość efektywnego pasma z 1.5);
3. **okno czasu** (`drop_grace`, czasy zatrzymania, czas reakcji na `counter_rotate`).

Strojenie:
- Wartości bazowe wynikają z **możliwości kciuka**, nie z realizmu: przyjmujemy, że gracz po nauce trzyma napięcie
  z odchyleniem ok. ±0,04 i trafia pozycję ±3% skoku. Okno < 2× tej precyzji jest „mistrzowskie”, < 1,5× — zakazane
  (weryfikator odrzuca).
- Okna zapisane w danych jako tabela per tier; dostrajane po playtestach bez zmiany kodu.
- Dostępność: opcja „Szersze okna” mnoży okna ×1,5 (oznaczenie w wyniku, bez kar w Trybie Ciągłym — do decyzji).
- Tryb „w ciemności”: okna ×1,15, bo gracz traci kanał wzroku; `near_shear` dostaje wyraźniejszą rampę dźwięku.
- Okno zawsze ma **strefę przed-sygnału** (`near_shear`), żeby gracz uczył się od informacji, nie od zgadywania.

### 1.8 Trudność jako wektor

Tier (1–10) wybiera **rozkład** wektora trudności, nie jedną liczbę. Wektor `D`:

| Oś | Parametry | Co odczuwa gracz |
|---|---|---|
| Złożoność | `n_elem`, `sec_count`, rodzaje zabezpieczeń | dłużej, więcej do zapamiętania |
| Precyzja | `win_shear`, `tension_band`, `overset_margin` | trudniej trafić |
| Czytelność | `fb_gain` (siła sygnałów), `noise` (szum kontaktów), podobieństwo `false_set`/`set` | trudniej odczytać |
| Kolejność | `bind_spread` (jak różne są `o_i`), `multi_bind_p` | trudniej znaleźć wiążący |
| Zasoby | `S_max`, `drop_grace`, limit czasu (Zlecenia) | mniej miejsca na błąd |

Zasady:
- W jednym zamku podnosimy maksymalnie **dwie osie naraz** względem poprzedniego zamka w serii (Tryb Ciągły), żeby
  gracz wiedział, czego się uczy.
- Po generacji weryfikator liczy **zmierzoną trudność** `M` (czas bota, minimalny margines napięcia, liczba
  potrzebnych resetów). Generator odrzuca seedy z `M` poza pasmem tieru. Seria sortuje zamki po `M`.
- Czas docelowy człowieka: t1–2: 30–60 s, t3–5: 45–120 s, t6–8: 60–150 s, t9–10: 90–180 s.

### 1.9 Weryfikator otwieralności

Każdy wygenerowany zamek musi przejść **trzy** sprawdzenia, zanim trafi do gracza (offline w CI dla danych stałych;
w grze dla seedów proceduralnych, budżet ≤ 20 ms na zamek, w tle podczas animacji przejścia):

1. **Wyrocznia analityczna (oracle).** Zna pełny stan. Sprawdza, że dla każdego kroku planu (kolejność wiązania,
   zabezpieczenia, bramki) istnieje pasmo napięcia o szerokości ≥ `δ_human` (domyślnie 0,08) i okno pozycji ≥ 1,5×
   precyzji kciuka, przy narzędziach z bieżącego zestawu gracza i bez przekroczenia `τ_safe`.
2. **Bot skryptowy.** Wykonuje plan wyroczni przez **prawdziwą** funkcję `step` z ograniczeniami człowieka:
   kwantyzacja wejść 1/64, maks. prędkość zmian (`tension` 1,5/s, `lift` 3/s), opóźnienie reakcji 180 ms,
   minimalny czas zatrzymania 100 ms. Musi otworzyć zamek w budżecie: czas ≤ 0,5 × limitu tieru, `S` nigdy ≥ 0,8·S_max,
   bez `break`. To łapie błędy, w których analiza i symulacja się rozjeżdżają.
3. **Bot czujący (blind).** Widzi tylko zdarzenia (z szumem i opóźnieniem), jak gracz w trybie „w ciemności”.
   Nie musi zawsze wygrać; jego wskaźnik sukcesu i czas służą do kalibracji `M` i do wykrywania zamków „nieczytelnych”
   (np. `false_set` nieodróżnialny od `set`).

Werdykt: `OK | REJECT(reason) | OK_TOO_EASY | OK_TOO_HARD`. Generator ponawia z `seed' = hash(seed, attempt)`,
maks. 16 prób, potem fallback do zamka z puli ręcznie zweryfikowanej.

### 1.10 Plan testu na 10 000 seedów (CI)

Dla każdej kombinacji rodzina × tier × minimalny zestaw narzędzi:
1. Wygeneruj 10 000 seedów (stała lista „złotych” 1 000 + 9 000 losowych na build).
2. **Inwarianty (twarde, 100%):** wyrocznia OK; bot skryptowy otwiera; brak `break` w planie; generator nie rzuca
   wyjątków; `LockDef` serializuje się i deserializuje bit-w-bit.
3. **Determinizm:** każdy z 1 000 złotych seedów odtworzony dwukrotnie na x86 i ARM (emulator/urządzenie) z tym samym
   logiem wejść → identyczny hash stanu co 120 kroków.
4. **Fuzzing:** 10 000 seedów × 60 s losowych wejść (losowy spacer + skoki) → brak stanów niedozwolonych
   (pozycja poza 0..65535, element `set` przy T < t_hold dłużej niż `drop_grace`, ujemne `S`), brak zawieszeń.
5. **Rozkłady (miękkie, raport):** odsetek odrzuconych seedów < 5% (sprawność generatora); mediana `M` rośnie
   monotonicznie z tierem; p90 czasu bota czującego w paśmie z 1.8; wskaźnik sukcesu bota czującego w paśmie
   per tier (np. t2: 90–98%, t9: 40–70%).
6. **Czytelność:** dla każdego seeda minimalna różnica cech zdarzeń `set` vs `false_set` (intensywność, czas trwania)
   ≥ progu z `docs/DESIGN.md`.
7. **Wydajność:** p99 czasu `step` < 50 µs, `verify` < 20 ms na referencyjnym słabym urządzeniu.
8. Wynik: raport HTML/CSV w artefaktach CI, porównanie z poprzednim buildem (regresja > 2 p.p. w sukcesie bota = błąd).

---

## 2. Karty rodzin

Konwencja: **t** = tier, **MVP / F1 / F2 / F3** = faza wydania. Wartości w tabelach to propozycje do playtestu.
„%” w oknach = procent pełnego skoku elementu.

---

### 2.1 Zasuwa kołkowa (drewniana) — `wooden_pin`
**PL:** Zasuwa kołkowa „Khorsabad” · **EN:** Wooden Pin Bolt · **Tier:** t1 · **Faza:** MVP (samouczek)

**Epoka.** Drewniane zamki kołkowe znane z Egiptu i Bliskiego Wschodu w starożytności; często przytaczany egzemplarz
z ruin pałacu Sargona II w Chorsabadzie (pałac budowany ok. 717–706 p.n.e., opuszczony po 705 p.n.e.).
**Niepewność:** popularne twierdzenia, że jest to „najstarszy zamek” i ma „4000 lat”, są kwestionowane w literaturze
(Potts 1990); daty „ok. 2000 p.n.e. w Egipcie” są szacunkowe. W grze: „zamek z dawnych czasów”, bez precyzyjnej daty.

**Zasada działania.** Drewniana zasuwa ma otwory; z obsady nad nią opadają kołki i blokują ją. Klucz z kołeczkami
unosi wszystkie naraz do poziomu, przy którym zasuwę można przesunąć.

**Logika zagadki.**
- Stany kołka: `free` → `bound` (zasuwa ciągnięta, kołek się klinuje) → `set` (uniesiony do krawędzi obsady).
  Brak overset w samouczku 1–2; od proceduralnych: zbyt wysokie uniesienie zaklinowuje kołek w obsadzie (`overset`).
- Wejścia: `tension` = ciąg zasuwy w bok; `pick_depth` wybiera kołek; `pick_lift` unosi.
- Zdarzenia: `contact` (miękki, drewniany), `bind`, `near_shear`, `set`, `overset`, `drop` (puszczenie zasuwy),
  `open` (zasuwa wysuwa się). Rodzinne: `wood.creak` (skrzypnięcie przy dużym ciągu; mapuje na `stress`, ale
  w tej rodzinie narzędzie się **nie łamie** — to rodzina nauki).
- Otwarcie: wszystkie kołki `set` i `tension ≥ t_hold` przez 0,3 s (zasuwa przesuwa się płynnie).
- Porażka: brak (samouczek); w serii proceduralnej tylko limit czasu.

**Parametry generatora.**

| Parametr | Zakres | Jednostka | Skalowanie |
|---|---|---|---|
| `n_elem` | 2–4 | kołki | 2 (samouczek) → 4 |
| `win_shear` | 18–12 | % | szerokie zawsze |
| `bind_spread` | duży–średni | — | kolejność wyraźna |
| `t_hold` | 0,10 | 0..1 | stałe |
| `overset_margin` | ∞ → 15 | % | overset dopiero w proceduralnych |

**Krzywa trudności.** Samouczek 1: jeden kołek, tylko unoszenie (bez napięcia). Samouczek 2: dwa kołki, pojawia się
ciąg zasuwy i zrzut przy puszczeniu. Samouczek 3: trzy kołki, kolejność wiązania. Proceduralne: 3–4 kołki, overset.
Mistrzowskie: nie dotyczy (rodzina kończy się na t1; wraca jako ciekawostka w Gablocie).

**Narzędzia.** Podważka kołkowa / Peg Lifter (startowe). Bez napinacza — ciąg zasuwy robi lewy kciuk „ręką”.

**Materiały i wygląd.** Jasne drewno z widocznymi słojami, ciemniejsze kołki z czopami; obsada z grubszej belki.
Przekrój: zasuwa poziomo, kołki pionowo nad otworami, linia podziału = dolna krawędź obsady (gruba, 3 dp).

**Haptyka i dźwięk.** Miękkie, niskie „puk” drewna (`contact`, `set`), tarcie zasuwy (szum ciągły ∝ tension),
`wood.creak`. Najmniej ostre zdarzenia w grze — wprowadza słownik bez stresu.

**Czytelność 2,5D.** 2–4 kołki po 40 dp szerokości, podziałka 72 dp — bardzo czytelne. Kamera: przekrój boczny,
lekko z góry (10°), zasuwa w dolnej tercji ekranu, nad strefą kciuków.

**Realizm kontra zabawa.** Realny klucz unosi wszystkie kołki naraz i nie ma „binding order”; dodajemy go, bo to
lekcja przed wkładką bębenkową. Uczciwie mówimy w Gablocie: „w grze uprościliśmy”.

---

### 2.2 Zamek zapadkowy (z zapadkami / warded) — `warded`
**PL:** Zamek zapadkowy · **EN:** Warded Lock · **Tier:** t1–2 · **Faza:** MVP

**Epoka.** Jedna z najstarszych konstrukcji; znana w starożytnym Rzymie (i według części źródeł w Chinach);
rozwinięta w średniowieczu (bogato zdobione zamki klasztorne i skrzyniowe). Brak jednej daty — uczciwie: „od starożytności”.

**Zasada działania.** Wewnątrz są stałe przeszkody (zapadki/wards). Klucz o pasującym profilu omija je przy obrocie
i dopiero wtedy popycha sprężynującą zasuwkę.

**Logika zagadki.** To zagadka **przestrzenna**, nie napięciowa.
- Stany: grot narzędzia ma pozycję (głębokość, wysokość) i kąt obrotu; przeszkody to łuki na określonych kątach.
  Element „zasuwka” ma stany `free` → `bound` (grot oparty) → `set` (podniesiona sprężyna) → `open`.
- Wejścia: `pick_depth`, `pick_lift`, `rotate`. `tension` służy jako **siła obrotu**; przy kontakcie z przeszkodą
  rośnie `stress` (narzędzie się gnie, nie łamie się w t1).
- Zdarzenia: `contact` (zgrzyt o przeszkodę), `gate_align` (grot w prześwicie przeszkody), `bind` (oparcie o
  zasuwkę), `set`, `stress`, `wear`, `open`. Rodzinne: `ward.scrape` (ciągłe tarcie o przeszkodę; mapuje na `contact`).
- Otwarcie: obrót o pełny kąt (np. 180°) bez kolizji, z grotem na wysokości zasuwki.
- Porażka: w t2 trzy `stress` maks. = narzędzie zgięte → `break` (strata życia).

**Parametry generatora.**

| Parametr | Zakres | Jednostka | Skalowanie |
|---|---|---|---|
| `n_wards` | 1–4 | przeszkody | 1 → 4 |
| `ward_gap` | 30–14 | % promienia | maleje |
| `bit_options` | 1–3 | groty do wyboru | rośnie (wybór profilu przed obrotem) |
| `bolt_spring` | 0,2–0,45 | wymagane `tension` | rośnie |
| `S_max` | ∞ → 3 kolizje | — | od t2 |

**Krzywa trudności.** Samouczek 1: jedna przeszkoda, prześwit widoczny. Samouczek 2: wybór grotu (kwadratowy / hak /
widełki). Samouczek 3: obrót przez dwie przeszkody na różnych kątach. Proceduralne: 2–3 przeszkody, wąskie
prześwity. Mistrzowskie: 4 przeszkody + przeszkoda ruchoma (sprężynka zmieniająca prześwit przy obrocie).

**Narzędzia.** Sonda przelotowa / Ward Probe (wymienne groty). Bez napinacza.

**Materiały i wygląd.** Kute żelazo, pokrywa z nitami, mosiężna rozeta. W przekroju (widok z czoła, „rentgen”)
koncentryczne łuki przeszkód jako grube pierścienie, grot jako wyraźna sylwetka.

**Haptyka i dźwięk.** Szorstki `ward.scrape`, suchy `set` zasuwki, metaliczny `open` z echem skrzyni.

**Czytelność 2,5D.** Widok **z czoła** (oś obrotu w ekran) z półprzezroczystą pokrywą; przeszkody ≥ 6 dp grubości,
prześwity ≥ 28 dp przy t2. Kamera: frontalna, zoom na mechanizm 300 dp średnicy.

**Realizm kontra zabawa.** W rzeczywistości te zamki są słabe, a „klucz uniwersalny” omija przeszkody prosto.
W grze robimy z nich labirynt obrotowy i nie uczymy o kluczach uniwersalnych (patrz `TOOLS.md`, wykluczenia).

---

### 2.3 Kłódka szyfrowa z pierścieniami — `ring_combo`
**PL:** Kłódka pierścieniowa · **EN:** Ring Combination Padlock · **Tier:** t2–3 · **Faza:** MVP

**Epoka.** Zamki z obrotowymi tarczami/pierścieniami znane już z okresu rzymskiego (znalezisko z Keramejkosu w Atenach);
opisane przez al-Dżazariego (1206); w XVI w. opisywał je Cardano. Nowoczesne kłódki z pierścieniami — XIX w.
(np. patenty USA 1841, 1869). **Niepewność:** dokładne datowanie znaleziska rzymskiego.

**Zasada działania.** Pierścienie z wycięciem (bramką) obracają się na trzpieniu kabłąka; gdy wszystkie bramki stoją
naprzeciw zębów trzpienia, kabłąk wychodzi.

**Logika zagadki.**
- Stany pierścienia: `free` (obraca się lekko) → `bound` (przy ciągu kabłąka ten pierścień jest najmocniej dociśnięty)
  → `near` (lekkie „zapadnięcie”) → `gate_align` / `set`.
  Fałszywe wycięcia (od t3) dają `false_set`: pierścień „wpada”, ale kabłąk nie drgnie.
- Wejścia: `tension` = ciąg kabłąka; `pick_depth` = wybór pierścienia; `rotate` = obrót pierścienia.
- Zdarzenia: `contact`, `bind`, `near_shear`, `gate_align`, `set`, `false_set`, `drop` (puszczenie kabłąka = nic się
  nie traci, ale `bind` się resetuje — łagodna rodzina), `open`. Rodzinne: `ring.detent` (zapadka cyfry co 36°;
  mapuje na `contact`, rytmiczne „tyk”).
- Otwarcie: wszystkie pierścienie w bramkach i `tension ≥ t_hold`.
- Porażka: brak łamania (ciągadło nie pęka); tylko czas.

**Parametry generatora.**

| Parametr | Zakres | Jednostka | Skalowanie |
|---|---|---|---|
| `n_elem` | 3–5 | pierścienie | 3 → 5 |
| `positions` | 10 | pozycji/pierścień | stałe |
| `gate_feel` | 0,8–0,35 | `fb_gain` | maleje |
| `false_gates` | 0–2 | na pierścień | od t3 |
| `bind_spread` | duży–mały | — | maleje |

**Krzywa trudności.** S1: 3 pierścienie, bez ciągu (szukamy po wizualnym wycięciu). S2: ciąg kabłąka — tylko jeden
pierścień stawia opór. S3: kolejność wiązania przechodzi na następny po ustawieniu. Proceduralne: 4 pierścienie,
słabszy sygnał. Mistrzowskie: 5 pierścieni + fałszywe wycięcia.

**Narzędzia.** Ciągadło kabłąka / Shackle Puller.

**Materiały i wygląd.** Mosiężny korpus, stalowy kabłąk, pierścienie z wybitymi cyframi. Przekrój wzdłuż trzpienia:
pierścienie jako pionowe plastry z widocznymi wycięciami.

**Haptyka i dźwięk.** Drobne `ring.detent`, wyraźniejsze „zapadnięcie” `near_shear`, głuchy `false_set`, sprężysty
`open` (kabłąk wyskakuje).

**Czytelność 2,5D.** Przekrój boczny trzpienia, pierścienie po 48 dp grubości (5 × 64 dp podziałki = 320 dp).
Kamera: z boku, kłódka obrócona o 15°, cyfry widoczne na wierzchu pierścieni.

**Realizm kontra zabawa.** Odczyt „który pierścień trzyma” jest ogólnie znany; tolerancje wymyślone, bez odniesienia
do konkretnych kłódek. Gra uczy cierpliwości, nie „hacka”.

---

### 2.4 Wkładka płytkowa (jednostronna) — `wafer`
**PL:** Wkładka płytkowa · **EN:** Wafer Lock · **Tier:** t2 · **Faza:** MVP

**Epoka.** Najstarszy znany patent USA na zamek płytkowy: Philo Felter, 1868; dalsze odmiany na przełomie XIX/XX w.
(1870, 1913, 1924 — według Wikipedii).

**Zasada działania.** Płaskie płytki ze sprężynkami wystają z rdzenia w rowki obudowy; właściwy klucz ustawia każdą
płytkę tak, by licowała z rdzeniem.

**Logika zagadki.**
- Stany płytki: `free` → `bound` → `near` → `set`; za wysoko = płytka wchodzi w rowek po drugiej stronie → `overset`.
  Brak osobnych elementów górnych — overset jest częstszy i łatwiejszy do naprawy niż we wkładce bębenkowej.
- Wejścia: `tension`, `pick_depth`, `pick_lift`.
- Zdarzenia: `contact`, `bind`, `near_shear`, `set`, `overset`, `drop`, `stress`, `break`, `wear`, `open`.
  Rodzinne: `wafer.rattle` (luźne płytki grzechoczą przy szybkim ruchu narzędzia; mapuje na `contact`).
- Otwarcie: wszystkie płytki `set`, `tension ≥ t_hold`, obrót rdzenia o 90° (automatyczny po ustawieniu ostatniej).
- Porażka: `break`.

**Parametry generatora.**

| Parametr | Zakres | Jednostka | Skalowanie |
|---|---|---|---|
| `n_elem` | 3–5 | płytki | 3 → 5 |
| `win_shear` | 14–10 | % | maleje |
| `tension_band` | 0,30–0,22 | szerokość | maleje |
| `overset_margin` | 12–8 | % | maleje |
| `S_max` | 1,0 | — | stałe (rodzina nauki łamania) |

**Krzywa trudności.** S1: 3 płytki, pierwsze łamanie pokazane „na niby”. S2: overset i jak z niego wyjść.
S3: falownik kontra haczyk (gracz widzi, że falownik działa na płytkach). Proceduralne: 4–5 płytek.
Mistrzowskie: nie dotyczy (przechodzi w wersję dwustronną).

**Narzędzia.** Napinacz kątowy + Haczyk lub Falownik.

**Materiały i wygląd.** Mosiądz (rdzeń), cienkie stalowe płytki z prostokątnym oknem. W przekroju płytki jak
„ramki” — gracz widzi okno i krawędzie.

**Haptyka i dźwięk.** Lżejsze, wyższe kliknięcia niż w bębenkowej; `wafer.rattle`.

**Czytelność 2,5D.** Przekrój podłużny, płytki 28–32 dp szerokości, podziałka 56 dp. Kamera jak w bębenkowej (wspólny
układ ekranu ułatwia przejście).

**Realizm kontra zabawa.** Realne płytki często mają duże luzy; w grze wymagamy więcej precyzji niż w rzeczywistości
nie jest potrzebne, ale mniej niż w bębenkowej.

---

### 2.5 Wkładka płytkowa dwustronna — `wafer_double`
**PL:** Wkładka płytkowa dwustronna · **EN:** Double-Sided Wafer Lock · **Tier:** t3–4 · **Faza:** F1

**Epoka.** Klucze dwustronne do zamków płytkowych od początku XX w. (wzór z 1913 r. wg Wikipedii); w motoryzacji
układ płytek naprzemiennych upowszechnił się w połowie XX w. (w UK „double-entry” od 1962). Szczegóły motoryzacyjne
pomijamy celowo.

**Zasada działania.** Płytki są ułożone naprzemiennie: część wymaga uniesienia, część dociśnięcia w dół.

**Logika zagadki.** Jak `wafer`, ale każda płytka ma znak (`up`/`down`). `pick_lift` < 0 dociska płytki dolne.
- Zdarzenia: wspólne jak w `wafer` + rodzinne `wafer.flip` (zmiana strony narzędzia, 0,3 s; mapuje na `contact`).
- Pułapka: płytka dolna dociśnięta w złą stronę = natychmiastowy `overset` tej płytki.
- Otwarcie / porażka: jak `wafer`.

**Parametry generatora.**

| Parametr | Zakres | Jednostka | Skalowanie |
|---|---|---|---|
| `n_elem` | 4–8 | płytki (obie strony) | 4 → 8 |
| `down_ratio` | 0,25–0,5 | udział płytek dolnych | rośnie |
| `win_shear` | 12–8 | % | maleje |
| `tension_band` | 0,24–0,16 | szerokość | maleje |
| `multi_bind_p` | 0–0,15 | — | od t4 |

**Krzywa trudności.** S1: 2 płytki górne + 2 dolne, widoczne kolory stron. S2: zmiana strony narzędzia w trakcie bez
zrzutu. S3: wiązanie przeskakuje między stronami. Proceduralne: 6 płytek. Mistrzowskie: 8 płytek, multi-bind.

**Narzędzia.** Napinacz kątowy + Klin dwustronny / Twin Wedge.

**Materiały i wygląd.** Stal ocynkowana (mat), płytki w dwóch rzędach. Strona górna/dolna rozróżniona kształtem
(ścięcie krawędzi), nie tylko kolorem.

**Haptyka i dźwięk.** Jak `wafer`; płytki dolne mają niższy ton kliknięcia (kanał rozróżniający strony).

**Czytelność 2,5D.** Dwa rzędy w jednym przekroju — w pionie 412 dp mieści się 8 płytek przy podziałce 44 dp
(2 rzędy po 4). Kamera: przekrój podłużny, delikatny zoom na aktywny rząd.

**Realizm kontra zabawa.** Uproszczone; żadnych odniesień do pojazdów.

---

### 2.6 Wkładka bębenkowa — `pin_tumbler`
**PL:** Wkładka bębenkowa · **EN:** Pin Tumbler Lock · **Tier:** t2–7 · **Faza:** MVP (zabezpieczenia: F1)

**Epoka.** Pierwszy patent na dwustronnie działający zamek bębenkowy: Abraham O. Stansbury, Anglia 1805 (USA 1807).
Nowoczesna wkładka bębenkowa: Linus Yale Sr., 1848. Linus Yale Jr.: płaski klucz z ząbkami — 1861 wg części źródeł;
patent na wkładkę cylindryczną 27.06.1865 (lista patentów). **Niepewność:** źródła różnie przypisują daty 1861/1865.
Zasada „kołków” sięga zamków drewnianych (2.1). Elementy zabezpieczające (szpulki, ząbkowane) — XX w., brak
dobrze udokumentowanej daty; w grze bez daty.

**Zasada działania.** W rdzeniu i obudowie są stosy kołków (dolny + górny + sprężyna); rdzeń obraca się, gdy granica
między kołkiem dolnym i górnym w każdym stosie leży na linii podziału.

**Logika zagadki.**
- Stany stosu: `free` → `bound` → `near` → `set`; `overset` (dolny kołek przeszedł linię podziału) → wymaga obniżenia
  napięcia poniżej `t_release`.
- **Zabezpieczenia (F1):**
  - *Szpulka* (`spool`): przy uniesieniu w okno pojawia się `false_set` (rdzeń obraca się o większy kąt — „fałszywe
    otwarcie”, pozostałe stosy luźne). Dalsze unoszenie wywołuje `counter_rotate`: rdzeń cofa się; gracz musi
    **lekko** zmniejszyć napięcie (do okna `cr_band`) i dopchnąć. Za dużo zmniejszy → `drop`; za mało → kołek nie pójdzie,
    rośnie `stress`.
  - *Ząbkowany* (`serrated`): 2–4 mikro-progi przed właściwym oknem; każdy daje `pin.serration` (drobne kliknięcie,
    rdzeń nie obraca się). Uczy różnicy między kliknięciem a ustawieniem.
  - *Szpulko-ząbkowany* (t7): połączenie.
- Wejścia: `tension`, `pick_depth`, `pick_lift`.
- Zdarzenia: wszystkie wspólne poza `gate_align` i `detector_trip`. Rodzinne: `pin.serration` (mapuje na
  `false_set`, intensywność 0,3), `pin.spring_bounce` (kołek luźny odbija po puszczeniu; mapuje na `contact`).
- Otwarcie: wszystkie stosy `set`, `tension ≥ t_hold` → rdzeń obraca do 90°.
- Porażka: `break`; w Zleceniach — limit czasu.

**Parametry generatora.**

| Parametr | t2 | t3 | t4 | t5 | t6 | t7 | Jedn. |
|---|---|---|---|---|---|---|---|
| `n_elem` | 3 | 4 | 5 | 5 | 6 | 6–7 | stosy |
| `win_shear` | 12 | 11 | 10 | 9 | 8 | 7 | % |
| `tension_band` | 0,28 | 0,24 | 0,20 | 0,18 | 0,15 | 0,12 | szerokość |
| `overset_margin` | 10 | 9 | 8 | 7 | 6 | 5 | % |
| `bind_spread` | 1,0 | 0,8 | 0,6 | 0,5 | 0,4 | 0,3 | względny |
| `multi_bind_p` | 0 | 0 | 0,05 | 0,10 | 0,15 | 0,20 | — |
| `sec_count` (F1) | 0 | 0 | 1 | 1–2 | 2–3 | 3–4 | kołki zab. |
| `noise` | 0 | 0,05 | 0,08 | 0,10 | 0,12 | 0,15 | — |
| `drop_grace` | 300 | 250 | 200 | 200 | 170 | 150 | ms |

`bind_spread` 1,0 = różnice `o_i` duże, łatwo rozpoznać wiążący stos.

**Krzywa trudności.** S1: 3 stosy, jeden wiąże, wizualna linia podziału. S2: zrzut przy puszczeniu, overset.
S3: kolejność wiązania nieoczywista (nie od przodu). Proceduralne t3–5: więcej stosów, węższe pasmo, pierwsza
szpulka (F1) z osobną mini-lekcją. Mistrzowskie t6–7: multi-bind, 3–4 zabezpieczenia różnego typu, szum kontaktów,
krótszy `drop_grace`.

**Narzędzia.** Napinacz kątowy (t2–5) lub listwowy (wymagany od t5, gdy kanał „wąski”); Haczyk (wszystkie tiery),
Falownik (tylko stosy bez zabezpieczeń — na szpulkach wywołuje `false_set` i nie skończy zamka).

**Materiały i wygląd.** Mosiężny rdzeń i obudowa, kołki mosiężne (dolne) i stalowe (górne — ciemniejsze, inny
kształt końcówki), sprężyny jako spirale. Szpulka ma wyraźne przewężenie; ząbkowany — nacięcia. Wszystko
rozróżnialne kształtem w skali szarości.

**Haptyka i dźwięk.** Pełny słownik. `set` = krótki, twardy klik + mikro-obrót; `false_set` = głębszy, „pusty” klik
+ większy obrót; `counter_rotate` = ciągłe, narastające pchnięcie w lewy kciuk (haptyka na lewej części ekranu, jeśli
urządzenie pozwala tylko na jeden silnik — wzorzec rytmiczny); `pin.serration` = bardzo drobne tyk-tyk.

**Czytelność 2,5D.** 7 stosów × 44 dp podziałki = 308 dp + marginesy 16 dp — mieści się w 412 dp. Kołki 28 dp
szerokości, linia podziału 2–3 dp. Kamera: przekrój podłużny, rdzeń w środkowej części ekranu, lekki obrót 2,5D
(głębia rdzenia widoczna jako druga warstwa). Aktywny stos lekko przybliżony (zoom 1,1×).

**Realizm kontra zabawa.** Model napięcia, kolejności i szpulek odpowiada encyklopedycznemu opisowi, ale okna są
kilkukrotnie szersze niż w rzeczywistości, a kolejność wiązania jest generowana, nie wynika z obróbki. Żadnych
profili kanałów, kodów ani nazw produktów.

---

### 2.7 Zamek dźwigniowy — `lever`
**PL:** Zamek dźwigniowy · **EN:** Lever Lock · **Tier:** t3–5 · **Faza:** MVP

**Epoka.** Zasada podwójnie działającej dźwigni: Robert Barron, 1778 (Wielka Brytania). Znaczne udoskonalenia
w XIX w. (patrz 2.8). Dziś typowe 3–5 dźwigni w drzwiach, 7+ w sejfach.

**Zasada działania.** Płaskie dźwignie ze sprężynami blokują trzpień zasuwy; każdą trzeba unieść na określoną wysokość,
by jej wycięcie (bramka) przepuściło trzpień.

**Logika zagadki.**
- Stany dźwigni: `free` → `bound` (trzpień dociśnięty do przodu dźwigni pod napięciem) → `near` → `gate_align`/`set`.
  Fałszywe bramki (wycięcia w przedniej krawędzi; od t4) dają `false_set`: trzpień wpada płytko, dźwignia „trzyma”,
  ale zasuwa nie idzie; wyjście: lekko zmniejszyć napięcie i unieść wyżej (`lever.false_gate` → `counter_rotate`).
- Zbyt wysokie uniesienie: dźwignia ponad bramką = `overset`.
- Wejścia: `tension` = nacisk na zasuwę; `pick_depth` = wybór dźwigni (w głąb pakietu); `pick_lift`.
- Zdarzenia: `contact`, `bind`, `near_shear`, `gate_align`, `set`, `false_set`, `counter_rotate`, `overset`, `drop`,
  `stress`, `break`, `wear`, `open`. Rodzinne: `lever.false_gate` (mapuje na `false_set`).
- Otwarcie: wszystkie dźwignie w bramkach + `tension ≥ t_hold` → zasuwa cofa się (animacja 250 ms).
- Porażka: `break`.

**Parametry generatora.**

| Parametr | Zakres | Jednostka | Skalowanie t3→t5 |
|---|---|---|---|
| `n_elem` | 3–5 | dźwignie | 3 → 5 |
| `win_gate` | 14–9 | % skoku | maleje |
| `false_gates` | 0–2 | na dźwignię | od t4 |
| `tension_band` | 0,26–0,18 | szerokość | maleje |
| `spring_force` | 0,3–0,5 | — | rośnie (dźwignie opadają szybciej) |

**Krzywa trudności.** S1: 3 dźwignie widoczne z boku, jedna bramka. S2: napięcie zasuwy i wiązanie. S3: overset
dźwigni. Proceduralne: 4–5 dźwigni. Mistrzowskie t5: fałszywe bramki na każdej dźwigni.

**Narzędzia.** Korba dźwigniowa / Lever Crank (dwuczęściowa: ramię napięcia + podnośnik).

**Materiały i wygląd.** Stalowa skrzynka zamka wpuszczanego, mosiężne dźwignie, sprężyny płaskie. Przekrój: dźwignie
jako nakładające się płyty z perspektywą 2,5D (rozsunięte w głąb), trzpień zasuwy jako wyraźny klocek.

**Haptyka i dźwięk.** Cięższe, niższe kliknięcia niż w bębenkowej; „szuranie” dźwigni o siebie; `false_set`
z charakterystycznym podwójnym dźwiękiem (wpadnięcie + oparcie).

**Czytelność 2,5D.** Dźwignie widziane z boku nakładają się — rozwiązanie: **eksplodowany widok 2,5D** (każda kolejna
dźwignia przesunięta w prawo-w górę o 12 dp, aktywna podświetlona konturem). Kamera: z boku, 20° z góry.

**Realizm kontra zabawa.** Ogólny opis zgodny z encyklopedycznym; konkretna liczba dźwigni i bramek wymyślona.
Bez nazw systemów.

---

### 2.8 Zamek dźwigniowy z detektorem — `lever_detector`
**PL:** Zamek dźwigniowy z detektorem · **EN:** Detector Lever Lock · **Tier:** t5–6 · **Faza:** opcja MVP (domyślnie F1)

**Epoka.** Zamek z detektorem opatentował Jeremiah Chubb w 1818 r.; ulepszenie (bez klucza regulacyjnego) — Charles
Chubb, 1824. Otwarty przez A. C. Hobbsa na Wystawie Światowej w Londynie w 1851 r. **Uwaga:** jedna strona Wikipedii
łączy zasadę detektora z zamkiem „Strutta z 1818”; główne źródła przypisują patent Chubbowi.

**Zasada działania.** Dodatkowa dźwignia-detektor: gdy którakolwiek dźwignia zostanie uniesiona za wysoko, detektor
blokuje zamek i sygnalizuje właścicielowi próbę manipulacji.

**Logika zagadki.** Jak `lever` plus:
- Próg `detector_h` powyżej bramek: każda dźwignia uniesiona ponad niego → `detector_trip`, wszystkie elementy
  `jammed`.
- **Reset (fikcyjny, w duchu oryginału):** obrót zasuwy w przeciwną stronę (`tension` przełączone na „wstecz”
  i przytrzymane 1,5 s) — kosztuje czas i `wear`; w Trybie Zleceń dodatkowo klient „widzi ślad próby” (−reputacja
  drobna, opcjonalnie).
- Zdarzenia: jak `lever` + `detector_trip`; rodzinne `detector.reset` (mapuje na `drop`).
- Otwarcie: jak `lever`, bez aktywnego detektora.
- Porażka: `break`; 3 × `detector_trip` w jednym zamku = zamek „zablokowany” (Zlecenie: konieczna inna metoda / wiertło).

**Parametry generatora.**

| Parametr | Zakres | Jednostka | Skalowanie t5→t6 |
|---|---|---|---|
| `n_elem` | 5–6 | dźwignie | 5 → 6 |
| `detector_margin` | 12–6 | % nad bramką | maleje |
| `false_gates` | 1–2 | — | rośnie |
| `reset_time` | 1,5–2,5 | s | rośnie |

**Krzywa trudności.** S1: detektor pokazany wizualnie kształtem „zapadki” wchodzącej w zasuwę (nie kolorem —
kolor nie może być jedynym kanałem). S2: reset. S3: overset vs detektor (ta sama akcja, różne skutki zależnie od
marginesu). Mistrzowskie: wąski margines + fałszywe bramki.

**Narzędzia.** Korba dźwigniowa.

**Materiały i wygląd.** Jak `lever`; detektor jako osobna, cieńsza dźwignia z charakterystycznym zaczepem.

**Haptyka i dźwięk.** `detector_trip` = mocny, „mechaniczny zatrzask” + długa wibracja; to jedyne zdarzenie w rodzinie,
które brzmi jak „zamknięcie drzwi”.

**Czytelność 2,5D.** Jak `lever`; detektor zawsze na wierzchu eksplodowanego widoku.

**Realizm kontra zabawa.** Mechanizm resetu jest uogólniony; nie opisujemy, jak resetować realne zamki.

---

### 2.9 Zamek rurkowy — `tubular`
**PL:** Zamek rurkowy · **EN:** Tubular Lock · **Tier:** t4–5 · **Faza:** F1

**Epoka.** Upowszechniony w USA od 1933 r. przez jednego producenta (znak towarowy — nie podajemy). **Korekta założenia:**
1933 to data popularyzacji, nie udokumentowanego wynalezienia; wcześniejsze konstrukcje kołkowe ułożone w okrąg
mogły istnieć. Typowo 6–8 stosów, spotyka się 4–10.

**Zasada działania.** Stosy kołków ułożone w okręgu wokół osi; rurkowy klucz z nacięciami na obwodzie wciska każdy
kołek na odpowiednią głębokość, co pozwala obrócić rdzeń.

**Logika zagadki.**
- Stany jak `pin_tumbler`, ale ruch to **wciśnięcie** (`push`) zamiast uniesienia.
- Kolejność wiązania biegnie wokół okręgu; po ustawieniu wszystkich rdzeń obraca się o jedną podziałkę i
  (od t5) **stosy przesuwają się względem otworów** — trzeba ustawić drugi „obrót” (`tubular.index`), jak w uogólnionym
  opisie mechanizmu, który wymaga kilku obrotów.
- Wejścia: `tension` (obrót), `rotate` (wybór stosu na okręgu, z przyciąganiem), `push`.
- Zdarzenia: `contact`, `bind`, `near_shear`, `set`, `overset`, `drop`, `stress`, `break`, `wear`, `open`.
  Rodzinne: `tubular.index` (rdzeń przeskoczył o podziałkę; mapuje na `set` z intensywnością 1).
- Otwarcie: `index_count` pełnych podziałek.
- Porażka: `break`.

**Parametry generatora.**

| Parametr | Zakres | Jednostka | Skalowanie t4→t5 |
|---|---|---|---|
| `n_elem` | 5–8 | stosy | 5 → 8 |
| `win_shear` | 11–8 | % | maleje |
| `index_count` | 1–3 | obroty | 1 → 3 |
| `tension_band` | 0,22–0,16 | szerokość | maleje |

**Krzywa trudności.** S1: widok z czoła, 5 stosów, jeden obrót. S2: kolejność wokół okręgu. S3: drugi obrót (stosy
„od nowa”). Proceduralne: 7 stosów. Mistrzowskie: 8 stosów, 3 obroty, multi-bind.

**Narzędzia.** Napinacz kątowy (wbudowany w koronkę) + Koronka / Crown Pick.

**Materiały i wygląd.** Chromowanie zakazane (DESIGN) → szczotkowana stal i mosiądz. Z czoła: pierścień otworów;
przekrój pomocniczy (mały, boczny) pokazuje głębokość aktywnego stosu.

**Haptyka i dźwięk.** Wysokie, „metalowe tyknięcia”; `tubular.index` = wyraźny obrót z zapadką.

**Czytelność 2,5D.** **Widok z czoła** (okrąg 280 dp, 8 otworów po 36 dp na obwodzie) + wstawka boczna 120 × 200 dp z
przekrojem aktywnego stosu. Kamera: frontalna, wstawka w prawym górnym rogu (poza strefą kciuka).

**Realizm kontra zabawa.** Mechanika obrotów uproszczona; brak jakichkolwiek wskazówek o narzędziach dekodujących.

---

### 2.10 Zamek magnetyczny (schemat) — `magnetic`
**PL:** Zamek magnetyczny · **EN:** Magnetic Lock · **Tier:** t6 · **Faza:** F2

**Epoka.** Zamki z kluczem magnetycznym (pasywne, bez prądu) — XX w.; hybrydy kołków i magnesów sprzedawane m.in.
od ok. 1970 r. **Niepewność:** brak wiarygodnej daty wynalezienia; źródła są sprzeczne i słabe. W grze bez daty
(„nowoczesny”).

**Zasada działania.** W kluczu są magnesy o określonym ułożeniu biegunów; obracają lub przesuwają magnetyczne
elementy w rdzeniu do pozycji odblokowania.

**Logika zagadki.** Rodzina **schematyczna** (abstrakcja, nie przekrój fizyczny):
- Elementy to obrotowe „rotory” z kierunkiem (8 lub 12 pozycji). Sonda tworzy lokalne pole; obrót sondy obraca
  najbliższy rotor z bezwładnością. Sąsiednie rotory się **sprzęgają** (obrót jednego lekko ciągnie sąsiada).
- Stany: `free` → `bound` (rotor sprzęgnięty z sondą) → `near` (w ±1 pozycji) → `gate_align` / `set`. Za mocne pole
  przeskakuje rotor o pozycję dalej (`overset`).
- Wejścia: `pick_depth` (pozycja sondy), `rotate`, `tension` = siła pola (nie moment!) — ten sam kciuk, nowe znaczenie.
- Zdarzenia: `contact` (pole „łapie”), `bind`, `near_shear`, `gate_align`, `set`, `overset`, `drop` (zbyt słabe pole →
  rotory wracają), `open`. Rodzinne: `mag.flip` (rotor przeskoczył bieguny; mapuje na `overset`), `mag.couple`
  (sąsiad się poruszył; mapuje na `contact`).
- Otwarcie: wszystkie rotory w pozycjach + przytrzymanie pola 0,5 s.
- Porażka: brak łamania; limit czasu i przegrzanie sondy (zużycie zamiast złamania).

**Parametry generatora.**

| Parametr | Zakres | Jednostka | Skalowanie |
|---|---|---|---|
| `n_elem` | 4–6 | rotory | 4 → 6 |
| `positions` | 8–12 | na rotor | rośnie |
| `coupling` | 0,1–0,35 | — | rośnie |
| `field_band` | 0,25–0,15 | szerokość | maleje |

**Krzywa trudności.** S1: 2 rotory bez sprzężenia. S2: sprzężenie (kolejność ustawiania ma znaczenie). S3: overset
polem. Proceduralne: 5 rotorów. Mistrzowskie: 6 rotorów, silne sprzężenie — ustaw „od środka”.

**Narzędzia.** Sonda biegunowa / Polarity Probe.

**Materiały i wygląd.** Mosiężna obudowa, rotory jako dyski z wyraźną strzałką-kształtem (dwa różne końce:
ostry/tępy dla biegunów — bez koloru jako jedynego kanału). Linie pola jako cienkie (2 dp) łuki.

**Haptyka i dźwięk.** Miękkie „szarpnięcia” pola, ciche brzęczenie ∝ siła pola, `mag.flip` = sucha zapadka.

**Czytelność 2,5D.** Widok z góry na rząd rotorów (każdy 48 dp, podziałka 64 dp). Kamera: top-down, schemat
w stylu rysunku technicznego.

**Realizm kontra zabawa.** Całkowicie uogólnione — świadoma abstrakcja. Gra mówi wprost: „schemat”.

---

### 2.11 Zamek suwakowy (typu Bramaha) — `axial_slider`
**PL:** Zamek suwakowy · **EN:** Axial Slider Lock · **Tier:** t7–8 · **Faza:** F2
(Nazwa w grze ogólna; „Bramah” tylko w tym dokumencie jako kontekst.)

**Epoka.** Joseph Bramah, patent 1784 (Londyn). Zamek „wyzwanie” w witrynie od 1790 r. z nagrodą 200 gwinei;
otwarty przez A. C. Hobbsa w 1851 r. po ok. 51 godzinach pracy w ciągu 16 dni. Narzędzia produkcyjne
współtworzył Henry Maudslay.

**Zasada działania.** Rurkowy klucz wciska promieniście ułożone suwaki na różne głębokości przeciw sprężynie; gdy
wycięcia wszystkich suwaków zrównają się z płytką blokującą, rdzeń można obrócić.

**Logika zagadki.**
- Suwaki rozmieszczone wokół osi (widok z czoła jak w `tubular`), każdy ma **prawdziwe wycięcie** i (od t8) 1–2
  **fałszywe wycięcia** płytsze.
- Wciśnięcie (`push`) jednego suwaka pod napięciem: suwak wiąże; w wycięciu → `set`/`gate_align`;
  w fałszywym → `false_set` (rdzeń drgnie i zatrzyma się). Za głęboko → `overset`.
- Wejścia: `tension`, `rotate` (wybór suwaka), `push`.
- Zdarzenia: `contact`, `bind`, `near_shear`, `gate_align`, `set`, `false_set`, `counter_rotate`, `overset`, `drop`,
  `stress`, `break`, `wear`, `open`. Rodzinne: `slider.false_notch` (mapuje na `false_set`).
- Otwarcie: wszystkie suwaki w prawdziwych wycięciach + obrót.
- Porażka: `break`.

**Parametry generatora.**

| Parametr | Zakres | Jednostka | Skalowanie t7→t8 |
|---|---|---|---|
| `n_elem` | 6–10 | suwaki | 6 → 10 |
| `win_gate` | 8–6 | % | maleje |
| `false_notches` | 0–2 | na suwak | od t8 |
| `tension_band` | 0,14–0,10 | szerokość | maleje |
| `multi_bind_p` | 0,1–0,25 | — | rośnie |

**Krzywa trudności.** S1: 4 suwaki, z czoła + przekrój jednego. S2: fałszywe wycięcie. S3: obrót wybiera suwak bez
zrzutu. Proceduralne: 8 suwaków. Mistrzowskie: 10 suwaków, 2 fałszywe wycięcia, multi-bind. To „boss” rodzin
obrotowych.

**Narzędzia.** Trzpień szczelinowy / Slot Plunger (z wbudowanym napinaczem).

**Materiały i wygląd.** Mosiądz i stal, precyzyjna, gładka obróbka; wycięcia na suwakach jako ostre prostokąty.

**Haptyka i dźwięk.** Dźwięki „precyzyjne” — krótkie, wysokie; `false_set` wyraźnie bardziej tępy.

**Czytelność 2,5D.** 10 suwaków na okręgu 300 dp → łuk między środkami ≈ 94 dp, OK. Wstawka z przekrojem aktywnego
suwaka. Kamera jak `tubular`.

**Realizm kontra zabawa.** Liczba suwaków i fałszywe wycięcia uogólnione; brak nawiązań do współczesnych wyrobów.

---

### 2.12 Zamek tarczowy (disc detainer) — `disc_detainer`
**PL:** Zamek tarczowy · **EN:** Disc Detainer Lock · **Tier:** t7–9 · **Faza:** F2

**Epoka.** Wynalazł fiński mechanik Emil Henriksson (1886–1959) — koncepcja datowana na 1907 r. (inspiracja:
tarcze kasy rejestrującej), pierwszy działający egzemplarz po ok. 2 latach; zgłoszenie patentowe i produkcja w 1918 r.
**Korekta:** „1907” to data wynalazku/początku prac, nie patentu.

**Zasada działania.** Obrotowe tarcze z wycięciami; klucz obraca każdą o inny kąt, aż wycięcia ustawią się w linii,
w którą wpada listwa boczna, i rdzeń się obraca. Brak sprężyn w tarczach.

**Logika zagadki.**
- Narzędzie ma dwie części: napinacz (zawsze na ostatniej tarczy) i obrotnik, którego `pick_depth` wybiera tarczę.
- Stany tarczy: `free` → `bound` (listwa boczna dociska tarczę pod napięciem) → `near` → `gate_align`/`set`;
  fałszywe wycięcia (płytkie, od t8) → `false_set`. Tarcze bez sprężyn **nie wracają same**: `drop` nie istnieje, ale
  zwolnienie napięcia nie cofa postępu — to celowo inna logika (gracz uczy się, że to nie jest „bębenkowa”).
  Zamiast tego **zbyt duży obrót** o pełny obrót tarczy przepycha sąsiada (sprzęgnięcie, `disc.drag`).
- Wejścia: `tension`, `pick_depth` (wybór tarczy), `rotate`.
- Zdarzenia: `contact`, `bind`, `near_shear`, `gate_align`, `set`, `false_set`, `counter_rotate`, `stress`, `break`,
  `wear`, `open`. Rodzinne: `disc.drag` (tarcza sąsiednia się obróciła; mapuje na `drop` z intensywnością 0,3),
  `disc.sidebar_drop` (listwa wpada przy ostatniej tarczy; mapuje na `open`).
- Otwarcie: wszystkie tarcze w prawdziwych wycięciach.
- Porażka: `break` (moment obrotnika przy dużym napięciu).

**Parametry generatora.**

| Parametr | Zakres | Jednostka | Skalowanie t7→t9 |
|---|---|---|---|
| `n_elem` | 5–11 | tarcze | 5 → 11 (kamera przewija) |
| `positions` | 6–10 | kątów na tarczę | rośnie |
| `false_notches` | 0–3 | na tarczę | od t8 |
| `drag_p` | 0–0,3 | prawdop. sprzężenia | rośnie |
| `tension_band` | 0,16–0,10 | szerokość | maleje |

**Krzywa trudności.** S1: 3 tarcze, widoczne wycięcia w widoku z czoła. S2: tarcze bez sprężyn — brak zrzutu.
S3: fałszywe wycięcie. Proceduralne: 7 tarcz. Mistrzowskie t9: 11 tarcz, 3 fałszywe wycięcia, sprzężenia.

**Narzędzia.** Obrotnik tarcz / Disc Turner (ogólny, fikcyjny dwuczęściowy).

**Materiały i wygląd.** Stal hartowana (ciemny mat) i mosiężne tarcze dla kontrastu; listwa boczna jako ciemny pręt.

**Haptyka i dźwięk.** Obrót tarczy = drobne „ziarno” (szum tarcia), wycięcie = miękkie zapadnięcie, fałszywe =
zapadnięcie + twarde odbicie.

**Czytelność 2,5D.** **Widok z czoła** na aktywną tarczę (średnica 240 dp) + boczny pasek pozostałych tarcz jako
plasterki 28 dp z zaznaczonym kątem (miniatury). Kamera: frontalna z lekkim odchyleniem, żeby widać było „stos”.

**Realizm kontra zabawa.** Ogólna zasada zgodna z encyklopedią; sprzężenie tarcz i fałszywe wycięcia uogólnione.
Bez nazw firm/serii.

---

### 2.13 Pakiet tarcz sejfu — `safe_wheels`
**PL:** Zamek szyfrowy sejfu · **EN:** Safe Wheel Pack · **Tier:** t8–10 · **Faza:** F2

**Epoka.** Zamki szyfrowe do banków i sejfów rozwijane w USA w połowie XIX w. (m.in. zamek z kluczem zmieniającym
kombinację, 1857; zamki z pokrętłem — początek lat 60. XIX w.). **Niepewność:** źródła sprzeczne co do pierwszeństwa
i dat (1857 vs 1862); sądowe spory patentowe z tego okresu. Pierwsza komercyjnie udana kłódka z jednym pokrętłem — 1910.

**Zasada działania.** Pokrętło napędza przez krzywkę napędową pakiet kół; każde koło ma bramkę. Gdy wszystkie bramki
ustawią się pod „płotkiem” (fence) dźwigni, dźwignia opada i zamek się otwiera.

**Logika zagadki.** Zagadka **odczytu i notatek** (manipulacja jako ogólna idea encyklopedyczna; tolerancje fikcyjne):
- Stany: koła mają kąt; pokrętło obraca je naprzemiennie (sprzęgnięcie zabierakami po pełnych obrotach).
  Przy krzywce napędowej istnieją dwa **punkty kontaktu** (lewy/prawy), których rozstaw zmienia się minimalnie,
  gdy bramka któregoś koła jest blisko płotka.
- Gracz: `rotate` pokrętła (z przyciąganiem do działek 0–99), `tension` = docisk palca słuchowego (czułość odczytu;
  za duży docisk tłumi sygnał — pasmo jak w napięciu). Notes w grze automatycznie rysuje wykres punktów kontaktu,
  jeśli gracz „zapisze” pomiar (przycisk).
- Zdarzenia: `contact` (punkt kontaktu), `near_shear` (zwężenie rozstawu), `gate_align` (koło w bramce — tylko
  pośrednio, przez wykres), `open`. Rodzinne: `safe.contact_l`, `safe.contact_r` (mapują na `contact`, różny ton L/R),
  `safe.pickup` (koło zabrane przez sąsiada; mapuje na `bind`), `safe.fence_drop` (mapuje na `set`).
- Otwarcie: koła ustawione → obrót do punktu otwarcia → `safe.fence_drop` → `open`.
- Porażka: brak łamania; limit czasu w Zleceniach. Alternatywa: **Wiertarka** (Tryb Zleceń, koszt reputacji, `TOOLS.md`).

**Parametry generatora.**

| Parametr | Zakres | Jednostka | Skalowanie t8→t10 |
|---|---|---|---|
| `n_wheels` | 2–4 | koła | 2 → 4 |
| `dial_divisions` | 50–100 | działek | rośnie |
| `contact_delta` | 1,2–0,4 | działki (różnica rozstawu przy bramce) | maleje |
| `false_gates` | 0–1 | na koło | t10 |
| `noise` | 0,05–0,2 | — | rośnie |

**Krzywa trudności.** S1: 1 koło, ogromny sygnał, wykres pokazany. S2: 2 koła i zabieranie przez sąsiada.
S3: samodzielne notatki. Proceduralne t8–9: 3 koła. Mistrzowskie t10: 4 koła, mały `contact_delta`, szum.
Czas: 2–3 min (górna granica; przyspieszamy przez „szybkie przewijanie” pełnych obrotów).

**Narzędzia.** Słuchawka / Listening Cup + Notes kontaktów / Contact Notebook. Wiertarka jako ostateczność (Zlecenia).

**Materiały i wygląd.** Gruba stal drzwi, mosiężne koła, płotek stalowy. Przekrój: pakiet kół z boku (plastry) + pokrętło
z czoła w dolnej części ekranu.

**Haptyka i dźwięk.** Główny kanał to **dźwięk** (kontakty) i obraz (wykres); haptyka jako lekkie tyknięcia
działek. W trybie „w ciemności” notes czyta wartości głosowo (i18n).

**Czytelność 2,5D.** Pokrętło 220 dp (cel dotyku całe koło), pakiet kół jako przekrój nad nim. Kamera: frontalna na
pokrętło, przekrój jako „rentgen” w górnej połowie.

**Realizm kontra zabawa.** Realna manipulacja trwa dużo dłużej i wymaga ułamków działki; my mamy 1–3 min i duże
różnice. Żadnych odniesień do klas zabezpieczeń ani modeli.

---

### 2.14 Zamek czasowy (wydarzenie: naprawa zegara) — `time_lock`
**PL:** Zamek czasowy · **EN:** Time Lock · **Tier:** — (wydarzenie) · **Faza:** F2

**Epoka.** Zamki czasowe do skarbców: wczesne konstrukcje od ok. 1831 i 1858 (używane w dwóch bankach);
James Sargent zgłosił patent w 1873 r., pierwszy montaż w banku w 1874 r. (źródła podają 2 lub 26 maja), uważany za
pierwszy komercyjnie udany. Upowszechnienie po napadach z porwaniami kasjerów pod koniec lat 60. XIX w.; znany
przypadek z maja 1875 r. (Great Barrington). **Niepewność:** daty montażu i „pierwszeństwo” różnią się w źródłach;
patenty zostały częściowo unieważnione wyrokiem z 1889 r.

**Zasada działania.** Mechanizm zegarowy (zwykle kilka równoległych dla redundancji) nie pozwala otworzyć skarbca
przed ustawioną godziną, nawet przy znanej kombinacji.

**Logika zagadki.** **Nie otwieramy** zamka czasowego — to zlecenie legalnej **naprawy**: zegar stanął, bank prosi
o przywrócenie chodu przed otwarciem rano.
- Stany: koła zębate (pozycja, zazębienie), sprężyna napędowa (naciąg 0..1), wychwyt (rytm).
- Wejścia: `tension` = nakręcanie sprężyny (za mocno → `stress`/`break` sprężyny), `pick_depth`/`pick_lift` =
  osadzanie kół (dopasowanie zazębienia), `rotate` = ustawienie godziny.
- Zdarzenia: `contact`, `gate_align` (zazębienie trafione), `stress`, `break`, `open` (= zegar ruszył i odliczył do
  godziny otwarcia). Rodzinne: `time.tick` (rytm wychwytu; mapuje na `contact`), `time.beat_off` (nierówny rytm;
  mapuje na `near_shear` — „prawie”), `time.wind` (zapadka nakręcania; mapuje na `bind`).
- Sukces: równy rytm przez 5 s + ustawiona godzina.
- Porażka: pęknięta sprężyna (wymiana kosztuje monety, nie życie — wydarzenie).

**Parametry generatora.**

| Parametr | Zakres | Jednostka | Skalowanie (poziom wydarzenia 1–3) |
|---|---|---|---|
| `n_wheels` | 3–6 | koła do osadzenia | 3 → 6 |
| `movements` | 1–3 | równoległe mechanizmy | 1 → 3 |
| `beat_tolerance` | 12–5 | % odchyłki rytmu | maleje |
| `wind_band` | 0,3–0,15 | szerokość | maleje |

**Krzywa trudności.** Poziom 1: jeden mechanizm, nakręcić i ustawić. Poziom 2: osadzić brakujące koła. Poziom 3:
trzy mechanizmy, każdy musi chodzić (redundancja).

**Narzędzia.** Zestaw zegarmistrza / Clockmaker's Kit (nagroda wydarzenia).

**Materiały i wygląd.** Mosiężne koła, stalowe osie, emaliowana tarcza; przekrój jak warsztat zegarmistrza — ale bez
„martwych zębatek” (DESIGN): każda zębatka **coś robi**.

**Haptyka i dźwięk.** Najbardziej muzyczna rodzina: rytm wychwytu jako metronom; haptyka w rytmie.

**Czytelność 2,5D.** Widok z czoła na mechanizm (płyta 360 dp), koła ≥ 48 dp. Kamera: frontalna, zoom na aktywne koło.

**Realizm kontra zabawa.** Zegarmistrzostwo mocno uproszczone; ton: „pomagamy bankowi otworzyć się rano”.

---

### 2.15 Wkładka z nawierceniami (dimple) — `dimple`
**PL:** Wkładka nawiercana · **EN:** Dimple Lock · **Tier:** t6–9 · **Faza:** F3

**Epoka.** Wariant wkładki bębenkowej z kluczem płaskim, kodowanym nawierceniami na powierzchni; druga połowa XX w.
**Niepewność:** brak wiarygodnej daty pierwszego rozwiązania w przejrzanych źródłach.

**Zasada działania.** Jak bębenkowa, ale kołki wchodzą z boku (od płaskiej strony klucza), często w kilku rzędach i pod
kątem.

**Logika zagadki.** Model `pin_tumbler` z różnicami:
- 2–3 rzędy stosów (`row`), narzędzie musi być obrócone w stronę rzędu (`rotate` dyskretne: rząd A/B/C).
- Kołki mają **kąt natarcia** — `pick_lift` działa w kierunku rzędu; zły rząd = `contact` bez ruchu.
- Zdarzenia: jak `pin_tumbler` + `dimple.row_switch` (mapuje na `contact`).
- Otwarcie, porażka: jak `pin_tumbler`.

**Parametry generatora.**

| Parametr | Zakres | Jednostka | Skalowanie t6→t9 |
|---|---|---|---|
| `rows` | 1–3 | — | 1 → 3 |
| `n_elem` | 5–10 | stosy łącznie | rośnie |
| `win_shear` | 9–6 | % | maleje |
| `sec_count` | 1–4 | — | rośnie |
| `tension_band` | 0,16–0,10 | szerokość | maleje |

**Krzywa trudności.** S1: jeden rząd z boku. S2: dwa rzędy, przełączanie bez zrzutu. S3: zabezpieczenie w drugim
rzędzie. Proceduralne: 2 rzędy × 4. Mistrzowskie: 3 rzędy, multi-bind, zabezpieczenia.

**Narzędzia.** Napinacz listwowy + Chorągiewka / Flag Pick.

**Materiały i wygląd.** Mosiądz niklowany na mat (bez chromu), kołki o płaskich czołach.

**Haptyka i dźwięk.** Jak bębenkowa, ale z innym „kolorem” dla każdego rzędu (wysokość tonu).

**Czytelność 2,5D.** Przekrój „z góry” na płaszczyznę klucza, rzędy jako pasy; maks. 5 stosów na rząd w pionie
ekranu (podziałka 44 dp). Kamera: top-down z 25° nachyleniem.

**Realizm kontra zabawa.** Uogólnione; bez profili, bez systemów.

---

### 2.16 Wkładka z listwą boczną — `sidebar`
**PL:** Wkładka z listwą boczną · **EN:** Sidebar Lock · **Tier:** t6–9 · **Faza:** F3

**Epoka.** Listwy boczne w zamkach (m.in. motoryzacyjnych) — według niezweryfikowanych relacji od lat 30. XX w.;
dziś w wielu wyższych klasach wkładek. **Niepewność:** brak wiarygodnej daty — tylko zakres „XX w.”.

**Zasada działania.** Oprócz zwykłych kołków jest listwa w bok rdzenia; wpada ona tylko wtedy, gdy dodatkowe elementy
(np. obrotowe kołki lub suwaki) mają właściwą **orientację lub położenie boczne**.

**Logika zagadki.** **Dwie warstwy warunków** na element:
- warstwa 1: wysokość (jak `pin_tumbler`) — linia podziału;
- warstwa 2: obrót kołka (4–6 pozycji kątowych) — wycięcie na listwę.
- Pod napięciem najpierw wiąże listwa (jeśli warstwa 2 nie gotowa, warstwa 1 „nic nie czuje” = brak `bind`).
  Gracz najpierw ustawia orientację (`rotate` na wybranym kołku, `gate_align`), potem wysokość (`set`).
- Zdarzenia: wspólne + `sidebar.engage` (listwa przylega; mapuje na `bind`), `sidebar.drop` (listwa wpadła;
  mapuje na `set` z intensywnością 1).
- Otwarcie: obie warstwy dla wszystkich elementów.
- Porażka: `break`.

**Parametry generatora.**

| Parametr | Zakres | Jednostka | Skalowanie t6→t9 |
|---|---|---|---|
| `n_elem` | 4–7 | — | rośnie |
| `rot_positions` | 3–6 | — | rośnie |
| `layer2_ratio` | 0,5–1,0 | udział kołków z warstwą 2 | rośnie |
| `tension_band` | 0,18–0,10 | szerokość | maleje |

**Krzywa trudności.** S1: listwa pokazana, 2 kołki obrotowe. S2: kolejność warstw. S3: brak `bind` jako informacja.
Proceduralne: 5 elementów. Mistrzowskie: 7 elementów, wszystkie dwuwarstwowe.

**Narzędzia.** Napinacz listwowy + Haczyk + Piórko boczne / Side Feather.

**Materiały i wygląd.** Stal i mosiądz; listwa jako długi, ciemny element równoległy do rdzenia; kołki z rowkiem
pokazującym orientację (kształt, nie kolor).

**Haptyka i dźwięk.** `sidebar.engage` = długie, miękkie dociśnięcie; `sidebar.drop` = głęboki, satysfakcjonujący stuk.

**Czytelność 2,5D.** Przekrój podłużny + druga warstwa 2,5D (listwa za rdzeniem, widoczna przez wycięcie). Obrót
kołka jako ikona-tarcza nad stosem (28 dp).

**Realizm kontra zabawa.** Bardzo uogólnione; realne systemy listew są różnorodne — nie odwzorowujemy żadnego.

---

### 2.17 Hybrydy — `hybrid`
**PL:** Zamki hybrydowe · **EN:** Hybrid Locks · **Tier:** t8–10 · **Faza:** F3

**Epoka.** Konstrukcje łączące kilka zasad są typowe dla XX i XXI w.; w grze to kategoria projektowa, nie historyczna.

**Zasada działania.** Zamek składa się z 2 (maks. 3) modułów rodzin połączonych **warunkiem logicznym**.

**Logika zagadki.**
- Kompozycja: `open = A.open ∧ B.open` (równolegle — oba naraz pod jednym napięciem) albo **sekwencyjnie**
  (`B` aktywny dopiero po `A.open`, np. dźwignie → pakiet tarcz).
- Wspólne napięcie: przy kompozycji równoległej moduły dzielą `tension`; pasmo efektywne = część wspólna pasm
  (weryfikator musi to sprawdzić — największe ryzyko nierozwiązywalności).
- Zdarzenia: suma zdarzeń modułów; `element_id` z prefiksem modułu. Rodzinne: `hybrid.stage` (moduł ukończony;
  mapuje na `set` intensywność 1).
- Porażka: jak w modułach.

**Parametry generatora.**

| Parametr | Zakres | Jednostka | Uwagi |
|---|---|---|---|
| `modules` | 2–3 | — | tylko rodziny, które gracz już opanował |
| `mode` | seq / par | — | par od t9 |
| `module_tier` | tier − 2 | — | moduły łatwiejsze niż całość |
| `shared_band_min` | 0,10 | szerokość | twardy próg weryfikatora |

**Krzywa trudności.** Samouczek: jedna kombinacja sekwencyjna z łatwymi modułami. Proceduralne: losowe pary.
Mistrzowskie: równoległe, 3 moduły.

**Narzędzia.** Suma narzędzi modułów (gracz musi je posiadać; `tool_swap` ma koszt).

**Materiały i wygląd.** Wynikają z modułów; ramka obudowy wspólna.

**Haptyka i dźwięk.** Moduły zachowują swoje „głosy” — gracz słyszy, który moduł mówi.

**Czytelność 2,5D.** Dzielony ekran pionowy (moduł aktywny 60% wysokości, drugi jako miniatura 28%); kamera
przejeżdża przy `tool_swap`.

**Realizm kontra zabawa.** Czysta zabawa; brak odniesień do realnych produktów.

---

## 3. Tabela zbiorcza

| # | ID | PL / EN | Tier | Faza | Widok | Wejścia | Kluczowa nowa logika | Narzędzie główne |
|---|---|---|---|---|---|---|---|---|
| 2.1 | `wooden_pin` | Zasuwa kołkowa / Wooden Pin Bolt | 1 | MVP | bok | T, D, L | unoszenie + kolejność | Podważka kołkowa |
| 2.2 | `warded` | Zamek zapadkowy / Warded Lock | 1–2 | MVP | czoło | T, D, L, R | labirynt obrotowy | Sonda przelotowa |
| 2.3 | `ring_combo` | Kłódka pierścieniowa / Ring Combination Padlock | 2–3 | MVP | bok | T, D, R | wiązanie przy obrocie | Ciągadło kabłąka |
| 2.4 | `wafer` | Wkładka płytkowa / Wafer Lock | 2 | MVP | bok | T, D, L | overset łatwy, łamanie | Haczyk / Falownik |
| 2.5 | `wafer_double` | Płytkowa dwustronna / Double-Sided Wafer | 3–4 | F1 | bok | T, D, ±L | dwie strony | Klin dwustronny |
| 2.6 | `pin_tumbler` | Wkładka bębenkowa / Pin Tumbler | 2–7 | MVP/F1 | bok | T, D, L | stosy, szpulki, ząbki | Haczyk |
| 2.7 | `lever` | Zamek dźwigniowy / Lever Lock | 3–5 | MVP | bok 2,5D | T, D, L | bramki, fałszywe bramki | Korba dźwigniowa |
| 2.8 | `lever_detector` | Dźwigniowy z detektorem / Detector Lever | 5–6 | MVP opc./F1 | bok 2,5D | T, D, L | detektor + reset | Korba dźwigniowa |
| 2.9 | `tubular` | Zamek rurkowy / Tubular Lock | 4–5 | F1 | czoło + wstawka | T, R, P | okrąg, wiele obrotów | Koronka |
| 2.10 | `magnetic` | Zamek magnetyczny / Magnetic Lock | 6 | F2 | góra (schemat) | T(pole), D, R | sprzężone rotory | Sonda biegunowa |
| 2.11 | `axial_slider` | Zamek suwakowy / Axial Slider Lock | 7–8 | F2 | czoło + wstawka | T, R, P | wciskanie, fałszywe wycięcia | Trzpień szczelinowy |
| 2.12 | `disc_detainer` | Zamek tarczowy / Disc Detainer | 7–9 | F2 | czoło + pasek | T, D, R | brak sprężyn, sprzężenie | Obrotnik tarcz |
| 2.13 | `safe_wheels` | Zamek sejfu / Safe Wheel Pack | 8–10 | F2 | czoło + rentgen | T(docisk), R | odczyt i wykres | Słuchawka + Notes |
| 2.14 | `time_lock` | Zamek czasowy / Time Lock | wydarzenie | F2 | czoło | T, D, L, R | naprawa, rytm | Zestaw zegarmistrza |
| 2.15 | `dimple` | Wkładka nawiercana / Dimple Lock | 6–9 | F3 | góra 25° | T, D, L, R(rząd) | rzędy | Chorągiewka |
| 2.16 | `sidebar` | Listwa boczna / Sidebar Lock | 6–9 | F3 | bok + warstwa | T, D, L, R | dwie warstwy warunków | Piórko boczne |
| 2.17 | `hybrid` | Hybrydy / Hybrid Locks | 8–10 | F3 | dzielony | suma | kompozycja modułów | suma |

T = tension, D = pick_depth, L = pick_lift, R = rotate, P = push.

---

## 4. Ryzyka projektowe

1. **Rozjazd wyroczni i symulacji.** Analityczny dowód otwieralności może nie zgadzać się z rzeczywistą funkcją `step`
   (np. przez kwantyzację). Mitygacja: bot skryptowy przez prawdziwy `step` jest twardym warunkiem (1.9).
2. **Pasmo napięcia za wąskie na telefonach z gorszym dotykiem / bez dobrej haptyki** (część Androidów).
   Mitygacja: profil urządzenia mnoży okna; kanał dźwięku i obrazu zawsze kompletny.
3. **Nieczytelność `false_set` vs `set`** w trybie „w ciemności”. Mitygacja: test czytelności w CI (1.10 p. 6)
   i test z ludźmi przed F1.
4. **Kciuki w pionie:** dwa kciuki naraz w pionie przy 412 dp mogą zasłaniać przekrój. Mitygacja: mechanizm w górnych
   60% ekranu, kontrolki w dolnych 35%; weryfikacja w makietach (`mockups/`).
5. **Postrzeganie jako „kurs włamywania”.** Mitygacja: tolerancje i mechanizmy fikcyjne, nazwy ogólne, brak narzędzi
   z listy wykluczeń (`TOOLS.md`), komunikat „to gra, nie kurs”, legalny kontekst zleceń. Nazwiska wynalazców tylko
   w Gablocie jako historia (do decyzji właściciela, czy w ogóle).
6. **Rodziny „inne” (zapadkowy, sejf, zegar, magnes) mogą wymagać nowych kontrolek** i łamać spójność dwóch kciuków.
   Mitygacja: każda rodzina deklaruje `input_mask`; mapowanie lewego kciuka zawsze jest „siłą” (moment/ciąg/pole/docisk).
7. **Rodzina `safe_wheels` trwa za długo** (górna granica 3 min). Mitygacja: szybkie przewijanie pełnych obrotów,
   auto-notes; jeśli playtest > 3 min — przenieść do Trybu Zleceń.
8. **Hybrydy równoległe** mogą dawać puste przecięcie pasm. Mitygacja: `shared_band_min` jako twardy próg.
9. **Determinizm międzyplatformowy** (floaty). Mitygacja: stałoprzecinkowo, test ARM/x86 w CI.
10. **Niepewne daty historyczne** w Gablocie. Mitygacja: w grze tylko przedziały i sformułowania ostrożne
    („według źródeł…”), daty tylko tam, gdzie są dobrze udokumentowane (1778, 1784, 1805, 1818, 1848, 1851, 1868).
11. **Zakaz koloru jako jedynego kanału** — kilka rodzin (dwustronne, magnes, detektor) kusi kolorem. Mitygacja:
    kształt zawsze pierwszy (zapisane w kartach).

---

## 5. Wzór karty (do kopiowania)

```markdown
### 2.NN Nazwa PL — `family_id`
**PL:** … · **EN:** … · **Tier:** tX–tY · **Faza:** MVP/F1/F2/F3

**Epoka.** Daty z źródłem; **Niepewność:** co nie jest pewne.

**Zasada działania.** 1–2 zdania, ogólnie.

**Logika zagadki.**
- Stany elementu (mapowanie na stany wspólne 1.4).
- Wejścia (input_mask).
- Zdarzenia: wspólne … ; rodzinne `family.event` (mapuje na …).
- Otwarcie: …
- Porażka: …

**Parametry generatora.**
| Parametr | Zakres | Jednostka | Skalowanie |
|---|---|---|---|

**Krzywa trudności.** S1 / S2 / S3 → proceduralne → mistrzowskie.

**Narzędzia.** (nazwy z TOOLS.md)

**Materiały i wygląd.** …

**Haptyka i dźwięk.** …

**Czytelność 2,5D.** wymiary w dp (≥ 28 dp elementy, ≥ 2 dp linia podziału), widok kamery.

**Realizm kontra zabawa.** …

Checklist przed przyjęciem: weryfikator OK na 10 000 seedów · czytelność set/false_set · brak marek ·
mapowanie zdarzeń rodzinnych · input_mask zgodny z dwoma kciukami · wpis w TOOLS.md (macierz).
```

---

## 6. Źródła

Ogólne i historia (dostęp 2026-11-04):
- Wikipedia, *Lock and key* — Barron 1778, Bramah 1784/1790, Stansbury 1805, Chubb 1818/1824, Hobbs 1851, Yale Sr. 1848:
  https://en.wikipedia.org/wiki/Lock_and_key
- Wikipedia, *Pin tumbler lock* — Khorsabad, Egipt (szac.), Stansbury 1805/1807, Yale Sr. 1848, Yale Jr. 1861, szpulki/ząbkowane:
  https://en.wikipedia.org/wiki/Pin_tumbler_lock
- Wikipedia, *Linus Yale Jr.* — patenty 1851, 1863, 1865 (wkładka 27.06.1865), zgon 1868:
  https://en.wikipedia.org/wiki/Linus_Yale_Jr.
- Wikipedia, *Lever tumbler lock* — Barron 1778, detektor, fałszywe bramki, liczba dźwigni:
  https://en.wikipedia.org/wiki/Lever_tumbler_lock
- Wikipedia, *Chubb detector lock* — patent 1818, ulepszenie 1824, Hobbs 1851:
  https://en.wikipedia.org/wiki/Chubb_detector_lock
- Wikipedia, *Bramah lock* — patent 1784, wyzwanie 1790, Hobbs 1851 (51 h / 16 dni), Maudslay:
  https://en.wikipedia.org/wiki/Bramah_lock
- Wikipedia, *Disc tumbler lock* — Henriksson, 1907 / patent i produkcja 1918:
  https://en.wikipedia.org/wiki/Disc_tumbler_lock
- Wikipedia, *Wafer tumbler lock* — Felter 1868, warianty 1870/1913/1924, „double-entry” 1962:
  https://en.wikipedia.org/wiki/Wafer_tumbler_lock
- Wikipedia, *Tubular pin tumbler lock* — popularyzacja od 1933, 4–10 stosów:
  https://en.wikipedia.org/wiki/Tubular_pin_tumbler_lock
- Wikipedia, *Combination lock* — Keramejkos (okres rzymski), al-Dżazari 1206, Cardano, patenty 1841/1869, 1910:
  https://en.wikipedia.org/wiki/Combination_lock
- Wikipedia, *Warded lock*: https://en.wikipedia.org/wiki/Warded_lock
- Wikipedia, *Magnetic keyed lock* (słabe źródło, bez dat): https://en.wikipedia.org/wiki/Magnetic_keyed_lock
- Wikipedia, *Time lock* — przypadek z 1875 r.: https://en.wikipedia.org/wiki/Time_lock
- Wikipedia, *James Sargent* — zamek szyfrowy 1857, time-delay 1880: https://en.wikipedia.org/wiki/James_Sargent
- *The Glory of American Locks*, Invention & Technology — patent zamka czasowego 1873, zamki bankowe 1857/1862, spór 1889:
  https://www.inventionandtech.com/node/86621
- Historia zamków czasowych (strona kolekcjonerska; daty montażu 1874, wcześniejsze konstrukcje 1858):
  https://my-time-machines.net/sargent_intro.htm
- Nekrolog J. Sargenta (1910, PDF) — wniosek patentowy czerwiec 1873, montaż 2.05.1874:
  https://www.nyscu.org/Archives/Universalist%20Memory%20Garden/Universalist%20Memory%20Garden%20SA-SL/Sargent,%20James%201910.pdf
- D. T. Potts (1990), *Lock and Key in Ancient Mesopotamia* — krytyka datowania zamka z Chorsabadu:
  https://www.yeshiva.org.il/midrash/pdf/wiki/potts_1990_-_lock_and_key_in_ancient_mes.pdf
- Oriental Institute (ISAC), Khorsabad — budowa pałacu 717–706 p.n.e.:
  https://isac.uchicago.edu/research/projects/khorsabad-relief-project

Uwagi o źródłach: Wikipedia jest punktem startu, nie źródłem ostatecznym; daty oznaczone „niepewność” wymagają
sprawdzenia w źródłach pierwotnych (rejestry patentowe), zanim trafią do treści dla gracza.
