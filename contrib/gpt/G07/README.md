# Lockwright — G07: Koncepty przyjazdu pod drzwi klienta

**Data:** 2026-11-05  
**Repo:** `woogitsugames/lockwright`  
**Zakres zmian:** tylko `contrib/gpt/G07/`.

## Rezultat

Dziesięć pionowych fotorealistycznych kadrów koncepcyjnych w formacie **WebP, 1080 × 2340 px, dokładnie 9:19,5**, plus arkusz podglądowy `preview.webp`. Wszystkie obrazy zachowują spokojniejszy dolny obszar przeznaczony pod diegetyczny HUD. Zdjęciowy charakter: stara kamienica, ślady użytkowania, drewno, tynki, lamperia, emalia i matowy metal; różne warunki oświetlenia. Brak widocznych ludzi, marek, logotypów, zewnętrznych nakładek UI i przestępczej narracji.

| # | Plik | Opis (PL / EN) |
|---|---|---|
| 01 | `images/01_apartment_day.webp` | **Dzień:** światło z okna klatki, drewniane drzwi, numer i wycieraczka. / **Daytime apartment:** window daylight, timber door, enamel number, mat. |
| 02 | `images/02_apartment_evening.webp` | **Wieczór:** ciepła żarówka nad drzwiami. / **Evening apartment:** warm stairwell bulb. |
| 03 | `images/03_apartment_night_timer.webp` | **Noc:** minutnik zgasił światło, chłodny półmrok. / **Night:** stairwell timer has switched the light off. |
| 04 | `images/04_apartment_rainy_evening.webp` | **Deszczowy wieczór:** mokre ślady butów i odbicia. / **Rainy evening:** wet shoe prints and reflections. |
| 05 | `images/05_attic.webp` | **Strych:** stara drewniana stolarka pod belkami. / **Attic:** weathered plank door below rafters. |
| 06 | `images/06_cellar.webp` | **Piwnica:** stalowe drzwi pod ceglanym sklepieniem. / **Cellar:** matte steel door, vaulted brick. |
| 07 | `images/07_kiosk_shutter.webp` | **Kiosk:** opuszczona roleta bez marki, mokry chodnik. / **Kiosk:** unbranded shutter, damp pavement. |
| 08 | `images/08_changing_room_locker.webp` | **Szatnia:** metalowe szafki i płytki. / **Changing room:** worn lockers and floor tiles. |
| 09 | `images/09_courtyard_gate.webp` | **Brama podwórza:** żelazna krata, bruk. / **Courtyard gate:** iron gate and wet cobbles. |
| 10 | `images/10_workshop_door.webp` | **Warsztat:** oszklone drzwi z ciepłym wnętrzem. / **Workshop:** glazed timber door with warm interior. |

## Dodatkowe pliki

- `preview.webp` — arkusz podglądowy 5 × 2 z podpisami PL i EN umieszczonymi poza kadrami.
- `source/concept_sheet_source.webp` — jeden źródłowy arkusz generatywny, zachowany do ponownego kadrowania i kontroli pochodzenia.
- `tools/rebuild.py` — pomocnicze powtarzalne wycinanie 10 kadrów ze źródła (Pillow).
- `ASSETS.md` — rejestr każdego pliku i jego promptu, narzędzia, daty, warunków oraz modyfikacji.

## Odbiór i ograniczenia

- Wszystkie dziesięć plików ma rozmiar **1080 × 2340 px** i mieści się dużo poniżej limitu **20 MB na plik**.
- Kadry nie zawierają instrukcji otwierania zamka, nazw producentów ani bezpośrednich odniesień do innych gier.
- **Ograniczenie istotne:** źródłem jest *jeden* wspólny arkusz generatywny z dziesięcioma panelami. Detale każdego wycinka mają naturalną szczegółowość około 220–260 × 500–540 px; 1080 × 2340 jest efektem skalowania, **nie natywnej generacji/rendera**.
- Ciemna scena 03 wymaga sprawdzenia czytelności interaktywnych punktów; scena 08 ma w dolnej części widoczne szafki i należy zweryfikować ją z HUD.
- `tools/rebuild.py` odtwarza kompozycje z zapisanej, stratnie skompresowanej kopii arkusza, zatem ponowny eksport może różnić się pikselowo od dostarczonych plików WebP.

## Sugestie do wersji produkcyjnej

1. Po wyborze najbardziej udanych wariantów wykonać osobne rendery natywnie w 9:19,5 (Blender Cycles / nowe generacje).
2. Sprawdzić rzeczywistą strefę dotyku i dolny HUD na tle 01, 03, 04, 08 i 09, bez pływających paneli.
3. Zweryfikować kontrast stanów nocnych także przy ograniczonej jasności ekranu, bez neonu, bloom i kolorowych klisz.
4. Odtwarzać w docelowym Godot materiały zgodnie z `docs/styles/realizm.md` i lokalnymi skryptami proceduralnymi, nie zamieniać generatywnego zdjęcia automatycznie w model 3D.

**Niczego poza `contrib/gpt/G07/` nie zmieniano.**
