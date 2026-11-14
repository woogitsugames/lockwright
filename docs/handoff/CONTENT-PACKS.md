# Paczki treści — jak wydać rozdział do pobrania (D-112)

Krótko dla właściciela. Szczegóły techniczne: `docs/TECH.md` §9.4, decyzja: `docs/DECISIONS.md` D-112.

## Co to jest

Rozdział, który nie mieści się w bazie gry (limit AAB 200 MB, D-99), wychodzi jako osobny plik pobierany z poziomu gry —
tak samo jak głosy: z GitHub Releases, zwykłym pobraniem HTTPS, ze sprawdzeniem sumy SHA-256. Gracz widzi rozdział na
liście zleceń z rozmiarem i przyciskiem „Pobierz”; usuwa go w Ustawieniach → „Rozdziały do pobrania”. Postępy zostają.

## Jakie paczki są (D-131, 2026-11-14)

Baza gry to rozdziały 1–12 (83 zlecenia). Rozdziały 13–16 są paczkami, po jednej na rozdział:

| Paczka | Rozdział | Zlecenia | Rozmiar pliku (build lokalny) | Wydanie GitHub |
|---|---|---|---|---|
| `ch13` | 13 „Wiosenne porządki” | 10 (+ 2 plansze przyjazdu) | ok. 0,25 MB | `content-ch13-v1` — **jeszcze nie wydane** |
| `ch14` | 14 „Lato za progiem” | 10 | ok. 0,14 MB | `content-ch14-v1` — **jeszcze nie wydane** |
| `ch15` | 15 „Powroty” | 10 | ok. 0,15 MB | `content-ch15-v1` — **jeszcze nie wydane** |
| `ch16` | 16 „Przed zimą” | 10 | ok. 0,16 MB | `content-ch16-v1` — **jeszcze nie wydane** |

Paczki są małe, bo rozdziały 13–16 to dziś głównie teksty i dane; urosną z własnymi scenkami przyjazdu.
Nazwy i opisy rozdziałów (`chapter.13…16.name/.desc`) są w bazie. Kwestie głosowe zostają w paczkach głosów.

**Dopóki wydania nie istnieją, gracz nie widzi rozdziałów 13–16 wcale** (ani nagłówka, ani wiersza „Pobierz”):
w `game/data/content_packs.json` paczki mają wpisy *oczekujące* — bez adresu, rozmiaru i sumy SHA-256. Gra zna z nich
tylko listę zleceń, więc zapis z postępem w rozdziałach 13+ (np. z wcześniejszego builda testowego) niczego nie traci.
W edytorze, w testach i u bota QA rozdziały działają normalnie.

## Jak opublikować paczki (koordynator / właściciel)

1. Sprawdzić, że ostatni przebieg `content-packs` na `main` jest zielony (po zwykłym pushu to tylko próba:
   walidacja + budowa, **bez wydania**; zbudowane pliki są w artefakcie `content-packs-dry-run`).
2. Uruchomić workflow ręcznie: GitHub → Actions → **content-packs** → *Run workflow* → gałąź `main`
   (pole `base_url` zostawić puste), albo z terminala: `gh workflow run content-packs.yml --ref main`.
3. Workflow sam: buduje cztery pliki `content_ch13.pck` … `content_ch16.pck`, tworzy wydania `content-ch13-v1` …
   `content-ch16-v1` (w każdym plik `.pck` i jego opis `.json`), wpisuje do `game/data/content_packs.json` adres
   (`https://github.com/woogitsugames/lockwright/releases/download/content-ch13-v1/content_ch13.pck` itd.), rozmiar
   i SHA-256 dokładnie tych plików, commituje manifest na `main` („content packs: manifest for content-ch13-v1 …”)
   i uruchamia build `game-android`.
4. Poczekać na ten commit i zielony `game-android`, zainstalować build z tego commita i sprawdzić na telefonie:
   lista zleceń → pod rozdziałem 12 nagłówek rozdziału 13 z rozmiarem → **Pobierz** → zlecenia grywalne →
   Ustawienia → „Rozdziały do pobrania” → **Usuń** → wiersz wraca, postępy zostają.
5. Dopiero ten AAB (z manifestem) wgrać do Play. Starszy build paczek nie zobaczy.

Niczego nie wpisujemy do manifestu ręcznie — adres i sumę zna tylko workflow, bo liczy je z plików, które sam wgrał.

