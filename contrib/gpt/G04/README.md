# G04 — Ściany klatki schodowej / Stairwell wall textures

Data realizacji: **5 listopada 2026 r.**  Projekt: **Lockwright** (`woogitsugames/lockwright`).

## Co zostało wykonane

- **Trzy** olejne lamperie (butelkowa zieleń, ochra, wiśniowy brąz) z wytarciami, odpryskami i spękaniami; każda 2048×2048 JPEG, krawędzie płynnie powtarzalne.
- **Jedna** biało-kremowa faktura tynku wapiennego z zabrudzeniami i pęknięciami, 2048×2048 JPEG, powtarzalna.
- **Jeden** osobny materiał pasa odcięcia — nierówna cienka ciemnobrązowa linia, 2048×2048 JPEG, powtarzalna.
- **Dwa** osobne wycięte obiekty 1024×1024 RGBA PNG: zużyta skrzynka elektryczna oraz okrągły czarny bakelitowy przycisk światła na minutnik. Bez marek i napisów.
- **Pięć** testów powtarzania 2×2 (po jednym na każdą teksturę) oraz **jedna** plansza porównawcza 2×2 z przykładowym zestawieniem materiałów w scenie.

## Spis plików

| Plik | Wymiary | Wielkość | Przeznaczenie |
|---|---:|---:|---|
| `objects/bakelite_timer_switch_rgba_1024.png` | 1024×1024 | 0.46 MiB | Bakelitowy okrągły minutnik z przyciskiem i śrubami, przezroczystość. |
| `objects/electrical_box_rgba_1024.png` | 1024×1024 | 0.55 MiB | Stara szara skrzynka elektryczna, korozja, łączniki, przezroczystość. |
| `previews/stairwell_variants_overview_2x2.png` | 1024×1024 | 1.27 MiB | Plansza 2×2: trzy kolory lamperii oraz wariant z oboma obiektami. |
| `previews/tile_lime_plaster_cream_2x2.png` | 1024×1024 | 0.93 MiB | Test UV: cztery stykające się kopie dokładnie tego samego materiału (2×2). |
| `previews/tile_paint_divider_band_2x2.png` | 1024×1024 | 0.93 MiB | Test UV: cztery stykające się kopie dokładnie tego samego materiału (2×2). |
| `previews/tile_wainscot_bottle_green_2x2.png` | 1024×1024 | 0.84 MiB | Test UV: cztery stykające się kopie dokładnie tego samego materiału (2×2). |
| `previews/tile_wainscot_cherry_brown_2x2.png` | 1024×1024 | 0.80 MiB | Test UV: cztery stykające się kopie dokładnie tego samego materiału (2×2). |
| `previews/tile_wainscot_ochre_2x2.png` | 1024×1024 | 0.83 MiB | Test UV: cztery stykające się kopie dokładnie tego samego materiału (2×2). |
| `textures/lime_plaster_cream_albedo_2048.jpg` | 2048×2048 | 0.82 MiB | Biało-kremowy tynk wapienny, zabrudzenia, rysy, włoskowate spękania. |
| `textures/paint_divider_band_albedo_2048.jpg` | 2048×2048 | 0.83 MiB | Cienki, nieregularny ciemnobrązowy pas odcięcia na tynku. |
| `textures/wainscot_bottle_green_albedo_2048.jpg` | 2048×2048 | 0.73 MiB | Zielona olejna lamperia z otarciami, pęknięciami i odpryskami. |
| `textures/wainscot_cherry_brown_albedo_2048.jpg` | 2048×2048 | 0.71 MiB | Wiśniowobrązowa olejna lamperia z siatką rys i odpryskami. |
| `textures/wainscot_ochre_albedo_2048.jpg` | 2048×2048 | 0.79 MiB | Ochrowa olejna lamperia z wytarciami, uszkodzeniami i prześwitującym podkładem. |

## Integracja w Godot / mapowanie UV

