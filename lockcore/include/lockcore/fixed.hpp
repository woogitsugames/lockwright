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

// Saturates an int64 to the int32 range (T25: no implementation-defined narrowing).
constexpr q16 q16_saturate(std::int64_t v) {
  return v > INT32_MAX ? INT32_MAX : (v < INT32_MIN ? INT32_MIN : static_cast<q16>(v));
}

// Builds a Q16 value from a ratio num/den, rounded toward zero. Total: den == 0
// gives 0, and a result outside int32 saturates (T25-17); every in-range call is
// unchanged.
constexpr q16 q16_ratio(std::int64_t num, std::int64_t den) {
  if (den == 0) return 0;
  constexpr std::int64_t lim = INT64_MAX / Q16_ONE;
  if (num > lim || num < -lim) {
    // num * 65536 would overflow int64: divide first. Outside the saturated range
    // |den| > 2^32 here, so den / 65536 != 0; the fraction is then exact to +-1.
    const std::int64_t q = num / den;
    if (q > INT32_MAX / Q16_ONE || q < INT32_MIN / Q16_ONE) return (q > 0) ? INT32_MAX : INT32_MIN;
    return q16_saturate(q * Q16_ONE + (num % den) / (den / Q16_ONE));
  }
  return q16_saturate((num * Q16_ONE) / den);
}

constexpr q16 q_mul(q16 a, q16 b) {
  // C++20 guarantees arithmetic right shift for negative values.
  return static_cast<q16>((static_cast<std::int64_t>(a) * b) >> 16);
}

// a / b in Q16; the caller guarantees b != 0. A quotient outside int32 saturates.
constexpr q16 q_div(q16 a, q16 b) {
  return q16_saturate((static_cast<std::int64_t>(a) * Q16_ONE) / b);
}

constexpr q16 q_clamp(q16 v, q16 lo, q16 hi) { return v < lo ? lo : (v > hi ? hi : v); }
constexpr q16 q_min(q16 a, q16 b) { return a < b ? a : b; }
constexpr q16 q_max(q16 a, q16 b) { return a > b ? a : b; }
// |a|; saturates at INT32_MAX for INT32_MIN (T25-19).
constexpr q16 q_abs(q16 a) { return a == INT32_MIN ? INT32_MAX : (a < 0 ? -a : a); }

// Per-second rate expressed as a per-step Q16 increment.
constexpr q16 q16_per_step(q16 per_second) { return per_second / SIM_HZ; }

// Milliseconds to whole simulation steps, rounded to nearest.
// Computed in int64 (T25-21); negative ms round toward zero like before.
constexpr std::int32_t ms_to_steps(std::int32_t ms) {
  return static_cast<std::int32_t>((static_cast<std::int64_t>(ms) * SIM_HZ + 500) / 1000);
}

// Input quantisation: every input axis is snapped to 1/256 (LOCKS.md §1.3).
inline constexpr q16 INPUT_QUANTUM = Q16_ONE / 256;
// Rounds half away from zero. Computed in int64 and clamped to the largest multiple
// of 1/256 that fits int32, so it is total over int32 (T25-20).
constexpr q16 quantize_256(q16 v) {
  const std::int64_t w = v;
  const std::int64_t units = (w >= 0) ? (w + INPUT_QUANTUM / 2) / INPUT_QUANTUM
                                      : -((-w + INPUT_QUANTUM / 2) / INPUT_QUANTUM);
  constexpr std::int64_t max_units = INT32_MAX / INPUT_QUANTUM;
  constexpr std::int64_t min_units = INT32_MIN / INPUT_QUANTUM;
  const std::int64_t u = units > max_units ? max_units : (units < min_units ? min_units : units);
  return static_cast<q16>(u * INPUT_QUANTUM);
}

}  // namespace lockcore
