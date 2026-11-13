# Lockwright: zadania dla lokalnej sesji z GPU (PC właściciela, RTX 5070)

Stan: 2026-11-13 (D-127). Lista rzeczy, których chmura nie zrobi, bo nie ma GPU. Zasady pracy lokalnej sesji:
`docs/handoff/LOCAL-SESSION-PROMPT.md` (rola, narzędzia, commity, log w `LOCAL-SESSION-LOG.md`). Kolejność = priorytet.
Po każdym zadaniu: arkusz porównawczy i zrzuty do `docs/handoff/` lub `art/renders/`, wiersz w `docs/ASSETS.md`,
wpis w logu, commit na `main`.

Wspólne: Blender **4.2.9 LTS** (ta sama wersja co wszystkie dotychczasowe rendery), Cycles, `--device GPU`
(OptiX, potem CUDA: `lw_common.configure_cycles_device`). `BL` = ścieżka do `blender.exe`. Bez marek, bez napisów,
bez twarzy; grafiki własne (render), każda wpisana do `docs/ASSETS.md`. Lista zakazów wizualnych: `CLAUDE.md`.

---

## 1. Pięć przedmiotów wyposażenia warsztatu (D-124, D-127) — najpierw to

**Po co:** monety z rozdziałów 13–15 nie miały celu. Właściciel zgodził się na pięć kosmetycznych przedmiotów
(4 800 monet). Dane, ceny, teksty w 5 językach i kod gry są już na `main`. Brakuje tylko pięciu nakładek. Gra chowa
przedmiot bez pliku nakładki (nie ma go w sklepie i nie da się go kupić), a pokaże go sama w pierwszej wersji,
w której plik `furn_<id>.webp` będzie w `game/assets/ui/workshop/`. **W kodzie gry, danych i tekstach nic nie
zmieniasz.**

### 1.1 Jak działają nakładki (to ogranicza wszystko niżej)

- Scena: `art/blender/workshop.py` (stół ślusarza, 1 jednostka = 1 mm). Przedmioty: `art/blender/workshop_furnishings.py`,
  jedna kolekcja Blendera `furn_<id>` na przedmiot, domyślnie ukryta w renderze.
- `workshop.py --layers DIR` renderuje `base.png` i po jednym `<id>.png` na przedmiot: ta sama kamera, ustawienia
  i seed, w kadrze zawsze **dokładnie jeden** przedmiot. `art/blender/workshop_layers.py` bierze różnicę wariantu
  i podstawy (próg 0,03 na kanał) i zapisuje pełnoklatkową nakładkę RGBA: przedmiot, jego cień i światło, które
  dodaje; reszta przezroczysta. Gra układa podstawę i kupione nakładki w kolejności `z` z `game/data/furnishings.json`.
- **Kamera i światła są zamrożone.** `photo_camera((-20, -930, 1650), yaw=0, lens=18, pitch=-39, shift=(0, 0.045))`,
  matryca 36 mm w pionie, ekspozycja −0,35, AgX Medium High Contrast, 10 odbić, próg adaptacyjny 0,01. Nie ruszasz
  kamery, lampy, okna, HDRI ani żadnego obiektu podstawy: zmiana jednego piksela podstawy psuje dziesięć
  istniejących nakładek.
- **Nowy przedmiot nie świeci.** Źródło światła zmienia pół kadru (tak działa `shelf_light`, warstwa `z` 10 pod
  przedmiotami). Wszystkie pięć nowych to zwykłe przedmioty, `z` 20, bez emisji i bez lamp.
- **Losowość:** `build()` ma jeden generator `rng = random.Random(71)`. Nowe kolekcje dopisz **na końcu** `build()`,
  za `exhibit_shelf`, a nowe identyfikatory na końcu listy `IDS`. Wtedy dziesięć starych przedmiotów losuje to samo
  co dotąd i ich rendery się nie zmieniają.
- **Dwa przedmioty nie mogą leżeć na tych samych pikselach.** Każdy wariant jest renderowany bez pozostałych,
  więc tam, gdzie dwie maski się nakładają, górna nakładka zasłania przedmiot albo cień dolnej. Liczy się też
  cień: lampa wisi z przodu po prawej (głowica ok. `(170, -600, 1640)`), cienie padają w lewo i do tyłu.
  `workshop_layers.py` wypisuje pary masek, które nakładają się powyżej 10 % mniejszej maski (`OVERLAP …`).
  Dla porównania: wśród dziesięciu starych najwięcej ma `plant / clock`, 19 %, i to są same cienie.

