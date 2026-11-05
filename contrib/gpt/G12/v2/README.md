# G12 v2 — Fotorealistyczne ikony Lockwright / Photorealistic app icons

**Data:** 2026-11-05. **Status:** cztery warianty do przeglądu; rekomendacja 01. Nie są automatycznie zatwierdzone do publikacji.

## Co przygotowano

Poprawkę pierwotnego G12 (wcześniejsze 12 ikon proceduralnych pozostają nienaruszone). Cztery kierunki fotograficzne o miękkim, ciepłym świetle z lewej góry, patynie i fakturze metalu/skóry. Bez marek i logotypów; bez scen manipulowania mechanizmem.

| ID | Wariant PL / EN | Ocena czytelności w 48 px | Ocena 29 px |
|---|---|---|---|
| 01 | Tabliczka emaliowana „L” / Enamel L plate | Najlepsza: prosta, wyraźna litera i kontrast granatu do kości słoniowej | Nadal rozpoznawalne „L” |
| 02 | Czoło mosiężnej wkładki / Brass cylinder face | Czytelna kołowa forma, charakterystyczny środek | Małe detale metalu znikają |
| 03 | Zwinięta skórzana zwijka / Closed leather tool roll | Napa daje punkt rozpoznania, mocny materiałowy charakter | Odczyt mniej jednoznaczny |
| 04 | Stary klucz na skórze / Old key on leather | Czytelna sylwetka, lecz dość pospolita | Bardzo cienki trzonek |

**Rekomendacja do testu A/B:** 01 versus 02. **Wybór do pierwszego testu:** 01, ponieważ znak „L” i pole z emalii mają najmniej elementów ginących przy 48 px. Wariant 02 lepiej komunikuje temat gry, ale bywa mylony z monetą lub elementem mechanizmu. Wariant 03 jest najbardziej charakterystyczny materiałowo, lecz w małej skali nie mówi jednoznacznie „pogotowie zamkowe”.

## Pliki

Każdy z czterech wariantów zawiera:

- `ios/<ID>_1024.png` — nieprzezroczysty PNG 1024×1024 RGB do iOS;
- `android/<ID>_foreground_432.png` — 432×432 RGBA z przezroczystością, sam przedmiot z cieniem i marginesem;
- `android/<ID>_background_432.png` — 432×432 RGB, proceduralne tło zgodne kolorystycznie;
- `previews/<ID>_light_dark_sizes.png` — rozmiary 180, 120, 60, 48, 29 px na jasnym i ciemnym tle;
- `sources/<ID>_source_354.png` — 354×354 wycinek obrazu źródłowego generatora.

Ponadto: `previews/contact_sheet_v2.png`, `previews/android_adaptive_round_mask.png`, `sources/native_imagegen_contact_sheet.png`, `build_assets.py`, `qa_manifest.json`, `ASSETS.md`, `requirements.txt`.

## Pochodzenie i ważne ograniczenie techniczne

Wynik rodzimego generatora obrazów ChatGPT był **planszą 1536×1024** z czterema fotorealistycznymi ujęciami, a nie czterema osobnymi natywnymi fotografiami 1024×1024. Każde źródło zostało wykadrowane do **354×354**, a następnie przeskalowane do wymaganych 1024×1024. Nie jest to więc równoważne z obrazem wygenerowanym od początku w 1024×1024. W podglądach 48 px wynik wygląda fotograficznie, ale przy powiększeniu 100% nie przybywa rzeczywistych detali. To **ograniczenie pozostaje** i w finalnej produkcji warto wymienić źródła na indywidualne fotografie/rendery wysokiej rozdzielczości bez zmiany układu ikon.

W oryginalnej planszy wygenerowano zaokrąglone krawędzie kadrów. Kwadratowe pliki iOS zachowują ten materiał źródłowy, ale nie mają przezroczystości. iOS systemowo nakłada docelowe zaokrąglenie. Android foreground ma rzeczywistą alfę, jednak krawędzie obiektów wycinano maskami z obrazu, więc przed akceptacją sklepową należy je obejrzeć także na fizycznych telefonach.

## QA

- 4 × iOS: 1024×1024, RGB, 100% pikseli nieprzezroczystych.
- 8 × Android: foreground 432×432 RGBA i tło 432×432 RGB.
- 4 plansze wielkości: 180 / 120 / 60 / 48 / 29 px dla jasnego i ciemnego tła; centralna plansza 4 kierunków.
- Weryfikacja poglądowa maski kołowej Androida; bez krytycznego obcięcia rozpoznawalnego motywu.
- Wszystkie PNG poniżej 20 MB. Szczegóły i SHA-256 w `qa_manifest.json`.
- Ocena wizualna: **nie przeprowadzono pomiaru rozpoznawalności z użytkownikami ani testów urządzeń**.

## Odtwarzanie

```bash
python3 -m pip install -r contrib/gpt/G12/v2/requirements.txt
python3 contrib/gpt/G12/v2/build_assets.py
```

Generowanie ikon i ekstrakcję masek wykonuje lokalny skrypt Pillow/NumPy/OpenCV. Nie pobiera żadnych zasobów. Źródło zdjęciowe jest dołączone. Więcej szczegółów o modelu i briefie w `ASSETS.md`.
