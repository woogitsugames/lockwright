# Publikacja strony na Cloudflare Pages (D-51) — przygotowane, NIEWŁĄCZONE

Strona jest statyczna i gotowa w `site/public/` (budowana i commitowana lokalnie: `python3 site/build.py --check`).
Cloudflare niczego nie buduje, tylko serwuje ten katalog. Bez JavaScriptu, ciasteczek i analityki (zgodnie z
`store/privacy.md`); nagłówki bezpieczeństwa: `site/_headers` (kopiowany do `site/public/`). Publikacja **dopiero na
sygnał właściciela**.

## Wariant A: integracja z GitHubem (zalecany, bez sekretów w repo)
1. Cloudflare → Workers & Pages → Create → Pages → *Connect to Git* → repo `woogitsugames/lockwright`, gałąź `main`.
2. Build: *Framework preset* „None”, *Build command* puste, *Build output directory* `site/public`.
3. *Save and Deploy*. Kolejne pushe z nową wersją `site/public/` wdrażają stronę same (Settings → Builds →
   *Build watch paths* = `site/public/*`, żeby inne commity nie uruchamiały wdrożeń).
4. Domena: Pages → Custom domains (DNS w Cloudflare albo CNAME u rejestratora).

## Wariant B: ręcznie (`wrangler`)
```bash
npx wrangler@3 pages deploy site/public --project-name lockwright --branch main
```
Wymaga `npx wrangler login` na koncie Cloudflare właściciela; `site/wrangler.toml` podaje katalog wyjściowy.

## Przed publikacją (właściciel)
- uzupełnić pola `[w nawiasach]` (kontakt, administrator danych, daty) — podświetlone na stronach;
- D-06/D-51: bez ceny i dostępności, dopóki model biznesowy jest otwarty;
- grafiki z dostaw AI są oznaczone w „Dla prasy” jako robocze.

Poprzedni wariant (GitHub Pages, `site/deploy/pages.yml`) usunięty zgodnie z D-51.
