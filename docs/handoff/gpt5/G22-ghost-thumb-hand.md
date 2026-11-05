# Zlecenie G22: zdjęcia kciuka i dłoni do „widma” w samouczku

**Dla:** ChatGPT z generatorem obrazów. **Nie wypychasz niczego**, oddajesz ZIP właścicielowi.

## Po co to jest
W samouczku gry, gdy gracz utknie, na ekranie pojawia się miękki **cień kciuka albo dłoni**, który pokazuje gest (jak cień rzucany przez lampę warsztatu). Cień zrobimy sami w grze: z Twojego zdjęcia wytniemy sylwetkę, rozmyjemy ją i przyciemnimy. Dlatego potrzebujemy **czystych, ostrych zdjęć dłoni na jednolitym białym tle**, z wyraźnym konturem.

## Najważniejsze zasady pracy
1. **Jeden obraz na jedną wiadomość.** Generuj po kolei, w osobnych wiadomościach. **Nigdy** nie rób kolaży, arkuszy, kilku ujęć obok siebie ani obrazków-podsumowań.
2. Każdy obraz to **jedno zdjęcie** opisane w prompcie: bez napisów, logo, ramek, pierścionków, zegarków i tatuaży.
3. Tło **czysto białe** (#FFFFFF lub prawie), bez cieni na tle, bez blatu, bez telefonu.
4. Dłoń **dorosłego rzemieślnika** (ok. 50–60 lat), naturalna, bez manicure. **Dokładnie pięć palców**, poprawna anatomia. Gdy palców jest za dużo albo kciuk jest dziwny, powtórz ten sam prompt.
5. Rozmiar 1024×1024 (kwadrat). Widok **prosto z góry**.
6. Gdy coś zostanie zablokowane, pomiń to i zapisz w raporcie.

## Wspólny początek promptu (wklej przed każdym opisem)
```
Square studio photo, shot straight from above, of a real adult craftsman's hand (about 55 years old, natural skin, short clean nails, no rings, no watch, no tattoos) on a pure flat white background. Even soft light, no shadow on the background, sharp clean outline, exactly five fingers, correct anatomy. No text, no logos, no other objects.
```

## Obrazy (6 sztuk, w tej kolejności)
1. **`thumb_left_press.png`:** `Only the left thumb and the edge of the left hand enter the frame from the lower left corner. The thumb points up and slightly right, its pad pressed flat as if touching a phone screen. The thumb tip is near the centre of the image.`
2. **`thumb_right_press.png`:** `Only the right thumb and the edge of the right hand enter the frame from the lower right corner. The thumb points up and slightly left, its pad pressed flat as if touching a phone screen. The thumb tip is near the centre of the image.`
3. **`thumb_right_slide.png`:** `Only the right thumb and the edge of the right hand enter the frame from the lower right corner. The thumb is bent and lying almost sideways, as if sliding across a phone screen to the left. The thumb tip is near the centre of the image.`
4. **`hand_left_tool.png`:** `A left hand enters from the lower left, wrist visible, holding a small thin flat L-shaped plain steel bar (about 7 cm, like a small hex key) between thumb and index finger, pressing it gently sideways. Relaxed fingers.`
5. **`hand_right_tool.png`:** `A right hand enters from the lower right, wrist visible, holding a long thin plain steel tool like a dentist's probe with a tiny hook at the tip, held like a pencil, tip pointing up-left toward the centre.`
6. **`hand_right_open.png`:** `A right hand enters from the lower right, wrist visible, open and relaxed, palm down, fingers slightly apart, as if just letting go of something.`

Opcjonalnie: druga wersja najlepszego obrazu z dopiskiem `_alt`.

## Oddanie
ZIP `Lockwright_G22.zip` o strukturze `contrib/gpt/G22/images/<nazwa>.png` oraz pliki:
- `ASSETS.md`: przy każdym pliku narzędzie, data, pełny użyty prompt i czy był edytowany;
- `README.md` po polsku: co powstało, czego nie udało się zrobić i dlaczego.
