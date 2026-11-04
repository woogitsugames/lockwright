// Wafer family (LOCKS.md §2.4). Second family, used to check that the interface
// and the shared components are family-independent.
#pragma once

#include <memory>
#include <vector>

#include "lockcore/family.hpp"

namespace lockcore::wafer {

inline constexpr std::string_view FAMILY_ID = "wafer";
inline constexpr std::int32_t RULES_VERSION = 1;

enum Sub : std::uint16_t {
  SUB_RATTLE = 1,  // "wafer.rattle", base kind contact
};

struct Wafer {
  q16 target = 0;
  q16 order = 0;
  q16 band_lo = 0;
};

struct Params : FamilyParams {
  std::vector<Wafer> wafers;
  q16 win_shear = 0;
  q16 overset_margin = 0;
  q16 tension_band = 0;
  q16 t_hold = 0;
  q16 t_release = 0;  // above t_hold: an overset wafer clears without a drop
  q16 tau_safe = 0;
  std::int32_t drop_grace_steps = 0;
  q16 s_max = Q16_ONE;
  q16 stress_gain = 0;
  q16 noise = 0;
  q16 bound_speed = 0;

  q16 win_lo(const Wafer& w) const { return w.target - win_shear / 2; }
  q16 win_hi(const Wafer& w) const { return w.target + win_shear / 2; }
  q16 t_stick(const Wafer& w) const { return w.band_lo + tension_band; }
};

inline constexpr q16 T_HOLD = q16_milli(80);
inline constexpr q16 T_RELEASE = q16_milli(160);
inline constexpr q16 T_BIND_BASE = q16_milli(220);
inline constexpr q16 T_BIND_JITTER = q16_milli(40);
inline constexpr q16 TAU_SAFE_MARGIN = q16_milli(60);
inline constexpr q16 STRESS_GAIN = q16_milli(95);
inline constexpr q16 BOUND_SPEED = q16_per_step(2 * Q16_ONE);

std::unique_ptr<FamilyModule> make_module();

}  // namespace lockcore::wafer
