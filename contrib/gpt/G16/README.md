# G16 — Gablota: karty eksponatów

**Data przygotowania:** 2026-11-05  
**Projekt:** `woogitsugames/lockwright`  
**Zakres:** wyłącznie `contrib/gpt/G16/`

## Dostarczone materiały

- 20 fotografii koncepcyjnych mechanizmów na bordowym aksamicie (`photos/*.jpg`, 768 × 432 px).
- Pusta etykieta muzealna z nagłówkami **Eksponat / Exhibit** (`props/exhibit_card_blank_pl_en.png`).
- Tło pustej gabloty w poziomie i pionie (`props/showcase_empty_landscape.jpg`, `props/showcase_empty_portrait.jpg`).
- Arkusz przeglądowy 20 zdjęć (`sheets/contact_sheet_g16.jpg`).
- Dwa obrazy źródłowe generacji (`sheets/source_collage_1.jpg`, `sheets/source_collage_2.jpg`) i `manifest.json` z mapowaniem, SHA-256.
- `ASSETS.md`: pochodzenie, identyfikatory generacji, opis promptu, zasady licencji i korekt.

## Mapowanie do `docs/SHOWCASE.md`

Zdjęcia są **autorskimi, generowanymi przez AI koncepcjami** mechanizmów, nie fotografiami rzeczywistych muzealiów, patentów ani odwzorowaniami konkretnych egzemplarzy.

| # | Identyfikator notki | Plik | Dopasowanie koncepcyjne |
|---:|---|---|---|
| 1 | `showcase.khorsabad_gate` | `photos/01_khorsabad_gate.jpg` | Drewniany rygiel z pionowymi kołkami / wooden bolt with drop pins |
| 2 | `showcase.egyptian_name` | `photos/02_egyptian_name.jpg` | Drewniany zamek kołkowy w rekonstrukcji / wooden pin lock reconstruction |
| 3 | `showcase.roman_ring_key` | `photos/03_roman_ring_key.jpg` | Stary klucz z małym uchwytem na pierścień / Roman-style ring-key study (symbolic) |
| 4 | `showcase.roman_wards` | `photos/04_roman_wards.jpg` | Zamek zapadkowy z kluczem / warded lock and key |
| 5 | `showcase.amen_padlock` | `photos/05_amen_padlock.jpg` | Pierścieniowa kłódka szyfrowa / ring combination padlock (numbers, not historical letters) |
| 6 | `showcase.barron_1778` | `photos/06_barron_1778.jpg` | Wczesny dwudźwigniowy zamek w przekroju / twin-lever lock |
| 7 | `showcase.chubb_detector` | `photos/07_chubb_detector.jpg` | Mechanizm dźwigni i zapadki detektora / lever with detector-like pawl |
| 8 | `showcase.hobbs_westminster` | `photos/08_hobbs_westminster.jpg` | Otwarta skrzynka z mechanizmem dźwigniowym / lever lock cutaway |
| 9 | `showcase.bramah_window` | `photos/09_bramah_window.jpg` | Mechanizm o kluczu rurkowym / tube-key lock (conceptual) |
| 10 | `showcase.hobbs_51_hours` | `photos/10_hobbs_51_hours.jpg` | Kłódka w przekroju / cutaway padlock |
| 11 | `showcase.stansbury_1805` | `photos/11_stansbury_1805.jpg` | Obracany bęben z pionowymi kołkami / pin mechanism |
| 12 | `showcase.yale_senior` | `photos/12_yale_senior.jpg` | Sprężynujące kołki w korpusie / spring-pin cylinder |
| 13 | `showcase.yale_flat_key` | `photos/13_yale_flat_key.jpg` | Miniaturowa wkładka bębenkowa w przekroju / compact cylinder cutaway |
| 14 | `showcase.yale_dial` | `photos/14_yale_dial.jpg` | Okrągła tarcza szyfrowa sejfu / circular safe dial |
| 15 | `showcase.sargent_time_lock` | `photos/15_sargent_time_lock.jpg` | Mechanizm zegarowy i rygiel / clockwork and bolt |
| 16 | `showcase.henriksson_disc` | `photos/16_henriksson_disc.jpg` | Stos obracanych dysków / rotating disc stack |
| 17 | `showcase.swiatniki_armourers` | `photos/17_swiatniki_armourers.jpg` | Kuta kłódka żelazna / forged iron padlock |
| 18 | `showcase.swiatniki_school` | `photos/18_swiatniki_school.jpg` | Dekorowany zamek skrzynkowy / decorated box lock |
| 19 | `showcase.krakow_guild_seal` | `photos/19_krakow_guild_seal.jpg` | Otwarty kuty zamek bramowy / forged gate lock cutaway (no guild crest) |
| 20 | `showcase.wroclaw_iron_world` | `photos/20_wroclaw_iron_world.jpg` | Zamek skrzynkowy o dźwigniowym ryglu / iron box lock (unsigned reconstruction) |

