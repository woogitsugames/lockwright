# audio/v2 — generator SFX metodą syntezy modalnej

**Co to jest.** Offline'owy generator dźwięków mechanizmów (`synth_v2.py`, Python 3 + numpy, nic więcej)
i walidator (`check_v2.py`). Wszystko to nasz kod: zero cudzych sampli, zero zależności poza numpy.
Wyjście ma ten sam układ co `game/assets/audio/sfx` i podmienia obecny prosty generator (`audio/tools/synth.py`),
którego nie ruszamy.

```bash
python3 audio/v2/synth_v2.py && python3 audio/v2/check_v2.py
python3 audio/v2/check_v2.py --determinism     # dodatkowo: ponowny render do katalogu tymczasowego i porównanie SHA-256
python3 audio/v2/synth_v2.py --seed 7 --out /tmp/x   # inny seed / katalog
```

Render trwa ok. 20 s (część 1: 7 s, część 2 `world.py`: 13 s), checker ok. 15 s (`--determinism` 30 s).
Wynik trafia do `audio/v2/out/`:
- `sfx/<event>/<material>_<n>.wav`: 464 pliki, 48 kHz, 16-bit PCM, mono (~9,6 MB);
- `ambience/<nazwa>.wav`: 4 pętle otoczenia, 30 s, **32 kHz**, 16-bit, mono, chunk `smpl` (~7,7 MB), część 2;
- `ui/<zdarzenie>_<n>.wav`: 34 diegetyczne dźwięki UI, 48 kHz / 16-bit / mono (~1,8 MB), część 2;
- `reward/<zdarzenie>_<n>.wav`: 9 nagród, 48 kHz / 16-bit / mono (~1,5 MB), część 2;
- `manifest.json`: per plik SHA-256, liczba próbek, czas, peak, onset_ms, rms_db (+ punkty pętli), tabela gainów;
  dla części 2 (`world_files`, `world_targets`) dodatkowo LUFS I / M_max / S_max i true peak;
- `demo_all.wav`: wszystkie zdarzenia × materiały (wariant 1) po kolei, przerwy 300 ms, pętle jako 1 s wycinki;
- `demo_world.wav`: UI i nagrody (wariant 1) po kolei, przerwy 400 ms (ambient słuchać z plików, w pętli);
- `ab_set_false_set.wav`: brass, na przemian set / false_set, warianty 1–6.

Razem ~27,4 MB (część 1: 14,8 MB). Pomiar głośności dowolnego pliku: `python3 audio/v2/loudness.py plik.wav`. Ten sam seed daje pliki identyczne co do bitu (sprawdzone `--determinism`; na innym CPU
lub w innej wersji numpy FFT może różnić się o 1 LSB, dlatego hashe w manifeście są per maszyna).

## Model (w skrócie)

Każdy dźwięk = **pobudzenie** ⊛ **bank tłumionych rezonatorów**.

- **Pobudzenie**: impuls siły kontaktu (połówka sinusa 0,05–2,5 ms; im węższy, tym jaśniejszy atak) +
  szum ziarna (żelazo, drewno) albo **tarcie**: pasmowy szum + ciąg impulsów stick-slip
  (skrzypienie, ślizg rdzenia, drapanie, pilnik).
- **Mody** (częstotliwość, τ, gain) zależą od **części**:
  pin/driver/spool (pręt swobodny: 1 : 2,756 : 5,404 : 8,933 + mod skrętny), sprężyna (22 gęste, krótkie mody
  1,5–6,5 kHz + modulacja „ocierania zwojów”), rdzeń/plug (1–3 kHz, dłuższe τ), wytrych (stal sprężynowa zawsze,
  wyżej i dłużej, glissando przy naprężeniu), dźwignia i zapadka warded (mody płyty podpartej), zapadka/pawl,
  koło zapadkowe, pierścień szyfrowy (mody pierścienia n(n²−1)/√(n²+1)), obudowa/drzwi, rygiel.
- **Materiał** (TECH §3.2) skaluje częstotliwości, τ, szerokość impulsu i ziarno:
  mosiądz (baza, 2–4 kHz, ciepły, 60–90 ms), stal (×1,95 → 5–8 kHz, impuls 0,11 ms = twardy atak, krótszy dzwon),
  żelazo (×0,52 → 1–2 kHz, krótkie τ, ziarnisty szum), drewno (×0,19 → 300–800 Hz, τ 5,5 ms, wyższe mody
  gasną najszybciej: „tok” bez dzwonienia).
