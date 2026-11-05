# lockcore

Deterministic lock-logic library for Lockwright (C++20, no engine dependency, no
third-party code). The Godot layer will reach it through GDExtension (D-04); the
library itself builds and tests natively on Linux, macOS, Android NDK and iOS.

Status: **v0.3** — core + seven families (`pin_tumbler`, `wafer`, `wooden_pin`, `warded`,
`lever`, `lever_detector`, `ring_combo`), verifier with three bots, replays, light fuzzing.
Balance per tier (feeling / clumsy bot): [`BALANCE.md`](BALANCE.md).

## Build and test

```bash
cmake -S lockcore -B lockcore/build -G Ninja          # Release by default; -G is optional
cmake --build lockcore/build
ctest --test-dir lockcore/build --output-on-failure   # unit tests, golden replays, fuzz, no-float check, 200-seed smoke
lockcore/build/verify_seeds --seeds 1000              # fast verifier run (CI on every push)
lockcore/build/verify_seeds --seeds 10000 --csv out.csv   # full run (A3), ~85 s on 1 core (all bots)
```

Other configurations:

```bash
cmake -S lockcore -B lockcore/build-clang -DCMAKE_CXX_COMPILER=clang++
cmake -S lockcore -B lockcore/build-asan -DCMAKE_BUILD_TYPE=Debug -DLOCKCORE_SANITIZE=ON
```

Tools:

```bash
lockcore/build/verify_seeds [--seeds N] [--family warded] [--tier 2] [--replays N] [--feel N] [--csv FILE]
lockcore/build/replay_tool lock pin_tumbler 4 123             # print a generated lockwright.lock/1
lockcore/build/replay_tool record wafer 2 77 out.replay.json  # record the bot's run [--clumsy|--feel]
lockcore/build/replay_tool play lockcore/tests/golden/wafer_t2_s77.replay.json
```

Run a single test group: `lockcore/build/lockcore_tests pin:` (substring filter);
`lockcore/build/lockcore_tests fuzz` runs only the fuzz test (ctest `lockcore_fuzz`; under
`-DLOCKCORE_SANITIZE=ON` UB is fatal).

## Layout

| Path | Content |
|---|---|
| `include/lockcore/fixed.hpp` | Q16 in int32 (`65536 == 1.0`), int64 products, `SIM_HZ = 120`, 1/256 input quantisation |
| `include/lockcore/prng.hpp` | PCG32, own implementation; one stream per family and purpose (`gen`, `sim`, `bot`) |
| `include/lockcore/hash.hpp` | FNV-1a 64 (event stream), SplitMix64 seed derivation |
| `include/lockcore/input.hpp`, `events.hpp` | `InputFrame`, `LockEvent`, `EventKind` (14 base kinds), priorities |
| `include/lockcore/components.hpp` | shared mechanics: drop timer (`TensionHold`), tool stress / break / wear (`ToolStress`), pick magnet |
| `include/lockcore/family.hpp` | `FamilyModule` interface, `FamilyState`, `StepCtx`, `ViewModel`, oracle `Plan`, `SolveReport`, `BotKind` + `run_bot()` |
| `include/lockcore/session.hpp` | `LockSession`: 1/120 s `step(InputFrame)`, events, continuous signals, event hash |
| `include/lockcore/bot.hpp` | scripted human-limited bot (oracle plan through the real `step()`), feeling bot for lift families |
| `include/lockcore/<family>.hpp` | `pin_tumbler`, `wafer`, `wooden_pin`, `warded`, `lever` (+ `lever_detector`), `ring_combo`: params, sub-events, constants |
| `include/lockcore/lockfile.hpp`, `replay.hpp`, `json.hpp` | `lockwright.lock/1`, `lockwright.replay/1`, minimal JSON |
| `src/families/` | one file per family, `builtin.cpp` (registration) |
| `tests/` | own minimal runner (`testing.hpp`), scenario tests per family, `test_fuzz.cpp`, `golden/*.replay.json` |
| `tools/` | `verify_seeds`, `replay_tool` |

## Rules of the core

- **No floating point** in `src/` and `include/` (ctest `lockcore_no_float` greps for it);
  `-ffp-contract=off` is set anyway. All fractions are Q16, all times are steps.
