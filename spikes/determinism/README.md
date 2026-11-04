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
