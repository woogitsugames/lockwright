# Rejestr zasobów

Każdy plik graficzny, dźwiękowy i font w repo musi mieć tu wpis. Dozwolone: własne, CC0, fonty OFL.

| Plik | Typ | Źródło | Licencja | Link |
|---|---|---|---|---|
| mockups/fonts/Brygada1918-wght.ttf, Brygada1918-Italic-wght.ttf | font | Google Fonts repo | SIL OFL 1.1 (mockups/fonts/OFL-brygada1918.txt) | https://github.com/google/fonts/tree/main/ofl/brygada1918 |
| mockups/fonts/BonaNova-Regular.ttf, BonaNova-Bold.ttf | font | Google Fonts repo | SIL OFL 1.1 (mockups/fonts/OFL-bonanova.txt) | https://github.com/google/fonts/tree/main/ofl/bonanova |
| mockups/fonts/Fraunces-SOFT-WONK-opsz-wght.ttf | font | Google Fonts repo | SIL OFL 1.1 (mockups/fonts/OFL-fraunces.txt) | https://github.com/google/fonts/tree/main/ofl/fraunces |
| mockups/fonts/Bitter-wght.ttf | font | Google Fonts repo | SIL OFL 1.1 (mockups/fonts/OFL-bitter.txt) | https://github.com/google/fonts/tree/main/ofl/bitter |
| mockups/fonts/BigShouldersStencil-opsz-wght.ttf | font | Google Fonts repo | SIL OFL 1.1 (mockups/fonts/OFL-bigshouldersstencil.txt) | https://github.com/google/fonts/tree/main/ofl/bigshouldersstencil |
| mockups/fonts/Lato-Regular/Bold/Italic.ttf | font | Google Fonts repo | SIL OFL 1.1 (mockups/fonts/OFL-lato.txt) | https://github.com/google/fonts/tree/main/ofl/lato |
| mockups/fonts/AtkinsonHyperlegibleNext-wght.ttf | font | Google Fonts repo | SIL OFL 1.1 (mockups/fonts/OFL-atkinsonhyperlegiblenext.txt) | https://github.com/google/fonts/tree/main/ofl/atkinsonhyperlegiblenext |
| mockups/fonts/SourceSerif4-opsz-wght.ttf, SourceSerif4-Italic-opsz-wght.ttf | font | Google Fonts repo | SIL OFL 1.1 (mockups/fonts/OFL-sourceserif4.txt) | https://github.com/google/fonts/tree/main/ofl/sourceserif4 |
| mockups/**/*.html, *.svg (rysunki makiet) | grafika | własne (Claude, rysowane w SVG/Canvas) | własne projektu | — |
| game/icon.svg | grafika (tymczasowa ikona) | własne (narysowane SVG) | własne projektu | — |
| game/assets/audio/sfx/**/*.wav (256 plików: 14 zdarzeń + 2 pętle × 4 materiały × 4 warianty, 48 kHz 16-bit mono) | dźwięk | własne, wygenerowane przez `audio/tools/synth.py` (synteza modalna + szum filtrowany) | własne projektu | — |
| audio/demo/all_events.wav | dźwięk (demo) | własne, `audio/tools/preview.py` | własne projektu | — |
| store/screenshots/out/**/*.png (makiety zrzutów sklepu, 256 kolorów) | grafika | własne: kadry z `art/renders/` + podpis fontem Bona Nova / Atkinson Hyperlegible Next (OFL, wpisy wyżej), `store/screenshots/make_screens.py` | własne projektu | — |
| Oboe 1.9.3 (google/oboe, pobierany przez CMake FetchContent w `spikes/audio-latency/plugin-android`, linkowany statycznie) | biblioteka C++ (audio) | https://github.com/google/oboe | Apache 2.0 | https://github.com/google/oboe/blob/main/LICENSE |
| spikes/audio-latency/samples/*.wav (8 kliknięć: set, false_set, break, contact × mosiądz/stal + impuls pomiarowy, 48 kHz 16-bit mono) | dźwięk | własne, synteza modalna `spikes/audio-latency/tools/synth_clicks.py` | własne projektu | — |
| spikes/haptics-latency/godot/icon.png (ikona aplikacji testowej) | grafika | własne, narysowane skryptem Pillow (prostokąty) | własne projektu | — |
| spikes/lit-metal/assets/interior.hdr (HDRI otoczenia; konwersja EXR→HDR) | grafika (HDRI) | `datafiles/studiolights/world/interior.exr` dołączony do Blendera 4.2 (to samo HDRI, którego używa `art/blender/cutaway.py`) | CC0 — sprawdzone 2026-11-05 w `blender-4.2.9/4.2/datafiles/studiolights/world/license.txt`: „All HDRIs are licenses as CC0. These were created by Greg Zaal (Poly Haven)” | https://polyhaven.com/license |
| spikes/lit-metal/assets/tex/*.png, cutaway*.glb, plate/*.png, screens/*.png | grafika (wypieki, rendery) | własne: wypiek i rendery sceny `art/blender/cutaway.py` skryptami `spikes/lit-metal/tools/` | własne projektu | — |
| art/blender/wafer.py, lever.py, warded.py, wooden_pin.py, ring_combo.py, tray.py, lw_common.py (sekcje v2 i v3: proceduralny dąb `oak()`) | skrypty look-dev (proceduralne modele i materiały) | własne (Claude) | własne projektu | — |
| art/renders/wafer.png, lever.png, warded.png, wooden_pin.png, ring_combo.png | grafika (render Cycles) | własne, wygenerowane skryptami z `art/blender/` | własne projektu | — |
| HDRI `interior.exr` (używane w renderach, nie w repo) | oświetlenie | Blender 4.2 datafiles/studiolights/world (Greg Zaal, Poly Haven) | CC0 | https://polyhaven.com |
| cyfry w ring_combo.py: mockups/fonts/Lato-Bold.ttf | font | jak wyżej (Lato) | SIL OFL 1.1 | — |
| game/addons/gut/fonts/* (AnonymousPro, CourierPrime, LobsterTwo) | font | GUT v9.7.1 (bitwes/Gut) | SIL OFL 1.1 | https://github.com/bitwes/Gut/tree/master/addons/gut/fonts  Uwaga: `game/addons/gut/fonts/OFL.txt` zawiera tylko notę copyright Anonymous Pro; brak not dla Courier Prime i Lobster Two (COMPLIANCE-AUDIT C-05). Poza eksportem (`exclude_filter`). |
| game/addons/lockcore_gd/** | kod (GDExtension) | własny + godot-cpp (master, API 4.7) | MIT | https://github.com/godotengine/godot-cpp |
| spikes/measure/android/app/fonts/BonaNova-Bold.ttf, AtkinsonHyperlegibleNext-wght.ttf (kopie z `mockups/fonts/`) | font | Google Fonts repo (wpisy wyżej) | SIL OFL 1.1 (licencje obok plików) | — |
| spikes/measure/screens/*.png, spikes/measure/android/app/icon.png | grafika | własne (zrzuty aplikacji pomiarowej, ikona z `spikes/haptics-latency`) | własne projektu | — |
| game/assets/ui/tray.jpg, section.jpg, loupe.jpg | grafika (tła HUD) | skopiowane z `mockups/realizm/img/` (własne sesji projektowej) | własne projektu | — |
| audio/v2/out/sfx/** (464 WAV, 48 kHz / 16-bit / mono: 14 zdarzeń gry × 4 materiały × 6 wariantów, 6 nowych zdarzeń, 2 pętle × 4 materiały × 4 warianty) oraz audio/v2/out/demo_all.wav, ab_set_false_set.wav (odsłuch, nie do builda) | dźwięk | własne, synteza modalna `audio/v2/synth_v2.py` (numpy, seed 20261105), bez sampli zewnętrznych | własne projektu | — |
| art/renders/section.png, section.jpg, section_v1.png, section_v2.png, tray.png, loupe.png | grafika (render Cycles: przekrój, tacka narzędzi, lupa) | własne, skrypty `art/blender/` (cutaway, tray, optics), jedyne obce dane: HDRI Blendera (CC0, wpis wyżej) | własne projektu | — |
| mockups/realizm/img/section.jpg, tray.jpg, loupe.jpg | grafika (JPG z renderów `art/renders/`) | własne | własne projektu | — |
| mockups/<kierunek>/png/*.png, mockups/compare/contact.png | grafika (zrzuty makiet: kolor, skala szarości, 50% jasności; zestawienie) | własne, `mockups/tools/render.mjs`, `contact.mjs` (Playwright) | własne projektu | — |
| game/assets/photoreal/cutaway_baked.glb, tex/*_normal.png, tex/*_orm.png, matcap/*.png, plate/plate_1236x1650.png | grafika 3D (model, wypieki, matcapy, plansza tła) | własne: scena `art/blender/cutaway.py`, wypiek jak w `spikes/lit-metal/tools/`, plansza `game/assets/photoreal/tools/render_plate.py` | własne projektu | — |
| game/scenes/photoreal/shots/*.png | grafika (zrzuty kontrolne ekranu fotoreal) | własne, zrzuty z gry | własne projektu | — |
| docs/handoff/img/a11y_portrait.png, a11y_landscape.png | grafika (zrzuty do audytu dostępności) | własne, zrzuty z gry | własne projektu | — |
| store/screenshots/contact_pl.png, contact_en.png | grafika (zestawienie zrzutów sklepu) | własne, `store/screenshots/make_screens.py` | własne projektu | — |
| game/addons/gut/images/*, gui/*.png, gui/*.tres, icon.png | grafika (ikony edytora GUT) | GUT v9.7.1 (bitwes/Gut), tylko edytor, poza eksportem | MIT (`game/addons/gut/LICENSE.md`) | https://github.com/bitwes/Gut |
| art/blender/optics.py, art/blender/cutaway.py (ujęcia `microscope`, `borescope`) | skrypty look-dev (wymyślony mikroskop warsztatowy i wziernik, widoki przez optykę) | własne (Claude) | własne projektu | — |
| art/renders/microscope.png, borescope.png, microscope_view.png, borescope_view.png | grafika (render Cycles) | własne, wygenerowane skryptami z `art/blender/` | własne projektu | — |
| mockups/realizm/img/microscope.jpg, borescope.jpg, microscope_view.jpg, borescope_view.jpg | grafika (JPEG z renderów powyżej) | własne | własne projektu | — |
| game/assets/photoreal/cutaway_baked.glb, tex/*_normal.png, tex/*_orm.png, matcap/*.png, scene.json | model 3D, wypieki, matcapy | własne: kopia wypieku spike'u 4 (`spikes/lit-metal/tools/bake.py`, `render_refs.py --what matcap`) ze sceny `art/blender/cutaway.py` | własne projektu | — |
| game/assets/photoreal/plate/plate_1236x1650.png | grafika (render Cycles, płyta planu B bez ruchomych części) | własne, `game/assets/photoreal/tools/render_plate.py` (scena `art/blender/cutaway.py`, HDRI `interior` — wpis wyżej) | własne projektu | — |
| game/assets/photoreal/tray/tray_full.png, tray_empty.png | grafika (render Cycles zwijki, `--lost 0` / `--lost 3`, 1080×960) | własne, `art/blender/tray.py` | własne projektu | — |
| game/scenes/photoreal/shots/*.png | zrzuty ekranu gry (lavapipe) | własne | własne projektu | — |
| art/blender/stairwell.py, workshop.py, env_common.py | skrypty look-dev (proceduralne sceny otoczenia: klatka schodowa, warsztat; materiały środowiskowe) | własne (Claude) | własne projektu | — |
| art/renders/stairwell.png, stairwell_night.png, workshop.png (+ `.json` z rzutem kotwic) | grafika (render Cycles) | własne, wygenerowane skryptami z `art/blender/` | własne projektu | — |
| mockups/realizm/img/stairwell.jpg, stairwell_night.jpg, workshop.jpg (+ `.json`) | grafika (JPG z renderów powyżej) | własne | własne projektu | — |
| numer na tabliczce w stairwell.py: mockups/fonts/BonaNova-Bold.ttf | font | jak wyżej (Bona Nova) | SIL OFL 1.1 | — |
| game/assets/ui/stairwell.jpg, workshop.jpg, microscope.jpg, microscope_view.jpg, borescope.jpg, borescope_view.jpg | grafika | skopiowane z `mockups/realizm/img/` (własne sesji projektowej) | własne projektu | — |
| site/public/img/*.jpg | grafika (pochodna) | własne: przeskalowane kopie `art/renders/*` i `mockups/realizm/png/*.portrait.png` (site/build.py) | jak źródła (własne) | — |
| site/public/fonts/BonaNova-*.ttf, AtkinsonHyperlegibleNext-wght.ttf | font (kopia) | kopie z `mockups/fonts/` | SIL OFL 1.1 (licencje skopiowane obok: OFL-bonanova.txt, OFL-atkinsonhyperlegiblenext.txt) | jak wyżej |
| audio/v2/out/ambience/*.wav (4 pętle otoczenia: stairwell, workshop, night_timer, rain_window; 30 s, 32 kHz / 16-bit / mono, chunk `smpl`) | dźwięk | własne, synteza `audio/v2/world.py` (numpy, seed 20261105: szum kształtowany, mody, pogłos syntetyczny), bez sampli zewnętrznych | własne projektu | — |
| audio/v2/out/ui/*.wav (34 diegetyczne dźwięki UI: zwijka skórzana, kartka, kreda, zeszyt, ołówek, telefon zleceń, szuflada gabloty; 48 kHz / 16-bit / mono) | dźwięk | własne, synteza modalna `audio/v2/world.py` (numpy, seed 20261105), bez sampli zewnętrznych; motyw telefonu własny (nie dzwonek producenta) | własne projektu | — |
| audio/v2/out/reward/*.wav (9 nagród: otwarcie drzwi, motyw „dziękuję”, monety; 48 kHz / 16-bit / mono) oraz audio/v2/out/demo_world.wav (odsłuch, nie do builda) | dźwięk | własne, synteza modalna `audio/v2/world.py` (numpy, seed 20261105), bez sampli zewnętrznych; motyw „dziękuję” własny | własne projektu | — |
| game/assets/audio/ambience/*.wav, game/assets/audio/ui/*.wav, game/assets/audio/reward/*.wav | dźwięk (kopie do builda) | kopie z `audio/v2/out/` (wiersze powyżej: synteza `world.py`) | własne projektu | — |


## Dostawy ChatGPT przyjęte do gry (D-42, D-43)
| Zasób | Ścieżka | Źródło / narzędzie | Prompt i warunki |
|---|---|---|---|
| Emaliowane tabliczki (36 PNG z alfą) | `contrib/gpt/G01/` | ChatGPT Image Generator + obróbka Pillow (`generate.py`) | `contrib/gpt/G01/ASSETS.md` |
| Kadry przyjazdu (10 × 1080×2340) | `contrib/gpt/G07/images/` | ChatGPT Image Generator, kadrowanie Pillow | `contrib/gpt/G07/ASSETS.md` |
| Kadry warsztatu (11) | `contrib/gpt/G08/images/` | ChatGPT Image Generator, kadrowanie Pillow | `contrib/gpt/G08/ASSETS.md` |
| Zeszyt mistrza (strony SVG/JPG) | `contrib/gpt/G10/` | rysowane kodem (SVG) | `contrib/gpt/G10/ASSETS.md` |
| Zeszyt mistrza v2 (strony 1600×2200) | `contrib/gpt/G10/v2/pages/` | faktury: ChatGPT Image Generator; treść: v1 SVG + font Caveat (OFL, `contrib/gpt/G10/v2/fonts/OFL.txt`), kompozycja sesji A | `contrib/gpt/G10/v2/README.md` |
| game/assets/ui/gpt/arrival/*.jpg (10 teł przyjazdu, G07) | grafika | ChatGPT (generowane AI), skopiowane z `contrib/gpt/G07/images/` (prompty i pochodzenie w `contrib/gpt/G07/ASSETS.md`, decyzja D-43) | generowane AI, projekt | https://github.com/woogitsugames/lockwright/tree/main/contrib/gpt/G07 |
| game/assets/ui/gpt/plates/*.png (24 numery mieszkań + 12 tabliczek pomieszczeń PL/EN, G01) | grafika (PNG z alfą) | ChatGPT (generowane AI), z `contrib/gpt/G01/` (z `contrib/gpt/G01/ASSETS.md`, D-43) | generowane AI, projekt | https://github.com/woogitsugames/lockwright/tree/main/contrib/gpt/G01 |
| game/assets/ui/gpt/workshop/*.webp (11 teł warsztatu wg pory dnia, G08) | grafika (WebP ≤ 1 MB) | ChatGPT (generowane AI), z `contrib/gpt/G08/images/` (D-43) | generowane AI, projekt | https://github.com/woogitsugames/lockwright/tree/main/contrib/gpt/G08 |
| game/assets/ui/gpt/cast/*/{avatar.png,portrait.jpg} (12 postaci z `docs/CLIENTS.md`, G09) | grafika (PNG z alfą / JPG) | ChatGPT (generowane AI), z `contrib/gpt/G09/characters/` + `cast.json` (D-43) | generowane AI, projekt | https://github.com/woogitsugames/lockwright/tree/main/contrib/gpt/G09 |
| game/assets/ui/gpt/tutorial/g11-*.png (36 kartek S1–S3: PL/EN/clean) i stamp-*.png (pieczątki, G11) | grafika (PNG z alfą) | wygenerowane programowo (skrypt `contrib/gpt/G11/generate_cards.py`, bez generatora obrazów), D-43 | własne projektu | https://github.com/woogitsugames/lockwright/tree/main/contrib/gpt/G11 |
| game/assets/ui/gpt/verify/*.webp (14 rekwizytów weryfikacji i pokwitowanie PL/EN, G14; PNG > 1 MB skonwertowane do WebP z alfą) | grafika (WebP ≤ 1 MB z alfą) | ChatGPT (generowane AI), z `contrib/gpt/G14/png/` (D-43) | generowane AI, projekt | https://github.com/woogitsugames/lockwright/tree/main/contrib/gpt/G14 |
| game/assets/ui/gpt/map/*.png|webp (mapa dzielnicy + znaczniki rozdziałów, G15; rozdziały 4–6 jako WebP ≤ 1 MB) | grafika | ChatGPT (generowane AI), z `contrib/gpt/G15/maps|overlays/` (D-43) | generowane AI, projekt | https://github.com/woogitsugames/lockwright/tree/main/contrib/gpt/G15 |
| game/assets/ui/gpt/showcase/*.jpg (20 zdjęć eksponatów, G16) + exhibit_card_blank_pl_en.png | grafika (JPG ≤ 1 MB) | ChatGPT (generowane AI), z `contrib/gpt/G16/photos|props/` + `manifest.json` (D-43) | generowane AI, projekt | https://github.com/woogitsugames/lockwright/tree/main/contrib/gpt/G16 |
| game/assets/ui/gpt/notebook/*.jpg (15 stron zeszytu v2, G10) | grafika (JPG ≤ 1 MB) | faktury: ChatGPT (generowane AI), treść: SVG v1 + font Caveat (OFL), z `contrib/gpt/G10/v2/pages/` (D-43) | generowane AI + własne, projekt | https://github.com/woogitsugames/lockwright/tree/main/contrib/gpt/G10/v2 |
| game/assets/audio/music/*.ogg (9 utworów S01: main_theme, menu_workshop, lock_harmony, 6 jingli) | dźwięk (muzyka) | ChatGPT (generowane AI), z `contrib/gpt/S01/audio/` (MIDI + render, `contrib/gpt/S01/ASSETS.md`, D-43); na magistrali Music ściszone (S01 było −16 LUFS I) | generowane AI, projekt | https://github.com/woogitsugames/lockwright/tree/main/contrib/gpt/S01 |
| game/assets/audio/foley/*.wav (39 dźwięków S02: kroki, pukanie, dzwonek, minutnik, …) | dźwięk (foley) | własna synteza skryptem dostawcy, `contrib/gpt/S02/foley/` (`manifest.json`, D-43) | własne projektu (synteza), projekt | https://github.com/woogitsugames/lockwright/tree/main/contrib/gpt/S02 |
| game/assets/audio/voices/*/*.wav (96 bezsłownych głosów S03, znormalizowane do −28 LUFS M przy imporcie) | dźwięk (głosy) | ChatGPT (generowane AI), z `contrib/gpt/S03/voices/` (`contrib/gpt/S03/ASSETS.md`, D-43) | generowane AI, projekt | https://github.com/woogitsugames/lockwright/tree/main/contrib/gpt/S03 |
| game/assets/audio/ui/*.wav (S04: kategorie nowe + tool_roll_open/close wybrane zamiast v2 — ostrzejszy onset ≤ 1,4 ms, peak −14 dBFS, 6 wariantów) | dźwięk (UI diegetyczne) | ChatGPT (generowane AI), z `contrib/gpt/S04/ui/` (`manifest.json`, D-43) | generowane AI, projekt | https://github.com/woogitsugames/lockwright/tree/main/contrib/gpt/S04 |


## Gemini (GEM2 — fotorealistyczne ekrany 4 rodzin zamków: wafer, lever, warded, wooden_pin)

| Plik | Typ | Źródło | Licencja | Link |
|---|---|---|---|---|
| `art/blender/plates/plate_common.py`, `wafer_plate.py`, `lever_plate.py`, `warded_plate.py`, `wooden_pin_plate.py`, `render_all_plates.py` | skrypty wypieku i renderu planu B (GPU Cycles OPTIX: płyta statyczna, matcapy, wypiek normal/ORM/albedo, eksport GLB + `scene.json`, poprawki `contrib/gpt/T06`) | własne (Gemini, na bazie `art/blender/{wafer,lever,warded,wooden_pin}.py` oraz `spikes/lit-metal/tools/bake.py`) | własne projektu | — |
| `game/assets/photoreal_families/{wafer,lever,warded,wooden_pin}/plate/plate_1236x1650.png` | grafika (render Cycles GPU 1236×1650, 256 spp, statyczne tła planu B bez ruchomych części dla 4 rodzin zamków) | własne, wygenerowane przez `art/blender/plates/*_plate.py` (HDRI `interior.exr` — CC0, wpis wyżej) | własne projektu | — |
| `game/assets/photoreal_families/{wafer,lever,warded,wooden_pin}/matcap/matcap_*.png` | grafika (render Cycles GPU 512×512, 128 spp, kule matcap w oświetleniu danej sceny dla ruchomych materiałów) | własne, wygenerowane przez `art/blender/plates/*_plate.py` (HDRI `interior.exr` — CC0, wpis wyżej) | własne projektu | — |
| `game/assets/photoreal_families/{wafer,lever,warded,wooden_pin}/tex/*_{normal,orm,albedo}.png`, `*_baked.glb`, `scene.json` | modele 3D i tekstury wypieków (Smart UV Project 1024×1024 normal/ORM/albedo, modele glTF 2.0 + opis kamery i materiałów) | własne, wypieczone w Blenderze 5.2 LTS przez `art/blender/plates/*_plate.py` | własne projektu | — |
| `game/scenes/photoreal_families/shots/*.png` (168 plików: 4 rodziny × 7 stanów × 2 orientacje `824x1830` i `1830x824` × 3 warianty: kolor, `.gray.png`, `.dim.png`) | grafika (zrzuty kontrolne ekranów fotorealistycznych w Godot 4.7.2 Vulkan Forward Mobile) | własne, wygenerowane przez `game/scripts/photoreal_families/capture_all_shots.gd` | własne projektu | — |


## Gemini (GEM4 — warianty przekroju 1, 3, 5, 6 i 7 pinów oraz pełny napinacz)

| Plik | Typ | Źródło | Licencja | Link |
|---|---|---|---|---|
| `art/blender/variants/cutaway_n.py`, `art/blender/variants/render_plate_n.py`, `art/blender/variants/render_all_variants.py`, `art/blender/variants/render_all_variants.sh` | skrypty look-dev i wsadowe (parametryczny przekrój 1–7 pinów, zaślepione komory S1/S2, pełny napinacz 0–14°, stany per-pin, płyty planu B) | własne (Gemini, na bazie `art/blender/cutaway.py` i `art/blender/lw_common.py`) | własne projektu | — |
| `art/renders/variants/cutaway_{1,3,5,6,7}pin.png` + `.gray.png` | grafika (render Cycles GPU 2160×2880, 256 spp, OIDN RGB+Albedo+Normal, bez DOF + skala szarości) | własne, wygenerowane przez `art/blender/variants/cutaway_n.py` (HDRI `interior.exr` — CC0, wpis wyżej) | własne projektu | — |
| `art/renders/variants/cutaway_{1,3,5,6,7}pin_wrench.png` + `.gray.png` | grafika (render Cycles GPU 2160×2880, 256 spp, pełne ramię napinacza `--wrench-in-frame`, kąty 4°–14° + skala szarości) | własne, wygenerowane przez `art/blender/variants/cutaway_n.py` (HDRI `interior.exr` — CC0, wpis wyżej) | własne projektu | — |
| `art/renders/variants/plates/plate_{1,3,5,6,7}pin.png`, `art/renders/variants/plates/plate_{1,3,5,6,7}pin_wrench.png` | grafika (render Cycles GPU 2160×2880, 256 spp, statyczne tła planu B bez ruchomych części) | własne, wygenerowane przez `art/blender/variants/render_plate_n.py` (HDRI `interior.exr` — CC0, wpis wyżej) | własne projektu | — |
| `art/renders/variants/compare_before_after.png` | grafika (zestawienie porównawcze przed/po względem `art/renders/section.jpg`) | własne, wygenerowane przez `art/blender/variants/render_all_variants.py` | własne projektu | — |


## Gemini (GEM1 — materiały marketingowe 4K: ujęcia R01–R17, zwiastuny 30 s i 15 s PL/EN, klatki 4K)

| Plik | Typ | Źródło | Licencja | Link |
|---|---|---|---|---|
| `art/blender/marketing/gpu_common.py`, `cutaway_anim.py`, `stairwell_anim.py`, `tray_anim.py`, `families_render.py`, `build_trailers.py` | skrypty animacji, renderowania GPU Cycles (OPTIX) i montażu wideo/audio (`docs/MARKETING.md` §1–§4) | własne (Gemini, na bazie `art/blender/{cutaway,stairwell,tray,wafer,warded,lever,wooden_pin,ring_combo,lw_common,env_common}.py`) | własne projektu | — |
| `art/marketing/previews/*.png` (23 pliki: podglądy 540×960 dla ujęć `R01`–`R17`, w tym 3 przyrządy optyczne `R16_*` oraz 5 rodzin zamków `R17_*` w stanach `free` i `set`) | grafika (render Cycles GPU 540×960, odszumianie OptiX RGB+Albedo+Normal, AgX) | własne, wygenerowane przez `art/blender/marketing/{stairwell_anim,tray_anim,cutaway_anim,families_render}.py` (HDRI `interior.exr` — CC0, fonty Bona Nova / Atkinson Hyperlegible Next — SIL OFL 1.1, wpisy wyżej) | własne projektu | — |
| `art/marketing/stills/*.png` (12 plików ≤ 10 MB: klatki 4K `2160x3840` 9:16 oraz `3840x2160` 16:9 dla sklepu i prasy — `R01`, `R02`, `R04`, `R06`, `R07`, `R08`, `R10`, `R12`, `R13`) | grafika (render Cycles GPU 256 spp, OptiX RGB+Albedo+Normal, bez DOF na ujęciach mechanizmu, AgX Medium High Contrast) | własne, wygenerowane przez `art/blender/marketing/{stairwell_anim,tray_anim,cutaway_anim}.py` | własne projektu | — |
| `art/marketing/subtitles/trailer_{30s,15s}_{pl,en}.srt` (4 pliki napisów SRT) | napisy wideo (`.srt`) | własne (`docs/MARKETING.md` §1 i §2) | własne projektu | — |
| `trailer_30s_{pl,en}.mp4`, `trailer_30s_{pl,en}_sub.mp4`, `trailer_30s_{pl,en}_music.mp4`, `trailer_15s_{pl,en}.mp4`, `trailer_15s_{pl,en}_sub.mp4`, `trailer_15s_{pl,en}_music.mp4` (4K `2160x3840` oraz `_1080p`), `R01.mp4`–`R15.mp4`, `stills_4k_R16_R17.zip` (w GitHub Release `gemini-gem1`) | wideo MP4 (H.264 `libx264` CRF 18 / AAC 192 kbps 48 kHz) i dodatkowe klatki 4K | własne: obraz z `art/blender/marketing/*.py`, dźwięk diegetyczny z `audio/v2/out/` i `game/assets/audio/` + sub-bas haptyczny 40–90 Hz (`-18 dB`), wersje `_music` z utworami `contrib/gpt/S01/audio/` (wpisy wyżej), montaż `art/blender/marketing/build_trailers.py` | własne projektu | https://github.com/woogitsugames/lockwright/releases/tag/gemini-gem1 |



## Materiały fotograficzne (Magnific AI, D-42, D-48)

Źródło: zdjęcia generowane AI w Magnific (2026-11-05), wybór sesji A: `contrib/incoming/magnific/selected/README.md` (pliki `creation_*.png` w Release `incoming-assets`); `leather_chocolate` i `thumb_dent` — Gemini Nano Banana, zestaw właściciela `contrib/incoming/leather_set_2026-11-05/` (NB01). Obróbka: `tools/make_photo_materials.py` (usunięcie gradientu światła, bezszwowość przez minimalne cięcie, mapy pochodne, wycinanie GrabCut). Opis plików i zastosowań: `art/textures/photo/README.md`.

| Plik | Typ | Źródło | Licencja | Link |
|---|---|---|---|---|
| `art/textures/photo/{leather_brown_new,leather_brown_worn,brass_face_milled,brass_patina_grease,steel_ground,spring_steel_polished,nickel_satin,iron_painted_rust,terrazzo_grey_red,cement_tiles,pine_floor_painted,workshop_concrete}/*` | tekstury bezszwowe u+v (albedo JPG q92 2048²/1024², normal OpenGL PNG, roughness PNG, height 16-bit 1024², `material.json`, podgląd 2×2) | Magnific (generowane AI) + obróbka `tools/make_photo_materials.py` | generowane AI, warunki narzędzia Magnific (D-42) | `contrib/incoming/magnific/selected/` |
| `art/textures/photo/leather_chocolate/*` | tekstura bezszwowa u+v (jw.) | Gemini Nano Banana (generowane AI, NB01) + obróbka skryptem | generowane AI, warunki narzędzia Gemini (D-42) | `contrib/incoming/leather_set_2026-11-05/` |
| `art/textures/photo/{leather_stitching_strip,steel_heat_tint}/*` | tekstury pasowe (bezszwowe tylko w poziomie, u) | Magnific (generowane AI) + obróbka skryptem | generowane AI, warunki Magnific (D-42) | `contrib/incoming/magnific/selected/` |
| `art/textures/photo/brass_turned/*` | tekstura promieniowa, wyśrodkowana (czoło wkładki), bez kafelkowania | Magnific (generowane AI) + obróbka skryptem | generowane AI, warunki Magnific (D-42) | `contrib/incoming/magnific/selected/` |
| `art/textures/photo/objects/*.png` (wycinki z alfą: zwijka otwarta, kieszeń, zatrzask, wycieraczka, koperty, papiery, owal tuszu, ikony dzwonek/„L”/„7”) | grafika RGBA (pełna + `_1k`) | Magnific (generowane AI) + GrabCut/Hough/klucz tuszu w skrypcie | generowane AI, warunki Magnific (D-42) | `contrib/incoming/magnific/selected/` |
| `art/textures/photo/objects/thumb_dent{,_1k,_normal}.png` | naklejka (decal) wgniecenia kciukiem w skórze, alfa promieniowa + normal | Gemini Nano Banana (generowane AI) + obróbka skryptem | generowane AI, warunki Gemini (D-42) | `contrib/incoming/leather_set_2026-11-05/` |
| `art/textures/photo/contact_previews.jpg`, `contact_objects.jpg` | arkusze kontrolne (nie do gry) | własne, skrypt | własne projektu | — |
| `tools/make_photo_materials.py` | skrypt obróbki (Python, numpy, Pillow, OpenCV) | własne | własne projektu | — |
