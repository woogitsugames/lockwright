# Raport realizacji zadania GEM2 — Fotorealistyczne ekrany 4 rodzin zamków w Godot 4.7.2 (`wafer`, `lever` / `lever_detector`, `warded`, `wooden_pin`)

## 1. Podsumowanie wykonanych prac

Zbudowano kompletny potok wypieku (Blender 5.2.1 LTS + Cycles GPU OPTIX) oraz grywalne, fotorealistyczne ekrany w Godot 4.7.2 (Plan B, decyzje **D-31** i **D-37**) dla pozostałych czterech rodzin zamków:

1. **`wafer`** — jednorzędowy zamek płytkowy (5 płytek z oknem w mosiężnym bębenku, stalowa sprężyna powrotna na płytkę, przekrój w drzwiczkach skrzynki pocztowej).
2. **`lever` (oraz wariant `lever_detector`)** — 3-zasuwkowy zamek wpuszczany w mosiężnej kasecie z ryglem o słupku (`stump`), sprężynami piórowymi, współosiowym napinaczem z drutem wytrycha oraz zapadką detektora Chubba (`detector_pawl` + `detector_spring`), która zatrzaskuje rygiel po nadmiernym uniesieniu zasuwki (`overset` → `jammed`).
3. **`warded`** — kuty żelazny zamek skrzyniowy z koncentrycznymi zastawkami (`wards`), sprężynującym ryglem zapadkowym (`tumbler` + `tspring`) i obracanym kluczem szkieletowym (`bit` + `stem`).
4. **`wooden_pin`** — drewniany zamek kołkowy z dębu i jesionu z 3 grawitacyjnymi kołkami o karbowanych trzonkach i przewężeniach `false_set` oraz jesionową łopatką („szczoteczką”, `lifter`) wsuwaną w kanał rygla.

### Zastosowane poprawki jakościowe z `contrib/gpt/T06`:
- **P0 — Prawdziwa czerń OLED `#000000` w trybie „po ciemku” (`--lw-dark 1` / `set_dark(true)`)**: sekcja 3D (`_section.visible = false`), ekspozycja shaderów (`exposure = 0.0`) oraz tekstura skórzanej zwijki są całkowicie wygaszane do `#000000`; rysowany jest wyłącznie subtelny relief zakładki pauzy (kontrast ~3:1) i opcjonalne wgłębienia dotyku (~1,5:1).
- **Mniej lustrzany metal i bogatsza mikrostruktura**: w `art/blender/plates/plate_common.py` podniesiono minimalną chropowatość metalu (`roughness >= 0.24`), wzmocniono anizotropowe rysy obróbcze na płaszczyznach przekroju i dodano wypiek tekstur albedo obok map `normal` i `orm`.
- **Czytelna szczelina ścinania (`>= 2 dp`) i dynamiczna okluzja**: w `family_occlusion.gdshaderinc` oraz `family_plate.gdshader` / `family_plate_rest.gdshader` wyciemniono linię ścinania oraz dynamiczny cień ruchomych elementów na statycznej płycie Cycles.
- **Rozróżnialność wszystkich 6 stanów bez udziału koloru (skala szarości i 50% jasności)**: każdy stan (`free`, `bound`, `set`, `false_set`, `overset`, `detector`) różni się jednoznacznie położeniem, kątem nachylenia/obrotu, ściśnięciem sprężyn oraz ugięciem narzędzia.

---

## 2. Środowisko sprzętowe i programowe

| Element | Specyfikacja |
|---|---|
| **CPU** | Intel(R) Core(TM) Ultra 7 270K Plus (24 wątki logiczne) |
| **GPU** | NVIDIA GeForce RTX 5070 (sterownik Vulkan 1.4.341 / OptiX) |
| **System operacyjny** | Windows 11 Pro x86_64 (10.0.26200) |
| **Blender** | Blender 5.2.1 LTS (`C:\Program Files\Blender Foundation\Blender 5.2\blender.exe`), backend `OPTIX` |
| **Godot** | Godot Engine v4.7.2.stable.official (`ed1daf0bf`), renderer `Forward Mobile` (Vulkan) |
| **Urządzenie Android (`adb`)** | Brak podłączonego telefonu (`adb devices -l` zwróciło pustą listę) — pomiary wykonano na PC |

---

## 3. Czasy renderowania i wypieku w Blenderze 5.2.1 LTS (GPU OPTIX)

