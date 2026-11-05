# Review T25 — outcome per finding

Source: `contrib/gpt/T25/REVIEW_LOCKCORE.md` (external static review, 24 findings, not run by
its author). Every claim was checked against the code before acting. API changes:
[`README.md`](README.md) "API changes / v0.5".

Gates after the fixes: ctest 13/13 green (Release, Clang, ASan + UBSan with
`-fno-sanitize-recover=undefined`, fuzz 100k steps per family included); `verify_seeds --seeds
1000`: scripted bot **0 failures** in every family and tier; all 13 golden replays give the
**same hashes, steps and open** as before (no regeneration: none of the fixes was a
determinism bug, each one only changes behaviour on input that was invalid or out of domain
before, or in a step that both opened and broke the tool, which no golden contains).

| # | Pri | Claim (short) | Verdict | Outcome |
|---|---|---|---|---|
| T25-01 | P1 | `step()` never checks the tools; `LockSession` with `ToolSet{}` simulates any family | **confirmed** | fixed in `ae318ed`: `LockSession` refuses a tool set without `required_tools(spec)` (`FailureKind::invalid_spec`, finished at t = 0); the two-argument constructor now uses the required tools. Test for all families with `ToolSet{0}` |
| T25-02 | P1 | `init_state()` casts an unvalidated parameter block (null / other family → UB) | **confirmed** | fixed in `ae318ed`: the session runs `validate()` (which `dynamic_cast`s) and checks the family id before `init_state()`; tests for missing params, params of another family, wrong id |
| T25-03 | P1 | `generate()` returns a refused lock after 16 attempts | **confirmed** (only for vectors outside the tier tables; 0 cases in the tables) | fixed in `ae318ed`: `run_replay()`, `replay_tool trace / lock / record` refuse a lock the oracle rejects; contract documented in `family.hpp`. Kept the return type (no exceptions in lockcore, every tier vector succeeds). Test with `win_shear = 0` |
| T25-04 | P1 | replay seed parsed without digit / overflow / empty checks | **confirmed** | fixed in `db9babd`: same strict `field::parse_u64()` as lock files |
| T25-05 | P1 | `as_int() * 256` can overflow int64 (UB) | **confirmed** | fixed in `db9babd`: ranges checked before scaling |
| T25-06 | P1 | RLE without a total frame limit (OOM) | **confirmed** | fixed in `db9babd`: `MAX_REPLAY_STEPS` = 3600 s × 120 over all runs (longest time limit a difficulty vector accepts) |
| T25-07 | P2 | axes / tool not range-checked; `tool = 256` wraps to 0 | **confirmed** | fixed in `db9babd`: per-axis ranges, tool 0..255, canonical inputs only (`quantize(f) == f`, push on its 1/64 grid) |
| T25-08 | P1 | `difficulty`, `expected`, `input_unit`, `input_fields` optional; `out` filled during parsing | **confirmed** | fixed in `db9babd`: all required; parse into a temporary, assign on success. Test that `out` stays untouched |
| T25-09 | P1 | `replay_tool play` compares only the hash | **confirmed** | fixed in `53857ee`: `play` and `trace` compare hash, steps and open and name the field; ctest `replay_tool_play_bad_steps` |
| T25-10 | P1 | `verify_seeds --seeds 0` / negative / text passes | **confirmed** | fixed in `53857ee`: strict integers, `--seeds >= 1`; ctest (WILL_FAIL) |
| T25-11 | P1 | unknown `--family` / `--tier 999` passes with nothing run | **confirmed** | fixed in `53857ee`: exit 2; ctest (WILL_FAIL) |
| T25-12 | P2 | seed sample masked to 48 bits | **rejected** (test added in `32df0b7`) | the seed only enters the simulation through `derive_seed()` (SplitMix / FNV mixing), so the upper 16 bits open no other code path; widening would change the A3 seed set and invalidate every number in `BALANCE.md` for no coverage gain. The real 64-bit risk (string serialisation, JS/Godot precision) is now tested: lock-file round trip, oracle and scripted bot for seeds `2^64-1`, `2^63+1`, `0xffff…0000` in every family, and replay seed `18446744073709551615` |
| T25-13 | P2 | verifier replay check does not round-trip `expected` | **confirmed** | fixed in `53857ee`: expected hash / steps / open written, parsed back and compared, plus steps of the replayed run |
| T25-14 | P1 | feeling bot skips validation and the tool check | **confirmed** (warded / ring_combo let it through on any oracle refusal) | fixed in `ae318ed`: `run_bot()` (base and both overrides) checks `session_input_error()` for all three bots; the feeling bot still skips only the oracle gate. Test for all families and bots |
| T25-15 | P1 | detector reset calls `set_wear()` → `init()` and wipes the peak stress | **confirmed** | fixed in `7a27d4b`: `ToolStress::add_wear()` (keeps S, peak, wear accumulator, stress timer); the `lever_detector` golden with a reset keeps its hash. Unit test |
| T25-16 | P2 | one step can end both `open` and `break` | **confirmed** (pin_tumbler, wafer, lever, warded incl. its bend limit) | fixed in `7a27d4b`: rule **open wins** — `end_step(..., can_break = !open)`; chosen over "break first" because it keeps the event order (open before stress / wear) and so every golden hash. Fuzz invariant: never open and failed at once |
| T25-17 | P1 | `q16_ratio`: overflow, division by zero | **partly** (all call sites use small constants; the public helper had no domain) | fixed in `c90362f`: den 0 → 0, saturating, in-range results unchanged; boundary tests |
| T25-18 | P2 | `ToolStress::ratio()` narrows before clamping | **confirmed** (S_max can be 1 via `s_max_q16 = 1`) | fixed in `c90362f`: clamp before dividing; `q_div` saturates. Test with S_max = 1 |
| T25-19 | P2 | `q_abs(INT32_MIN)` UB | **confirmed** (unreachable from clamped inputs) | fixed in `c90362f`: saturates to `INT32_MAX` |
| T25-20 | P2 | `quantize_256` overflows at the int32 ends | **confirmed** (unreachable through `quantize()`) | fixed in `c90362f`: int64 and clamp to the largest multiple of 1/256 |
| T25-21 | P2 | `ms_to_steps` multiplies in int32 | **confirmed** (lock files allow ≤ 10 000 ms, so not reachable today) | fixed in `c90362f`: int64 |
| T25-22 | P1 | `Pcg32::range` overflows for wide spans | **confirmed** (all call sites use narrow ranges) | fixed in `c90362f`: span in uint32, full range via `next()`; the sequence for ordinary ranges is bit-identical (test) |
| T25-23 | P2 | lone low surrogate accepted; raw UTF-8 not validated | **confirmed** | fixed in `94ccdad`: both rejected (overlong, surrogates, > U+10FFFF, truncated, stray bytes); tests |
| T25-24 | P3 | output file open / write errors ignored | **confirmed** | fixed in `53857ee`: `verify_seeds --csv` exit 2, `replay_tool record / trace` exit 1; ctest |

Summary: 23 confirmed and fixed (T25-17 only partly a real risk, fixed anyway), 1 rejected
(T25-12, with a test for the underlying 64-bit concern). No P0 findings in the review; no golden
regenerated.
