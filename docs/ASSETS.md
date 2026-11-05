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