Wszystkie zasoby wygenerowano z pojedynczej stałej kamery na rodzinę (płyta statyczna `1236×1650` przy 256 spp + OIDN, kule matcap `512×512` przy 128 spp, wypiek tekstur `1024×1024` `normal` + `orm` + `albedo`, eksport `<rodzina>_baked.glb` oraz `scene.json`):

| Rodzina | Płyta `1236×1650` (s) | Matcapy `512×512` (s) | Wypiek tekstur `1024×1024` (s) | Eksport GLB (s) | Łączny czas (s) | Rozmiar `.glb` |
|---|---:|---:|---:|---:|---:|---:|
| **`wafer`** | 9,24 s | 4,06 s | 27,78 s | 0,88 s | **43,91 s** | 4,78 MB |
| **`lever`** | 27,59 s | 11,34 s | 58,19 s | 0,09 s | **99,17 s** | 0,41 MB |
| **`warded`** | 14,12 s | 6,45 s | 34,22 s | 0,10 s | **56,40 s** | 0,46 MB |
| **`wooden_pin`** | 14,07 s | 6,49 s | 33,01 s | 0,08 s | **55,45 s** | 0,36 MB |
| **Razem** | **65,02 s** | **28,34 s** | **153,20 s** | **1,15 s** | **254,93 s (~4 min 15 s)** | **6,01 MB** |

---

## 4. Pomiary czasu klatki (`LW_PERF`) w Godot 4.7.2 na PC

Pomiar wykonano w rozdzielczości okna `824×1830` (`SubViewport` sekcji 3D: `824×1100`, MSAA 2×, Vulkan 1.4.341 Forward Mobile na `NVIDIA GeForce RTX 5070`) za pomocą parametru `--lw-bench`:

### 4.1. Pomiar bez limitu V-Sync (`--disable-vsync --lw-bench 2`)
| Scena | `frame_p95` (ms) | Czas GPU (ms) | Draw calls (`draws`) | Prymitywy (`prims`) | VRAM (MB) | Rozmiar `SubViewport` |
|---|---:|---:|---:|---:|---:|---|
| `lock_photoreal_wafer.tscn` | **4,85 ms** | **0,023 ms** | 35 | 85 449 | 123,6 MB | `824×1100` |
| `lock_photoreal_lever.tscn` | **4,68 ms** | **0,028 ms** | 44 | 26 548 | 134,4 MB | `824×1100` |
| `lock_photoreal_warded.tscn` | **4,41 ms** | **0,028 ms** | 47 | 18 552 | 133,9 MB | `824×1100` |
| `lock_photoreal_wooden_pin.tscn` | **4,10 ms** | **0,023 ms** | 31 | 12 838 | 120,7 MB | `824×1100` |

### 4.2. Pomiar z domyślnym V-Sync monitora 60 Hz (`--lw-bench 5`)
| Scena | `frame_p95` (ms, V-Sync 60 Hz) | Czas GPU (ms) | Draw calls (`draws`) | Prymitywy (`prims`) | VRAM (MB) |
|---|---:|---:|---:|---:|---:|
| `lock_photoreal_wafer.tscn` | 17,63 ms | 0,037 ms | 35 | 85 449 | 123,6 MB |
| `lock_photoreal_lever.tscn` | 19,65 ms | 0,037 ms | 44 | 26 548 | 134,4 MB |
| `lock_photoreal_warded.tscn` | 18,08 ms | 0,028 ms | 47 | 18 552 | 133,9 MB |
| `lock_photoreal_wooden_pin.tscn` | 17,74 ms | 0,028 ms | 31 | 12 838 | 120,7 MB |

Wszystkie cztery sceny mieszczą się z dużym zapasem w budżecie **120 Hz (< 8,33 ms)** oraz w budżecie liczby wywołań rysowania (`31–47 draws`) i prymitywów (`12,8 tys. – 85,4 tys.`).

---

## 5. Wyniki testów GUT (`test_photoreal_families.gd`)

Polecenie uruchomienia:
```powershell
Godot_v4.7.2-stable_win64_console.exe --headless --path game -s addons/gut/gut_cmdln.gd -gtest=res://scenes/photoreal_families/test_photoreal_families.gd -gexit
```

Wynik:
- **Skrypty**: `1`
- **Testy**: **`25 / 25 passed`**
- **Asercje**: **`66`**
- **Czas wykonania**: **`1,447 s`**