1. Umieść lamperię na osobnym fragmencie ściany do wysokości ok. **150 cm** (bez tekstu ani interfejsu). Wariant koloru wybieraj per kamienica/kondygnacja, nie wymieniaj dynamicznie podczas sceny.
2. Tynk zastosuj na płaszczyźnie **powyżej** lamperii. Materiały lamperii i tynku są odrębne — granica nie jest na stałe wypalona w ich bitmapach.
3. Osobny `paint_divider_band` przypnij do bardzo wąskiego pasa geometrii na granicy. Ciemna linia znajduje się w środku tekstury, na współrzędnych **V około 0.48–0.515**; reszta mapy zawiera tynk. Dla wąskiego pasa próbkuj środkowy fragment V albo zbuduj podłużny detal UV. Dzięki temu pas nie powtarza się na całej wysokości ściany.
4. Dla faktur ustaw `Texture Repeat = Enabled` i sprawdź skalę UV w docelowym ujęciu 9:16. Obrazy z `previews/tile_*_2x2.png` pokazują podwójne powtórzenie w obu osiach.
5. Obiekty RGBA są **sprite'ami / wyciętymi ujęciami rekwizytów**, a nie modelami 3D. Do bliskich ujęć z paralaksą trzeba przygotować geometrię i mapy PBR. Bezpośrednio nie implementują działania instalacji elektrycznej ani mechaniki minutnika.
6. Oświetlenie sceny zgodne z `docs/styles/realizm.md`: ciepłe światło żarówki z klatki oraz chłodne doświetlenie od okna, bez bloom i bez chromu.

## Kontrola jakości

- Wszystkie JPEG i PNG otwarte i zweryfikowane w Pillow (wymiary, integralność, kanał alfa tam, gdzie wymagany).
- Materiały przed kompresją JPEG miały identyczne skrajne wiersze i kolumny (kontrola pikselowa). W finalnych JPEG drobna różnica na krawędziach wynika z kompresji stratnej (średnio poniżej 3 poziomów RGB); podglądy 2×2 służą kontroli wzrokowej płynności łączenia.
- Wszystkie pojedyncze pliki binarne są mniejsze niż **20 MB**.
- Nie dodano marek, logotypów, postaci ani niedozwolonych elementów interfejsu.
- Zasoby źródłowe, narzędzia, pełny brief oraz informacje o obróbce i warunkach użycia opisano w [`ASSETS.md`](ASSETS.md).

## Co się nie udało / ograniczenia

- Wygenerowana plansza referencyjna była kompozytem, a nie pięcioma indywidualnymi fotografiami 2048×2048. Finalne obrazy są faktycznie **2048×2048**, lecz część szczegółu wizualnego pochodzi z mniejszych kadrów źródłowych i została przeskalowana oraz uzupełniona proceduralnie. Przy ujęciach makro może brakować naturalnych detali o pełnej rozdzielczości 2K.
- Nie przygotowano map **normal, roughness, height** ani modeli 3D — wykraczały poza zakres G04.
- Drobne refleksy źródłowych rekwizytów są częścią wyciętej ilustracji, więc jako billboard 2D nie powinny być używane w skrajnie innym kierunku światła.

## Propozycje

- Dla zbliżeń: osobna generacja materiałów 2K lub skany PBR / proceduralne tekstury Blendera wraz z normal i roughness; obecna paczka jest odpowiednia do testów kadru i otoczenia.
- Sprawdzić scenę mobilną na docelowych urządzeniach: pamięć tekstur, mipmapy, rozmiar instalacyjny, odległość obserwacji oraz widoczność laminowanych ścian na ekranie telefonu.
- Przy ostatecznej integracji przygotować zgodne z `art/blender/stairwell.py` obiekty 3D z własnymi materiałami, bazując na tych wzorcach kolorystyki.

**Zakres zmian:** wyłącznie `contrib/gpt/G04/`.
