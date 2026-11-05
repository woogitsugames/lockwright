# G13 — Store feature graphic and key art

**Data:** 2026-11-05 · **repo:** woogitsugames/lockwright · **katalog:** contrib/gpt/G13/

## Oddane w tej sesji

W rozmowie dostarczono **Lockwright_G13_store_art_complete.zip** (22 MiB): cztery fotorealistyczne key arty 3840×2160 / 2160×3840 (z polem pod tytuł i bez), dwa feature graphic Google Play 1024×500, 6 banerów social PL/EN, 3 warianty logotypu PL/EN w SVG (kontury) i PNG, arkusz podglądowy, skrypt `generate_g13.py`, `ASSETS.md` i manifest SHA256.

**Ważne ograniczenie GitHuba:** dostępny konektor pozwala atomowo zapisywać tekst i wskazywać istniejące bloby, ale nie przyjmuje lokalnych plików PNG/JPEG. W tej ścieżce repozytorium zapisano więc komplet wariantów **SVG**, 6 logotypów SVG, arkusz SVG, kopię repozytoryjnego renderu klatki schodowej i warsztatu oraz generator alternatywnych rastrów `render_repo_fallback.py`. **Fotograficzne rastry AI i oryginalne źródła AI są tylko w dostarczonym ZIP, nie w tym commicie.** SVG w repo odwołują się do obrazów `source/` i mają dokładne wymiary.

## Pliki repozytoryjne

- `source/stairwell-render.png` — istniejący render z `art/renders/stairwell.png` (skopiowany bez zmian).
- `source/workshop-reference.jpg` — istniejący podgląd z `mockups/realizm/img/workshop.jpg`.
- `key-art/*.svg` — 3840×2160 i 2160×3840, czyste/z miejscem na tytuł.
- `feature/*.svg` — Google Play 1024×500, bez tekstu/z tytułem.
- `social/*.svg` — kwadrat 1080×1080, pion 1080×1920, panorama 1500×500, PL i EN.
- `logos/*.svg` — 3 pomysły na logotyp z podpisem PL/EN.
- `preview/contact-sheet.svg` — arkusz poglądowy wariantów repozytoryjnych.
- `render_repo_fallback.py` — opcjonalny, offline eksport JPG do podanych wymiarów (Pillow + zainstalowany EB Garamond OFL).

## Ocena i zalecenia

W pełnej paczce ZIP rekomendujemy **logotyp 1** i poziomy key art z miejscem na tytuł. Wszystkie obrazy podkreślają przyjazd fachowca, pomoc i spokojną atmosferę. Bez estetyki złodzieja, instruktażu i nazw produktów. Warsztat w paczce jest tylko szkicem niskiej rozdzielczości. Źródła AI 1672×941 zostały przeskalowane — eksporty 4K mają dokładne rozmiary, ale nie dodatkowe natywne szczegóły. Przed publikacją sprawdzić aktualne wymagania sklepu i stosować prawdziwe zrzuty aplikacji tam, gdzie są wymagane.

Zasady: `docs/styles/realizm.md`, `docs/HUD.md`, `docs/MARKETING.md`, `store/listing.md`. Nic poza `contrib/gpt/G13/` nie zostało zmienione.
