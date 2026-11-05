# Lockwright — specyfikacja odczucia (feel spec): haptyka, dźwięk, obraz dla 7 rodzin

Status: **proponowana** (2026-11-05). Źródła i nadrzędność: `docs/DESIGN.md` §1 (kod stanów, 3 kanały),
`docs/TECH.md` §2–3 (warstwy haptyki, tabela zdarzeń §3.3, miks §3.5), `docs/LOCKS.md` §1.4–1.6 i karty rodzin,
`lockcore/README.md` + nagłówki `lockcore/include/lockcore/*.hpp` (słownik zdarzeń, pod-zdarzenia),
`audio/v2/README.md` (biblioteka SFX), `game/data/haptics_patterns.json` (bank wzorców, właściciel: sesja B).

Ten dokument **nie zmienia logiki** (lockcore) ani kodu gry. Daje:
1. pełne mapowanie: każde zdarzenie i sygnał ciągły lockcore × 7 rodzin → haptyka iOS (Core Haptics), łańcuch Androida
   (Composition → envelope → amplituda → one-shot), warstwa dźwięku (materiał × zdarzenie, warianty, onset ≤ 2 ms)
   i znak wizualny (geometria/ruch, czytelny w skali szarości);
2. kontrolę rozróżnialności: każdy stan ma **≥ 2 kanały niehaptyczne** (obraz + dźwięk) i jest czytelny w szarości;
3. **budżet intensywności** (brak zmęczenia przez 3-minutowy zamek) z regulatorem w czasie rzeczywistym;
4. rozstrzygnięcia rozbieżności między dokumentami (F-01…F-09) i błędy znalezione w warstwie gry (dla sesji B);
5. **łatkę JSON** do `game/data/haptics_patterns.json` (§9), addytywną, do nałożenia przez sesję B.

Konwencje: I = intensity, S = sharpness (0–1, wartości dla mosiądzu przed modyfikatorem materiału i rodziny),
T = transient, C = continuous. Priorytet: 1 = najwyższy (numeracja z `TECH.md`/JSON; `events.hpp` liczy odwrotnie,
„higher wins” — patrz F-08). Czas: ms. Klatka logiki = 1/120 s (8,33 ms).

---

## 1. Zasady wspólne

### 1.1 Trzy kanały i reguła „2 + 1”
- **Obraz** niesie znaczenie geometrią i ruchem (DESIGN §1): przesunięcie w bok, kreski tarcia, klin szczeliny,
  stopka, talia, obrys pełny/przerywany, klamra, podziałka na czole, ugięcie i rysy narzędzia. Kolor tylko wzmacnia.
- **Dźwięk** niesie znaczenie barwą (materiał), rytmem (pojedynczy / podwójny / seria / ciągły) i rejestrem.
- **Haptyka** powtarza rytm i siłę dźwięku. **Nigdy nie jest jedynym nośnikiem** (XAG 103/110). Każdy stan jest
  rozpoznawalny przy wyłączonej haptyce (DESIGN A9) i — w trybie „w ciemności” — z samego dźwięku + haptyki.
- Reguła rytmu wspólna dla dźwięku i haptyki (to ona robi rozróżnialność bez barwy):

| Rytm | Znaczenie |
|---|---|
| 1 krótki, jasny | `set` (prawda) |
| 2 impulsy: mocny + cichy niski po 28 ms (dźwignie 40 ms) | `false_set` (pułapka) |
| tępy, bez wybrzmienia, potem cisza elementu | `overset` |
| zapadka w stałym rytmie 110–120 ms, dopóki trwa nacisk | `counter_rotate` |
| kaskada malejąca co 40–50 ms | `drop` (i `detector.reset`, wolniej) |
| gęste, cienkie drżenie narastające | `stress` |
| 2 ciężkie po 140 ms | `detector_trip` |
| narastanie 300 ms + mocny klik | `open` |

### 1.2 Ścieżka sygnału i czasy
- `lockcore` (120 Hz) → `FeedbackDirector` → `HapticsBridge` / `ClickAudioBridge` (L2) / `AudioServer` (L1, L3, L4) / render.
- Synchronizacja dźwięk–haptyka |Δ| ≤ 15 ms; na Androidzie opóźniamy audio o znane opóźnienie wibratora, nigdy haptykę.
- **Onset SFX ≤ 2 ms** od początku pliku (próbka ≥ −30 dB peaku), fade-in ≤ 0,3 ms; `audio/v2` spełnia to z zapasem (≤ 0,21 ms).
  Dłuższe dźwięki (stress, open, ward_scrape, wear) zaczynają się od transjentu kontaktu, nie od narastania.
- Obraz: zmiana stanu rysowana w tej samej klatce co zdarzenie; animacje 100–250 ms, `out-cubic` lub krokowo, bez overshootu.
- Kolejność zdarzeń z jednego kroku: `gate_align` przed `set`, `false_set` przed `lever.false_gate` — reżyser gra je jako
  **jeden** wzorzec (patrz §2 i F-05), a nie jako dwa transienty w oknie 30 ms.

### 1.3 Łańcuch fallbacków Androida (na zdarzenie)
Każde zdarzenie w JSON dostaje `android_chain`: uporządkowaną listę wariantów. Runtime wybiera **pierwszy**, którego
`tier` ≤ tier urządzenia i którego **wszystkie** prymitywy są w `supported_primitives_mask` (jeden nieobsługiwany
prymityw blokuje całą kompozycję).

```text
A4 Builder  → używa wariantów "a3" (BasicEnvelopeBuilder; fallback frameworka) i "a2"
A3 Envelope → "a3": envelope [[t_ms, I, S], ...] (+ opcjonalny tick/then z prymitywu)
A2 Compos.  → "a2": composition [[PRIMITIVE, scale, delay_ms], ...]; kolejne "a2" to zamienniki prymitywów
A1 Ampl.    → "a1": waveform {timings, amps[, repeat]} lub effect EFFECT_CLICK/EFFECT_TICK
A0 on/off   → "a0": on_ms / pattern_ms, albo skip (tylko zdarzenia kluczowe; odstęp ≥ 150 ms)
A– / H0     → brak haptyki: dźwięk + obraz (bez zmian w treści)
```
iOS: H3 Core Haptics (wzorce poniżej), H1 `UIImpactFeedbackGenerator` tylko dla zdarzeń `essential`
(styl: `.rigid` dla set/break, `.heavy` dla drop/detector_trip/open/overset, `.soft` dla false_set — drugi impuls pomijany,
różnicę niesie dźwięk), H0 brak.

### 1.4 Modyfikatory: materiał × rodzina
`S' = clamp(S + Δs_mat + Δs_fam)`, `I' = clamp(I_event · I_base · k_mat · k_fam)`; I_event = `intensity` z lockcore.
Materiał z `LockEvent.material` (TECH §3.2: mosiądz 0/×1,0, stal +0,10/×1,05, żelazo −0,10/×1,10, drewno −0,25/×0,9).
Rodzina (nowe, §9 `families`): wafer ×0,85/+0,05 (lżej, wyżej), lever ×1,10/−0,10 (ciężej, niżej), ring_combo ×0,90.
Zdarzenia narzędzia (`stress`, `break`, `wear`) zawsze ze **stali** (tak emituje lockcore), niezależnie od zamka.

---

## 2. Słownik bazowy: 14 zdarzeń + 2 sygnały ciągłe

Wartości iOS = mosiądz. „Obraz (szarość)” = znak geometryczny, który przetrwa skalę szarości i 50% jasności.
Kolumna „≥2” = kanały niehaptyczne, które same rozróżniają stan od sąsiadów (O = obraz, D = dźwięk).

