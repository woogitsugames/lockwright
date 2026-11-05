# T23 — raport przekazania (PL)

## Wykonano

- Napisano informację prasową zapowiadającą **Lockwright: Pogotowie Zamkowe / Lockwright: Locksmith on Call** w językach PL i EN.
- Napisano maile do dziennikarzy w obu językach: 106 i 124 słów odpowiednio (wraz z tematem i podpisem); oba poniżej limitu 150.
- Przygotowano listę **40 mediów i twórców**: **PL 10 / DE 10 / UK 10 / US 10**; każdy ma link, typ i indywidualne uzasadnienie.
- Zastosowano zasadę legalnego ślusarstwa i fikcyjnych mechanizmów, bez marek i instruktażu otwierania rzeczywistych zamków.
- Nie obiecywano daty wydania, ceny ani dostępności. Warstwę zleceń oznaczono jako planowaną.
- Nikogo nie kontaktowano.

## Lista plików

- `PRESS_RELEASE.md` — informacja prasowa PL/EN.
- `PITCH_EMAIL.md` — e-mail PL/EN (limit sprawdzony).
- `media_list.csv` — UTF-8, 40 pozycji + nagłówek, pięć kolumn: `market,name,website,type,why_fit`.
- `README.md` — raport i ograniczenia.

## Źródła repozytorium

Sprawdzono: `CLAUDE.md`, `docs/DESIGN.md`, `docs/CLIENTS.md`, `docs/JOBS.md`, `docs/DECISIONS.md`, `docs/MARKETING.md`, `site/README.md`, `site/public/index.html`.

**Ważne rozbieżności:** aktualna nazwa EN to „Lockwright: Locksmith on Call” według **D-32** (zamiast wcześniejszego „Emergency Locksmith” w `CLAUDE.md`). **D-06 i D-51** pozostawiają model biznesowy otwarty. **`docs/JOBS.md`** umieszcza Tryb Zleceń po MVP; komunikat nie traktuje tej części jako zapewnionej funkcji podstawowej wersji.

## Sprawdzenie listy mediów

Dobór oparto na przeglądzie stron i aktualnych przykładów publikacji z **5 listopada 2026 r.**, m.in.:
- https://www.pocketgamer.com/news/ — newsy mobilne.
- https://www.pockettactics.com/cosy-games — gry cozy.
- https://www.droidgamers.com/news/barda-backpack-roguelike/ — indie mobile.
- https://indiegamesplus.com/ — małe gry i zagadki.
- https://theindieinformer.com/ — odkrywanie nowych indyków.
- https://cdaction.pl/tag/gry-indie/ — polska publicystyka indie.
- https://www.pcgames.de/Indie-Games-Thema-239276/News/ — niemieckie wiadomości indie.
- https://indiearenabooth.de/ — kuratorstwo i prezentacje gier niezależnych.

Pole `market` to **segment kampanii**, a nie gwarancja siedziby redakcji w danym kraju. Lista zawiera także media branżowe i kuratorów (Indie Arena Booth, Wholesome Games) — nie wszystkie pozycje to standardowe redakcje informacyjne. Linki prowadzą do stron, nie do prywatnych kontaktów dziennikarzy.

## Nie wykonano / uwagi dla właściciela

- Nie ustalono adresu e-mail do kontaktu prasowego ani publicznego URL press kitu. W obu tekstach są jawne miejsca do uzupełnienia.
- Strona gry w `site/` jest przygotowana na Cloudflare Pages, ale decyzja D-51 nie zezwala jeszcze na jej publikację; dlatego nie wpisano hipotetycznego adresu.
- Nie przeprowadzono osobnej weryfikacji adresów do zgłoszeń i polityk redakcji — należy to zrobić przed kampanią.
- Nie wysyłano e-maili i nie prowadzono kontaktów z odbiorcami.
- Nie modyfikowano plików poza `contrib/gpt/T23/`.
