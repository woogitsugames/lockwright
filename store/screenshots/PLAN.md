# Zrzuty do sklepów — plan

Status: szablon z renderami 2160 px (`art/renders/`) · aktualizacja 2026-11-05 (etap 2). Generator: `make_screens.py` (Pillow).
Podgląd: `contact_pl.png`, `contact_en.png` (8 kadrów, iPhone 6,9"). Pliki PNG do sklepów generuje się lokalnie (`out/` jest poza repo).

## Zasady
- Sceny fotorealistyczne, **bez paneli UI na ekranie zamka** (D-12). Bez ramek telefonów, gradientów, poświat.
- Podpis w jednolitym pasie u góry (`#14110E`, ciepła prawie czerń z palety realizmu), tekst kredowy `#F1EEE6`.
  Krój: Bona Nova Bold (podpis), Atkinson Hyperlegible Next (opcjonalna druga linia). Oba OFL, `mockups/fonts/`.
- Podpis ≤ ok. 40 znaków, maks. 2 linie, łamanie preferowane po kropce lub przecinku, marginesy boczne 7,5%.
- Pliki RGB bez kanału alfa (App Store odrzuca przezroczystość).
- Kolejność ma znaczenie: w wynikach wyszukiwania widać 1–3 pierwsze zrzuty.

## Rozmiary
| Cel | Rozmiar (px) | Status |
|---|---|---|
| App Store iPhone 6,9" (pion) | 1320 × 2868 | wymagany, generowany domyślnie |
| App Store iPhone 6,5" (pion) | 1284 × 2778 | generowany domyślnie (opcjonalny, gdy jest 6,9") |
| Google Play telefon (pion) | 1080 × 1920 | generowany domyślnie |
| App Store iPad 13" (pion) | 2064 × 2752 | tylko jeśli iPad zostaje (D-10): `--sizes ipad13` |

App Store skaluje 6,9" na mniejsze iPhone'y. Play przyjmuje 16:9 pion (2–8 zrzutów, boki 320–3840 px).

## Kadry (etap 2)

Zasada podpisów: tylko to, co gra robi już w etapie prototypu albo jest w zatwierdzonej biblii treści; żadnych liczb poziomów, rankingów ani „najbardziej realistyczna”.

| # | Kadr | Podpis PL | Podpis EN | Źródło | Uwagi / pokrycie w grze |
|---|---|---|---|---|---|
| 01 | Cały przekrój wkładki, wytrych pod trzecim kołkiem | Czujesz każdy kołek pod kciukiem. | Feel every pin under your thumb. | `section.png` (2160 × 2880) | pin_tumbler (lockcore), haptyka (spike 1–2) |
| 02 | Zbliżenie linii podziału, kołek ustawiony | Klik. Ten już siedzi. | Click. That one's set. | `section.png`, kadr 0,52 | zdarzenie `set` |
| 03 | Przekrój u góry, zwijka z narzędziami u dołu (D-12) | Lewy kciuk napina, prawy szuka. | Left thumb tensions, right thumb picks. | `section.png` + `tray.png` | sterowanie D-24; docelowo zrzut z gry (plan B, D-31) |
| 04 | Widok przez lupę: linia podziału przy kołku | Lupa pokazuje linię podziału. | The loupe shows the shear line. | `loupe.png` | D-13 (lupa na start) |
| 05 | Tryb „w ciemności”: przekrój wygaszony | Zgaś ekran. Graj dotykiem i słuchem. | Screen off. Play by touch and ear. | `section.png`, jasność 10% | tryb „w ciemności” (CLAUDE.md); bez narzędzi obserwacji (D-13) |
| 06 | Zwijka: wytrychy w kieszeniach | Zapasowe wytrychy. Licz je. | Spare picks. Count them. | `tray.png` | życia = wytrychy (D-12) |
| 07 | Zamek dźwigniowy w przekroju | Każdy mechanizm prosi o inną rękę. | Every mechanism asks for a different hand. | `lever.png` (1620 × 2160) | rodziny lever / lever_detector (lockcore v0.2); jeśli 1.0 ich nie zawiera, zamienić na `wafer.png` albo `warded.png` |
| 08 | Sprężyny i kołki w półmroku + linia o grze | Bez reklam. Bez sieci. Bez pośpiechu. / To gra, nie kurs. Zamki są wymyślone. | No ads. Offline. No rush. / A game, not a course. The locks are invented. | `section.png`, jasność 55% | D-06 (bez reklam), offline |

