# Practice locks (`practice.t01`–`practice.t30`)

Thirty authored `lockwright.lock/1` files for the practice mode, proposed in
`contrib/gpt/T20/practice/` (ChatGPT delivery T20) and validated here with lockcore; path order,
lesson targets and four parameter sets revised from T38 (`contrib/gpt/T38/`, D-54). Titles and
hints (`title_key`, `hint_key`) are in `contrib/gpt/T20/practice.csv` (PL + EN) until they move
into the game's i18n tables; the goals (`goal_key` = `practice.<tNN>.goal`) are in
`game/i18n/strings.csv` (T38 texts, PL / EN / DE; they replace the T20 goal lines).
`presentation.practice` (order, focus, lesson_target, i18n keys) is game metadata: lockcore ignores it
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
   plus the share of runs that met `lesson_target` (gate: clumsy ≥ 30 %, feeling open ≥ 95 %).

ctest `practice_locks` runs it on every file here (200 bot seeds). All 30 parse, pass the
format check, open with the scripted bot and pass the lesson gate; feeling-bot success is 100 %
for all 30.

## Results (path order, D-54)

`check_locks --feel 1000`, bot seeds 1000–1999. The path is ordered by tier, and inside a tier by
the feeling bot's median time (strictly rising in every tier; `practice.t25`, tier 5, at 25.3 s is
above every tier-4 lesson, max 20.8 s). The id is stable (i18n keys, saves); the position in the
path is `presentation.practice.order` (`#`).