- Families get randomness only from `StepCtx::rng`, never from a clock.
- The core never names a family; families register in `register_builtin_families()`.
- Events, not effects: the library emits `LockEvent`s plus two continuous signals
  (`tension_resistance`, `pick_drag`) per step; mapping to picture/sound/haptics is data.
- Family events carry the nearest base kind plus a sub-id (`pin.serration` = `false_set` + sub 1).

## Shared model and the v0.1 families

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
Tier tables: `pin_tumbler` t2–t7 per LOCKS.md §2.6 (t5 5–6 stacks, t7 overset 5.5 %, D-34); `wafer` t1–t3 (D-17).

## Families (v0.2)

| Family | Tiers | Inputs | Tool bit | Core of the puzzle |
|---|---|---|---|---|
| `pin_tumbler` | t2–t7 | T, D, L | wrench + hook | stacks, spools, serrations (v0.1) |
| `wafer` | t1–t3 | T, D, L | wrench + hook | easy overset fix (v0.1) |
| `wooden_pin` | t1 | T, D, L | `TOOL_PEG_LIFTER` | bolt pull, pegs in order, open after 0.3 s hold |
| `warded` | t1–t2 | T, D, L, R, tool | `TOOL_WARD_PROBE` | turn through ward gaps, bit choice, spring bolt |
| `lever` | t3–t5 | T, D, L | `TOOL_LEVER_CRANK` | gates, false notches, spring fall-back |
| `lever_detector` | t5–t6 | T, D, L, R | `TOOL_LEVER_CRANK` | lever + detector trip and rotate-back reset |
| `ring_combo` | t2–t3 | T, D, R | `TOOL_SHACKLE_PULLER` | which ring binds, where it drops in, false notches |

`wooden_pin` (§2.1): like `wafer` (set pegs stay up, `t_release` 0.20 above `t_hold` 0.10, so an
overset costs no drop), but the tool never breaks: a pull above `tau_creak` emits `wood.creak`
(base `stress`, sub 1). Opening needs every peg set and `T >= t_hold` for `open_hold` (36 steps).
`overset_enabled = false` gives the tutorial locks of the card. Tier t1 only (3–4 pegs, 15 %).

`warded` (§2.2): state = probe depth, tip height `h`, turn `theta` (open at 1). Ward k blocks the
turn through `[a_lo, a_hi]` unless the whole bit `[h - w/2, h + w/2]` is inside its gap; inside a
span the tip only moves within the gap (`ward.scrape`). `gate_align` when the bit lines up with
the ward ahead. Bits (`InputFrame::tool`): square w 0.12 / safe 0.55, hook 0.06 / 0.32, fork
0.22 / 0.80; swapped only withdrawn and unturned. The bolt at `a_bolt` 0.82 is caught (bind) with
`h` in its band and lifted only with `bolt_spring <= T <= bit limit` (set at 0.92). Pressing
against a ward / the bolt / the end stop above the bit limit loads stress (gain 0.08). t1 probes
only bend (S is kept below S_max); t2 breaks after three stress episodes. The generator makes
exactly one offered bit work. Tiers: t1 1–2 wards, 2 bits; t2 2–3 wards, 3 bits (`sec` = bits).

`lever` / `lever_detector` (§2.7, §2.8): one module, generator flag `Params::detector`. Pin-like
binding and stress; a bound lever falls back on its spring (0.3→0.5 × 4/s) when the lifter drops;
gate = `gate_align` + `set`; false notches below the gate (`sec` per lever) catch the lever
(`false_set` + `lever.false_gate`) and release it only with `T` in `[cr_lo, cr_hi]` =
`[0.12, 0.21]` (`counter_rotate`); overset clears below `t_release` 0.05 (costs a drop). A set
lever follows the lifter above its gate at most `set_speed` 0.6/s (rules 2). Detector:
any lever above gate top + `detector_margin` (t5 0.10, t6 0.083; rules 2) trips (`detector_trip`, every lever
`jammed`); reset = `T < t_hold` and `rotate <= -1/2` for 1.5 s (t5) / 2.5 s (t6) →
`detector.reset` (base `drop`, sub 2), 2 wear points; the third trip blocks the lock
(`FailureKind::detector_trip`).

