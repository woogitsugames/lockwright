# Audyt wizualny ekranów — 2026-11-07 (VA)

Zakres: każdy ekran tak, jak widzi go gracz, w 412×915, 915×412 i 360×800; PL we wszystkich
rozmiarach, EN/DE/FR/ES na ekranach z tekstem (412×915 i 360×800, DE także 915×412).
Poprzeczka: rendery `art/renders/warded.png`, `wafer.png`, `lever.png` oraz lista zakazów z `CLAUDE.md` / `docs/DESIGN.md`.

Jak zrobione: `tools/local/run_gut.sh --screens` (272/272 GUT, 11 ekranów × 2 rozmiary) plus
`game/tests/shot_scene.tscn` dla reszty (każda rodzina zamków, rozmowa, faktura, Tryb ciągły, samouczek,
Wyposażenie). Do runnera doszły flagi `--lang=` (język w pamięci), `--no-day-after=1` (lista zleceń bez
nałożonej sceny „następnego dnia”), `--targets=1` (wypisuje widoczne przyciski < 48×48 dp), a nakładka FPS
z buildów debug jest w tych zrzutach ukryta. Renderer: opengl3, jak w CI.

Arkusze: `sheets/01_menu.jpg` … `sheets/14_i18n_360.jpg`; przed/po: `before_after/`; wycinki: `crops/`.
Ekran pauzy nie był zrzucany (należy do innego agenta, zob. VA-13).

## Co przeszło
- **Cele dotyku:** skan `--targets=1` na 17 ekranach × 2 rozmiary nie znalazł żadnego widocznego przycisku
  poniżej 48×48 dp (próba kontrolna z progiem 60 dp wyłapuje przyciski 48 dp, więc skan działa).
- **Fonty:** wszędzie Atkinson Hyperlegible Next + Bona Nova + Caveat (paragon). Bez fontu systemowego.
- **Emoji, zielone ptaszki, czerwone X:** brak w skryptach, scenach i CSV (skan Unicode). Stany słowami.
- **Menu (tablica z filcu)** i **scena „następnego dnia”** są na poziomie renderów: zostają.
- **Ustawienia** trzymają styl (emalia, mosiądz, skóra). W DE/FR/ES przy 360 dp nic nie wychodzi za ekran.

## Ranking (od najbardziej „taniego” wrażenia)

