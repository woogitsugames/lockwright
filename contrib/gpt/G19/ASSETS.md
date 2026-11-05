# G19 — pochodzenie i parametry zasobów

Data: **2026-11-05**. Narzędzie: **autorski generator Python `generate.py` (SVG → CairoSVG → Pillow/NumPy)**. Żadnych zewnętrznych obrazów, stocku, marek ani sampli. Pliki przeznaczone do użytku w projekcie Lockwright, przygotowane na zamówienie właściciela. Kod źródłowy jest częścią pakietu; biblioteki wykonawcze nie są dystrybuowane.

## Pełny prompt / brief — auto

> Create an original 768x768 wordless pencil-and-chalk control-choice illustration on transparent backing. In a fixed frontal view, depict an imaginary unbranded upright smartphone, with a deliberately fictional simplified lock cutaway drawn on its display in the top half (four abstract pins and a broad dividing line, no actionable lock-picking details). One RIGHT hand approaches from below and the right thumb touches the RIGHT half of the display. A large graphite UP arrow above that thumb indicates lift. Close to the lower-left schematic tensioner, draw a small, original, simple CHALK ANCHOR/CLIP sign to communicate that tension holds automatically. Visual language: restrained graphite contour, faint off-white chalk echo, light hatching, warm hand outline, master Henryk notebook G10 style. No text, letters, numbers, emoji, real model design, logo, brands, neon, steampunk, photoreal instructions or crime imagery. Keep phone size and placement identical to the two-thumbs variant. Draw vector paths, render at 2x and downsample; prepare alpha and cream-paper texture versions.


## Pełny prompt / brief — two_thumbs

> Create an original 768x768 wordless pencil-and-chalk control-choice illustration on transparent backing. In a fixed frontal view, depict the SAME imaginary unbranded upright smartphone and SAME deliberately fictional simple lock cutaway as the AUTO version (four abstract pins and a broad dividing line, no actionable lock-picking details). TWO hands approach from below: the LEFT thumb touches the LEFT half of display with an upward arrow for tension, and the RIGHT thumb touches the RIGHT half with a second upward arrow PLUS one bold horizontal DOUBLE arrow to show lateral motion. Visual language: restrained graphite contour, faint off-white chalk echo, light hatching, warm hand outline, master Henryk notebook G10 style. No text, letters, numbers, emoji, real model design, logo, brands, neon, steampunk, photoreal instructions or crime imagery. Keep phone size and placement identical to AUTO. Draw vector paths, render at 2x and downsample; prepare alpha and cream-paper texture versions.


## Edycje wykonane kodem

Rysunek: własne ścieżki SVG bez modelu realnego telefonu; rasteryzacja w 1536×1536 i zmniejszenie metodą Lanczos do 768×768; delikatna modulacja alfy imitująca grafit; dla wariantu papierowego dołożona proceduralna, deterministyczna faktura kremowa; miniatury przez Lanczos. Żadna zewnętrzna fotografia nie weszła w skład prac.

## Wykaz zasobów

| Plik | Narzędzie | Brief | Modyfikacje | SHA-256 |
|---|---|---|---|---|
| `controls_auto.png` | Python/SVG/CairoSVG/Pillow | auto | rasteryzacja / faktura / skala | `e6f40cf58511457122b977e4ba9bd2f5d197120d63c5d57d13752e1819bf43e0` |
| `controls_auto_alpha.png` | Python/SVG/CairoSVG/Pillow | auto | rasteryzacja / faktura / skala | `ac350be8493e1589088a657fd3ca8fcdd4b31ddc385e6184fef1ebb9c4cc0e74` |
| `controls_two_thumbs.png` | Python/SVG/CairoSVG/Pillow | two_thumbs | rasteryzacja / faktura / skala | `994f6f052aa6fba14d8338879f8cd5181cc2ce2d1c7becfa579ba56f7c4efa78` |
| `controls_two_thumbs_alpha.png` | Python/SVG/CairoSVG/Pillow | two_thumbs | rasteryzacja / faktura / skala | `217ed281592214c1bfbf51637158fadb3907ab3b8163bc9094a899281544b2ed` |
| `contact-sheet.jpg` | Python/SVG/CairoSVG/Pillow | auto + two_thumbs | kompozycja 4 wariantów | `b740fee2edec1a7fcff0bbdccd1a3b1b37a9e47166fdcdea062826a87c88e119` |
| `preview_auto_192.png` | Python/SVG/CairoSVG/Pillow | auto | rasteryzacja / faktura / skala | `910fa4ae94a389221ab25c473e87ed9f9c0e76314844635802f477e9af17ce2b` |
| `preview_auto_96.png` | Python/SVG/CairoSVG/Pillow | auto | rasteryzacja / faktura / skala | `977c86e0bf1bcf8b66db46d30df8f54e340674d59bec40ca9f656e99a1aa4bb3` |
| `preview_two_thumbs_192.png` | Python/SVG/CairoSVG/Pillow | two_thumbs | rasteryzacja / faktura / skala | `0fae3c751bf62af5f78a7285469d293d540380d76e86498c7230095c53f0a9a3` |
| `preview_two_thumbs_96.png` | Python/SVG/CairoSVG/Pillow | two_thumbs | rasteryzacja / faktura / skala | `4e35e10a6efde47b4b3f5aa251dd5c2ed1af9523c7d507886d2cd35ae6bc7a0f` |

| `auto.svg` | Python / własne ścieżki SVG | auto | wektorowy rysunek źródłowy | `4d76be0b5451f4f56ff6ae07c6f9a588d49861daafbeb4963b3fb65b29e0f435` |
| `two_thumbs.svg` | Python / własne ścieżki SVG | two_thumbs | wektorowy rysunek źródłowy | `ad33be4c43e95d23ba76c7161de2943622cede2c36eb7a2aca27ec5b87b73900` |

Zastosowanie: bez ograniczeń wewnątrz projektu Lockwright w zakresie praw przysługujących zamawiającemu do oryginalnych materiałów. **Nie dołączono licencjonowanych materiałów osób trzecich.**
