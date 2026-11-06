# Przegląd G23 — pełne postacie (D1, D2) i dłonie widma

Data: 2026-11-06 · sesja A · dostawa: `contrib/gpt/G23/` (8 obrazów, `ASSETS.md`, `README.md`). Decyzja: D-66.
Wynik: **przyjęte w całości**; wszystkie 8 plików wykorzystane (wycinki postaci, kompozyty scenki D-58, sylwetki widma).

## D1 — pan Kazimierz (`D1_kazimierz_fullbody.png`, 1024×1536)

- **Twarz:** zgodna z `game/assets/ui/gpt/cast/episodic/portrait_kazimierz.webp` — ten sam kształt głowy, siwe
  zaczesane włosy, nos, czerwone policzki, zmarszczki przy oczach, uśmiech. Bez wątpliwości ta sama osoba.
- **Strój i rekwizyt:** tweedowa marynarka, koszula w kratę, poluzowany krawat, ciemne spodnie, znoszone półbuty —
  jak w briefie. Klucz w **prawej** ręce, gładki, bez znaków firmowych. Lewa ręka w kieszeni.
- **Anatomia:** dłoń z kluczem poprawna (kciuk + palce zgięte wokół główki), stopy i buty poprawne.
- **Uwagi (drobne, bez poprawki):** zamiast „zdziwiony, patrzy na klucz” patrzy w obiektyw z szerokim uśmiechem — pasuje
  do kwestii „po imieninach”, ale mniej do „to chyba nie moje drzwi”. Światło jest studyjne, z przodu i z lewej, a nie
  „od tyłu z góry”; po wkomponowaniu daje to lekko płaski wygląd (opis w `art/renders/arrival/README.md`).
- **Wycięcie:** maska BiRefNet zgubiła klucz (szary na szarym tle) — przywrócony kluczem kolorów w ramce
  (`figure_cutout.py --keep-box`). Włosy z miękką alfą, bez szarej obwódki (odkażenie koloru).

## D2 — pani Teresa (`D2_teresa_fullbody.png`, 1024×1536)

- **Twarz:** zgodna z `portrait_teresa.webp` — siwe upięte włosy, kształt nosa i oczu, otwarte usta, zmarszczki,
  ten sam wiek. Ta sama osoba.
- **Strój:** pikowany szlafrok z paskiem, koszula nocna w drobne kwiaty, pantofle — jak w briefie. Dłoń na piersi.
- **Anatomia:** obie dłonie poprawne (prawa na piersi, lewa odsunięta w bok, pięć palców), stopy poprawne.
- **Uwagi:** kok jest luźny, raczej upięcie z tyłu — bez znaczenia. Pozycja „cała postać na środku” nie pasuje sama z siebie
  do uchylonych drzwi; w kompozycie stoi teraz w przedpokoju za skrzydłem i zagląda przez szparę (nowy slot, README scenki).

## Dłonie widma (6 × 1024², białe tło)

| Plik | Gest w grze | Ocena |
|---|---|---|
| `thumb_left_press.png` | H2: napięcie, łagodzenie, stuknięcie (lewy kciuk) | poprawny lewy kciuk od dołu z lewej, paznokieć u góry; bez dodatkowych palców |
| `thumb_right_press.png` | H2: uniesienie (prawy kciuk) | poprawny prawy kciuk od dołu z prawej |
| `thumb_right_slide.png` | H2: `roll`, `turn` (kciuk przesuwa koło/tarczę) | kciuk poziomo w lewo, czytelnie inny od nacisku |
| `hand_left_tool.png` | H4: ręka mistrza, lewa strona (napinacz) | lewa dłoń trzyma płaski pręt w kształcie L — sylwetką przypomina napinacz; anatomia poprawna |
| `hand_right_tool.png` | H4: ręka mistrza, prawa strona (wytrych) | prawa dłoń, sonda z haczykiem trzymana jak ołówek; poprawna |
| `hand_right_open.png` | H4: puszczenie (ręka się otwiera i cofa; lustrzana po lewej) | prawa dłoń grzbietem do góry, kciuk + 4 palce; poprawna |

- Zero logo, tekstu, pierścionków, zegarków i tatuaży. Tło prawie białe z minimalnym szumem — maska z odległości od tła
  działa bez ręcznych poprawek.
- Dłonie są fotografiami, ale gra pokazuje z nich tylko **sylwetkę**: czarny cień 35 %, krawędź rozmyta 12 dp
  (ONBOARDING §2.2). Zrzuty `docs/handoff/device-tests/fixes/hints_g23/` czytają się jako miękki cień, nie wklejone zdjęcie.

## Co z tego powstało

- `art/renders/arrival/figures/{kazimierz,teresa}.png` + kompozyty `wrong_floor_*_{kazimierz,teresa}.png`
  i arkusz `wrong_floor_with_figures_board.jpg` (cień 2D; mapy cienia GPU w `docs/handoff/LOCAL-SESSION-PROMPT.md`).
- `game/assets/ui/ghost/*.png` + `ghost_silhouettes.json`; `GhostHand.set_silhouette()` i dobór gestu w `TutorialHints`.

## Ewentualne poprawki u ChatGPT (niepilne)

1. D1 w wariancie „zdziwiony, patrzy na klucz”, ciepłe światło z góry i z tyłu (obrys na włosach), żeby postać lepiej
   siedziała pod żarówką klatki.
2. D2 w pozie „wygląda zza drzwi” (pół postaci, ręka na krawędzi skrzydła), światło od tyłu z przedpokoju.
