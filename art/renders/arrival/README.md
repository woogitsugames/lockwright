# Przyjazd do klienta (D-58) — pilot `job.wrong_floor`

Scenka 2.5D: 3 s przejazdu kamery po ostatnich stopniach kamienicy na podest, potem stop-klatka drzwi
(nr 19, wianek z suszonych kwiatów, wycieraczka, skrzynka na listy z wizytówką) i klient z wyciętego zdjęcia.
Scena powstaje z zestawu klatki schodowej: `art/blender/arrival_scene.py` uruchamia bez zmian
`art/blender/stairwell.py` i dobudowuje bieg schodów, okno, wianek, tabliczkę, skrzynkę, kamerę i światło pory dnia.

## Pliki w tym katalogu (podgląd CPU, niska rozdzielczość — NIE finał)

| Plik | Co to |
|---|---|
| `wrong_floor_night_seq/f_0001..0036.png` | sekwencja 36 kl. @ 12 fps (3,0 s), 270×480, 10 spp |
| `wrong_floor_preview_contact.png` | arkusz kontrolny sekwencji (6×6) |
| `wrong_floor_night_hold.png` + `.json` + `_depth.png` | stop-klatka nocna 540×960, 32 spp, kotwice, głębia (maska zasłaniania) |
| `wrong_floor_night_ajar_hold.*` | wariant: pani Teresa otwiera (drzwi uchylone do środka, łańcuch, światło z przedpokoju) |
| `wrong_floor_{evening,day}_hold.*` | ta sama stop-klatka wieczorem i w dzień, 270×480 (porównanie światła) |
| `wrong_floor_night_shadow_kazimierz.png`, `wrong_floor_night_ajar_shadow_teresa.png` | mapy cienia postaci (Cycles Shadow Catcher: stosunek światła z postacią / bez) |
| `wrong_floor_preview_{night,evening,day}_kazimierz.png`, `wrong_floor_preview_night_teresa.png` | proof składania: stop-klatka + zaślepka postaci |
| `wrong_floor_preview_board.png` | zestawienie czterech proofów |
| `wrong_floor_preview_vs_stairwell_locks.png` | porównanie: noc tutaj / `stairwell_night.png` / `stairwell.png` / `wafer.png` |
| `placeholder_kazimierz.png`, `placeholder_teresa.png` | szare sylwetki-zaślepki z alfą (do czasu dostawy Magnific D1/D2) |

Sekwencja (216×384, 8 spp), stop-klatki i proofy są z tego samego stanu skryptu (przebieg materiałów zdjęciowych).

## Czego potrzebuje gra

1. **Sekwencja** `<job>_<time>_seq/f_####.png` (12 fps, 36 klatek) — odtwarzana raz jako flipbook albo po
   złożeniu do wideo (polecenie niżej). Ostatnia klatka = ta sama kamera co stop-klatka.
2. **Stop-klatka** `<job>_<time>_hold.png` — wyższa jakość; gra przenika z ostatniej klatki sekwencji (100–150 ms).
3. **Kotwice** `<job>_<time>_hold.json` (jak D-41, współrzędne 0..1 od lewego górnego rogu, czworokąty tl,tr,br,bl):
   - `anchors.namecard` — wizytówka w drzwiach (tekst nazwiska przez i18n, homografia),
   - `anchors.mailbox_card` — wizytówka na skrzynce („inne nazwisko”, poszlaka z `job.wrong_floor.line.2`),
   - `anchors.number_plate`, `anchors.wreath`, `anchors.door`, `anchors.cylinder` — obszary dotyku/podświetleń,
   - `figures.<postać>` — `feet_center`, `feet_line` (linia stóp), `head_top`, `height_px` (dla wzrostu `height_mm`),
     `px_per_mm`, `depth_mm`, `door_state` (closed/ajar) i `lights` (kolor, siła względna, kierunek do światła
     w 2D i 3D, elewacja) — do składania postaci i jej „oddechu” w grze,
   - `camera` — pozycja, obiektyw, shift (gdyby gra chciała liczyć punkty sama, D-41),
   - `depth_png` — plik głębi i kodowanie.