| Zdarzenie (prio, essential) | iOS Core Haptics | Android: A2 → A1 → A0 | Dźwięk (L, id, czas) | Obraz (szarość) | ≥2 |
|---|---|---|---|---|---|
| `contact` (12, –) | T I 0,30 S 0,70, 12 ms | `TICK` 0,35 → 10 ms/70 → brak | L2 `contact`, 12–16 ms, −15 dBFS peak | końcówka wytrycha dotyka elementu: element drga 1 dp (80 ms) | O, D |
| `bind` (10, –) | T I 0,45 S 0,35 + C oporu +0,2 w 80 ms | `LOW_TICK` 0,5 (alt `TICK` 0,4); A3 + obwiednia 80 ms → 15 ms/110 → brak | L2 `bind` 22–30 ms; L1 tarcie gęstnieje | element w bok 2–3 dp, **3 kreski tarcia** na linii podziału, ruch bez sprężynowania | O, D |
| `near_shear` (11, –) | C oporu: S +0,15 przez 150 ms, powrót 300 ms; **jeden** T I 0,12 S 0,80 przy wejściu w okno | A3 obwiednia S↑; A2 `QUICK_RISE` 0,2 (alt `TICK` 0,12) → amp oporu +20% → brak | L1: filtr HP tarcia +600 Hz (ziarno drobnieje), `near_shear` 71–109 ms, bez kliku | **klin szczeliny** się zwęża, jedna kreska tarcia znika | O, D |
| **`set`** (5, ✔) | T I 0,90 S 0,85 + dip oporu ×0,5 / 110 ms | `CLICK` 0,9 → 18 ms/255 (lub `EFFECT_CLICK`) → 30 ms | L2 `set` 63–83 ms: jasny klik + krótki ślizg rdzenia | **stopka** na półce, rdzeń +1 podziałka, klin zamknięty, obrys pełny | O, D |
| **`false_set`** (5, ✔) | T I 0,85 S 0,75 + T2 +28 ms I 0,25 S 0,30 + dip ×0,35 / 260 ms | `CLICK` 0,85 + `LOW_TICK` 0,25 @28 (alt `TICK` 0,2) → 18/240, 40 off, 10/70 → 30 on, 150 off, 25 on | L2 `false_set` 109–128 ms: ten sam klik, body −4 półtony, cichy niski impuls @28 ms, dłuższy ślizg | rdzeń +2 podziałki, **talia** na linii, **obrys przerywany**, kreska „za daleko” na skali | O, D |
| `counter_rotate` (6, ✔) | C I 0,20→0,40 w 600 ms (× I_event), S 0,15 + T co 110 ms I 0,30 S 0,20 | A3 obwiednia + `LOW_TICK` co 120; A2 `LOW_TICK` 0,35 co 120 (alt `TICK`) → 15/100 co 150 → 25 co 250 | L1+L2 `counter_rotate` (klik zapadki + skrzyp), rytm = haptyka | rdzeń **cofa się** pod kciukiem, łuk-strzałka na czole maleje, element unosi się sam | O, D |
| `overset` (7, –) | T I 0,60 S 0,10 + opór „martwy”: S 0,05, bez modulacji do zwolnienia | `THUD` 0,6 (alt `CLICK` 0,4) → 25/160 → 30 | L2 `overset` 32–38 ms tępy stuk; L1 tej komory milknie | sprężyna = **czarna bryła**, element za linią, **klamra** nad komorą | O, D |
| `drop` (3, ✔) | 2–6 T co 40 ms (liczba ∝ I_event·n), I 0,7→0,4, S 0,6; opór → 0 w 200 ms | `TICK` 0,7→0,4 co 50 → 12/200 ×3 co 70 → 60 | L2 `drop` 151–266 ms: kaskada + grzechot sprężyn | elementy spadają kaskadą 40 ms, rdzeń na 0 skali | O, D |
| `stress` (8, –) | C oporu I +0,10…+0,35, S 0,85; T co 70 ms I 0,2 S 0,9; ≥ 0,9 S/Smax co 45 ms; po 4 s ciągłego: co 140 ms | A3 obwiednia S 0,85–0,9 + `TICK` co 80; A2 `TICK` 0,3 co 80 → 10/90 co 120 → brak | L1 `stress` 324–477 ms: „śpiew” wytrycha, pitch +0…8% ∝ S/Smax | **ugięcie** narzędzia ∝ stres, **poprzeczne rysy** 1→3, drżenie 1 dp ≥ 90% | O, D |
| `break` (1, ✔) | T I 1,0 S 1,0, 40 ms + C → 0 + 150 ms ciszy haptyki | `CLICK` 1,0 + `QUICK_FALL` 0,6 (alt sam `CLICK`) → 40/255 → 60 | L2 `break` 140–176 ms: trzask + odłamek; duck reszty −12 dB / 300 ms | pęknięcie na rysie, uchwyt odskakuje 6 dp, odłamek na stole | O, D |
| `wear` (15, –) | brak w trakcie zamka | brak | L4 `wear` po zamku (warsztat) | zadziory na końcówce 0–4 stopnie (w warsztacie i w przekroju) | O, D |
| `gate_align` (9, –) | T I 0,50 **S 0,40** + dip ×0,7 / 60 ms | `LOW_TICK` 0,6 (alt `CLICK` 0,5, `TICK` 0,6) → 15/140 → 25 | L2 `gate_align` 21–26 ms miękki „tok” | wycięcie i trzpień w jednej linii, **prześwit** (wąska szczelina) | O, D |
| `detector_trip` (2, ✔) | C 80 ms I 0,7 S 0,3, przerwa 60, C 80 ms | A3 dwie obwiednie; A2 `THUD` 0,7 + `THUD` 0,7 @140 (alt `CLICK` 0,8 ×2) → 60/220, 80, 60/220 → to samo on/off | L2 `detector_trip` 180–208 ms: „klak-klak” zatrzasku | zapadka detektora **opada na rygiel** (zmiana sylwetki), klamry na wszystkich dźwigniach | O, D |
| `open` (1, ✔) | C 300 ms I 0→0,3 S 0,4 + T I 1,0 S 0,6 | A3 rampa + `CLICK` 1,0; A2 `SLOW_RISE` 0,3 + `CLICK` 1,0 → 300/60 + 30/255 → 50 | L2 `open` 420–537 ms: obrót + krzywka + rygiel | rygiel do końca 250 ms, rdzeń/kabłąk w pełni | O, D |

**Sygnały ciągłe** (każdy krok, 0–1):

| Sygnał | iOS (osobny player, `sendParameters` ≤ 60 Hz) | Android | Dźwięk L1 (pętla 1,1–1,4 s, RMS −18) | Obraz |
|---|---|---|---|---|
| `tension_resistance` | I = 0,10 + 0,45·r^1,5 (krzywa łagodna na dole), S 0,20–0,35; ducking ×0,3 / 35 ms + 60 ms powrotu | A3/A4 obwiednie po 60 ms; A2/A1 segment 40 ms amp 30–140, aktualizacja 100 ms; A0 brak | `tension_resistance` (materiał zamka): −24…−14 dBFS ∝ r, pitch 0,9–1,2 | wygięcie napinacza w świecie ∝ r, ugięcie skóry pod kciukiem (HUD §5.2) |
| `pick_drag` | I 0,05–0,25 ∝ prędkość, S 0,55–0,75; mikro-T I 0,15 S 0,7 na krawędziach ≤ 20/s | mikro-`TICK` 0,15 ≤ 12/s; A1 `EFFECT_TICK` ≤ 6/s; A0 brak | `pick_drag`: drapanie + mikrotiki, pitch ∝ prędkość | końcówka sunie po elementach; lekki ślad ruchu (bez smug) |

Idle: brak dotyku > 1,5 s → oba kanały ciągłe gasną w 300 ms (haptyka i L1), wracają od razu przy dotyku.

---

## 3. Karty rodzin

