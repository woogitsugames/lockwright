# Zrzuty do sklepów — plan

Status: robocze makiety z istniejących renderów · 2026-11-04. Generator: `make_screens.py` (Pillow).

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
| Google Play telefon (pion) | 1080 × 1920 | generowany domyślnie |
| App Store iPad 13" (pion) | 2064 × 2752 | tylko jeśli iPad zostaje (D-10): `--sizes ipad13` |

App Store skaluje 6,9" na mniejsze iPhone'y. Play przyjmuje 16:9 pion (2–8 zrzutów, boki 320–3840 px).

## Kadry

| # | Kadr | Podpis PL | Podpis EN | Źródło | Status |
|---|---|---|---|---|---|
| 01 | Cały przekrój wkładki w drzwiach, wytrych pod trzecim kołkiem, napinacz po lewej | Czujesz każdy kołek pod kciukiem. | Feel every pin under your thumb. | `section.png`, pełny kadr | OK jako makieta. **Nowy render** w wyższej rozdzielczości |
| 02 | Zbliżenie linii podziału: czwarty kołek ustawiony (stopka nad linią, szczelina pod spodem) | Klik. Ten już siedzi. | Click. That one's set. | `section.png`, kadr 0,52 | **Nowy render**: makro w stanie `set`, ostre (obecny kadr to ok. 4× powiększenie, miękki) |
| 03 | Ekran gry jak w D-12: przekrój u góry, zwijka z narzędziami u dołu (strefy kciuków) | Lewy kciuk napina, prawy szuka. | Left thumb tensions, right thumb picks. | `section.png` + `tray.png` | OK jako makieta. Docelowo **zrzut z gry** (Godot), z odciskami kciuków |
| 04 | Zwijka: wytrychy w kieszeniach (życia) | Zapasowe wytrychy. Licz je. | Spare picks. Count them. | `tray.png`, zbliżenie lewej części | **Nowy render**: trzy wytrychy w kieszeniach, jedna kieszeń pusta, ułamana końcówka obok |
| 05 | Tryb „w ciemności”: przekrój wygaszony prawie do czerni | Zgaś ekran. Graj dotykiem i słuchem. | Screen off. Play by touch and ear. | `section.png`, jasność 10% | **Nowy render**: ciemna klatka, tylko odblask napinacza i dłoń z telefonem? (do decyzji: bez dłoni, tylko czerń z ledwo widocznym rdzeniem) |
| 06 | Klient przed zamkiem: drzwi kamienicy, emaliowana tabliczka mieszkania, siatka z zakupami | Pani Halina czeka. Rosół też. | Mrs Halina is waiting. So is the soup. | `section.png`, kadr drewna w prawym górnym rogu (**zaślepka**) | **Nowy render**: drzwi z tabliczką (Bona Nova), ciepłe światło klatki. Tylko jeśli klienci są w 1.0 |
| 07 | Lupa zegarmistrzowska, potem gablota | Lupa, a potem gablota z historią. | The loupe, then the history case. | `tray.png`, zbliżenie lupy (**zaślepka**) | **Nowe rendery**: widok przez lupę (`loupe.png` jest w CSS, brak pliku) i gablota z eksponatem i notką |
| 08 | Sprężyny i kołki w półmroku + druga linia o grze | Bez reklam. Bez sieci. Bez pośpiechu. / To gra, nie kurs. Zamki są wymyślone. | No ads. Offline. No rush. / A game, not a course. The locks are invented. | `section.png`, kadr sprężyn, jasność 55% | OK jako makieta |

Uwaga do 08: „Bez sieci” / „Offline” obiecuje działanie bez internetu. Jeśli w wariancie A D-06 zakup wymaga
połączenia, zdanie dalej jest prawdziwe (gra działa offline, zakup idzie przez sklep), ale warto to potwierdzić.

## Zamówienie dla sesji renderowej (art)
1. `section` w 2640 × 3520 (lub wyższej), te same ustawienia co obecny `section.png` — dla 01 i 03.
2. Makro linii podziału w stanie `set` i osobno `false set` (szpulka), 2640 × 3520 — dla 02 (i ewentualnie wariantu „szpulka kłamie”).
3. Zwijka z pełnym kompletem: 3 wytrychy w kieszeniach, napinacz, lupa, 2640 × 1060 — dla 03 i 04.
4. Tryb „w ciemności”: ten sam kadr co 01, światło klatki zgaszone, tylko słaby odblask — dla 05.
5. Drzwi kamienicy z emaliowaną tabliczką (bez numeru prawdziwego adresu) — dla 06.
6. Widok przez lupę (`loupe.png`) i gablota z eksponatem — dla 07.

Każdy nowy render wpisać do `docs/ASSETS.md`. Po dostarczeniu zmienić `src`, `focus`, `zoom` w `SHOTS` w `make_screens.py`.

## Rozmiar plików
Pełne RGB PNG (optimize) dla PL + EN, iPhone + Android: 42,7 MB (32 pliki). W repo są wersje `--quantize`
(256 kolorów z ditheringiem): 24,8 MB. Do wysyłki do sklepów generować pełne RGB bez `--quantize`.

## Znane słabości makiet
- Rendery mają 824 × 1100 px, a iPhone 6,9" potrzebuje 1320 px szerokości: każdy kadr jest powiększony 1,6–4×, zbliżenia (02, 06, 07) są miękkie.
- W kadrach 04 i 07 widać krawędź renderu zwijki na jednolitym tle skóry (tło próbkowane z renderu, ale render ma winietę).
- Kadry 06 i 07 to zaślepki: treść podpisu nie odpowiada obrazowi.
