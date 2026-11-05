// Dial safe with a wheel pack (D-59, docs/research/new-families.md §1,
// docs/LOCKS.md §2.18). An invented, encyclopedic-level game variant: the dial
// drives a pack of wheels through drive pins with half a turn of lost motion on
// each side; a wheel that is carried shows the dial's number. With the handle
// pressed inside the listening band, the gate of the last picked-up wheel is
// heard as it passes under the fence. Leave each wheel on its gate by reversing
// the dial, then turn to the opening mark and press the handle. No tool breaks.
//
// Inputs: tension = handle / listening pressure (band), pick_lift = dial turn
// speed and direction (+ = right), pick_depth unused (any value).
#pragma once

#include <memory>
#include <vector>

#include "lockcore/family.hpp"

namespace lockcore::dial {

inline constexpr std::string_view FAMILY_ID = "dial_safe";
inline constexpr std::int32_t RULES_VERSION = 1;

enum Sub : std::uint16_t {
  SUB_DETENT = 1,        // "safe.detent", base contact: one click per dial division
  SUB_PICKUP = 2,        // "safe.pickup", base bind: a wheel joins the carried pack
  SUB_FENCE_DROP = 3,    // "safe.fence_drop", base set: every gate aligned, fence drops into the cam
  SUB_FENCE_BOUNCE = 4,  // "safe.fence_bounce", base contact: handle pressed on the mark, fence held up
};

struct Wheel {
  std::int32_t gate = 0;   // dial number that leaves this wheel's gate under the fence
  std::int32_t start = 0;  // number the wheel shows when the safe is handed over
  std::vector<std::int32_t> false_gates;  // numbers of shallow false notches
};

struct Params : FamilyParams {
  std::vector<Wheel> wheels;  // wheel 0 is farthest from the dial (set first)
  std::int32_t divisions = 20;
  std::int32_t dial_start = 0;
  std::int32_t open_mark = 0;  // dial number of the cam notch
  q16 gate_win = 0;            // full gate window, fraction of a turn
  q16 band_lo = 0;             // listening band: the fence touches the wheels
  q16 band_hi = 0;             // above it the pack clamps (dial stiff)
  std::int32_t open_hold_steps = 0;
  q16 gate_feel = 0;   // fb_gain: intensity scale of near / gate / set
  q16 rot_speed = 0;   // turn per step at |pick_lift| = 1
  q16 snap_speed = 0;  // detent pull toward the nearest division when not turned

  q16 digit_pos(std::int32_t d) const {
    return static_cast<q16>((static_cast<std::int64_t>(d) * Q16_ONE) / divisions);
  }
  q16 division() const { return divisions > 0 ? Q16_ONE / divisions : Q16_ONE; }
};

inline constexpr q16 LOST_MOTION = Q16_ONE / 2;      // slack on each side of a drive pin
inline constexpr q16 LIFT_DEADZONE = Q16_ONE / 16;   // |pick_lift| below this = dial let go
inline constexpr q16 ROT_SPEED = q16_per_step(q16_milli(800));
inline constexpr q16 SNAP_SPEED = q16_per_step(q16_milli(400));
inline constexpr std::int32_t OPEN_HOLD_STEPS = 36;   // 0.3 s of handle after the fence drops
inline constexpr std::int32_t PICKUP_QUIET_STEPS = 24;  // a wheel resting this long clicks again
inline constexpr q16 GATE_MARGIN = Q16_ONE / 5;       // consecutive numbers differ by >= 1/5 turn

std::unique_ptr<FamilyModule> make_module();

}  // namespace lockcore::dial