Lista zdarzeń w każdej karcie = to, co **faktycznie emituje** kod `lockcore/src/families/*.cpp` (v0.3), plus
`stress`/`break`/`wear` z `ToolStress` tam, gdzie rodzina go używa. Odchylenia od słownika bazowego wypisane są wprost;
wszystko, czego nie ma w karcie, gra jak §2.

### 3.1 `pin_tumbler` — wkładka bębenkowa (t2–t7)
- **Materiał / skala:** mosiądz (rdzeń, piny), narzędzie stal. Rodzina ×1,00 / Δs 0. Pełny słownik.
- **Emituje:** contact (+ `pin.spring_bounce`, + pozorne kontakty sąsiadów przy `noise`), bind, near_shear, set,
  false_set (+ `pin.serration`), counter_rotate, overset, drop, stress, break, wear, open.
- **Ciągłe:** `tension_resistance` = opór rdzenia pod napinaczem; `pick_drag` = wytrych po pinach.
- **Pod-zdarzenia:**

| Pod-zdarzenie | Haptyka | Dźwięk | Obraz |
|---|---|---|---|
| `pin.serration` (baza false_set, I 0,3) | **nie** gra jak false_set (F-04): T I 0,18 S 0,90, 8 ms; bez dipu, bez duckingu; prio 11, nie-essential; A2 `TICK` 0,2 → 8/50 → brak | `ratchet` −6 dB („tyk” ząbka) | ząbek pinu przeskakuje o 1 ząb przez krawędź; rdzeń **nie** obraca się |
| `pin.spring_bounce` (baza contact) | T I 0,12 S 0,55, 10 ms; A2 `TICK` 0,12; A1 brak | `spring` (brzęk zwojów) | pin wraca na dno, zwoje sprężyny drgają 2 cykle (bez overshootu bryły) |

- **Pary do odróżnienia:** set ↔ false_set (§2 + TECH §3.4; potwierdzenie przez counter_rotate) • serration ↔ false_set
  (serration: cichy tyk bez obrotu rdzenia, bez talii) • overset ↔ set (bryła sprężyny + klamra vs równe zwoje + stopka)
  • pozorny contact sąsiada ↔ contact (celowo mylący na wyższych tierach: ten sam dźwięk, ale **cichszy** — I_event
  1/3…1, a obraz rysuje drgnięcie na sąsiednim, nie aktywnym stosie).
- **Counter_rotate:** na urządzeniach z jednym aktuatorem kierunek „w lewy kciuk” daje rytm zapadki, nie lokalizacja;
  w audio panorama o −0,3 (strona napinacza).

### 3.2 `wafer` — wkładka płytkowa (t1–t3)
- **Materiał / skala:** mosiądz; rodzina ×0,85 / +0,05 („lżejsze, wyższe kliknięcia”). Brak false_set i counter_rotate.
- **Emituje:** contact (+ `wafer.rattle`), bind, near_shear, set, overset, drop, stress, break, wear, open.
- **Overset:** wyjście `T < t_release` (0,16) **powyżej** `t_hold` — bez zrzutu. Feel: po overset opór „martwy”, a gdy
  gracz popuści do `t_release`, płytka wraca → gramy `contact` z I 0,5 (stuk powrotu) i znika klamra. Brak `drop`
  w tej sytuacji uczy, że w płytkach overset kosztuje mało.
- **Pod-zdarzenia:** `wafer.rattle` (baza contact, I 0,25): T I 0,10 S 0,80, 8 ms, haptyka ≤ 6/s (dźwięk zawsze);
  A2 `TICK` 0,1; A1 brak. Dźwięk `contact` +8% pitch, −4 dB. Obraz: luźna płytka drga ±1 dp w komorze, **bez** kresek tarcia.
- **Obraz stanów (płytka):** binding = płytka dociśnięta do ściany obudowy + kreski tarcia; set = krawędź płytki równo
  z obwodem rdzenia (stopka = płaska krawędź na linii); overset = płytka wystaje po przeciwnej stronie + klamra.
- **Pary:** rattle ↔ bind (rattle: drganie bez przesunięcia w bok i bez wzrostu oporu L1; bind: kreski + skok oporu).

### 3.3 `wooden_pin` — zasuwa kołkowa (t1, wprowadzenie słownika)
- **Materiał / skala:** drewno (Δs −0,25, ×0,9). Najmniej ostre zdarzenia w grze. Narzędzie **nigdy się nie łamie**
  (`no_break`): nie ma `break`, a `stress` przychodzi wyłącznie jako `wood.creak`.
- **Emituje:** contact, bind, near_shear, set, overset (gdy `overset_enabled`), drop, `wood.creak`, open.
- **Ciągłe:** `tension_resistance` = tarcie zasuwy (ciągnięcie rygla), `pick_drag` = podnośnik po kołkach.
- **Pod-zdarzenia:** `wood.creak` (baza stress, I ∝ (T − τ_creak)): **nie** essential, prio 8. iOS: C oporu
  I +0,05…+0,20, S 0,25 + T co 140 ms I 0,15 S 0,20 (wolny, niski skrzyp; nie „metalowe drżenie”). Android `LOW_TICK` 0,25
  co 160 (alt `TICK` 0,2) → 12/80 co 160 → brak. Dźwięk: `stress` w materiale **wood**, pitch ×0,8. Obraz: na belce
  zasuwy rozchylają się **szczeliny słojów** (1→3 jasne kreski wzdłuż włókien); podnośnik się **nie** wygina.
- **Open:** wymaga przytrzymania `T ≥ t_hold` przez 0,3 s (36 kroków). Feel: w tym czasie opór L1 i haptyka ciągła
  rosną liniowo o +0,1 (zasuwa „idzie”), obraz przesuwa zasuwę o 0→30% drogi, potem `open`. Bez tego gracz nie wie,
  że trzeba trzymać. *Wymaga od lockcore pola postępu w `ViewModel`* (F-07) — do tego czasu warstwa gry liczy 36 kroków
  od ostatniego `set`, wyłącznie kosmetycznie.
- **Pary:** creak ↔ stress innych rodzin (zamierzenie: ta sama rola ostrzeżenia, inny materiał i tempo; na t1 nie ma kary).

### 3.4 `warded` — zamek zapadkowy (t1–t2), widok z czoła
- **Materiał / skala:** żelazo (Δs −0,10, ×1,10); sonda stal. Brak false_set, overset, counter_rotate.
- **Emituje:** contact (zmiana grotu: stal, I 0,3; dociśnięcie do ogranicznika), `ward.scrape`, gate_align (grot zgrany
  z prześwitem przeszkody przed nim), bind (rygiel złapany), set (rygiel uniesiony, I 0,85), drop (rygiel opadł),
  stress, break (tylko t2, po trzech epizodach), open.
- **Ciągłe:** `tension_resistance` = opór obrotu (`theta`); `pick_drag` = przesuw grotu (głębokość/wysokość).
- **Pod-zdarzenia:** `ward.scrape` (baza contact, I 0,45): kanał ciągły `pick_drag` S +0,10 + T co 60 ms I 0,15 S 0,60,
  haptyka ≤ 10/s; Android `TICK` 0,18 co 100 → `EFFECT_TICK` ≤ 5/s → brak. Dźwięk `ward_scrape` 161–245 ms
  (round-robin bez powtórzeń, nakładanie ≤ 2 głosy). Obraz: na krawędzi przeszkody **krótkie rysy** w miejscu tarcia
  (te same kreski tarcia co w bind, ale na przeszkodzie, nie na elemencie); grot nie wchodzi w obrys przeszkody.
- **Zmiana grotu (contact, stal 0,3):** dźwięk `contact` stal + krótki „klik” chwytu; obraz: nowy profil grotu w zwijce
  i w kanale (kwadrat / hak / widełki — różne sylwetki, nie kolory).
- **Stress t1:** sonda się **gnie**, nigdy nie pęka (S < S_max). Obraz: ugięcie zostaje do wyjęcia sondy. Haptyka i dźwięk
  jak `stress`, bez fazy ≥ 0,9.