## Jak przenieść rozdział do paczki (same pliki, bez kodu)

Tak zostały przeniesione rozdziały 13–16 (D-131); kolejny rozdział robi się tak samo. Przykład: rozdział 13 jako
paczka `ch13`. Wszystko trafia do `game/packs/ch13/`:

1. `pack.json`:
   `{"schema": "lockwright.content_pack/1", "id": "ch13", "version": 1, "min_game": 1, "chapters": [13]}`
2. `jobs/` — pliki zleceń rozdziału przeniesione z `game/data/jobs/` (`git mv`).
3. `i18n/content.csv` — wiersze tych zleceń wycięte z `game/i18n/content.csv` (nagłówek `keys,en,pl,de,fr,es`).
   Nazwa i opis rozdziału (`chapter.13.name`, `chapter.13.desc`) **zostają w bazie** — nagłówek widać przed pobraniem.
4. `arrival_scenes.json` — wpisy scenek tych zleceń wycięte z `game/data/arrival_scenes.json`, z `dir` zmienionym na
   `res://packs/ch13/arrival/<zlecenie>`; foldery klatek przeniesione z `game/assets/arrival/` do `game/packs/ch13/arrival/`.
5. `python3 tools/build_content_packs.py --sync` (dopisuje listę zleceń do `pack.json` i wpis oczekujący paczki do
   `game/data/content_packs.json`), otworzyć projekt w Godocie albo `godot --headless --path game --import`, jeszcze raz
   `--sync` (ustawia `compress=0` dla nowego CSV), jeszcze raz import, potem
   `python3 tools/build_content_packs.py --check` — musi wypisać `content packs OK: ch13, …`.
   Grafika przeniesiona z `game/assets/` dostaje nowy plik `.import` z ustawieniami domyślnymi — przepisać do niego
   ustawienia ze starego (`compress/mode`, `compress/lossy_quality`, `process/size_limit`) i zaimportować ponownie.
6. Commit razem z plikami `.import` (`git add -f game/packs/ch13`), push na `main`.

To może zrobić agent jednym zadaniem („przenieś rozdział 13 do paczki ch13”). W edytorze i w testach rozdział działa
dalej normalnie — folder na dysku liczy się jak część gry.

## Co dzieje się po pushu, a co po ręcznym uruchomieniu (D-131)

- **Push** zmieniający `game/packs/**`: `content-packs.yml` sprawdza źródła, buduje pliki i sprawdza, że są w nich tylko
  dane. **Niczego nie wydaje** i nie zmienia manifestu — to próba.
- **Ręczne uruchomienie** (*Run workflow*): to samo, a potem wydania GitHub dla wersji, których jeszcze nie ma,
  commit `game/data/content_packs.json` i build Androida (kroki w „Jak opublikować paczki”).

**Paczka działa dopiero w buildzie gry, który ma manifest z jej adresem i sumą** — do Play trzeba wgrać nowy AAB.

## Poprawka w wydanej paczce

Zmienić pliki w `game/packs/ch13/`, **podnieść `version`** w `pack.json` (2, 3, …), wypchnąć i uruchomić workflow
ręcznie. Bez podniesienia wersji build się zatrzyma z komunikatem — wydanej wersji nie nadpisujemy. Gracze po
aktualizacji gry pobiorą rozdział ponownie (stary plik gra usuwa sama; postępy zostają).
Przed pierwszym wydaniem (wpis oczekujący) paczkę można zmieniać bez podnoszenia wersji; po zmianie listy zleceń
uruchomić `--sync`.

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
  Rozdziały 13–16: paczka zasobów Androida 121,36 → 120,85 MB (−0,5 MB; próg ostrzeżenia 170 MB).
- **Bot QA** (`qa/run_career.sh`) buduje paczki z kopii gry, usuwa ich foldery i przechodzi karierę jak gracz:
  zaczyna z 83 zleceniami, każdy rozdział 13–16 pobiera tabliczką „Pobierz” z listy zleceń (kopia pliku zamiast
  HTTPS, sprawdzenie sumy i montaż robi kod gry). `QA_PACKS=bundled` wyłącza to (foldery jak w edytorze).
- **Scenki przyjazdu paczki:** `art/tools/arrival_export.py --data game/packs/<id>/arrival_scenes.json` zapisuje
  klatki pod `game/packs/<id>/arrival/…`.
