# Practice locks (`practice.t01`–`practice.t30`)

Thirty authored `lockwright.lock/1` files for the practice mode, proposed in
`contrib/gpt/T20/practice/` (ChatGPT delivery T20) and validated here with lockcore. Lesson
texts (`title_key`, `goal_key`, `hint_key` in `presentation.practice`) are in
`contrib/gpt/T20/practice.csv` (PL + EN) until they move into the game's i18n tables.
`presentation.practice` (order, focus, i18n keys) is game metadata: lockcore ignores it
and `lock_to_json()` does not write it back, so the game reads it from these files.

## How they were checked

```bash
lockcore/build/check_locks --feel 1000 --csv out.csv lockcore/practice/*.json
```

`check_locks` (new tool, `lockcore/tools/check_locks.cpp`) per file:

1. **parse** with `lock_from_json()` (which runs `validate()`), and a **format check**: every key
   outside `presentation` must come back from a parse / write round trip (a key the parser
   ignores, e.g. a typo of an optional field, or a value that reads back differently, fails);
2. **scripted bot** (`solver()`, the hard gate: oracle plan, half the time limit, stress < 0.8);
3. **clumsy bot** and **feeling bot** over 1000 bot seeds (soft metrics, full time limit),
   plus the share of feeling runs that met the lesson's event (`focus seen`).

ctest `practice_locks` runs it on every file here (20 bot seeds). All 30 parse, pass the
format check and open with the scripted bot; feeling-bot success is 100 % for all 30.

## Results (ordered by difficulty = feeling-bot median time)

| # | id | family | tier | focus | scripted | clumsy | feel % | median s | focus seen | path flag |
|---:|---|---|---:|---|---|---:|---:|---:|---:|---|
| 1 | `practice.t01` | `wooden_pin` | 1 | `open_hold` | ok (2.5 s) | 100 % | 100 % | 2.8 | – |  |
| 2 | `practice.t06` | `warded` | 1 | `bit_choice` | ok (2.9 s) | 100 % | 100 % | 3.2 | – | **below t05 (4.0 s)** |
| 3 | `practice.t05` | `warded` | 1 | `ward_gap` | ok (2.9 s) | 100 % | 100 % | 4.0 | – |  |
| 4 | `practice.t03` | `wafer` | 1 | `binding` | ok (4.3 s) | 100 % | 100 % | 6.1 | – |  |
| 5 | `practice.t11` | `ring_combo` | 2 | `detents` | ok (4.9 s) | 100 % | 100 % | 6.3 | – |  |
| 6 | `practice.t13` | `warded` | 2 | `spring_bolt` | ok (3.0 s) | 100 % | 100 % | 8.6 | – |  |
| 7 | `practice.t02` | `wooden_pin` | 1 | `binding_order` | ok (4.7 s) | 100 % | 100 % | 8.8 | – |  |
| 8 | `practice.t04` | `wafer` | 1 | `set_cue` | ok (6.2 s) | 100 % | 100 % | 9.1 | – |  |
| 9 | `practice.t07` | `wafer` | 2 | `overset` | ok (5.2 s) | 100 % | 100 % | 9.2 | ov 0% |  |
| 10 | `practice.t19` | `lever` | 3 | `spring_return` | ok (5.4 s) | 100 % | 100 % | 9.2 | – | **below t18 (11.9 s)** |
| 11 | `practice.t18` | `lever` | 3 | `lever_gate` | ok (5.8 s) | 100 % | 100 % | 11.9 | – |  |
| 12 | `practice.t10` | `pin_tumbler` | 2 | `tension_hold` | ok (5.3 s) | 100 % | 100 % | 11.9 | – | **below t09 (13.0 s)** |
| 13 | `practice.t22` | `lever` | 4 | `false_gate` | ok (7.0 s) | 100 % | 100 % | 12.5 | fs 62% |  |
| 14 | `practice.t09` | `pin_tumbler` | 2 | `binding_order` | ok (5.9 s) | 100 % | 100 % | 13.0 | – |  |
| 15 | `practice.t08` | `wafer` | 2 | `overset_recovery` | ok (7.1 s) | 100 % | 100 % | 14.9 | ov <1% |  |
| 16 | `practice.t14` | `pin_tumbler` | 3 | `narrow_window` | ok (6.9 s) | 100 % | 100 % | 14.9 | – |  |
| 17 | `practice.t16` | `wafer` | 3 | `multi_binding` | ok (8.0 s) | 100 % | 100 % | 15.4 | – |  |
| 18 | `practice.t12` | `ring_combo` | 2 | `ring_binding` | ok (6.8 s) | 100 % | 100 % | 15.5 | – |  |
| 19 | `practice.t28` | `lever_detector` | 5 | `detector_reset` | ok (8.0 s) | 100 % | 100 % | 15.5 | dt 2% | **below t27 (17.9 s)** |
| 20 | `practice.t25` | `pin_tumbler` | 5 | `mixed_security` | ok (7.9 s) | 99.9 % | 100 % | 15.7 | fs 100% | **below t20 (21.2 s)** |
| 21 | `practice.t15` | `pin_tumbler` | 3 | `overset_recovery` | ok (6.9 s) | 100 % | 100 % | 16.9 | ov <1% |  |
| 22 | `practice.t24` | `lever` | 4 | `multiple_gates` | ok (7.1 s) | 100 % | 100 % | 16.9 | – |  |
| 23 | `practice.t27` | `lever_detector` | 5 | `detector_trip` | ok (8.4 s) | 100 % | 100 % | 17.9 | dt 1% |  |
| 24 | `practice.t21` | `pin_tumbler` | 4 | `counter_rotation` | ok (8.4 s) | 100 % | 100 % | 18.1 | cr 100% | **below t20 (21.2 s)** |
| 25 | `practice.t23` | `pin_tumbler` | 4 | `serration` | ok (8.4 s) | 100 % | 100 % | 20.9 | fs 88% | **below t20 (21.2 s)** |
| 26 | `practice.t20` | `pin_tumbler` | 4 | `false_set` | ok (8.4 s) | 100 % | 100 % | 21.2 | fs 100% |  |
| 27 | `practice.t26` | `lever` | 5 | `two_false_gates` | ok (10.0 s) | 100 % | 100 % | 22.2 | fs 99% |  |
| 28 | `practice.t17` | `ring_combo` | 3 | `false_notch` | ok (8.1 s) | 100 % | 100 % | 23.8 | fs 100% |  |
| 29 | `practice.t30` | `lever_detector` | 6 | `detector_mastery` | ok (12.4 s) | 31.6 % | 100 % | 26.4 | dt 2% |  |
| 30 | `practice.t29` | `pin_tumbler` | 6 | `quiet_precision` | ok (9.5 s) | 99.9 % | 100 % | 26.5 | – |  |