| # | id | family | tier | focus | lesson_target | scripted | clumsy | feel % | median s | target clumsy | target feel |
|---:|---|---|---:|---|---|---|---:|---:|---:|---:|---:|
| 1 | `practice.t01` | `wooden_pin` | 1 | `open_hold` | `open` | ok (2.5 s) | 100 % | 100 % | 2.7 | 100 % | 100 % |
| 2 | `practice.t06` | `warded` | 1 | `bit_choice` | `gate_align` | ok (2.8 s) | 100 % | 100 % | 3.2 | 100 % | 96.5 % |
| 3 | `practice.t05` | `warded` | 1 | `ward_gap` | `gate_align` | ok (2.8 s) | 100 % | 100 % | 3.9 | 100 % | 100 % |
| 4 | `practice.t03` | `wafer` | 1 | `binding` | `bind` | ok (4.2 s) | 100 % | 100 % | 6.1 | 100 % | 100 % |
| 5 | `practice.t02` | `wooden_pin` | 1 | `binding_order` | `bind` | ok (4.6 s) | 100 % | 100 % | 8.8 | 100 % | 100 % |
| 6 | `practice.t04` | `wafer` | 1 | `set_cue` | `set` | ok (6.2 s) | 100 % | 100 % | 9.1 | 100 % | 100 % |
| 7 | `practice.t11` | `ring_combo` | 2 | `detents` | `ring.detent` | ok (4.8 s) | 100 % | 100 % | 6.2 | 100 % | 100 % |
| 8 | `practice.t13` | `warded` | 2 | `spring_bolt` | `set` | ok (2.9 s) | 100 % | 100 % | 8.5 | 100 % | 100 % |
| 9 | `practice.t07` | `wafer` | 2 | `overset` | `overset` | ok (4.1 s) | 100 % | 100 % | 8.9 | 38.6 % | 4.1 % |
| 10 | `practice.t10` | `pin_tumbler` | 2 | `tension_hold` | `set` | ok (5.2 s) | 100 % | 100 % | 11.9 | 100 % | 100 % |
| 11 | `practice.t09` | `pin_tumbler` | 2 | `binding_order` | `bind` | ok (5.8 s) | 100 % | 100 % | 13.0 | 100 % | 100 % |
| 12 | `practice.t08` | `wafer` | 2 | `overset_recovery` | `overset` | ok (5.7 s) | 99.9 % | 100 % | 14.6 | 54.4 % | 6 % |
| 13 | `practice.t12` | `ring_combo` | 2 | `ring_binding` | `bind` | ok (6.7 s) | 100 % | 100 % | 15.4 | 100 % | 100 % |
| 14 | `practice.t19` | `lever` | 3 | `spring_return` | `set` | ok (5.3 s) | 100 % | 100 % | 9.2 | 100 % | 100 % |
| 15 | `practice.t18` | `lever` | 3 | `lever_gate` | `gate_align` | ok (5.7 s) | 100 % | 100 % | 11.8 | 100 % | 100 % |
| 16 | `practice.t14` | `pin_tumbler` | 3 | `narrow_window` | `set` | ok (6.9 s) | 100 % | 100 % | 14.9 | 100 % | 100 % |
| 17 | `practice.t16` | `wafer` | 3 | `multi_binding` | `bind` | ok (8.0 s) | 100 % | 100 % | 15.3 | 100 % | 100 % |
| 18 | `practice.t15` | `pin_tumbler` | 3 | `overset_recovery` | `overset` | ok (5.7 s) | 100 % | 100 % | 16.7 | 48.7 % | 2.7 % |
| 19 | `practice.t17` | `ring_combo` | 3 | `false_notch` | `false_set` | ok (8.1 s) | 88.4 % | 100 % | 23.8 | 47.1 % | 100 % |
| 20 | `practice.t22` | `lever` | 4 | `false_gate` | `lever.false_gate` | ok (6.9 s) | 100 % | 100 % | 12.5 | 100 % | 89.8 % |
| 21 | `practice.t20` | `pin_tumbler` | 4 | `false_set` | `false_set` | ok (8.2 s) | 100 % | 100 % | 15.7 | 100 % | 100 % |
| 22 | `practice.t24` | `lever` | 4 | `multiple_gates` | `gate_align` | ok (7.0 s) | 100 % | 100 % | 16.9 | 100 % | 100 % |
| 23 | `practice.t21` | `pin_tumbler` | 4 | `counter_rotation` | `counter_rotate` | ok (8.3 s) | 100 % | 100 % | 18.1 | 100 % | 100 % |
| 24 | `practice.t23` | `pin_tumbler` | 4 | `serration` | `pin.serration` | ok (8.3 s) | 100 % | 100 % | 20.8 | 100 % | 88 % |
| 25 | `practice.t27` | `lever_detector` | 5 | `detector_trip` | `detector_trip` | ok (8.3 s) | 99.6 % | 100 % | 17.9 | 75.4 % | 2.9 % |
| 26 | `practice.t28` | `lever_detector` | 5 | `detector_reset` | `detector.reset` | ok (8.4 s) | 99.4 % | 100 % | 20.5 | 52 % | 2.8 % |
| 27 | `practice.t26` | `lever` | 5 | `two_false_gates` | `lever.false_gate` | ok (9.9 s) | 100 % | 100 % | 22.1 | 100 % | 99.3 % |
| 28 | `practice.t25` | `pin_tumbler` | 5 | `mixed_security` | `false_set` | ok (9.8 s) | 100 % | 100 % | 25.3 | 100 % | 100 % |
| 29 | `practice.t30` | `lever_detector` | 6 | `detector_mastery` | `detector_trip` | ok (12.4 s) | 31.6 % | 100 % | 26.4 | 99.9 % | 2.5 % |
| 30 | `practice.t29` | `pin_tumbler` | 6 | `quiet_precision` | `set` | ok (9.4 s) | 99.9 % | 100 % | 26.4 | 100 % | 100 % |

`scripted` = scripted bot result and time; `clumsy` / `feel %` = success over 1000 bot seeds;
`median s` = feeling-bot median time of the successful runs; `target clumsy` / `target feel` =
share of runs (successful or not) in which the event named by `lesson_target` occurred.

### lesson_target (D-54)

`presentation.practice.lesson_target` names the event the lesson is about: a base event kind
(`set`, `false_set`, `overset`, `detector_trip`, …) or a family sub-event (`ring.detent`,
`pin.serration`, `lever.false_gate`, `detector.reset`). Like the rest of `presentation.practice`,
lockcore ignores it and `lock_to_json()` does not write it (test `lockfile: presentation.practice.lesson_target …`);
at the root of the file it would be an ignored key and fail the format check (ctest
`check_locks_rejects_root_target`). `check_locks` gates every file that has one: the name must be
a known event of the family (`check_locks_rejects_bad_target`), the **clumsy bot must meet it in
≥ 30 %** of runs and the **feeling bot must open ≥ 95 %**. ctest `practice_locks` runs 200 bot seeds.

