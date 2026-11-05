# G20 — raport z udostępnionych wyników (częściowe wykonanie)

**Status: nieukończone.** Z 16 zamówionych obrazów w sesji wygenerowano jeden obraz źródłowy przedstawiający dwie koncepcje A1 obok siebie. Każdą wyodrębniono i przekształcono w pionowy obraz 1024×1792, z przedłużeniem spokojnego środka pegboardu. Ze względu na powtarzanie środkowych fragmentów faktur obie wersje należy traktować jako **robocze tła**, wymagające oceny wizualnej przed użyciem w grze.

## Co jest w paczce

- `images/menu_workshop_wall_9x16.png` — A1 główny, 1024×1792, z pierwszego panelu kompozycji.
- `images/menu_workshop_wall_9x16_alt.png` — A1 alternatywny, 1024×1792, z drugiego panelu.
- `contact_sheet_A1.png` — szybki podgląd A1.
- `sources/a_photorealistic_highly_detailed_pair_of_vertical.png` — nietknięta oryginalna kompozycja A1 (dwie kolumny).
- `sources/a_detailed_completion_message_and_deliverable_summ.png` — nieudany wynik: nie jest zamówionym A2 ani portretem.
- `sources/a_detailed_realistic_game_dev_deliverable_pack.png` — nieudany wynik: nie jest zamówionym A2 ani portretem.
- `REQUEST.md` — pełna oryginalna specyfikacja G20.
- `ASSETS.md` — identyfikacja narzędzi, pochodzenia, przekształceń i promptu referencyjnego.
- `manifest.json` — spis z sumami SHA-256.

## Braki względem kryteriów odbioru

Zgodnie z oryginalnym zleceniem brakuje 14 obrazów: dwóch zdjęć `leather_tab_snap_topdown` (głównego i `_alt`) oraz po dwóch portretów dla każdej z sześciu fikcyjnych postaci: Janka, Mila, Oskar, Paweł, Karol i Leon. Nie ma kompletu 8 głównych plików + 8 `_alt`. Dwa pozostałe generaty zostały zachowane wyłącznie jako dokumentacja próby i **nie są assetami produkcyjnymi**.

## Uwagi dotyczące techniki

A1 został przekształcony z nietypowej pary dwóch wąskich widoków umieszczonych obok siebie. Środkowe fragmenty obrazu powielono z odbiciem lustrzanym (bez interpolowania rozciągającego narzędzia na brzegach), a następnie przeskalowano do 1024×1792. Jest to przybliżenie robocze, a nie niezależnie wygenerowane dwa pełnowymiarowe zdjęcia 9:16. Nie wykonano commita ani zmian w GitHubie — użytkownik polecił zapis do ZIP.
