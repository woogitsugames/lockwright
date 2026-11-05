// Lever lock (LOCKS.md §2.7) and its detector variant (§2.8). One module class
// serves both families; `Params::detector` is the generator flag that adds the
// detector lever (detector_trip, rotate-back reset).
#pragma once

#include <memory>
#include <vector>

#include "lockcore/family.hpp"

namespace lockcore::lever {

inline constexpr std::string_view FAMILY_ID = "lever";
inline constexpr std::string_view DETECTOR_FAMILY_ID = "lever_detector";
inline constexpr std::int32_t RULES_VERSION = 2;  // 2: set_speed, D-32

enum Sub : std::uint16_t {
  SUB_FALSE_GATE = 1,      // "lever.false_gate", base kind false_set: second knock of the false gate
  SUB_DETECTOR_RESET = 2,  // "detector.reset", base kind drop: detector released, levers loose
};

struct Lever {
  q16 target = 0;   // centre of the gate (fraction of lever travel)
  q16 order = 0;    // binding offset
  q16 band_lo = 0;  // binds at T >= band_lo
  std::vector<q16> false_gates;  // notches below the gate, increasing
};

struct Params : FamilyParams {
  std::vector<Lever> levers;
  q16 win_gate = 0;
  q16 overset_margin = 0;
  q16 tension_band = 0;
  q16 t_hold = 0;
  q16 t_release = 0;  // below t_hold: fixing an overset costs a drop
  q16 tau_safe = 0;
  q16 cr_lo = 0;  // false gate: the lever rises only with T in [cr_lo, cr_hi]
  q16 cr_hi = 0;
  std::int32_t drop_grace_steps = 0;
  q16 s_max = Q16_ONE;
  q16 stress_gain = 0;
  q16 bound_speed = 0;   // per step
  q16 false_speed = 0;   // per step, inside a false gate
  q16 spring_speed = 0;  // per step: a bound lever falls back when the lifter drops
  // v0.3 (rules 2): per step, how fast a set lever follows the lifter above its gate
  // (the stump rubs in the gate). 0 = it jumps to the lifter at once (rules 1).
  q16 set_speed = 0;
  // Detector (lever_detector only).
  bool detector = false;
  q16 detector_margin = 0;          // trips when any lever rises above gate top + margin
  std::int32_t reset_steps = 0;     // T < t_hold and rotate <= -1/2 held this long
  std::int32_t max_trips = 3;       // the third trip blocks the lock (failure detector_trip)
  std::int32_t reset_wear = 2;      // tool wear points per reset

  q16 win_lo(const Lever& l) const { return l.target - win_gate / 2; }
  q16 win_hi(const Lever& l) const { return l.target + win_gate / 2; }
  q16 t_stick(const Lever& l) const { return l.band_lo + tension_band; }
  q16 detector_h(const Lever& l) const { return win_hi(l) + detector_margin; }
};

inline constexpr q16 T_HOLD = q16_milli(100);
inline constexpr q16 T_RELEASE = q16_milli(50);
inline constexpr q16 T_BIND_BASE = q16_milli(220);
inline constexpr q16 T_BIND_JITTER = q16_milli(50);
inline constexpr q16 TAU_SAFE_MARGIN = q16_milli(60);
inline constexpr q16 CR_LO = q16_milli(120);
inline constexpr q16 CR_HI = q16_milli(210);
inline constexpr q16 STRESS_GAIN = q16_milli(95);
inline constexpr q16 BOUND_SPEED = q16_per_step(q16_milli(1600));
inline constexpr q16 FALSE_SPEED = q16_per_step(q16_milli(600));

std::unique_ptr<FamilyModule> make_module();           // lever, t3-t5
std::unique_ptr<FamilyModule> make_detector_module();  // lever_detector, t5-t6

}  // namespace lockcore::lever