`ring_combo` (§2.3): 10 digits per ring; `pick_depth` selects a ring, `rotate` turns it. The
lowest-order unset ring binds at `T >= band_lo`, turns stiffly (drag) and only while
`T <= t_stick`; at its gate it drops in (`gate_align` + `set`), the next ring binds. Detents
(`ring.detent`, one per digit) and a snap to the nearest digit when not turned. False notches (t3)
catch a bound ring until the pull is eased below `band_lo`. Letting go keeps ring positions (only
the set flags go). `gate_feel` = 1 − `noise` scales the cues (t2 0.7, t3 0.45). No breaking.

## Verifier (LOCKS.md §1.9)

1. **Oracle** (`FamilyModule::oracle`): validates, checks every tension band in the plan
   (including the spool band) ≥ δ_human 0.08, window ≥ 1.5× and window + margin ≥ 3×
   human position precision (0.03), and emits a plan (order, tension, approach, lift cap).
2. **Scripted bot** (`run_plan_bot`): executes the plan through `LockSession::step()` with
   1/256 quantisation, tremor ±0.03 tension / ±0.01 lift, rate limits 1.5/s and 3/s,
   180 ms reaction latency, 100 ms dwell; must open within half the tier time limit,
   with peak stress < 0.8 S_max and no break.
3. **Feeling bot** (stage 3, v0.2, `BotKind::feeling`): sees only the events and the two
   continuous signals, delayed by 220 ms (tremor ±0.04), plus what is drawn (element count,
   offered bits). Lift families share `run_feel_bot`: it raises the tension until a probed
   element drags, lifts the dragging one slowly, eases into false gates, flicks the tension after
   an overset, lowers the tension on stress and resets a tripped detector. `ring_combo` and
   `warded` have their own (ring: drag probing, notch escape; warded: height sweep at a ward,
   bit change after a failed sweep or stress, more force on a stuck bolt). Budget = the tier time
   limit. Success rate and time p50/p90 per tier go to the report and the CSV — **not a gate**.
   The **clumsy bot** (tremor ±0.06, faster lifting, 250 ms reaction, no knowledge of the
   overset limit) stays as a second soft metric.

`FamilyModule::run_bot(kind, ...)` runs any of the three bots; the default serves lift-based
families (`run_plan_bot` / `run_feel_bot`), `warded` and `ring_combo` override it (and `solver()`).

Results (10 000 seeds per tier, scripted gate: 0 failures in every family and tier; full table
in [`BALANCE.md`](BALANCE.md)). Feeling bot success is 99.9–100 % everywhere since v0.3; its time
p50 rises with every tier: `pin_tumbler` t2–t7 11–27 s, `wafer` 12–22 s, `wooden_pin` 16 s,
`warded` 15–19 s, `lever` 13–23 s, `lever_detector` 23–29 s, `ring_combo` 25–34 s. Clumsy bot on
the top tiers: `pin_tumbler` t6 93.7 % → t7 36.0 %, `lever_detector` t5 99.9 % → t6 42.5 %.

`generate()` retries up to 16 times (`seed' = hash(seed, attempt)`) until the oracle accepts.
Per seed `verify_seeds` also checks `validate()`, the lock-file round trip (bit-exact) and,
for the first `--replays` seeds, that replaying the recorded inputs gives the same hash.

## Data formats

`lockwright.lock/1` (ARCHITECTURE §6) and `lockwright.replay/1`: JSON with integers only;
fractions are `*_q16` integers, seeds are decimal strings (64-bit safe in Godot/JS).
Replays store `family`, `rules_version`, `seed`, the full difficulty vector and inputs
as RLE rows `[run, tension, depth, lift, rotate, push, tool]` in 1/256 units, plus the
expected FNV-1a 64 event hash. A replay with another `rules_version` is rejected explicitly.

Golden files (`tests/golden/`): two per v0.2 family, one of them recorded from the feeling bot
(`--feel`); `lever_detector_t6_s8_feel_reset` includes a detector trip and reset.

Regenerate a golden file only on an intentional rules change (and bump `rules_version`; a
replay stores the difficulty vector, so tier-table changes do not touch goldens):
`replay_tool record <family> <tier> <seed> lockcore/tests/golden/<name>.replay.json`.

## Fuzzing