`#` = rank by difficulty; the path order is the number in the id (`order` in the file).
`scripted` = scripted bot result and time; `clumsy` / `feel %` = success over 1000 bot seeds;
`median s` = feeling-bot median time of the successful runs; `focus seen` = share of feeling
runs with the focus event (`ov` overset, `fs` false_set incl. serration / false notch,
`cr` counter_rotate, `dt` detector_trip); `–` = the focus has no single event.

## Fixes against the T20 proposal

No format errors: all 30 files parsed, every key was read, ids match file names, `difficulty`
agrees with `spec` (element count within `n_min..n_max`, shared Q16 values equal). Two content
fixes, found by the bots:

- **`practice.t17` (`false_notch`)**: the only false notch was on ring 0 (digit 5); the
  feeling bot never got caught in it (0 / 1000 runs; ≤ 2 % for any digit on ring 0 or 1, and
  generated t3 locks with a notch only on an early-binding ring show the same).
  Moved to ring 2, digit 0 (the oracle forbids the digit before the gate): caught in 100 % of
  runs, median time unchanged.
- **`practice.t30` (`detector_mastery`)**: `overset_margin` 0.085 was above the detector
  margin 0.083, so the detector tripped before an overset could warn (against the rules-2
  design, BALANCE.md: t6 overset 0.08 < detector 0.083); clumsy bot 0 %. Set to 0.08
  (5243, the `lever_detector` t6 table value, in `spec` and `difficulty`): clumsy 31.6 %
  (generated t6 locks: 18–68 %), feeling bot unchanged.

## Flags

**Not monotonic in the path** (median time below an earlier lesson of the same family;
the path is ordered by tier, which never decreases):

- `t06` < `t05` (warded, 3.2 vs 4.0 s), `t10` < `t09` (pin, 11.9 vs 13.0 s), `t19` < `t18`
  (lever, 9.2 vs 11.9 s), `t28` < `t27` (detector, 15.5 vs 17.9 s): consecutive lessons of the
  same tier; small, acceptable if the order serves the lesson.
- `t21`, `t23` < `t20` (pin t4, 18.1 / 20.9 vs 21.2 s): same tier, small.
- **`t25` (tier 5, `mixed_security`) is easier than all three tier-4 pin lessons** (15.7 s vs
  18.1–21.2 s) — the clearest outlier; suggest more stacks or a narrower window, or moving it
  before `t20`.

Across families the time is not monotonic by design (e.g. `t17` ring tier 3 at 23.8 s is the
third hardest; `t13` warded tier 2 at 8.6 s).

**Focus rarely shown by itself:** `t07` (`overset`, 0 %), `t08` / `t15` (`overset_recovery`,
< 1 %), `t27` / `t28` / `t30` (detector, 1–2 %), `t22` (`false_gate`, 62 %). A careful player
(the feeling bot) does not overset or trip the detector, so these lessons need the goal text
to ask for it ("lift past the click", "trip it once and reset"); the lock definition alone
cannot force it (T20 README says the same).
