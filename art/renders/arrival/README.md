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
| `figures/kazimierz.png`, `figures/teresa.png` | wycinki postaci (Kazimierz od 2026-11-06 z G25 v2, Teresa z G23) (ChatGPT, D-66): RGBA, `art/tools/figure_cutout.py` (rembg BiRefNet-portrait + odkażenie koloru pymatting; G23-Kazimierz miał `--keep-box 380,175,425,250`, G25 go nie potrzebuje) |
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

## G25 i scenka w grze (2026-11-06, D-74)

- `figures/kazimierz.png` to teraz wycinek z G25 v2 (`contrib/gpt/G25/images/D1_kazimierz_fullbody_v2.png`, patrzy na
  klucz w prawej ręce); `figure_cutout.py` bez `--keep-box` — klucz leży na tle marynarki i model go zachowuje.
  Kompozyty nocy/wieczoru/dnia złożone ponownie (dzień `--exposure 1.0`, wcześniej 1,15 — postać była jaśniejsza
  od otoczenia); pani Teresa bez zmian. Arkusz: `wrong_floor_with_figures_board_v2.jpg`.
- **Cień kontaktowy z podeszew:** `arrival_composite.py` liczy ślad stóp z najniższego kryjącego piksela każdej kolumny
  w dolnych 12 % wycinka (zamiast jednej elipsy pod środkiem ramki). Nowa poza ma ciężar na jednej nodze i drugą stopę
  z tyłu — z elipsą tylna stopa wisiała w powietrzu.
- **Ocena v2:** noc i wieczór dobre (klucz czytelny, twarz w świetle żarówki); dzień nadal najsłabszy — postać
  oświetlona „studyjnie” i chłodniejsza niż plama słońca na posadzce, ciepły obrys z lewej (ze zdjęcia) nie ma
  źródła w kadrze dziennym. Do poprawy mapą cienia GPU i ew. `--warm` dla dnia.
- **Gra:** `python3 art/tools/arrival_export.py` → `game/assets/arrival/wrong_floor/<pora>/` (flipbook `seq/f_NN.webp`,
  `plate_<postać>.webp` + `figure_<postać>.webp` z `arrival_composite.py --layers-out`) i kotwice w
  `game/data/arrival_scenes.json`. Bez `--master` przejazd pochodzi z kafli `*_final_contact.png` (tymczasowe, 178×318);
  z `--master build/local-session/arrival-master` z pełnych klatek GPU (540×960). `--shadows` składa z mapami cienia GPU.

## Kolejne zlecenia bez postaci (2026-11-08, D-84)

Pięć wczesnych zleceń dostało scenkę z tego samego zestawu, ubraną danymi z `art/blender/arrival_jobs.json`
(drzwi, tabliczka, numer, lamperia, schody, pora, rekwizyty, koniec ruchu kamery). Stop-klatka to pusty podest
(wycinki mają tylko Kazimierz i Teresa); historię opowiadają drzwi i rzeczy pod nimi.

| Zlecenie | Pora | Drzwi / klatka | Rekwizyty (co mówią) |
|---|---|---|---|
| `grandma_broth` | dzień | stare, malowane na brąz, emalia nr 7; lamperia bordowa, schody dębowe | żółty pion gazowy z zaworem zakręconym w poprzek (sąsiadka zakręciła gaz), list wystający ze skrzynki („list na panią”) |
| `cat_bathroom` | wieczór | jasno malowane, uchylone 62° (Marta otworzyła), emalia nr 23; lamperia szaroniebieska, lastryko | miska z karmą i filcowa myszka na chodniku w przedpokoju |
| `refuse_ex_partner` | noc | obite skajem (wałek, ćwieki, sznurek w romby), mosiądz nr 4; lastryko | drugi, nowiutki zamek nad starym i pył z wiercenia pod nim — ona niedawno coś zmieniła |
| `newlyweds_4am` | noc | dąb, emalia nr 12; lamperia ochrowa, lastryko | pudło z tortem na wycieraczce, płatki róż i ryż od schodów do drzwi |
| `refuse_rush_bribe` | noc (zlecenie: „1:00”) | dąb, mosiądz nr 8; schody dębowe | zapchana skrzynka, listy i ulotki na wycieraczce, jeden list wsunięty pod drzwi, ulotki w szparze — od tygodni nikogo nie ma |

```bash
M=C:/Users/matma/lockwright/build/local-session/arrival-master   # mastery tylko lokalnie
blender -b -P art/blender/arrival_scene.py -- --job grandma_broth --mode still --device GPU --still-res 1080x1920 --still-spp 512 --hair 1 --out-dir $M
blender -b -P art/blender/arrival_scene.py -- --job grandma_broth --mode seq --device GPU --res 1080x1920 --spp 128 --hair 1 --out-dir $M
python art/tools/arrival_export.py --job grandma_broth --master $M     # albo --job all
```
`--time` domyślnie bierze pierwszą porę z danych; podgląd: `--still-res 720x1280 --still-spp 64` (ok. 10 s na GPU).
Pliki tutaj: `<job>_<pora>_hold.{png,json}` + `_hold_depth.png` (finał GPU 512 spp), `<job>_<pora>_final_contact.png`
(36 klatek 128 spp), `arrival_early_jobs_board.jpg` (pięć stop-klatek obok pilota).