- **Realizm**: na wariant losowe odstrojenie modów ±3% (+ globalnie ±2%), losowe miejsce uderzenia
  (zmienia gainy modów), losowa szerokość impulsu ±15%; wyższe mody gasną szybciej.
- **Post**: bardzo krótki, suchy klaster wczesnych odbić (1,3 / 2,1 / 3,4 / 4,7 ms, −22…−30 dB, bez ogona),
  łagodna półka wysokich (−1…−3 dB od 7 kHz), HP 25 Hz, usunięcie DC bez skoku na krawędziach,
  przycięcie ciszy z przodu i z tyłu, fade-out 3 ms, normalizacja do tabeli gainów.
- Wszystkie filtry są **przyczynowe** (IIR jako odpowiedź impulsowa przez FFT), więc nic nie „dzwoni” przed onsetem.
- Losowość: PCG64 z seedem CRC32(`seed:event:material:wariant`). Uwaga: stary `audio/tools/synth.py` seeduje
  przez `hash((event, material, v))`, a to w Pythonie 3 zmienia się co uruchomienie (PYTHONHASHSEED),
  więc tamten generator nie jest deterministyczny.

## Zdarzenia × materiały × warianty

| Zdarzenie | Materiały | Warianty | Czas [ms] | Peak [dBFS] | Opis |
|---|---|---|---|---|---|
| `contact` | brass, steel, iron, wood | 6 | 12–16 | −15 | cichy tik końcówki wytrycha o pin |
| `bind` | brass, steel, iron, wood | 6 | 22–30 | −10 | krótkie zacięcie: tarcie pinu o krawędź rdzenia |
| `near_shear` | brass, steel, iron, wood | 6 | 71–109 | −19 | bardzo subtelne pojaśnienie tarcia, bez kliknięcia |
| `set` | brass, steel, iron, wood | 6 | 63–83 | −5,5 | ostre kliknięcie + krótki ślizg rdzenia ~60 ms |
| `false_set` | brass, steel, iron, wood | 6 | 109–128 | −5,5 | ten sam klik + niski body (−4 półtony, +20 ms) + drugi cichy niski impuls po 28 ms + głębszy ślizg |
| `counter_rotate` | brass, steel, iron, wood | 6 | 100–119 | −7 | jednostka rytmu zapadki: klik + skrzyp (stick-slip 200→120 Hz) |
| `overset` | brass, steel, iron, wood | 6 | 32–38 | −6 | głuchy stuk, bez dzwonienia |
| `drop` | brass, steel, iron, wood | 6 | 151–266 | −7 | 3–6 uderzeń pinów co ~40 ms + grzechot sprężyn |
| `stress` | brass, steel, iron, wood | 6 | 324–477 | −8 | rosnące „śpiewanie” wytrycha (+4…8% pitch), tiki co ~70 ms |
| `break` | brass, steel, iron, wood | 6 | 140–176 | −1 | suchy trzask 40 ms + odbicia odłamka (~120 ms) |
| `wear` | brass, steel, iron, wood | 6 | 240–327 | −13 | cichy szlif / pilnik (menu, L4) |
| `gate_align` | brass, steel, iron, wood | 6 | 21–26 | −8 | miękki „tok” dźwigni/tarczy |
| `detector_trip` | brass, steel, iron, wood | 6 | 180–208 | −4 | podwójne „klak-klak” (drugi po ~140 ms) |
| `open` | brass, steel, iron, wood | 6 | 420–537 | −1 | obrót rdzenia + krzywka + przesuw i uderzenie rygla |
| `spring` ✚ | brass, steel | 6 | 44–60 | −11 | brzęczenie ściskanej sprężyny |
| `lever` ✚ | brass, steel, iron | 6 | 29–40 | −8 | uniesienie dźwigni (klik) |
| `lever_fall` ✚ | brass, steel, iron | 6 | 46–64 | −7 | opadnięcie dźwigni z małym odbiciem |
| `ratchet` ✚ | steel, brass, iron | 6 | 30–42 | −7 | klik zapadki (pawl) o ząb |
| `ring_detent` ✚ | brass, steel | 6 | 35–50 | −8 | zatrzask pierścienia szyfrowego |
| `ward_scrape` ✚ | brass, steel, iron | 6 | 161–245 | −10 | sonda drapiąca o zapadkę warded |
| `tension_resistance` (pętla) | brass, steel, iron, wood | 4 | 1123–1385 | RMS −18 | niski szum tarcia rdzenia |
| `pick_drag` (pętla) | brass, steel, iron, wood | 4 | 1137–1392 | RMS −18 | drapanie + mikrotiki krawędzi pinów |

