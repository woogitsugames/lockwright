// Wooden pin bolt (LOCKS.md §2.1): the tutorial family. A wooden bolt is pulled
// sideways (tension) while pegs dropping from the housing are lifted one by one.
#pragma once

#include <memory>
#include <vector>

#include "lockcore/family.hpp"

namespace lockcore::wooden {

inline constexpr std::string_view FAMILY_ID = "wooden_pin";
inline constexpr std::int32_t RULES_VERSION = 1;
// v0.6 (D-59): "ancient" pin bolt (LOCKS.md §2.22), the same module with a flag:
// pegs fall by gravity (no spring), tiers 1-2, longer bolt slide.
inline constexpr std::string_view EGYPT_FAMILY_ID = "egyptian";
inline constexpr std::int32_t EGYPT_RULES_VERSION = 1;

enum Sub : std::uint16_t {
  SUB_CREAK = 1,  // "wood.creak", base kind stress: hard pull; the tool never breaks
};

struct Peg {
  q16 target = 0;   // centre of the set window (housing edge)
  q16 order = 0;    // binding offset: lowest unset binds first
  q16 band_lo = 0;  // binds at T >= band_lo
};

struct Params : FamilyParams {
  std::vector<Peg> pegs;
  q16 win_shear = 0;
  bool overset_enabled = true;  // false: tutorials 1-2 (LOCKS.md: "overset_margin = infinity")
  q16 overset_margin = 0;
  q16 tension_band = 0;
  q16 t_hold = 0;
  q16 t_release = 0;  // above t_hold: a jammed peg frees without dropping the others
  q16 tau_creak = 0;  // above this the bolt creaks (wood.creak)
  std::int32_t drop_grace_steps = 0;
  std::int32_t open_hold_steps = 0;  // all pegs set and T >= t_hold this long -> open
  q16 bound_speed = 0;
  q16 fall_speed = 0;  // egyptian: a free peg falls this much per step (0 = spring, at rest at once)

  q16 win_lo(const Peg& p) const { return p.target - win_shear / 2; }
  q16 win_hi(const Peg& p) const { return p.target + win_shear / 2; }
  q16 t_stick(const Peg& p) const { return p.band_lo + tension_band; }
};

inline constexpr q16 T_HOLD = q16_milli(100);
inline constexpr q16 T_RELEASE = q16_milli(200);
inline constexpr q16 T_BIND_BASE = q16_milli(240);
inline constexpr q16 T_BIND_JITTER = q16_milli(40);
inline constexpr q16 CREAK_MARGIN = q16_milli(60);
inline constexpr std::int32_t OPEN_HOLD_MS = 300;
inline constexpr q16 BOUND_SPEED = q16_per_step(q16_milli(1500));

inline constexpr q16 EGYPT_FALL_SPEED = q16_per_step(q16_milli(1200));
inline constexpr std::int32_t EGYPT_OPEN_HOLD_MS = 500;

std::unique_ptr<FamilyModule> make_module();
std::unique_ptr<FamilyModule> make_egyptian_module();  // egyptian, t1-t2

}  // namespace lockcore::wooden