## Rozdziały 3–6 (2026-11-09, D-108)

Siedem zleceń z rozdz. 3–6 i drzwi 21 pana Kazimierza (rozdz. 9) dostały scenkę zamiast pożyczonego zdjęcia G07 (część wybrana po audycie D-104: wieczorne drzwi 7 to numer pani Haliny, „Administracja” przy beginażu, drzwi 12 zamiast 21). Arkusz: `arrival_ch3_6_board.jpg`
(finały obok pizzerii i muzeum + dwa odrzucone podglądy 720×1280 / 64 spp).

| Zlecenie | Zestaw | Pora | Co opowiada |
|---|---|---|---|
| `krakow_tenement_gate` | `facade` / `tenement_gate` | deszcz | brama z 1890 r. (konserwator: ani jednej dziury), lampa w łuku, zamek skrzynkowy z kluczem, który utknął, kartka lokatorów ze strzałką na sąsiednie podwórko, odbojniki, mokra kostka |
| `ghent_beguinage` | `facade` / `beguinage` | deszcz | bielony dom beginażu, smołowany cokół, zielone drzwi ze starym szyldem zamka, rower brata Pietera z wiklinowym koszykiem |
| `liege_bakery` | `shop` / `bakery` | noc (3:50) | pęk 30 kluczy wujka na złym kluczu w zamku zaplecza, ciasto rośnie pod lnem, pusta ściana na pieczywo, zegar 3:50 |
| `uncle_safe_heirs` | klatka | wieczór | drzwi nr 16 uchylone przez spadkobierców, klepsydra wujka przy drzwiach, walizka i buty w przedpokoju |
| `dollhouse_wooden_lock` | klatka | dzień | drzwi nr 11, hulajnoga Hani, dębowa deska na nowy drewniany klucz |
| `widow_bureau` | klatka | wieczór | ciemnozielone drzwi nr 2 (nie 7), dwa stosy książek męża przewiązane sznurkiem |
| `charleroi_letters` | `facade` / `beguinage` (czerwona cegła) | wieczór | górniczy dom szeregowy pani Martine, nr 38 |
| `t43_09_08_spare_key_hook` | klatka | dzień | drzwi pana Kazimierza nr 21, ta sama kamienica co 19 pani Teresy, bez wianka |

Odrzucone: `brussels_townhouse` (styl `townhouse` zostaje w zestawie jako look-dev) i `allotment_shed` (zestaw usunięty) —
nie trzymały poziomu klatki/pizzerii. Polecenia jak wyżej (`arrival_place.py` dla zestawów, `arrival_scene.py --hair 1`
dla klatki), pora `rainy` jest własną porą scenki. Czasy na RTX 5070: stop-klatka 512 spp / przejazd 36 × 128 spp (z budową sceny):
krakow 129 s / 906 s, ghent 202 s / 1133 s, charleroi 122 s / 980 s, liege 47 s / 550 s, uncle 75 s / 713 s, widow 74 s / 706 s,
dollhouse 69 s / 680 s, spare_key_hook 66 s / 639 s (mgła w deszczu dokłada ok. 30 %). Eksport: 1,4–1,7 MB na zlecenie
(charleroi 2,7 MB — drobna cegła), razem 14 MB.

## Miejsca zastępcze z audytu (2026-11-09, D-110)

Cztery miejsca, które pokazywały złe zdjęcie zastępcze (drzwi 7 pani Haliny, „Pralnia”, „Warsztat ślusarski”), dostały
scenkę; inne zlecenia w tym samym miejscu biorą jej stop-klatkę przez `arrival_from`. Arkusz: `arrival_placeholders_board.jpg`.

| Zlecenie (scena) | Zestaw | Pora | Wspólne z |
|---|---|---|---|
| `shared_room_door` — drzwi świetlicy, tablica korkowa, składane krzesła | klatka | wieczór | 9 zleceń świetlicy (rozdz. 7–12) |
| `student_dorm` — korytarz akademika, drzwi 412 z tablicą i naklejkami, suszarka | `corridor` + `dorm` | noc | `t43_10_05_porters_drawer` |
| `drummer_locker` — sala prób, szafka nr 8, panele akustyczne, werbel, wzmacniacz | `lockers` (nowy) | wieczór | `edek_rehearsal_store`, `t43_11_05_rehearsal_chest` |
| `gosia_workbench_drawer` — pracownia renowacji, stół z zamkniętą szufladą | `shop` / `atelier` | dzień | `bramah_bureau` |

Zdjęcie na karcie roweru Borysa: `t43_11_02_bicycle_stand_before_day_hold.png` (sama stop-klatka, `--job
t43_11_02_bicycle_stand_before`), w grze `game/assets/ui/cards/photo_borys_bike_before.webp`. Czasy (RTX 5070, stop-klatka 512 spp / przejazd 36 × 128 spp): świetlica 77 s / 721 s, akademik 59 s / 619 s, sala prób 48 s / 514 s, pracownia 45 s / 520 s; zdjęcie roweru 248 s (budowa kostki + 512 spp).

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
