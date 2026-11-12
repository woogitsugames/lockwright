// Scripted bot (verifier stage 2, LOCKS.md §1.9). It executes an oracle Plan
// through the real LockSession::step() under human limits: input noise, 1/256
// quantisation, rate limits, 180 ms reaction latency and 100 ms minimum dwell.
#pragma once

#include <cstdint>

#include "lockcore/family.hpp"

namespace lockcore {

struct HumanLimits {
  q16 tension_rate = q16_per_step(q16_milli(1500));  // 1.5 / s
  q16 lift_rate = q16_per_step(q16_milli(3000));     // 3 / s
  q16 depth_rate = q16_per_step(q16_milli(3000));    // 3 / s
  q16 slow_rate = q16_per_step(q16_milli(200));      // careful lift near the window
  q16 fine_rate = q16_per_step(q16_milli(200));      // after near_shear is felt
  bool adaptive = false;  // slow down by 1/4 after every perceived overset
  q16 spool_rate = q16_per_step(q16_milli(150));     // lift through a false gate
  std::int32_t latency_steps = ms_to_steps(180);
  std::int32_t min_hold_steps = ms_to_steps(100);
  std::int32_t noise_period_steps = 6;  // tremor changes every 50 ms
  q16 tension_noise = q16_milli(30);    // +- (human holds about +-0.04)
  q16 lift_noise = q16_milli(10);
  std::int32_t max_retries = 40;
  // Heavy hand (D-118, report only). The bot holds the plan's tension plus tension_over
  // and takes tension_ease off after every lift on one element that ended at the lift
  // cap with nothing felt (the element stuck). 0 = off: the other bots are unchanged.
  q16 tension_over = 0;
  q16 tension_ease = 0;
  // An open lock with the tool at >= BOT_MAX_STRESS counts as a failure (hard gate).
  // The heavy hand turns it off: it is there to measure stress, not to pass a gate.
  bool stress_gate = true;
};

// A less careful player for soft metrics and golden replays that exercise
// overset / drop paths: more tremor, faster lifting, 250 ms reaction.
HumanLimits clumsy_human_limits();

// The "heavy hand" (D-118): the clumsy player (who already lifts past the window, with no
// overset knowledge) who also pulls the tension wrench 0.20 too hard on every new element
// and never reacts to `stress`. It eases the wrench by 0.10 only after an element did not
// move. Soft metric for tool breakage (break rate, peak S / S_max per tier); never part
// of a gate.
inline constexpr q16 HEAVY_TENSION_OVER = q16_milli(200);
HumanLimits heavy_human_limits(q16 tension_over = HEAVY_TENSION_OVER);

// Human precision assumed by the oracle (LOCKS.md §1.7, §1.9).
inline constexpr q16 HUMAN_TENSION_BAND = q16_milli(80);   // delta_human
inline constexpr q16 HUMAN_POSITION_PRECISION = q16_milli(30);
inline constexpr q16 BOT_MAX_STRESS = q16_milli(800);      // S must stay < 0.8 S_max

// Runs an oracle plan through LockSession::step(). Since v0.2 it also handles a
// detector trip (families with AXIS_ROTATE in input_mask): release tension, turn
// the bolt back (rotate = -1) until the reset event, then start over.
SolveReport run_plan_bot(const FamilyModule& family, const LockSpec& spec, const ToolSet& tools,
                         const Plan& plan, const HumanLimits& limits, std::int64_t budget_steps,
                         const SolveOptions& opt);

// v0.2: verifier stage 3 ("feeling" / blind bot, LOCKS.md §1.9) for lift-based
// families. It knows only what a player in "dark" mode knows: the number of
// elements (they are drawn) and its own hand. Everything else comes from the
// events and the two continuous signals, delayed by the reaction latency. It
// searches the tension, probes elements for drag, lifts the bound one slowly and
// reacts to set / false_set / overset / drop / stress / detector_trip. Report only.
HumanLimits feeling_human_limits();
SolveReport run_feel_bot(const FamilyModule& family, const LockSpec& spec, const ToolSet& tools,
                         const HumanLimits& limits, std::int64_t budget_steps, const SolveOptions& opt);

// Shared by family bots: rate-limited approach of a hand axis.
constexpr q16 bot_approach(q16 cur, q16 target, q16 rate) {
  return cur < target ? (cur + rate < target ? cur + rate : target) : (cur - rate > target ? cur - rate : target);
}

}  // namespace lockcore