### 1.2 Wolne miejsca w kadrze (zmierzone `workshop.py --probe`, 2026-11-13)

Kadr jest ciasny. Ułamki kadru: x od lewej, y od góry. Zajęte przez dziesięć starych przedmiotów:

| przedmiot | x | y |
|---|---|---|
| `plant` | 0,453–0,575 | 0,493–0,598 |
| `rug` | cała szerokość | 0,758–0,980 (podłoga pod stołem) |
| `shelf_light` | 0–0,428 | 0,422–0,435 (plus światło na tablicy kluczy) |
| `radio` | 0–0,337 | 0,488–0,608 |
| `certificate` | 0,121–0,361 | 0,044–0,158 |
| `case_velvet` | 0–0,434 | 0,201–0,383 |
| `clock` | 0,373–0,489 | 0,462–0,520 |
| `thanks_cards` | 0,496–0,649 | 0,401–0,442 |
| `vise` | 0,048–0,426 | 0,595–0,817 |
| `exhibit_shelf` | 0,649–0,960 | 0,408–0,486 |

Przeliczenie (przybliżone, do pierwszego ustawienia; potem `--probe`): przy ścianie i na tablicy perforowanej
1 mm ≈ 0,0011–0,0014 szerokości kadru, lewa krawędź kadru na wysokości dyplomu to x ≈ −385 mm, prawa krawędź na
tablicy to x ≈ 477 mm; z przodu stołu (y ≈ −600) widać x od ok. −300 do +285 mm.

Strefy wolne w podstawie i we wszystkich dziesięciu wariantach (współrzędne sceny w mm; stół ma blat na `BZ` = 900,
tył przy ścianie y = −30, przód y = −690; tablica perforowana x −30…660, z 990…1720, lico y = −22):

| strefa | gdzie | współrzędne sceny | uwaga |
|---|---|---|---|
| **Z1** | blat z tyłu, między radiem a pelargonią | x −225…−75, y −215…−60, wysokość do ok. 120 nad blatem | nad nią na ścianie wisi zegar (dół zegara z = 996); w `--probe` górna krawędź przedmiotu ma zostać poniżej y = 0,525 |
| **Z2** | ściana na prawo od dyplomu | x −128…−38, z 1600…1770, przy ścianie y −22…−2 | 90 mm szerokości; cień pada w lewo, w stronę dyplomu (ramka dyplomu kończy się na x = −135) |
| **Z3** | tablica perforowana pod kartkami z podziękowaniami | x −20…145, z 1095…1185 | niżej zasłania pelargonia (stoi przed tablicą), po prawej zaczyna się półka z eksponatami (x = 150) |
| **Z4** | ściana nad tablicą perforowaną | x 0…380, z 1728…1798 | niski, szeroki pas; po prawej od x ≈ 400 wchodzi klosz lampy |
| **Z5** | blat z przodu, między telefonem a podkładką z blankietami | x 85…200, y −690…−600 | przedmiot niski (do ok. 70 mm), żeby nie zasłonił blankietu na podkładce (kotwica `slip` w `workshop.json`) |
| Z6 (zapas) | blat z przodu, między zawieszką imadła a telefonem | x −75…−15, y −650…−520 | tylko 60 mm; na drobiazg |

Nie ma wolnego miejsca: na lewo od imadła (maska wariantu `vise`), przy kubku i maszynie do kluczy, na szczycie
gabloty (zasłoniłoby dyplom).

### 1.3 Przedmioty

Każdy: wymyślony, bez napisów, marek i twarzy; materiały z `env_common.py` (`oak`, `enamel`, `paper`, `metal`…)
i z `g` (`brass`, `bright`, `nickel`, `cotton`, `label_m`, `glass_m`, `clip_m`…), tak jak w istniejących kolekcjach.
Na telefonie kadr ma 412 dp szerokości, więc przedmiot węższy niż ok. 0,07 kadru (28 dp) przestaje być czytelny.
Jeśli coś się w strefie nie mieści albo wygląda źle, zmniejsz albo uprość przedmiot; jeśli dalej źle, opisz to
w logu i zostaw ten jeden bez nakładki (gra dalej go chowa). Nie przesuwaj starych przedmiotów.

