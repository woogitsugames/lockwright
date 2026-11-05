# G08 — Koncepty warsztatu ślusarza

**Projekt:** Lockwright: Pogotowie Zamkowe / Lockwright: Locksmith on Call  
**Data:** 2026-11-05  
**Status:** przygotowano 11 kadrów koncepcyjnych i arkusz; do oceny artystycznej.  

## Zakres

- **5 pionowych kadrów** w proporcji **9:19,5** (720 × 1560 px).
- **3 poziome kadry** w proporcji **19,5:9** (1560 × 720 px).
- **3 zbliżenia** 16:9 (1280 × 720 px): zeszyt mistrza, gablota, tablica wytrychów.
- **1 arkusz zbiorczy** `contact-sheet.webp` z podpisami po polsku i angielsku.
- Fotorealistyczny kierunek: bukowy blat, patynowana stal bez chromu, chłodne okno, ciepła lampa warsztatowa, fizyczne przedmioty zamiast pływających paneli, czysty fachowy warsztat z lekkim nieładem.

## Pliki

| Plik | PL / EN | Opis |
|---|---|---|
| `images/01-workshop-morning-portrait.webp` | Warsztat — poranek / Workshop — morning | Okno, rośliny, imadło, tablica i poranna praca. |
| `images/02-key-cutter-afternoon-portrait.webp` | Dorabiarka kluczy — popołudnie / Key cutter — afternoon | Wymyślona bezmarkowa maszyna; satynowa stal, metalowe opiłki. |
| `images/03-workshop-evening-portrait.webp` | Warsztat — wieczór / Workshop — evening | Ciepła przegubowa lampa, notes, kubek i telefon. |
| `images/04-tool-board-portrait.webp` | Tablica narzędzi / Tool board | Ułożone w ręczny sposób narzędzia o różnych wykończeniach. |
| `images/05-display-cabinet-portrait.webp` | Gablota z mechanizmami / Mechanism display cabinet | Drewniana szafka, szklane drzwiczki, wymyślone otwarte mechanizmy. |
| `images/06-workbench-afternoon-landscape.webp` | Blat roboczy — popołudnie / Workbench — afternoon | Imadło, zeszyt, telefon, kubek, maszyna, faktura klejonego drewna. |
| `images/07-workshop-overview-landscape.webp` | Warsztat — widok ogólny / Workshop — wide view | Ergonomia huba: stół, tablica, gablota i oświetlenie. |
| `images/08-lamplight-evening-landscape.webp` | Wieczór przy lampie / Evening by the work lamp | Ciepłe światło miejscowe i chłodne okno, telefon oraz zeszyt. |
| `images/09-master-notebook-closeup.webp` | Zeszyt mistrza — zbliżenie / Master’s notebook — close-up | Papier, ręczne notatki i szkice; tekst koncepcyjny, nie finalna lokalizacja. |
| `images/10-display-cabinet-closeup.webp` | Gablota — zbliżenie / Display cabinet — close-up | Przekroje wymyślonych zamków w szklanej gablocie. |
| `images/11-pick-board-closeup.webp` | Tablica wytrychów — zbliżenie / Pick board — close-up | Proste wytrychy fikcyjnego systemu, bez marek. |
| `contact-sheet.webp` | Arkusz zbiorczy / Contact sheet | Układ 5 + 3 + 3 z podpisami PL/EN. |
| `ASSETS.md` | Rejestr zasobów / Asset register | Narzędzia, źródła, prompty, przekształcenia, warunki. |

## Ograniczenia i co nie zostało osiągnięte

1. Obrazy są **kadrami wyciętymi z trzech większych, wygenerowanych arkuszy** i interpolowanymi do docelowych proporcji. Nie są to natywne, odrębne rendery o tej rozdzielczości. Jakość po powiększeniu jest ograniczona szczegółowością źródłowych paneli. Do finalnych materiałów produkcyjnych zalecane jest osobne wyrenderowanie każdego kadru w Blenderze.
2. Narzędzie generujące stosowało ogólny opis zlecenia; brak dostępu do dokładnego promptu wykonywanego wewnętrznie przez model obrazu. W `ASSETS.md` wpisano pełny opis wejściowy widoczny dla tej sesji oraz granice metadanych.
3. Kształty wymyślonych mechanizmów, działanie dorabiarki, proporcje narzędzi i napisy odręczne **nie są dokumentacją inżynierską**. Nie należy ich automatycznie przenosić do rzeczywistych modeli. Notatki na zeszycie są wyłącznie koncepcyjne.
4. Nie udało się otworzyć istniejącego PNG makiety `mockups/realizm/png/04-workshop.portrait.png` do oceny wizualnej przez interfejs GitHuba (pobieranie binariów niedostępne); układ zweryfikowano z tekstami `CLAUDE.md`, `docs/styles/realizm.md`, `docs/DESIGN.md`, `docs/HUD.md`.

## Rekomendacje wdrożenia

- Potraktować kadry jako **moodboard i materiał do wyboru kompozycji**, a nie tekstury gry lub zrzuty gotowego Godota.
- Utrzymać interaktywne elementy huba jako przedmioty: telefon = zlecenia, kartka = dyżur, imadło = ćwiczenia, gablota = przegląd mechanizmów, zeszyt = ustawienia, szuflada = narzędzia.
- W Blenderze odtworzyć geometrycznie spójną maszynę, fikcyjne przekroje, rozsądne miejsca chwytu, podpisy z i18n i powierzchnie dotyku ≥ 48 dp (44 pt na iOS), a następnie zrobić ujęcia w świetle porannym, popołudniowym i wieczornym.
- Używać obrazu w układzie 9:16 jako „bezpiecznego mastera”; kompozycję ważnych elementów zabezpieczyć pod docelowy telefon 9:19,5; potwierdzić safe-area.
- Nie traktować czytelnego tekstu wygenerowanego na papierze jako gotowego tekstu w grze. Finalne napisy nakładać jako PL/EN na powierzchniach zgodnie z projektem.

## Kontrola jakości

- 11 plików WebP, wszystkie w zadanych proporcjach; arkusz zbiorczy.
- Wszystkie pliki binarne poniżej 20 MB; poszczególne rozmiary i sumy SHA-256: `ASSETS.md`.
- Brak dodanych znaków marek, prawdziwych osób i elementów HUD w postaci paneli UI.
