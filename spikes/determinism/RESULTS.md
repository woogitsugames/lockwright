# Spike 5 — determinizm lockcore na ARM: wyniki

Stan: 2026-11-04, lockcore v0.1 (`pin_tumbler` i `wafer`, rules_version z repo), commit bazowy `46f180f`.
Kryterium z `docs/TECH.md` §4 (spike 5): **100% zgodności skrótów**, zero rozbieżności.

## Wynik: PRZESZŁO (lokalnie, 4 buildy). CI: macOS arm64 natywnie — patrz niżej.

### Co porównujemy
1. `ctest` lockcore (testy jednostkowe, złote powtórki, brak float, smoke 200 seedów) — na arm64 przez qemu-user.
2. Hash FNV-1a 64 strumienia zdarzeń dla każdej złotej powtórki z `lockcore/tests/golden/`.
3. SHA-256 (16 znaków) pliku CSV z `verify_seeds --seeds 1000` (generator + wyrocznia + bot skryptowy + bot niezdarny, 9 tierów × 1000 seedów).
4. `replay_fuzz`: **10 000 powtórek nagranych na x86_64 gcc** i odtworzonych na celu. Dla każdej sprawdzamy hash zdarzeń i hash stanu (view model) co 60 kroków oraz hash końcowy, liczbę kroków i wynik.

### Tabela (lokalnie, Linux x86_64 host; arm64 przez `qemu-aarch64-static` 8.2)

| Build | Platform / compiler | ctest | pin_tumbler_t2_s1001 | pin_tumbler_t2_s1001_break | pin_tumbler_t5_s1_clumsy | pin_tumbler_t7_s4242 | wafer_t2_s77 | verify_seeds_csv_sha256 | replay_fuzz 10 000 |
|---|---|---|---|---|---|---|---|---|---|
| x86_64-gcc | linux-x86_64, gcc 13.3.0 | pass | `9f4bea9c61f463e5` | `8f0b2bff4f6ac777` | `4fb93155363bfa42` | `6179e59ebde7514b` | `b66a74e51e817656` | `c9e38026f430bbc7` | 10000 match, 0 MISMATCH, 0 skipped (rules_version) |
| android-arm64-clang | android-arm64, clang 21.0.0 | pass | `9f4bea9c61f463e5` | `8f0b2bff4f6ac777` | `4fb93155363bfa42` | `6179e59ebde7514b` | `b66a74e51e817656` | `c9e38026f430bbc7` | 10000 match, 0 MISMATCH, 0 skipped (rules_version) |
| linux-aarch64-gcc | linux-arm64, gcc 13.3.0 | pass | `9f4bea9c61f463e5` | `8f0b2bff4f6ac777` | `4fb93155363bfa42` | `6179e59ebde7514b` | `b66a74e51e817656` | `c9e38026f430bbc7` | 10000 match, 0 MISMATCH, 0 skipped (rules_version) |
| x86_64-clang | linux-x86_64, clang 18.1.3 | pass | `9f4bea9c61f463e5` | `8f0b2bff4f6ac777` | `4fb93155363bfa42` | `6179e59ebde7514b` | `b66a74e51e817656` | `c9e38026f430bbc7` | 10000 match, 0 MISMATCH, 0 skipped (rules_version) |

Kompilatory: gcc 13.3.0 (x86_64 i `aarch64-linux-gnu-g++`), clang 18.1.3, Android NDK 29.0.14206865 (clang 21, `arm64-v8a`, `android-30`, statycznie z bionic).
Wszystkie buildy Release, `-ffp-contract=off` (z `lockcore/CMakeLists.txt`).

### Korpus `replay_fuzz` (seed 20261104)
- 10 000 przypadków: 7 030 losowa „niezdarna ręka” (błądzenie losowe, drżenie, szarpnięcia, puszczanie napięcia), 1 463 bot skryptowy, 1 507 bot niezdarny; 30% powtórek botów ma losowo zaburzony ogon napięcia.
- 13 926 009 kroków symulacji (≈ 32 h gry przy 120 Hz), 2 648 otwarć, 111 złamań narzędzia.
- Pokryte zdarzenia: contact 172 080, bind 74 481, near_shear 17 535, set 22 143, false_set 18 398, counter_rotate 69 499, overset 5 702, drop 2 445, stress 720, break 111, wear 122, open 2 648. **Brak** `gate_align` i `detector_trip` (lockcore v0.1 nie ma jeszcze rodzin, które je emitują).
- Hash korpusu: `e2b1a23d5e25b9ff`. Rozmiar: 83 MB (21,5 MB gzip) — nie trzymamy w repo, CI generuje go od nowa.

### Koszt `step()` (`replay_fuzz bench`, najtrudniejszy tier, 100 000 kroków losowej ręki)
| Build | p50 | p99 | p99.9 |
|---|---|---|---|
| x86_64 gcc (natywnie) | 63 ns | 118 ns | 182 ns |
| x86_64 clang (natywnie) | 84 ns | 161 ns | 262 ns |
| Android arm64 (qemu, emulacja!) | 1,7 µs | 2,3 µs | 15 µs |
| Linux arm64 (qemu, emulacja!) | 5,9 µs | 12,4 µs | 34 µs |

Kryterium „`step()` ≤ 0,2 ms p99 na tanim Androidzie” ma zapas ponad 80× nawet w emulacji. Pomiar na urządzeniu: `replay_fuzz bench` przez `adb push` + `adb shell` (binarka statyczna, patrz README).

### Czego ten spike jeszcze nie pokrywa
- **Prawdziwe urządzenie Android arm64** i **iOS arm64**: qemu-user emuluje instrukcje AArch64 wiernie (arytmetyka całkowita), ale to nie jest dowód dla konkretnego SoC. Binarka statyczna NDK uruchamia się na telefonie bez roota: `adb push build/android-arm64-clang/replay_fuzz corpus.lwfz /data/local/tmp/` i `adb shell /data/local/tmp/replay_fuzz check /data/local/tmp/corpus.lwfz`.
- iOS: build macOS arm64 (Apple clang) w CI to ten sam kompilator i ISA co iOS; urządzenie dojdzie z GDExtension.
- Niezależność od FPS renderu (30/60/120 Hz): logika ma stały krok 1/120 s, a wejście w powtórce jest już per krok, więc FPS renderu nie wchodzi do hasha z definicji. Test na poziomie Godota (próbkowanie wejścia przy różnych FPS) należy do warstwy `game/` (InputSampler).
- Rozjazdów **nie znaleziono**, więc nie ma minimalnego przypadku do zgłoszenia.

## CI
`.github/workflows/spike-determinism.yml`: `record` (ubuntu, gcc, korpus 10 000) → `linux-check` (x86_64 clang, Linux aarch64 qemu, Android NDK qemu) + `macos-arm64` (natywnie, Apple clang) → `summary` (tabela w podsumowaniu runu i artefakt `determinism-table`).
