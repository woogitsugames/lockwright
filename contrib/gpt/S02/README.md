# S02 — Kamienica: tła i dźwięki foley

**Projekt:** Lockwright: Pogotowie Zamkowe / Lockwright: Locksmith on Call  
**Data:** 2026-11-05  
**Zakres:** `contrib/gpt/S02/` — bez zmian w pozostałych katalogach.

## Rezultat

- **44 oryginalne pliki WAV**: 39 efektów mono i 5 teł stereo po dokładnie 60 sekund; bez źródeł nagranych, cudzej muzyki, rozpoznawalnych słów lub marek.
- **Format:** 48 000 Hz, signed PCM 24-bit WAV; maksymalny plik: 17,28 MB (poniżej limitu 20 MB).
- **Foley:** 16 kroków (8 drewno + 8 lastryko), 6 sekwencji pukania (2 nieśmiałe, 2 stanowcze, 2 pilne/autorytatywne bez syren), 3 oryginalne dzwonki mieszkań, 2 kliknięcia włącznika minutnika, 2 pętle tykania, 2 wygaśnięcia światła, 5 zawiasów, 3 klamki.
- **Tła:** klatka w dzień, wieczorem, nocą; mokre podwórko; warsztat z zegarem i dalekim tramwajem. Zawierają metadane zapętlenia RIFF `smpl`, od próbki 0 do ostatniej.
- **Głośność:** wszystkie foley: peak −12 dBFS; tła: −18,00 LUFS I (EBU R128/BS.1770, obie ścieżki), nie występuje clipping PCM.
- **Onset:** najpóźniej 0,167 ms w foley przy progu −30 dB względem szczytu (limit zamówienia ≤ 5 ms).
- **Odbiór automatyczny:** `python validate.py` → 44/44 PASS (format, pętle, liczniki, LUFS, onset, szew, hash SHA-256, poziom szczytu).

## Metoda i pochodzenie

Dźwięki są **autorską syntezą proceduralną**, a nie nagraniami lub modelowymi klonami cudzych próbek. `synthesize.py` tworzy modalne rezonanse drewna/metalu/lastryko, impulsy uderzeń, tarcie *stick-slip*, przestrzenne wczesne odbicia i barwiony szum stochastyczny. Nie używa pakietów sampli, rozpoznawalnej muzyki, głosów ani komercyjnych nazw urządzeń. Używany jest deterministyczny generator NumPy PCG64 z seedem `20261105`; warianty mają odmienne proporcje i timingi, nie są tylko przestrojeniem jednego pliku.

Tła otrzymują 0,9-sekundową pętlę zachodzącą na siebie przed dodaniem zdarzeń modulo 60 s; dzięki temu ich koniec łączy się z początkiem bez dodatkowego kliku. Różnice na szwie mieszczą się w normalnej dynamice sąsiednich próbek (test p99,99). Foley dostają bardzo krótki fade-in (12 próbek), fade-out, usunięcie składowej stałej i normalizację peaku. Bębniące w stare drewno uderzenia i brzęk dzwonków są wymyślone, bez odniesień do rzeczywistych producentów.

Pies dzienny jest proceduralnym niskim dźwiękiem o szczekającej obwiedni. „Radio” to tylko przytłumiony za ścianą, nieregularny szum o charakterze mowy, **bez głosu, słów ani muzyki**. Tramwaj to model toczącego się, oddalonego pojazdu, bez sygnałów rozpoznawalnej firmy.

### Odtworzenie i test

```bash
python -m pip install -r requirements.txt
python synthesize.py  # wypełnia ./foley, ./ambience i manifest.json
python document.py    # odtwarza README.md i ASSETS.md
python validate.py    # weryfikacja, 44/44 PASS
```

Do integracji: nie ustawiać `edit/normalize` ani `edit/trim` w Godot (zniszczy poziomy i opóźnienia); wykrywanie loop z `smpl` albo ręcznie `loop_begin=0` i `loop_end=60s`. Dla tykania `timer_ticking_01/02` stosować pętle programu audio z plikiem WAV; nie są to 60-sekundowe tła.

**Ważny konflikt specyfikacji:** S02 wymaga teł `−18 LUFS`, natomiast `audio/v2/README.md` i `docs/FEEL.md` opisują domyślny miks otoczenia `−35 LUFS`. Surowy plik spełnia S02; przy wpięciu do istniejącej szyny ambience należy zastosować wstępną redukcję około **−17 dB**, skorygowaną odsłuchem, zachowując ducking `−6 dB` przy aktywnym zamku. Inaczej szum kamienicy zagłuszy mechanikę.

