# lockcore balance (v0.3, D-34)

> **D-116 (2026-11-12):** two rows below are superseded — `lever_detector` t6 (clumsy 42.5 % → 75.4 %) and
> `dimple` t3 (clumsy drops 1.72 → 0.89 per lock). See [D-116](#d-116-difficulty-curve-audit-2026-11-12) at the
> end; the full current tables per family, tier and chapter are in
> [`docs/research/difficulty-curve-2026-11.md`](../docs/research/difficulty-curve-2026-11.md).

`verify_seeds --seeds 10000` (all bots on every seed), 2026-11-05. Scripted bot (hard gate):
**0 failures** in every family and tier. Feeling bot = events and continuous signals only, budget =
tier time limit. Clumsy bot = oracle plan with tremor ±0.06, fast lifting, 250 ms reaction and no
overset knowledge. Times are medians of the successful runs.

| family | tier | feel ok | feel p50 | clumsy ok | clumsy p50 |
|---|---|---|---|---|---|
| `pin_tumbler` | t2 | 99.99 % | 10.9 s | 100 % | 2.9 s |
| | t3 | 100 % | 15.4 s | 100 % | 3.8 s |
| | t4 | 99.98 % | 19.9 s | 99.99 % | 5.0 s |
| | t5 | 99.99 % | 22.2 s | 99.93 % | 14.0 s |
| | t6 | 100 % | 24.6 s | 93.7 % | 33.1 s |
| | t7 | 99.94 % | 27.4 s | 36.0 % | 56.9 s |
| `wafer` | t1 | 100 % | 12.0 s | 100 % | 3.1 s |
| | t2 | 99.96 % | 16.8 s | 100 % | 3.9 s |
| | t3 | 99.98 % | 21.9 s | 100 % | 4.7 s |
| `wooden_pin` | t1 | 100 % | 16.2 s | 100 % | 3.7 s |
| `warded` | t1 | 99.96 % | 14.6 s | 100 % | 2.3 s |
| | t2 | 99.90 % | 18.8 s | 100 % | 2.5 s |
| `lever` | t3 | 100 % | 12.5 s | 100 % | 3.0 s |
| | t4 | 100 % | 17.6 s | 100 % | 4.7 s |
| | t5 | 100 % | 23.4 s | 99.99 % | 12.1 s |
| `lever_detector` | t5 | 99.97 % | 23.2 s | 99.87 % | 11.3 s |
| | t6 | 99.96 % | 29.1 s | 42.5 % | 21.9 s |
| `ring_combo` | t2 | 100 % | 24.7 s | 100 % | 6.4 s |
| | t3 | 100 % | 33.8 s | 100 % | 8.2 s |

## Reading the table

- **Monotonic per family:** the feeling bot's median time rises strictly with the tier in every
  family; clumsy success never rises and clumsy time rises. Feeling-bot success is saturated
  (99.9–100 %): differences of 1–4 seeds in 10 000 (pin t2 vs t3, t5 vs t6, wafer t2 vs t3) are
  below the binomial noise (σ ≈ 0.02 pp at 99.97 %) and count as ties.
- Since v0.3 feeling-bot success says "a player who reads the signals can open it"; difficulty
  shows in its **time** and in the **clumsy bot** (how forgiving a tier is to rough hands).
- Top tiers are hard but not walls: clumsy `pin_tumbler` t7 36 % (t6 94 %), `lever_detector` t6
  42 % (t5 99.9 %).

## Before v0.3 (same seeds)

| family | tier | feel ok | feel p50 | clumsy ok | clumsy p50 |
|---|---|---|---|---|---|
| `pin_tumbler` | t2 / t3 / t4 / t5 / t6 / t7 | 98.0 / 99.9 / 99.2 / 99.1 / 98.8 / 98.1 % | 12.2 / 17.1 / 21.7 / **21.4** / 26.7 / 29.6 s | 100 / 100 / 99.9 / 99.9 / 93.6 / **24.2** % | 2.9 / 3.8 / 5.0 / 12.6 / 33.1 / 56.2 s |
| `wafer` | t1 / t2 / t3 | 97.6 / 96.5 / 95.2 % | 13.3 / 18.2 / 23.3 s | 100 % | 3.1 / 3.9 / 4.7 s |
| `wooden_pin` | t1 | 97.9 % | 17.6 s | 100 % | 3.7 s |
| `warded` | t1 / t2 | 99.9 / 99.9 % | 14.6 / 18.8 s | 100 % | 2.3 / 2.5 s |
| `lever` | t3 / t4 / t5 | 100 / **90.3** / 94.6 % | 13.6 / 18.6 / 24.7 s | 100 / 99.9 / 97.8 % | 3.0 / 11.2 / 36.9 s |
| `lever_detector` | t5 / t6 | 94.4 / **75.5** % | 24.5 / 29.9 s | 16.0 / **0.0** % | 23.2 / – s |
| `ring_combo` | t2 / t3 | 100 / 100 % | 24.7 / 33.8 s | 100 % | 6.4 / 8.2 s |

## What changed and why (D-34)

1. **Feeling bot fixes** (`run_feel_bot`, report-only bot; goldens replay inputs, so unchanged).
   Every failure analysed in lever t4 and detector t6 was a stuck loop that ran out the budget, not
   a hard lock:
   - an element caught in a false gate was forgotten after a 3 s spool timeout; the bot then
     probed *below* it, felt nothing and cycled the tension for the rest of the budget
     (lever t4: all 9.7 % of failures). It now keeps working the caught element, and it also
     reacts to a catch it perceives 220 ms late, after the probe has moved on;
   - a probe left a bound element at its own height (+ tremor), where the next probe to the same
     height pushed it along without ever reaching the drag threshold 0.03 (pin t2: 2 %). The
     threshold is now 0.01 (free elements have no drag at all) and each empty sweep probes 0.05
     higher, up to 0.37.
2. **`lever` / `lever_detector` rules 2.** A set lever follows the lifter above its gate at most
   0.6/s (`Params::set_speed`). Before, a lever leaving a false gate jumped in one step to the
   lifter, which had run ahead while the lever was caught — straight over the overset /
   detector line. That, not the reset cost, caused the detector failures (clumsy bot: 100 % of
   its t6 failures). Detector margin t5 12 % → 10 %, t6 6 % → 8.3 % (t6 margin is now above the
   overset margin 8 %, so an overset warns before the detector trips — the card's S3 lesson).
   Reset time (1.5 s / 2.5 s), wear and 3 trips stay. Lever t4 < t5 was the bot bug only.
3. **`pin_tumbler` tier table** (difficulty vector; goldens store it, so unchanged): t5 has 5–6
   stacks (was 5; the feeling bot opened t5 faster than t4), t7 overset margin 5.5 % (was 5 %;
   clumsy 24 % → 36 %, every t7 parameter still strictly harder than t6).

Reproduce: `lockcore/build/verify_seeds --seeds 10000` (~2.5 min on 1 core; `--family` splits it).

## v0.6: D-59 families (1000 seeds per tier, 2026-11-05)

`verify_seeds --seeds 1000` (all bots). Scripted bot: **0 failures** in every new family and tier.
The clumsy bot is a weak signal for these families (most of them have no overset to stumble into);
the feeling bot's time is the calibration figure. 10 000-seed numbers come from the nightly CI run.

| family | tier | scripted p50 | feel ok | feel p50 | feel p90 | clumsy ok |
|---|---|---|---|---|---|---|
| `dial_safe` | t1 | 10.7 s | 100 % | 9.3 s | 14.5 s | 100 % |
| | t2 | 15.3 s | 100 % | 20.1 s | 23.0 s | 100 % |
| | t3 | 19.5 s | 100 % | 32.4 s | 38.9 s | 100 % |
| `combo` | t1 | 7.9 s | 100 % | 20.6 s | 28.1 s | 100 % |
| | t2 | 9.0 s | 100 % | 24.7 s | 35.1 s | 100 % |
| | t3 | 10.4 s | 100 % | 29.2 s | 37.7 s | 100 % |
| | t4 | 11.5 s | 100 % | 34.0 s | 45.5 s | 100 % |
| `dimple` | t1 | 7.6 s | 100 % | 15.4 s | 18.6 s | 100 % |
| | t2 | 7.5 s | 100 % | 17.8 s | 23.1 s | 100 % |
| | t3 | 8.8 s | 100 % | 22.7 s | 28.7 s | 100 % |
| `disc_detainer` | t1 | 10.8 s | 100 % | 28.5 s | 37.5 s | 100 % |
| | t2 | 13.5 s | 100 % | 39.2 s | 49.3 s | 100 % |
| | t3 | 14.6 s | 100 % | 45.0 s | 57.4 s | 100 % |
| `egyptian` | t1 | 6.9 s | 100 % | 13.5 s | 16.3 s | 100 % |
| | t2 | 9.7 s | 100 % | 22.1 s | 27.6 s | 100 % |
| `axial_slider` | t1 | 7.6 s | 100 % | 17.6 s | 21.1 s | 100 % |
| | t2 | 8.8 s | 100 % | 22.9 s | 28.0 s | 100 % |
| | t3 | 10.6 s | 100 % | 28.3 s | 35.0 s | 100 % |
| `time_lock` | t1 | 7.5 s | 100 % | 12.9 s | 14.3 s | 100 % |
| | t2 | 11.3 s | 100 % | 18.6 s | 22.3 s | 100 % |
| `magnetic` | t1 | 5.6 s | 100 % | 10.8 s | 13.1 s | 100 % |
| | t2 | 7.0 s | 100 % | 15.4 s | 18.5 s | 100 % |

Open calibration point: every new family is at 100 % for the feeling bot, so the tiers are separated
only by time. Human playtests should decide whether t2/t3 need narrower windows or more false notches.

## D-116: difficulty-curve audit (2026-11-12)

`verify_seeds --seeds 10000`, all bots on every seed, scripted gate 0 failures in all 41 family × tier rows.
The audit read the tables against the chapters that use each tier (`game/data/jobs`) and changed two numbers
in the tier tables. Rules, generators and `rules_version` are untouched, so every golden replay keeps its hash
(a replay carries its own difficulty vector).

| family | tier | parameter | was | now |
|---|---|---|---|---|
| `dimple` | t3 | `drop_grace_ms` | 220 | 250 (same as t2) |
| `lever_detector` | t6 | gate window (`win_shear`) | 0.080 | 0.085 |

| family | tier | bot | before | after |
|---|---|---|---|---|
| `dimple` | t3 | clumsy | 100 %, p50 18.1 s, p90 30.7 s, drops 1.72, oversets 3.04 per lock | 100 %, p50 15.5 s, p90 24.9 s, drops 0.89, oversets 3.03 |
| | | feeling | 99.96 %, p50 22.4 s, p90 28.2 s | 99.96 %, p50 22.4 s, p90 28.3 s |
| `lever_detector` | t6 | clumsy | 42.4 %, p50 21.9 s, 5755 blocked locks | 75.4 %, p50 20.2 s, 2458 blocked locks |
| | | feeling | 99.96 %, p50 29.1 s, p90 36.7 s | 99.95 %, p50 29.1 s, p90 36.5 s |

Why these two:

- **`lever_detector` t5 → t6** was the largest cliff in the data (clumsy 99.9 % → 42 %, feeling bot unchanged)
  and a threshold, not a slope: a set lever follows the lifter at 0.6/s, 250 ms of reaction is 0.15 of travel plus
  tremor, and the t6 headroom (gate 0.08 + detector margin 0.083) was 0.163. Gate width alone moves the clumsy bot
  42 % (0.080) → 64 % (0.083) → 75 % (0.085) → 86 % (0.087) → 93.5 % (0.090, the t5 value). 0.085 keeps every t6
  parameter at or below t5 and leaves the detector margin above the overset margin (D-34).
- **`dimple` t3** (chapter 10) was rougher for the clumsy bot than `pin_tumbler` t5 (chapter 12; 14.0 s, 1.67
  drops, 2.44 oversets) while its chapter neighbours sit at 3–10 s and 0 drops. Every dimple security pin is
  telescoping (spool rule), t3 has 1–2 of them, and the generator's "drop every stack" rule starts at tier 3. With
  220 ms of grace an overset fix (tension below `t_release`) always cost the whole lock for a hand that reacts in
  250 ms. 250 ms halves the drops; the feeling bot is unchanged, so the tier is not easier for a careful player.

Left alone on purpose: `pin_tumbler` t7 (clumsy 36 %, not used by any job or by the endless run), the wafer time
limit (flat 60 s; raising it changed no result and the game does not enforce it), and the 28 rows where the
clumsy bot pays nothing at all — there the bots cannot say which way to tune (neither bot over-tensions: 0 clumsy
breaks in 410 000 runs). Chapter-level outliers that need a content decision (`lever_detector` t5 in chapter 5,
job tiers outside the family range, `disc_detainer` times) are listed in the research note, §6.

New in the `verify_seeds` report and CSV (appended columns): false sets and oversets per lock for both soft bots,
clumsy p90, failure reasons (time-outs, tool at ≥ 0.8 S_max, blocked detector), exact success counts.
