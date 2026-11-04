# Lockwright — instrukcje dla Claude

**Gra:** Lockwright (PL: „Lockwright: Pogotowie Zamkowe”, EN: „Lockwright: Emergency Locksmith”).
Mobilna gra premium o ślusarzu z pogotowia zamkowego. iOS wiodący, Android drugi.

## Etap bieżący: research, biblia treści, tożsamość wizualna, plan techniczny
- To **nie jest produkcja**. Kodu gry nie piszemy, dopóki właściciel nie wybierze stylu (docs/styles) i silnika (docs/TECH.md).
- Makiety w `mockups/` to narzędzie projektowe (HTML/SVG/Canvas, ew. three.js), nie kod gry.

## Język
- Z właścicielem: po polsku.
- Kod, komentarze, nazwy plików: po angielsku.
- Teksty dla gracza: wyłącznie przez i18n, PL + EN od pierwszego dnia.

## Ton i odpowiedzialność
- Ciepły i legalny: pomagamy ludziom, nie włamujemy się. Ślusarz weryfikuje prawo do lokalu.
- Mechanizmy wymyślone, na poziomie encyklopedycznym. Zero marek zamków i samochodów, zero instrukcji do realnych, nazwanych produktów.
- W grze krótka informacja: to gra, nie kurs.

## Zasady wizualne (skrót; pełna lista: docs/DESIGN.md)
- Zakazane: gradienty fiolet-niebieski / teal-orange, glassmorphism, neon, bloom na metalu, karty SaaS, emoji jako ikony,
  Inter/Roboto/systemowy jako jedyny krój, „Welcome!”/„Get Started”, dziurka od klucza na czerni, złoty blask na pinie,
  zielony ptaszek/czerwony X, pasek wytrzymałości, chrom, szare muzeum, estetyka złodzieja, złota kłódka na ciemnym tle,
  pastisz (sepia, „steampunk” z martwymi zębatkami, faktury ze stocku).
- Wymagane: grafika tłumaczy mechanikę; każdy stan (binding, set, overset, false set, bliskie złamanie) rozróżnialny
  w skali szarości, z trzema kanałami (kształt/ruch, dźwięk, haptyka); elementy ≥ 28 dp; linia podziału ≥ 2 dp;
  kontrast metal/tło ≥ 3:1; cele dotyku ≥ 48 dp / 44 pt; safe-area; pion podstawowy, poziom sprawdzony; animacje 100–250 ms.
- Haptyka nigdy nie jest jedynym kanałem (XAG 103/110).

## Repo
- Praca bezpośrednio na `main` (decyzja właściciela, D-02): małe, opisowe commity, push na bieżąco. PR tylko na prośbę właściciela.
- Na bieżąco wysyłamy właścicielowi zrzuty ekranów (makiety, potem gra).
- Zależności deweloperskie (Vite, Playwright, three.js) tylko w `mockups/`.
- Fonty tylko OFL; grafiki/dźwięki tylko własne lub CC0; każdy zasób wpisany do `docs/ASSETS.md`.
- Nie kopiujemy kodu, grafik, nazw ani UI cudzych gier.
- Decyzje właściciela (styl, silnik, zakres, model biznesowy): pytać z rekomendacją. Pozostałe: rozstrzygać i zapisywać w `docs/DECISIONS.md` (D-NN).
- Agenci: na etapie researchu max 5 równolegle; w dalszym rozwoju max 2–3. Agenci nie uruchamiają kolejnych agentów.

## Komendy
```bash
cd mockups && npm install          # zależności makiet (Playwright korzysta z preinstalowanego Chromium)
cd mockups && npm run render       # renderuje makiety do PNG (412×915 i 915×412 @2x) + skala szarości + 50% jasności
cd mockups && node tools/render.mjs klatka         # jeden kierunek
cd mockups && node tools/contrast.mjs klatka/palette.json   # kontrast WCAG + daltonizm
cd mockups && node tools/contact.mjs               # zestawienie kierunków: compare/contact.png
```

## Mapa dokumentów
- `docs/RESEARCH.md` — rynek, konkurencja, model biznesowy, ryzyka, sprawdzenie tytułu
- `docs/LOCKS.md`, `docs/TOOLS.md`, `docs/PROGRESSION.md`, `docs/JOBS.md`, `docs/SHOWCASE.md` — biblia treści
- `docs/ARCHITECTURE.md` — architektura (szkic), `docs/TECH.md` — silnik, haptyka, spike'i, CI
- `docs/DESIGN.md` — kod stanów, kryteria akceptacji prototypu, zasady UI
- `docs/styles/*.md` + `mockups/<kierunek>/` — kierunki wizualne
- `docs/DECISIONS.md`, `docs/ASSETS.md`