| # | Ekran | Problem | Stan |
|---|---|---|---|
| VA-01 | Warsztat | Zakładki obcięte wielokropkiem: „Wyposaże…” (PL, każda wizyta), „Aménage…” (FR), „Herramien…” (ES). | **naprawione** |
| VA-02 | Wszystkie nagłówki | Bona Nova ma domyślnie cyfry nautyczne: „Monety: 4o”, „9:3o”, „Monety: 9oo”, „Rozdział 1” czyta się jak „Rozdział ı”. | **naprawione** |
| VA-03 | Przyjazd | Tytuł łamie się w środku słowa („Vorstellungsg / espräch”, DE 360), zajmuje 3 linie, a „‹ Zurück” rozciąga się do ~100 dp wysokości. PL „Rozmowa o / 9:30” w dwóch liniach. | **naprawione** |
| VA-04 | Faktura | Kreski „Razem: ____” przechodzą przez środek kwoty, co wygląda jak skreślenie. Tło to płaski brąz. W poziomie paragon ma ~60 dp szerokości i nie da się go przeczytać. Trzy wyśrodkowane linie bez hierarchii. | **naprawione** |
| VA-05 | Lista zleceń | Ściana jednakowych kremowych tabliczek (wygląda jak lista SaaS): zlecenie wykonane i otwarte różnią się tylko dopiskiem. Rozdziały przyklejone do poprzedniej tabliczki. Opis rozdziału ma ~4,1:1 na zdjęciu (14 px, wymagane 4,5:1). | **naprawione** |
| VA-06 | Tryb ciągły („poziom”) | Pusty płaski brąz, trzy wyśrodkowane linie w kolumnie 380 dp, brak przycisku Wstecz (wyjście tylko gestem). | **naprawione** |
| VA-07 | Samouczek (kadry przed etapem) | Płaski brąz. Szkice mistrza mają 112×140 dp, wielkość znaczka. Pod spodem dużo pustki. | **częściowo** (tło + większe karty). Same szkice wymagają grafiki, zob. „Rendery” |
| VA-08 | Weryfikacja | Płaski brąz, ~60% pustego ekranu, sam tytuł na środku. W poziomie tytuł przycięty u góry (`crops/va08_verify_land_clipped.png`). „Zdjęcie / Paragon” to małe plakietki obok siebie. | **naprawione** (D-85: drzwi na zdjęciu pod nagłówkiem, karty większe tuż nad decyzjami; w poziomie teksty \| karty w rzędzie, decyzje w jednym rzędzie na dole; `fit_title`). `fixes/verify_va08/` |
| VA-09 | Zamki: egipski, drewniany, osiowy, czasowy, dźwigniowy | Daleko od poprzeczki renderów. Egipski: drewno na drewnie (kołek/szczelina ~1,8:1, kołek/rama ~2,2:1), zamek ~35% szerokości na czerwonej desce. Drewniany: ~1,8:1. Osiowy: płaskie suwaki (suwak/szczelina ~1,4:1). Czasowy: mosiężne koła na mosiężnej płycie, prawie zero kontrastu, blisko zakazanego „steampunku z martwymi zębatkami”. Dźwignia: płaski pomarańcz jak plastik. Wszystkie poniżej 3:1 metal/tło. `crops/va09_*.jpg` | **GPU / Blender** |
| VA-10 | Zamki: dimple, magnetyczny | Ten sam przekrój wkładki bębenkowej co pin (`crops/va10_*.jpg`): rodzina bez własnej sylwetki. | **GPU / Blender** |
| VA-11 | Zamki: tarczowy (disc), szyfrowy (combo), pion | Przekrój kończy się na ~55% wysokości. Między nim a zwijką jest pas drewna/skóry z „wiszącym” wskaźnikiem napięcia (`crops/va11_*.jpg`). Wygląda jak niedokończony kadr. | **naprawione układem** (D-85: zwijka jak na innych ekranach, przekrój do niej, zamek tuż nad zwijką; blat nad płytą odbity). Lepiej: płyty z zamkiem niżej (render, opis w D-85). `fixes/landscape_crop/va11_*` |
| VA-12 | Wybór sterowania | Jedyna granatowa tabliczka emaliowana w grze („Kontynuuj”, `crops/va12_navy_plate.png`). Reszta przycisków jest kremowa, więc ta wypada z systemu. | **naprawione** (D-86): „Kontynuuj” na kremowej emalii (`ivory`), jak reszta przycisków |
| VA-13 | Pauza | Nie zrzucana (inny agent). Do sprawdzenia przy jego przekazaniu: te same kryteria (tło, 48 dp, kontrast). | nie moje |
| VA-14 | Warsztat — narzędzia | Wiersze narzędzi to sam tekst na ciemnym papierze, bez wizerunku narzędzia, i czyta się to jak lista w aplikacji biurowej. Mapa dzielnicy jest ostra i „płaska” obok fotorealu. | **naprawione** (D-86): zdjęcie studyjne każdego z 22 narzędzi w wierszu (Blender, biblioteka zdjęć materiałów), mapa jak papier pod lampą |
| VA-15 | Debug | Zielona nakładka „FPS … frame … ms” w buildach debug (APK testerskie) zasłania „‹ Wstecz” na każdym ekranie i trafia na zrzuty dla właściciela. | **naprawione** (D-86): w buildach debug domyślnie ukryta; F3, dotyk czterema palcami albo `-- --fps=1` |
| VA-16 | Samouczek, poziom | „Wstecz” poniżej krawędzi (trzeba przewinąć). | **naprawione** (D-86): „‹ Wstecz” w lewym górnym rogu poza przewijaniem (pion i poziom); w poziomie mniejsze karty, więc „Zacznij ćwiczenie” też bez przewijania. Tryb ciągły miał to już od VA-06 |
| VA-17 | Menu FR/ES | Wracało do polskiej tablicy (`pick_lang` → PL). | **naprawione** → EN, PL dopiero gdy brak EN |
| VA-18 | Faktura DE/FR/ES | Papier paragonu jest tylko PL/EN (DE/FR/ES dostają EN). Zrzut w DE bez flagi deweloperskiej pokazywał PL, bo ekran czytał `Settings.language()` zamiast języka UI. | **naprawione** (D-86): papiery `receipt_{de,fr,es}.webp` (`art/tools/receipt_i18n.py`, ten sam papier i układ pól co G14), wybór papieru według języka UI dla wszystkich 5 języków |