Pokryte obszary testowe:
- Jednostkowe testy geometrii i stanów `WaferPose`, `LeverPose` (w tym `lever_detector`), `WardedPose` oraz `WoodenPinPose` (`free`, `bound`, `set`, `false_set`, `overset`, `jammed`/`detector`).
- Testy jednoznacznej rozróżnialności wszystkich stanów po samej geometrii (bez koloru).
- Testy integracyjne wszystkich 4 scen (`.tscn`) uruchamianych w trybie headless z pętlą fizyki 120 Hz i sesją `FamilyLockSession` / `LockcoreSession`.
- Test weryfikujący poprawkę P0 trybu nocnego (`set_dark(true)` wygasza widoczność sekcji 3D i ustawia ekspozycję shaderów na `0.0`).

---

## 6. Wykaz utworzonych plików

### 6.1. Skrypty wypieku i renderu w Blenderze (`art/blender/plates/`)
- `art/blender/plates/plate_common.py` — wspólny potok GPU OPTIX: ulepszenia materiałowe T06, render płyty bez części ruchomych (`hide_render`), render kul matcap, wypiek `normal`/`orm`/`albedo` (`Smart UV Project`), eksport `<family>_baked.glb` oraz zapis `scene.json`.
- `art/blender/plates/wafer_plate.py` — konfiguracja i uruchomienie wypieku rodziny `wafer`.
- `art/blender/plates/lever_plate.py` — konfiguracja i uruchomienie wypieku rodziny `lever` (wraz z elementami `detector_pawl` i `detector_spring`).
- `art/blender/plates/warded_plate.py` — konfiguracja i uruchomienie wypieku rodziny `warded`.
- `art/blender/plates/wooden_pin_plate.py` — konfiguracja i uruchomienie wypieku rodziny `wooden_pin`.
- `art/blender/plates/render_all_plates.py` — skrypt wsadowy uruchamiający wszystkie 4 rodziny po kolei.

### 6.2. Zasoby 3D, wypieki, matcapy i płyty (`game/assets/photoreal_families/`)
- `game/assets/photoreal_families/wafer/`: `wafer_baked.glb`, `scene.json`, `plate/plate_1236x1650.png`, `matcap/matcap_{wafer_brass,spring_steel,pick_steel,handle_steel}.png`, `tex/{wafer_brass,spring_steel,pick_steel,handle_steel}_{normal,orm,albedo}.png`.
- `game/assets/photoreal_families/lever/`: `lever_baked.glb`, `scene.json`, `plate/plate_1236x1650.png`, `matcap/matcap_{lever_brass,steel,spring_steel,blued_steel,pick_steel,iron}.png`, `tex/*_{normal,orm,albedo}.png`.
- `game/assets/photoreal_families/warded/`: `warded_baked.glb`, `scene.json`, `plate/plate_1236x1650.png`, `matcap/matcap_{wrought_iron,spring_steel,key_steel}.png`, `tex/*_{normal,orm,albedo}.png`.
- `game/assets/photoreal_families/wooden_pin/`: `wooden_pin_baked.glb`, `scene.json`, `plate/plate_1236x1650.png`, `matcap/matcap_{pin_wood,lifter_wood,brass_peg}.png`, `tex/*_{normal,orm,albedo}.png`.

### 6.3. Skrypty i shadery Godot 4.7.2 (`game/scripts/photoreal_families/`)
- `family_occlusion.gdshaderinc` — wspólna funkcja okluzji z wyciemnioną szczeliną ścinania (`>= 2 dp`) i miękkim cieniem ruchomych elementów.
- `family_plate.gdshader` — shader projekcji ekranowej statycznej płyty Cycles.
- `family_plate_rest.gdshader` — shader projekcji w spoczynkowym układzie współrzędnych (`rest_model`) dla obracanego bębenka/napinacza (`wafer`) oraz przesuwanego rygla (`lever`).
- `family_matcap.gdshader` — shader matcap + wypieczona mapa normalnych, ORM i domieszka albedo oraz ugięcie narzędzia (`bend`).
- `wafer_pose.gd` (`WaferPose`), `lever_pose.gd` (`LeverPose`), `warded_pose.gd` (`WardedPose`), `wooden_pin_pose.gd` (`WoodenPinPose`) — czysto geometryczne kalkulatory póz dla wszystkich stanów.
- `family_lock_session.gd` (`FamilyLockSession`) — adapter sesji zamka używający natywnego `LockcoreSession` (GDExtension), a w razie braku biblioteki dla danej platformy zapewniający wierny fallback GDScript dla wszystkich 5 rodzin (`wafer`, `lever`, `lever_detector`, `warded`, `wooden_pin`).
- `lock_photoreal_family_view.gd` (`LockPhotorealFamilyView`) — główny widok kompatybilny z `LockPhotorealView` (`present`, `on_event`, `set_lives`, `set_dark`, `touch`, `pause_requested`).
- `lock_photoreal_family.gd` (`LockPhotorealFamily`) — kontroler sceny obsługujący pętlę 120 Hz (`InputSampler`, `Haptics`, `Sfx`, `Events`) oraz flagi CLI (`--lw-family`, `--lw-pose`, `--lw-size`, `--lw-shot`, `--lw-dark`, `--lw-bench` itd.).
- `capture_all_shots.gd` oraz `shot_variants.gd` — generatory zrzutów ekranu (`824×1830` i `1830×824`) oraz wariantów `.gray.png` i `.dim.png`.

