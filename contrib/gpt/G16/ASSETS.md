# ASSETS — G16

**Data:** 2026-11-05. **Narzędzie:** natywny generator obrazów ChatGPT (OpenAI), plus lokalna edycja Python/Pillow/OpenCV.
**Pochodzenie:** oryginalne grafiki syntetyczne wykonane do Lockwright. Bez używania fotografii ze stron WWW, zewnętrznych marek i portretów.

## Opis generacji i pełna informacja o promptach

W wywołaniach generatora nie przekazywano ręcznie tekstu `prompt` (parametr null); zwrócone metadane mają `prompt: ""`. Usługa dostosowała obraz na podstawie treści zlecenia i dokumentów kontekstowych. **Pełnego wewnętrznego promptu nie da się odzyskać; nie przypisujemy generatorowi zmyślonego promptu.** Poniżej zapisano pełne opisy obu generacji udostępnione wraz z wynikiem, identyfikator generacji oraz brief wejściowy (jako odnośnik do G16 i `docs/SHOWCASE.md`).

### Generacja A

- **Gen ID:** `972996b6-9818-4158-95df-a14fdeeb605a`
- **Plik źródłowy:** `sheets/source_collage_1.jpg` (konwersja oryginalnego PNG).
- **Tekst opisu wyniku:**

> A museum-style, photorealistic showcase collage for the Lockwright project (G16) combines 20 numbered photographs of historic and mechanical locks with three supporting assets: a bilingual “Eksponat / Exhibit” label card and empty landscape and portrait display-case backgrounds. Arranged in a clean infographic grid, the warm cinematic presentation features burgundy velvet, aged brass and iron, wood trim, glass reflections, shallow depth of field, detailed lock mechanisms, and clear white numbering, with no people shown.

### Generacja B

- **Gen ID:** `e698a81a-2684-41be-8d0c-f97a6249ed46`
- **Plik źródłowy:** `sheets/source_collage_2.jpg` (konwersja oryginalnego PNG).
- **Tekst opisu wyniku:**

> A polished, museum-style contact sheet showcases 20 photorealistic “Lockwright” lock exhibits in a 5×4 grid, each labeled with a filename, followed by a blank bilingual exhibit card and horizontal/vertical empty display-case backgrounds. Warm lighting, red velvet, wood-and-glass cases, and detailed brass, iron, and wooden mechanisms create a refined historical ambience with no people present.

### Warunki i prawa

- **Warunki:** OpenAI Terms of Use: https://openai.com/policies/terms-of-use/ oraz Service Terms, stosownie do planu konta. Gdy przepisy i warunki na to pozwalają, użytkownik otrzymuje prawa do Output; rezultat generacji może nie być wyłączny. Nie jest to zewnętrzna licencja typu CC0.
- **Wykorzystanie:** komercyjne w ramach gry, po ręcznej kontroli jakości i ewentualnych praw osób trzecich. Nie zakładać weryfikowalnej autentyczności historycznej.
- **Obróbka:** Pillow (kadrowanie, skalowanie LANCZOS, JPEG, arkusz zbiorczy), OpenCV (usuwanie numerów w generacji A); ujęcie AMEN retusz liter w miejsce cyfr; źródła A/B zapisano osobno.

## Rejestr plików

