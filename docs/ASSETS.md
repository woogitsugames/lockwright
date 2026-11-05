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
| art/blender/wafer.py, lever.py, warded.py, wooden_pin.py, ring_combo.py, lw_common.py (sekcja v2) | skrypty look-dev (proceduralne modele i materiały) | własne (Claude) | własne projektu | — |
| art/renders/wafer.png, lever.png, warded.png, wooden_pin.png | grafika (render Cycles) | własne, wygenerowane skryptami z `art/blender/` | własne projektu | — |
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