- **Pary:** scrape ↔ gate_align (scrape: ciągły szorstki szum + rysy; gate_align: jeden miękki „tok” + prześwit) •
  bind ↔ set rygla (bind: rygiel zahaczony, kreski tarcia; set: rygiel podniesiony, stopka na zaczepie).

### 3.5 `lever` — zamek dźwigniowy (t3–t5), widok eksplodowany 2,5D
- **Materiał / skala:** dźwignie mosiądz, skrzynka stal; rodzina ×1,10 / −0,10 („cięższe, niższe”).
- **Emituje:** contact, bind, near_shear, gate_align + set (ten sam krok), false_set + `lever.false_gate` (ten sam krok),
  counter_rotate, overset (wyjście poniżej `t_release` 0,05, kosztem zrzutu), drop, stress, break, wear, open.
- **Ciągłe:** `tension_resistance` = nacisk korby na trzpień rygla; `pick_drag` = podnoszenie dźwigni (+ „szuranie”
  dźwigni o siebie jako tekstura `pick_drag` L1).
- **gate_align + set w jednym kroku:** gramy **jeden** wzorzec `set` (I 0,9·1,1), a `gate_align` tylko w obrazie
  (prześwit) i w dźwięku jako warstwa „tok” −6 dB pod klikiem. Dwa transienty w 0 ms zlałyby się w jeden mocniejszy
  i zatarłyby różnicę z false_set.
- **false_set + `lever.false_gate`:** jeden wzorzec pary z odstępem **40 ms** (rodzina; „wpadnięcie + oparcie”),
  drugi impuls ma I z `lever.false_gate`. Dźwięk: `false_set` + `lever_fall` z opóźnieniem 40 ms.
  Obraz: trzpień w **płytkim** nacięciu (krótsze niż bramka), obrys dźwigni przerywany, korba drgnęła o 2 podziałki.
- **Opadanie na sprężynie** (podnośnik puszcza związaną dźwignię): bez zdarzenia lockcore — obraz dźwigni opada
  0,3→0,5 × 4/s; dźwięk `lever_fall` wyzwalany przez warstwę gry, gdy pozycja w `ViewModel` spada o ≥ 0,1 bez nacisku;
  haptyka brak (to nie stan, tylko ruch).
- **Set → podążanie:** ustawiona dźwignia jedzie z podnośnikiem nad bramką maks. 0,6/s. Feel: dopóki ustawiona dźwignia
  jest unoszona, `pick_drag` S +0,1 (cięższa) — sygnał, że za chwilę overset.
- **Pary:** set ↔ false_set (1 klik + prześwit vs para 40 ms + płytkie nacięcie + przerywany obrys) • overset ↔ false_set
  (overset: tępy THUD, klamra nad dźwignią, dźwignia ponad bramką; nie ma drugiego impulsu).

### 3.6 `lever_detector` — dźwigniowy z detektorem (t5–t6)
- **Jak `lever`**, plus stan `jammed` (detektor) i reset.
- **`detector_trip`** (prio 2, essential): §2; to jedyne zdarzenie rodziny, które brzmi jak „zamknięcie drzwi”.
  Obraz: zapadka detektora (osobna, cieńsza dźwignia z zaczepem, zawsze na wierzchu) **opada i zachodzi** na rygiel;
  **klamra** nad każdą dźwignią (wszystkie `jammed`); rdzeń skali przekreślony poziomą kreską. Dźwięk L1 tarcia gaśnie.
  Haptyka ciągła oporu przechodzi w „martwą” (S 0,05) jak przy overset.
- **Reset:** `T < t_hold` i `rotate ≤ −1/2` przez 1,5 s (t5) / 2,5 s (t6). Podczas trzymania: obraz — łuk postępu
  wyryty na czole rygla (krokowo co 0,25 s), dźwięk — ciche tyknięcia `ratchet` co 250 ms, haptyka — `TICK` 0,15 co 250 ms
  (iOS T I 0,15 S 0,5). *Wymaga pola `reset_progress` w `ViewModel`* (F-07); bez niego — licznik po stronie gry.
- **`detector.reset`** (baza drop, sub 2; essential, prio 3): to **ulga**, nie kara, więc nie gra jak `drop`.
  iOS: C 350 ms I 0,30→0 S 0,20 + 3 miękkie T (120/200/260 ms, I 0,25 S 0,30). Android: `QUICK_FALL` 0,4 + `LOW_TICK` 0,25
  ×3 (alt `TICK` 0,3 ×3) → 12/120, 110, 12/100, 70, 12/80 → 40 on. Dźwięk: `lever_fall` ×3 (120/80/60 ms) + zwolnienie
  zapadki. Obraz: zapadka unosi się, klamry znikają jedna po drugiej (40 ms), dźwignie opadają luźno.
  Trzeci trip blokuje zamek (`FailureKind::detector_trip`): obraz zostaje w stanie jammed, dźwięk `detector_trip` −6 dB,
  bez dodatkowej haptyki (komunikat ślusarza w UI).
- **Pary:** detector_trip ↔ overset (trip: dwa ciężkie po 140 ms, wszystkie klamry, zapadka; overset: jeden THUD, jedna
  klamra) • detector.reset ↔ drop (reset: wolniejszy, malejący, poprzedzony łukiem postępu; drop: szybka kaskada 40 ms).

### 3.7 `ring_combo` — kłódka szyfrowa z pierścieniami (t2–t3)
- **Materiał / skala:** mosiądz (pierścienie, korpus), kabłąk stal; rodzina ×0,90. Bez stresu i łamania.
  Lockcore już skaluje sygnały przez `gate_feel` (t2 0,7, t3 0,45) — **nie** dokładamy drugiego skalowania;
  zamiast tego `continuousFloor` dotyczy też `set` i `false_set` (essential), żeby t3 nie zeszło poniżej progu czucia.
- **Emituje:** contact (+ `ring.detent`), bind (najniższy nieustawiony pierścień wiąże), near_shear („zapadnięcie”,
  I = gate_feel/2), gate_align + set (pierścień wpada w bramkę), false_set (fałszywe nacięcie, t3), drop (puszczenie
  ciągu kasuje flagi set, pozycje zostają), open.
- **Ciągłe:** `tension_resistance` = ciąg kabłąka; `pick_drag` = opór obrotu pierścienia (sztywny, gdy związany).
- **`ring.detent`** (baza contact; I 0,15 luźny / 0,35 związany, × (0,5 + gate_feel/2)): T I 0,22 S 0,65, 10 ms.
  Limit haptyki: iOS 12/s, A2–A4 8/s, A1 4/s, A0 0 (dźwięk do 25/s, kradzież najstarszego głosu). Dźwięk `ring_detent`.
  Obraz: cyfra przeskakuje o jedną pozycję, kreska podziałki na korpusie (krokowo, 100 ms).
  Związany pierścień ma detent **mocniejszy i niższy** (I 0,35 → wyraźnie inny niż luźny 0,15).
- **near_shear „zapadnięcie”:** ciągły opór S +0,15 + T I 0,12; dźwięk `near_shear`; obraz pierścień przesuwa się
  osiowo o 1 dp, klin między pierścieniem a ząbkiem trzpienia zwęża się.
- **set (z gate_align):** jeden wzorzec `set`; obraz — pierścień **wpada** osiowo o 3 dp, wycięcie widać w przekroju;
  dźwięk `set` + `gate_align` −6 dB.
- **false_set (fałszywe nacięcie):** para 28 ms; obraz — wpadnięcie tylko o 1,5 dp, nacięcie płytkie, obrys przerywany;
  wyjście: popuszczenie ciągu poniżej `band_lo` → gramy `contact` (I 0,4) + pierścień wraca do osi.
