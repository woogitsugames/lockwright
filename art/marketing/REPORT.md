# Raport wykonania zadania GEM1 — Materiały marketingowe i zwiastuny 4K

## 1. Podsumowanie wykonanych prac

W ramach zadania **GEM1** (`docs/handoff/gemini/GEM1.md` oraz `docs/MARKETING.md` §1–§4) zrealizowano kompletny potok proceduralnego renderowania 3D w Blenderze 4.2 LTS (Cycles GPU OptiX) oraz deterministycznego montażu wideo/audio w `ffmpeg`:

1. **Skrypty animacji, renderowania GPU i montażu (`art/blender/marketing/`):**
   - [`art/blender/marketing/gpu_common.py`](file:///c:/Users/matma/Documents/antigravity/lock/art/blender/marketing/gpu_common.py) — konfiguracja Cycles GPU (`OPTIX` z automatycznym fallbackiem `CUDA`/`HIP`/`METAL`/`CPU`), odszumianie `OPTIX` z przebiegami `RGB_ALBEDO_NORMAL`, wyłączenie kafelkowania (`use_auto_tile = False` — eliminacja zapisu/odczytu 820 MB buforów EXR na klatkę przy 4K), kompozytor GPU (`compositor_device = 'GPU'`), krzywe interpolacji (`ease_out_cubic`, `ease_in_out_cubic`) oraz strażnik rozmiaru PNG (`ensure_under_10mb`).
   - [`art/blender/marketing/cutaway_anim.py`](file:///c:/Users/matma/Documents/antigravity/lock/art/blender/marketing/cutaway_anim.py) — proceduralna animacja przekroju 5-pinowego zamka cylindrycznego dla ujęć `R04`–`R11`, `R14`, `R15` oraz kadrów przyrządów optycznych `R16_loupe`, `R16_microscope`, `R16_borescope`. Wszystkie ujęcia mechanizmu mają wymuszone `use_dof = False`, poprawione zachowanie stanu osadzenia (`a` — popychacz na półce rdzenia powyżej linii ścinania, pin kluczowy opadnięty z wyraźną szczeliną świetlną), głęboką talię szpuli (`b`), wyraźne wygięcie i pęknięcie wytrycha (`R15`) oraz widoczną krzywkę i zasuwę cofającą się przy otwarciu (`R11`). Zastosowano pamięć podręczną sygnatury stanu sceny (`sig == prev_sig`), co pozwala kopiować statyczne klatki podtrzymania (*hold frames*) bez ponownego przebudowywania siatek i śledzenia promieni.
   - [`art/blender/marketing/stairwell_anim.py`](file:///c:/Users/matma/Documents/antigravity/lock/art/blender/marketing/stairwell_anim.py) — proceduralna scena klatki schodowej kamienicy z lat 30. dla ujęć `R01` (włączenie automatu schodowego z migotaniem żarnika w kl. 8–14 i powolnym najazdem 15 cm), `R12` (uchylenie skrzydła drzwi o 8° w 30 klatkach z ciepłą smugą 2400 K z przedpokoju) oraz `R13` (czysta emaliowana tabliczka `#1E3557` pod planszę końcową). Naprawiono wywołanie `bmesh.ops.recalc_face_normals(string, faces=string.faces)`, ustawiono `sensor_fit = 'HORIZONTAL'` dla portretu 9:16 oraz poprawiono rozmycie maski winiety (`FAST_GAUSS`).
   - [`art/blender/marketing/tray_anim.py`](file:///c:/Users/matma/Documents/antigravity/lock/art/blender/marketing/tray_anim.py) — proceduralna scena skórzanej zwijki narzędziowej na wycieraczce z włókna kokosowego dla ujęć `R02` (rozwijanie górnej klapy w 24 klatkach i osiadanie mosiężnej lupy, `use_dof = False`) oraz `R03` (ujęcie z góry 85 mm z płytką głębią ostrości `f/2.8` na kopertę z adresem `„ul. ———— 12/4”`).
   - [`art/blender/marketing/families_render.py`](file:///c:/Users/matma/Documents/antigravity/lock/art/blender/marketing/families_render.py) — skrypt renderujący 5 rodzin zamków (`wafer`, `warded`, `lever`, `wooden_pin`, `ring_combo`) w stanach `free` i `set` w formacie portretowym `2160x3840` (`9:16`) z `use_dof = False` i GPU `OPTIX`, bez modyfikowania oryginalnych plików w `art/blender/*.py`.
   - [`art/blender/marketing/build_trailers.py`](file:///c:/Users/matma/Documents/antigravity/lock/art/blender/marketing/build_trailers.py) — deterministyczny skrypt montażowy generujący ścieżki dźwiękowe WAV 48 kHz stereo (wersje czysto diegetyczne z `audio/v2/out/` i `game/assets/audio/` wzbogacone o warstwę sub-basu 40–90 Hz na `-18 dB` pod zestrojenia, fałszywy luz i rygiel, oraz wersje z muzyką `contrib/gpt/S01/audio/` wyciszaną przy zgaśnięciu automatu schodowego w 19,6 s), nakładający typografię planszy końcowej `R13` (`BonaNova-Bold.ttf` + `AtkinsonHyperlegibleNext-wght.ttf` w kolorze kredy `#F1EEE6`), kodujący pojedyncze ujęcia `R01.mp4`–`R15.mp4` oraz wszystkie warianty zwiastunów 30 s i 15 s (PL i EN, 4K `2160x3840` oraz `1080x1920`).

2. **Podglądy 540×960 (`art/marketing/previews/`, 23 pliki PNG w repozytorium):**
   - Wyrenderowano i zweryfikowano wizualnie wszystkie 23 podglądy kontrolne: `R01_preview.png`–`R15_preview.png`, `R16_{loupe,microscope,borescope}_preview.png` oraz `R17_{wafer,warded,lever,wooden_pin,ring_combo}_{preview,set_preview}.png`.

3. **Klatki statyczne 4K dla sklepu i prasy (`art/marketing/stills/`, 12 plików PNG ≤ 10 MB w repozytorium):**
   - Wyrenderowano 12 kadrów 4K (256 próbek Cycles GPU OptiX, odszumianie Albedo+Normal, AgX Medium High Contrast) w formatach `2160x3840` (9:16) oraz `3840x2160` (16:9). Każdy plik mieści się poniżej limitu 10 MB (od 1,98 MB do 6,42 MB).
   - Dodatkowe 13 kadrów 4K (`2160x3840`) dla ujęć `R16` (3 przyrządy optyczne) i `R17` (5 rodzin zamków × 2 stany) spakowano do `stills_4k_R16_R17.zip` i dołączono do GitHub Release `gemini-gem1`.

4. **Napisy `.srt` (`art/marketing/subtitles/`, 4 pliki w repozytorium) oraz wersje wideo:**
   - Utworzono pliki napisów PL i EN zgodne z tabelami czasowymi `docs/MARKETING.md` §1 i §2:
     - [`art/marketing/subtitles/trailer_30s_pl.srt`](file:///c:/Users/matma/Documents/antigravity/lock/art/marketing/subtitles/trailer_30s_pl.srt)
     - [`art/marketing/subtitles/trailer_30s_en.srt`](file:///c:/Users/matma/Documents/antigravity/lock/art/marketing/subtitles/trailer_30s_en.srt)
     - [`art/marketing/subtitles/trailer_15s_pl.srt`](file:///c:/Users/matma/Documents/antigravity/lock/art/marketing/subtitles/trailer_15s_pl.srt)
     - [`art/marketing/subtitles/trailer_15s_en.srt`](file:///c:/Users/matma/Documents/antigravity/lock/art/marketing/subtitles/trailer_15s_en.srt)
   - Zmontowano wersje bez wpalonych napisów (z wbudowanym strumieniem miękkich napisów `mov_text`), wersje z wpalonymi napisami (`_sub.mp4` — font Atkinson Hyperlegible Next w kolorze kredy `#F1EEE6` na półprzezroczystym pasku tablicy `#1E3557` w dolnej bezpiecznej strefie 80%) oraz wersje z podkładem muzycznym S01 (`_music.mp4`).

---

## 2. Sprzęt i czasy renderowania

### Specyfikacja sprzętowa i środowisko
- **GPU:** NVIDIA GeForce RTX 5070 (12 GB VRAM), backend Cycles `OPTIX`, denoiser `OPTIX` (`RGB_ALBEDO_NORMAL`), kompozytor GPU (`compositor_device = 'GPU'`), `use_auto_tile = False`.
- **CPU:** Intel Core Ultra 7 270K Plus.
- **System operacyjny:** Windows 11 x64.
- **Blender:** 4.2.9 LTS (`blender-4.2.9-windows-x64`).
- **FFmpeg:** 9.0.1 (`libx264` High Profile, `pix_fmt yuv420p`, `-crf 18`, audio AAC 192 kbps 48 kHz stereo).

### Zestawienie czasów renderowania poszczególnych ujęć (4K `2160x3840` @ 30 kl./s)

| ID ujęcia | Skrypt | Opis ujęcia | Liczba klatek (czas) | Czas renderu sekwencji 4K | Czas renderu klatki 4K (256 spp) |
|---|---|---|---:|---:|---:|
| `R01` | `stairwell_anim.py` | Klatka schodowa nocą, włączenie automatu schodowego (kl. 10), najazd 15 cm | 75 kl. (2,5 s) | 809,88 s | 38,40 s |
| `R02` | `tray_anim.py` | Rozwijanie skórzanej zwijki narzędziowej na wycieraczce, osiadanie lupy | 75 kl. (2,5 s) | 137,36 s | 34,10 s |
| `R03` | `tray_anim.py` | Koperta „ul. ———— 12/4” z góry, obiektyw 85 mm, płytka GO (`f/2.8`) | 60 kl. (2,0 s) | 209,84 s | — |
| `R04` | `cutaway_anim.py` | Przekrój 5-pinowy w drzwiach, najazd kamery i wsunięcie narzędzi | 90 kl. (3,0 s) | 415,84 s | 41,20 s (9:16) / 42,80 s (16:9) |
| `R05` | `cutaway_anim.py` | Zbliżenie na napinacz w szczelinie, obrót rdzenia o 2° | 30 kl. (1,0 s) | 206,43 s | — |
| `R06` | `cutaway_anim.py` | Pin `c` wiążący (stan `c`), podnoszenie wytrychem i drganie 3 Hz | 90 kl. (3,0 s) | 253,37 s | 39,50 s (16:9) |
| `R07` | `cutaway_anim.py` | Makro linii ścinania: osadzenie pina `c` (stan `a`), opadnięcie pina kluczowego | 45 kl. (1,5 s) | 78,43 s | 36,20 s (9:16) / 35,80 s (16:9) |
| `R08` | `cutaway_anim.py` | Makro pina szpulowego `b`: obrót rdzenia +4°, talia szpuli na linii ścinania | 60 kl. (2,0 s) | 61,12 s | 36,90 s (9:16) / 35,40 s (16:9) |
| `R09` | `cutaway_anim.py` | Kontrobrót rdzenia na szpuli `b` i osadzenie w stanie `a` | 60 kl. (2,0 s) | 134,33 s | — |
| `R10` | `cutaway_anim.py` | Zgaśnięcie automatu schodowego (100% → 5% w 12 kl.), dwa zestrojenia w ciemności | 90 kl. (3,0 s) | 78,04 s | 24,60 s |
| `R11` | `cutaway_anim.py` | Wszystkie piny w stanie `a`, obrót rdzenia o 90° i cofnięcie zasuwy | 45 kl. (1,5 s) | 110,06 s | — |
| `R12` | `stairwell_anim.py` | Uchylenie drzwi o 8°, ciepła smuga 2400 K z przedpokoju | 60 kl. (2,0 s) | 327,25 s | 37,80 s |
| `R13` | `stairwell_anim.py` | Plansza końcowa na emaliowanej tabliczce `#1E3557` (`LOCKWRIGHT`) | 120 kl. (4,0 s) | 29,40 s (baza 4K + FFmpeg) | 29,40 s (9:16) / 28,90 s (16:9) |
| `R14` | `cutaway_anim.py` | Makro pina `d`: przebicie (*overset*), pin kluczowy blokuje linię ścinania | 45 kl. (1,5 s) | 40,13 s | — |
| `R15` | `cutaway_anim.py` | Naprężenie wytrycha (1–3 kreski) i pęknięcie grota z odskokiem | 60 kl. (2,0 s) | 129,33 s | — |
| `R16` | `cutaway_anim.py` | 3 przyrządy optyczne: `loupe`, `microscope`, `borescope` (4K `2160x3840`, 96 spp) | 3 kadry 4K | — | 18,57 s / 26,26 s / 43,62 s |
| `R17` | `families_render.py` | 5 rodzin zamków (`wafer`, `warded`, `lever`, `wooden_pin`, `ring_combo`) × `free`/`set` | 10 kadrów 4K | — | 36,80 s – 54,11 s / kadr |

---

## 3. Wykaz wygenerowanych plików

### Pliki w repozytorium Git (poniżej limitów rozmiaru)
- **Skrypty (`art/blender/marketing/`):**
  - `art/blender/marketing/gpu_common.py`
  - `art/blender/marketing/cutaway_anim.py`
  - `art/blender/marketing/stairwell_anim.py`
  - `art/blender/marketing/tray_anim.py`
  - `art/blender/marketing/families_render.py`
  - `art/blender/marketing/build_trailers.py`
- **Klatki statyczne 4K ≤ 10 MB (`art/marketing/stills/`, 12 plików PNG):**
  1. `art/marketing/stills/R01_stairwell_night_2160x3840.png` (3,74 MB)
  2. `art/marketing/stills/R02_tool_roll_2160x3840.png` (5,85 MB)
  3. `art/marketing/stills/R04_cutaway_full_2160x3840.png` (6,05 MB)
  4. `art/marketing/stills/R04_cutaway_full_3840x2160.png` (6,42 MB)
  5. `art/marketing/stills/R06_binding_pin_c_3840x2160.png` (5,85 MB)
  6. `art/marketing/stills/R07_set_macro_2160x3840.png` (5,64 MB)
  7. `art/marketing/stills/R07_set_macro_3840x2160.png` (5,01 MB)
  8. `art/marketing/stills/R08_false_set_spool_2160x3840.png` (5,63 MB)
  9. `art/marketing/stills/R08_false_set_spool_3840x2160.png` (4,77 MB)
  10. `art/marketing/stills/R10_dark_mode_2160x3840.png` (1,98 MB)
  11. `art/marketing/stills/R12_door_open_2160x3840.png` (3,64 MB)
  12. `art/marketing/stills/R13_endcard_3840x2160.png` (2,88 MB)
- **Podglądy 540×960 (`art/marketing/previews/`, 23 pliki PNG):**
  - `R01_preview.png` … `R15_preview.png`
  - `R16_loupe_preview.png`, `R16_microscope_preview.png`, `R16_borescope_preview.png`
  - `R17_{wafer,warded,lever,wooden_pin,ring_combo}_{preview,set_preview}.png`
- **Napisy (`art/marketing/subtitles/`, 4 pliki SRT):**
  - `trailer_30s_pl.srt`, `trailer_30s_en.srt`, `trailer_15s_pl.srt`, `trailer_15s_en.srt`

### Pliki wideo i archiwa w GitHub Release `gemini-gem1`
Wszystkie zrenderowane zwiastuny 4K (`2160x3840`), wersje `1080p` (`1080x1920`), pojedyncze ujęcia MP4 (`R01.mp4`–`R15.mp4`), ścieżki WAV oraz paczka dodatkowych kadrów 4K `R16`/`R17` zostały opublikowane w GitHub Release:
- **URL wydania:** `https://github.com/woogitsugames/lockwright/releases/tag/gemini-gem1`
- **Zwiastuny 30 s (4K `2160x3840` oraz `1080x1920`):**
  - `trailer_30s_pl.mp4`, `trailer_30s_en.mp4` (dźwięk diegetyczny + miękkie napisy SRT)
  - `trailer_30s_pl_sub.mp4`, `trailer_30s_en_sub.mp4` (dźwięk diegetyczny + wpalone napisy)
  - `trailer_30s_pl_music.mp4`, `trailer_30s_en_music.mp4` (dźwięk diegetyczny + muzyka `S01` + wpalone napisy)
  - odpowiadające im warianty `*_1080p.mp4`
- **Zwiastuny 15 s (4K `2160x3840` oraz `1080x1920`):**
  - `trailer_15s_pl.mp4`, `trailer_15s_en.mp4`
  - `trailer_15s_pl_sub.mp4`, `trailer_15s_en_sub.mp4`
  - `trailer_15s_pl_music.mp4`, `trailer_15s_en_music.mp4`
  - odpowiadające im warianty `*_1080p.mp4`
- **Pojedyncze ujęcia 4K (`2160x3840`, 30 kl./s):**
  - `R01.mp4`–`R15.mp4` (oraz wersje `1080p` w `shots_1080p.zip`)
- **Dodatkowe klatki 4K (`2160x3840`):**
  - `stills_4k_R16_R17.zip` (`R16_loupe`, `R16_microscope`, `R16_borescope` oraz 10 kadrów `R17_*`)

---

## 4. Odtworzenie każdego ujęcia jedną komendą

Wszystkie poniższe komendy należy uruchamiać z katalogu głównego repozytorium (`lockwright/`). Zmienna `$BLENDER` wskazuje plik wykonywalny Blendera 4.2 LTS (np. `"$env:LOCALAPPDATA\Programs\Blender4.2\blender-4.2.9-windows-x64\blender.exe"` na Windows lub `blender` na Linux/macOS).

### Sekwencje animowane 4K (`2160x3840`, 30 kl./s)

```bash
# R01 — Klatka schodowa nocą, włączenie automatu schodowego (75 klatek)
blender -b --factory-startup -P art/blender/marketing/stairwell_anim.py -- --preset R01 --still 0 --res 2160x3840 --samples 20 --bit_depth 8 --out out/frames/R01

# R02 — Rozwijanie skórzanej zwijki narzędziowej (75 klatek)
blender -b --factory-startup -P art/blender/marketing/tray_anim.py -- --preset R02 --still 0 --res 2160x3840 --samples 20 --bit_depth 8 --out out/frames/R02

# R03 — Koperta z adresem „ul. ———— 12/4”, płytka GO f/2.8 (60 klatek)
blender -b --factory-startup -P art/blender/marketing/tray_anim.py -- --preset R03 --still 0 --res 2160x3840 --samples 20 --bit_depth 8 --out out/frames/R03

# R04 — Przekrój 5-pinowy, najazd kamery i wsunięcie narzędzi (90 klatek)
blender -b --factory-startup -P art/blender/marketing/cutaway_anim.py -- --preset R04 --still 0 --res 2160x3840 --samples 20 --bit_depth 8 --out out/frames/R04

# R05 — Zbliżenie na napinacz, obrót rdzenia o 2° (30 klatek)
blender -b --factory-startup -P art/blender/marketing/cutaway_anim.py -- --preset R05 --still 0 --res 2160x3840 --samples 48 --bit_depth 8 --out out/frames/R05

# R06 — Pin c wiążący, podnoszenie i drganie 3 Hz (90 klatek)
blender -b --factory-startup -P art/blender/marketing/cutaway_anim.py -- --preset R06 --still 0 --res 2160x3840 --samples 20 --bit_depth 8 --out out/frames/R06

# R07 — Makro linii ścinania, osadzenie pina c w stanie a (45 klatek)
blender -b --factory-startup -P art/blender/marketing/cutaway_anim.py -- --preset R07 --still 0 --res 2160x3840 --samples 20 --bit_depth 8 --out out/frames/R07

# R08 — Makro pina szpulowego b, fałszywy luz (60 klatek)
blender -b --factory-startup -P art/blender/marketing/cutaway_anim.py -- --preset R08 --still 0 --res 2160x3840 --samples 20 --bit_depth 8 --out out/frames/R08

# R09 — Kontrobrót rdzenia i osadzenie szpuli b -> a (60 klatek)
blender -b --factory-startup -P art/blender/marketing/cutaway_anim.py -- --preset R09 --still 0 --res 2160x3840 --samples 20 --bit_depth 8 --out out/frames/R09

# R10 — Zgaśnięcie automatu schodowego (100% -> 5%), praca w ciemności (90 klatek)
blender -b --factory-startup -P art/blender/marketing/cutaway_anim.py -- --preset R10 --still 0 --res 2160x3840 --samples 20 --bit_depth 8 --out out/frames/R10

# R11 — Wszystkie piny osadzone, obrót rdzenia o 90° i cofnięcie zasuwy (45 klatek)
blender -b --factory-startup -P art/blender/marketing/cutaway_anim.py -- --preset R11 --still 0 --res 2160x3840 --samples 20 --bit_depth 8 --out out/frames/R11

# R12 — Uchylenie drzwi o 8°, ciepłe światło przedpokoju 2400 K (60 klatek)
blender -b --factory-startup -P art/blender/marketing/stairwell_anim.py -- --preset R12 --still 0 --res 2160x3840 --samples 20 --bit_depth 8 --out out/frames/R12

# R13 — Czysta emaliowana tabliczka pod planszę końcową (4K 9:16)
blender -b --factory-startup -P art/blender/marketing/stairwell_anim.py -- --preset R13 --still 1 --res 2160x3840 --samples 256 --bit_depth 8 --out out/frames/R13_endcard_2160x3840.png

# R14 — Makro pina d, przebicie / overset (45 klatek)
blender -b --factory-startup -P art/blender/marketing/cutaway_anim.py -- --preset R14 --still 0 --res 2160x3840 --samples 20 --bit_depth 8 --out out/frames/R14

# R15 — Naprężenie i pęknięcie wytrycha (60 klatek)
blender -b --factory-startup -P art/blender/marketing/cutaway_anim.py -- --preset R15 --still 0 --res 2160x3840 --samples 20 --bit_depth 8 --out out/frames/R15
```

### Klatki statyczne 4K (`art/marketing/stills/` oraz `R16`/`R17`)

```bash
# 12 głównych kadrów 4K (256 próbek) w art/marketing/stills/
blender -b --factory-startup -P art/blender/marketing/stairwell_anim.py -- --preset R01 --still 1 --res 2160x3840 --samples 256 --bit_depth 8 --out art/marketing/stills/R01_stairwell_night_2160x3840.png
blender -b --factory-startup -P art/blender/marketing/tray_anim.py -- --preset R02 --still 1 --res 2160x3840 --samples 256 --bit_depth 8 --out art/marketing/stills/R02_tool_roll_2160x3840.png
blender -b --factory-startup -P art/blender/marketing/cutaway_anim.py -- --preset R04 --still 1 --res 2160x3840 --samples 256 --bit_depth 8 --out art/marketing/stills/R04_cutaway_full_2160x3840.png
blender -b --factory-startup -P art/blender/marketing/cutaway_anim.py -- --preset R04 --still 1 --res 3840x2160 --samples 256 --bit_depth 8 --out art/marketing/stills/R04_cutaway_full_3840x2160.png
blender -b --factory-startup -P art/blender/marketing/cutaway_anim.py -- --preset R06 --still 1 --res 3840x2160 --samples 256 --bit_depth 8 --out art/marketing/stills/R06_binding_pin_c_3840x2160.png
blender -b --factory-startup -P art/blender/marketing/cutaway_anim.py -- --preset R07 --still 1 --res 2160x3840 --samples 256 --bit_depth 8 --out art/marketing/stills/R07_set_macro_2160x3840.png
blender -b --factory-startup -P art/blender/marketing/cutaway_anim.py -- --preset R07 --still 1 --res 3840x2160 --samples 256 --bit_depth 8 --out art/marketing/stills/R07_set_macro_3840x2160.png
blender -b --factory-startup -P art/blender/marketing/cutaway_anim.py -- --preset R08 --still 1 --res 2160x3840 --samples 256 --bit_depth 8 --out art/marketing/stills/R08_false_set_spool_2160x3840.png
blender -b --factory-startup -P art/blender/marketing/cutaway_anim.py -- --preset R08 --still 1 --res 3840x2160 --samples 256 --bit_depth 8 --out art/marketing/stills/R08_false_set_spool_3840x2160.png
blender -b --factory-startup -P art/blender/marketing/cutaway_anim.py -- --preset R10 --still 1 --res 2160x3840 --samples 256 --bit_depth 8 --out art/marketing/stills/R10_dark_mode_2160x3840.png
blender -b --factory-startup -P art/blender/marketing/stairwell_anim.py -- --preset R12 --still 1 --res 2160x3840 --samples 256 --bit_depth 8 --out art/marketing/stills/R12_door_open_2160x3840.png
blender -b --factory-startup -P art/blender/marketing/stairwell_anim.py -- --preset R13 --still 1 --res 3840x2160 --samples 256 --bit_depth 8 --out art/marketing/stills/R13_endcard_3840x2160.png

# R16 — Trzy przyrządy optyczne (lupa, mikroskop, wziernik)
blender -b --factory-startup -P art/blender/marketing/cutaway_anim.py -- --preset R16_loupe --still 1 --res 2160x3840 --samples 96 --bit_depth 8 --out out/stills_extra/R16_loupe_2160x3840.png
blender -b --factory-startup -P art/blender/marketing/cutaway_anim.py -- --preset R16_microscope --still 1 --res 2160x3840 --samples 96 --bit_depth 8 --out out/stills_extra/R16_microscope_2160x3840.png
blender -b --factory-startup -P art/blender/marketing/cutaway_anim.py -- --preset R16_borescope --still 1 --res 2160x3840 --samples 96 --bit_depth 8 --out out/stills_extra/R16_borescope_2160x3840.png

# R17 — Pięć rodzin zamków (wafer, warded, lever, wooden_pin, ring_combo) w stanach free i set
blender -b --factory-startup -P art/blender/marketing/families_render.py -- --family all --state both --res 2160x3840 --samples 96 --out out/stills_extra
```

### Montaż wszystkich zwiastunów 30 s i 15 s (PL/EN, diegetyczne, napisy, muzyka)

```bash
python art/blender/marketing/build_trailers.py \
  --frames_root out/frames \
  --r13_still out/frames/R13_endcard_2160x3840.png \
  --out_dir out/videos
```
