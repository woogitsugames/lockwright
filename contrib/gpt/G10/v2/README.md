# G10 v2 — źródła od właściciela (z sesji ChatGPT)

Przekazane przez właściciela jako obrazy w czacie (2026-11-05). Generator obrazów zablokował strony z rysunkami mechanizmu, więc do gry bierzemy **puste** strony i okładkę jako faktury, a treść z v1 (`../pages-svg/`) nakłada sesja A kodem (font odręczny OFL).

| Plik | Opis |
|---|---|
| `source/cover_blank.jpg` | płócienna okładka, bez napisów |
| `source/page_lined_blank.jpg` | pusta strona w linię |
| `source/page_grid_blank.jpg` | pusta strona w kratkę |
| `source/preview_sheet_a.jpg`, `preview_sheet_b.jpg` | podglądy z tekstem (tylko referencja; treść z arkusza A odbiega od kodu stanów i zasad z CLIENTS.md — nie używać) |

Narzędzie: ChatGPT Image Generator (D-42). Prompty: w sesji ChatGPT (G10-v2.md).

## Strony v2 (złożone przez sesję A)
`pages/*.jpg` 1600×2200: treść v1 (5 zasad PL/EN, 10 szkiców stanów ii-01…ii-10) wyciągnięta z SVG jako warstwa „grafitu” (font Caveat, OFL, `fonts/`), z lekkim rozmyciem i nierównym naciskiem, nałożona trybem mnożenia na fotorealistyczne puste strony z `source/`. Narzędzia: `tools/ink.mjs` (Playwright → warstwa tuszu) + kompozycja Pillow. Okładka i puste strony skopiowane z `source/`.