- **Pary:** detent ↔ near_shear (detent: krótki tyk co cyfrę bez ruchu osiowego; near_shear: zmiana tekstury oporu
  + przesuw 1 dp) • set ↔ false_set (3 dp vs 1,5 dp, pełny vs przerywany obrys, klik vs para).

---

## 4. Macierz rozróżnialności (wszystkie rodziny)

Każdy wspólny stan (LOCKS §1.4) ma znak obrazu z jednego słownika (DESIGN §1: kreski tarcia, klin, stopka, talia,
przerywany obrys, klamra, bryła sprężyny, ugięcie + rysy, prześwit) i własny rytm dźwięku. Sprawdzenie
(✔ = rozróżnialny od sąsiednich stanów tym kanałem, samodzielnie):

| Stan | Obraz w szarości (A7) | Dźwięk sam (iPad, A–) | Haptyka | Kanały niehaptyczne |
|---|---|---|---|---|
| free | ✔ oś komory, równe zwoje | ✔ ciche tarcie | ✔ | 2 |
| bound | ✔ przesunięcie + 3 kreski | ✔ skrobanie gęstnieje | ✔ | 2 |
| near | ✔ klin się zwęża | ✔ ziarno drobnieje (HP) | ✔ (S ↑) | 2 |
| set | ✔ stopka, +1 podziałka | ✔ 1 jasny klik | ✔ | 2 |
| false_set | ✔ talia/płytkie nacięcie, przerywany obrys, +2 podziałki | ✔ para klik + niski impuls | ✔ | 2 |
| counter_rotate | ✔ cofanie rdzenia, łuk maleje | ✔ rytm zapadki 110–120 ms | ✔ | 2 |
| overset | ✔ klamra, bryła sprężyny | ✔ tępy stuk, potem cisza komory | ✔ (martwy opór) | 2 |
| jammed (detektor) | ✔ zapadka na ryglu, klamry wszędzie | ✔ „klak-klak” + cisza L1 | ✔ | 2 |
| stress | ✔ ugięcie + rysy (drewno: szczeliny słojów) | ✔ „śpiew” / skrzyp | ✔ | 2 |
| break | ✔ pęknięcie, odłamek | ✔ trzask | ✔ | 2 |
| drop / reset | ✔ kaskada / klamry znikają | ✔ szybka vs wolna kaskada | ✔ | 2 |
| open | ✔ rygiel / kabłąk | ✔ długi szczęk | ✔ | 2 |

Ryzyka rozróżnialności i środki:
- **set vs false_set na głośniku telefonu:** podpis false_set ma ziarno w paśmie średnim, żeby przetrwał HP 500 Hz
  (`audio/v2`: Δcentroid −32…−39%, energia po 25 ms +4,6…+10,5 dB). Drewno: centroid na głośniku *rośnie* (+27%), ale
  energia po 25 ms +10,5 dB wystarcza; w `wooden_pin` i tak nie ma false_set.
- **overset vs bind przy niskiej jasności:** klamra ma 2 dp grubości i ±1 dp czystego tła; bryła sprężyny = wypełnienie,
  nie kolor.
- **ring t3 (`gate_feel` 0,45):** różnicę set/false_set niesie głównie obraz (3 vs 1,5 dp) i rytm; floor haptyczny
  utrzymuje oba transienty powyżej progu z kalibracji.
- **A0 / H1 (bez prymitywów):** para false_set rozjeżdża się do 150 ms (on/off) — wciąż „podwójny”; detent i scrape bez
  haptyki, zostają w dźwięku i obrazie.

---

## 5. Budżet intensywności (3-minutowy zamek bez zmęczenia)

Cel: po 3 min ciągłej gry ostatni `set` czuć tak wyraźnie jak pierwszy, a dłoń nie jest „zdrętwiała”. Zmęczenie
w haptyce bierze się głównie z **długiego ciągłego tła o wysokiej sharpness** i z **gęstych mocnych transientów**;
w dźwięku z ciągłej pętli L1 na wysokim poziomie i z powtarzania identycznych próbek.

### 5.1 Limity (okno = 180 s, liczone na żywo w oknach kroczących)

| Metryka | Limit | Uwagi |
|---|---|---|
| RMS intensywności ciągłej (oba kanały, po suwaku) | ≤ 0,30 | krzywa oporu `0,10 + 0,45·r^1,5` daje ~0,22 przy typowym r 0,4–0,5 |
| Wypełnienie kanału ciągłego (I > 0,05) | ≤ 70% | idle-fade po 1,5 s bez dotyku |
| Sharpness ciągła | ≤ 0,75 | wyjątek: `stress` (S 0,85–0,9) maks. 4 s ciągłe, potem tylko tyki co 140 ms |
| Transienty / 10 s | iOS 40, A2–A4 25, A1 15, A0 8 | średnio; chwilowo obowiązują limity TECH §3.5 (25/12/6/3 na s) |
| Mocne transienty (I ≥ 0,7) / 10 s | ≤ 8 | essential liczone, **nigdy** odrzucane; przy przekroczeniu tniemy prio ≥ 11 |
| Dźwięk L1 (krótkoterminowo) | ≤ −20 dBFS | ducking L1 −6 dB / 50 ms na każde L2 |
| Głośność rozgrywki | −23 LUFS integr., L2 peak ≤ −1 dBFS | open/break jedyne zbliżone do peaku |
| Powtórzenia SFX | 6 wariantów, bez powtórzenia tego samego pod rząd, ±3% pitch, ±1,5 dB | `sfx.gd` ma `VARIANTS := 4` (F-09) |

### 5.2 Regulator zmęczenia (w `FeedbackDirector`)
1. Kroczące 30 s: jeśli RMS ciągłej > 0,35 → skala kanałów ciągłych liniowo do min. 0,75 (nigdy poniżej
   `continuousFloor + 0,05`). Powrót w 10 s, gdy RMS < 0,28.
2. Gdy przekroczony limit transientów: najpierw odrzucamy haptykę prio ≥ 11 (contact, near_shear-tick, detent,
   rattle, scrape-tick, serration), **dźwięk tych zdarzeń zostaje**. Potem prio 9–10 (bind, gate_align). Essential nigdy.
3. `stress` po 4 s ciągłych: tyki co 140 ms, I bez zmian (ostrzeżenie zostaje, znika „brzęczenie” dłoni).
4. Po `break`: 150 ms ciszy haptyki, potem kanały ciągłe wracają rampą 300 ms (nie skokiem).
5. Nic z regulatora nie zmienia obrazu ani logiki.

### 5.3 Szacunek obciążenia: trudny 3-minutowy zamek (`pin_tumbler` t5, gracz się zmaga)
Założenia: 4 zrzuty, 2 overset, 2 epizody stresu, 1 szpulka z 3 próbami kontrrotacji, opór aktywny 150 s z 180.

| Źródło | Liczba / 3 min | Haptyka po regulatorze | Uwagi |
|---|---|---|---|
| contact + pozorne | ~300 | ~150 (limit/coalescing) | ~0,8/s, I ≤ 0,3 — tło, nie męczy |
| bind | ~45 | 45 | I 0,45 |
| near_shear (tick) | ~35 | 35 | I 0,12 |
| set | ~28 (6 × 4 próby + reszta) | 28 | mocne |
| false_set | ~6 | 6 | mocne |
| counter_rotate | ~5 s łącznie | ~45 tyków | I 0,30 |
| serration | ~20 | 20 | I 0,18 |
| overset / drop / break / open | 2 / 4 / 0 / 1 | 7 | mocne |
| stress | ~6 s | ~60 tyków (część co 140 ms) | S 0,9 |
| **Razem** | | **~395 transientów = 2,2/s**; mocne ~42 = **2,3 / 10 s** | w budżecie (40 i 8 / 10 s) |