## Spis plików audio (PL / EN)

| Plik | Opis PL / EN | Czas |
|---|---|---:|
| `foley/step_wood_01.wav` | Krok po drewnianych schodach; wariant 1 / Step on wooden staircase; variation 1 | 0.71 s |
| `foley/step_wood_02.wav` | Krok po drewnianych schodach; wariant 2 / Step on wooden staircase; variation 2 | 0.64 s |
| `foley/step_wood_03.wav` | Krok po drewnianych schodach; wariant 3 / Step on wooden staircase; variation 3 | 0.66 s |
| `foley/step_wood_04.wav` | Krok po drewnianych schodach; wariant 4 / Step on wooden staircase; variation 4 | 0.72 s |
| `foley/step_wood_05.wav` | Krok po drewnianych schodach; wariant 5 / Step on wooden staircase; variation 5 | 0.73 s |
| `foley/step_wood_06.wav` | Krok po drewnianych schodach; wariant 6 / Step on wooden staircase; variation 6 | 0.52 s |
| `foley/step_wood_07.wav` | Krok po drewnianych schodach; wariant 7 / Step on wooden staircase; variation 7 | 0.53 s |
| `foley/step_wood_08.wav` | Krok po drewnianych schodach; wariant 8 / Step on wooden staircase; variation 8 | 0.66 s |
| `foley/step_terrazzo_01.wav` | Krok po lastryko; wariant 1 / Footstep on terrazzo; variation 1 | 0.59 s |
| `foley/step_terrazzo_02.wav` | Krok po lastryko; wariant 2 / Footstep on terrazzo; variation 2 | 0.66 s |
| `foley/step_terrazzo_03.wav` | Krok po lastryko; wariant 3 / Footstep on terrazzo; variation 3 | 0.76 s |
| `foley/step_terrazzo_04.wav` | Krok po lastryko; wariant 4 / Footstep on terrazzo; variation 4 | 0.58 s |
| `foley/step_terrazzo_05.wav` | Krok po lastryko; wariant 5 / Footstep on terrazzo; variation 5 | 0.64 s |
| `foley/step_terrazzo_06.wav` | Krok po lastryko; wariant 6 / Footstep on terrazzo; variation 6 | 0.62 s |
| `foley/step_terrazzo_07.wav` | Krok po lastryko; wariant 7 / Footstep on terrazzo; variation 7 | 0.76 s |
| `foley/step_terrazzo_08.wav` | Krok po lastryko; wariant 8 / Footstep on terrazzo; variation 8 | 0.59 s |
| `foley/door_knock_01.wav` | Stukanie do drzwi: nieśmiały; wariant 1 / Door knock: nieśmiały; variation 1 | 0.94 s |
| `foley/door_knock_02.wav` | Stukanie do drzwi: nieśmiały; wariant 2 / Door knock: nieśmiały; variation 2 | 0.93 s |
| `foley/door_knock_03.wav` | Stukanie do drzwi: stanowczy; wariant 3 / Door knock: stanowczy; variation 3 | 0.95 s |
| `foley/door_knock_04.wav` | Stukanie do drzwi: stanowczy; wariant 4 / Door knock: stanowczy; variation 4 | 0.97 s |
| `foley/door_knock_05.wav` | Stukanie do drzwi: pilny, autorytatywny (bez syren); wariant 5 / Door knock: pilny, autorytatywny (bez syren); variation 5 | 1.04 s |
| `foley/door_knock_06.wav` | Stukanie do drzwi: pilny, autorytatywny (bez syren); wariant 6 / Door knock: pilny, autorytatywny (bez syren); variation 6 | 1.05 s |
| `foley/apartment_bell_01.wav` | Wymyślony stary dzwonek mieszkania; wariant 1 / Original old-fashioned apartment bell; variation 1 | 1.55 s |
| `foley/apartment_bell_02.wav` | Wymyślony stary dzwonek mieszkania; wariant 2 / Original old-fashioned apartment bell; variation 2 | 2.04 s |
| `foley/apartment_bell_03.wav` | Wymyślony stary dzwonek mieszkania; wariant 3 / Original old-fashioned apartment bell; variation 3 | 1.43 s |
| `foley/timer_switch_01.wav` | Klik włącznika światła na minutnik; wariant 1 / Timed stair-light switch click; variation 1 | 0.37 s |
| `foley/timer_ticking_01.wav` | Tykanie starego minutnika; wariant 1 / Old staircase timer ticking; variation 1 | 8.00 s |
| `foley/light_bulb_off_01.wav` | Wygaśnięcie żarówki, z towarzyszącym lekkim trzaskiem wyłącznika; wariant 1 / Bulb goes out, subtle switch release; variation 1 | 0.46 s |
| `foley/timer_switch_02.wav` | Klik włącznika światła na minutnik; wariant 2 / Timed stair-light switch click; variation 2 | 0.37 s |
| `foley/timer_ticking_02.wav` | Tykanie starego minutnika; wariant 2 / Old staircase timer ticking; variation 2 | 8.00 s |
| `foley/light_bulb_off_02.wav` | Wygaśnięcie żarówki, z towarzyszącym lekkim trzaskiem wyłącznika; wariant 2 / Bulb goes out, subtle switch release; variation 2 | 0.46 s |
| `foley/door_hinge_01.wav` | Skrzypienie zawiasów otwieranych drzwi; wariant 1 / Opening door hinge squeak; variation 1 | 1.17 s |
| `foley/door_hinge_02.wav` | Skrzypienie zawiasów otwieranych drzwi; wariant 2 / Opening door hinge squeak; variation 2 | 1.34 s |
| `foley/door_hinge_03.wav` | Skrzypienie zawiasów otwieranych drzwi; wariant 3 / Opening door hinge squeak; variation 3 | 1.51 s |
| `foley/door_hinge_04.wav` | Skrzypienie zawiasów otwieranych drzwi; wariant 4 / Opening door hinge squeak; variation 4 | 1.68 s |
| `foley/door_hinge_05.wav` | Skrzypienie zawiasów otwieranych drzwi; wariant 5 / Opening door hinge squeak; variation 5 | 1.85 s |
| `foley/door_handle_01.wav` | Szczęk klamki i zapadki; wariant 1 / Door handle/latch clack; variation 1 | 0.53 s |
| `foley/door_handle_02.wav` | Szczęk klamki i zapadki; wariant 2 / Door handle/latch clack; variation 2 | 0.61 s |
| `foley/door_handle_03.wav` | Szczęk klamki i zapadki; wariant 3 / Door handle/latch clack; variation 3 | 0.69 s |
| `ambience/stairwell_day.wav` | Klatka schodowa w dzień: daleki pies, radio bez muzyki za ścianą / Daytime stairwell, distant dog and unintelligible wall-muffled radio noise | 60.00 s |
| `ambience/stairwell_evening.wav` | Klatka schodowa wieczorem: kroki, zamykanie drzwi / Evening stairwell, footsteps and distant door closing | 60.00 s |
| `ambience/stairwell_night.wav` | Klatka schodowa nocą: cisza budynku i kapanie / Night stairwell, building room tone and occasional drips | 60.00 s |
| `ambience/courtyard_rain.wav` | Podwórko podczas deszczu: szum deszczu i rynny / Rainy courtyard, rain wash and sparse gutter drips | 60.00 s |
| `ambience/workshop.wav` | Warsztat: zegar na ścianie i daleki przejazd tramwaju / Workshop, wall clock and distant tram pass | 60.00 s |

