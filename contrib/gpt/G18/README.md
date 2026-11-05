# G18 — trzy kadry samouczka Henryka

**Data:** 2026-11-05  
**Zakres:** `contrib/gpt/G18/`; mechanizm wymyślony, trzy uproszczone komory, bez marek, bez napisów wewnątrz PNG.

## Oddane

| Kadr | Papier w kratkę | Przezroczysty rysunek | Pokazywany gest |
|---|---|---|---|
| Napięcie | `frame_1_tension.png` | `frame_1_tension_alpha.png` | Lewy kciuk w górę, łuk małego obrotu rdzenia |
| Uniesienie | `frame_2_lift.png` | `frame_2_lift_alpha.png` | Prawy kciuk w górę, strzałka boczna, wybrany środkowy kołek |
| Klik | `frame_3_click.png` | `frame_3_click_alpha.png` | Osadzenie kołka przy linii podziału, trzy kreski promieniste, mały obrót |

Dodatkowo: `contact_sheet.jpg` (wszystkie 6 wariantów), `source/graph_paper_chatgpt.png` (oryginalna, pusta faktura papieru), `generate.py` (precyzyjne, deterministyczne nakładanie rysunku), `ASSETS.md` (pochodzenie materiałów).

## Technika i integracja

Każdy obraz ma **1080×1080**, PNG RGBA z profilem ICC sRGB, 8 bitów na kanał. Wersje z papierem używają **dokładnie tej samej** faktury. Wersje `_alpha.png` zawierają tylko rysunek, a poza jego liniami są całkowicie przezroczyste. Współrzędne zewnętrznej ramy i wszystkich 3 komór pozostają takie same; zmieniają się gesty, stan jednego kołka i minimalne położenie rdzenia, aby przejścia działały jak animacja poklatkowa.

Ciemny ołówek z delikatnymi podwójnymi śladami i jasna kreda są nanoszone wektorowo w Pillow w podwójnej rozdzielczości i zmniejszane do 1080 px. Opisy wprowadzenia są osobnymi kluczami w `contrib/gpt/T39/tutorial_lines.csv`, **nie** zostały wrysowane w żaden kadr. Kolor papieru jest neutralnie kremowy, a całość nie wykorzystuje zewnętrznych assetów ani realnych modeli zamków.

```bash
python3 -m pip install pillow
python3 contrib/gpt/G18/generate.py
```

## Ograniczenia

Stylistykę oparto na opisie zeszytu mistrza Henryka i wymaganiach G18. Z uwagi na ograniczony odczyt plików binarnych z repo nie wykonano pikselowego porównania z `G10/v2/contact-sheet.jpg`. Obecny rysunek jest szkicem **celowo umownym**, bez odwzorowania wymiarów lub zachowania rzeczywistej wkładki. G18 nie integruje grafik bezpośrednio z Godotem — katalog należy wyłącznie do zasobów.