### 6.4. Sceny, testy i zrzuty kontrolne (`game/scenes/photoreal_families/`)
- `lock_photoreal_wafer.tscn`
- `lock_photoreal_lever.tscn`
- `lock_photoreal_warded.tscn`
- `lock_photoreal_wooden_pin.tscn`
- `test_photoreal_families.gd`
- `shots/*.png` — **168 plików** (`4 rodziny × 7 stanów [free, bound, set, false_set, overset, detector, dark] × 2 orientacje [portrait 824×1830, landscape 1830×824] × 3 warianty [kolor, .gray.png, .dim.png]`).

---

## 7. Co się nie udało / ograniczenia środowiska

1. **Brak podłączonego telefonu z Androidem (`adb devices`)**: w środowisku nie było podłączonego fizycznego urządzenia Android, dlatego pomiary czasu klatki wykonano na PC (`NVIDIA GeForce RTX 5070`, Godot 4.7.2 Forward Mobile Vulkan).
2. **Brak skompilowanej biblioteki `lockcore_gd` dla `windows.x86_64`**: w repozytorium znajduje się konfiguracja `lockcore_gd.gdextension`, lecz bez binarnej biblioteki `.dll` dla Windows. Aby sceny i testy działały bezbłędnie zarówno na Windows, jak i na docelowym buildzie z GDExtension, `LockPhotorealFamily.make_session()` automatycznie wykrywa `ClassDB.class_exists("LockcoreSession")` i w razie braku natywnej klasy przełącza się na `FamilyLockSession` w GDScript.

---

## 8. Instrukcja integracji dla Sesji B

### 8.1. Podpięcie scen fotorealistycznych w routerze ekranu zamka
Wszystkie 4 nowe sceny przyjmują dokładnie ten sam interfejs co `res://scenes/photoreal/lock_photoreal.tscn` (`family`, `seed`, `tier` oraz sygnały `Events.lock_event`, `Events.lock_opened`, `Events.lock_failed`). W miejscu wyboru sceny zamka według rodziny (`family_id`) wystarczy zmapować:

```gdscript
const PHOTOREAL_SCENES := {
	&"pin_tumbler": "res://scenes/photoreal/lock_photoreal.tscn",
	&"wafer": "res://scenes/photoreal_families/lock_photoreal_wafer.tscn",
	&"lever": "res://scenes/photoreal_families/lock_photoreal_lever.tscn",
	&"lever_detector": "res://scenes/photoreal_families/lock_photoreal_lever.tscn",
	&"warded": "res://scenes/photoreal_families/lock_photoreal_warded.tscn",
	&"wooden_pin": "res://scenes/photoreal_families/lock_photoreal_wooden_pin.tscn",
}
```

Dla wariantu `lever_detector` wystarczy ustawić `scene.family = &"lever_detector"` przed dodaniem węzła do drzewa (lub przekazać `--lw-family lever_detector` z CLI) — widok automatycznie aktywuje zapadkę detektora Chubba (`view.detector_enabled = true`).

### 8.2. Dodanie testów GUT do głównego uruchomienia CI
Plik testowy został umieszczony zgodnie z zakresem zadania w `res://scenes/photoreal_families/test_photoreal_families.gd`. Aby włączyć go do głównego katalogu testów GUT:
1. Przenieś lub zaimportuj `res://scenes/photoreal_families/test_photoreal_families.gd` do `res://tests/gut/test_photoreal_families.gd` **lub**
2. Dodaj katalog `res://scenes/photoreal_families` jako drugi katalog `dirs` w `.gutconfig.json` / wywołaniu `-gdir=res://tests/gut,res://scenes/photoreal_families`.
