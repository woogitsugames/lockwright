// Fixed-point arithmetic for the lock simulation.
//
// All simulation quantities are Q16 in int32 (65536 == 1.0). Products use an int64
// intermediate. No floating point is used anywhere in the simulation path, so the
// result is bit-identical on every platform and compiler (ARCHITECTURE.md §1, D-07).
#pragma once

#include <cstdint>

namespace lockcore {

using q16 = std::int32_t;

inline constexpr q16 Q16_ONE = 65536;
inline constexpr int SIM_HZ = 120;  // one step == 1/120 s

// Builds a Q16 constant from thousandths (q16_milli(120) == 0.120), rounded to nearest.
constexpr q16 q16_milli(std::int32_t milli) {
  const std::int64_t num = static_cast<std::int64_t>(milli) * Q16_ONE;
  return static_cast<q16>(num >= 0 ? (num + 500) / 1000 : (num - 500) / 1000);
}

// Builds a Q16 value from a ratio num/den, rounded toward zero.
constexpr q16 q16_ratio(std::int64_t num, std::int64_t den) {
  return static_cast<q16>((num * Q16_ONE) / den);
}

constexpr q16 q_mul(q16 a, q16 b) {
  // C++20 guarantees arithmetic right shift for negative values.
  return static_cast<q16>((static_cast<std::int64_t>(a) * b) >> 16);
}

constexpr q16 q_div(q16 a, q16 b) {
  return static_cast<q16>((static_cast<std::int64_t>(a) * Q16_ONE) / b);
}

constexpr q16 q_clamp(q16 v, q16 lo, q16 hi) { return v < lo ? lo : (v > hi ? hi : v); }
constexpr q16 q_min(q16 a, q16 b) { return a < b ? a : b; }
constexpr q16 q_max(q16 a, q16 b) { return a > b ? a : b; }
constexpr q16 q_abs(q16 a) { return a < 0 ? -a : a; }

// Per-second rate expressed as a per-step Q16 increment.
constexpr q16 q16_per_step(q16 per_second) { return per_second / SIM_HZ; }

// Milliseconds to whole simulation steps, rounded to nearest.
constexpr std::int32_t ms_to_steps(std::int32_t ms) { return (ms * SIM_HZ + 500) / 1000; }

// Input quantisation: every input axis is snapped to 1/256 (LOCKS.md §1.3).
inline constexpr q16 INPUT_QUANTUM = Q16_ONE / 256;
constexpr q16 quantize_256(q16 v) {
  const std::int32_t units = (v >= 0) ? (v + INPUT_QUANTUM / 2) / INPUT_QUANTUM
                                      : -((-v + INPUT_QUANTUM / 2) / INPUT_QUANTUM);
  return units * INPUT_QUANTUM;
}

}  // namespace lockcore