| id | cena, rozdz. | co to jest | strefa | wskazówki |
|---|---|---|---|---|
| `enamel_mugs` | 500, rozdz. 13 | Emaliowany czajnik i dwa kubki: biała emalia z granatowym rantem (te same materiały co kubek z podstawy: `mug_m`, `mug_rim`), kilka odprysków. „Dla klienta, który musi chwilę poczekać.” | Z1 | czajnik Ø ok. 90, wysokość z pałąkiem do 120; dwa kubki Ø ok. 65 lekko z przodu; nie dotykać liści pelargonii (x > −75) |
| `neighbours_photo` | 800, rozdz. 13 | Zdjęcie z Dnia Sąsiada w wąskiej dębowej ramce: długi stół pod lipą (finał rozdz. 13). Odbitka to miękkie plamy pod szkłem: jasny pas stołu, zielona plama korony drzewa, bez ludzi z twarzami i bez tekstu (jak odbitki w `photo_frames`, D-117). | Z4 | format panoramiczny, ok. 260 × 62 mm, ramka jak `cert_frame`; szyba z `visible_shadow = False` (inaczej odbitka wychodzi czarna, patrz `certificate`) |
| `postcards` | 700, rozdz. 14 | Trzy pocztówki od klientów z urlopu przypięte klipsami do tablicy, pod kartkami z podziękowaniami: morze, góry, jezioro jako dwa–trzy płaskie pasy koloru, jedna odwrócona stroną adresową (linie, bez liter). | Z3 | kartki ok. 74 × 52 mm, lekko przekrzywione, klipsy `clip_m` jak w `thanks_cards`; nie wchodzić wyżej niż z = 1185 |
| `key_cabinet` | 1 200, rozdz. 14 | Szafka na klucze sąsiadów: mała, płaska, z ciemnego dębu, drzwiczki otwarte na bok albo przeszklone, w środku **dwanaście pustych mosiężnych haczyków** (3 × 4) i jedna koperta oparta na dole. Haczyki są puste, bo klucze wróciły do właścicieli (finał rozdz. 15) — ślusarz nie trzyma cudzych kluczy. | Z2 | ok. 88 × 165 × 20 mm; to najdroższy z czterech pierwszych, ma być czytelny: jeśli w Z2 jest za mały, zamień miejscami z `neighbours_photo` (szafka niska i szeroka w Z4, 3 × 4 haczyki zamienione na 2 × 6; zdjęcie pionowe w Z2) |
| `exam_lock` | 1 600, rozdz. 15 | Podstawka na zamek Zuzanny: dębowa podstawka z mosiężną tabliczką (pusta, bez grawerunku), na niej mała wkładka bębenkowa z niklowanym korpusem i mosiężnym bębenkiem, zrobiona ręcznie (ślady toczenia, `bright`/`nickel`/`brass`). „Zrobiony, nie kupiony.” Bez klucza w zamku: klucz został w akademiku. | Z5 | podstawka ok. 100 × 60 × 14, wkładka leży albo stoi, razem do 70 mm wysokości; nie zasłaniać blankietu |

`exam_lock` zastąpił lampę na ramieniu z listy D-124: w podstawie stoi już lampa na ramieniu, a druga, świecąca,
zmieniłaby światło w całym kadrze (D-127).

### 1.4 Render

1. Kolekcje w `workshop_furnishings.py`: `out['<id>'] = begin('furn_<id>')` … `end()`, na końcu `build()`; pięć
   identyfikatorów na końcu `IDS`; komentarz na górze pliku.
2. Ustawienie: `"$BL" -b -P art/blender/workshop.py -- --probe` wypisuje prostokąty wszystkich piętnastu. Nowe mają
   się mieścić w swojej strefie i nie nachodzić na prostokąty z tabeli 1.2.
3. Szkic (kilka minut na GPU), wszystkie piętnaście naraz, do oceny kompozycji:
   `"$BL" -b -P art/blender/workshop.py -- --out build/local-session/workshop_all15.png --furnish all --res 1080x1920 --samples 64 --device GPU`