✚ = nowe zdarzenia (dla sesji B). Proponowane mapowanie pod-zdarzeń lockcore:
`pin.serration` → `ratchet` (ząbki pinu) lub `spring`, `lever.false_gate` → `lever` / `lever_fall`,
`ring.detent` → `ring_detent`, `ward.scrape` → `ward_scrape`.

**Poziomy.** One-shoty nie mają jednego peaku: peak = −1 dBFS + `GAIN_DB[event]` (tabela w `synth_v2.py`,
także w manifeście). Głośność „LUFS-owa” (`rms_db`: maks. RMS w oknie 25 ms po HP 100 Hz) wychodzi w kolejności:
open −13,8, break −16,1, …, near_shear −28,5, contact −31,5 dBFS. Checker pilnuje, żeby break/open były w czwórce
najgłośniejszych, a contact/near_shear w trójce najcichszych. W grze nie trzeba więc już dokręcać względnych
poziomów; `volume_db` w `Sfx.play()` zostaje do miksu sytuacyjnego. Pętle mają RMS −18 dBFS (peak ≤ −1),
a gra skaluje je sama (`update_loop`).

## Reguła onsetu (opóźnienie)

Akustyczny początek każdego one-shota (pierwsza próbka ≥ −30 dB względem peaku) leży **≤ 2 ms (≤ 96 próbek)**
od początku pliku; w praktyce ≤ 0,21 ms. Ciszę z przodu tniemy przy −60 dB, a fade-in trwa 0,25 ms (≤ 0,3 ms).
Dlaczego: budżet dotyk → dźwięk/haptyka to p95 ≤ 25 ms (TECH, spike 1), a dźwięk i haptyka mają się zgadzać
w |Δ| ≤ 15 ms (§3.5). Każda milisekunda ciszy na początku pliku idzie prosto na opóźnienie, którego nie da się
skompensować. Dlatego też każde dłuższe zdarzenie (stress, wear, open, ward_scrape) zaczyna się od transjentu
kontaktu, a nie od narastania.

## Co sprawdza `check_v2.py` (exit ≠ 0 przy błędzie)

Format 48k/16/mono PCM; peak = cel ±0,5 dB; onset ≤ 96 próbek; pierwsza próbka nie jest skokiem;
brak clippingu; DC < −60 dBFS; koniec w ciszy; czas w oknie zdarzenia; 4–6 ciągłych wariantów na
zdarzenie × materiał; SHA-256 zgodne z manifestem. Pętle: chunk `smpl` (forward, 0…N−1), długość 1,0–1,5 s,
RMS −18 ±1,5 dB, szew bez kliku. Kryterium szwu: residuum predykcji 2. rzędu na zawinięciu ponad własny p99,9 sygnału
musi być < −40 dBFS (wynik: 0, czyli −200 dBFS). Krok na zawinięciu nie może też odstawać od kroków wewnątrz
pętli (najgorszy: p97). Surowy krok |x[0]−x[N−1]| (do −15,7 dBFS w `pick_drag`) to zwykła treść pasma 4–8 kHz,
taka sama jak między każdą parą sąsiednich próbek, a nie klik. Raportuje też głośność per zdarzenie
i rozróżnialność set/false_set.

## Set vs false_set (TECH §3.3–3.4)

Ta sama rodzina kliknięcia (te same części, peak, impuls tylko o 15% szerszy). Podpis false_set:
body rdzenia transponowane o −4 półtony z dłuższym ogonem, drugi cichy, niski impuls po 28 ms (±1,5 ms)
z ziarnem w paśmie średnim (żeby rytm „podwójnego” przeżył głośnik telefonu) i dłuższy, niższy ślizg (~6° luzu).
Pomiar (średnia z 6 wariantów; „telefon” = HP 500 Hz 2. rzędu + LP 9 kHz):

| Materiał | centroid set → false | energia po 25 ms set → false | telefon: Δcentroid / Δenergia po 25 ms |
|---|---|---|---|
| brass | 2393 → 1541 Hz (−36%) | −14,5 → −9,2 dB (+5,2) | −32% / +4,6 dB |
| steel | 4788 → 2653 Hz (−45%) | −18,1 → −10,3 dB (+7,8) | −39% / +7,0 dB |
| iron | 1181 → 717 Hz (−39%) | −20,1 → −9,2 dB (+10,9) | −32% / +9,8 dB |
| wood | 362 → 238 Hz (−34%) | −21,6 → −10,0 dB (+11,6) | +27% / +10,5 dB |

