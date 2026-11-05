# GEM1-v2 — raport poprawek zwiastuna Lockwright

**Data:** 2026-11-05  
**Repo:** https://github.com/woogitsugames/lockwright  
**Gałąź:** \`main\`  
**Podstawa:** \`docs/handoff/gemini/GEM1.md\`, \`docs/DECISIONS.md\` (D-49), \`docs/MARKETING.md\` §0–§4.

## Status wykonania

**Kod i napisy są zapisane na \`main\`. Finalne filmy 4K i 1080p nie są jeszcze wyrenderowane i nie zostały opublikowane w Release \`gemini-gem1-v2\`.**

Nie ma podstaw, by zgłaszać wykonanie finalnych renderów Cycles/OptiX. Sesja przygotowująca v2 nie ma dostępu do lokalnego Windows/RTX 5070 użytego w GEM1 ani zainstalowanego Blendera; udostępnione narzędzia GitHub potrafią zapisać tekst w repozytorium, ale nie umożliwiają przesyłania binarnych zasobów do Release.

| Wymaganie GEM1-v2 | Stan | Szczegóły |
|---|---|---|
| Usunięcie fałszywej informacji „Dostępne na Android · iOS” | **Kod wykonany** | \`build_trailers.py\` generuje tylko LOCKWRIGHT + „Pogotowie Zamkowe” / „Locksmith on Call”; naprawiono też cztery stare SRT |
| Narracja: klientka → notes → przekrój → otwarcie → uśmiech → plansza | **Skrypt wykonany, media do renderu** | \`build_trailers_v2.py\`, wolny Ken Burns z trzech zatwierdzonych JPG |
| Zastąpienie proceduralnych metali PBR | **Skrypt wykonany, render nieuruchomiony** | \`photo_materials_v2.py\`, załadowanie albedo/normal/roughness z \`art/textures/photo\` |
| Fotorealistyczny przekrój satynowy 128–256 spp OptiX | **Do renderu na RTX** | \`cutaway_anim.py\`, \`--require_photo 1\` i \`--samples 128\` lub \`256\` |
| Maksymalnie 40% ekstremalnych zbliżeń | **Weryfikacja timeline PASS** | 30 s: 105/900 kl. = **11,7%**; 15 s: 60/450 kl. = **13,3%**. R06 jest kadrem średnim, nie ekstremalnym |
| Cały przekrój z napinaczem i wytrychem w kadrze | **Ujęcie dodane, kompozycja do obejrzenia po renderze** | \`R04_V2_FULL\`; kamera 82 mm, szeroki dystans, pokazuje mechanizm i oba narzędzia |
| PL i EN, 30 s i 15 s, miękkie + wypalone napisy | **Kod i 4 SRT wykonane** | \`art/marketing/subtitles/v2/\` |
| Release \`gemini-gem1-v2\` | **Nieopublikowany** | Przygotowano \`publish_trailers_v2.py\` do weryfikacji i wysłania 24 MP4 przy dostępie do lokalnego \`gh\` |

## Pliki na \`main\`

- \`art/blender/marketing/build_trailers_v2.py\` — nowy storyboard, kadrowanie źródeł, Ken Burns, montaż FFmpeg, ponowne rozmieszczenie ścieżki audio, SRT, 1080p/4K.
- \`art/blender/marketing/photo_materials_v2.py\` — powiązanie PBR dla pięciu istniejących bibliotek metalu.
- \`art/blender/marketing/cutaway_anim.py\` — import PBR; preset \`R04_V2_FULL\`; wymuszenie kompletności map opcją \`--require_photo 1\`.
- \`art/blender/marketing/build_trailers.py\` — poprawka oryginalnej planszy R13.
- \`art/blender/marketing/publish_trailers_v2.py\` — weryfikator klatek i uploader do Release przez GitHub CLI.
- \`art/marketing/subtitles/v2/trailer_30s_pl.srt\`
- \`art/marketing/subtitles/v2/trailer_30s_en.srt\`
- \`art/marketing/subtitles/v2/trailer_15s_pl.srt\`
- \`art/marketing/subtitles/v2/trailer_15s_en.srt\`
- Zmieniono również cztery starsze pliki \`art/marketing/subtitles/trailer_{30s,15s}_{pl,en}.srt\` (usunięto obietnicę dostępności w sklepach).

## Storyboard 30 s / 900 klatek @30 FPS

| Czas | Źródło | Akcja |
|---|---|---|
| 00:00–00:02,5 | \`keyart_9x16.jpg\` | Klientka w otwartych drzwiach, powolny ruch kamery |
| 00:02,5–00:05 | \`keyart_1x1.jpg\` | Zbliżenie na notes ślusarza, symboliczne sprawdzenie |
| 00:05–00:07,5 | \`R04_V2_FULL\` | Pełny przekrój z wytrychem i napinaczem |
| 00:07,5–00:09,5 | \`R06\` | Odnajdywanie oporu na pinie |
| 00:09,5–00:11 | \`R07\` | Osadzenie pina, makro |
| 00:11–00:13 | \`R08\` | Fałszywe osadzenie szpulki, makro |
| 00:13–00:15 | \`R09\` | Kontrrotacja |
| 00:15–00:18 | \`R10\` | Trzy sekundy przygaszenia i słyszalnych kliknięć |
| 00:18–00:20 | \`R11\` | Obrót rdzenia, wycofanie rygla |
| 00:20–00:22 | \`R12\` | Drzwi otwierają się |
| 00:22–00:25 | \`keyart_16x9.jpg\` | Uśmiech klientki, ostatnie ujęcie fabularne |
| 00:25–00:30 | \`R13\` | Czysta emaliowana tabliczka: wyłącznie tytuł i podtytuł |

**Ograniczenie materiału źródłowego:** trzy key arty przedstawiają tę samą scenę, a klientka uśmiecha się już na oryginalnych zdjęciach. Montaż akcentuje ją w finale przez osobne kadrowanie; nie generuje nowej mimiki ani nie przedstawia realnego dokumentu tożsamości. To wizualna sugestia legalnej weryfikacji, nie pokazanie przeprowadzonej kontroli.

## Storyboard 15 s / 450 klatek @30 FPS

| Czas | Źródło |
|---|---|
| 00:00–00:02 | Klientka (\`keyart_9x16.jpg\`) |
| 00:02–00:04 | Notes (\`keyart_1x1.jpg\`) |
| 00:04–00:06 | Pełny przekrój (\`R04_V2_FULL\`) |
| 00:06–00:07 | Osadzenie pina (\`R07\`) |
| 00:07–00:08 | Szpulka (\`R08\`) |
| 00:08–00:10 | Zgaśnięcie światła (\`R10\`) |
| 00:10–00:11 | Otwarcie (\`R11\`) |
| 00:11–00:13 | Uśmiech klientki (\`keyart_16x9.jpg\`) |
| 00:13–00:15 | Tabliczka LOCKWRIGHT + podtytuł |

## Mapowanie PBR

| Materiał | Zastosowanie | Dolny próg roughness |
|---|---|---:|
| \`nickel_satin\` | korpus i przekrój niklowy | 0,26 |
| \`brass_turned\` | mosiężny rdzeń, półka, piny | 0,24 |
| \`brass_face_milled\` | powierzchnia frezowana, rygiel | 0,24 |
| \`steel_ground\` | piny stalowe, napinacz, krzywka | 0,26–0,28 |
| \`spring_steel_polished\` | sprężyny, wytrych | 0,22 |

Mapy normalne mają obniżoną siłę (0,15–0,28). Ustawienie \`--require_photo 1\` kończy proces błędem, gdy mapy są niekompletne — zamiast niejawnie wracać do starego, proceduralnego połysku. Stosowany jest istniejący w GEM1 backend GPU z priorytetem OptiX.

## Wyniki testów

- **PASS:** \`python -m py_compile\` skryptu \`build_trailers_v2.py\` w lokalnym kontenerze.
- **PASS:** walidacja długości i kolejności: 30 s = **900 klatek**, 15 s = **450 klatek**.
- **PASS:** udział ekstremalnych zbliżeń: **11,7%** i **13,3%**.
- **PASS:** testowy FFmpeg z syntetycznymi bitmapami zamiast właściwych renderów, 180×320, z przejściami Ken Burns i ponownym podziałem WAV; \`ffprobe\` potwierdził 900/450 klatek w obu językach.
- **Nieprzetestowane:** rzeczywiste Cycles/OptiX, czytelność map PBR w 4K, fizyczne kadrowanie szerokiego ujęcia, płynność oryginalnego audio S01 i końcowa jakość napisów w realnym renderze. Test syntetyczny korzystał z atrap funkcji renderowania tytułu i wypalania napisów — nie stanowi dowodu finalnego wyglądu tabliczki ani napisów.

## Jak dokończyć finalny render na komputerze z RTX 5070

Wykonać z katalogu głównego repozytorium, po aktualizacji \`main\`. Blender 4.2.9 LTS, FFmpeg i Python z \`numpy\`, \`Pillow\`.

**1. Siedem ujęć przekroju z fotografiami PBR (OptiX, 128 spp):**

\`\`\`bash
blender -b --factory-startup -P art/blender/marketing/cutaway_anim.py -- --batch_presets R04_V2_FULL,R06,R07,R08,R09,R10,R11 --res 2160x3840 --samples 128 --bit_depth 8 --require_photo 1 --out out/gem1-v2/frames
\`\`\`

Dla nieruchomych kadrów promocyjnych można ustawić \`--samples 256\`. Skontrolować pierwszy kadr \`R04_V2_FULL\` przed pełnym renderowaniem.

**2. Animacja drzwi i czysta tabliczka R13:**

\`\`\`bash
blender -b --factory-startup -P art/blender/marketing/stairwell_anim.py -- --preset R12 --still 0 --res 2160x3840 --samples 128 --bit_depth 8 --out out/gem1-v2/frames/R12
blender -b --factory-startup -P art/blender/marketing/stairwell_anim.py -- --preset R13 --still 1 --res 2160x3840 --samples 256 --bit_depth 8 --out out/gem1-v2/R13_blank.png
\`\`\`

**3. Wersje 1080p i 4K, 30 s i 15 s, PL/EN, bez muzyki i z muzyką:**

\`\`\`bash
python art/blender/marketing/build_trailers_v2.py --frames-root out/gem1-v2/frames --r13-still out/gem1-v2/R13_blank.png --out-dir out/gem1-v2/release/1080 --size 1080x1920 --music
python art/blender/marketing/build_trailers_v2.py --frames-root out/gem1-v2/frames --r13-still out/gem1-v2/R13_blank.png --out-dir out/gem1-v2/release/4k --size 2160x3840 --music
\`\`\`

Skrypt pobiera na potrzeby remiksu oryginalne pliki \`trailer_30s_diegetic.wav\` i \`trailer_30s_music.wav\` z istniejącego Release \`gemini-gem1\` (można je również podać przez \`--audio-dir\`). Nie używa starego \`R13.mp4\`, na którym znajduje się niedozwolony tekst o sklepach.

**4. Publikacja 24 MP4 do \`gemini-gem1-v2\`, po kontroli wizualnej i dźwiękowej:**

\`\`\`bash
python art/blender/marketing/publish_trailers_v2.py --root out/gem1-v2/release --dry-run
python art/blender/marketing/publish_trailers_v2.py --root out/gem1-v2/release
\`\`\`

Warunek: zainstalowany i zalogowany GitHub CLI \`gh\`. Wysyłane są po dwie długości × dwa języki × trzy warianty (z miękkimi napisami / wypalone napisy / wersja z muzyką) × dwie rozdzielczości. Publikator sprawdza każdy plik \`ffprobe\`; odrzuca brakujący albo o błędnej liczbie klatek.

## Odbiór końcowy — do wykonania na finalnych plikach

- Zweryfikować kadry z realnych JPG Magnific: klientka, notes, wyraźny uśmiech przed planszą.
- W \`R04_V2_FULL\` obejrzeć oba narzędzia jednocześnie, sprawdzić czy nie są ucięte przez ekran 9:16.
- Obejrzeć metal w 4K i w skali szarości — bez efektu chromu; szczególnie osadzenie pina i szpulkę.
- Odsłuchać montaż bez obrazu i obejrzeć bez dźwięku z wypalonymi napisami SDH.
- Potwierdzić tylko dwie linie na tabliczce: „LOCKWRIGHT” + podtytuł lokalizowany, bez ceny, terminów premiery, ikon sklepów.
- Sprawdzić rzeczywiste 30/15 s i wykonanie obydwu uploadów do nowego Release. Dopiero wtedy zmienić status na **ukończone**.
