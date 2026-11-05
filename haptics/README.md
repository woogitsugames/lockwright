# haptics/: wzorce haptyczne per zdarzenie (iOS AHAP + łańcuchy Androida)

To narzędzie projektowe na etapie researchu, nie kod gry. Generator bierze `docs/FEEL.md` (§2, §3, §9) oraz
`game/data/haptics_patterns.json` (bank, **tylko odczyt**, właściciel: sesja B). Wynik to pliki per rodzina × zdarzenie,
które sesja B może ładować w mostkach haptyki.

```bash
python3 haptics/build.py && python3 haptics/validate.py     # generacja + walidacja (exit ≠ 0 przy błędzie)
python3 haptics/validate.py --markdown                      # tabela budżetu w Markdown
python3 -m http.server 8000   # z katalogu głównego repo, potem http://localhost:8000/haptics/preview.html
```

Sesja B nałożyła już łatkę §9 na bank (commit „FEEL.md §9 patch merged…”). Merge patch jest idempotentny, więc
wynik jest identyczny przed nałożeniem i po nim (sprawdzone). Wymagany jest sam Python 3 (stdlib). Wyjście jest deterministyczne: posortowane klucze, liczby zaokrąglone do 4 miejsc,
bez znaczników czasu. Dwa kolejne buildy dają te same SHA-256.

## Co jest gdzie

