# lockcore

Deterministic lock-logic library for Lockwright (C++20, no engine dependency, no
third-party code). The Godot layer will reach it through GDExtension (D-04); the
library itself builds and tests natively on Linux, macOS, Android NDK and iOS.

Status: **v0.1** — core + two families (`pin_tumbler`, `wafer`), verifier, replays.

## Build and test

```bash
cmake -S lockcore -B lockcore/build -G Ninja          # Release by default; -G is optional
cmake --build lockcore/build
ctest --test-dir lockcore/build --output-on-failure   # unit tests, golden replays, no-float check, 200-seed smoke
lockcore/build/verify_seeds --seeds 1000              # fast verifier run (CI on every push)
lockcore/build/verify_seeds --seeds 10000 --csv out.csv   # full run (A3), ~25 s on 1 core
```

Other configurations:

```bash
cmake -S lockcore -B lockcore/build-clang -DCMAKE_CXX_COMPILER=clang++
cmake -S lockcore -B lockcore/build-asan -DCMAKE_BUILD_TYPE=Debug -DLOCKCORE_SANITIZE=ON
```

Tools:

```bash
lockcore/build/verify_seeds [--seeds N] [--family pin_tumbler] [--tier 5] [--replays N] [--csv FILE]
lockcore/build/replay_tool lock pin_tumbler 4 123             # print a generated lockwright.lock/1
lockcore/build/replay_tool record wafer 2 77 out.replay.json  # record the bot's run [--clumsy]
lockcore/build/replay_tool play lockcore/tests/golden/wafer_t2_s77.replay.json
```

Run a single test group: `lockcore/build/lockcore_tests pin:` (substring filter).

## Layout

| Path | Content |
|---|---|
| `include/lockcore/fixed.hpp` | Q16 in int32 (`65536 == 1.0`), int64 products, `SIM_HZ = 120`, 1/256 input quantisation |
| `include/lockcore/prng.hpp` | PCG32, own implementation; one stream per family and purpose (`gen`, `sim`, `bot`) |
| `include/lockcore/hash.hpp` | FNV-1a 64 (event stream), SplitMix64 seed derivation |
| `include/lockcore/input.hpp`, `events.hpp` | `InputFrame`, `LockEvent`, `EventKind` (14 base kinds), priorities |
| `include/lockcore/components.hpp` | shared mechanics: drop timer (`TensionHold`), tool stress / break / wear (`ToolStress`), pick magnet |
| `include/lockcore/family.hpp` | `FamilyModule` interface, `FamilyState`, `StepCtx`, `ViewModel`, oracle `Plan`, `SolveReport` |
| `include/lockcore/session.hpp` | `LockSession`: 1/120 s `step(InputFrame)`, events, continuous signals, event hash |
| `include/lockcore/bot.hpp` | scripted human-limited bot that runs an oracle plan through the real `step()` |
| `include/lockcore/lockfile.hpp`, `replay.hpp`, `json.hpp` | `lockwright.lock/1`, `lockwright.replay/1`, minimal JSON |
| `src/families/` | `pin_tumbler.cpp`, `wafer.cpp`, `builtin.cpp` (registration) |
| `tests/` | own minimal runner (`testing.hpp`), scenario tests, `golden/*.replay.json` |
| `tools/` | `verify_seeds`, `replay_tool` |

## Rules of the core

- **No floating point** in `src/` and `include/` (ctest `lockcore_no_float` greps for it);
  `-ffp-contract=off` is set anyway. All fractions are Q16, all times are steps.
- Families get randomness only from `StepCtx::rng`, never from a clock.
- The core never names a family; families register in `register_builtin_families()`.
- Events, not effects: the library emits `LockEvent`s plus two continuous signals
  (`tension_resistance`, `pick_drag`) per step; mapping to picture/sound/haptics is data.
- Family events carry the nearest base kind plus a sub-id (`pin.serration` = `false_set` + sub 1).

## Model (v0.1)

Shared tension model (LOCKS.md §1.5): the unset element with the lowest binding offset
binds at `T >= band_lo`; it moves only while `T <= t_stick = band_lo + tension_band`;
pressing it while `T > tau_safe` loads the tool (`S += (T - tau_safe) * press * gain`),
`stress` at 0.6 S_max, `break` at S_max, decay when unloaded, wear lowers S_max.
`T < t_hold` for `drop_grace` steps drops set elements.

`pin_tumbler`: set at window bottom; pushing a set key pin above window top +
`overset_margin` oversets it and jams the core until `T < t_release`. Spools catch at a
false gate (`false_set`, larger core rotation, other stacks loose), then rise only with
`T` in the counter-rotation band `[cr_lo, cr_hi]` (`counter_rotate` events while pushed;
above the band the tool is stressed, below `t_hold` it drops). Serrated stacks emit
`pin.serration` clicks below the window. Multi-bind pairs share a binding offset.

`wafer`: set wafers stay put; no security wafers; an overset clears when `T < t_release`,
which is above `t_hold`, so fixing it costs no drop.

Generator constants (Q16 thousandths): pin `t_hold 0.10`, `t_release 0.05`,
`band_lo 0.20..0.25`, `tau_safe = max t_stick + 0.06`, `cr 0.12..0.21`, stress gain 0.095,
bound pin speed 2/s, spool 0.6/s. Wafer: `t_hold 0.08`, `t_release 0.16`, `band_lo 0.22..0.26`.
Tier tables: `pin_tumbler` t2–t7 per LOCKS.md §2.6; `wafer` t1–t3 (D-17).

## Verifier (LOCKS.md §1.9)

1. **Oracle** (`FamilyModule::oracle`): validates, checks every tension band in the plan
   (including the spool band) ≥ δ_human 0.08, window ≥ 1.5× and window + margin ≥ 3×
   human position precision (0.03), and emits a plan (order, tension, approach, lift cap).
2. **Scripted bot** (`run_plan_bot`): executes the plan through `LockSession::step()` with
   1/256 quantisation, tremor ±0.03 tension / ±0.01 lift, rate limits 1.5/s and 3/s,
   180 ms reaction latency, 100 ms dwell; must open within half the tier time limit,
   with peak stress < 0.8 S_max and no break.
3. Blind bot: not in v0.1. As a soft metric `verify_seeds` runs a **clumsy bot**
   (tremor ±0.06, faster lifting, 250 ms reaction, no knowledge of the overset limit) and
   reports its success rate, drops and oversets per tier.

`generate()` retries up to 16 times (`seed' = hash(seed, attempt)`) until the oracle accepts.
Per seed `verify_seeds` also checks `validate()`, the lock-file round trip (bit-exact) and,
for the first `--replays` seeds, that replaying the recorded inputs gives the same hash.

## Data formats

`lockwright.lock/1` (ARCHITECTURE §6) and `lockwright.replay/1`: JSON with integers only;
fractions are `*_q16` integers, seeds are decimal strings (64-bit safe in Godot/JS).
Replays store `family`, `rules_version`, `seed`, the full difficulty vector and inputs
as RLE rows `[run, tension, depth, lift, rotate, push, tool]` in 1/256 units, plus the
expected FNV-1a 64 event hash. A replay with another `rules_version` is rejected explicitly.

Regenerate a golden file only on an intentional rules change (and bump `rules_version`):
`replay_tool record <family> <tier> <seed> lockcore/tests/golden/<name>.replay.json`.
