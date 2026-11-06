# Lockwright: prompt startowy dla lokalnej sesji Claude Code (PC właściciela, GPU + telefon)

Wklej całość jako pierwszą wiadomość w Claude Code na komputerze właściciela
(Windows, Intel Core Ultra 7 270, RTX 5070, 64 GB RAM). Stan briefu: 2026-11-06.

---

Jesteś **lokalną sesją Claude Code** projektu Lockwright (mobilna gra o ślusarzu z pogotowia zamkowego).
Z właścicielem rozmawiasz **po polsku**. Kod, komentarze i nazwy plików po angielsku.

## Rola (ważne)
- **Koordynuje sesja A w chmurze.** Ona decyduje, co wchodzi do gry, scala, pilnuje CI. Ty robisz tylko to,
  czego chmura nie umie: **rendery Cycles na GPU** i **testy na telefonie przez adb**.
- Nie przebudowujesz logiki gry, nie zmieniasz `lockcore/`, `game/scripts/**`, `game/i18n/*.csv`, CI ani decyzji.
  Gdy do zadania potrzebna jest zmiana w kodzie gry (np. stałe widoku), opisz ją w logu dla sesji A i idź dalej.
- Wyjątek: drobna zmiana w skryptach Blendera, jeśli bez niej nie da się renderować na GPU (pkt 0.4).
- Właściciel 2026-11-05: **tylko rozwój gry**. Zero filmów, zwiastunów, rolek, key artów i renderów marketingowych
  (`art/blender/marketing/` nie ruszasz). Gemini niedostępny.
- Agentów nie uruchamiasz (praca liniowa, GPU jest jedno).

## 0. Start
1. Repo (Git for Windows, terminal Git Bash; wszystkie polecenia niżej są dla bash):
   ```bash
   cd ~ && git clone https://github.com/woogitsugames/lockwright.git || (cd lockwright && git pull --rebase origin main)
   cd ~/lockwright && git log --oneline -5
   ```
   Przeczytaj: `CLAUDE.md`, `docs/handoff/SESSION-A-HANDOVER.md` §2 i §8–§9, koniec `docs/handoff/SESSION-B-LOG.md`
   (ok. 150 linii), `art/renders/arrival/README.md`.