4. Finał. Ustawienia muszą być te same co dla podstawy z gry: **2160×3840, 256 spp, GPU**.
   - Jeśli na dysku jest `art/renders/workshop_layers/raw/` z ostatniego pełnego przebiegu (katalog jest w
     `.gitignore`; ma `base.png` i dziesięć `<id>.png` w 2160×3840), renderuj tylko nowe:
     `"$BL" -b -P art/blender/workshop.py -- --layers art/renders/workshop_layers/raw --res 2160x3840 --samples 256 --device GPU --only enamel_mugs,neighbours_photo,postcards,key_cabinet,exam_lock`
     a potem `python art/blender/workshop_layers.py --only enamel_mugs,neighbours_photo,postcards,key_cabinet,exam_lock`
     (podstawa i dziesięć starych nakładek zostają bajt w bajt).
   - Jeśli `raw/` nie ma albo jest z innego sprzętu lub sterownika: cały przebieg, bez `--only` (podstawa + 15,
     jeden proces), potem `python art/blender/workshop_layers.py`. Podstawa i stare nakładki zapiszą się na nowo;
     to jest w porządku (tak zrobiono w D-89), bo wszystko pochodzi z jednego przebiegu.
5. Wynik: `game/assets/ui/workshop/furn_<id>.webp` (2160×3840, WebP stratny q82 z alfą, `alpha_quality` 90 — robi to
   `workshop_layers.py`), mastery `art/renders/workshop_layers/furn_<id>.png` i `compare.jpg`.
6. Import w Godocie: `godot --headless --path game --import` tworzy `furn_<id>.webp.import`. Parametry mają być
   takie jak w `furn_plant.webp.import`: `compress/mode=1`, `compress/lossy_quality=0.8`, `mipmaps/generate=false`,
   `process/size_limit=2560`. Najprościej skopiować sekcję `[params]` z `furn_plant.webp.import`. Commit obejmuje
   `.webp` i `.webp.import`.

### 1.5 Sprawdzenie

- `workshop_layers.py` nie wypisuje `OVERLAP` dla żadnej pary z nowym przedmiotem (albo tylko sam cień, poniżej 20 %,
  i na `compare.jpg` nic nie znika). Maska każdego nowego przedmiotu: rząd 1–4 % kadru; maska kilkunastu procent
  oznacza, że przedmiot zmienia światło albo podstawa nie pasuje do wariantu.
- `compare.jpg`: środkowy panel (wszystko naraz) wygląda jak szkic z punktu 3; nie ma „duchów” (jasnych obwódek,
  prostokątów innego odcienia) wokół nowych przedmiotów.
- W grze: `godot --path game --resolution 412x915 res://tests/shot_scene.tscn -- --scene=res://scenes/workshop.tscn --tab=furnishings --coins=9999 --furnish=all --chapter=15 --out=…`
  (parametry: nagłówek `game/tests/shot_scene.gd`); zrzut z kompletem i zrzut tła warsztatu. Pięć nowych wierszy
  jest w sklepie, obrazek nad listą pokazuje wszystkie piętnaście.
- Testy: `test_furnishings.gd` w GUT zielony (sam wykrywa, że nakładki doszły), `python tools/econ_sim.py` — z raportu
  znika punkt „Czeka na grafikę”; `docs/ECONOMY.md` do commita.
- Skala szarości: każdy nowy przedmiot odróżnia się od tła także po odbarwieniu (kontrast z blatem lub ścianą).
- `docs/ASSETS.md`: dopisz pięć identyfikatorów do wierszy skryptów, renderów i `game/assets/ui/workshop/`.
- Zrzuty dla właściciela: `compare.jpg`, zrzut sklepu, zrzut warsztatu z kompletem.

---

## 2. Scenki przyjazdu zrobione na CPU: finały 512 spp i przejazdy

Pięć scenek ma w grze tylko stop-klatkę z CPU (1080×1920, 48 spp + OIDN; odszumianie wygładziło tynk, lastryko
i cegłę). Do zrobienia: stop-klatka 512 spp i przejazd 36 klatek 128 spp, jak finały D-94/D-108.

