# G17 — pochodzenie i warunki użycia zasobów

**Data wytworzenia:** 2026-11-05.  
**Narzędzie źródłowe:** natywny generator obrazów ChatGPT ImageGen (OpenAI), obrazy stworzone na potrzeby tego zlecenia.  
**Narzędzia edycyjne:** autorski skrypt `generate.py` (Python, Pillow, NumPy): usuwanie długiego cienia, kadrowanie, 9-slice z czystym środkiem, korekta kolorów, zmian stanu przycisku, nowe przezroczyste tła i cienie, sRGB ICC, eksport PNG/JPEG.  
**Warunki:** zasoby wyjściowe pochodzą z narzędzia OpenAI; korzystanie i rozpowszechnianie zgodnie z obowiązującymi warunkami usługi OpenAI. Nie należy oznaczać materiałów jako CC0 ani przypisywać praw do cudzych fotografii.

## Pełne prompty źródłowe

**P1 — pozioma emaliowana tabliczka** (`source/enamel_wide_chatgpt.png`):

> A photorealistic, straight-on product render of a blank, rounded rectangular enamel street sign isolated on a transparent checkerboard background, centered and spanning the frame horizontally with no text, logos, symbols, or perspective distortion. Its glossy deep navy-blue surface shows fine scratches, crackle lines, dust, and weathering, framed by a thin aged ivory inset border and a thick rounded rim with chipped enamel, exposed metal, rust-brown corrosion, and worn corners; two symmetrical rust-ringed mounting holes sit near the center height, while subtle reflections and a faint shadow beneath enhance its ceramic, game-asset appearance.

**P2 — kwadratowa emaliowana tabliczka** (`source/enamel_square_chatgpt.png`):

> A front-facing, square vintage enamel metal plaque with softly rounded corners is isolated on a transparent checkerboard background, filling most of the frame with no lettering, graphics, people, or other objects. Its glossy deep navy-blue surface features a cream inset border, symmetrical rust-ringed mounting holes, worn edges, chipped corners, fine scratches, speckling, and uneven reflections that convey realistic age and industrial character.

## Rejestr plików

| Plik | Narzędzie / źródło | Prompt | Edycje po wygenerowaniu |
|---|---|---|---|
| `source/enamel_wide_chatgpt.png` | ChatGPT ImageGen | P1 (pełny powyżej) | Brak; oryginał źródłowy |
| `source/enamel_square_chatgpt.png` | ChatGPT ImageGen | P2 (pełny powyżej) | Brak; oryginał źródłowy |
| `button_navy_normal.png` | ChatGPT ImageGen + Python | P1 | Kadrowanie, usunięcie oryginalnego cienia, czysty środek 9-slice, cień w alfie, eksport 1600×400 |
| `button_navy_pressed.png` | ChatGPT ImageGen + Python | P1 | Jak normal + przesunięcie w dół 5 px, słabszy cień i mniejszy połysk |
| `button_bottle_green_normal.png` | ChatGPT ImageGen + Python | P1 | Jak normal + kolor butelkowej zieleni |
| `button_bottle_green_pressed.png` | ChatGPT ImageGen + Python | P1 | Jak pressed + kolor butelkowej zieleni |
| `button_ivory_normal.png` | ChatGPT ImageGen + Python | P1 | Jak normal + jasna emalia i ciemna obwódka |
| `button_ivory_pressed.png` | ChatGPT ImageGen + Python | P1 | Jak pressed + jasna emalia i ciemna obwódka |
| `button_burgundy_normal.png` | ChatGPT ImageGen + Python | P1 | Jak normal + kolor bordo |
| `button_burgundy_pressed.png` | ChatGPT ImageGen + Python | P1 | Jak pressed + kolor bordo |
| `primary_navy_normal.png` | ChatGPT ImageGen + Python | P1 | Czysty środek 9-slice, proporcje 3:1, wyższa i grubsza obwódka, cień w alfie |
| `primary_navy_pressed.png` | ChatGPT ImageGen + Python | P1 | Jak poprzedni + 5 px przesunięcia i słabszy cień |
| `initial_navy.png` | ChatGPT ImageGen + Python | P2 | Kadrowanie, ujednolicone tło alfa, rozmiar 512×512 |
| `initial_bottle_green.png` | ChatGPT ImageGen + Python | P2 | Jak poprzedni + kolor butelkowej zieleni |
| `initial_ivory.png` | ChatGPT ImageGen + Python | P2 | Jak poprzedni + jasna emalia i ciemna obwódka |
| `initial_burgundy.png` | ChatGPT ImageGen + Python | P2 | Jak poprzedni + kolor bordo |
| `contact_sheet.jpg` | Python/Pillow | P1 + P2 | Skalowanie podglądów, siatka tła tylko na arkuszu, opisy poza obrazami |

**Pliki programistyczne (`generate.py`, `manifest.json`, `README.md`, `ASSETS.md`):** wytworzone tekstowo, bez generatora obrazów; pochodzenie i opis w tym katalogu.
