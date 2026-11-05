# site/ — strona gry (sesja C, etap 3, zadanie 5)

Statyczny HTML bez frameworków i bez JavaScriptu, PL (`/`) i EN (`/en/`): strona główna, „Jak gramy uczciwie” (`fair.html`: weryfikacja prawa do lokalu, odmowy, „to gra, nie kurs”), dla prasy, polityka prywatności, kontakt.

```bash
python3 site/build.py --check   # buduje site/public/ i sprawdza: zakazane frazy i style, linki, alt, rozmiar ≤ 8 MB
```

- **Treść nie jest przepisywana ręcznie:** press kit pochodzi z `docs/MARKETING.md` §3.1/3.2, polityka prywatności z `store/privacy.md` §1/§2. Po zmianie tych plików wystarczy przebudować.
- Obrazy: rendery z `art/renders/` (800 i 1600 px, JPEG) i makiety z `mockups/realizm/png/` (480 px) — kopie pochodne, wpisane w `docs/ASSETS.md`.
- Fonty: Bona Nova (nagłówki) i Atkinson Hyperlegible Next (tekst), SIL OFL 1.1, kopiowane z `mockups/fonts/` razem z licencjami.
- Kolory: kreda `#F1EEE6` i ciepła prawie-czerń `#14110E` (MARKETING §0), tryb ciemny wg ustawień systemu; linki „stary mosiądz” (kontrast ≥ 7:1). Bez gradientów, cieni-poświat, glassmorphismu i kart SaaS (DESIGN.md / CLAUDE.md).
- Dostępność: cele nawigacji 48 px, `skip link`, `alt` przy każdym obrazie, safe-area, `prefers-reduced-motion`, brak poziomego przewijania przy 412 px.
- Pola `[w nawiasach]` (kontakt, administrator, daty, cena wg D-06) są podświetlone — uzupełnia właściciel.

**Publikacja:** workflow `site/deploy/pages.yml` jest przygotowany, ale **niewłączony** (wymaga zgody właściciela i włączenia Pages w ustawieniach repo). Instrukcja w nagłówku pliku.

**Część 2 (etap 4):** gdy w `contrib/REVIEW.md` G12 (ikona) i G13 (key art) dostaną status „przyjęte”, ich kopie trafią
do `site/assets/` (wpis w `docs/ASSETS.md`), a strona główna i press kit dostaną ikonę i key art.
**Zrobione 2026-11-05 (etap 5):** `site/assets/icon-{180,512}.png` z G12 v2 (kierunek 01, rekomendacja — do potwierdzenia przez właściciela), `key-art-{800,1600}.jpg` z G13 v1 16:9 (bez pasów); ikona jako favicon/apple-touch-icon, key art na stronie głównej (pełne 16:9, bez kadrowania), oba do pobrania w „Dla prasy”. Publikacja dalej wyłączona.
