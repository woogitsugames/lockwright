// Difficulty vector (LOCKS.md §1.8). A tier selects one vector per family; the
// generator draws concrete parameters from it.
#pragma once

#include <cstdint>

#include "lockcore/fixed.hpp"

namespace lockcore {

struct DifficultyVector {
  std::int32_t tier = 0;
  // Complexity
  std::int32_t n_min = 3, n_max = 3;      // element count range
  std::int32_t sec_min = 0, sec_max = 0;  // security elements range
  // Precision
  q16 win_shear = 0;       // set window, fraction of element travel
  q16 tension_band = 0;    // width of the working tension band
  q16 overset_margin = 0;  // headroom above the window before overset
  // Readability
  q16 noise = 0;  // spurious contact probability scale
  // Order
  q16 bind_spread = Q16_ONE;  // 1.0 = binding offsets clearly distinct
  q16 multi_bind_p = 0;       // probability that two elements bind together
  // Resources
  std::int32_t drop_grace_ms = 300;
  q16 s_max = Q16_ONE;              // tool stress capacity
  std::int32_t time_limit_s = 60;   // human time budget of the tier (bot gets half)

  friend bool operator==(const DifficultyVector&, const DifficultyVector&) = default;
};

}  // namespace lockcore