W drewnie na telefonie centroid false_set *rośnie* (niski body ginie, zostaje średnie ziarno drugiego impulsu),
więc rozróżnienie niesie wtedy rytm i ogon (+10,5 dB energii po 25 ms). Checker wymaga: centroid false_set
≤ 92% set, a energia po 25 ms ≥ +3 dB, także w symulacji telefonu.

## Jak podmienić w grze (sesja B)

1. Skopiować `audio/v2/out/sfx/*` do `game/assets/audio/sfx/` (nadpisze obecne 14 zdarzeń + 2 pętle, doda 6 nowych folderów).
2. `sfx.gd`: `VARIANTS` zostawić 4 albo podnieść do 6 (one-shoty mają 6 wariantów). **Pętle mają tylko 4**, więc
   przy 6 trzeba osobnej stałej dla `LOOPS` albo fallbacku (dziś `_stream_for` wraca do wariantu 1, czyli działa).
3. Dopisać do `EVENTS`: `&"spring", &"lever", &"lever_fall", &"ratchet", &"ring_detent", &"ward_scrape"`.
   Nie każde nowe zdarzenie ma wszystkie materiały (tabela wyżej). `_stream_for` zwraca wtedy `null`
   i dźwięk milknie, więc FeedbackDirector powinien mapować materiał na najbliższy istniejący
   (np. wood → brass dla `lever`).
4. Ustawienia importu (`.import` / preset dla folderu `sfx`): `compress/mode=0` (PCM), `edit/trim=false`,
   `edit/normalize=false`, `force/mono=false`, `force/8_bit=false`, `force/max_rate=false`.
   Trim/normalize Godota zepsułyby onset i tabelę poziomów.
5. Pętle `tension_resistance` i `pick_drag`: `edit/loop_mode` = Detect From WAV (pliki mają chunk `smpl`:
   forward, start 0, end N−1) albo Forward z `loop_begin=0`, `loop_end=-1` (koniec pliku).
   `begin_loop()` ustawia tylko `loop_mode`, nie `loop_end`, więc punkt końca musi przyjść z importu.
   Do sprawdzenia w edytorze: czy Godot traktuje `end` z `smpl` jako włączny (różnica 1 próbki, niesłyszalna).
6. ±3% pitch robi już `Sfx.play()`. Losowe ±1,5 dB (TECH §3.5) warto dodać w `play()`, bo pliki mają
   dokładne peaki.

## Lista odsłuchowa

- [ ] `ab_set_false_set.wav` na **głośniku telefonu, mono, 50% głośności**, bez patrzenia: osoba trzecia
  odtwarza losowo set albo false_set (warianty 1–6), słuchacz zgaduje. Cel: ≥ 80% trafień po 10 próbach
  (po krótkim „tutorialu” z A/B).
- [ ] To samo na słuchawkach i na głośniku iPada (tryb „tylko dźwięk”, §3.4).
- [ ] false_set na pierwszy kontakt brzmi „prawie jak set” (ma mylić), a nie jak zupełnie inny dźwięk.
- [ ] Materiały odróżnialne: brass ciepły, steel jasny i twardy, iron matowy z ziarnem, wood głuchy „tok” bez dzwonienia.
- [ ] Brak kliku na zawinięciu pętli (zapętlić w odtwarzaczu z loop points `smpl` na 30 s).
- [ ] Szybka seria `contact` / `bind` / `pick_drag` po 10 min nie męczy (brak ostrych sybilantów 6–9 kHz w steel).
- [ ] `drop`, `break`, `open` wyraźnie najgłośniejsze w kontekście; `near_shear` ledwo słyszalny (tak ma być).
- [ ] Losowanie wariantów nie daje efektu „karabinu maszynowego” (6 wariantów, ±3% pitch).
- [ ] Nic nie kojarzy się z alarmem, nagrodą typu „ding” ani z „estetyką włamania” (CLAUDE.md, ton).

---

# Część 2: otoczenie, UI diegetyczne, nagrody (`world.py`)

