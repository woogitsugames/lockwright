## v2 — fotopochodne tekstury drzwi (2026-11-05)

W `v2/` przygotowano cztery nowe materiały: stary dąb satynowy, dąb w butelkowej zieleni, łuszczącą się kremową sosnę i ciemny orzech. Każdy materiał ma bezszwowe albedo (RGB PNG 2048²), height (16-bit PNG 2048², względny), roughness (8-bit PNG 2048²) i podgląd powtarzania 2×2. Dodatkowo są dwa ujęcia dębowych drzwi z mosiężnym szyldem, podglądy zbiorcze, źródłowe wycinki z generacji obrazowej, skrypt składania i `v2/QA.json`. Pełna dokumentacja i proweniencja: `v2/README.md` i `v2/ASSETS.md`.

**Ograniczenie:** generator zwracał plansze, więc albedo powstało z kadrowanych fragmentów 213–380 px, a nie z natywnych fotografii 2048 px. Bezszwowość 12 map potwierdzona pikselowo, ale jakości makro nie można uznać za spełnioną bez nowych pełnokadrowych źródeł. Stara wersja G03 pozostaje bez zmian.