| Plik | Rola |
|---|---|
| `spec.py` | Jedno źródło danych. Wyciąga blok ```json spod „## 9.” z FEEL.md, nakłada go na bank jako JSON Merge Patch (RFC 7396). Do tego kształty wzorców iOS z FEEL §2/§3 zapisane jako dane (każdy z komentarzem „FEEL §…”), lista zdarzeń każdej rodziny (§3, sprawdzona z `lockcore/src/families/*.cpp`) i modyfikatory materiał × rodzina (§1.4). |
| `build.py` | Generuje `out/` (lista niżej). |
| `validate.py` | (a) schemat AHAP i Androida, SHA-256 z indeksu, zgodność banku z FEEL (ostrzeżenia); (b) symulacja budżetu §5 dla 7 rodzin × 6 poziomów. |
| `preview.html` + `preview.js` | Podgląd: rodzina i zdarzenie, krzywe I/S z AHAP, wybór z łańcucha Androida A4–A0 (pełna maska prymitywów oraz samo CLICK+TICK), dźwięk z `audio/v2` z kursorem. Bez frameworków i bez CDN. Dane w `out/preview_data.js`, więc strona działa też z `file://`, tylko bez dźwięku. Parametry URL: `?family=lever&event=false_set`. |
| `out/ios/<rodzina>/<zdarzenie>[.<wariant>].ahap` | 116 plików AHAP (`{"Version":1.0,"Metadata":…,"Pattern":[…]}`) z modyfikatorami dla domyślnego materiału rodziny. Warianty: `drop.n2…n6` (liczba uderzeń = round(2 + 4·I_event)), `stress` / `stress.high` (≥ 0,9 S/Smax, co 45 ms) / `stress.capped` (po 4 s, co 140 ms), `counter_rotate` (rampa 0,20→0,40, 660 ms) + `counter_rotate.loop` (pętla, dopóki trwa nacisk). |
| `out/ios/<rodzina>/<zdarzenie>.mod.json` | 51 plików z modulacją **kanału ciągłego** (dipy set/false_set/gate_align, +0,2 dla bind, S +0,15 dla near_shear, martwy opór dla overset i detector_trip, opór → 0 dla drop, cisza 150 ms i rampa 300 ms dla break, dodatki stress i creak). Nie siedzą w AHAP zdarzenia, bo krzywe Core Haptics działają tylko na własny player (TECH §2.1). |
| `out/ios/_continuous/{tension_resistance,pick_drag}.ahap` | Szablony do zapętlenia: jedno zdarzenie ciągłe 30 s (I 1,0, S środkowe) plus początkowe krzywe sterujące. Obok `*.control.json`: tabela r/v → `HapticIntensityControl` / `HapticSharpnessControl`, k i Δs per rodzina, ducking, idle, clamp S ≤ 0,75. |
| `out/android/<rodzina>/<zdarzenie>.json` | 73 pliki: `chain` (warianty a3/a2/a1/a0 po modyfikatorach, `onset_ms` = suma opóźnień), `selection` i `selection_min_primitives` (wybór dla A4…A0), priorytet, essential. |
| `out/android/_continuous/*.json`, `out/android/selection_table.json` | Łańcuchy sygnałów ciągłych oraz zbiorcza tabela wyboru: rodzina → zdarzenie → poziom. |
| `out/index.json` | Manifest: rodzina → zdarzenia → pliki + SHA-256, status (`play` / `fold:<baza>` / `audio`), materiał, k, Δs, sfx, hashe źródeł. |

**Liczby.** 7 rodzin, 83 pary rodzina × zdarzenie. Z nich 73 grają własny wzorzec: pin_tumbler 13, wafer 10,
wooden_pin 8, warded 9, lever 11, lever_detector 14, ring_combo 8. Pozostałe 10 to 6 złożeń (`gate_align` → set
w lever, lever_detector i ring_combo; `lever.false_gate` → drugi impuls false_set w lever i lever_detector) oraz
4 × `wear`, który w trakcie zamka gra tylko dźwięk. Razem: 116 AHAP + 4 pliki ciągłe, 51 modulacji,
73 + 2 pliki Androida.

### Decyzje podjęte przy generacji (do przeglądu)
- Zdarzenia narzędzia (`stress`, `break`, `wear`) dostają **stal bez modyfikatora rodziny**, bo narzędzie jest to samo
  w każdej rodzinie. FEEL §1.4 mówi tylko „zawsze ze stali”.
- `wood.creak` ma materiał zamka (drewno), bo tak emituje go lockcore. Wartości FEEL traktuję jak wszystkie inne
  („mosiądz przed modyfikatorem”), więc S ticków wychodzi 0,2 − 0,25 → **0,0**. Jeśli §3.3 podaje wartości końcowe,
  trzeba to oznaczyć w FEEL.
- `ward.scrape` i `ring.detent` to pojedynczy tyk na AHAP. Rytm robi runtime (scrape: min. odstęp 60 ms i limit 10/s;
  detent: 12/s na iOS, 8/s na A2–A4, 4/s na A1, 0 na A0).
- `detector.reset_hold` (tyk co 250 ms podczas trzymania resetu, FEEL §3.6) to wzorzec **po stronie gry**, nie
  zdarzenie lockcore. Prio 11, nie-essential.
- Łańcuchy kończące się na `a1 skip` (`pin.spring_bounce`, `wafer.rattle`) dostają na końcu `{"tier":"a0","skip":true,"normalized":true}`.
- Czas trwania transientu z FEEL (8–40 ms) nie ma odpowiednika w AHAP, bo transient Core Haptics ma stałą długość.
  Zostaje w `spec.py` (`nominal_ms`) i w opisie FEEL.

## Jak sesja B to ładuje

`game/data/haptics_patterns.json` **zostaje indeksem runtime** (priorytety, essential, limity, mix_rules, budget i,
po nałożeniu łatki §9, `android_chain` / `sub_events` / `families`). Pliki z `haptics/out` to **szczegół per zdarzenie**:
gotowe wzorce, które mostek wczytuje w `prepare()`. Routing: `sub_events["<rodzina>.<nazwa>"]`, potem baza
(FEEL §7.2). Klucz pliku to `index.json → families[f].events[e].ios[] / android.file`.

**iOS (H3, Core Haptics).**
- Eksport: dodać `haptics/out/**` do projektu jako zasoby (`res://haptics/…`), a w presecie eksportu ustawić
  `include_filter = "*.ahap, *.json"`, bo inaczej Godot ich nie spakuje.
- Wczytanie w ObjC++: `[[CHHapticPattern alloc] initWithContentsOfURL:url error:&err]` (Swift:
  `CHHapticPattern(contentsOf: url)`), gdzie `url` to ścieżka z `ProjectSettings.globalize_path("res://…")`.
  Uwaga: w zbudowanej aplikacji `res://` siedzi w `.pck`, a `globalize_path` daje prawdziwy plik tylko w edytorze lub
  przy plikach dołączonych jako surowe zasoby bundla. Bezpieczniej czytać JSON przez `FileAccess`, przekazać go do
  natywnego kodu jako `Dictionary` i użyć `initWithDictionary:error:`. To samo pozwala przeskalować
  `HapticIntensity` przez I_event, suwak i `continuousFloor` (raz, na końcu, FEEL §7.5) przed utworzeniem wzorca.
- Wzorce prebuildować w `prepare()`, transienty grać w osobnym playerze (TECH §2.1).
- Kanały ciągłe: `_continuous/*.ahap` w `CHHapticAdvancedPatternPlayer` z `loopEnabled = YES`. Sterowanie przez
  `sendParameters:` z `CHHapticDynamicParameter` (`HapticIntensityControl` = mnożnik 0..1,
  `HapticSharpnessControl` = przesunięcie −1..1) ≤ 60 Hz, wartości z `*.control.json`.
- `*.mod.json` gra się na playerze ciągłym przez `scheduleParameterCurve:atTime:` (dipy, rampy) albo w pętli
  `sendParameters` (absolutne `sharpness_set`).
- `counter_rotate`: najpierw plik rampy, po 660 ms przełączyć na `.loop`, a po puszczeniu nacisku zrobić
  `stopAtTime:`. `stress`: plik zwykły, `.high` przy ≥ 0,9 i `.capped` po 4 s.
- H1 (`UIImpactFeedbackGenerator`) tylko dla essential, wg stylów z FEEL §1.3.

**Android.**
- Wczytać `out/android/<rodzina>/<zdarzenie>.json` i wziąć **pierwszy** wpis `chain`, którego `tier` ≤ poziom
  urządzenia i którego wszystkie prymitywy (`composition`, `tick`, `then`) są w `supported_primitives_mask`
  (FEEL §1.3). `selection` / `selection_min_primitives` pokazują wynik dla pełnej maski i dla minimum CLICK+TICK.
  Tak samo liczy go runtime.
- A2: `VibrationEffect.startComposition().addPrimitive(PRIMITIVE_x, scale, delay).compose()`. **Uwaga:** `delay_ms`
  w FEEL liczy się od *początku* poprzedniego prymitywu (`onset_ms` = suma), a `addPrimitive` liczy opóźnienie od
  *końca* poprzedniego. Trzeba więc odjąć `Vibrator.getPrimitiveDurations()` poprzedniego prymitywu (min. 0).
- A3/A4: `envelope [[t_ms, I, S], …]` przez `VibrationEffect.BasicEnvelopeBuilder` (API 36), który bierze
  `addControlPoint(intensity, sharpness, durationMs)` dla różnic czasów. Do tego `tick` / `then` jako kompozycja.
  A4 używa tych samych wpisów `a3`/`a2`, a fallback robi framework.
- A1: `createWaveform(timings, amps, repeat)` albo `createPredefined(EFFECT_CLICK/EFFECT_TICK)`.
  A0: `createOneShot(on_ms, DEFAULT_AMPLITUDE)` albo wzór on/off. `skip` oznacza samą warstwę dźwięku i obrazu.
- `repeat_interval_ms` / `tick_interval_ms` oznaczają rytm, który odpala reżyser, dopóki trwa stan
  (counter_rotate, stress, creak).

## Budżet intensywności (FEEL §5): wynik symulacji

`validate.py` buduje deterministyczny strumień zdarzeń na 180 s dla każdej rodziny:
- **pin_tumbler**: t5, zmagający się gracz, liczby z §5.3: ~300 contact z pozornymi, 45 bind, 35 near_shear, 28 set,
  6 false_set, 20 serration, 2 overset, 4 drop, 1 open, kontrrotacja 5 s, stress 4,6 s + 1,4 s;
- **wafer**: t3, 150 rattle;
- **wooden_pin**: 3 zamki, 3 epizody creak;
- **warded**: 10 × 5 s `ward.scrape`, 3 epizody stresu i break;
- **lever**: gate_align+set i false_set+false_gate w tym samym kroku;
- **lever_detector**: jak lever + 2 tripy, 2 × trzymanie resetu 2,5 s, 2 resety;
- **ring_combo**: 30 serii kręcenia po 2,5 s przy 22 detentach/s.

Do tego mikrotyki `pick_drag` (~2,5/s, prio 13) przez cały czas ruchu wytrycha.

Regulator działa per poziom: limity 1 s z TECH §3.5 (25/12/6/3), limit 10 s z §5.1, koalescencja 30 ms po
(nazwa, element) bez przesuwania okna, limity pod-zdarzeń, `minTransientGap` (40/60/150 ms). Odrzuca najpierw
prio ≥ 11 (od 80% limitu 10 s), potem 9–10. Essential nigdy nie są odrzucane. Do tego cisza 150 ms po break,
stress po 4 s co 140 ms bez ciągłej części S 0,85, ducking ×0,3 / 35 + 60 ms i governor RMS 30 s
(0,35 → skala ≥ 0,75).

**Wynik: wszystkie 7 rodzin × 6 poziomów mieści się w limitach, 0 odrzuconych essential.** Kolumny:
- „max10” to najgorsze kroczące 10 s, przekraczane wyłącznie przez essential;
- „shed” to wszystko, co zjadł regulator (koalescencja, limity, min-gap, priorytet);
- RMS jest liczony **per kanał** (patrz rozbieżność 6), a „RMS sum” to suma obu kanałów, informacyjnie;
- „S max (raw)” to ostrość po clampie 0,75 (w nawiasie: przed clampem).

| family | tier | T/10s | max10 | cap | strong/10s | strong max10 | shed | ess drop | RMS tension | RMS pick | RMS sum | duty | S max (raw) | stress S run | result |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| pin_tumbler | ios | 23.0 | 50 | 40 | 2.2 | 6 | 391 | 0 | 0.201 | 0.099 | 0.274 | 65% | 0.73 (0.73) | 4.0 | ok |
| pin_tumbler | a4 | 16.2 | 36 | 25 | 2.2 | 6 | 420 | 0 | 0.207 | 0.000 | 0.207 | 61% | 0.30 (0.30) | 4.0 | ok |
| pin_tumbler | a3 | 16.2 | 36 | 25 | 2.2 | 6 | 420 | 0 | 0.207 | 0.000 | 0.207 | 61% | 0.30 (0.30) | 4.0 | ok |
| pin_tumbler | a2 | 16.3 | 36 | 25 | 2.2 | 6 | 453 | 0 | 0.222 | 0.000 | 0.222 | 63% | 0.30 (0.30) | 4.0 | ok |
| pin_tumbler | a1 | 11.1 | 28 | 15 | 2.2 | 6 | 445 | 0 | 0.222 | 0.000 | 0.222 | 63% | 0.30 (0.30) | 4.0 | ok |
| pin_tumbler | a0 | 3.8 | 13 | 8 | 3.8 | 13 | 0 | 0 | 0.000 | 0.000 | 0.000 | 0% | 0.00 (0.00) | 0.0 | ok |
| wafer | ios | 21.3 | 40 | 40 | 1.2 | 6 | 319 | 0 | 0.195 | 0.092 | 0.269 | 63% | 0.75 (0.78) | 3.0 | ok |
| wafer | a4 | 14.7 | 26 | 25 | 1.2 | 6 | 402 | 0 | 0.197 | 0.000 | 0.197 | 60% | 0.35 (0.35) | 3.0 | ok |
| wafer | a3 | 14.7 | 26 | 25 | 1.2 | 6 | 402 | 0 | 0.197 | 0.000 | 0.197 | 60% | 0.35 (0.35) | 3.0 | ok |
| wafer | a2 | 14.8 | 26 | 25 | 1.2 | 6 | 431 | 0 | 0.205 | 0.000 | 0.205 | 60% | 0.35 (0.35) | 3.0 | ok |
| wafer | a1 | 9.5 | 19 | 15 | 1.2 | 6 | 329 | 0 | 0.205 | 0.000 | 0.205 | 60% | 0.35 (0.35) | 3.0 | ok |
| wafer | a0 | 1.5 | 6 | 8 | 1.5 | 6 | 0 | 0 | 0.000 | 0.000 | 0.000 | 0% | 0.00 (0.00) | 0.0 | ok |
| wooden_pin | ios | 17.3 | 40 | 40 | 1.0 | 4 | 98 | 0 | 0.170 | 0.087 | 0.234 | 61% | 0.48 (0.48) | 0.0 | ok |
| wooden_pin | a4 | 12.8 | 26 | 25 | 1.0 | 4 | 147 | 0 | 0.173 | 0.000 | 0.173 | 58% | 0.05 (0.05) | 0.0 | ok |
| wooden_pin | a3 | 12.8 | 26 | 25 | 1.0 | 4 | 147 | 0 | 0.173 | 0.000 | 0.173 | 58% | 0.05 (0.05) | 0.0 | ok |
| wooden_pin | a2 | 13.4 | 26 | 25 | 1.0 | 4 | 164 | 0 | 0.178 | 0.000 | 0.178 | 59% | 0.05 (0.05) | 0.0 | ok |
| wooden_pin | a1 | 8.7 | 16 | 15 | 1.1 | 4 | 220 | 0 | 0.178 | 0.000 | 0.178 | 59% | 0.05 (0.05) | 0.0 | ok |
| wooden_pin | a0 | 1.2 | 4 | 8 | 1.2 | 4 | 0 | 0 | 0.000 | 0.000 | 0.000 | 0% | 0.00 (0.00) | 0.0 | ok |
| warded | ios | 19.1 | 45 | 40 | 0.9 | 3 | 873 | 0 | 0.210 | 0.103 | 0.289 | 64% | 0.72 (0.72) | 3.0 | ok |
| warded | a4 | 13.7 | 29 | 25 | 0.9 | 3 | 615 | 0 | 0.230 | 0.000 | 0.230 | 61% | 0.20 (0.20) | 3.0 | ok |
| warded | a3 | 13.7 | 29 | 25 | 0.9 | 3 | 615 | 0 | 0.230 | 0.000 | 0.230 | 61% | 0.20 (0.20) | 3.0 | ok |
| warded | a2 | 13.8 | 29 | 25 | 0.9 | 3 | 615 | 0 | 0.239 | 0.000 | 0.239 | 62% | 0.20 (0.20) | 3.0 | ok |
| warded | a1 | 9.2 | 18 | 15 | 0.9 | 3 | 410 | 0 | 0.239 | 0.000 | 0.239 | 62% | 0.20 (0.20) | 3.0 | ok |
| warded | a0 | 2.5 | 7 | 8 | 2.5 | 7 | 1 | 0 | 0.000 | 0.000 | 0.000 | 0% | 0.00 (0.00) | 0.0 | ok |
| lever | ios | 21.0 | 41 | 40 | 2.4 | 7 | 177 | 0 | 0.228 | 0.096 | 0.305 | 64% | 0.62 (0.62) | 3.0 | ok |
| lever | a4 | 14.9 | 32 | 25 | 2.4 | 7 | 231 | 0 | 0.267 | 0.000 | 0.267 | 60% | 0.20 (0.20) | 3.0 | ok |
| lever | a3 | 14.9 | 32 | 25 | 2.4 | 7 | 231 | 0 | 0.267 | 0.000 | 0.267 | 60% | 0.20 (0.20) | 3.0 | ok |
| lever | a2 | 15.2 | 33 | 25 | 2.4 | 7 | 268 | 0 | 0.275 | 0.000 | 0.275 | 62% | 0.20 (0.20) | 3.0 | ok |
| lever | a1 | 10.2 | 24 | 15 | 2.4 | 7 | 282 | 0 | 0.275 | 0.000 | 0.275 | 62% | 0.20 (0.20) | 3.0 | ok |
| lever | a0 | 4.1 | 12 | 8 | 4.1 | 12 | 2 | 0 | 0.000 | 0.000 | 0.000 | 0% | 0.00 (0.00) | 0.0 | ok |
| lever_detector | ios | 21.9 | 53 | 40 | 2.7 | 9 | 207 | 0 | 0.206 | 0.108 | 0.289 | 64% | 0.62 (0.62) | 3.0 | ok |
| lever_detector | a4 | 15.9 | 37 | 25 | 2.6 | 9 | 245 | 0 | 0.227 | 0.000 | 0.227 | 60% | 0.20 (0.20) | 3.0 | ok |
| lever_detector | a3 | 15.9 | 37 | 25 | 2.6 | 9 | 245 | 0 | 0.227 | 0.000 | 0.227 | 60% | 0.20 (0.20) | 3.0 | ok |
| lever_detector | a2 | 16.2 | 37 | 25 | 2.6 | 9 | 281 | 0 | 0.239 | 0.000 | 0.239 | 62% | 0.20 (0.20) | 3.0 | ok |
| lever_detector | a1 | 11.6 | 27 | 15 | 2.6 | 9 | 317 | 0 | 0.239 | 0.000 | 0.239 | 62% | 0.20 (0.20) | 3.0 | ok |
| lever_detector | a0 | 4.4 | 19 | 8 | 4.4 | 19 | 1 | 0 | 0.000 | 0.000 | 0.000 | 0% | 0.00 (0.00) | 0.0 | ok |
| ring_combo | ios | 20.1 | 39 | 40 | 1.3 | 4 | 1611 | 0 | 0.185 | 0.091 | 0.258 | 64% | 0.73 (0.73) | 0.0 | ok |
| ring_combo | a4 | 13.6 | 26 | 25 | 1.3 | 4 | 1667 | 0 | 0.189 | 0.000 | 0.189 | 60% | 0.30 (0.30) | 0.0 | ok |
| ring_combo | a3 | 13.6 | 26 | 25 | 1.3 | 4 | 1667 | 0 | 0.189 | 0.000 | 0.189 | 60% | 0.30 (0.30) | 0.0 | ok |
| ring_combo | a2 | 14.0 | 26 | 25 | 1.3 | 4 | 1720 | 0 | 0.193 | 0.000 | 0.193 | 62% | 0.30 (0.30) | 0.0 | ok |
| ring_combo | a1 | 9.0 | 17 | 15 | 1.4 | 4 | 1746 | 0 | 0.193 | 0.000 | 0.193 | 62% | 0.30 (0.30) | 0.0 | ok |
| ring_combo | a0 | 2.0 | 7 | 8 | 2.0 | 7 | 0 | 0 | 0.000 | 0.000 | 0.000 | 0% | 0.00 (0.00) | 0.0 | ok |


Scenariusz „§5.3 dosłownie” (opór aktywny 150 s z 180) też jest liczony, ale tylko informacyjnie. Daje
**wypełnienie 83–86%** przy limicie 70%, a na iOS także RMS sumy 0,31 (rozbieżność 1).

## Rozbieżności znalezione przy generacji (do przeglądu)

1. **FEEL §5.3 sam ze sobą:** „opór aktywny 150 s z 180” przy krzywej `0,10 + 0,45·r^1,5` (minimum 0,10 > 0,05)
   daje wypełnienie ≥ 83%, a nie „~65%”, więc przekracza limit 70%. Symulacja przyjmuje 112 s napięcia, co daje
   61–65%. Do rozstrzygnięcia: albo ~115 s napięcia w §5.3, albo próg wypełnienia liczony ponad 0,10, albo idle-fade
   także przy napięciu bez ruchu.
2. **Materiał wafer:** lockcore `wafer.cpp` ma domyślnie `MaterialId::steel`, a FEEL §3.2 i §9 `families.wafer`
   mówią mosiądz. Ze stali + rodzina wyszłoby S +0,15.
3. **pick_drag w wafer ma S 0,80 > 0,75**, bo 0,75 + Δs rodziny +0,05. FEEL nie przewiduje clampa, a wychodzi to
   z samych tabel. Dodałem regułę `budget_sharpness_max` w `*.control.json` (clamp po modyfikatorach).
4. **Semantyka `delay_ms` w kompozycji:** FEEL liczy od początku poprzedniego prymitywu (false_set @28, reset
   120/80/60), a API Androida od końca. Bez korekty drugi impuls false_set wypadnie po ~40–50 ms zamiast 28.
5. **Bank po łatce:** `events.drop.ios.count` [3, 6] zostaje obok nowego `count_from_event` [2, 6]. Stare
   `events.gate_align.android.primitive` = CLICK, a F-03 chce LOW_TICK (ma go tylko `android_chain`). Kod czytający
   stare klucze dostanie stare wartości.
6. **RMS:** limit §5.1 to 0,30, a governor §5.2 rusza dopiero przy 0,35 (30 s), więc nie chroni limitu. Suma kanałów
   dla lever na iOS wynosi 0,305. Szacunek §5.3 (0,22 przy 65%) zgadza się tylko z RMS liczonym dla samego oporu.
   Trzeba ustalić, czy „oba kanały” oznacza sumę, czy każdy osobno. Jeśli sumę, to trigger governora ≤ 0,30.
7. **A0 i essential rytmiczne:** `counter_rotate` na A0 to 25 ms co 250 ms, czyli 4/s, ponad limit A0 3/s
   (TECH §3.5). Do tego każdy impuls on/off jest „mocny”, więc kroczące 10 s mocnych na A0 dochodzi do 12–19
   (lever_detector), wyłącznie z essential. Średnio jest w budżecie (≤ 4,4 / 10 s). Na iOS kroczące 10 s dochodzi do
   50–53 (> 40) przez tyki counter_rotate co 110 ms, które są essential.
8. **Rytmy ponad limity chwilowe:** stress A2 co 80 ms (12,5/s > 12/s), A1 co 120 ms (8,3/s > 6/s),
   `ward.scrape` co 60 ms (16,7/s) przy własnym limicie 10/s. Regulator to przerzedza, ale lepiej wpisać wprost
   84 / 170 / 100 ms.
9. **Stress ze stali:** S tyków 0,9 + 0,1 = 1,0, a ciągłej części 0,85 + 0,1 = 0,95. FEEL §5.1 pisze „S 0,85–0,9”.
   Albo wartości stress są końcowe (bez modyfikatora stali), albo opis limitu trzeba poprawić.
10. **`wood.creak`:** materiał drewno daje S 0,0 (decyzje wyżej). Możliwe, że §3.3 miało wartości końcowe.
11. **Lista zdarzeń:** karta `warded` (§3.4) pomija `wear`, a `warded.cpp` wywołuje `ToolStress::end_step`, który
    je emituje. Bez wpływu na haptykę, bo `wear` gra tylko dźwięk.
12. **Łańcuchy bez a0:** `pin.spring_bounce` i `wafer.rattle` kończą się na `a1 skip` (wymóg §1.3: a0 lub skip jest
    spełniony, ale brak jawnego a0). `lever.false_gate` ma tylko `{"tier":"a2","folded":true}`.
13. **TECH §3.3 vs FEEL `open`:** TECH ma „C 300 ms I 0,3→0”, FEEL i bank mają rampę 0→0,3. Generator idzie
    za FEEL; TECH do poprawy. Podobnie TECH `counter_rotate` 0,35→0,15 i `gate_align` S 0,50 (F-02, F-03 w FEEL).
14. Znane z FEEL i potwierdzone: priorytety `events.hpp` są odwrócone względem JSON (F-08). Nazwy pod-zdarzeń
    w lockcore (`pin.serration`, `pin.spring_bounce`, `wafer.rattle`, `wood.creak`, `ward.scrape`,
    `lever.false_gate`, `detector.reset`, `ring.detent`) zgadzają się 1:1 z §9.