Wycofane z etapu 1: „Pani Halina czeka. Rosół też.” (brak kadru z klientem) i „Lupa, a potem gablota z historią.” (gablota bez renderu) — wrócą, gdy powstaną rendery i ekrany.

## Zamówienie dla sesji renderowej (art)
1. `section` w 2640 × 3520 (lub wyższej), te same ustawienia co obecny `section.png` — dla 01 i 03.
2. Makro linii podziału w stanie `set` i osobno `false set` (szpulka), 2640 × 3520 — dla 02 (i ewentualnie wariantu „szpulka kłamie”).
3. Zwijka z pełnym kompletem: 3 wytrychy w kieszeniach, napinacz, lupa, 2640 × 1060 — dla 03 i 04.
4. Tryb „w ciemności”: ten sam kadr co 01, światło klatki zgaszone, tylko słaby odblask — dla 05.
5. Drzwi kamienicy z emaliowaną tabliczką (bez numeru prawdziwego adresu) — dla 06.
6. Widok przez lupę (`loupe.png`) i gablota z eksponatem — dla 07.

Każdy nowy render wpisać do `docs/ASSETS.md`. Po dostarczeniu zmienić `src`, `focus`, `zoom` w `SHOTS` w `make_screens.py`.

## Rozmiar plików
48 plików (PL + EN × iPhone 6,9", 6,5", Android × 8) to ok. 44 MB nawet po `--quantize`, dlatego `out/` nie jest w repo. Do wysyłki: `python3 store/screenshots/make_screens.py --lang all` (pełne RGB, bez `--quantize`).

## Znane słabości makiet
- Rendery `section.png` mają już 2160 × 2880 px; zbliżenie 02 (kadr 0,52) jest nadal ok. 1,2× powiększone.
- W kadrach 04 i 07 widać krawędź renderu zwijki na jednolitym tle skóry (tło próbkowane z renderu, ale render ma winietę).
- Kadr 03 to zestawienie dwóch renderów, nie zrzut z gry; po ekranie zamka w planie B (D-31) zastąpić prawdziwym zrzutem.

## Etap 3: zrzuty z prawdziwej gry (2026-11-05)

`capture_game.sh` renderuje ekran zamka planu B (`lock_photoreal.tscn`, argumenty `--lw-sim/--lw-shot/--lw-dark/--lw-lives`)
w natywnym 1320 × 2868 na kopii `game/`; `make_screens.py --from-game <katalog>` podmienia kadry 01, 02, 03, 05, 06 na te
klatki (reszta zostaje z renderów). Podgląd: `contact_game_pl.png`, `contact_game_en.png`.

Job `game-screens` sesji B istnieje, ale na dziś nie daje artefaktu (`res://tests/screens.tscn` nie ma w repo, run #2
zakończony błędem) i renderuje 412 × 915 — za mało na 1320 × 2868. Dlatego własne przechwytywanie w rozdzielczości sklepu.

Uwagi do jakości (do poprawy przed wysyłką):
- kadry 01–03 są zbyt podobne: prosty skryptowany „wytrych” (`--lw-sim`) nie ustawia wyraźnie różnych stanów; lepiej
  odtworzyć powtórkę lockcore do wybranych chwil (set, false set) — potrzebny argument `--lw-replay` w scenie (sesja A);
- wgniecenia kciuków (`--lw-touch 1`) nie są widoczne w tej rozdzielczości; podpis 03 („Lewy kciuk napina…”) wymaga ich;
- kadr 06 („Zapasowe wytrychy”) — `--lw-lives 1` do sprawdzenia na pełnym rozmiarze;
- menu (lista zleceń, warsztat, gablota) przy `--write-movie` renderują się w 412 × 915 i w domyślnym wyglądzie
  silnika — nie nadają się do sklepu (zob. audyt A11Y, runda 2).