Ciągłe: RMS ≈ 0,22 przy wypełnieniu ~65% — w budżecie. Najwyższe ryzyko w innych rodzinach:
`ring_combo` (szybkie kręcenie: detenty > 20/s → limit 12/s haptyki, dźwięk do 25/s), `warded` (długi `ward.scrape` →
tyk co 60 ms limitowany do 10/s), `lever_detector` (reset 1,5–2,5 s + tyki co 250 ms — tanie).

---

## 6. Rozstrzygnięcia rozbieżności (proponowane; do wpisania jako D-NN przez koordynatora)

| # | Rozbieżność | Rozstrzygnięcie |
|---|---|---|
| F-01 | `false_set`: drugi impuls 40–60 ms (DESIGN) vs 28 ms (TECH, `audio/v2`) | 28 ms w pinach i pierścieniach (zgodnie z gotowym audio), **40 ms w dźwigniach** (rodzina: „wpadnięcie + oparcie”). A1 40 ms, A0 150 ms (fizyczny limit ERM). |
| F-02 | `counter_rotate`: I 0,35→0,15 (TECH) vs „narastająca” (DESIGN) | narastająca 0,20→0,40 w 600 ms × I_event (∝ nacisk) — „pchanie wstecz” rośnie, im mocniej gracz napiera. |
| F-03 | `gate_align`: S 0,50 (TECH) vs „niska sharpness” (DESIGN) | S 0,40; na Androidzie pierwszy wybór `LOW_TICK`. |
| F-04 | `pin.serration` gra jak bazowy `false_set` (essential, dip oporu, ducking) | własny wzorzec: drobny tyk, nie-essential, prio 11, bez dipu. Inaczej ząbki pinu udawałyby fałszywe ustawienie. |
| F-05 | zdarzenia z jednego kroku (`gate_align`+`set`, `false_set`+`lever.false_gate`) | jeden wzorzec haptyczny; drugie zdarzenie tylko jako warstwa dźwięku/obrazu (lub drugi impuls pary). |
| F-06 | `stress`: 20–30 tyków/s (DESIGN) vs co 70 ms (TECH) | 70 ms (14/s); 45 ms (22/s) tylko ≥ 0,9 S/Smax na iOS; Android 80 ms (limit 12/s). Po 4 s: 140 ms (budżet). |
| F-07 | brak pól postępu w `ViewModel` (`wooden_pin` open-hold, reset detektora) | prośba do lockcore o `hold_progress`/`reset_progress` (Q16, tylko odczyt, nie wpływa na hash); do tego czasu licznik kosmetyczny w grze. |
| F-08 | priorytety: `events.hpp`/LOCKS §1.6 (`stress` > `open`, wyższy wygrywa) vs TECH/JSON (1 = najwyższy, `open` = 1) | dla prezentacji obowiązuje JSON (`break`=`open`=1, `detector_trip` 2, `drop` 3 … `stress` 8). `stress` jest ciągły i nie konkuruje z `open` (po open nie ma nacisku). |
| F-09 | `sfx.gd` `VARIANTS := 4`, `audio/v2` ma 6 | 6 wariantów, losowanie bez powtórzenia poprzedniego. |

---

## 7. Uwagi dla sesji B (stan `feedback_director.gd` / `haptics.gd` / `sfx.gd`, tylko odczyt)

1. **Odwrócony warunek przerwania:** przy przekroczonym limicie `if priority >= 3: pop_front()` przepuszcza zdarzenia
   o *niskiej* ważności (3–15), a odrzuca `break`/`open`/`detector_trip` (1–2). Powinno być `priority <= 3`
   (`mix_rules.interrupt_priority_max`).
2. **Pod-zdarzenia ignorowane:** `emit_event` czyta tylko `kind` → `pin.serration` gra jak pełny `false_set`
   (essential + floor + ducking), `ring.detent`/`ward.scrape` nie mają własnych dźwięków (`ring_detent`, `ward_scrape`
   już są w `audio/v2`). Routing: `sub_events["<rodzina>.<nazwa>"]`, potem baza.
3. **Koalescencja po `kind`** łączy `false_set` z `lever.false_gate` (ten sam krok) i gubi drugi impuls; dodatkowo
   przesuwa `at` przy każdym zdarzeniu, więc strumień detentów co < 30 ms tłumi się bez końca. Koalescować po
   (kind, sub, element) i bez przesuwania okna.
4. **Ducking bez powrotu:** `_duck_continuous()` ustawia opór na 0, a późniejsze `update_continuous` z tą samą wartością
   jest odrzucane jako no-op (porównanie z `_last_continuous`, który ducking omija) → opór może zostać wyzerowany.
   Ducking ×0,3 / 35 ms + rampa 60 ms, po stronie mostka (`duck()`).
5. **Podwójne skalowanie suwakiem** dla essential: reżyser mnoży przez `haptics_intensity`, potem `Haptics._scaled_intensity`
   mnoży drugi raz (i jeszcze przez bazowe I wzorca, już po floorze). Floor stosować **na końcu**, raz.
6. `Sfx.play()` ma `VARIANTS := 4` (F-09) i nie zna `sfx.id` innego niż nazwa zdarzenia (np. `lever_fall`, `ratchet`).

---

## 8. Testy akceptacji odczucia (uzupełnienie DESIGN §4)

| # | Test | Próg |
|---|---|---|
| F-A1 | Po tutorialu rodziny: set vs false_set, 10 losowych prób, tryby: pełny / tylko dźwięk / dźwięk + haptyka | ≥ 80% trafień po potwierdzeniu, ≥ 40% od razu (TECH §3.4), w każdej rodzinie z false_set |
| F-A2 | Zrzuty w szarości każdego stanu z §4 dla każdej rodziny (7 × do 12) | ≥ 90% trafień (A7) |
| F-A3 | 3-min sesja na zamku z §5.3; ocena zmęczenia dłoni 1–5 i „czy ostatni set był wyraźny” | mediana ≤ 2, ≥ 85% „tak” |
| F-A4 | Log reżysera z 10 powtórek (`replay_tool play` → zdarzenia → reżyser offline) | 0 przekroczeń limitów §5.1 po regulatorze, 0 odrzuconych essential |
| F-A5 | Tier A0 i H1: rodziny t1–t3 do ukończenia | 100% (dźwięk + obraz wystarczają) |
| F-A6 | Onset SFX i synchronizacja | onset ≤ 2 ms (`check_v2.py`), |Δ audio–haptyka| p95 ≤ 15 ms (piezo + mikrofon) |

---

## 9. Łatka do `game/data/haptics_patterns.json` (dla sesji B)

Format: **JSON Merge Patch (RFC 7396)**, addytywny: istniejące klucze `ios`/`android`/`fallback` zostają (obecny kod
działa dalej); zmieniają się tylko `counter_rotate.ios.intensity_from/to` (F-02) i `gate_align.ios.sharpness` (F-03).
Nowe sekcje: `events.*.android_chain`, `events.*.sfx`, `sub_events`, `families`, `mix_rules.*`, `budget`.
Sprawdzone: nakłada się na bieżący plik bez błędów, wszystkie prymitywy z listy Androida
(`CLICK, TICK, LOW_TICK, THUD, SPIN, QUICK_RISE, SLOW_RISE, QUICK_FALL`).

Semantyka nowych pól:
- `android_chain[]`: `{tier, composition: [[PRIM, scale, delay_ms]], envelope: [[t_ms, I, S]], waveform: {timings, amps, repeat},
  effect, on_ms, pattern_ms, skip, repeat_interval_ms, tick, then}` — wybór jak w §1.3.
- `sub_events["fam.name"]`: pełny wzorzec z `base` (do fallbacku), `ducks_resistance`, `haptic_limit_per_s`,
  `fold_into` (gra jako część wzorca bazy).
- `families[id]`: `material` domyślny, `intensity_scale`, `delta_sharpness`, `false_set_second_delay_ms`, `no_break`,
  `events_scaled_by_gate_feel` (nie skalować drugi raz).
