# G03 — bezszwowe drewno drzwi i ramiaków (Lockwright)

**Data:** 2026-11-05. **Status:** zestaw gotowy lokalnie; przed użyciem produkcyjnym wymagany test look-dev w Blenderze na docelowej geometrii.

## Zawartość

Cztery materiały PBR (12 map, **każda 2048×2048 px, PNG, tekstura powtarzalna na obu osiach**):

| Materiał | Albedo | Height | Roughness | Przeznaczenie |
|---|---|---|---|---|
| Stary dąb satynowo lakierowany / Satin old oak | `materials/oak_satin_albedo_2048.png` | `materials/oak_satin_height_2048.png` | `materials/oak_satin_roughness_2048.png` | Drzwi wejściowe klasyczne, nieregularne słoje, patyna, pory i rysy |
| Dąb w butelkowej zieleni / Bottle-green painted oak | `materials/oak_bottle_green_albedo_2048.png` | `materials/oak_bottle_green_height_2048.png` | `materials/oak_bottle_green_roughness_2048.png` | Kryjąca farba olejna, smugi pędzla, odsłonięte drewno i odpryski |
| Sosna kremowa / Cream painted pine | `materials/pine_cream_albedo_2048.png` | `materials/pine_cream_height_2048.png` | `materials/pine_cream_roughness_2048.png` | Starsza farba kremowa, większe łuski i rysy |
| Orzech ciemny / Dark walnut | `materials/walnut_dark_albedo_2048.png` | `materials/walnut_dark_height_2048.png` | `materials/walnut_dark_roughness_2048.png` | Elegantsze drzwi, ciemne żyłkowanie i umiarkowany połysk |

**Referencje fotograficzne (nie mapy PBR):**

- `references/reference_oak_escutcheon_closeup.jpg` — fotograficzne zbliżenie starego dębu, podłużnego metalowego szyldu i fikcyjnej wkładki, ciepłe światło (996×734).
- `references/reference_oak_escutcheon_knob.jpg` — zbliżenie szyldu i okrągłej gałki na dębowych drzwiach płycinowych, żarówka na klatce (1118×734).

**Podglądy 2×2:**

- `previews/preview_albedo_2x2.jpg` — cztery tekstury albedo w siatce 2×2, podpisy PL/EN.
- `previews/preview_pbr_2x2.jpg` — cztery materiały, w każdym widok Albedo / Height / Roughness. Kanał Height jest **wzmocniony kontrastowo tylko w podglądzie**, nie w plikach źródłowych.

**Narzędzia i odtwarzalność:** `generate_textures.py` (deterministyczny generator), `requirements.txt` (zależności), `quality_checks.py` (walidacja), `QA.json` (wyniki), `ASSETS.md` (pochodzenie i warunki wszystkich grafik).

## Jak importować w Blenderze / Godot

1. `albedo` — Image Texture **sRGB / Color** do Base Color; nie wzmacniać ekspozycji, nie traktować obrazu referencyjnego jako albedo (referencje zawierają oświetlenie).
2. `roughness` — Image Texture **Non-Color** bez dodatkowej gamma → Principled BSDF / Roughness. Bez metaliczności, bez sztucznego bloom.
3. `height` — **16-bit PNG, Non-Color**, podłączyć do Bump (Height) z dystansem początkowo ok. **0,1–0,3 mm** (dostroić do skali obiektu). To skala względna, nie pomiar rzeczywistej topografii drewna.
4. Słoje mają domyślną orientację **wzdłuż osi V** obrazu. Dla ramiaków, płycin i listew używać osobnych UV z kierunkiem włókien zgodnym z częścią drzwi; nie skalować tekstury w poprzek tak, by włókna stały się paskami.
5. Po skonfigurowaniu materiału przetestować w Cycles, następnie w Godot Mobile z docelowym światłem: ciepła żarówka z lewej/góry, chłodne okno jako fill. Materiały nie zawierają wypalonych cieni ani refleksów.
6. Rzeczywiste szczeliny między deskami, obrzeża, listwy i ramiaki pozostają **geometrią 3D**, nie namalowanymi głębokimi pasami w albedo.

## Tworzenie od nowa

```bash
python3 -m pip install -r requirements.txt
python3 generate_textures.py
python3 quality_checks.py
```

Skrypt tworzy 12 map, podglądy albedo i PBR. **Dwie referencje są odrębnymi wygenerowanymi obrazami fotograficznymi**; nie odtwarza ich skrypt procedur. Zestaw dostarczony zawiera ich gotowe kopie.

## Weryfikacja i ograniczenia

- `quality_checks.py` potwierdza rozmiar 2048×2048, typ kanałów, limit **20 MB na plik**, ciągłość przeciwległych krawędzi dla wszystkich 12 map oraz obecność 2 zdjęć i 2 zestawień 2×2. Wyniki: `QA.json`.
- Mapy generowane są procedurami z poziomami szumu o różnych skalach, ugięciem słojów przy sękach, porami i rysami. Brak wzoru z idealnie równoległych pasów. Każdy wariant ma inny seed.
- To opracowanie materiałowe, nie skan fotogrametryczny rzeczywistych drzwi. Przy bardzo bliskiej kamerze widać ograniczenia proceduralnych uszkodzeń lakieru i farby; wymagana kontrola plastyczna na modelu Blendera.
- Zdjęcia referencyjne pochodzą z dwóch kadrów wygenerowanego kolażu, następnie zostały wykadrowane i dwukrotnie powiększone. Ich **rzeczywista ilość szczegółów jest niższa** niż sugeruje wynikowy rozmiar pikselowy.
- Kod i zdjęcia nie opisują technik otwierania realnych zamków. Okucia są fikcyjne i bez marek.
- Nie modyfikowano plików poza `contrib/gpt/G03/`. Zalecenie dla zespołu Blendera: w `art/blender/env_common.py` używać tej samej orientacji UV dla wzdłużnych ram i osobnych płycin; to **uwaga**, nie zmiana pliku.