The feeling bot (a careful player) rarely oversets or trips a detector (2–6 %); the clumsy bot
(rough hands, no overset knowledge) does, so these lessons can be met by a player who tries — the
goal text asks for it once (`practice.<id>.goal` in `game/i18n/strings.csv`, PL / EN / DE).

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

## T38 adoption (D-54)

ChatGPT delivery T38 proposed a new order, `lesson_target` for every file and parameter changes
for seven lessons, none of it run. Checked with `check_locks --feel 1000`:

| lesson | T38 proposal | measured | adopted |
|---|---|---|---|
| order | one global order by median time, tiers interleaved, ids renumbered | median rises globally, but tier 5–6 lessons before tier 3 and same-family lessons out of lesson order | **modified**: tier order kept, sorted by median inside each tier; ids kept, only `order` changes |
| `lesson_target` | 30 names under `presentation.practice` | all known events of their family | **accepted** |
| `t07`, `t08`, `t15` overset | `overset_margin` 0.05 / 0.045 / 0.05 | clumsy overset **0 %** in all three: with a 0.11–0.125 window the clumsy bot slows near the line and stops 250 ms after the set click, well below window + margin | **modified**: window 0.07 and margin 0.055 (the narrowest `pin_tumbler` t7 values, D-34; below the `wafer` table, deliberately, for these three lessons only): clumsy overset 39 / 54 / 49 %, feeling 100 %, median ±0.3 s |
| `t17` false notch (no T38 change) | target `false_set` | clumsy 0 %: the plan spins each ring loose and binds one digit before the gate, never over a notch | **tuned**: ring 2 notch digit 0 → 4 (on the spin path) and `band_lo` 0.225 → 0.16 (free-spin band 0.08 = δ_human; below the generator range 0.22–0.26, for this ring only): a rough pull binds the ring mid-spin and the notch catches it, clumsy 47 % (opens 88 %), feeling caught 100 %, median unchanged |
| `t22` false gate | false gate 0.36 on lever 0 too | feeling caught 62 → 90 %, clumsy 100 %, median +0.1 s | **accepted** |
| `t25` tier 5 | 6 stacks, t5 table window / band / margin / noise / grace | 19.9 s, still below tier 4 (21.1 s): binding order was the index order, which the probe sweep finds at once | **accepted + tuned**: binding order scrambled (stacks 1, 3, 5, 0, 4, 2): **25.3 s** |
| `t27` detector trip | window 0.09, detector 0.093 | clumsy trip 21 % | **modified**: window 0.09 (T38), overset 0.09 → 0.08, detector 0.083 (t6 table values; overset < detector as rules 2 demand): clumsy 75 % (opens 99.6 %) |
| `t28` detector reset | detector 0.09, reset 1.25 s | clumsy reset 13 %; 1.25 s is no table value | **modified**: overset 0.08, detector 0.083, reset 1.5 s kept; binding order scrambled (levers 1, 2, 4, 0, 3) so the reset lesson comes after the trip lesson: clumsy reset 52 %, 20.5 s |
| `t30` detector mastery | detector 0.082, reset 2 s, 4 trips | the unchanged file already meets the gate (clumsy trip 99.9 %); the change made it easier (clumsy opens 32 → 64 %) and 4 trips is outside the rules | **rejected** |
| `t20` false set (no T38 change) | — | 21.1 s, slower than the later spool lessons `t21` / `t23` | **tuned**: binding order = index order (it is the spool intro): 15.7 s, so false set → counter-rotation → serration keeps its lesson order |

Other inversions (`t06` < `t05`, `t10` < `t09`, `t19` < `t18`, `t30` < `t29` by 5 steps) are fixed by the
order, not by parameters. Golden replays are untouched (no rules change).
