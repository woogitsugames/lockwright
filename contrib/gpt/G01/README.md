# Zlecenie G01 — emaliowane tabliczki mieszkań

**Data wykonania:** 2026-11-05  
**Projekt:** Lockwright — Pogotowie Zamkowe  
**Zakres zmian:** wyłącznie `contrib/gpt/G01/`.

## Wykonano

- 24 osobne numery mieszkań (1–24) w estetyce historycznej emalii na stali: granat, butelkowa zieleń, bordo i kość słoniowa.
- 6 polskich tabliczek pomieszczeń i 6 odpowiadających im tabliczek angielskich.
- Dwa otwory z mocowaniami na każdej tabliczce; przetarcia, zarysowania, odpryski, miejscowa rdza.
- 36 pojedynczych PNG 1024×1024, widok frontalny, kanał alfa i przeźroczyste narożniki.
- `contact_sheet.png`: arkusz zbiorczy 6×6 z podpisami i szachownicą podglądu przezroczystości.
- `ASSETS.md`: pochodzenie AI, prompt, data, warunki i rodzaj edycji.
- `source_sheet.webp` oraz `generate.py`: archiwum źródła i powtarzalny skrypt wydzielania zasobów.

## Lista plików

| Plik | Opis |
|---|---|
| `plate_01.png` | Numer 1, granat |
| `plate_02.png` | Numer 2, kość słoniowa |
| `plate_03.png` | Numer 3, butelkowa zieleń |
| `plate_04.png` | Numer 4, bordo |
| `plate_05.png` | Numer 5, kość słoniowa |
| `plate_06.png` | Numer 6, granat |
| `plate_07.png` | Numer 7, butelkowa zieleń |
| `plate_08.png` | Numer 8, bordo |
| `plate_09.png` | Numer 9, kość słoniowa |
| `plate_10.png` | Numer 10, granat |
| `plate_11.png` | Numer 11, butelkowa zieleń |
| `plate_12.png` | Numer 12, bordo |
| `plate_13.png` | Numer 13, granat |
| `plate_14.png` | Numer 14, kość słoniowa |
| `plate_15.png` | Numer 15, butelkowa zieleń |
| `plate_16.png` | Numer 16, bordo |
| `plate_17.png` | Numer 17, kość słoniowa |
| `plate_18.png` | Numer 18, granat |
| `plate_19.png` | Numer 19, bordo |
| `plate_20.png` | Numer 20, butelkowa zieleń |
| `plate_21.png` | Numer 21, granat |
| `plate_22.png` | Numer 22, kość słoniowa |
| `plate_23.png` | Numer 23, bordo |
| `plate_24.png` | Numer 24, butelkowa zieleń |
| `plate_sign_administracja_pl.png` | Napis „Administracja (PL)” |
| `plate_sign_dozorca_pl.png` | Napis „Dozorca (PL)” |
| `plate_sign_pralnia_pl.png` | Napis „Pralnia (PL)” |
| `plate_sign_strych_pl.png` | Napis „Strych (PL)” |
| `plate_sign_piwnica_pl.png` | Napis „Piwnica (PL)” |
| `plate_sign_warsztat_slusarski_pl.png` | Napis „Warsztat ślusarski (PL)” |
| `plate_sign_administration_en.png` | Napis „Administration (EN)” |
| `plate_sign_caretaker_en.png` | Napis „Caretaker (EN)” |
| `plate_sign_laundry_en.png` | Napis „Laundry (EN)” |
| `plate_sign_attic_en.png` | Napis „Attic (EN)” |
| `plate_sign_cellar_en.png` | Napis „Cellar (EN)” |
| `plate_sign_locksmith_workshop_en.png` | Napis „Locksmith Workshop (EN)” |
| `contact_sheet.png` | 36 tabliczek na arkuszu 6×6 z podpisami |
| `source_sheet.webp` | Bezstratna kopia wzorcowego obrazu AI, do powtórnego generowania wycinków |
| `generate.py` | Odtwarzalny skrypt segmentacji i eksportu PNG |
| `ASSETS.md` | Pełny rejestr źródeł i warunków |
| `README.md` | Raport wykonania i QA |

## Kontrola jakości

- Wszystkie 24 cyfry (1–24) są widoczne na arkuszu zbiorczym.
- Sprawdzono sześć polskich napisów: Administracja, Dozorca, Pralnia, Strych, Piwnica, Warsztat ślusarski oraz ich sześć angielskich odpowiedników: Administration, Caretaker, Laundry, Attic, Cellar, Locksmith Workshop.
- Sprawdzono liczbę plików: 36 tabliczek PNG + 1 contact sheet. Każda osobna tabliczka ma wymiar 1024×1024, tryb RGBA i przezroczystość poza tabliczką.
- Wszystkie pliki są mniejsze niż 20 MB.
- Brak widocznych logotypów, prawdziwych adresów lub marek produktów; nazwy pomieszczeń są ogólnymi określeniami.

## Ograniczenia / co się nie udało

- Wektorowa precyzja typograficzna nie była celem; cyfry i nazwy powstały w generatorze obrazów. Kontrola wizualna wskazuje poprawne napisy, ale bez ręcznego składu fontów pozostaje ryzyko drobnych artefaktów rasteryzacji.
- Materiał wejściowy to jeden arkusz AI 1536×1024, dlatego eksport 1024×1024 jest powiększeniem wycinków. Nie ma natywnej liczby detali pojedynczego renderu 1024×1024 (m.in. w mikroodpryskach).

## Propozycje

- Jeśli tabliczka będzie oglądana w dużym zbliżeniu, należy wygenerować osobne ujęcie 1024×1024 albo wykonać model 3D i bake PBR, zachowując numery i kolory.
- W Godot 4.7 użyć PNG z alfą jako tekstur na płaszczyźnie lub jako materiału na geometrii tabliczki; oddzielny normal/roughness map bake byłby wskazany przy dużym zbliżeniu.
- Podpinać PL/EN na etapie wyboru tekstury; nie tłumaczyć samej tekstury w locie.

## Reprodukcja

```bash
python -m pip install "Pillow>=10" "numpy>=1.24" "opencv-python-headless>=4.8"
cd contrib/gpt/G01
python generate.py
```

Ponowne uruchomienie skryptu nadpisuje tylko pliki PNG we wskazanym katalogu G01.