2. Narzędzia (zapytaj właściciela o zgodę na instalację, potem zainstaluj):
   - **Blender 4.2 LTS** (repo używa 4.2.9): ZIP `https://download.blender.org/release/Blender4.2/blender-4.2.9-windows-x64.zip`
     rozpakuj do `C:\tools\blender-4.2.9`. Potem `BL="/c/tools/blender-4.2.9/blender.exe"`.
   - **Python 3.11+** z `pip install pillow numpy` (składanie postaci, zestawienia).
   - **Godot 4.7.2**: `https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_win64.exe.zip`
     + szablony `Godot_v4.7.2-stable_export_templates.tpz` (rozpakuj zawartość `templates/` do
     `%APPDATA%\Godot\export_templates\4.7.2.stable\`).
   - **JDK 17** (`winget install Microsoft.OpenJDK.17`), **Android SDK** cmdline-tools
     (`https://developer.android.com/studio#command-tools`), potem
     `sdkmanager "platforms;android-36" "build-tools;36.1.0" "platform-tools" "ndk;28.1.13356709"` (wersje jak w
     `.github/workflows/game-android.yml`). `adb` jest w `platform-tools`.
   - **GitHub CLI** `gh` (zalogowany), **ffmpeg** (klatki z nagrań ekranu).
3. Sprawdź GPU w Blenderze (OptiX):
   ```bash
   "$BL" -b --python-expr "import bpy;p=bpy.context.preferences.addons['cycles'].preferences;p.compute_device_type='OPTIX';p.refresh_devices();print([d.name for d in p.devices])"
   ```
4. **GPU w skryptach.** Skrypty z `--device` (`dial_safe_plate.py`, `combo_plate.py`, `tool_layers.py`,
   `arrival_scene.py`) włączają GPU same. `photo_plates.py`, `warded_photo_plate.py`, `render_plate.py`
   (przez `cutaway.py`), `lever.py`, `ring_combo.py` i `menu_gate.py` idą przez `render_setup()` w
   `art/blender/lw_common.py` (oraz własny setup w `cutaway.py`), który ustawia na sztywno `device = 'CPU'`.
   Dodaj tam jedną opcję: zmienna środowiskowa `LW_DEVICE=GPU` → ta sama logika co
   `enable_gpu_cycles()` z `art/blender/plates/plate_common.py` (OptiX, potem CUDA), denoiser OptiX lub OIDN.
   Domyślnie bez zmian (CPU), więc nic nie psujesz chmurze. Commit osobno, `[skip ci]`.
   Potem w każdej sesji: `export LW_DEVICE=GPU`.

## 1. Zadania (kolejność = priorytet)

### (a) Płyty planu B w 2× (ostrość na dużych ekranach, N-65)
Rozmiar docelowy: piny/warded/wafer/lever **2472×3300** (dziś 1236×1650), dial_safe/combo/disc_detainer
**1236×1648** (dziś szkic CPU 618×824, 16–32 spp). Nazwy plików zostają te same (gra czyta stałe ścieżki
albo `res` z `layers.json`).
```bash
export LW_DEVICE=GPU
# piny (pin_tumbler) — sekcja z cutaway.py
"$BL" -b -P game/assets/photoreal/tools/render_plate.py -- --res 2472x3300 --samples 128 \
    --out game/assets/photoreal/plate/plate_1236x1650.png
# warded — CAŁOŚĆ naraz (parts, plate, wards z tymi samymi materiałami; zadanie (c))
"$BL" -b -P art/blender/plates/warded_photo_plate.py -- --out-dir game/assets/photoreal_families/warded/photo \
    --res 2472x3300 --samples 128
# wafer i lever
"$BL" -b -P art/blender/plates/photo_plates.py -- --family wafer --out-dir game/assets/photoreal_families/wafer/photo --res 2472x3300 --samples 128
"$BL" -b -P art/blender/plates/photo_plates.py -- --family lever --out-dir game/assets/photoreal_families/lever/photo --res 2472x3300 --samples 128
"$BL" -b -P art/blender/plates/photo_plates.py -- --family lever --detector 1 --passes parts \
    --out-dir game/assets/photoreal_families/lever/photo --res 2472x3300 --samples 128   # -> parts_detector.png
# sejf, kółka, tarczowy (skrypty z --device)
"$BL" -b -P art/blender/plates/dial_safe_plate.py -- --out-dir game/assets/photoreal_families/dial_safe/photo --res 1236x1648 --spp 256 --device GPU
"$BL" -b -P art/blender/plates/combo_plate.py -- --out-dir game/assets/photoreal_families/combo/photo --res 1236x1648 --spp 256 --device GPU
"$BL" -b -P art/blender/plates/combo_plate.py -- --family disc_detainer --out-dir game/assets/photoreal_families/disc_detainer/photo --res 1236x1648 --spp 256 --device GPU
# warstwy narzędzi magnetic/dimple (sonda, chorągiewka): finał 48 px/mm
"$BL" -b -P art/blender/plates/tool_layers.py -- --out-dir game/assets/photoreal_families/tools --ppmm 48 --spp 128 --device GPU
```
- Przed każdym renderem przeczytaj nagłówek skryptu (`grep -n "arg('--" <skrypt>`): flagi mogły się zmienić.
  Każdą nową rodzinę z planem B, która pojawi się na `main` (`JobRun.PHOTOREAL_READY` w
  `game/scripts/lock/job_run.gd`, skrypty w `art/blender/plates/`), renderuj tak samo.
- Najpierw **jeden** szybki test (`--samples 16`), porównaj z obecną płytą w tej samej skali (położenie części
  musi się zgadzać 1:1; `layers.json` ma się przeliczyć sam). Dopiero potem finał.
- **Rozmiar paczki:** pck ≤ 58 MB (D-55, `perf-budget`). Płyta 2× to 4× pikseli. Każdy obraz gry ma mieć **stratny**
  import (`compress/mode=1`, WebP ~0,8–0,85) w `.import` i `git add -f <plik>.import` (`*.import` jest w
  `.gitignore`, bez tego CI importuje bezstratnie, N-30). Po imporcie Godotem
  (`Godot_v4.7.2-stable_win64.exe --headless --path game --import`) sprawdź rozmiar `.ctex`. Jeśli razem
  przekroczysz budżet, zatrzymaj się i opisz to sesji A (opcje: 2× tylko dla profilu „wysoka”, mniejsze 1,5×).
- Zestawienie przed/po (wycinek 1:1) do `docs/handoff/device-tests/fixes/plates_2x/` i pokaż właścicielowi.

### (b) `lever_detector`: model 5-dźwigniowy i jego płyty
Stan: ekran `lock_job_lever_detector.tscn`, `DetectorControl` i `lever_view.gd` są gotowe na **dowolną liczbę dźwigni (do 6)**. Liczbę dźwigni, ich głębokości i osie widok bierze z GLB i `scene.json`. Rodzina **odblokuje się sama**, gdy w projekcie pojawi się `game/assets/photoreal_families/lever_detector/lever_detector_baked.glb` (`JobRun.planb_ready`). Sesja A nie musi niczego zmieniać w kodzie.
Do zrobienia po stronie Blendera:
1. W `art/blender/lever.py` i `art/blender/plates/lever_plate.py` dodaj opcję `--levers 5` (domyślnie 3, więc dla `lever` nic się nie zmienia). Pięć dźwigni w kasecie: cieńsza blacha albo głębsza kaseta. Trzpień, sprężyny, nity i zapadkę detektora (`--detector 1`, na ostatniej dźwigni) dopasuj do pięciu. Każda dźwignia ma mieć ≥ 28 dp na ekranie 412 dp, a linia bramki ma być czytelna w skali szarości.
2. Wypiecz model i płyty do **osobnego katalogu** `game/assets/photoreal_families/lever_detector/`, żeby nie ruszyć zwykłego `lever`. Nazwy plików:
   - `lever_detector_baked.glb`: węzły `lever0`…`lever4`, `spring0`…`spring4`, `rivet0`…`rivet4`, `detector`, `stump`, `lifter`, `tension`, `tension_shaft`, `bolt`, `stud`, `stud_post`. Dźwignie w pozycji spoczynku **z bramką na trzpieniu** (rest lift = needed lift);
   - `scene.json` z kluczami jak w `lever/scene.json`: `camera`, `pivot` [x, y, z], `stump_x`, `lever_specs` (dla każdej dźwigni `y0` = głębokość w Blenderze), `detector_pivot`;
   - `photo/plate.png` (bez ruchomych części) i `photo/parts.png` (wszystko z detektorem), oba 1236×1650. Wyrenderuj je przez `art/blender/plates/photo_plates.py --family lever --detector 1 --out-dir game/assets/photoreal_families/lever_detector/photo`. W `CONFIG['lever']` tego skryptu podmiana pozycji spoczynku zakłada listę 3 dźwigni, więc dopisz wariant dla 5 (lift = needed). Plik `parts_detector.png` powstanie z sufiksem: zmień nazwę na `parts.png` albo zostaw oba, bo widok woli `parts_detector.png`.
3. W projekcie Godot: import, potem lossy `.import` dla obu PNG (`compress/mode=1`, `git add -f`), wpis w `docs/ASSETS.md` i `gut` (test `test_every_lever_detector_job_opens_in_both_modes` przestanie być „pending”). `REST_DELTA_LIFT` i `GATE_HALF_H` w `lever_view.gd` zmień tylko wtedy, gdy nowa geometria ma inne wymiary bramek.

### (c) `warded_photo_plate.py` w całości
`parts.png` powstało przed commitem 508b3b3 (nowe materiały rygla/sondy), `plate`/`wards` po nim. Jeden przebieg
wszystkich trzech warstw — polecenie w (a). Porównaj z `art/renders/warded.png`.

### (d) Scenka przyjazdu D-58 (`job.wrong_floor`) — finał
Polecenia: `art/renders/arrival/README.md` §„Finał na GPU”. Kolejno:
1. sekwencje `--mode seq` dla `--time night`, `evening`, `day` (1080×1920, 128 spp, `--hair 1`);
2. stop-klatki `--mode still` (512 spp) dla trzech pór oraz `--door ajar` w nocy;
3. mapy cienia `--mode shadow` i złożenie `arrival_composite.py` — **dopiero gdy są wycinki Magnific D1/D2**
   (`contrib/incoming/magnific/D1_kazimierz_fullbody.png`, `D2_teresa_fullbody.png`). Do tego czasu zostają
   zaślepki `placeholder_*.png`;
4. arkusz kontrolny i porównanie z renderami zamków (`wrong_floor_preview_vs_stairwell_locks.png`) — pokaż właścicielowi.
Gdy `--denoiser OPTIX` daje plamy na tynku, wróć do OIDN. Rendery do `art/renders/arrival/`; do `game/` trafiają
dopiero po akceptacji (decyduje sesja A).

### (e) Menu — finalny render
Nagłówek `art/blender/menu_gate.py`: całość jednym poleceniem
```bash
python art/blender/menu_compose.py --render-all --blender "$BL" --samples 160
```
(pion 1080×2400, poziom 2400×1080, `menu_pressed_jobs.png`, `menu_hits*.json`, `compare_with_locks.jpg`).
Uwagi właściciela do proofu: dramatyczne światło jak w zamkach, tablica ok. 75 % szerokości, mniej równe litery,
większe zawieszki, przetarcia ściany. Najpierw porównaj sam z `art/renders/wafer.png` i `lever.png`
(`compare_with_locks.jpg`); jeśli menu wygląda taniej, popraw parametry światła (`--bulb`, `--window`, `--bounce`)
i dopiero wtedy pokaż. Integracja w Godot to praca sesji A.

### (f) Poprawki renderów zamków
- `lever` (patyna): zrobione w 2a705a6, nie ruszaj.
- `ring_combo` (litera „E” → cyfry): skrypt poprawiony (1955d59, d1eeb4d), **render nie został powtórzony**:
  ```bash
  "$BL" -b -P art/blender/ring_combo.py -- --out art/renders/ring_combo.png --res 1620x2160 --samples 128
  ```
  Sprawdź w powiększeniu, że każda cyfra jest cała i nieodbita.

### (g) APK na telefon właściciela, zrzuty i logcat
1. **Najprościej (zalecane):** APK z CI dla najnowszego zielonego `game-android` na `main`:
   ```bash
   gh run list -R woogitsugames/lockwright --workflow game-android --branch main --status success -L 1
   gh run download <RUN_ID> -R woogitsugames/lockwright -n lockwright-android-debug -D build/apk
   adb devices
   adb install -r build/apk/*.apk
   ```
2. **Lokalny build** (gdy trzeba sprawdzić coś przed CI): kroki 1:1 z `.github/workflows/game-android.yml`
   (AAR haptyki i click-audio przez Gradle, `lockcore_gd` dla arm64 przez scons + NDK 28.1, szablon Androida,
   klucz debug z `platform/android/debug.keystore`), potem
   `Godot_v4.7.2-stable_win64.exe --headless --path game --export-debug "Android" build/lockwright-debug.apk`.
   Pakiet: `com.woogitsugames.lockwright`.
3. Test i dowody:
   ```bash
   adb logcat -c && adb shell monkey -p com.woogitsugames.lockwright 1
   adb exec-out screencap -p > docs/handoff/device-tests/<run>/<ekran>.png
   adb shell screenrecord --time-limit 60 /sdcard/lw.mp4 && adb pull /sdcard/lw.mp4 build/
   adb logcat -d -s godot:* AndroidRuntime:* > docs/handoff/device-tests/<run>/logcat.txt
   ffmpeg -i build/lw.mp4 -vf "fps=2,scale=360:-1,tile=6x4" docs/handoff/device-tests/<run>/contact.png
   ```
   Lista do sprawdzenia: wstecz, wibracje („Impuls próbny”), wybór sterowania, samouczek S1–S3 (oba tryby),
   wskazówki H0–H4 i widmo kciuka, lupa, klapka pauzy, wszystkie rodziny planu B z listy zleceń (piny, warded,
   wafer, lever, dial_safe, combo, magnetic, dimple, disc_detainer), przyjazd z głosami PL/EN, rachunek, poziom.
   Każdy problem zapisz jako **N-xx** (następny wolny numer: sprawdź ostatni w `SESSION-B-LOG.md`) w sekcji
   „## Od sesji lokalnej: …” w `docs/handoff/SESSION-B-LOG.md`, ze zrzutami i fragmentem logcat.

## 2. Zasady repo
- Praca na `main`, małe commity, push od razu:
  `git -c rebase.autoStash=true pull --rebase origin main && git push origin main` (przy wyścigu ponów).
- Commity spoza `game/` (rendery w `art/`, logi, docs) z `[skip ci]`. Commit w `game/**` startuje `game-android`
  i przerywa trwający build (`cancel-in-progress`), więc pliki gry wypychaj **paczką** (np. wszystkie płyty 2× naraz).
- Heredoc w bashu tylko `<<'EOF'`. Na końcu commita linie atrybucji, których wymaga Twoja sesja.
- Każdy nowy lub podmieniony obraz gry: stratny `.import` + `git add -f`. Każdy zasób wpisany do `docs/ASSETS.md`
  (render własny: skrypt, flagi, spp, data; AI: narzędzie i prompt, D-42).
- Duże pliki robocze (pełne sekwencje 1080×1920 PNG, EXR) nie idą do repo, jeśli nie są potrzebne grze: w repo
  zostaje arkusz kontrolny, stop-klatki i to, co gra czyta.
- Bez marek, bez renderów marketingowych, zakazana lista wizualna z `CLAUDE.md` obowiązuje.

## 3. Raportowanie
- Log pracy: `docs/handoff/LOCAL-SESSION-LOG.md` (utwórz): co wyrenderowane, czasy na RTX 5070, pliki, otwarte sprawy.
- Do sesji A: wpis „## Od sesji lokalnej: …” w `SESSION-B-LOG.md` (tam czyta godzinna kontrola sesji A).
- Właścicielowi po polsku, krótko: co gotowe, zestawienie obrazów, co czeka na niego (np. akceptacja menu, Magnific D).

## Dodatek (sesja A, 2026-11-06 05:00 UTC): po poprawkach renderów zamków
- `warded.png`: kontrast zastawek do skrzynki ok. 1,7:1 (cel ≥ 3:1). Na GPU wyrenderuj ponownie z mocniejszym światłem kluczowym na zastawkach albo ekspozycją ok. +0,8 (`art/blender/warded.py`), sprawdź kontrast w skali szarości.
- Płyty planu B `lever` i `warded` (`game/assets/photoreal_families/{lever,warded}/photo/*`) są jeszcze ze starymi materiałami — w zadaniu (a)/(c) renderuj je od nowa (skrypty płyt same biorą nowe materiały z `lever.py`/`warded.py`).
- `ring_combo.png` jest już poprawiony (cyfry 0–9 wycięte w płaskach, bez „E”); ponowny render tylko przy 2×.
- **Nowe rodziny D-59 (szkice CPU 618×824, 16 spp):** finalnie `--res 1236x1648 --spp 256 --device GPU`: `art/blender/plates/egyptian_plate.py`, `time_lock_plate.py`, `axial_slider_plate.py` (wspólny `layer_plate_common.py`), `combo_plate.py` (też `--family disc_detainer`), `dial_safe_plate.py`, `tool_layers.py --ppmm 48` (sonda magnetyczna, flaga). Wyniki do `game/assets/photoreal_families/<rodzina>/photo/` (stratny `.import`, `git add -f`).

## Dodatek (sesja A, 2026-11-06): menu v2 — finalny render wszystkich stanów i języków (D-62, zastępuje polecenie z (e))
Proof v2 jest zaakceptowany; w repo są szkice CPU (48 spp) stanów „wciśnięty” i wersji EN/DE, a menu w Godot już ich używa.
Jedno polecenie renderuje wszystko na GPU i od razu eksportuje pliki gry:
```bash
python art/blender/menu_compose.py --render-all --blender "$BL" --samples 256 --device OPTIX
```
- Robi: 3 języki (PL, EN, DE; napisy z `game/i18n/strings.csv`, `menu.*`) × pion 1080×2400 i poziom 2400×1080 = 6 pełnych
  renderów + 36 wycinków „wciśnięty” (`--pressed i --crop-row i`), `menu_hits*.json`, arkusze `menu_langs.jpg`,
  `menu_pressed_all.jpg`, a na końcu eksport do `game/assets/ui/menu/` (WebP + `menu_layout.json`; wycinki wtapiane w tło
  na marginesie 20 px). Opcje: `--sprite-samples N`, `--langs pl,en`, `--orients portrait`, `--render-missing`, `--no-game`.
- `--device`: `OPTIX` (RTX 5070); awaryjnie `CUDA`. Nie zmieniaj sceny ani ziaren: strefy dotyku (`hit_rect`) muszą
  zostać identyczne; skrypt przerywa eksport, jeśli w którymś języku się różnią.
- Po renderze: `git add -f game/assets/ui/menu/*.webp game/assets/ui/menu/*.import art/renders/menu/*`, potem
  `godot --headless --path game --import` i GUT (`tests/gut/test_main_menu_v2.gd`). Obejrzyj `menu_pressed_all.jpg`
  (górny pasek = tło, dolny = wciśnięty: litery wychylone, bez widocznego prostokąta wycinka) i `menu_langs.jpg`.
