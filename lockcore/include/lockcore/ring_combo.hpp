// Ring combination padlock (LOCKS.md §2.3). Rings with a gate notch turn on the
// shackle spindle; pulling the shackle (tension) makes one ring bind, and it
// drops into its gate when turned there. Deduction by feel: which ring resists,
// where it falls in. No tool breaks in this family.
#pragma once

#include <memory>
#include <vector>

#include "lockcore/family.hpp"

namespace lockcore::ring {

inline constexpr std::string_view FAMILY_ID = "ring_combo";
inline constexpr std::int32_t RULES_VERSION = 1;
// v0.6 (D-59): thumbwheel combination lock (bike cable lock, box latch). Same
// module with a flag: wheels spun by pick_lift (no rotate), tiers 1-4, and the
// sleeve slip: a bound wheel spun faster than slip_speed skips its notch.
inline constexpr std::string_view COMBO_FAMILY_ID = "combo";
inline constexpr std::int32_t COMBO_RULES_VERSION = 1;

enum Sub : std::uint16_t {
  SUB_DETENT = 1,  // "ring.detent" / "combo.detent", base kind contact: one click per digit
  SUB_SLIP = 2,    // "combo.slip", base kind overset: the sleeve slipped past its notch
};

struct Ring {
  std::int32_t gate = 0;   // digit of the true gate
  std::int32_t start = 0;  // digit shown when the lock is handed over
  q16 order = 0;           // binding offset
  q16 band_lo = 0;         // binds at T >= band_lo
  std::vector<std::int32_t> false_gates;  // digits of shallow false notches
};

struct Params : FamilyParams {
  std::vector<Ring> rings;
  std::int32_t positions = 10;  // digits per ring
  q16 gate_win = 0;             // gate window, fraction of a full turn
  q16 tension_band = 0;         // a bound ring turns only while T <= band_lo + band
  q16 t_hold = 0;               // set rings stay while T >= t_hold
  std::int32_t drop_grace_steps = 0;
  q16 gate_feel = 0;            // fb_gain: intensity scale of near / gate / detent
  q16 rot_speed = 0;            // turn per step at rotate = 1 (free ring)
  q16 bound_rot_speed = 0;      // max turn per step of a bound ring
  q16 snap_speed = 0;           // detent pull toward the nearest digit when not turned
  q16 slip_speed = 0;           // combo: a bound wheel turned faster than this slips (0 = never)

  q16 digit_pos(std::int32_t d) const { return static_cast<q16>((static_cast<std::int64_t>(d) * Q16_ONE) / positions); }
  q16 t_stick(const Ring& r) const { return r.band_lo + tension_band; }
};

inline constexpr q16 T_HOLD = q16_milli(80);
inline constexpr q16 T_BIND_BASE = q16_milli(220);
inline constexpr q16 T_BIND_JITTER = q16_milli(40);
inline constexpr q16 GATE_WIN = q16_milli(60);
inline constexpr q16 ROT_SPEED = q16_per_step(q16_milli(500));
inline constexpr q16 BOUND_ROT_SPEED = q16_per_step(q16_milli(200));
inline constexpr q16 SNAP_SPEED = q16_per_step(q16_milli(400));

std::unique_ptr<FamilyModule> make_module();
std::unique_ptr<FamilyModule> make_combo_module();  // combo, t1-t4

}  // namespace lockcore::ring
