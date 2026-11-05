# G03 — Drewno drzwi i ramiaków / Door wood PBR

Data: **2026-11-05**. Opracowano cztery bezszwowe materiały PBR i dwa osobne obrazy referencyjne.
**Ważne:** W GitHub umieszczono źródła, opis i rejestr pochodzenia. Duże PNG/JPG są w archiwum ZIP dostarczonym właścicielowi poza repozytorium; należy rozpakować je do tego katalogu. Sam commit GitHub nie jest jeszcze pełnym zestawem binarnych grafik.

## Materiały

Wszystkie mapy: **2048 × 2048 px**; albedo sRGB, height **16-bit grayscale**, roughness **8-bit grayscale**, bezszwowe w U i V.

| Materiał (PL / EN) | Albedo | Height | Roughness |
|---|---|---|---|
| Dąb satynowy / Satin oak | materials/oak_satin_albedo_2048.png | materials/oak_satin_height_2048.png | materials/oak_satin_roughness_2048.png |
| Dąb malowany w butelkowej zieleni / Bottle-green oak | materials/oak_bottle_green_albedo_2048.png | materials/oak_bottle_green_height_2048.png | materials/oak_bottle_green_roughness_2048.png |
| Sosna kremowa / Cream painted pine | materials/pine_cream_albedo_2048.png | materials/pine_cream_height_2048.png | materials/pine_cream_roughness_2048.png |
| Orzech ciemny / Dark walnut | materials/walnut_dark_albedo_2048.png | materials/walnut_dark_height_2048.png | materials/walnut_dark_roughness_2048.png |

**Zdjęcia referencyjne (nie mapy PBR):**
- references/reference_oak_escutcheon_closeup.jpg — dąb, szyld, fikcyjna wkładka, ciepła żarówka.
- references/reference_oak_escutcheon_knob.jpg — dąb, gałka, szyld i płycina w świetle klatki schodowej.

**Podglądy 2×2:** previews/preview_albedo_2x2.jpg oraz previews/preview_pbr_2x2.jpg. W podglądzie PBR skala height jest rozciągnięta kontrastowo wyłącznie na potrzeby czytelności.

## Odtworzenie map

Po instalacji zależności uruchom z katalogu G03:

    python3 -m pip install -r requirements.txt
    python3 generate_textures.py
    python3 quality_checks.py

Generator tworzy 12 map i 2 podglądy, ale **nie** odtwarza referencji zdjęciowych; są dołączone do przekazanego archiwum. Jeżeli referencje nie zostały rozpakowane, walidacja pełnej paczki zgłosi ich brak.

## Look-dev Blender 4.2 LTS / Godot 4.7

- Albedo -> Principled BSDF / Base Color, Color Space **sRGB**.
- Roughness -> Principled BSDF / Roughness, Color Space **Non-Color**.
- Height -> Bump / Height, Color Space **Non-Color**, orientacyjnie od 0,1 do 0,3 mm odkształcenia; konieczne dostrojenie do skali skrzydła i kamery.
- Włókna drewna biegną wzdłuż osi **V**. Dla ramiaków i płycin stosować odrębne UV zgodne z kierunkiem słojów.
- Rzeczywiste listwy, ramiaki i szczeliny desek wykonać geometrią, a nie dorysowanym wzorem w albedo.
- Sprawdzić w Cycles i Godot Mobile przy ciepłej żarówce z klatki i chłodnym świetle okna. Brak wypalonego cienia i bloom.

## Testy i ograniczenia

Lokalny test: 12/12 map 2048², 16-bit height, 0 różnicy przeciwległych krawędzi, pliki poniżej 20 MB, 2 referencje, 2 podglądy. Pełny wynik w przekazanym ZIP: QA.json.

Materiał jest generacją proceduralną, nie skanem rzeczywistych drzwi. Zbliżenia ekstremalne wymagają dodatkowego look-dev i poprawienia detalu mikro-porów, odprysków oraz refleksów z lampy już w silniku. Zdjęcia referencyjne to kadry wygenerowanego kolażu poddane cropowi i przeskalowaniu ×2, nie oryginały z aparatu.

Przedmioty są pozbawione logotypów; mechanizmy fikcyjne. Nie zmieniano innych katalogów. Dla zespołu Blendera: dopasować UV w art/blender/env_common.py (uwaga, bez zmiany tamtego pliku).