Ten sam warsztat co w części 1 (mody tłumione + tarcie/szum, numpy, zero sampli), ten sam seed i ten sam
sposób losowania (PCG64 z CRC32 `seed:world:nazwa:wariant`), więc `--determinism` obejmuje też te pliki.
Renderuje je to samo polecenie (`synth_v2.py` woła `world.render_world()`); osobno: `python3 audio/v2/world.py`.
Głośnościomierz: `loudness.py` (ITU-R BS.1770-4 / EBU R128 w numpy, bez pyloudnorm; filtr K wyprowadzony
z prototypu analogowego dla dowolnego SR, przy 48 kHz zgodny ze współczynnikami z normy, autotest:
sinus 1 kHz −20 dBFS = −23,0 LUFS; true peak przez 4× nadpróbkowanie FFT).

## Pętle otoczenia (`ambience/`, 30 s, 32 kHz)

| Plik | Co słychać | Zmierzone: I / M_max / S_max / TP |
|---|---|---|
| `stairwell` (klatka schodowa) | niski szum budynku (bez subbasu poniżej 45 Hz) + daleki ruch uliczny, 2 serie kroków po schodach (6–10 kroków, ~0,55 s, zbliżają się albo oddalają), daleko zamykane drzwi (1–2), wszystko przez pogłos klatki RT60 2,4 s z ciemnym ogonem | −35,0 / −30,4 / −32,4 LUFS / −17,6 dBTP |
| `workshop` (warsztat) | ciepły szum pomieszczenia, zegar ścienny tik-tak co 1 s (wychwyt stalowy + drewniana skrzynka), 4–5 razy odkładane narzędzie na drewniany blat (stal + blat + małe odbicie), mały pokój RT60 0,45 s | −35,0 / −33,1 / −33,7 / −19,7 |
| `night_timer` (noc z minutnikiem) | bardzo cichy pokój nocą, minutnik mechaniczny 4 tyk/s (tyk-tak lekko odstrojone), 2 dalekie przejazdy samochodu za oknem | −35,0 / −32,4 / −33,8 / −19,3 |
| `rain_window` (deszcz za oknem) | deszcz zza szyby (szum + gęste krople, obcięte wysokie przez szybę i ramę), wolne wahania natężenia, 2 serie kapania na blaszany parapet co 0,85–1,7 s, rzadkie stuknięcia kropli w szybę | −35,0 / −32,3 / −32,7 / −18,5 |

**Szew.** Każda warstwa jest okresowa w długości pętli: szum kształtowany w dziedzinie częstotliwości jednego
okresu, zdarzenia wstawiane modulo długość, pogłos przez splot kołowy (ogon zdarzenia sprzed końca pliku
gra na początku). Pętla jest więc bezszwowa z konstrukcji, także z pogłosem. 30 s to całkowita liczba sekund,
więc zegar 1 Hz i minutnik 4 Hz zachowują rytm na zawinięciu. Render w 48 kHz → 32 kHz przez obcięcie widma
(dla sygnału okresowego dokładne, idealny filtr antyaliasingowy 16 kHz), normalizacja do −35 LUFS I
(pomiar kołowy, tak jak słyszy gracz w pętli), dither TPDF ±1 LSB (z seeda).

Dlaczego 32 kHz: treść otoczenia leży poniżej ~12 kHz, a 4 × 30 s w 48 kHz to 11,5 MB zamiast 7,7 MB.
Godot przelicza częstotliwość sam. Pętle zdarzeń zamka zostają w 48 kHz.

## Diegetyczne UI (`ui/`, 48 kHz)

Każdy zaczyna się od transjentu kontaktu (onset ≤ 0,7 ms, limit 5 ms: to odpowiedź na dotyk).

