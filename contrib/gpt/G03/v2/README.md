# G03 v2 — fotorealistyczne drewno drzwi / Photoreal door wood

**Lockwright** · katalog docelowy `contrib/gpt/G03/v2/` · **2026-11-05**.

## Co dostarczono

Cztery materiały wywiedzione z **obrazów wygenerowanych w ChatGPT** (a nie stworzone od podstaw z proceduralnych fal). Dla każdego:

- `materials/{id}_albedo_2048.png` — bezszwowy kolor bazowy, 2048 × 2048 px, RGB 8-bit (sRGB);
- `materials/{id}_height_2048.png` — bezszwowy przybliżony height, 2048 × 2048 px, 16-bit PNG, efektywnie 10-bit danych; skala względna, **nie** pomiar geometrii;
- `materials/{id}_roughness_2048.png` — bezszwowa szorstkość, 2048 × 2048 px, 8-bit grayscale, wartości w przybliżeniu 0–1;
- `previews/{id}_albedo_2x2.jpg` — podgląd identycznego materiału powtórzonego cztery razy (2 × 2).

| `id` | Materiał (PL / EN) | Wizualnie |
|---|---|---|
| `oak_satin` | Stary dąb satynowy / Satin old oak | Promienie rdzeniowe, nieregularny rysunek, pory, delikatne rysy |
| `oak_bottle_green` | Dąb w butelkowej zieleni / Bottle-green painted oak | Ślady pędzla, odsłonięte drewno, przetarcia i ubytki |
| `pine_cream` | Kremowa sosna / Cream painted pine | Odstające płaty starej farby, wywinięte brzegi, fragmenty drewna |
| `walnut_dark` | Ciemny orzech / Dark walnut | Kontrastowe słoje, kilka sęków, cieplejsza ciemna patyna |

Dodatkowe materiały:

- `previews/materials_overview_2x2.jpg` — cztery odmiany drewna obok siebie;
- `previews/pbr_overview.jpg` — Albedo / Height / Roughness dla każdej odmiany; **kontrast Height wzmocniony tylko w podglądzie**;
- `references/reference_oak_brass_escutcheon_A.jpg`, `..._B.jpg` — dwa generowane obrazy referencyjne z dębowymi drzwiami i mosiężnymi szyldami; bez narzędzi, bez logotypów;
- `sources/` — po trzy kadry wejściowe na materiał, wycięte z trzech wygenerowanych plansz źródłowych;
- `tools/build_v2.py`, `requirements.txt` — reprodukowalna rekonstrukcja map z dostarczonych kadrów;
- `tools/quality_checks.py`, `QA.json` — sprawdzenie parametrów i zgodności krawędzi;
- `ASSETS.md` — pochodzenie, pełne prompty generatora, obróbka i warunki korzystania.

## Metoda

1. W generatorze obrazów ChatGPT powstały trzy **plansze zbiorcze** z wyraźnymi przykładami czterech materiałów i ujęć okuć. Źródła map nie są proceduralnie wygenerowanym rysunkiem słojów.
2. Z plansz wycięto osobne fotografie materiałów (`sources/`). Fragmenty mają 213–380 px szerokości, a **nie** nominalne 2048 px. Trzeba to uwzględnić przy ocenie ostrości.
3. Obrazy źródłowe zostały zrekonstruowane do 2048 × 2048 przez łączenie fragmentów na torusie (patch quilting), miękkie łatanie przejść, wyrównanie dużych gradientów oświetlenia i lokalne wyostrzenie. Jasność nie zastępuje realnego reliefu.
4. Z kolorów i kontrastów wyprowadzono przybliżone height i roughness. Farba w miejscach odprysków jest mniej lub bardziej szorstka w zależności od wariantu; warstwa lakieru ma niższy roughness.
5. Wyrównano przeciwległe krawędzie. **W 12 mapach różnica pikselowa lewa/prawa i góra/dół = 0**, co potwierdza `QA.json` i `tools/quality_checks.py`. Dostarczono podglądy powtarzania 2 × 2.

## Ważne ograniczenie jakościowe

**Zadanie spełniono funkcjonalnie, ale nie w całości jakościowo:** generator zwrócił plansze, nie osobne pełnorozdzielcze zdjęcia 2048 × 2048. Mapy mają nominalne 2048 × 2048 i są fotopochodne, lecz detale są rekonstrukcją z mniejszych fragmentów. W bliskich zbliżeniach widać powielanie motywów. Nie należy ich przedstawiać jako natywnych fotografii materiałowych ani jako fotogrametrii. Do produkcyjnego zbliżenia makro zalecane są **cztery pełnokadrowe źródła wysokiej rozdzielczości**, powtórne płytkowanie i pomiary/ocena reliefu w Blenderze. Wymóg „makro 30–40 cm szerokości” nie jest możliwy do wiarygodnego potwierdzenia z wygenerowanej planszy.

## Użycie w Blenderze i Godot

- Albedo: przestrzeń **sRGB** / Base Color. Nie dodawaj baked illumination ani wysokokontrastowych odbić.
- Height: **Non-Color**, 16-bit; bardzo słaby Bump, start ~0,1–0,3 mm i dalsze dostrojenie do geometrii. Intensywnie łuszcząca się farba potrzebuje również prawdziwego modelowania/decals.
- Roughness: **Non-Color**, 8-bit; poziomy są artystycznym przybliżeniem, a nie zmierzoną BRDF.
- Na ramiakach i płycinach obracaj UV zgodnie z kierunkiem włókien; geometria szczelin między deskami powinna pozostać geometrią, nie fakturą.
- Sprawdź materiały w Blenderze Cycles i Godot Mobile przy ciepłej żarówce i chłodnym wypełnieniu, bez bloom i metaliczności na drewnie.

## Reprodukcja

Uruchom z katalogu `v2/` po instalacji zależności:

```bash
python3 -m pip install -r requirements.txt
python3 tools/build_v2.py
python3 tools/quality_checks.py
```

Skrypt wykorzystuje tylko dostarczone `sources/`, nie wymaga osobnego modelu do generacji obrazu. Każda mapa ma mniej niż 20 MiB. Nie zmieniono żadnego pliku w starej wersji `contrib/gpt/G03/`.

## Status GitHub

Repozytorium `woogitsugames/lockwright` jest dostępne przez konektor GitHub. W tym środowisku nie dało się przesłać dużych binarnych map bezpośrednio do repozytorium; dlatego komplet oddano jako **dwa archiwa ZIP** z katalogiem `contrib/gpt/G03/v2/` i sekcjami do dołączenia do nadrzędnych `README.md`, `ASSETS.md`. **Nie ma commita na `main`.**
