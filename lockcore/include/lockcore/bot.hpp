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
};

// A less careful player for soft metrics and golden replays that exercise
// overset / drop paths: more tremor, faster lifting, 250 ms reaction.
HumanLimits clumsy_human_limits();

// Human precision assumed by the oracle (LOCKS.md §1.7, §1.9).
inline constexpr q16 HUMAN_TENSION_BAND = q16_milli(80);   // delta_human
inline constexpr q16 HUMAN_POSITION_PRECISION = q16_milli(30);
inline constexpr q16 BOT_MAX_STRESS = q16_milli(800);      // S must stay < 0.8 S_max

SolveReport run_plan_bot(const FamilyModule& family, const LockSpec& spec, const ToolSet& tools,
                         const Plan& plan, const HumanLimits& limits, std::int64_t budget_steps,
                         const SolveOptions& opt);

}  // namespace lockcore
