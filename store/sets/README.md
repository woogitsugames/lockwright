# Zestawy grafik do App Store i Google Play (etap 5, zadanie 3)

`python3 store/tools/build_store_set.py --game <katalog z capture_game.sh> [--icon 01_enamel_l]` buduje komplet
(pełne RGB, ok. 92 MB, **poza repo**, domyślnie `/tmp/lw_store_set`) i sprawdza limity sklepów. W repo zostają tylko
`REPORT.md` (57 kontroli), `manifest.json` i podglądy `contact_pl.jpg` / `contact_en.jpg`.

| Element | Wymiar | Źródło | Stan |
|---|---|---|---|
| App Store: zrzuty iPhone 6,9" i 6,5" (PL, EN × 8) | 1320×2868, 1284×2778, RGB bez alfy | `make_screens.py --from-game`: kadry 01, 02, 03, 05, 06 z prawdziwego ekranu zamka (Vulkan lavapipe, 1320×2868), reszta z renderów | ✅ w limitach |
| App Store: ikona | 1024×1024 RGB bez alfy | G12 v2, kierunek **01 tabliczka „L”** (rekomendacja; wybór właściciela) | ✅ |
| Google Play: zrzuty telefonu (PL, EN × 8) | 1080×1920, ≤ 8 MB, proporcja ≤ 2:1 | jak wyżej | ✅ |
| Google Play: ikona | 512×512 PNG ≤ 1 MB (+ warstwy adaptive 432) | G12 v2 / 01 | ✅ |
| Google Play: feature graphic | 1024×500 JPG bez alfy | G13 v1 `google-play-1024x500-title` (bez pasów; G13 v2 zlecone) | ✅ |

## Co jeszcze nie jest gotowe do wysyłki
- **Kadry 01–03 i 06 są prawie takie same** (ten sam przekrój pin_tumbler z innym stanem kołków). Lepszy zestaw:
  kadr z klientem (przyjazd: tło G07, portret G09, `capture_game.sh` robi już `arrival_pl/en.png`), ale ekran ma
  dziś 3 puste przyciski i domyślne przyciski silnika (N-36) — po poprawce B podmienić nim kadr 02.
- Kadr 07 (dźwignia) to render, nie gra; rodziny GEM2 mają nierozróżnialne stany (contrib/REVIEW.md) — po poprawce
  zrobić zrzut lever z gry.
- Ikona i feature graphic czekają na decyzję właściciela (G12: kierunek; G13 v2: logotyp).
- Na tle przyjazdu „Rosół na gazie” drzwi mają numer 12, a tabliczka w UI pokazuje 7 (N-47).
