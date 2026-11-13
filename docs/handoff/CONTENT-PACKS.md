# Paczki treści — jak wydać rozdział do pobrania (D-112)

Krótko dla właściciela. Szczegóły techniczne: `docs/TECH.md` §9.4, decyzja: `docs/DECISIONS.md` D-112.

## Co to jest

Rozdział, który nie mieści się w bazie gry (limit AAB 200 MB, D-99), wychodzi jako osobny plik pobierany z poziomu gry —
tak samo jak głosy: z GitHub Releases, zwykłym pobraniem HTTPS, ze sprawdzeniem sumy SHA-256. Gracz widzi rozdział na
liście zleceń z rozmiarem i przyciskiem „Pobierz”; usuwa go w Ustawieniach → „Rozdziały do pobrania”. Postępy zostają.

**Dziś nie ma żadnej paczki** — mechanizm jest gotowy, rozdział 13 powstaje w bazie gry.

## Jak przenieść rozdział do paczki (same pliki, bez kodu)

Przykład: rozdział 13 jako paczka `ch13`. Wszystko trafia do `game/packs/ch13/`:

1. `pack.json`:
   `{"schema": "lockwright.content_pack/1", "id": "ch13", "version": 1, "min_game": 1, "chapters": [13]}`
2. `jobs/` — pliki zleceń rozdziału przeniesione z `game/data/jobs/` (`git mv`).
3. `i18n/content.csv` — wiersze tych zleceń wycięte z `game/i18n/content.csv` (nagłówek `keys,en,pl,de,fr,es`).
   Nazwa i opis rozdziału (`chapter.13.name`, `chapter.13.desc`) **zostają w bazie** — nagłówek widać przed pobraniem.
4. `arrival_scenes.json` — wpisy scenek tych zleceń wycięte z `game/data/arrival_scenes.json`, z `dir` zmienionym na
   `res://packs/ch13/arrival/<zlecenie>`; foldery klatek przeniesione z `game/assets/arrival/` do `game/packs/ch13/arrival/`.
5. `python3 tools/build_content_packs.py --sync` (dopisuje listę zleceń do `pack.json`), otworzyć projekt w Godocie albo
   `godot --headless --path game --import`, jeszcze raz `--sync` (ustawia `compress=0` dla nowego CSV), potem
   `python3 tools/build_content_packs.py --check` — musi wypisać `content packs OK: ch13`.
6. Commit razem z plikami `.import` (`git add -f game/packs/ch13`), push na `main`.

To może zrobić agent jednym zadaniem („przenieś rozdział 13 do paczki ch13”). W edytorze i w testach rozdział działa
dalej normalnie — folder na dysku liczy się jak część gry.

## Co dzieje się po pushu

`content-packs.yml` buduje `content_ch13.pck`, sprawdza, że są w nim tylko dane, tworzy wydanie GitHub
`content-ch13-v1`, zapisuje rozmiar i SHA-256 w `game/data/content_packs.json` i uruchamia build Androida.
**Paczka działa dopiero w buildzie gry, który ma ten manifest** — do Play trzeba wgrać nowy AAB.

Kolejność wydania: (1) push paczki → poczekać na zielony `content-packs` i commit manifestu, (2) build `game-android`
z tego commita, (3) sprawdzić na telefonie: rozdział „do pobrania” → Pobierz → zlecenia grywalne → Usuń, (4) AAB do Play.

## Poprawka w wydanej paczce

Zmienić pliki w `game/packs/ch13/`, **podnieść `version`** w `pack.json` (2, 3, …) i wypchnąć. Bez podniesienia wersji
build się zatrzyma z komunikatem — wydanej wersji nie nadpisujemy. Gracze po aktualizacji gry pobiorą rozdział ponownie
(stary plik gra usuwa sama; postępy zostają).

## O czym pamiętać

- **Polityka prywatności:** tekst publiczny mówi już o rozdziałach do pobrania (zrobione 2026-11-13, D-128; opis w
  `docs/handoff/PLAY-DATA-SAFETY.md` §3). Odpowiedzi Data safety się nie zmieniają. Polityka zakłada **ten sam host co głosy**
  i pobranie **tylko po stuknięciu „Pobierz”** — zmiana któregoś z tych dwóch wymaga poprawki tekstu przed wydaniem.
- **Nowy rodzaj treści wymagający kodu** (np. nowa rodzina zamka): podnieść `GAME_LEVEL` w
  `game/scripts/autoload/content_packs.gd` i `min_game` w paczce. Starsza gra pokaże wtedy „wymaga nowszej wersji gry”.
- **Hosting:** adres bazowy można zmienić bez kodu (zmienna repo `CONTENT_PACKS_BASE_URL`, np. Cloudflare — D-51).
- **Głosy:** kwestie zleceń z paczki zostają w paczkach głosów (EN w bazie).
- **Walidatory (D-115):** `data/tools/validate.py`, `data/tools/loc_qa.py`, `tools/i18n_lint.py` i `tools/voice_lines.py`
  czytają też `game/packs/<id>/` — teksty i zlecenia paczki są sprawdzane tak samo jak w bazie, także przed wydaniem paczki.
- **Budżet:** po przeniesieniu rozdziału sprawdzić `qa/budget` — AAB powinien spaść o rozmiar klatek scenek.