`tests/test_fuzz.cpp`: 100 000 steps of random inputs per family (random walk with jumps on every
axis, random tool slots, new lock on open / failure / after 40 s, random tier). Checked every step:
event time = session step, intensities in [0, 1], element index in range, sub-events named,
continuous signals in [0, 1], view positions / stress / rotation in [0, 1], window lo <= hi,
S >= 0. CI runs it under ASan + UBSan with `-fno-sanitize-recover=undefined` and a 300 s timeout.

## API changes

### v0.3 (balance, D-34)

Additive for the API; behaviour changes are listed here.

- `lever.hpp`: `lever::RULES_VERSION` 1 → **2** (both `lever` and `lever_detector`). New
  `Params::set_speed` (per step; 0 = rules-1 behaviour, the set lever jumps to the lifter) and
  constants `SET_SPEED` (0.6/s), `DETECTOR_MARGIN_T5` (0.10), `DETECTOR_MARGIN_T6` (0.083; was
  0.12 / 0.06). Lock files gain an optional `set_speed_q16` (written only when > 0; files without
  it still parse). The rules version feeds the generator seed, so every generated lever lock
  changes; lever replays recorded under rules 1 are rejected.
- Goldens regenerated on purpose: `lever_t5_s5` (rules 2), `lever_detector_t6_s1_feel_reset`
  replaced by `lever_detector_t6_s8_feel_reset` (seed 1 no longer trips the detector under
  rules 2; seed 8 does, once, and resets). Other goldens unchanged (same hashes).
- `pin_tumbler::difficulty_for_tier`: t5 `n` 5 → 5–6, t7 `overset_margin` 0.05 → 0.055.
  `RULES_VERSION` unchanged (the generator code is the same; replays carry their vector).
- `run_feel_bot` (report only): keeps working an element perceived in a false gate (also when
  the catch is perceived after the probe moved on), drag threshold 0.03 → 0.01, empty sweeps
  probe higher (0.22 → 0.37 in 0.05 steps). Fixes stuck loops; see `BALANCE.md`.
- `verify_seeds`: clumsy and feeling lines also print exact counts (`(9987/10000)`, `(9996 ok)`).
  CSV unchanged.

### v0.2

v0.2 only **adds** to the public headers; code written against v0.1 compiles unchanged.

- `family.hpp`: `enum class BotKind { scripted, clumsy, feeling }` and
  `virtual SolveReport FamilyModule::run_bot(BotKind, const LockSpec&, const ToolSet&, const SolveOptions& = {}) const`
  (default implementation in `bot.cpp`). Adding a virtual changes the vtable: rebuild anything
  that links lockcore (the GDExtension builds it from source anyway).
- `bot.hpp`: `run_feel_bot()`, `feeling_human_limits()`, `bot_approach()`. `run_plan_bot()` now
  also resets a tripped detector (only for families with `AXIS_ROTATE`; v0.1 families unaffected,
  golden hashes unchanged).
- `spec.hpp`: `ToolBits` `TOOL_PEG_LIFTER`, `TOOL_WARD_PROBE`, `TOOL_LEVER_CRANK`,
  `TOOL_SHACKLE_PULLER`. `ToolSet{}` still defaults to wrench + hook, so pass
  `family.required_tools(spec)` to `LockSession` / `solver()` for the new families.
- New headers: `wooden_pin.hpp`, `warded.hpp`, `lever.hpp`, `ring_combo.hpp` (not in the umbrella
  `lockcore.hpp`, like `pin_tumbler.hpp` / `wafer.hpp`). New family ids in `FamilyRegistry::builtin()`.
- Behaviour fix: `ToolStress::ratio()` (and so `ViewModel::stress`) is clamped to [0, 1]; in the
  breaking step it could exceed 1 before. Event hashes do not change (break intensity is 1).
- Family-specific `InputFrame` use: `warded` reads `tool` as the bit slot and `rotate` as turn
  speed; `ring_combo` reads `rotate`; `lever_detector` reads `rotate <= -1/2` for the reset.
  `ViewModel` meanings per family: `warded` elements = wards then the bolt, `core_rotation` = turn;
  `ring_combo` element `position` = fraction of a turn (digit = position × 10), windows may wrap;
  `lever` `variant` = number of false notches.
- `verify_seeds`: `--feel N`, feeling-bot section in the report, CSV gains `clumsy_ok_x1000`,
  `feel_runs`, `feel_ok_x1000`, `feel_p50`, `feel_p90`. `replay_tool record ... --feel`.
