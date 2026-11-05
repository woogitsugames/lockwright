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
| spikes/lit-metal/assets/interior.hdr (HDRI otoczenia; konwersja EXR→HDR) | grafika (HDRI) | `datafiles/studiolights/world/interior.exr` dołączony do Blendera 4.2 (to samo HDRI, którego używa `art/blender/cutaway.py`) | CC0 (HDRI studia Blendera pochodzą z Poly Haven) — **do weryfikacji** w `blender/release/datafiles/studiolights/world/license.txt` | https://polyhaven.com/license |
| spikes/lit-metal/assets/tex/*.png, cutaway*.glb, plate/*.png, screens/*.png | grafika (wypieki, rendery) | własne: wypiek i rendery sceny `art/blender/cutaway.py` skryptami `spikes/lit-metal/tools/` | własne projektu | — |
| art/blender/wafer.py, lever.py, warded.py, wooden_pin.py, ring_combo.py, lw_common.py (sekcja v2) | skrypty look-dev (proceduralne modele i materiały) | własne (Claude) | własne projektu | — |
| art/renders/wafer.png, lever.png, warded.png, wooden_pin.png | grafika (render Cycles) | własne, wygenerowane skryptami z `art/blender/` | własne projektu | — |
| HDRI `interior.exr` (używane w renderach, nie w repo) | oświetlenie | Blender 4.2 datafiles/studiolights/world (Greg Zaal, Poly Haven) | CC0 | https://polyhaven.com |
| cyfry w ring_combo.py: mockups/fonts/Lato-Bold.ttf | font | jak wyżej (Lato) | SIL OFL 1.1 | — |
| game/addons/gut/fonts/* (AnonymousPro, CourierPrime, LobsterTwo) | font | GUT v9.7.1 (bitwes/Gut) | SIL OFL 1.1 | https://github.com/bitwes/Gut/tree/master/addons/gut/fonts |
| game/addons/lockcore_gd/** | kod (GDExtension) | własny + godot-cpp (master, API 4.7) | MIT | https://github.com/godotengine/godot-cpp |