- `budget`: limity i regulator z §5.

```json
{
  "source": "docs/TECH.md §3.2-3.5, docs/FEEL.md (patch F-1)",
  "feel_version": 2,
  "events": {
    "contact": {
      "android_chain": [{"tier": "a2", "composition": [["TICK", 0.35, 0]]}, {"tier": "a1", "waveform": {"timings": [10], "amps": [70]}}, {"tier": "a0", "skip": true}],
      "sfx": {"id": "contact", "variants": 6, "pitch_jitter": 0.03, "gain_jitter_db": 1.5}
    },
    "bind": {
      "android_chain": [
        {"tier": "a3", "composition": [["LOW_TICK", 0.5, 0]], "envelope": [[0, 0.3, 0.3], [80, 0.5, 0.3]]},
        {"tier": "a2", "composition": [["LOW_TICK", 0.5, 0]]},
        {"tier": "a2", "composition": [["TICK", 0.4, 0]]},
        {"tier": "a1", "waveform": {"timings": [15], "amps": [110]}},
        {"tier": "a0", "skip": true}
      ],
      "sfx": {"id": "bind", "variants": 6}
    },
    "near_shear": {
      "ios": {"entry_tick_intensity": 0.12, "entry_tick_sharpness": 0.8, "entry_tick_once_per_window": true},
      "android_chain": [
        {"tier": "a3", "envelope": [[0, 0.3, 0.45], [150, 0.3, 0.45], [450, 0.3, 0.3]]},
        {"tier": "a2", "composition": [["QUICK_RISE", 0.2, 0]]},
        {"tier": "a2", "composition": [["TICK", 0.12, 0]]},
        {"tier": "a1", "resistance_amp_boost_pct": 20},
        {"tier": "a0", "skip": true}
      ],
      "sfx": {"id": "near_shear", "variants": 6, "layer": "L1_filter", "hp_shift_hz": 600}
    },
    "set": {
      "android_chain": [
        {"tier": "a2", "composition": [["CLICK", 0.9, 0]]},
        {"tier": "a1", "waveform": {"timings": [18], "amps": [255]}},
        {"tier": "a1", "effect": "EFFECT_CLICK"},
        {"tier": "a0", "on_ms": 30}
      ],
      "sfx": {"id": "set", "variants": 6}
    },
    "false_set": {
      "android_chain": [
        {"tier": "a2", "composition": [["CLICK", 0.85, 0], ["LOW_TICK", 0.25, 28]]},
        {"tier": "a2", "composition": [["CLICK", 0.85, 0], ["TICK", 0.2, 28]]},
        {"tier": "a1", "waveform": {"timings": [18, 40, 10], "amps": [240, 0, 70]}},
        {"tier": "a0", "on_ms": 30, "second_on_ms": 25, "second_gap_ms": 150}
      ],
      "sfx": {"id": "false_set", "variants": 6}
    },
    "counter_rotate": {
      "ios": {"intensity_from": 0.2, "intensity_to": 0.4, "ramp_ms": 600, "intensity_follows_event": true},
      "android_chain": [
        {"tier": "a3", "envelope": [[0, 0.2, 0.15], [600, 0.4, 0.15]], "tick": ["LOW_TICK", 0.35], "tick_interval_ms": 120},
        {"tier": "a2", "composition": [["LOW_TICK", 0.35, 0]], "repeat_interval_ms": 120},
        {"tier": "a2", "composition": [["TICK", 0.35, 0]], "repeat_interval_ms": 120},
        {"tier": "a1", "waveform": {"timings": [15, 135], "amps": [100, 0], "repeat": 0}},
        {"tier": "a0", "on_ms": 25, "interval_ms": 250}
      ],
      "sfx": {"id": "counter_rotate", "variants": 6, "rhythm_from_haptic": true}
    },
    "overset": {
      "ios": {"dead_resistance": true},
      "android_chain": [
        {"tier": "a2", "composition": [["THUD", 0.6, 0]]},
        {"tier": "a2", "composition": [["CLICK", 0.4, 0]]},
        {"tier": "a1", "waveform": {"timings": [25], "amps": [160]}},
        {"tier": "a0", "on_ms": 30}
      ],
      "sfx": {"id": "overset", "variants": 6, "mute_element_l1": true}
    },
    "drop": {
      "ios": {"count_from_event": [2, 6]},
      "android_chain": [
        {"tier": "a2", "composition": [["TICK", 0.7, 0], ["TICK", 0.6, 50], ["TICK", 0.5, 50], ["TICK", 0.4, 50]]},
        {"tier": "a1", "waveform": {"timings": [12, 70, 12, 70, 12], "amps": [200, 0, 160, 0, 120]}},
        {"tier": "a0", "on_ms": 60}
      ],
      "sfx": {"id": "drop", "variants": 6}
    },
    "stress": {
      "ios": {"tick_interval_ms_high": 45, "high_threshold": 0.9, "sustain_cap_ms": 4000, "after_cap_tick_interval_ms": 140},
      "android_chain": [
        {"tier": "a3", "envelope": [[0, 0.3, 0.85], [400, 0.55, 0.9]], "tick": ["TICK", 0.3], "tick_interval_ms": 80},
        {"tier": "a2", "composition": [["TICK", 0.3, 0]], "repeat_interval_ms": 80},
        {"tier": "a1", "waveform": {"timings": [10, 110], "amps": [90, 0], "repeat": 0}},
        {"tier": "a0", "skip": true}
      ],
      "sfx": {"id": "stress", "variants": 6, "pitch_from_event": [1.0, 1.08]}
    },
    "break": {
      "android_chain": [
        {"tier": "a2", "composition": [["CLICK", 1.0, 0], ["QUICK_FALL", 0.6, 0]]},
        {"tier": "a2", "composition": [["CLICK", 1.0, 0]]},
        {"tier": "a1", "waveform": {"timings": [40], "amps": [255]}},
        {"tier": "a0", "on_ms": 60}
      ],
      "sfx": {"id": "break", "variants": 6, "duck_all_db": -12, "duck_ms": 300}
    },
    "wear": {"sfx": {"id": "wear", "variants": 6, "layer": "L4", "in_lock": false}},
    "gate_align": {
      "ios": {"sharpness": 0.4},
      "android_chain": [
        {"tier": "a2", "composition": [["LOW_TICK", 0.6, 0]]},
        {"tier": "a2", "composition": [["CLICK", 0.5, 0]]},
        {"tier": "a2", "composition": [["TICK", 0.6, 0]]},
        {"tier": "a1", "waveform": {"timings": [15], "amps": [140]}},
        {"tier": "a0", "on_ms": 25}
      ],
      "sfx": {"id": "gate_align", "variants": 6}
    },
    "detector_trip": {
      "android_chain": [
        {"tier": "a3", "envelope": [[0, 0.7, 0.3], [80, 0.7, 0.3], [81, 0.0, 0.3], [140, 0.0, 0.3], [141, 0.7, 0.3], [220, 0.7, 0.3], [221, 0.0, 0.3]]},
        {"tier": "a2", "composition": [["THUD", 0.7, 0], ["THUD", 0.7, 140]]},
        {"tier": "a2", "composition": [["CLICK", 0.8, 0], ["CLICK", 0.8, 140]]},
        {"tier": "a1", "waveform": {"timings": [60, 80, 60], "amps": [220, 0, 220]}},
        {"tier": "a0", "pattern_ms": [60, 80, 60]}
      ],
      "sfx": {"id": "detector_trip", "variants": 6}
    },
    "open": {
      "android_chain": [
        {"tier": "a3", "envelope": [[0, 0.0, 0.4], [300, 0.3, 0.4]], "then": ["CLICK", 1.0]},
        {"tier": "a2", "composition": [["SLOW_RISE", 0.3, 0], ["CLICK", 1.0, 0]]},
        {"tier": "a2", "composition": [["CLICK", 1.0, 0]]},
        {"tier": "a1", "waveform": {"timings": [300, 30], "amps": [60, 255]}},
        {"tier": "a0", "on_ms": 50}
      ],
      "sfx": {"id": "open", "variants": 6}
    }
  },
  "sub_events": {
    "pin.serration": {
      "base": "false_set",
      "priority": 11,
      "essential": false,
      "audio_layer": "L2",
      "ducks_resistance": false,
      "ios": {"type": "transient", "intensity": 0.18, "sharpness": 0.9, "duration_ms": 8},
      "android_chain": [{"tier": "a2", "composition": [["TICK", 0.2, 0]]}, {"tier": "a1", "waveform": {"timings": [8], "amps": [50]}}, {"tier": "a0", "skip": true}],
      "sfx": {"id": "ratchet", "variants": 6, "gain_db": -6}
    },
    "pin.spring_bounce": {
      "base": "contact",
      "priority": 12,
      "essential": false,
      "audio_layer": "L2",
      "ducks_resistance": false,
      "ios": {"type": "transient", "intensity": 0.12, "sharpness": 0.55, "duration_ms": 10},
      "android_chain": [{"tier": "a2", "composition": [["TICK", 0.12, 0]]}, {"tier": "a1", "skip": true}],
      "sfx": {"id": "spring", "variants": 6}
    },
    "wafer.rattle": {
      "base": "contact",
      "priority": 12,
      "essential": false,
      "audio_layer": "L2",
      "ducks_resistance": false,
      "haptic_limit_per_s": 6,
      "ios": {"type": "transient", "intensity": 0.1, "sharpness": 0.8, "duration_ms": 8},
      "android_chain": [{"tier": "a2", "composition": [["TICK", 0.1, 0]]}, {"tier": "a1", "skip": true}],
      "sfx": {"id": "contact", "variants": 6, "pitch": 1.08, "gain_db": -4}
    },
    "wood.creak": {
      "base": "stress",
      "priority": 8,
      "essential": false,
      "audio_layer": "L1",
      "ios": {
        "type": "continuous_mod",
        "intensity_boost": [0.05, 0.2],
        "sharpness": 0.25,
        "tick_interval_ms": 140,
        "tick_intensity": 0.15,
        "tick_sharpness": 0.2
      },
      "android_chain": [
        {"tier": "a2", "composition": [["LOW_TICK", 0.25, 0]], "repeat_interval_ms": 160},
        {"tier": "a2", "composition": [["TICK", 0.2, 0]], "repeat_interval_ms": 160},
        {"tier": "a1", "waveform": {"timings": [12, 148], "amps": [80, 0], "repeat": 0}},
        {"tier": "a0", "skip": true}
      ],
      "sfx": {"id": "stress", "material": "wood", "variants": 6, "pitch": 0.8}
    },
    "ward.scrape": {
      "base": "contact",
      "priority": 12,
      "essential": false,
      "audio_layer": "L1",
      "ducks_resistance": false,
      "haptic_limit_per_s": 10,
      "ios": {"type": "continuous_mod", "channel": "pick_drag", "sharpness_boost": 0.1, "tick_interval_ms": 60, "tick_intensity": 0.15, "tick_sharpness": 0.6},
      "android_chain": [
        {"tier": "a2", "composition": [["TICK", 0.18, 0]], "repeat_interval_ms": 100},
        {"tier": "a1", "effect": "EFFECT_TICK", "limit_per_s": 5},
        {"tier": "a0", "skip": true}
      ],
      "sfx": {"id": "ward_scrape", "variants": 6}
    },
    "lever.false_gate": {
      "base": "false_set",
      "priority": 5,
      "essential": true,
      "audio_layer": "L2",
      "fold_into": "false_set.second",
      "ios": {"type": "folded"},
      "android_chain": [{"tier": "a2", "folded": true}],
      "sfx": {"id": "lever_fall", "variants": 6, "delay_ms": 40}
    },
    "detector.reset": {
      "base": "drop",
      "priority": 3,
      "essential": true,
      "audio_layer": "L2",
      "ios": {
        "type": "continuous_then_transients",
        "continuous": {"ms": 350, "intensity_from": 0.3, "intensity_to": 0.0, "sharpness": 0.2},
        "transients": [[120, 0.25, 0.3], [200, 0.25, 0.3], [260, 0.25, 0.3]]
      },
      "android_chain": [
        {"tier": "a2", "composition": [["QUICK_FALL", 0.4, 0], ["LOW_TICK", 0.25, 120], ["LOW_TICK", 0.25, 80], ["LOW_TICK", 0.25, 60]]},
        {"tier": "a2", "composition": [["TICK", 0.3, 120], ["TICK", 0.3, 80], ["TICK", 0.3, 60]]},
        {"tier": "a1", "waveform": {"timings": [12, 110, 12, 70, 12], "amps": [120, 0, 100, 0, 80]}},
        {"tier": "a0", "on_ms": 40}
      ],
      "sfx": {"id": "lever_fall", "variants": 6, "count": 3, "interval_ms": [120, 80, 60]}
    },
    "ring.detent": {
      "base": "contact",
      "priority": 12,
      "essential": false,
      "audio_layer": "L2",
      "ducks_resistance": false,
      "haptic_limit_per_s": {"ios": 12, "android_a2_a4": 8, "a1": 4, "a0": 0},
      "ios": {"type": "transient", "intensity": 0.22, "sharpness": 0.65, "duration_ms": 10},
      "android_chain": [{"tier": "a2", "composition": [["TICK", 0.22, 0]]}, {"tier": "a1", "effect": "EFFECT_TICK"}, {"tier": "a0", "skip": true}],
      "sfx": {"id": "ring_detent", "variants": 6, "audio_limit_per_s": 25}
    }
  },
  "families": {
    "pin_tumbler": {"material": "brass", "intensity_scale": 1.0, "delta_sharpness": 0.0, "false_set_second_delay_ms": 28},
    "wafer": {"material": "brass", "intensity_scale": 0.85, "delta_sharpness": 0.05},
    "wooden_pin": {"material": "wood", "intensity_scale": 1.0, "delta_sharpness": 0.0, "no_break": true},
    "warded": {"material": "iron", "intensity_scale": 1.0, "delta_sharpness": 0.0},
    "lever": {"material": "brass", "intensity_scale": 1.1, "delta_sharpness": -0.1, "false_set_second_delay_ms": 40},
    "lever_detector": {"material": "brass", "intensity_scale": 1.1, "delta_sharpness": -0.1, "false_set_second_delay_ms": 40},
    "ring_combo": {"material": "brass", "intensity_scale": 0.9, "delta_sharpness": 0.0, "false_set_second_delay_ms": 28, "events_scaled_by_gate_feel": true}
  },
  "mix_rules": {
    "interrupt_priority_max": 3,
    "route_sub_events_before_coalesce": true,
    "per_element_gap_ms": 30,
    "sfx_voice_limit": 16,
    "sfx_no_immediate_repeat": true,
    "onset_max_ms": 2,
    "av_sync_max_ms": 15
  },
  "budget": {
    "window_s": 180,
    "continuous_rms_max": 0.3,
    "continuous_duty_max": 0.7,
    "continuous_sharpness_max": 0.75,
    "idle_fade_after_ms": 1500,
    "idle_fade_ms": 300,
    "transients_per_10s_max": {"ios": 40, "android_a2_a4": 25, "a1": 15, "a0": 8},
    "strong_transients_per_10s_max": 8,
    "strong_threshold": 0.7,
    "governor": {"rolling_s": 30, "continuous_rms_trigger": 0.35, "continuous_scale_min": 0.75, "shed_priority_from": 11, "recover_s": 10},
    "audio": {"l1_short_term_max_dbfs": -20, "gameplay_integrated_lufs": -23, "l2_peak_max_dbfs": -1}
  }
}
```