## Co naprawiłem (pliki, przed/po)

- **VA-01** `scripts/ui/workshop_screen.gd`, `theme/build_theme.gd` (`TabPlate`: boki 6 dp zamiast 16)
  i `ScreenFrame.fit_button_text` (zmniejsza tekst 16→13 px, zanim zadziała wielokropek).
  Przed/po: `before_after/va01_workshop_tabs_pl.jpg`, `va01_workshop_tabs_fr360.jpg`, `crops/va01_*`.
- **VA-02** `theme/title_font.tres`: Bona Nova z `lnum` (cyfry nautyczne zamiast tekstowych), używana przez motyw (Title,
  Heading, MenuTitle) oraz `control_choice.gd` i `job_arrival.gd`. Przed/po: `crops/va02_*`.
- **VA-03** `ScreenFrame.fit_title`: jedna linia, jeśli mieści się w ≥ 22 px. Inaczej dwie linie, łamane
  tylko między słowami. Przyciski obok trzymają 48 dp (`job_arrival.gd`). Przed/po: `before_after/va03_arrival_de360.jpg`, `crops/va03_*`.
- **VA-04** `scenes/job_payment.tscn`, `scripts/ui/job_payment.gd`: kwota „Razem” leży na kreskach, a „x” w kratce
  gotówki. Za paragonem zdjęcie klatki schodowej. Wynik w Bona Nova (Heading), napiwek jako podpis. W poziomie
  paragon stoi na całą wysokość po lewej, tekst i „Kontynuuj” po prawej. Papier według języka UI.
  Przed/po: `before_after/va04_invoice_pl.jpg`, `va04_invoice_land.jpg`, `crops/va04_*`.
- **VA-05** `scripts/ui/jobs_list.gd` + `DonePlate` w motywie: wykonane zlecenie to tabliczka „położona”
  na papierze (ciemna, mosiężna linia, bez cienia), a otwarte zostaje wypukłą emalią. Różnica jest w kształcie
  i walorze, nie tylko w kolorze. Nad rozdziałem 12 dp odstępu. Przyciemnienie zdjęcia 0,55→0,64, więc opis
  rozdziału ma ~5:1. Przed/po: `before_after/va05_jobs_pl.jpg`.
- **VA-06** `scripts/ui/run_loop.gd`: zdjęcie klatki wieczorem, „‹ Wstecz” jak na innych ekranach,
  notka dyspozytora na ciemnym papierze w dolnej strefie kciuka (safe-area, w poziomie maks. 640 dp).
  Ścieżki `VBox/Info` i `VBox/StartButton` bez zmian (testy). Przed/po: `before_after/va06_run_loop_*.jpg`.
- **VA-07** `scripts/ui/tutorial.gd`: tło warsztatu wieczorem (G08, przyciemnione 0,72), karty 136×168 dp.
  Przed/po: `before_after/va07_tutorial_pl.jpg`.
- **VA-17** `scripts/ui/main_menu.gd` (`FALLBACK_LANG = "en"`, `LAST_RESORT_LANG = "pl"`) i test w
  `tests/gut/test_main_menu_v2.gd` (FR/ES → EN, brak EN → PL, pętla po 5 językach).

## Dla koordynatora: potrzebne rendery (GPU/Blender)
1. **Egipski, drewniany, osiowy, czasowy, dźwignia (VA-09)**: przerobić look-dev do poziomu `warded.png`/`wafer.png`.
   Ciemne tło za elementem (≥ 3:1), fazki, ślady obróbki. W czasowym stal na tle mosiądzu (albo odwrotnie)
   i mniej kół (tylko te, które tłumaczą mechanizm).
2. **Dimple i magnetyczny (VA-10)**: własne przekroje (dołeczkowe piny pod kątem / magnetyczne trzpienie),
   żeby rodzinę dało się rozpoznać po sylwetce.
3. **Disc / combo w pionie (VA-11)**: kadr przekroju do zwijki, bez pasa „pustego” drewna.
4. **Samouczek (VA-07)**: kadry G11 jako rendery przekroju z ręką/kredą zamiast cienkich szkiców.
5. **Weryfikacja (VA-08)**: tło (dokumenty na kartce w dłoni przy drzwiach, jak przyjazd); to pod właściciela ekranu.
6. ~~**Warsztat — narzędzia (VA-14)**~~ zrobione (D-86).
7. ~~**Paragon DE/FR/ES (VA-18)**~~ zrobione (D-86).