| Plik | Narzędzie i źródło | Data | Edytowany | Uwagi / prompty |
|---|---|---|---|---|
| `photos/01_khorsabad_gate.jpg` | ChatGPT ImageGen (B, panel 5) + Pillow/OpenCV | 2026-11-05 | Tak | Pełny opis generacji B wyżej; Drewniany rygiel z pionowymi kołkami / wooden bolt with drop pins |
| `photos/02_egyptian_name.jpg` | ChatGPT ImageGen (A, panel 4) + Pillow/OpenCV | 2026-11-05 | Tak | Pełny opis generacji A wyżej; Drewniany zamek kołkowy w rekonstrukcji / wooden pin lock reconstruction |
| `photos/03_roman_ring_key.jpg` | ChatGPT ImageGen (A, panel 2) + Pillow/OpenCV | 2026-11-05 | Tak | Pełny opis generacji A wyżej; Stary klucz z małym uchwytem na pierścień / Roman-style ring-key study (symbolic) |
| `photos/04_roman_wards.jpg` | ChatGPT ImageGen (B, panel 8) + Pillow/OpenCV | 2026-11-05 | Tak | Pełny opis generacji B wyżej; Zamek zapadkowy z kluczem / warded lock and key |
| `photos/05_amen_padlock.jpg` | ChatGPT ImageGen (B, panel 4) + Pillow/OpenCV | 2026-11-05 | Tak | Retusz cyfr na litery AMEN; Pełny opis generacji B wyżej; Pierścieniowa kłódka szyfrowa / ring combination padlock (numbers, not historical letters) |
| `photos/06_barron_1778.jpg` | ChatGPT ImageGen (B, panel 6) + Pillow/OpenCV | 2026-11-05 | Tak | Pełny opis generacji B wyżej; Wczesny dwudźwigniowy zamek w przekroju / twin-lever lock |
| `photos/07_chubb_detector.jpg` | ChatGPT ImageGen (A, panel 7) + Pillow/OpenCV | 2026-11-05 | Tak | Pełny opis generacji A wyżej; Mechanizm dźwigni i zapadki detektora / lever with detector-like pawl |
| `photos/08_hobbs_westminster.jpg` | ChatGPT ImageGen (B, panel 18) + Pillow/OpenCV | 2026-11-05 | Tak | Pełny opis generacji B wyżej; Otwarta skrzynka z mechanizmem dźwigniowym / lever lock cutaway |
| `photos/09_bramah_window.jpg` | ChatGPT ImageGen (B, panel 14) + Pillow/OpenCV | 2026-11-05 | Tak | Pełny opis generacji B wyżej; Mechanizm o kluczu rurkowym / tube-key lock (conceptual) |
| `photos/10_hobbs_51_hours.jpg` | ChatGPT ImageGen (B, panel 13) + Pillow/OpenCV | 2026-11-05 | Tak | Pełny opis generacji B wyżej; Kłódka w przekroju / cutaway padlock |
| `photos/11_stansbury_1805.jpg` | ChatGPT ImageGen (A, panel 1) + Pillow/OpenCV | 2026-11-05 | Tak | Pełny opis generacji A wyżej; Obracany bęben z pionowymi kołkami / pin mechanism |
| `photos/12_yale_senior.jpg` | ChatGPT ImageGen (B, panel 19) + Pillow/OpenCV | 2026-11-05 | Tak | Pełny opis generacji B wyżej; Sprężynujące kołki w korpusie / spring-pin cylinder |
| `photos/13_yale_flat_key.jpg` | ChatGPT ImageGen (B, panel 1) + Pillow/OpenCV | 2026-11-05 | Tak | Pełny opis generacji B wyżej; Miniaturowa wkładka bębenkowa w przekroju / compact cylinder cutaway |
| `photos/14_yale_dial.jpg` | ChatGPT ImageGen (A, panel 18) + Pillow/OpenCV | 2026-11-05 | Tak | Pełny opis generacji A wyżej; Okrągła tarcza szyfrowa sejfu / circular safe dial |
| `photos/15_sargent_time_lock.jpg` | ChatGPT ImageGen (A, panel 16) + Pillow/OpenCV | 2026-11-05 | Tak | Pełny opis generacji A wyżej; Mechanizm zegarowy i rygiel / clockwork and bolt |
| `photos/16_henriksson_disc.jpg` | ChatGPT ImageGen (B, panel 10) + Pillow/OpenCV | 2026-11-05 | Tak | Pełny opis generacji B wyżej; Stos obracanych dysków / rotating disc stack |
| `photos/17_swiatniki_armourers.jpg` | ChatGPT ImageGen (B, panel 3) + Pillow/OpenCV | 2026-11-05 | Tak | Pełny opis generacji B wyżej; Kuta kłódka żelazna / forged iron padlock |
| `photos/18_swiatniki_school.jpg` | ChatGPT ImageGen (B, panel 12) + Pillow/OpenCV | 2026-11-05 | Tak | Pełny opis generacji B wyżej; Dekorowany zamek skrzynkowy / decorated box lock |
| `photos/19_krakow_guild_seal.jpg` | ChatGPT ImageGen (B, panel 16) + Pillow/OpenCV | 2026-11-05 | Tak | Pełny opis generacji B wyżej; Otwarty kuty zamek bramowy / forged gate lock cutaway (no guild crest) |
| `photos/20_wroclaw_iron_world.jpg` | ChatGPT ImageGen (A, panel 3) + Pillow/OpenCV | 2026-11-05 | Tak | Pełny opis generacji A wyżej; Zamek skrzynkowy o dźwigniowym ryglu / iron box lock (unsigned reconstruction) |
| `props/exhibit_card_blank_pl_en.png` | ChatGPT ImageGen (B) + Pillow | 2026-11-05 | Tak | Etykieta z nagłówkami PL/EN, pozostała część pusta; kadrowanie i skalowanie. Pełne opisy źródeł A/B wyżej. |
| `props/showcase_empty_landscape.jpg` | ChatGPT ImageGen (B) + Pillow | 2026-11-05 | Tak | Pozioma gablota; kadrowanie i skalowanie, usunięty podpis automatyczny. Pełne opisy źródeł A/B wyżej. |
| `props/showcase_empty_portrait.jpg` | ChatGPT ImageGen (B) + Pillow | 2026-11-05 | Tak | Pionowe tło; kadrowanie i skalowanie, usunięty podpis automatyczny. Pełne opisy źródeł A/B wyżej. |
| `sheets/contact_sheet_g16.jpg` | ChatGPT ImageGen (A+B) + Pillow | 2026-11-05 | Tak | Nowy arkusz 5×4 z 20 kadrami i identyfikatorami. Pełne opisy źródeł A/B wyżej. |
| `sheets/source_collage_1.jpg` | ChatGPT ImageGen (A) + Pillow | 2026-11-05 | Tak | Bez retuszu scen, przekodowanie PNG→JPEG. Pełne opisy źródeł A/B wyżej. |
| `sheets/source_collage_2.jpg` | ChatGPT ImageGen (B) + Pillow | 2026-11-05 | Tak | Bez retuszu scen, przekodowanie PNG→JPEG. Pełne opisy źródeł A/B wyżej. |

**Manifest:** `manifest.json` zawiera mapping PL/EN z `docs/SHOWCASE.md`, identyfikator obrazu źródłowego, numer pola i sumę kontrolną dla 20 zdjęć.