| zlecenie | decyzja | skrypt | `steps` jak w |
|---|---|---|---|
| `krystyna_wooden_album` (drzwi 14) | D-117 | `arrival_scene.py`, `--hair 1` | `widow_bureau` (schody drewniane) |
| `refuse_wrong_letterbox` (drzwi 16) | D-117 | `arrival_scene.py`, `--hair 1` | `widow_bureau` albo `shared_room_door`, wg posadzki sceny |
| `refuse_t43_09_empty_flat` (drzwi 34, lastryko) | D-117 | `arrival_scene.py`, `--hair 1` | `shared_room_door` (lastryko) |
| `ch13_01_balcony_boxes` (piwnica, komórki 6–8) | D-122 | `arrival_place.py` | `museum_time_lock` |
| `ch13_10_courtyard_door` (tylne drzwi świetlicy) | D-122 | `arrival_scene.py`, `--hair 1` | `shared_room_door` |

```bash
"$BL" -b -P art/blender/arrival_scene.py -- --job <id> --mode both --device GPU --hair 1 --res 1080x1920 --spp 128 --still-res 1080x1920 --still-spp 512 --out-dir build/local-session/arrival-master
"$BL" -b -P art/blender/arrival_place.py -- --job ch13_01_balcony_boxes --mode both --device GPU --res 1080x1920 --spp 128 --still-res 1080x1920 --still-spp 512 --out-dir build/local-session/arrival-master
python3 art/tools/arrival_export.py --job <id> --master build/local-session/arrival-master
```

Po eksporcie (1080×1920 WebP q80, import stratny 0,8): w `game/data/arrival_scenes.json` `frames` z 0 na 36 i `steps`
jak w tabeli; zlecenie znika z listy `STILL_ONLY` w `art/tools/arrival_export.py`; w `game/tests/gut/test_arrival_scene.gd`
przenieś je z `D117_STILLS` / `D122_STILLS` do `PLATE_JOBS` (klatka) albo `PLACE_JOBS` (miejsce). To jedyne zmiany
w danych i teście, na które to zadanie pozwala. Sprawdzenie: arkusze `art/renders/arrival/arrival_door7_board.jpg`
i `arrival_ch13_board.jpg` z nowymi kadrami obok starych (kadr i światło bez zmian, więcej szczegółu w fakturach),
`test_arrival_scene.gd` zielony, przejazd obejrzany w grze.

Przy okazji, z tych samych decyzji: odbitki w ramkach u Krystyny z bliska wyglądają jak chmury, czerwona koperta
w szesnastce ma ok. 60 px; w piwnicy pelargonie widać tylko przez szczeliny, a odbłyśnik lampy jest duży i jasny.
Poprawki mile widziane, jeśli nie zmieniają kadru.

---

## 3. Nowe sceny przyjazdu (lista życzeń z D-111, D-117, D-119, D-123, scalona)

Dziś te zlecenia pokazują zdjęcie G07 swojego miejsca albo pożyczają scenę przez `arrival_from`. Każda scena to
osobna decyzja „wchodzi / nie wchodzi” po podglądzie: poprzeczką są finały z D-108 (pizzeria, muzeum, klatki).
Kolejność według liczby zleceń, którym scena posłuży. Sceny dzienne w plenerze (★) to rodzaj kadru, który dotąd
odpadał jako „wizualizacja” albo „zabawka” (D-108, D-110, D-122); warto zacząć od zestawu zieleni i bruku, a nie
od pojedynczego kadru.

