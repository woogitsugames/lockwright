# Spike 5 — determinizm lockcore (x86_64 ↔ arm64)

Buduje `lockcore/` z zewnątrz (katalog tylko do odczytu) i sprawdza, że te same wejścia dają bit w bit te same zdarzenia na każdej platformie. Wyniki: [RESULTS.md](RESULTS.md).

```bash
# x86_64 (referencja) + korpus 10 000 powtórek
cmake -S spikes/determinism -B spikes/determinism/build/x86_64-gcc -G Ninja
cmake --build spikes/determinism/build/x86_64-gcc
spikes/determinism/build/x86_64-gcc/replay_fuzz gen --count 10000 --out /tmp/corpus.lwfz

# Linux aarch64 (apt: g++-aarch64-linux-gnu qemu-user-static)
cmake -S spikes/determinism -B spikes/determinism/build/linux-aarch64-gcc -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE=$PWD/spikes/determinism/cmake/aarch64-linux-gnu.cmake -DDET_STATIC=ON
cmake --build spikes/determinism/build/linux-aarch64-gcc

# Android arm64 (NDK 29.0.14206865), statycznie: działa w qemu-user i przez adb shell
cmake -S spikes/determinism -B spikes/determinism/build/android-arm64-clang -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE=$ANDROID_HOME/ndk/29.0.14206865/build/cmake/android.toolchain.cmake \
  -DANDROID_ABI=arm64-v8a -DANDROID_PLATFORM=android-30 -DDET_STATIC=ON \
  -DCMAKE_CROSSCOMPILING_EMULATOR=qemu-aarch64-static
cmake --build spikes/determinism/build/android-arm64-clang

# wszystkie testy jednej platformy -> results/<nazwa>.txt, potem tabela
spikes/determinism/tools/run_platform.sh linux-aarch64-gcc spikes/determinism/build/linux-aarch64-gcc /tmp/corpus.lwfz qemu-aarch64-static
python3 spikes/determinism/tools/summarize.py spikes/determinism/results
```

`replay_fuzz`:
- `gen --count N [--seed S] --out F` — nagrywa korpus (bot, bot niezdarny, losowa ręka), zapisuje hash zdarzeń i hash stanu co 60 kroków;
- `check F [--report R]` — odtwarza, porównuje, wypisuje pierwszy rozjazd (krok) dla każdej niezgodności;
- `bench [--steps N]` — koszt `step()` p50/p99/p99.9.

Na telefonie (bez roota): `adb push build/android-arm64-clang/replay_fuzz /tmp/corpus.lwfz /data/local/tmp/` i `adb shell /data/local/tmp/replay_fuzz check /data/local/tmp/corpus.lwfz` oraz `... bench`.

## Determinizm w buildzie gry (etap 3, zadanie 10)

`godot/` to minimalny projekt Godota z samym `lockcore_gd` (kopiowanym z `game/addons/` przez `tools/godot_det.sh`).
Host (Linux x86_64) nagrywa korpus 630 powtórek — 7 rodzin × tier 1–3 × 10 seedów × trzy ręce (solver, niezdarna z
deterministycznym szumem całkowitym, przerwana po 60%) — z wejściami w jednostkach 1/256 i RLE, razem z oczekiwanymi
hashami zdarzeń. APK arm64 (eksport bez Gradle, ta sama biblioteka co w grze) odtwarza korpus i drukuje
`LW_DET_DONE … digest=<sha256 wszystkich hashy>`; CI porównuje digest z hostem.

```bash
spikes/determinism/tools/godot_det.sh prepare godot /tmp/det 10   # korpus + samosprawdzenie hosta
spikes/determinism/tools/godot_det.sh apk godot /tmp/det          # APK (wymaga liblockcore_gd.android.template_debug.so)
spikes/determinism/tools/godot_det.sh device /tmp/det/build/lw-determinism.apk /tmp/det/host_result.txt   # adb
```

CI: `spike-determinism-apk.yml` — emulator Androida (obrazy x86_64 API 30 i 34 z translacją ARM, KVM). To uruchamia
kod arm64 lockcore_gd w prawdziwym runtime Godota na Androidzie, ale przez tłumacza instrukcji; natywny arm64 nadal
sprawdzają `spike-determinism` (qemu, macOS arm64) i telefon właściciela (to samo APK, wynik na ekranie).
Uwaga dla sesji B: godot-cpp (master) domyślnie szuka NDK 28.1 — przy NDK 29 trzeba podać `ndk_version=29.0.14206865`
do scons (inaczej „Could not find NDK toolchain”).
