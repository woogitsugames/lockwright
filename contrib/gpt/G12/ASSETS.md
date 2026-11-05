# G12 — rejestr zasobów / Asset manifest

**Data / Date:** 2026-11-05  
**Narzędzie / Tool:** Python 3, NumPy, Pillow, `generate_icons.py` (proceduralne rysowanie kodem).  
**Pochodzenie / Provenance:** wszystkie ilustracje i warstwy stworzone od zera algorytmicznie; bez pobranych zdjęć, tekstur lub logotypów. Czcionki Noto Serif / Noto Sans służą tylko do rasteryzacji liter i podpisów i nie są dołączone (SIL Open Font License).

**Licencja/warunki / Rights:** oryginalna grafika proceduralna wygenerowana na potrzeby użytkownika; jej wykorzystanie podlega odpowiednim warunkom korzystania z OpenAI. Brak zewnętrznych licencji stockowych lub cudzych assetów. Nie deklarujemy CC0 ani przeniesienia praw od osób trzecich.

## Wspólny, pełny brief/prompt / Common full prompt

> Stwórz oryginalną, półrealistyczną ikonę 1024×1024 do spokojnej gry o legalnym pogotowiu ślusarskim w starej kamienicy. Przedmiot ma być samodzielny, duży, czytelny w 48×48, bez postaci, bez nazw i znaków firm, bez demonstracji otwierania drzwi, bez neonów, błyszczącego chromu, fioletowo-niebieskiego i turkusowo-pomarańczowego przejścia barw, bez bankowych paneli UI. Oświetlenie ciepłe z górnego lewego rogu, miękkie cienie, materiałowe mikroślady użytkowania. Styl proceduralny półrealistyczny, nie fotografia.

Każdy wariant dziedziczy **pełny brief powyżej** i otrzymuje poniższy szczegółowy prompt. Format i dalsze przekształcenia: RGB PNG 1024×1024, pasek pięciu podglądów (180, 120, 60, 48, 29), Android adaptive foreground 432×432 z kanałem alfa i tło 432×432 RGB. Cienie i faktury są rysowane matematycznie, nie generowane z cudzych fotografii.

## Wykaz plików i promptów

### 01 — Tabliczka emaliowana „L” / Enamel L plate
**Pełny prompt szczegółowy:** ivory enamel, navy serif L, worn dark-blue edge, four old screws. Kompozycja kwadratowa, przedmiot w centrum, bez napisów reklamowych. Tło materiałowe: `navy`. Elementy drobne są podrzędne wobec sylwetki głównego przedmiotu.
**Pliki / Files (4):** `ios/01_enamel_l_1024.png`, `previews/01_enamel_l_sizes.png`, `android/01_enamel_l_foreground_432.png`, `android/01_enamel_l_background_432.png`.
**Narzędzie:** `generate_icons.py` (Pillow i NumPy), wariant proceduralny. **Data:** 2026-11-05. **Warunki:** jak wyżej. **Edytowany:** tak — kompozycja, skala, rasteryzacja, obróbka antialiasingowa i osobne wersje platformowe generowane skryptem; bez ręcznego retuszu.

### 02 — Czoło wkładki / Brass cylinder face
**Pełny prompt szczegółowy:** satiny brass concentric face, imagined geometric central slot, wood. Kompozycja kwadratowa, przedmiot w centrum, bez napisów reklamowych. Tło materiałowe: `wood`. Elementy drobne są podrzędne wobec sylwetki głównego przedmiotu.
**Pliki / Files (4):** `ios/02_brass_cylinder_1024.png`, `previews/02_brass_cylinder_sizes.png`, `android/02_brass_cylinder_foreground_432.png`, `android/02_brass_cylinder_background_432.png`.
**Narzędzie:** `generate_icons.py` (Pillow i NumPy), wariant proceduralny. **Data:** 2026-11-05. **Warunki:** jak wyżej. **Edytowany:** tak — kompozycja, skala, rasteryzacja, obróbka antialiasingowa i osobne wersje platformowe generowane skryptem; bez ręcznego retuszu.

### 03 — Zwijka skórzana / Closed leather tool roll
**Pełny prompt szczegółowy:** closed brown leather roll, neat stitching, large brass snap. Kompozycja kwadratowa, przedmiot w centrum, bez napisów reklamowych. Tło materiałowe: `linen`. Elementy drobne są podrzędne wobec sylwetki głównego przedmiotu.
**Pliki / Files (4):** `ios/03_leather_roll_1024.png`, `previews/03_leather_roll_sizes.png`, `android/03_leather_roll_foreground_432.png`, `android/03_leather_roll_background_432.png`.
**Narzędzie:** `generate_icons.py` (Pillow i NumPy), wariant proceduralny. **Data:** 2026-11-05. **Warunki:** jak wyżej. **Edytowany:** tak — kompozycja, skala, rasteryzacja, obróbka antialiasingowa i osobne wersje platformowe generowane skryptem; bez ręcznego retuszu.