## Jakość i znane ograniczenia

- **Fotorealizm sceniczny:** miękkie światło, metal i patyna, drewno, szkło oraz bordowy aksamit. Brak logotypów i zewnętrznych marek.
- **Brak rekonstrukcji historycznych:** geometrii nie należy prezentować jako dokładnych odwzorowań maszyn z opisanych patentów; szczególnie `roman_ring_key`, `chubb_detector`, `bramah_window`, `sargent_time_lock` oraz `krakow_guild_seal` są interpretacjami. Widoczny klucz w pozycji 03 nie jest rzeczywistym rzymskim pierścieniem do noszenia na palcu.
- **Wierność pojedynczych detali:** w pozycji 05 cyfry na bębnach zastąpiono literami `A M E N` oraz literami w pozostałych rzędach. Pozycja 19 nie pokazuje cechowego węża w koronie. Pozycja 20 celowo nie nosi autentycznej sygnatury historycznego twórcy, zgodnie z zakazem sygnatur.
- **Wymiary źródła:** każda fotografia pochodzi z pojedynczego kadru kolażu (~300 × 160 px), powiększonego do 768 × 432 px. To ilustracje do prototypu/UI, **nie pełnowartościowe mastersy 2K/4K do zbliżeń**. Nie wprowadzono dodatkowego detalu 3D przez sam upscale.
- **AI artefakty:** należy przed shippingiem sprawdzić geometrię, zasadę działania fikcyjnych mechanizmów i historyczne implikacje; nie używać kadrów do nauki otwierania prawdziwych zamków.
- **Kompozycja:** białe numery i automatyczne nazwy plików z wygenerowanych arkuszy usunięto przez inpainting lub kadrowanie; pliki w `photos/` i `props/` nie zawierają tych podpisów.
- **Teksty:** fizyczna kartka ma tylko dozwolone nagłówki PL/EN; treść notek pozostaje w i18n gry, nie jest wypalana w zdjęcia.

## Proponowane kolejne kroki

1. Po akceptacji kierunku zastąpić pięć najbardziej schematycznych ujęć (`roman_ring_key`, `chubb_detector`, `bramah_window`, `sargent_time_lock`, `krakow_guild_seal`) indywidualnymi renderami/zdjęciami koncepcyjnymi o źródle co najmniej 1024 px.
2. Dla zbliżeń w Godot 4.7 wykonać finalne modele proceduralne Blender/Cycles, a gablotę zastosować jako warstwę świata i hotspoty na karcie, bez paneli SaaS.
3. Sprawdzić kontrast obiekt/tło i czytelność po skalowaniu i w skali szarości, porównać z `docs/DESIGN.md` i `docs/HUD.md`.

## Inne katalogi — uwagi

Nie zmieniono `CLAUDE.md`, `docs/*`, `art/*` ani kodu gry. Potrzeba ustawienia tekstu notek z pliku `docs/SHOWCASE.md` przez system PL/EN i18n (po stronie zespołu integracji).
