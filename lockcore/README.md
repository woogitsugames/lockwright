# lockcore

Deterministic lock-logic library for Lockwright (C++20, no engine dependency, no
third-party code). The Godot layer will reach it through GDExtension (D-04); the
library itself builds and tests natively on Linux, macOS, Android NDK and iOS.

Status: **v0.6** — core + families `pin_tumbler`, `wafer`, `wooden_pin`, `warded`,
`lever`, `lever_detector`, `ring_combo` and the D-59 families (`dial_safe`, `combo`, `dimple`,
`disc_detainer`, `egyptian`, `axial_slider`, `time_lock`, `magnetic`; see v0.6 below),
verifier with three bots, replays, light fuzzing.
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
lockcore/build/replay_tool trace lockcore/tests/golden/wafer_t2_s77.replay.json out.trace.json  # per-step trace
lockcore/build/check_locks [--feel N] [--csv FILE] lockcore/practice/*.json   # authored locks: parse, format, all bots
```

Authored practice locks (30, validated, with the results table): [`practice/`](practice/README.md).

### Replay debugger (lockviz)

`replay_tool trace <file.replay.json> <out.trace.json>` plays a replay exactly like `play`
(same session, same hash; exit 1 on mismatch) and writes `lockwright.trace/1`: one flat row per
step (`frame_fields` = inputs, continuous signals, stress, core rotation, pick element, failure,
hold/reset progress, then `state, position` per element), every event `[t_step, kind, sub, element, intensity,
material]`, name tables and the element windows. All values stay Q16 integers (65536 = 1.0).

`mockups/tools/lockviz/` is a plain HTML+JS viewer for it (design/debug tool, not game code):
per-family schematic (pins/wafers, levers + stump, wards + key bit + bolt, rings + reading line),
input and signal curves, per-element state strips (pattern per state), event lanes, scrubbing
(drag the timeline, arrows, Shift+arrows ×10, `[`/`]` previous/next event, space = play).

```bash
# regenerate traces for all golden replays
for f in lockcore/tests/golden/*.replay.json; do b=$(basename $f .replay.json); \
  lockcore/build/replay_tool trace $f mockups/tools/lockviz/traces/$b.trace.json; done
python3 -m http.server -d . 8000   # open http://localhost:8000/mockups/tools/lockviz/?trace=wafer_t2_s77&t=400
node mockups/tools/lockviz/shot.mjs [trace-name] [frame|end] [out.png]   # Playwright screenshot
```

A new trace name must also be added to `mockups/tools/lockviz/traces/index.json`; any other
trace/replay can be opened with the file pickers.

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
| `tools/` | `verify_seeds`, `replay_tool`, `check_locks` (authored lock files) |
| `practice/` | 30 authored practice locks (`lockwright.lock/1`) + results table |

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
| `dial_safe` | t1–t3 | T, L | `TOOL_LISTENING_CUP` | wheel pack: pick up, listen for the gate, reverse to leave it (LOCKS.md §2.18) |
| `combo` | t1–t4 | T, D, L | `TOOL_SHACKLE_PULLER` | `ring_combo` module flag: thumbwheels on `pick_lift`, sleeve slip (§2.19) |
| `disc_detainer` | t1–t3 | T, D, L | `TOOL_DISC_PICK` | `ring_combo` module, third flavour: discs both ways, over-turn (§2.21) |
| `egyptian` | t1–t2 | T, D, L | `TOOL_PEG_LIFTER` | `wooden_pin` module flag: pegs fall by gravity, wedge when the bolt bites (§2.22) |
| `axial_slider` | t1–t3 | T, D, L | `TOOL_SLIDER_PUSHER` | `lever` module flag: sliders pressed in, false notches from t2 (§2.23) |
| `time_lock` | t1–t2 | T, D, L | `TOOL_CLOCK_KIT` | `wafer` module flag: mesh the train in order, wind and keep the beat (§2.24) |
| `magnetic` | t1–t2 | T, D, L | `TOOL_MAGNET_PROBE` | `pin_tumbler` module, third flavour: pins trail the probe field (§2.25) |
| `dimple` | t1–t3 | T, D, L | `TOOL_DIMPLE_FLAG` | `pin_tumbler` module flag: telescoping pins (spool rule), side row (§2.20) |

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

### v0.6 (D-59 families)

Additive; hashes and goldens of the earlier families unchanged.

- New families `dial_safe` (`dial_safe.hpp`, LOCKS.md §2.18) and `combo` (`ring::make_combo_module()`,
  §2.19; `ring::Params::slip_speed`, written to lock files only when > 0, sub `combo.slip` = overset + 2),
  `dimple` (`pin::make_dimple_module()`, §2.20; `TOOL_DIMPLE_FLAG`, `pin::DIMPLE_SIDE_ROW` variant bit),
  `disc_detainer` (`ring::make_disc_module()`, §2.21; `TOOL_DISC_PICK`, `ring::Params::overturn_speed`,
  sub `disc.overturn` = overset + 3, 8 positions), `egyptian` (`wooden::make_egyptian_module()`, §2.22;
  `wooden::Params::fall_speed`, written only when > 0), `axial_slider` (`lever::make_slider_module()`,
  §2.23; `TOOL_SLIDER_PUSHER`, sub 1 named `slider.false_notch`, rules 1), `time_lock`
  (`wafer::make_clock_module()`, §2.24; `TOOL_CLOCK_KIT`, `wafer::Params::run_steps` / `run_lo`, subs
  `time.tick` = contact + 2, `time.beat_off` = near_shear + 3; `hold_progress` = run progress),
  `magnetic` (`pin::make_magnetic_module()`, §2.25; `TOOL_MAGNET_PROBE`, `pin::Params::field_speed`,
  written only when > 0; `pick_lift` in the view = field position).
- `bot.cpp`: the scripted and feeling bots keep waiting for `open` while the drawn `hold_progress` is
  above 0 (a run or a bolt slide in progress). Earlier families open within the old wait anyway; goldens
  replay inputs, so their hashes are unchanged. They read only `tension`, `pick_depth`,
  `pick_lift` (no `rotate` / `push`), so a plan-B screen calling `step(t, depth, lift)` drives them.
- `spec.hpp`: `TOOL_LISTENING_CUP` (dial_safe).
- `family.hpp`: `ViewModel` gains `q16 dial` (dial reading, fraction of a turn) and `std::int32_t
  dial_divisions` (0 for families without a dial). The GDExtension `describe()` exposes them as
  `dial` (float) and `dial_divisions` (int).
- `dial_safe` sub-events: `safe.detent` (contact), `safe.pickup` (bind), `safe.fence_drop` (set),
  `safe.fence_bounce` (contact). Element `position` = wheel number / divisions; `pick_element` = the
  wheel being listened to; `hold_progress` = bolt travel after the fence drops.

### v0.5 (review T25, [`REVIEW-T25.md`](REVIEW-T25.md))

Hashes and goldens unchanged (every fix only changes behaviour on input that was
invalid or out of domain before, or in a step that both opened and broke, which no golden has).

- `session.hpp`: `LockSession` checks its input (`session_input_error()`: `spec.family` names the
  module, `validate()` is empty, `tools` hold `required_tools(spec)`). A refused session never
  calls `init_state()`: `valid()` false, `error()` says why, `finished()` at t = 0 with the new
  `FailureKind::invalid_spec` (appended to the enum), `state()` an empty base state.
  `LockSession(family, spec)` (two arguments) now uses `family.required_tools(spec)` instead of
  `ToolSet{}` (wrench + hook); code that passed a `ToolSet` explicitly is unchanged.
- `FamilyModule::run_bot()` (all three bots; `warded` / `ring_combo` overrides too) returns
  `ok = false` with the refusal reason; the feeling bot still skips only the oracle gate.
- `run_replay()` (and `replay_tool trace` / `lock` / `record`) refuses a generated lock the oracle
  rejects (`generate()` returns its 16th attempt for vectors outside the tier tables).
- `replay_from_json()` is strict: seed via `field::parse_u64()` (now public in `lockfile.hpp`),
  `difficulty`, `input_unit` "1/256", `input_fields`, `expected` with `event_hash_fnv1a64`
  required; axes in range (tension / depth / push 0..256, lift / rotate −256..256, tool 0..255)
  before scaling; inputs must be canonical (`quantize(f) == f`, push on its 1/64 grid); at most
  `MAX_REPLAY_STEPS` (3600 s × 120) frames over all runs. `out` is assigned only on success.
- `fixed.hpp` / `prng.hpp` / `components.hpp`: `q16_saturate()`; `q16_ratio` (den 0 → 0, saturates),
  `q_div` (saturates), `q_abs(INT32_MIN)`, `ms_to_steps`, `quantize_256` are total; `Pcg32::range`
  covers the full int32 range; `ToolStress::ratio()` clamps before dividing. In-range results
  and PCG sequences are bit-identical.
- `ToolStress::add_wear()` (keeps S, peak, wear accumulator); the `lever_detector` reset uses it, so
  `peak_ratio()` no longer drops after a reset. `end_step(..., can_break)`: the step that opens a
  lock cannot break the tool (`pin_tumbler`, `wafer`, `lever`, `warded`); open wins.
- JSON: lone low surrogates and malformed raw UTF-8 are rejected.
- New tool `check_locks` (authored lock files: parse, ignored-key check, scripted / clumsy /
  feeling bot, lesson events) and ctest `practice_locks` over `practice/*.json`.
- `verify_seeds`: `--seeds` ≥ 1, strict integers, unknown `--family` / empty tier selection and
  CSV errors exit 2; replay check also round-trips `expected`. `replay_tool play` / `trace`
  compare hash, steps and open and name the mismatching field; write errors exit 1.

### v0.4 (progress fields, FEEL.md F-07)

Additive; code written against v0.3 compiles unchanged, hashes and goldens unchanged.

- `family.hpp`: `ViewModel` gains `q16 hold_progress` and `q16 reset_progress` (Q16 0..1,
  read-only, never hashed; 0 where not applicable). `wooden_pin`: fraction of `open_hold_steps`
  for which all pegs are set and the bolt is held (`T >= t_hold`), back to 0 when the hold
  breaks, 1 once open. `lever_detector`: while tripped, fraction of `reset_steps` the rotate-back
  (`T < t_hold`, `rotate <= -1/2`) has been held; 0 when released or after the reset. All other
  families: always 0.
- `replay_tool trace`: `frame_fields` gains `hold_progress`, `reset_progress` after `failure`
  (per-element columns follow them; lockviz reads the layout from `frame_fields`). Traces in
  `mockups/tools/lockviz/traces/` regenerated.

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
