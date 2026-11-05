# G07 — Koncepty przyjazdu ślusarza pod drzwi klienta

**Projekt:** Lockwright: Pogotowie Zamkowe / Lockwright: Locksmith on Call  
**Data opracowania:** 2026-11-05  
**Status:** 10 wariantów koncepcyjnych + arkusz podglądowy, do przeglądu artystycznego  
**Obszar pracy:** wyłącznie `contrib/gpt/G07/`

## Co wykonano

Przygotowano dziesięć pionowych, fotorealistycznie stylizowanych kadrów otoczenia z perspektywy ślusarza przybywającego na legalne zlecenie, bez widocznych osób, marek, UI i instrukcji otwierania zamków. Kadry obejmują wnętrza kamienicy i obiekty z biblii zleceń. Warianty oświetlenia obejmują światło dzienne, lampę żarową, noc po zgaśnięciu minutnika i mokre odbicia deszczowego wieczoru. Materiały: drewno, poobijana lamperia, emalia, lastryko, matowa stal, kamień, mokry bruk i szorstki metal.

Kompozycje zachowują względnie spokojne dolne pole na diegetyczny interfejs gry. **Żadne napisy ani elementy interfejsu nie zostały nałożone na pojedyncze kadry.** Numery mieszkań na emaliowanych tabliczkach pozostają, zgodnie z charakterem otoczenia.

Jeden wspólny arkusz został wygenerowany narzędziem ChatGPT; dziesięć pól wycięto i przeskalowano do **1080 × 2340 px (9:19,5)** w formacie JPEG. Powstały także dziesięć samodzielnych dokumentów SVG o tych samych wymiarach logicznych, zawierających skompresowany arkusz obrazów i odpowiednie wykadrowanie; ich szczegółowość rastrowa jest mniejsza. Arkusz `preview.jpg` ponownie złożono z kadrów, z polskimi i angielskimi podpisami **pod** obrazami. Źródło oraz narzędzie do powtarzalnego eksportu są dołączone. Pochodzenie i warunki wykorzystania podano w `ASSETS.md`.

## Lista kadrów

| Nr | Plik | Opis PL / EN |
|---|---|---|
| 01 | `images/01_apartment_day.jpg` | Mieszkanie w dzień: chłodne światło z okna, dębowe drzwi, emaliowany numer, wycieraczka i lamperia. / **Apartment, daytime:** cool window light, oak door, enamel number plate, mat and painted lower wall. |
| 02 | `images/02_apartment_evening.jpg` | Wieczór: żółta żarówka i spokojne cienie na starych drzwiach. / **Apartment, evening:** warm bare bulb and calm shadows on old timber. |
| 03 | `images/03_apartment_night_timer.jpg` | Noc: klatka po zgaśnięciu minutnika, tylko resztkowe światło. / **Apartment, night:** stairwell after timer light goes out, minimal ambient light. |
| 04 | `images/04_apartment_rainy_evening.jpg` | Deszczowy wieczór: mokry podest i ślady butów, ciepłe światło. / **Rainy evening:** wet landing and shoe marks in tungsten light. |
| 05 | `images/05_attic.jpg` | Strych: nierówne deski, belki i nieduże okno dachowe. / **Attic:** rough plank door, exposed rafters, small rooflight. |
| 06 | `images/06_cellar.jpg` | Piwnica: masywne matowe drzwi, sklepienie ceglane, posadzka z odpływem. / **Cellar:** utilitarian iron door, brick vault, drain. |
| 07 | `images/07_kiosk_shutter.jpg` | Kiosk: zamknięta żaluzja bez marki, mokry chodnik. / **Kiosk:** unbranded roller shutter above wet pavement. |
| 08 | `images/08_changing_room_locker.jpg` | Szatnia: zmatowiałe metalowe szafki i zużyta podłoga. / **Changing room:** dull metal lockers and worn tiles. |
| 09 | `images/09_courtyard_gate.jpg` | Brama: otwarta perspektywa podwórka, żelazo i mokry bruk. / **Courtyard gate:** iron gate, courtyard view, wet cobbles. |
| 10 | `images/10_workshop_door.jpg` | Warsztat: drewniano-szklane drzwi, ciepłe światło za szybą. / **Workshop door:** framed glass panels, warm workshop light beyond. |

## Pozostałe pliki

- `preview.jpg` — arkusz podglądowy 5 × 2, podpisy PL i EN pod kadrówkami.
- `preview.svg` — lekki, samodzielny arkusz wektorowo-rastrowy (sam obraz wewnątrz jest WebP).
- `images/*.svg` — dziesięć samodzielnych tła SVG o wymiarach logicznych 1080 × 2340.
- `source/concept_sheet_compact.webp` — skompresowana wersja źródła użyta w SVG.
- `source/concept_sheet_original.png` — oryginalny arkusz z generatora ChatGPT, zachowany dla pochodzenia zasobów.
- `tools/build_assets.py` — reprodukcja cropów JPEG i arkusza JPG z zachowanego źródła (Pillow).
- `tools/build_compact_svg.py` — reprodukcja wariantów SVG z osadzonym źródłem WebP (Pillow).
- `ASSETS.md` — rejestr wszystkich grafik z narzędziem, datą, pełnym opisem promptów, warunkami wykorzystania i edycją.

## QA i ograniczenia

- **Wymiary:** 10 × 1080 × 2340 px, dokładnie 9:19,5. Każdy pojedynczy plik jest mniejszy niż 20 MB.
- **Bezpieczeństwo narracji:** nie ma ludzi identyfikowalnych, marek, kodów rzeczywistych produktów, scen włamania ani instruktażu; grafiki przedstawiają spokojną sytuację obsługi klienta.
- **Jakość:** źródłem jest wspólny arkusz, zatem wycięte fragmenty mają naturalną szczegółowość rzędu 220–260 × 500–540 px; rozdzielczość 1080 × 2340 uzyskano przez interpolację, **nie przez niezależny render natywny**. To karty do wyboru kierunku, a nie jeszcze gotowe assety produkcyjne 1:1.
- **Kadry 05–10:** różnią się typem obiektu; nie wszystkie mają charakterystyczną emaliowaną tabliczkę numeru i wycieraczkę, gdy nie pasowałoby to do obiektu.
- **Kadr 03:** jest celowo ciemny i wymaga testu czytelności interaktywnych punktów w Godot.
- **Dół 40%:** pole uproszczone kompozycyjnie, ale w scenie szatni dolna część szafek pozostaje widoczna. Przed użyciem UI zalecany test z rzeczywistą zwijką HUD.
- **Kompozycje:** pełne zdjęciowe tła; interfejs, weryfikacja prawa do lokalu i przejścia stanów nie są pokazane jako samodzielne elementy (będą nakładane diegetycznie przez grę).

## Propozycje dalszych działań

1. Po wyborze 2–3 kompozycji wykonać indywidualne rendery w Blender Cycles / narzędziu generatywnym **bezpośrednio w 9:19,5**; nie opierać finalnego artu na interpolowanych cropach.
2. Zweryfikować w makiecie `mockups/realizm/03-job.html` podział strefy: weryfikacja dokumentów, podgląd wkładki, opcjonalny włącznik minutnika oraz diegetyczny HUD w dolnych 40%.
3. Przetestować dostępność nocnego kadru bez sztucznych błysków, neonu i bloomu; zachować czytelność w skali szarości.
4. Przy docelowym oświetleniu używać materiałów z `art/blender/env_common.py` zamiast przenosić generatywne detale 1:1 do modelu gry.

Nie zmieniano plików poza katalogiem `contrib/gpt/G07/`.
