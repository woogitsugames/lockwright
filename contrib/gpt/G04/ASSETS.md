# ASSETS — G04 / Pochodzenie zasobów

Data: **2026-11-05**. Nie korzystano z pobranych fotografii, materiałów stockowych ani znaków firmowych. Grafiki pochodzą z wygenerowanej w ChatGPT planszy referencyjnej, zostały wykadrowane, wyprostowane, w razie potrzeby uzupełnione i wyrenderowane do wymaganych formatów.

**Narzędzia:** natywne generowanie obrazów ChatGPT (`image_gen`), Python 3 (`Pillow`, `NumPy`, `OpenCV`) do kadrowania, usuwania wpływu światła, periodycznej korekty krawędzi (rozwiązanie równania Poissona FFT), uzupełnienia ziarna, maskowania przezroczystości i przygotowania podglądów. Nie używano generatorów obrazów osób ani znaków firmowych.

**Warunki użycia:** obrazy wygenerowano na potrzeby zlecenia właściciela projektu; używanie i prawa do wygenerowanych wyników podlegają aktualnym warunkom usług OpenAI (https://openai.com/policies/terms-of-use/), a elementy stworzone przez użytkownika/program na jego zlecenie mogą być wykorzystywane w projekcie zgodnie z tymi warunkami. Nie dołączono zasobów z odrębnymi licencjami stockowymi; brak gwarancji wyłączności podobnych wyników generatywnych. Nie są to fotografie rzeczywistych marek.

# Pełny brief / full contextual image-generation prompt

> Lockwright (PL: Lockwright: Pogotowie Zamkowe; EN: Lockwright: Locksmith on Call) to mobilna premium gra iOS/Android w Godot 4.7. Ślusarz legalnie pomaga osobom zatrzaśniętym za drzwiami starej kamienicy; wygląd maksymalnie fotorealistyczny, ciepła żarówka na klatce schodowej i chłodne światło z okna, interfejs diegetyczny. Bez estetyki złodzieja, bez nazw i marek producentów, bez logotypów, bez portretów prawdziwych osób, bez teal-orange, fioletowo-niebieskich gradientów, bloom, chromu, steampunku i sztucznego stylu stockowego. Materiały: (1) olejna lamperia w butelkowej zieleni, ochrze i wiśniowym brązie, wysokość ~150 cm, fizyczne otarcia, odpryski i odcięcie od tynku, (2) biało-kremowy wapienny tynk z rysami i zabrudzeniami, (3) cienka ciemniejsza linia odcięcia jako osobny powtarzalny detal, (4) stara niemarkowa skrzynka elektryczna, (5) czarny bakelitowy włącznik światła na minutnik z okrągłym przyciskiem. Albedo 2048×2048, bezszwowo powtarzalne; obiekty PNG 1024×1024 z kanałem alfa; do tego podglądy 2×2. Kolory naturalne i stonowane, brak tekstów firmowych.

**Transparentność informacji o generowaniu:** użyto natywnego generatora obrazów ChatGPT (`image_gen`) z automatycznym skonstruowaniem promptu z kontekstu powyższego briefu. Zwrócone metadane `gen_id=c0594956-e3e5-4a83-abac-9e6bc9ce4104` zawierały pole `prompt` puste; narzędzie nie ujawniło dokładnego wewnętrznego sformułowania promptu. Powyżej zapisano **pełny brief użytkownika wykorzystany jako kontekst**, a nie rzekomo odtworzony ukryty prompt systemowy.

## Rejestr każdego pliku

Każdy poniższy plik ma źródłowy pełny brief podany powyżej; kolumna „Dodatkowy kontekst” wskazuje konkretny wycinek i obróbkę. Data oraz warunki użycia są wspólne dla każdego wpisu: **2026-11-05, warunki OpenAI opisane powyżej**. Status edycji **TAK** dla wszystkich plików.

| Plik | Narzędzie / pochodzenie | Dodatkowy kontekst (wycinek, transformacje, edycja) | Edytowany |
|---|---|---|---|
| `objects/bakelite_timer_switch_rgba_1024.png` | ChatGPT `image_gen` + Python (`Pillow`, `NumPy`, `OpenCV`) | Source `image_gen` (pierwsza plansza), wycięty czarny bakelitowy przycisk; maska okrągła, usunięcie tła szachownicowego, alfa, skala i centrowanie, PNG 1024². | TAK |
| `objects/electrical_box_rgba_1024.png` | ChatGPT `image_gen` + Python (`Pillow`, `NumPy`, `OpenCV`) | Source `image_gen` (pierwsza plansza), wycięta stara skrzynka metalowa; niezależny, ręcznie wyznaczony kontur, usunięcie atrap tła szachownicowego, alfa, skala i centrowanie, PNG 1024². | TAK |
| `previews/stairwell_variants_overview_2x2.png` | Python `Pillow`, na bazie materiałów G04 z `image_gen` | `Pillow`: cztery warianty przykładowej ściany, warstwy tynku/pasa/lamperii, w czwartym oba obiekty, wynik 1024². | TAK |
| `previews/tile_lime_plaster_cream_2x2.png` | Python `Pillow`, na bazie materiałów G04 z `image_gen` | `Pillow`: czterokrotne powielenie 512×512 materiału `lime_plaster_cream` bez dodawania obcych obrazów, wynik 1024². | TAK |
| `previews/tile_paint_divider_band_2x2.png` | Python `Pillow`, na bazie materiałów G04 z `image_gen` | `Pillow`: czterokrotne powielenie 512×512 materiału `paint_divider_band` bez dodawania obcych obrazów, wynik 1024². | TAK |
| `previews/tile_wainscot_bottle_green_2x2.png` | Python `Pillow`, na bazie materiałów G04 z `image_gen` | `Pillow`: czterokrotne powielenie 512×512 materiału `wainscot_bottle_green` bez dodawania obcych obrazów, wynik 1024². | TAK |
| `previews/tile_wainscot_cherry_brown_2x2.png` | Python `Pillow`, na bazie materiałów G04 z `image_gen` | `Pillow`: czterokrotne powielenie 512×512 materiału `wainscot_cherry_brown` bez dodawania obcych obrazów, wynik 1024². | TAK |
| `previews/tile_wainscot_ochre_2x2.png` | Python `Pillow`, na bazie materiałów G04 z `image_gen` | `Pillow`: czterokrotne powielenie 512×512 materiału `wainscot_ochre` bez dodawania obcych obrazów, wynik 1024². | TAK |
| `textures/lime_plaster_cream_albedo_2048.jpg` | ChatGPT `image_gen` + Python (`Pillow`, `NumPy`, `OpenCV`) | Source `image_gen` (pierwsza plansza), stary wapienny biało-kremowy tynk; kadrowanie obrazu, korekta oświetlenia i bezszwowości, mikroziarno, JPEG RGB 2048². | TAK |
| `textures/paint_divider_band_albedo_2048.jpg` | ChatGPT `image_gen` + Python (`Pillow`, `NumPy`, `OpenCV`) | Source `image_gen` (pierwsza plansza), środkowy wąski pas ciemnej farby wyodrębniony z krawędzi lamperii, skomponowany na powtarzalnym tynku, 2048². | TAK |
| `textures/wainscot_bottle_green_albedo_2048.jpg` | ChatGPT `image_gen` + Python (`Pillow`, `NumPy`, `OpenCV`) | Source `image_gen` (pierwsza plansza), lamperia butelkowa zieleń; kadrowanie obrazu, korekta oświetlenia i bezszwowości, mikroziarno, JPEG RGB 2048². | TAK |
| `textures/wainscot_cherry_brown_albedo_2048.jpg` | ChatGPT `image_gen` + Python (`Pillow`, `NumPy`, `OpenCV`) | Source `image_gen` (pierwsza plansza), wiśniowo-brązowa lamperia; kadrowanie obrazu, korekta oświetlenia i bezszwowości, mikroziarno, JPEG RGB 2048². | TAK |
| `textures/wainscot_ochre_albedo_2048.jpg` | ChatGPT `image_gen` + Python (`Pillow`, `NumPy`, `OpenCV`) | Source `image_gen` (pierwsza plansza), lamperia ochrowa; kadrowanie obrazu, korekta oświetlenia i bezszwowości, mikroziarno, JPEG RGB 2048². | TAK |

## Ślad integralności

SHA-256 poniżej umożliwia porównanie bajtów z wersją przygotowaną w tej sesji. Metadane wytworzenia plików są w tym dokumencie, nie w nagłówkach plików graficznych.

| Plik | SHA-256 |
|---|---|
| `objects/bakelite_timer_switch_rgba_1024.png` | `00938fcfba7274e7fffaa59ac20269135a21ca7142292fe27294e67959d9c2c3` |
| `objects/electrical_box_rgba_1024.png` | `ca1e548d5f1ae73201aa91088cb9fabd427b74b0193a27e5e8a0427a49806d31` |
| `previews/stairwell_variants_overview_2x2.png` | `d7135abd86373435f2e449f54e2a3f8a0e481163c262a7caf1a5d8bd31189626` |
| `previews/tile_lime_plaster_cream_2x2.png` | `7b1d20cb7f309cda09741fcf9755882a7f0482bfc52fa7d5611b7dd6d0c2ad73` |
| `previews/tile_paint_divider_band_2x2.png` | `9223fd73d8cc1e31098ec947cd0eea8ab5fa93b05e7f70a64063752c21adcb01` |
| `previews/tile_wainscot_bottle_green_2x2.png` | `0b905d0ea32f0a74526bbb9de8d6fca41d53ebc3099262dd7f9d07fecb1ecf3b` |
| `previews/tile_wainscot_cherry_brown_2x2.png` | `2959a77e76d7f7a258323260f05bc03215ccbff1413922d457232d565d059c0d` |
| `previews/tile_wainscot_ochre_2x2.png` | `bca8058eb5fc0bcff815f12fb26b5153325033f2fc212c61345896e5e74ea892` |
| `textures/lime_plaster_cream_albedo_2048.jpg` | `baba7c0f093c4544a138860996882dab09b64d9486e54a86ad20da2838a380c7` |
| `textures/paint_divider_band_albedo_2048.jpg` | `d4308b30d1a9677cec6e43a539ee416ea7018b9df2c3a2918bdbaa39ab374be1` |
| `textures/wainscot_bottle_green_albedo_2048.jpg` | `3dfafe9767a7dd880835d924c8ff60106b2b3c93339cb7b553e54e5ad841c4c2` |
| `textures/wainscot_cherry_brown_albedo_2048.jpg` | `2de5526692b64c32098f8cdd4c28885f110dc9847ef8bea31556dcb9df50ae14` |
| `textures/wainscot_ochre_albedo_2048.jpg` | `3ca86e3a3481327140727fa469de4b89e11e55b352902922743b66a27abe09cd` |
