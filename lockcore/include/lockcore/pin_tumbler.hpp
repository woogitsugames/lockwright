// Pin tumbler family (LOCKS.md §2.6). Exposed so tests and tools can author specs.
#pragma once

#include <memory>
#include <vector>

#include "lockcore/family.hpp"

namespace lockcore::pin {

inline constexpr std::string_view FAMILY_ID = "pin_tumbler";
inline constexpr std::int32_t RULES_VERSION = 1;
// v0.6 (D-59): dimple cylinder, the same module with a flag (LOCKS.md §2.20).
inline constexpr std::string_view DIMPLE_FAMILY_ID = "dimple";
inline constexpr std::int32_t DIMPLE_RULES_VERSION = 1;
inline constexpr std::uint8_t DIMPLE_SIDE_ROW = 16;  // ElementView::variant bit: pin in the side row

enum class Variant : std::uint8_t { standard, spool, serrated, spool_serrated };
std::string_view variant_name(Variant v);

// Family sub-events (LockEvent::sub).
enum Sub : std::uint16_t {
  SUB_SERRATION = 1,      // "pin.serration", base kind false_set, intensity 0.3
  SUB_SPRING_BOUNCE = 2,  // "pin.spring_bounce", base kind contact
};

struct Stack {
  q16 target = 0;     // centre of the shear window (fraction of travel)
  q16 order = 0;      // binding offset o_i: lowest unset binds first
  q16 band_lo = 0;    // binds at T >= band_lo; moves while T <= band_lo + tension_band
  Variant variant = Variant::standard;
  q16 false_gate = 0;            // spool: height of the false set
  std::vector<q16> serrations;   // serrated: micro-ledges below the window
  bool has_spool() const { return variant == Variant::spool || variant == Variant::spool_serrated; }
};

struct Params : FamilyParams {
  std::vector<Stack> stacks;
  q16 win_shear = 0;
  q16 overset_margin = 0;
  q16 tension_band = 0;
  q16 t_hold = 0;
  q16 t_release = 0;
  q16 tau_safe = 0;
  q16 cr_lo = 0;  // counter-rotation band for spools
  q16 cr_hi = 0;
  std::int32_t drop_grace_steps = 0;
  bool drop_all = true;
  q16 s_max = Q16_ONE;
  q16 stress_gain = 0;
  q16 noise = 0;
  q16 bound_speed = 0;  // per step
  q16 spool_speed = 0;  // per step

  q16 win_lo(const Stack& s) const { return s.target - win_shear / 2; }
  q16 win_hi(const Stack& s) const { return s.target + win_shear / 2; }
  q16 t_stick(const Stack& s) const { return s.band_lo + tension_band; }
};

// Generator constants (documented in lockcore/README.md).
inline constexpr q16 T_HOLD = q16_milli(100);
inline constexpr q16 T_RELEASE = q16_milli(50);
inline constexpr q16 T_BIND_BASE = q16_milli(200);
inline constexpr q16 T_BIND_JITTER = q16_milli(50);
inline constexpr q16 TAU_SAFE_MARGIN = q16_milli(60);
inline constexpr q16 CR_LO = q16_milli(120);
inline constexpr q16 CR_HI = q16_milli(210);
inline constexpr q16 STRESS_GAIN = q16_milli(95);
inline constexpr q16 BOUND_SPEED = q16_per_step(2 * Q16_ONE);
inline constexpr q16 SPOOL_SPEED = q16_per_step(q16_milli(600));

std::unique_ptr<FamilyModule> make_module();
std::unique_ptr<FamilyModule> make_dimple_module();  // dimple, t1-t3

}  // namespace lockcore::pin
