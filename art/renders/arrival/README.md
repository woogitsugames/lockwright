# Przyjazd do klienta (D-58) — pilot `job.wrong_floor`

Scenka 2.5D: 3 s przejazdu kamery po ostatnich stopniach kamienicy na podest, potem stop-klatka drzwi
(nr 19, wianek z suszonych kwiatów, wycieraczka, skrzynka na listy z wizytówką) i klient z wyciętego zdjęcia.
Scena powstaje z zestawu klatki schodowej: `art/blender/arrival_scene.py` uruchamia bez zmian
`art/blender/stairwell.py` i dobudowuje bieg schodów, okno, wianek, tabliczkę, skrzynkę, kamerę i światło pory dnia.

## Pliki w tym katalogu (finały GPU i historyczne podglądy CPU)

| Plik | Co to |
|---|---|
| `wrong_floor_night_seq/f_0001..0036.png` | sekwencja 36 kl. @ 12 fps (3,0 s), 270×480, 10 spp |
| `wrong_floor_preview_contact.png` | arkusz kontrolny sekwencji (6×6) |
| `wrong_floor_night_hold.png` + `.json` + `_depth.png` | finał GPU: stop-klatka nocna 1080×1920, 512 spp, OIDN, kotwice, głębia (maska zasłaniania) |
| `wrong_floor_night_ajar_hold.*` | finał GPU 1080×1920 / 512 spp: pani Teresa otwiera (drzwi uchylone do środka, łańcuch, światło z przedpokoju) |
| `wrong_floor_{evening,day}_hold.*` | finały GPU: wieczór i dzień, 1080×1920, 512 spp, OIDN |
| `wrong_floor_night_shadow_kazimierz.png`, `wrong_floor_night_ajar_shadow_teresa.png` | mapy cienia postaci (Cycles Shadow Catcher: stosunek światła z postacią / bez) |
| `wrong_floor_preview_{night,evening,day}_kazimierz.png`, `wrong_floor_preview_night_teresa.png` | proof składania: stop-klatka + zaślepka postaci |
| `wrong_floor_preview_board.png` | zestawienie czterech proofów |
| `wrong_floor_preview_vs_stairwell_locks.png` | porównanie: noc tutaj / `stairwell_night.png` / `stairwell.png` / `wafer.png` |
| `placeholder_kazimierz.png`, `placeholder_teresa.png` | szare sylwetki-zaślepki z alfą (do czasu dostawy Magnific D1/D2) |
| `figures/kazimierz.png`, `figures/teresa.png` | wycinki postaci z G23 (ChatGPT, D-66): RGBA, `art/tools/figure_cutout.py` (rembg BiRefNet-portrait + odkażenie koloru pymatting; Kazimierz `--keep-box 380,175,425,250` przywraca klucz) |
| `wrong_floor_{night,evening,day}_kazimierz.png`, `wrong_floor_night_teresa.png` | kompozyty z prawdziwymi postaciami na finałach GPU, **cień 2D** (mapy cienia GPU czekają na lokalną sesję) |
| `wrong_floor_with_figures_board.jpg` | arkusz przeglądu czterech kompozytów (`art/tools/arrival_board.py`) |

Historyczne sekwencje i pliki `preview_*` pozostają podglądami CPU. Stop-klatki `*_hold.*` zastąpiono finałami GPU 2026-11-06. Nowe arkusze `*_final_contact.png` pokazują po 36 klatek 1080×1920 / 128 spp z włosiem; pełne 108 klatek pozostają lokalnie w `build/local-session/arrival-master/` (nie w repo). `wrong_floor_final_board.jpg` porównuje cztery finały.

Postacie przyszły z ChatGPT (G23, D-66) zamiast Magnific D1/D2; przegląd: `contrib/gpt/REVIEW-G23.md`.
Kompozyty z prawdziwymi postaciami (2026-11-06, bez ponownego renderu stop-klatek GPU):
```bash
A=art/renders/arrival; G="--tint-gain 2.0 --sat 1.2 --wrap 0.25"
for t in night evening day; do python3 art/blender/arrival_composite.py --plate $A/wrong_floor_${t}_hold.png \
    --figure kazimierz=$A/figures/kazimierz.png $G --exposure 1.15 --out $A/wrong_floor_${t}_kazimierz.png; done
python3 art/blender/arrival_composite.py --plate $A/wrong_floor_night_ajar_hold.png --figure teresa=$A/figures/teresa.png \
    --feet-world teresa=560,720 --occlude-mm 0 --exposure 1.5 $G --out $A/wrong_floor_night_teresa.png
python3 art/tools/arrival_board.py
```
- **Cień:** stare `*_shadow_*.png` (540×960, CPU, zaślepki) nie pasują do nowych sylwetek, więc kompozyty mają cień 2D
  (okluzja pod podeszwami + miękka plama od żarówki, maskowana głębią: nie kładzie się na ościeżnicy). Polecenia mapy
  cienia GPU: `docs/handoff/LOCAL-SESSION-PROMPT.md`, dodatek G23.
- **Pani Teresa — nowe miejsce:** slot (250, 420) stał przed swobodną krawędzią uchylonego skrzydła (≈ 262, 600), więc
  postać wisiała na skrzydle i nie dało się jej nim zasłonić. Teraz (560, 720): stoi w przedpokoju za skrzydłem i zagląda
  przez szparę; skrzydło i ościeżnica zasłaniają ją przez mapę głębi (`--occlude-mm 0`). `arrival_scene.py` ma już nowy
  slot; JSON stop-klatki `night_ajar` ma stary, stąd `--feet-world` (rzutowanie kamerą z JSON-a, sprawdzone na obu
  starych slotach co do piksela). Przy następnym renderze `--door ajar` flagę można usunąć.
- **Kolor:** zdjęcia studyjne były za chłodne i mleczne na tle ciepłej żarówki; `--tint-gain 2.0 --sat 1.2` przenosi je
  w kolor światła sceny, `--wrap 0.25` (było 0,55) usuwa poświatę na krawędzi. Szum głębi (liście, gałązki wianka) nie
  dziurawi już postaci (otwarcie morfologiczne maski zasłaniania).
- **Znane braki:** dzień — plama słońca z okna nie oświetla nóg pana Kazimierza (nie jest liczona); światło na postaci
  to wciąż „studio z przodu”, żarówka nad nim daje tylko gradient góra–dół, bez obrysu na włosach; nocą Teresa jest
  ciemna (podświetlona od przedpokoju) — na telefonie do sprawdzenia. Integracja w grze należy do sesji A po akceptacji.

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
