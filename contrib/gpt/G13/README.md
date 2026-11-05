# G13 — Grafiki sklepowe i key art gry Lockwright

**Status:** kompletny zestaw eksportów lokalnych, 2026-11-05.

## Wykonano

- Dwie kompozycje key art o dokładnych rozmiarach **3840×2160** i **2160×3840**, każda w wariancie czystym i z polem na logo.
- Feature graphic Google Play **1024×500**: wersja bez napisu i wersja z tytułem „Lockwright”.
- Trzy formaty social **1080×1080**, **1080×1920** i **1500×500**, każdy osobno PL i EN.
- Trzy warianty logotypu „Lockwright” w **SVG (kontury)** i **przezroczystym PNG**, każdy z dopiskiem PL „Pogotowie Zamkowe” albo EN „Locksmith on Call”.
- Arkusz porównawczy `preview/contact-sheet.jpg` i pomocnicze studia detalu oraz warsztatu.
- Pełna dokumentacja pochodzenia źródeł i eksportów (`ASSETS.md`), skrypt odtwarzający (`generate_g13.py`) oraz kontrola rozdzielczości/SHA256 (`manifest.json`).

## Pliki

| Plik | Wymiary | Zastosowanie |
|---|---|---|
| `feature/google-play-1024x500-clean.png` | 1024×500 | grafika Google Play |
| `feature/google-play-1024x500-title.png` | 1024×500 | grafika Google Play |
| `feature/google-play-title-overlay.svg` | SVG / źródło | grafika Google Play |
| `key-art/key-art-2160x3840-clean.jpg` | 2160×3840 | fotorealistyczny key art |
| `key-art/key-art-2160x3840-logo-space.jpg` | 2160×3840 | fotorealistyczny key art |
| `key-art/key-art-3840x2160-clean.jpg` | 3840×2160 | fotorealistyczny key art |
| `key-art/key-art-3840x2160-logo-space.jpg` | 3840×2160 | fotorealistyczny key art |
| `logos/concept-01-en.png` | 1600×470 | logotyp ze zmodyfikowanymi konturami OFL |
| `logos/concept-01-en.svg` | SVG / źródło | logotyp ze zmodyfikowanymi konturami OFL |
| `logos/concept-01-pl.png` | 1600×470 | logotyp ze zmodyfikowanymi konturami OFL |
| `logos/concept-01-pl.svg` | SVG / źródło | logotyp ze zmodyfikowanymi konturami OFL |
| `logos/concept-02-en.png` | 1600×470 | logotyp ze zmodyfikowanymi konturami OFL |
| `logos/concept-02-en.svg` | SVG / źródło | logotyp ze zmodyfikowanymi konturami OFL |
| `logos/concept-02-pl.png` | 1600×470 | logotyp ze zmodyfikowanymi konturami OFL |
| `logos/concept-02-pl.svg` | SVG / źródło | logotyp ze zmodyfikowanymi konturami OFL |
| `logos/concept-03-en.png` | 1600×470 | logotyp ze zmodyfikowanymi konturami OFL |
| `logos/concept-03-en.svg` | SVG / źródło | logotyp ze zmodyfikowanymi konturami OFL |
| `logos/concept-03-pl.png` | 1600×470 | logotyp ze zmodyfikowanymi konturami OFL |
| `logos/concept-03-pl.svg` | SVG / źródło | logotyp ze zmodyfikowanymi konturami OFL |
| `preview/contact-sheet.jpg` | 2600×4200 | arkusz kontrolny lub studium |
| `preview/oak-and-brass-detail-1080x1920.jpg` | 1080×1920 | arkusz kontrolny lub studium |
| `preview/workshop-concept-lowres.jpg` | 1500×840 | arkusz kontrolny lub studium |
| `social/social-1080x1080-en.jpg` | 1080×1080 | baner PL/EN |
| `social/social-1080x1080-pl.jpg` | 1080×1080 | baner PL/EN |
| `social/social-1080x1920-en.jpg` | 1080×1920 | baner PL/EN |
| `social/social-1080x1920-pl.jpg` | 1080×1920 | baner PL/EN |
| `social/social-1500x500-en.jpg` | 1500×500 | baner PL/EN |
| `social/social-1500x500-pl.jpg` | 1500×500 | baner PL/EN |
| `source/arrival-bag.png` | 1672×941 | oryginał AI do rekonstrukcji eksportów |
| `source/arrival-evening.png` | 1672×941 | oryginał AI do rekonstrukcji eksportów |
| `source/arrival-landing.png` | 1672×941 | oryginał AI do rekonstrukcji eksportów |
| `source/study-sheet.png` | 1672×941 | oryginał AI do rekonstrukcji eksportów |

## Rekomendacje

**Rekomendowany logotyp: koncepcja 1** (najczytelniejszy tytuł w miniaturach i najbardziej neutralny krój szeryfowy). Koncepcja 2 nadaje się do emaliowanej tabliczki przy drzwiach; 3 do materiałów redakcyjnych i limitowanych.

**Rekomendowany key art:** `key-art/key-art-3840x2160-logo-space.jpg` + logotyp 1 w jednej wersji językowej na lewej części kadru. W pionie użyć `key-art-2160x3840-logo-space.jpg`; logo lokować poza twarzą i torbą. Przy produkcji sklepów sprawdzić fizyczne marginesy po skalowaniu i cropach.

## Co się nie udało / ryzyka

- Generator obrazu udostępnił bazowy kadr poziomy (1672×941); portret uzyskano **uczciwym kadrowaniem i skalowaniem**, bez dopowiadania szczegółów. Dotyczy to też zwiększenia wielkości do 4K.
- Warsztat: przygotowano tylko `preview/workshop-concept-lowres.jpg` jako szkic, nie pełnowymiarową finalną ilustrację. Przy docelowym wariancie warto użyć renderu `art/blender/workshop.py` z repozytorium.
- W ramach zlecenia nie wprowadzano żadnych zmian poza `contrib/gpt/G13/`. Materiały nie obiecują niezatwierdzonych funkcji ani modelu płatności.
- Obrazy AI pokazują fikcyjne postacie i ogólne rekwizyty; przed użyciem jako ilustracji rzeczywistej rozgrywki trzeba zastąpić je nagraniami z gry.

## Odtworzenie

W środowisku z Pythonem 3, Pillow, FontTools, CairoSVG, EB Garamond 12 (OFL) i Lato (OFL): `python3 generate_g13.py`. Skrypt czyta cztery pliki `source/*.png` z paczki i nadpisuje wyjścia w bieżącym katalogu G13. Nie jest wymagany dostęp do usług obrazowych.

**Notatka dla zespołu:** spójność z `docs/styles/realizm.md`, `docs/HUD.md`, `docs/MARKETING.md`, `store/listing.md`. Identyfikacja korzysta z naturalnych ciepłych faktur, bez neonu, chromu, paneli HUD ani estetyki włamania.