| Zdarzenie | Warianty | Czas [s] | Opis |
|---|---|---|---|
| `tool_roll_open` | 3 | 0,65–0,73 | skórzana zwijka: dotyk, szelest skóry, 3 klapnięcia coraz większe, na końcu ledwo słyszalne stuknięcie narzędzi w środku |
| `tool_roll_close` | 3 | 0,52–0,58 | zwijanie: szybszy szelest, 2 klapnięcia, krótkie niskie skrzypnięcie zaciąganego paska |
| `paper_turn` | 3 | 0,41–0,45 | przewrócenie kartki: chwyt rogu, szum z włóknami, opadnięcie |
| `paper_slide` | 3 | 0,24–0,35 | przesunięcie kartki po blacie |
| `chalk_stroke` | 4 | 0,22–0,27 | kreska kredą: tarcie stick-slip z dużym jitterem (ziarno, nie pisk) przez mody tablicy + okruchy |
| `notebook_open` | 3 | 0,36–0,40 | dotyk okładki, krótki szelest kartek, tekturowe klapnięcie okładki |
| `notebook_close` | 3 | 0,16–0,19 | szelest + plaśnięcie zamykanej okładki |
| `pencil_tick` | 3 | 0,12–0,14 | ołówek: stuk w kartkę + dwie kreski „ptaszka” (krótka, dłuższa) |
| `job_phone` | 3 | 2,06–2,10 | telefon zleceń: dwa impulsy wibracji telefonu na drewnianym biurku (~170 Hz) + miękki dwudźwięk pałeczką (G4+D5, potem A4+E5); własny motyw, nie dzwonek żadnego producenta ani „ding-dong” |
| `drawer_open` | 3 | 0,54–0,68 | szuflada gabloty: palce na mosiężnym uchwycie, drewno po drewnie (stick-slip 55–90 Hz przez mody skrzynki), stuk o ogranicznik, cichutko zadrży szyba gabloty |
| `drawer_close` | 3 | 0,51–0,56 | jak wyżej, szybszy ślizg i mocniejszy stuk zamknięcia |

## Nagrody (`reward/`, 48 kHz)

| Zdarzenie | Warianty | Czas [s] | Opis |
|---|---|---|---|
| `door_open` | 3 | 1,85–2,12 | otwarcie drzwi: klamka i zapadka (mosiądz + sprężyna), zapadka wychodzi z zaczepu i rusza skrzydło (drewno 68–360 Hz), krótki, niski, „naoliwiony” zawias (żadnego horroru), miękki podmuch powietrza i oddech klatki, mały pogłos sieni |
| `thanks` | 3 | 2,51–2,67 | bezsłowne „dziękuję”: D-dur, szarpane „języczki” (mody belki wspornikowej) + miękka sztabka na D4; 3 wznoszące się dźwięki, krok w dół, łagodnie rozłożony akord rozwiązania. Wariant 1: A4–D5–F♯5–E5 → D-dur, 2: F♯4–A4–D5–C♯5 → D-dur, 3: A4–B4–D5–E5 → D-dur z F♯5 na górze |
| `coins` | 3 | 0,55–0,88 | 3–5 monet do drewnianej szkatułki: moneta (mody krążka 2,1–3,2 kHz) + blat, kolejne dzwonią o leżące, małe odbicia; wariant 2: ostatnia moneta „dokręca się” na rancie. Bez dzwonków, bez rosnących tonów, bez kaskady: nie kasyno |

---

# Miks: głośność, priorytety, ducking

Zgodne z `docs/FEEL.md` (§5.1: rozgrywka −23 LUFS integr., L2 peak ≤ −1 dBFS, L1 ≤ −20 dBFS krótkoterminowo,
ducking L1 −6 dB / 50 ms na każde L2; `break` duck reszty −12 dB / 300 ms; priorytety z JSON: 1 = najwyższy).
**Zasada: pliki części 2 są zmiksowane do poziomu docelowego.** Szyny UI, nagród i otoczenia grają je z 0 dB przy
suwakach na 100%; gra ich nie normalizuje (import: `edit/normalize=false`). Pętle zamka (`tension_resistance`,
`pick_drag`) gra skaluje sama (−24…−14 dBFS ∝ r, FEEL).

## Cele głośności (LUFS wg EBU R128; M = maks. momentary 400 ms, I = integrated, S = maks. short-term 3 s)

| Kategoria | Pomiar, cel | Sufity | Zmierzone (średnia [min…max]) |
|---|---|---|---|
| Zdarzenia zamka L2 — kotwica miksu | open/break: M −24 ±1,5; set/false_set: M −29 ±1,5 (wynika z tabeli peaków części 1) | sample peak ≤ −1 dBFS (FEEL) | open −23,3, break −24,5, set −28,9, false_set −29,1, drop −25,2, stress −20,9, contact −41,3 |
| Ciągłe L1 (pętle zamka) | plik: RMS −18 dBFS; w grze ≤ −20 dBFS short-term (FEEL) | peak ≤ −1 dBFS | plik I: tension_resistance −19,3, pick_drag −15,5 (przed skalowaniem w grze) |
| Nagrody | `door_open`, `coins`: M −25 ±1; `thanks`: I −27,5 ±1, M ≤ −24 | TP ≤ −3 dBTP; żadna nie głośniejsza niż open/break | M −25,0; thanks I −27,5, M −25,0…−24,4; TP max −9,2 |
| UI diegetyczne | M −32 ±1 (≥ 2 LU pod set) | TP ≤ −6 dBTP | M −32,0; TP max −9,4 |
| UI: `job_phone` | M −29 ±1 (≥ 3 LU pod open/break) | TP ≤ −6 dBTP | M −29,0; TP −18,5 |
| Otoczenie | I −35 ±1 (≥ 10 LU pod open/break) | S ≤ −31, M ≤ −30 (≥ 1 LU pod set), TP ≤ −12 dBTP | I −35,0; M −33,1…−30,4; S max −32,4; TP max −17,6 |