### 04 — Stary klucz / Old key
**Pełny prompt szczegółowy:** single silver antique invented key lying diagonally on leather. Kompozycja kwadratowa, przedmiot w centrum, bez napisów reklamowych. Tło materiałowe: `leather`. Elementy drobne są podrzędne wobec sylwetki głównego przedmiotu.
**Pliki / Files (4):** `ios/04_old_key_1024.png`, `previews/04_old_key_sizes.png`, `android/04_old_key_foreground_432.png`, `android/04_old_key_background_432.png`.
**Narzędzie:** `generate_icons.py` (Pillow i NumPy), wariant proceduralny. **Data:** 2026-11-05. **Warunki:** jak wyżej. **Edytowany:** tak — kompozycja, skala, rasteryzacja, obróbka antialiasingowa i osobne wersje platformowe generowane skryptem; bez ręcznego retuszu.

### 05 — Dzwonek do mieszkania / Apartment doorbell
**Pełny prompt szczegółowy:** big ivory pushbutton and patinated brass bezel on green wood. Kompozycja kwadratowa, przedmiot w centrum, bez napisów reklamowych. Tło materiałowe: `green`. Elementy drobne są podrzędne wobec sylwetki głównego przedmiotu.
**Pliki / Files (4):** `ios/05_doorbell_1024.png`, `previews/05_doorbell_sizes.png`, `android/05_doorbell_foreground_432.png`, `android/05_doorbell_background_432.png`.
**Narzędzie:** `generate_icons.py` (Pillow i NumPy), wariant proceduralny. **Data:** 2026-11-05. **Warunki:** jak wyżej. **Edytowany:** tak — kompozycja, skala, rasteryzacja, obróbka antialiasingowa i osobne wersje platformowe generowane skryptem; bez ręcznego retuszu.

### 06 — Tabliczka z numerem 12 / Number 12 plate
**Pełny prompt szczegółowy:** cream ceramic 12 plate with navy border and screws on green paint. Kompozycja kwadratowa, przedmiot w centrum, bez napisów reklamowych. Tło materiałowe: `green`. Elementy drobne są podrzędne wobec sylwetki głównego przedmiotu.
**Pliki / Files (4):** `ios/06_number_plate_1024.png`, `previews/06_number_plate_sizes.png`, `android/06_number_plate_foreground_432.png`, `android/06_number_plate_background_432.png`.
**Narzędzie:** `generate_icons.py` (Pillow i NumPy), wariant proceduralny. **Data:** 2026-11-05. **Warunki:** jak wyżej. **Edytowany:** tak — kompozycja, skala, rasteryzacja, obróbka antialiasingowa i osobne wersje platformowe generowane skryptem; bez ręcznego retuszu.

### 07 — Wkładka z podziałką / Cylinder and dial
**Pełny prompt szczegółowy:** brass cylinder inside scaled industrial brass faceplate. Kompozycja kwadratowa, przedmiot w centrum, bez napisów reklamowych. Tło materiałowe: `plaster`. Elementy drobne są podrzędne wobec sylwetki głównego przedmiotu.
**Pliki / Files (4):** `ios/07_dial_cylinder_1024.png`, `previews/07_dial_cylinder_sizes.png`, `android/07_dial_cylinder_foreground_432.png`, `android/07_dial_cylinder_background_432.png`.
**Narzędzie:** `generate_icons.py` (Pillow i NumPy), wariant proceduralny. **Data:** 2026-11-05. **Warunki:** jak wyżej. **Edytowany:** tak — kompozycja, skala, rasteryzacja, obróbka antialiasingowa i osobne wersje platformowe generowane skryptem; bez ręcznego retuszu.

### 08 — Drzwi kamienicy / Tenement door
**Pełny prompt szczegółowy:** solid old oak door with inlaid panels and warm transom light. Kompozycja kwadratowa, przedmiot w centrum, bez napisów reklamowych. Tło materiałowe: `plaster`. Elementy drobne są podrzędne wobec sylwetki głównego przedmiotu.
**Pliki / Files (4):** `ios/08_tenement_door_1024.png`, `previews/08_tenement_door_sizes.png`, `android/08_tenement_door_foreground_432.png`, `android/08_tenement_door_background_432.png`.
**Narzędzie:** `generate_icons.py` (Pillow i NumPy), wariant proceduralny. **Data:** 2026-11-05. **Warunki:** jak wyżej. **Edytowany:** tak — kompozycja, skala, rasteryzacja, obróbka antialiasingowa i osobne wersje platformowe generowane skryptem; bez ręcznego retuszu.