## Pozostałe pliki

- `synthesize.py` — deterministyczny generator dźwięków (wyłącznie wewnątrz S02).
- `document.py` — odtwarzanie spisu i rejestru praw do zasobów.
- `validate.py` — automatyczny test formatów, onsetów, poziomów i szwów.
- `manifest.json` — parametry każdego pliku, SHA-256, metoda, opis PL/EN.
- `ASSETS.md` — wpis dla każdego z 44 zasobów, licencja/warunki oraz specyfikacja generacji.
- `requirements.txt` — zależności wyłącznie do syntezy offline.
- `push_to_github.sh` — opcjonalne, bezpieczne wdrożenie wyłącznie katalogu S02 z lokalnego sklonowanego repozytorium; brak force-push.

## Nieukończone / decyzje do podjęcia

Brak nagrań z terenu i testu odsłuchowego na fizycznym telefonie. Synteza zawiasów, lastryko i dalekich odgłosów wymaga odsłuchu w rzeczywistej grze z aktywnym zamkiem, zwłaszcza przy słuchawkach i na głośniku telefonu. W razie potrzeby można wymienić wybrane zasoby na autorskie nagrania, z opisem ich pochodzenia i nowymi wpisami w `ASSETS.md`.

Po stronie zespołu integracyjnego: ustalić czy tła mają być celowo głośniejsze niż istniejąca biblioteka, czy ich pliki bazowe pozostają na −18 LUFS z tłumieniem na szynie, oraz zweryfikować ustawienia importu Godot 4.7. **Nie zmieniono** `audio/v2/`, `game/` ani żadnego kodu innych zespołów.