4. **Postać** — wycięte zdjęcie (Magnific D1/D2) złożone narzędziem `arrival_composite.py` w gotowy PNG
   (albo osobno: warstwa postaci + maska cienia, jeśli gra ma animować oddech na żywo).

## Finał na GPU (RTX 5070, lokalna sesja właściciela)

Wszystkie polecenia z katalogu repo. `BL=/ścieżka/do/blender` (4.2 LTS). Rozdzielczość: master 9:16
`1080x1920` (D-41: ważne elementy w środkowych 80 % szerokości); `1080x2400` też działa — kotwice liczą się dla
podanej rozdzielczości, kadr jest wtedy węższy w poziomie (pan Kazimierz bliżej lewej krawędzi, ok. 6 %).

```bash
BL=blender   # lub pełna ścieżka
# 1) sekwencja 36 klatek (noc), z ruchem kamery i rozmyciem ruchu
$BL -b -P art/blender/arrival_scene.py -- --job wrong_floor --time night --mode seq \
    --device GPU --res 1080x1920 --spp 128 --hair 1
# 2) stop-klatka + kotwice + głębia, drzwi zamknięte (pan Kazimierz) i uchylone (pani Teresa)
$BL -b -P art/blender/arrival_scene.py -- --time night --mode still --device GPU --still-res 1080x1920 --still-spp 512 --hair 1
$BL -b -P art/blender/arrival_scene.py -- --time night --mode still --door ajar --device GPU --still-res 1080x1920 --still-spp 512 --hair 1
# 3) mapy cienia dla prawdziwych wycinków (po dostawie Magnific D1/D2)
$BL -b -P art/blender/arrival_scene.py -- --time night --mode shadow --device GPU --still-res 1080x1920 --still-spp 256 \
    --figure kazimierz=contrib/incoming/magnific/D1_kazimierz_fullbody.png
$BL -b -P art/blender/arrival_scene.py -- --time night --mode shadow --door ajar --device GPU --still-res 1080x1920 --still-spp 256 \
    --figure teresa=contrib/incoming/magnific/D2_teresa_fullbody.png
# 4) złożenie postaci (Pillow + NumPy)
python3 art/blender/arrival_composite.py --plate art/renders/arrival/wrong_floor_night_hold.png \
    --figure kazimierz=contrib/incoming/magnific/D1_kazimierz_fullbody.png \
    --shadow art/renders/arrival/wrong_floor_night_shadow_kazimierz.png --out art/renders/arrival/wrong_floor_night_kazimierz.png
python3 art/blender/arrival_composite.py --plate art/renders/arrival/wrong_floor_night_ajar_hold.png \
    --figure teresa=contrib/incoming/magnific/D2_teresa_fullbody.png \
    --shadow art/renders/arrival/wrong_floor_night_ajar_shadow_teresa.png --out art/renders/arrival/wrong_floor_night_teresa.png
#    --breath 24 : dodatkowo 24 klatki oddechu (pętla 2 s) zamiast jednego PNG
# 5) arkusz kontrolny i wideo dla gry (opcjonalnie)
python3 art/blender/arrival_composite.py --contact art/renders/arrival/wrong_floor_night_seq --out art/renders/arrival/wrong_floor_preview_contact.png
ffmpeg -framerate 12 -i art/renders/arrival/wrong_floor_night_seq/f_%04d.png -c:v libvpx-vp9 -b:v 0 -crf 30 -pix_fmt yuv420p wrong_floor_night.webm
```

Pory dnia: `--time day|evening|night` (noc: jedna ciepła żarówka w mlecznym kloszu + zimne okno, światło spada
z kwadratem odległości; wieczór: niebieska godzina w oknie, słabsza żarówka; dzień: żarówka zgaszona, okno + doświetlenie
z góry klatki). Opcje: `--frames 36 --fps 12`, `--step N` (co N-ta klatka na szybki podgląd), `--denoiser OPTIX`,
`--number 19`, `--threads N`, `--out-dir`.