### 09 — Klamka z szyldem / Door handle and plate
**Pełny prompt szczegółowy:** large curved worn brass door handle on oak door. Kompozycja kwadratowa, przedmiot w centrum, bez napisów reklamowych. Tło materiałowe: `wood`. Elementy drobne są podrzędne wobec sylwetki głównego przedmiotu.
**Pliki / Files (4):** `ios/09_door_handle_1024.png`, `previews/09_door_handle_sizes.png`, `android/09_door_handle_foreground_432.png`, `android/09_door_handle_background_432.png`.
**Narzędzie:** `generate_icons.py` (Pillow i NumPy), wariant proceduralny. **Data:** 2026-11-05. **Warunki:** jak wyżej. **Edytowany:** tak — kompozycja, skala, rasteryzacja, obróbka antialiasingowa i osobne wersje platformowe generowane skryptem; bez ręcznego retuszu.

### 10 — Lampa warsztatowa / Workshop lamp
**Pełny prompt szczegółowy:** dark green anglepoise lamp shining on quiet timber workbench. Kompozycja kwadratowa, przedmiot w centrum, bez napisów reklamowych. Tło materiałowe: `workshop`. Elementy drobne są podrzędne wobec sylwetki głównego przedmiotu.
**Pliki / Files (4):** `ios/10_workshop_lamp_1024.png`, `previews/10_workshop_lamp_sizes.png`, `android/10_workshop_lamp_foreground_432.png`, `android/10_workshop_lamp_background_432.png`.
**Narzędzie:** `generate_icons.py` (Pillow i NumPy), wariant proceduralny. **Data:** 2026-11-05. **Warunki:** jak wyżej. **Edytowany:** tak — kompozycja, skala, rasteryzacja, obróbka antialiasingowa i osobne wersje platformowe generowane skryptem; bez ręcznego retuszu.

### 11 — Pęk kluczy / Keys on a ring
**Pełny prompt szczegółowy:** large ring and three distinct invented steel and brass keys. Kompozycja kwadratowa, przedmiot w centrum, bez napisów reklamowych. Tło materiałowe: `leather`. Elementy drobne są podrzędne wobec sylwetki głównego przedmiotu.
**Pliki / Files (4):** `ios/11_key_ring_1024.png`, `previews/11_key_ring_sizes.png`, `android/11_key_ring_foreground_432.png`, `android/11_key_ring_background_432.png`.
**Narzędzie:** `generate_icons.py` (Pillow i NumPy), wariant proceduralny. **Data:** 2026-11-05. **Warunki:** jak wyżej. **Edytowany:** tak — kompozycja, skala, rasteryzacja, obróbka antialiasingowa i osobne wersje platformowe generowane skryptem; bez ręcznego retuszu.

### 12 — Fasada kamienicy / Tenement facade
**Pełny prompt szczegółowy:** close-up of cream tenement bay with sage window and stone cornice. Kompozycja kwadratowa, przedmiot w centrum, bez napisów reklamowych. Tło materiałowe: `daylight`. Elementy drobne są podrzędne wobec sylwetki głównego przedmiotu.
**Pliki / Files (4):** `ios/12_facade_1024.png`, `previews/12_facade_sizes.png`, `android/12_facade_foreground_432.png`, `android/12_facade_background_432.png`.
**Narzędzie:** `generate_icons.py` (Pillow i NumPy), wariant proceduralny. **Data:** 2026-11-05. **Warunki:** jak wyżej. **Edytowany:** tak — kompozycja, skala, rasteryzacja, obróbka antialiasingowa i osobne wersje platformowe generowane skryptem; bez ręcznego retuszu.

## Pozostałe zasoby

- `previews/contact_sheet.png`: 12 oryginalnych wariantów na jednej planszy PL/EN; narzędzie: Pillow; data 2026-11-05; prompt: „Zestaw 12 finalnych ikon w czytelnej planszy porównawczej 4×3, podpisy po polsku i angielsku, miniatury 48 px, rekomendacja 01/02/03”; przerobiony: tak, skład i podpisy; warunki jak wyżej.
- `generate_icons.py`, `validate.py` — kod źródłowy i testy; nie są plikami graficznymi.

**Uwagi:** wygenerowana w rozmowie tablica inspiracyjna ChatGPT nie jest dołączona do finalnego repozytorium ani do tego rejestru, bo nie jest źródłem binarnych eksportów.