Krótkie dźwięki (< 400 ms) mierzymy M, bo integrated dla nich nie istnieje (energia liczona na tle 400 ms,
jak w R128: tik 30 ms ma niskie M). Przy suwakach 100% sesja z zamkiem (gęste set/bind/contact + opór)
powinna wypaść w okolicach −23 LUFS I z FEEL; zmierzyć na nagraniu z gry (sesja B), bo tu nie ma miksu.

**Odchylenie (do decyzji, nie zmieniam w tej sesji):** `break` ma sample peak −1,0 dBFS, ale **true peak do
+0,64 dBTP** (międzypróbkowe przekroczenie po DAC/resamplingu). Checker zgłasza to jako WARN, nie FAIL, bo zmiana
`GAIN_DB["break"]` zmieni pliki i hashe części 1, z których korzysta sesja B. Propozycja: `break` −1,5 dB
(peak −2,5 dBFS, TP ≈ −0,9 dBTP, M ≈ −26) albo limiter true-peak w `finish_oneshot` dla wszystkich zdarzeń.

## Priorytety (wyższy wygrywa, niższy jest ściszany, a nigdy odwrotnie)

1. **Zdarzenia zamka L2, prio 1–3** (`break`, `open`, `detector_trip`, `drop`): nigdy nie ściszane, nigdy nie
   odrzucane (essential), przerywają wszystko (`interrupt_priority_max` 3).
2. **Pozostałe L2** (prio 4–12: set, false_set, bind, contact…): nie ściszane przez nic poza `break`.
3. **Ciągłe L1** (`tension_resistance`, `pick_drag`): −6 dB / 50 ms na każde L2 (FEEL), po `break` −12 dB / 300 ms
   i rampa powrotu 300 ms.
4. **Nagrody**: grają dopiero po zamku. Kolejność po udanym zleceniu: `open` (zamek) → `door_open` od końca
   ogona `open` (≥ 450 ms od jego startu) → `thanks` 300 ms przed końcem `door_open` → `coins` przy ekranie zapłaty.
   Nigdy nad aktywnym zamkiem; jeśli w trakcie przyjdzie zdarzenie L2 (np. kolejny zamek w serii), nagroda dostaje
   −10 dB / 50 ms.
5. **UI diegetyczne**: nad aktywnym zamkiem (napięcie > 0 albo dotyk zamka < 1,5 s temu) −6 dB; `job_phone` w ogóle
   nie dzwoni nad aktywnym zamkiem, tylko czeka w kolejce, aż gracz odpuści (idle 1,5 s), potem maks. 3 cykle co
   1,5 s i dalej już tylko cicha ikona (nie męczy).
6. **Otoczenie**: zawsze na dole.

## Ducking (szyna → kogo ścisza)

| Wyzwalacz | Otoczenie | UI | L1 | Nagrody | Atak / trzymanie / powrót |
|---|---|---|---|---|---|
| tryb zamka (napięcie > 0 lub `pick_drag`) | −6 dB | −6 dB | — | — | 300 ms / do końca / 1,5 s |
| L2 prio ≥ 4 (set, bind, contact…) | bez zmian (już ≥ 10 LU niżej; ducking na każdy tik dałby „pompowanie”) | — | −6 dB | −10 dB | 5 ms / 50 ms / 60 ms |
| L2 prio 1–3 (`open`, `detector_trip`, `drop`) | −10 dB | −10 dB | −6 dB | — | 5 ms / długość zdarzenia / 400 ms |
| `break` | −12 dB | −12 dB | −12 dB | — | 5 ms / 300 ms / 300 ms (FEEL) |
| nagroda | −8 dB | −6 dB | — | — | 80 ms / długość / 1,0 s |
| `job_phone` | −4 dB | — | — | — | 100 ms / długość / 800 ms |