### Czasy

- Tu (CPU, 4 rdzenie dzielone z 2 innymi renderami): budowa sceny ok. 40 s; klatka 270×480 @ 10 spp ok. 60 s;
  stop-klatka 540×960 @ 32 spp ok. 5–6 min.
- RTX 5070 (szacunek, niezmierzony): klatka 1080×1920 @ 128 spp ok. 10–25 s → sekwencja 6–15 min;
  stop-klatka @ 512 spp 1–2 min; mapa cienia 1 min. `--hair 1` (włosie wycieraczki) dokłada kilka sekund na klatkę.

## Ocena podglądu i znane braki

**Przebieg materiałów zdjęciowych (`art/textures/photo/`, `--photo 0` wyłącza):** tynk wapienny (`wall_lime_plaster`)
z łatami i prześwitującą starą farbą, lamperia olejna (`wall_oil_paint_green`) z otarciami butów/toreb nisko,
pas brudu wzdłuż posadzki liczony od linii schodów (na biegu też), lastryko `terrazzo_grey_red` z przetarciami,
mosiądz `brass_patina_grease` (tłuste ślady palców), brud wokół klamki i kopnięcia na dole skrzydła, ciemniejsze
brzegi podestu przy balustradzie. Przedpokój za uchylonymi drzwiami: płytki cementowe (`cement_tiles`), chodnik
w paski, płaszcze na wieszaku z półką, szafka na buty, zdjęcie w ramce, ciepła lampka w mlecznym kloszu. Za oknem:
bielona cegła oficyny naprzeciwko z oknami (w nocy kilka zapalonych), lampa na podwórzu, niebo nad dachem; szkło
już nie mleczne. Dzień: słońce wpada przez okno i kładzie jasną plamę z cieniem szprosów przy nogach postaci.

- **Lepiej niż wcześniej i niż `stairwell.png`:** lastryko ma prawdziwe kamyki, ściana ma fakturę, rysy i zabrudzenia,
  podwórze daje głębię za oknem, przedpokój wygląda na zamieszkany. Noc jest najbardziej udana.
- **Nadal słabsze niż rendery zamków:** przy 540 px i 24 spp odszumianie wygładza tynk i drewno, więc kadr jest
  miękki; rendery zamków są ostre, bo kamera jest blisko przedmiotu, a tekstury mają dużo pikseli. Finał 1080×1920
  @ 512 spp wyostrzy obraz. Drzwi zostały proceduralne (dąb z zestawu) — można je podmienić na `g03:oak_satin`.
  Poręcz nie ma jeszcze wytartego połysku od rąk.
- **Światło:** podwórze oświetla ciepła lampa sodowa, więc w nocy okno nie daje już tak wyraźnie zimnego akcentu
  jak w pierwszej wersji (zimne światło okna nadal pada na schody). Jeśli właściciel chce mocniejszego podziału
  ciepłe/zimne, wystarczy zmienić kolor `court_lamp` na zimny LED. Dzień jest mniej płaski niż wcześniej, ale wciąż
  najsłabszy z trzech; plama słońca jest mała.
- **Jasny owal na skrzydle drzwi** to odbicie mlecznego klosza w lakierze (prawdziwe, nie błąd). Natomiast plamy
  brudu (`stain_decal`) dawały połysk, którego nie ma pod nimi farba — poprawione w `arrival_scene.py` i w
  `stairwell.py` (Specular IOR Level = 0); `stairwell.png` nie był renderowany ponownie.
- **Światło na postaci:** żarówka wisi za panem Kazimierzem, więc jest on podświetlony od tyłu, a cień pada do przodu.
  Prompt D1/D2 powinien prosić o ciepłe światło z góry i z tyłu po lewej oraz miękkie wypełnienie z przodu.
- Pozycja postaci (po lewej od drzwi) i kąt uchylenia (38°) zatwierdzone przez koordynatora.
