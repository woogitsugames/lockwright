# G18 — pochodzenie i warunki użycia zasobów

**Data:** 2026-11-05.  
**Narzędzie:** ChatGPT ImageGen (OpenAI) + autorski skrypt Python/Pillow `generate.py`.  
**Warunki:** materiał generowany na potrzeby projektu; użycie według aktualnych warunków OpenAI, nie deklarować CC0. Rysunki nanoszone w skrypcie nie korzystają z obcych grafik, marek ani realnych modeli zamków.

## Pełny prompt obrazu wejściowego (P3)

> A square, straight-on photorealistic view of a blank, aged graph-paper notebook page fills the frame, showing a warm ivory surface with visible fibers, faded blue-gray square ruling, and subtle stains, scratches, smudges, creases, specks, and worn texture. The left side features a darker frayed binding strip, while the rounded edges and lightly curled corners show additional grime and wear, including a soft brownish coffee-like stain in the lower-left; lighting remains even and diffuse, with no text, marks, symbols, objects, or other content present.

## Rejestr

| Plik | Narzędzie / prompt | Edycja |
|---|---|---|
| `source/graph_paper_chatgpt.png` | ChatGPT ImageGen / P3 (pełny powyżej) | Brak, oryginał pustej strony |
| `frame_1_tension.png` | P3 + Pillow | Skalowanie papieru do 1080 i nakładanie koncepcyjnego rysunku ołówka/kredy, napinacza i gestu lewego kciuka |
| `frame_1_tension_alpha.png` | Pillow, na podstawie P3 | Wyłącznie rysunek i gest z pierwszego kadru, kanał alfa bez papieru |
| `frame_2_lift.png` | P3 + Pillow | Ten sam kadr i papier + gest prawego kciuka, schemat uniesienia środkowego kołka i strzałka boczna |
| `frame_2_lift_alpha.png` | Pillow, na podstawie P3 | Rysunek etapu drugiego bez papieru, alfa |
| `frame_3_click.png` | P3 + Pillow | Ten sam kadr i papier + trzy kreski przy kołku, osadzenie i drobny obrót rdzenia |
| `frame_3_click_alpha.png` | Pillow, na podstawie P3 | Rysunek etapu trzeciego bez papieru, alfa |
| `contact_sheet.jpg` | Pillow / P3 + rysunki | Układ 3×2 z podpisami *poza kadrami*, podgląd alfa na kratkowanym tle |

**Instrukcja do rysunków kodowych:** opis scen i sekwencji znajduje się w pliku zadania `G18-tutorial-chalk-frames.md`, a dokładna geometria i transformacje są jawnie zapisane w `generate.py`. Nie użyto generatora obrazów do przedstawiania rzeczywistego zamka.
