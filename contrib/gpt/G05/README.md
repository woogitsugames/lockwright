# G05 — Posadzki / Floor textures

**Data:** 2026-11-05  
**Projekt:** Lockwright, fotorealistyczna klatka schodowa i warsztat ślusarski  
**Zakres:** wyłącznie `contrib/gpt/G05/`

## Wykonano

Cztery autorskie, proceduralnie wygenerowane materiały podłogowe z bezszwową powtarzalnością osi X/Y oraz odrębną wycieraczkę kokosową widzianą z góry. Dla każdego materiału dostarczono 2048 × 2048 px: albedo (PNG z paletą RGB, bez oświetlenia), 8-bitową mapę wysokości (PNG w skali szarości) i 8-bitową mapę roughness (PNG w skali szarości). Wycieraczka ma 2048 × 2048 px i przezroczystość PNG `tRNS` (odpowiednik kanału alpha dla obrazu z paletą). Każdy plik binarny jest mniejszy niż 20 MB.

Materiały:

- `textures/terrazzo_albedo.png`, `textures/terrazzo_height.png`, `textures/terrazzo_roughness.png` — lastryko szaro-czerwone z kamiennym kruszywem, wytarte w osi środkowej stopnia.
- `textures/cement_tiles_albedo.png`, `textures/cement_tiles_height.png`, `textures/cement_tiles_roughness.png` — cementowe kafle w oryginalny geometryczny motyw karo/trójkątów, z zaprawą i lokalnymi pęknięciami.
- `textures/painted_pine_albedo.png`, `textures/painted_pine_height.png`, `textures/painted_pine_roughness.png` — poziome deski sosnowe; czerwono-brązowa farba olejna, miejscowe przetarcia aż do jasnego drewna i szczeliny między deskami.
- `textures/workshop_concrete_albedo.png`, `textures/workshop_concrete_height.png`, `textures/workshop_concrete_roughness.png` — szary beton warsztatowy, zaschnięte plamy oleju, odcisk podstawy imadła i punkty po śrubach.
- `textures/coconut_doormat_rgba.png` — osobna wycieraczka z włókien kokosowych, widok ortogonalny z góry, przezroczyste tło.
- `previews/terrazzo_2x2.png`, `previews/cement_tiles_2x2.png`, `previews/painted_pine_2x2.png`, `previews/workshop_concrete_2x2.png` — podglądy podwójnego powtórzenia po obu osiach, 512 × 512 px.
- `previews/contact_sheet_4_materials.png` — arkusz 2 × 2 z czterema podglądami, 1024 × 1024 px.
- `generate_textures.js` — deterministyczny generator JS, Node.js 18+, bez dodatkowych zależności.
- `ASSETS.md` — rejestr pochodzenia zasobów, narzędzia, promptów i warunków użycia.

## Jak użyć w Godot 4.7

Albedo: `albedo_texture`, `albedo_color` = biały, import jako sRGB. Roughness: `roughness_texture` (kanał R), traktować liniowo, nie sRGB. Height: bump/parallax lub delikatna normal map wygenerowana z wysokości; wysokość jest **relatywna**, nie w milimetrach. Wycieraczka: płaska osobna siatka o proporcjach ~1,90:1, przezroczystość `alpha scissor`/`alpha hash` według potrzeb Mobile. Mapowanie albedo/height/roughness musi używać tych samych UV. Włączenie repeat i trilinear (mipmaps); sprawdzić czy importer Godot obsługuje indeksowane PNG i konwersję do RGBA (w razie potrzeby przekonwertować lokalnie na standardowe RGB/RGBA bez zmiany pikseli).

**Ważne:** Wytarcia i ślad po imadle są cechami konkretnego fragmentu powierzchni; wielokrotne kafelkowanie na dużej płaszczyźnie może ujawnić powtarzalność. Na stopniach ustaw UV tak, by środkowe wytarcie wypadało na środku stopnia. Przy warsztacie można rozdzielić plamy i odcisk imadła na decals w późniejszej iteracji.

## Kontrola jakości

- Wygenerowano 4 × (albedo + height + roughness) oraz wycieraczkę PNG z alfą.
- Generator wyrównuje przeciwległe piksele brzegowe na wszystkich mapach; kontrola programowa sprawdza identyczność pierwszego i ostatniego wiersza oraz kolumny.
- Podglądy 2 × 2 pozwalają ocenić ciągłość krawędzi, a arkusz porównać kolory i stopień zużycia.
- Wszystkie zasoby są własne, bez zewnętrznych tekstur, logo, napisów czy elementów innych gier.

## Co pozostało

Nie wykonano jeszcze testu materiałów w docelowych siatkach Godota na urządzeniu mobilnym (oświetlenie, mipmapy, wydajność, różne kierunki UV). Mapy wysokości są heurystyczne i wymagają dostrojenia skali bump. Nie wykonano skanu fizycznych materiałów ani renderów PBR w Cycles.

## Proponowany następny etap

1. Nałożyć materiał na konkretne stopnie, podłogę klatki i warsztatu; zweryfikować powtarzalność przy odległościach kamery gry.
2. W razie konieczności przenieść nałożenia oleju, przetarcia i odcisk imadła na osobne decals, aby ograniczyć regularne powtarzanie zabrudzeń.
3. Przygotować normal maps z `height` z małą intensywnością, zweryfikować w Godot Mobile i zachować kontrast materiałów w świetle ciepłej lampy oraz chłodnego okna.