## Druga runda (2026-11-08, D-86): VA-12, VA-14, VA-15, VA-16, VA-18

- **VA-14** `art/blender/tool_thumbs.py` (22 narzędzia z `game/data/tools.json`: ostrza `flat_tool` jak w `tray.py`,
  sonda magnetyczna i chorągiewka z `plates/tool_layers.py`, lupa z `tray.py`, mikroskop i boroskop z `optics.py`;
  materiały `photo_mat` z `art/textures/photo`; ciemna, matowa skóra jako tło; światło jak `tray.py`) →
  `art/tools/tool_thumbs_post.py` → `game/assets/ui/tools/<id>.webp` (160 px = 2× miejsca 80 dp, import stratny 0,85).
  `workshop_screen.gd`: zdjęcie w cienkiej ciemnej oprawie obok nazwy i opisu; narzędzie jeszcze nie twoje jest
  przyciemnione (stan i tak jest słowami). Mapa: cieplejsza i ciemniejsza, krawędzie w cieniu, ciemne passe-partout.
  Arkusz: `art/renders/tool_thumbs_contact.jpg`. Przed/po: `before_after/va14_workshop_tools_pl.jpg`, `va14_va18_after_es_land.jpg`.
- **VA-12** `scenes/control_choice.tscn`: `plate = ivory`. Przed/po: `before_after/va12_control_choice_plate.jpg`.
- **VA-15** `autoload/quality.gd`: nakładka FPS ukryta domyślnie; F3 / cztery palce / `--fps=1`. `shot_scene.gd --keep-fps=1`
  pokazuje to, co widzi tester. Przed/po: `before_after/va15_fps_overlay_debug.jpg`.
- **VA-16** `ui/tutorial.gd`. Przed/po: `before_after/va16_tutorial_back.jpg`.
- **VA-18** `art/tools/receipt_i18n.py`, `ui/job_payment.gd` (`receipt_path()`). Przed/po: `before_after/va18_invoice_de_fr.jpg`.
- Testy GUT: `test_ui_layout.gd` (miniatury, płytka, Wstecz), `test_fps_overlay.gd`, `test_flow_after_tutorial.gd` (papier w 5 językach).


## Stan 2026-11-08: VA-09 i VA-10 (rendery GPU, sesja płyt)

Kontrast w skali szarości każdego ruchomego elementu do jego tła (`tools/art/plate_contrast.py`, najsłabszy element,
min z „pierścień wokół” i „tło pod spodem”): egipski 1,02 → 3,45:1, osiowy 1,52 → 3,02:1, czasowy 1,00 → 3,62:1,
dźwignia 4,04 → 3,42:1 (mosiądz bez „plastiku”), dźwignia z detektorem 4,89 → 4,41:1. Geometria, kamery i położenia
części bez zmian (maski warstw IoU ≥ 0,99, przesunięcie ≤ 0,25 px). Arkusze: `docs/handoff/device-tests/fixes/family_rerenders/`.

**VA-10 wymaga zmiany kodu (nie zrobiona).** Dimple i magnetyczny ładują `lock_photoreal_view.gd` przez
`pin_family_view.gd`, a płyta to stała `PLATE` (`res://assets/photoreal/plate/plate_1236x1650.png`). Nowe płyty
(`plate_dimple_1236x1650.png`, `plate_magnetic_1236x1650.png`, ta sama kamera i te same ruchome piny) leżą obok.
Potrzebne: w `lock_photoreal_view.gd` `@export var plate_path := PLATE` i w `_build_materials()` `_tex(plate_path)`
zamiast `_tex(PLATE)`; w `scenes/photoreal/lock_job_dimple.tscn` i `lock_job_magnetic.tscn` w węźle `View`
`plate_path = "res://assets/photoreal/plate/plate_<rodzina>_1236x1650.png"`. Znana drobna wada: wypełniona dolna część
kanału klucza należy na obrazie do bębenka, a w GLB jej nie ma, więc przy obrocie bębenka (`plate_rest.gdshader`) ten
pas nie obróci się razem z nim (kilka px przy pełnym obrocie).