| # | scena | zlecenia | źródło | uwagi |
|---|---|---|---|---|
| 1 | Warsztat ślusarza ze stołem Henryka | finały rozdz. 12 i 15 (`ch15_10_exam_lock`) i inne zlecenia z `place: workshop` | D-123 | wnętrze; można oprzeć na scenie `workshop.py` (inna kamera, to nie jest tło sklepu) |
| 2 | ★ Ogródki działkowe: brama, wiata ze skrzynią na prasę, altana | `ch13_03_allotment_gate`, `ch15_02_apple_press`, `allotment_shed` | D-111, D-122, D-123, D-108 | **drugie podejście do działki** (punkt 4) |
| 3 | ★ Kiosk pana Stefana za dnia, z zamrażarką i sejfem pod ladą | `ch13_02_first_ice_cream`, `ch15_05_first_vacation`, `t43_09_05_receipt_safe` | D-111, D-122, D-123 | |
| 4 | ★ Nabrzeże z trapem statku Aino | `ch14_02_ship_time`, `finnish_sailor`, `t43_11_04_sailors_stall` | D-119 | ze straganem na nabrzeżu zamknie też brak kadru targu (D-117) |
| 5 | Szkolny korytarz z szafkami i gablotą; wariant: pracownia biologiczna z oszkloną szafą | `ch14_07_prize_cupboard`, `time_capsule`, `t43_12_04_school_box`, `ch15_07_skeleton_cupboard` | D-119, D-123 | wnętrze; zdejmie tabliczkę „Pralnia” przy szkolnych szafkach (D-125) |
| 6 | ★ Podwórko z lipą: biblioteczka, stół, tylne drzwi świetlicy od zewnątrz | rozdz. 13 i 14 (m.in. finał rozdz. 13 od strony podwórka) | D-119 | wewnętrzna strona tylnych drzwi już jest (D-122) |
| 7 | Szafka na klucze z kopertami w świetlicy | `ch14_10_holiday_keys`, `refuse_ch15_08_no_answer` | D-119 | wariant sceny `shared_room_door` |
| 8 | Drzwi strychu z kartką zarządczyni | `refuse_ch15_04_closed_attic`, `attic_drying_room` | D-123 | zestaw klatki; kartka bez liter (kreski) |
| 9 | ★ Dziedziniec kampusu z ekranem kina letniego i drzwiami kabiny projektora | `ch14_09_summer_cinema` | D-119 | wieczór, łatwiejszy niż dzień |
| 10 | Drzwi wynajmowanego mieszkania w kamienicy nocą, z walizką | `refuse_ch14_04_paid_week` | D-119 | zestaw klatki, drzwi nr 5 |
| 11 | Przechowalnia akademika (regał ze schowkami); wariant: portiernia z gablotą na klucze | `ch14_01_summer_storage`, `ch15_09_key_board`, `t43_10_05_porters_drawer` | D-119, D-123 | warianty sceny `student_dorm` |
| 12 | ★ Stojak rowerowy z rowerem z sakwami | `ch15_06_bike_by_train` | D-123 | wariant `bike_interview` |

Ustawienia finałów jak w punkcie 2. Nowa scena: wpis w `art/blender/arrival_jobs.json`, eksport `arrival_export.py`,
wpis w `game/data/arrival_scenes.json`, zlecenia współdzielące przez `arrival_from`, test w `test_arrival_scene.gd`;
arkusz podglądów przed finałem. Sceny rozdziału 16 dopisze tu sesja A, gdy rozdział wejdzie.

---

## 4. Bruksela i działka: drugie podejście (D-108, D-110)

Oba kadry odrzucono po podglądzie i nie ma ich w grze; zlecenia pokazują zdjęcie G07.

- **`brussels_townhouse`** (Saint-Gilles, fasada z balkonem i pelargoniami; zestaw `facade`, styl `townhouse`
  w `arrival_place.py`, został jako look-dev). Powód odrzucenia: „wygląda jak wizualizacja — płaska cegła, puste
  szyby”. Do poprawy: cegła z fugą i nierównym licem (jak w `cellar`, D-122), wnętrza za szybami (firanka, odbicie
  ulicy, ciemna głębia), zabrudzenia przy cokole i pod parapetami, światło z jednej strony zamiast równego.
- **`allotment_shed`** (altana na działce; zestaw usunięty). Powód: „trawa, żywopłot i drewno wychodzą jak
  zabawka”. Do zrobienia razem ze sceną 2 z punktu 3: trawa z cząsteczek o kilku długościach i odcieniach,
  wydeptana ścieżka, żywopłot z prawdziwą głębią (nie bryła z teksturą), drewno szare i spękane, siatka i furtka
  z rdzą. Pora: późne popołudnie albo pochmurno; południe w pełnym słońcu wypada najgorzej.

Ocena: arkusz obok `art/renders/arrival/arrival_ch3_6_board.jpg`. Jeśli drugi podgląd znów nie trzyma poziomu,
nie wchodzi do gry; zapisz w logu, co próbowano.
