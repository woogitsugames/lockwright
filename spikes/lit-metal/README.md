# Spike 4 — fotorealistyczny metal w Godot 4.7 (renderer Mobile)

Cel: sprawdzić, czy wygląd renderów Cycles (`art/renders/section*.png`) da się osiągnąć w czasie rzeczywistym na rendererze **Mobile** przy 60 FPS na tanim Androidzie. Kryteria: `docs/TECH.md` §4 (spike 4). Wyniki i porównania: [RESULTS.md](RESULTS.md).

## Potok

1. **Scena** pochodzi bez zmian z `art/blender/cutaway.py` (katalog `art/` jest tylko do odczytu). Skrypty w `tools/` wykonują go z wyłączonym ostatnim `render()`.
2. **Wypiek** (`tools/bake.py`, Blender 4.2 LTS, Cycles CPU): krzywe sprężyn → siatki, modyfikatory zastosowane, n-gony → trójkąty; atlas UV na materiał (Smart UV Project wszystkich obiektów materiału naraz + pakowanie); wypiekane mapy: **albedo** (DIFFUSE/COLOR przy metallic = 0, z „brudem” z węzła AO materiału), **roughness**, **normal** (tangent, OpenGL +Y, z frezowania i szlifu w węzłach bump), **AO** (16 próbek). Pakowane do `*_orm.png` (R = AO, G = roughness, B = metallic). Rozdzielczości: 2K mosiądz/nikiel/drewno, 1K stal/kołki/sprężyny/wytrych/żelazo, 512 px reszta. Wyjście: `assets/cutaway_baked.glb` (nazwy węzłów i materiałów zachowane), `assets/tex/`, `assets/scene.json` (kamera, światła, ekspozycja), `assets/interior.hdr` (to samo HDRI, którego używa Cycles).
   ```bash
   blender -b -P spikes/lit-metal/tools/bake.py -- --size 2048 --ao-samples 16      # ~15 min na 4 rdzeniach
   blender -b -P art/blender/cutaway.py -- --glb spikes/lit-metal/assets/cutaway.glb --res 64x64 --samples 1   # surowy eksport glTF
   ```
3. **Referencje i plan B** (`tools/render_refs.py`): `--what reference` (Cycles, cały przekrój), `--what plate` (Cycles bez ruchomych części, do planu B), `--what matcap` (kule z materiałami ruchomych części w tym samym świetle).
4. **Godot** (`project.godot`, renderer Mobile, `scripts/main.gd` buduje scenę w kodzie):
   - **Wariant A „realtime”**: `ORMMaterial3D` z wypieczonych map; światła obszarowe Blendera → `OmniLight3D` w tych samych pozycjach i kolorach (spadek 1/d², cień miękki tylko z klucza); odbicia świateł obszarowych na płaskim metalu → emisyjne prostokąty widoczne tylko dla `ReflectionProbe` (warstwa 2); niebo = to samo HDRI z tą samą siłą; tonemapping **AgX** i ekspozycja z Blendera; **bez glow i bloomu**; kamera: ogniskowa 180 mm, przetwornik 36 mm (stały FOV poziomy), yaw −22°, pitch 10°.
   - **Wariant B „baked” (plan B)**: statyczne siatki rysują piksel z renderu Cycles rzutowany przez kamerę (`shaders/plate.gdshader`, unshaded, prawdziwa głębia), ruchome części (kołki, sprężyny, wytrych) mają matcap z Cycles + wypieczoną normal mapę i AO (`shaders/matcap.gdshader`). Zero świateł, zero sondy.
   - Animacja: kołki góra–dół 1 Hz (sprężyny ściskają się), wytrych podąża za kołkiem C.
5. **Zrzuty**: `--shot plik.png --size WxH` renderuje poza ekranem (SubViewport) i kończy; `tools/compare.py` składa porównanie z Cyclesem (lewa połowa Cycles, prawa Godot) i liczy MAE / PSNR / SSIM.
   ```bash
   Xvfb :99 -screen 0 2400x3000x24 & export DISPLAY=:99          # bez GPU: Mesa lavapipe (Vulkan na CPU)
   godot --path spikes/lit-metal --rendering-method mobile -- --shot /tmp/a.png --size 1236x1650 --frames 20
   godot --path spikes/lit-metal --rendering-method mobile -- --shot /tmp/b.png --size 1236x1650 --variant b
   python3 spikes/lit-metal/tools/compare.py spikes/lit-metal/screens/cycles_1236x1650.png /tmp/a.png /tmp/cmp
   ```

## Pomiar FPS na telefonie

APK: GitHub → Actions → **spike-lit-metal** → artefakt `spike-lit-metal-debug-apk` → `adb install -r spike-lit-metal-debug.apk` (albo otwórz plik na telefonie).

Na ekranie (nakładka diagnostyczna spike'u, nie UI gry): wariant, FPS, czas klatki p50/p95, **czas GPU** p50/p95 (`RenderingServer.viewport_get_measured_render_time_gpu`), liczba draw calli i prymitywów. Sterowanie:
- dotknięcie **prawego górnego rogu** — przełącza wariant A ⇄ B,
- dotknięcie **dolnego pasa** ekranu — włącza/wyłącza animację.

Co 10 s aplikacja wypisuje wiersz do logu:
```bash
adb logcat -s godot | grep LW_PERF
# LW_PERF variant=a fps=60 frame_p50=16.67 frame_p95=16.80 frame_p99=17.10 gpu_p50=… gpu_p95=… draws=… prims=… vram_mb=…
```

Procedura (TECH §4): jasność 50%, tryb samolotowy, bateria > 50%, telefon nie na ładowarce; po 1 min rozgrzewki zbierz 10 min dla wariantu A i 10 min dla B (każdy z animacją). Notuj co minutę wiersz `LW_PERF`, temperaturę (`adb shell dumpsys battery | grep temp`) i zużycie baterii (`adb shell dumpsys batterystats --reset` przed, `adb shell dumpsys batterystats | grep "Computed drain"` po). Pamięć: `adb shell dumpsys meminfo com.woogitsugames.lockwright.spike.litmetal | grep TOTAL`. Czas startu: `adb shell am start -W -n com.woogitsugames.lockwright.spike.litmetal/com.godot.game.GodotApp`.

Dodatkowo bez instalacji narzędzi: Opcje programisty → „Profilowanie renderowania HWUI” (słupki) albo Android GPU Inspector / Perfetto dla czasu GPU.

## Kryteria (TECH §4, spike 4)

- **Przeszło (tani Android, Mali-G52/G57 lub PowerVR):** 10 min, czas klatki p95 ≤ 16,7 ms, 1% low ≥ 55 FPS, bez spadku < 55 FPS po 10 min (throttling), RAM ≤ 450 MB, bateria ≤ 15%/h, start ≤ 4 s, AAB ≤ 60 MB; iPhone SE 3 i iPad stałe 60 FPS; ProMotion 120 FPS p95 ≤ 8,3 ms (opcjonalnie).
- **Nie przeszło:** p95 > 20 ms w obu rendererach w wariancie minimalnym.

W tym kontenerze nie ma GPU (Mesa lavapipe na CPU), więc **FPS z kontenera nie jest miarą wydajności telefonu** — liczby z telefonu wpisuje właściciel do `RESULTS.md`.
