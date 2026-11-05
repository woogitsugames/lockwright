# ASSETS — G03 v2

**Data:** 2026-11-05. **Lokalizacja:** `contrib/gpt/G03/v2/`.

## Narzędzie, warunki użycia i historia generacji

- **Narzędzie źródłowe:** generator obrazów ChatGPT (OpenAI). Trzy kolejne generacje; model w każdej stworzył planszę zbiorczą 1536 × 1024 px, nie osobne źródła 2048 × 2048. Materiały wycięto z plansz, a następnie złożono algorytmicznie z ich fragmentów.
- **Postprodukcja:** Python, Pillow, OpenCV, NumPy. Łączenie fragmentów z miękką maską i okresowymi krawędziami, lokalna korekcja jasności, wyostrzenie, pochodne mapy height/roughness. Wszystkie nowe mapy mają rozmiar 2048 × 2048 px.
- **Licencja i prawa:** obrazy wygenerowane usługą OpenAI, korzystanie zgodnie z aktualnymi warunkami OpenAI (https://openai.com/policies/terms-of-use/). Nie należy zakładać wyłączności ani gwarancji oryginalności wobec praw osób trzecich. Kod postprodukcji napisano na potrzeby projektu; brak zewnętrznych materiałów stockowych i logotypów.
- **Modyfikacje:** TAK dla każdego nowego pliku; obrazy z generatora wycinano, komponowano, skalowano, przekształcano lub zapisywano ponownie.

## Pełne opisy generacji obrazów (prompty źródłowe, bez skrótów)

### P1 — generator ChatGPT

A polished, game-asset-style texture sheet presents four wooden door material sets in a dark charcoal grid with fine dividers, Polish labels, seamless 2×2 previews, albedo, height, and roughness maps, plus two stacked oak-door hardware reference photos on the right. The rows feature satin-finished golden oak, worn bottle-green painted oak, peeling cream-painted pine, and richly grained dark walnut, all rendered with crisp photoreal detail, consistent typography, and clearly marked 2048×2048 maps.

### P2 — generator ChatGPT

A polished, high-resolution documentary-style asset board for the “G03-v2” Lockwright update presents four photorealistic door-wood variants—satin-finished oak, distressed bottle-green oak, peeling cream-painted pine, and dark walnut—each arranged in Polish-labeled rows with Albedo, Height, Roughness, and 2×2 tiled previews on a charcoal background with refined serif typography and fine borders. A dedicated “Referencje (zdjęcia)” column adds two close-up oak door photographs featuring worn brass keyhole escutcheons, reinforcing the realistic, game-ready moodboard aesthetic without people or extraneous objects.

### P3 — generator ChatGPT

A polished, high-resolution presentation sheet for the G03-v2 door wood texture pack, arranged as a four-column grid on a dark charcoal background with cream serif-style typography, neat borders, and Polish labels. It features four detailed door finishes—satiny aged oak, distressed bottle-green paint, heavily peeling cream pine, and dark walnut—each paired with Albedo, Height, and Roughness maps, seamless 2×2 tiling previews, brass keyhole escutcheon references without tools, and a technical information panel listing 2048×2048 PNG maps, intended uses, and realistic G03 styling.

**Wspólny brief od użytkownika (`G03-v2.md`):** frontalna, płaska fotografia starego drewna drzwi, miękkie i równe światło, brak perspektywy i cieni, makrokadr 30–40 cm; warianty dąb lakierowany, zielony dąb olejny, kremowa łuszcząca się sosna, ciemny orzech; albedo / height / roughness 2048 px, bezszwowość i podgląd 2×2; dwie referencje dębowych drzwi z samym mosiężnym szyldem, bez narzędzi.

**Ważne:** specyfikacja briefu nie jest gwarancją faktycznie wygenerowanej rozdzielczości. Z planszy wycięto kadry tylko 213–380 px szerokości. Sam generator nie dostarczył osobnych fotografii w żądanej rozdzielczości.

## Rejestr nowych plików

W każdym wierszu: narzędzie, data, źródło z pełnym promptem powyżej, przekształcenie i fakt edycji. **Warunki:** wspólna sekcja „Narzędzie, warunki użycia” powyżej, dotyczy wszystkich wierszy.

| Nazwa pliku | Narzędzie | Data | Źródło / pełny prompt i opis operacji | Edytowany? |
|---|---|---|---|---|
| `sources/oak_satin_source_1.jpg` | ChatGPT images + Pillow | 2026-11-05 | P3 (pełny tekst w § P3); kadruj obszar **stary satynowy dąb / satin old oak** z planszy i zapisz JPEG | Tak — kadrowanie / eksport |
| `sources/oak_satin_source_2.jpg` | ChatGPT images + Pillow | 2026-11-05 | P1 (pełny tekst w § P1); kadruj obszar **stary satynowy dąb / satin old oak** z planszy i zapisz JPEG | Tak — kadrowanie / eksport |
| `sources/oak_satin_source_3.jpg` | ChatGPT images + Pillow | 2026-11-05 | P2 (pełny tekst w § P2); kadruj obszar **stary satynowy dąb / satin old oak** z planszy i zapisz JPEG | Tak — kadrowanie / eksport |
| `materials/oak_satin_albedo_2048.png` | ChatGPT images P1+P2+P3 → Python/NumPy/OpenCV/Pillow | 2026-11-05 | Z kadrów P1+P2+P3 wykonaj patch quilting (torus U/V), wyrównaj oświetlenie, lokalne wyostrzenie, domknij krawędzie; RGB PNG 2048×2048. Pełne prompty źródeł: § P1, P2 i P3. | Tak — rekonstrukcja |
| `materials/oak_satin_height_2048.png` | ChatGPT images P1+P2+P3 → Python/NumPy/OpenCV/Pillow | 2026-11-05 | Z albedo odtwórz grayscale height na podstawie lokalnego kontrastu i masek farby, 16-bit PNG (10-bit wartości); to NIE jest zmierzona geometria. Pełne prompty źródeł: § P1, P2 i P3. | Tak — rekonstrukcja |
| `materials/oak_satin_roughness_2048.png` | ChatGPT images P1+P2+P3 → Python/NumPy/OpenCV/Pillow | 2026-11-05 | Z albedo odtwórz roughness grayscale 8-bit; lakier niższa szorstkość, odsłonięte drewno wyższa, miejscowe łuski wzmocnione. Pełne prompty źródeł: § P1, P2 i P3. | Tak — rekonstrukcja |
| `previews/oak_satin_albedo_2x2.jpg` | Python/Pillow | 2026-11-05 | Powtórz 4× powstałe albedo **stary satynowy dąb / satin old oak** w siatce 2×2, tile 900×900, eksport JPEG. Źródła P1+P2+P3. | Tak — kompozycja |
| `sources/oak_bottle_green_source_1.jpg` | ChatGPT images + Pillow | 2026-11-05 | P3 (pełny tekst w § P3); kadruj obszar **dąb olejny butelkowa zieleń / bottle green oak** z planszy i zapisz JPEG | Tak — kadrowanie / eksport |
| `sources/oak_bottle_green_source_2.jpg` | ChatGPT images + Pillow | 2026-11-05 | P1 (pełny tekst w § P1); kadruj obszar **dąb olejny butelkowa zieleń / bottle green oak** z planszy i zapisz JPEG | Tak — kadrowanie / eksport |
| `sources/oak_bottle_green_source_3.jpg` | ChatGPT images + Pillow | 2026-11-05 | P2 (pełny tekst w § P2); kadruj obszar **dąb olejny butelkowa zieleń / bottle green oak** z planszy i zapisz JPEG | Tak — kadrowanie / eksport |
| `materials/oak_bottle_green_albedo_2048.png` | ChatGPT images P1+P2+P3 → Python/NumPy/OpenCV/Pillow | 2026-11-05 | Z kadrów P1+P2+P3 wykonaj patch quilting (torus U/V), wyrównaj oświetlenie, lokalne wyostrzenie, domknij krawędzie; RGB PNG 2048×2048. Pełne prompty źródeł: § P1, P2 i P3. | Tak — rekonstrukcja |
| `materials/oak_bottle_green_height_2048.png` | ChatGPT images P1+P2+P3 → Python/NumPy/OpenCV/Pillow | 2026-11-05 | Z albedo odtwórz grayscale height na podstawie lokalnego kontrastu i masek farby, 16-bit PNG (10-bit wartości); to NIE jest zmierzona geometria. Pełne prompty źródeł: § P1, P2 i P3. | Tak — rekonstrukcja |
| `materials/oak_bottle_green_roughness_2048.png` | ChatGPT images P1+P2+P3 → Python/NumPy/OpenCV/Pillow | 2026-11-05 | Z albedo odtwórz roughness grayscale 8-bit; lakier niższa szorstkość, odsłonięte drewno wyższa, miejscowe łuski wzmocnione. Pełne prompty źródeł: § P1, P2 i P3. | Tak — rekonstrukcja |
| `previews/oak_bottle_green_albedo_2x2.jpg` | Python/Pillow | 2026-11-05 | Powtórz 4× powstałe albedo **dąb olejny butelkowa zieleń / bottle green oak** w siatce 2×2, tile 900×900, eksport JPEG. Źródła P1+P2+P3. | Tak — kompozycja |
| `sources/pine_cream_source_1.jpg` | ChatGPT images + Pillow | 2026-11-05 | P3 (pełny tekst w § P3); kadruj obszar **sosna z łuszczącą się kremową farbą / peeling cream pine** z planszy i zapisz JPEG | Tak — kadrowanie / eksport |
| `sources/pine_cream_source_2.jpg` | ChatGPT images + Pillow | 2026-11-05 | P1 (pełny tekst w § P1); kadruj obszar **sosna z łuszczącą się kremową farbą / peeling cream pine** z planszy i zapisz JPEG | Tak — kadrowanie / eksport |
| `sources/pine_cream_source_3.jpg` | ChatGPT images + Pillow | 2026-11-05 | P2 (pełny tekst w § P2); kadruj obszar **sosna z łuszczącą się kremową farbą / peeling cream pine** z planszy i zapisz JPEG | Tak — kadrowanie / eksport |
| `materials/pine_cream_albedo_2048.png` | ChatGPT images P1+P2+P3 → Python/NumPy/OpenCV/Pillow | 2026-11-05 | Z kadrów P1+P2+P3 wykonaj patch quilting (torus U/V), wyrównaj oświetlenie, lokalne wyostrzenie, domknij krawędzie; RGB PNG 2048×2048. Pełne prompty źródeł: § P1, P2 i P3. | Tak — rekonstrukcja |
| `materials/pine_cream_height_2048.png` | ChatGPT images P1+P2+P3 → Python/NumPy/OpenCV/Pillow | 2026-11-05 | Z albedo odtwórz grayscale height na podstawie lokalnego kontrastu i masek farby, 16-bit PNG (10-bit wartości); to NIE jest zmierzona geometria. Pełne prompty źródeł: § P1, P2 i P3. | Tak — rekonstrukcja |
| `materials/pine_cream_roughness_2048.png` | ChatGPT images P1+P2+P3 → Python/NumPy/OpenCV/Pillow | 2026-11-05 | Z albedo odtwórz roughness grayscale 8-bit; lakier niższa szorstkość, odsłonięte drewno wyższa, miejscowe łuski wzmocnione. Pełne prompty źródeł: § P1, P2 i P3. | Tak — rekonstrukcja |
| `previews/pine_cream_albedo_2x2.jpg` | Python/Pillow | 2026-11-05 | Powtórz 4× powstałe albedo **sosna z łuszczącą się kremową farbą / peeling cream pine** w siatce 2×2, tile 900×900, eksport JPEG. Źródła P1+P2+P3. | Tak — kompozycja |
| `sources/walnut_dark_source_1.jpg` | ChatGPT images + Pillow | 2026-11-05 | P3 (pełny tekst w § P3); kadruj obszar **ciemny orzech / dark walnut** z planszy i zapisz JPEG | Tak — kadrowanie / eksport |
| `sources/walnut_dark_source_2.jpg` | ChatGPT images + Pillow | 2026-11-05 | P1 (pełny tekst w § P1); kadruj obszar **ciemny orzech / dark walnut** z planszy i zapisz JPEG | Tak — kadrowanie / eksport |
| `sources/walnut_dark_source_3.jpg` | ChatGPT images + Pillow | 2026-11-05 | P2 (pełny tekst w § P2); kadruj obszar **ciemny orzech / dark walnut** z planszy i zapisz JPEG | Tak — kadrowanie / eksport |
| `materials/walnut_dark_albedo_2048.png` | ChatGPT images P1+P2+P3 → Python/NumPy/OpenCV/Pillow | 2026-11-05 | Z kadrów P1+P2+P3 wykonaj patch quilting (torus U/V), wyrównaj oświetlenie, lokalne wyostrzenie, domknij krawędzie; RGB PNG 2048×2048. Pełne prompty źródeł: § P1, P2 i P3. | Tak — rekonstrukcja |
| `materials/walnut_dark_height_2048.png` | ChatGPT images P1+P2+P3 → Python/NumPy/OpenCV/Pillow | 2026-11-05 | Z albedo odtwórz grayscale height na podstawie lokalnego kontrastu i masek farby, 16-bit PNG (10-bit wartości); to NIE jest zmierzona geometria. Pełne prompty źródeł: § P1, P2 i P3. | Tak — rekonstrukcja |
| `materials/walnut_dark_roughness_2048.png` | ChatGPT images P1+P2+P3 → Python/NumPy/OpenCV/Pillow | 2026-11-05 | Z albedo odtwórz roughness grayscale 8-bit; lakier niższa szorstkość, odsłonięte drewno wyższa, miejscowe łuski wzmocnione. Pełne prompty źródeł: § P1, P2 i P3. | Tak — rekonstrukcja |
| `previews/walnut_dark_albedo_2x2.jpg` | Python/Pillow | 2026-11-05 | Powtórz 4× powstałe albedo **ciemny orzech / dark walnut** w siatce 2×2, tile 900×900, eksport JPEG. Źródła P1+P2+P3. | Tak — kompozycja |
| `references/reference_oak_brass_escutcheon_A.jpg` | ChatGPT images P2 + Pillow | 2026-11-05 | Pełny prompt źródłowy § P2; wytnij kadr starego dębu z mosiężnym szyldem (sam szyld, bez narzędzi), zachowaj oryginalne piksele, eksport JPEG. | Tak — kadrowanie |
| `references/reference_oak_brass_escutcheon_B.jpg` | ChatGPT images P2 + Pillow | 2026-11-05 | Pełny prompt źródłowy § P2; wytnij kadr starego dębu z mosiężnym szyldem (sam szyld, bez narzędzi), zachowaj oryginalne piksele, eksport JPEG. | Tak — kadrowanie |
| `previews/materials_overview_2x2.jpg` | Python/Pillow | 2026-11-05 | Ułóż cztery pomniejszone albedo w siatce 2×2 z podpisami PL/EN. Pełne prompty źródeł albedo P1+P2+P3. | Tak — kompozycja |
| `previews/pbr_overview.jpg` | Python/Pillow | 2026-11-05 | Ułóż wszystkie 4 warianty w tabeli Albedo/Height/Roughness; Height rozciągnij wyłącznie w podglądzie do 2–98 percentyla. Nie zmieniaj map źródłowych. Pełne prompty źródeł albedo P1+P2+P3. | Tak — kompozycja |

## Odwzorowalność i brak zewnętrznych materiałów

- Skrypt: `tools/build_v2.py`, wymaga `sources/`; seedy i rozmiary są w kodzie. Narzędzia i parametry dostępne bez korzystania z niedostępnych oryginalnych plansz.
- `QA.json` potwierdza pikselową zgodność krawędzi, lecz nie dowodzi wysokiej jakości detali 1:1.
- Źródłowe plansze P1–P3 nie zostały włączone w ZIP, ponieważ ich istotne kadry znajdują się już w `sources/`; pełne prompty oraz wymiary generacji podano powyżej.
- Nie kopiowano obcych gier, marek, logotypów ani banków tekstur. Samo podobieństwo wygenerowanych fotografii nie gwarantuje wyłączności.