Ducking nie dotyczy haptyki (haptyka ma własne zasady w FEEL). Haptyka nigdy nie jest jedynym kanałem, więc
żadne ściszenie nie może zejść do zera: dolna granica dla otoczenia −18 dB łącznie.

**Głosy:** otoczenie 1 pętla naraz (przejście między pętlami: crossfade 1,5 s equal-power), UI maks. 4 głosy,
nagrody maks. 2, bez powtórzenia tego samego wariantu pod rząd, ±3% pitch i ±1,5 dB jak w zamku (FEEL §5.1;
nie dotyczy `thanks`, bo to motyw: pitch stały). **Suwaki gracza (propozycja):** Zamek / Otoczenie / Interfejs i
nagrody; Otoczenie domyślnie 100% = poziom pliku.

**Import w Godocie:** `ambience/*`: `edit/loop_mode` = Detect From WAV (chunk `smpl`, forward, 0…N−1),
kompresja QOA/Ogg dozwolona (opóźnienie nieistotne); `ui/*`, `reward/*`: bez pętli, `edit/trim=false`,
`edit/normalize=false`, kompresja dozwolona; pliki zamka zostają PCM (onset ≤ 2 ms).

## Co sprawdza checker dla części 2

`check_v2.py` (exit ≠ 0 przy błędzie; reguły części 1, w tym onset ≤ 2 ms zdarzeń zamka, bez zmian):
komplet plików i brak nadmiarowych; format (otoczenie 32 kHz, reszta 48 kHz, 16-bit mono PCM); SHA-256 z manifestem;
brak clippingu i DC; pętle: chunk `smpl`, długość 30–60 s, szew bez kliku (residuum 2. rzędu na zawinięciu
ponad p99,9 całego pliku < −40 dBFS **i** ponad p99,9 z ±100 ms wokół szwu < −50 dBFS, krok na zawinięciu ≤ p99,5,
skok poziomu po filtrze K 50 ms przed/po szwie ≤ 6 dB; wynik: −200 dBFS, czyli brak nadwyżki, skok ≤ 2,6 dB);
one-shoty: czas w oknie zdarzenia, onset ≤ 5 ms, pierwsza próbka nie jest skokiem, koniec w ciszy;
głośność: miara kategorii w tolerancji celu, sufity S/M, true peak; hierarchia miksu (nagrody ≤ open/break,
UI ≥ 2 LU pod set, telefon ≥ 3 LU pod open/break, otoczenie I ≥ 10 LU pod open/break i M ≥ 1 LU pod set).
Raportuje też M_max i true peak każdego zdarzenia zamka. Test negatywny (sprawdzony ręcznie na kopii `out/`):
ucięcie 37 albo 1000 próbek z pętli `workshop` / `night_timer`, +4 dB w pliku UI i 200 próbek ciszy przed `set`
dają FAIL. Ucięcie pętli deszczu (szeroki szum) nie daje mierzalnego kliku i checker go nie zgłasza; to zgodne
z uchem, ale znaczy, że szew pętli szumowej pilnuje konstrukcja, a nie checker.

## Lista odsłuchowa (część 2)

- [ ] Każda pętla otoczenia zapętlona 3× w odtwarzaczu z loop points `smpl`: brak kliku i „przeskoku” na szwie, nie
  słychać, że to 30 s (kroki i drzwi w klatce najłatwiej zapamiętać: jeśli przeszkadzają, rozrzedzić).
- [ ] Otoczenie na głośniku telefonu 50% pod sesją zamka: słychać, ale nie zasłania `contact` / `near_shear`.
- [ ] Minutnik w `night_timer` nie stresuje (lekki, w tle); zegar w `workshop` nie męczy po 5 min.
- [ ] `job_phone`: rozpoznawalny po dwóch cyklach, ciepły, nie kojarzy się z dzwonkiem do drzwi ani z żadnym
  znanym dzwonkiem; nie irytuje po 3 cyklach.
- [ ] `thanks`: ciepłe, krótkie, nie „wygrana w automacie”; 3 warianty brzmią jak ten sam „głos”.
- [ ] `coins`: kilka monet do drewna, nie jackpot; `door_open`: zawias spokojny, nie horror.
- [ ] Kreda bez pisku; papier i zeszyt nie syczą na głośniku telefonu (6–9 kHz).
- [ ] Nic nie kojarzy się z alarmem, kasynem, neonem ani „estetyką włamania” (CLAUDE.md, ton).
