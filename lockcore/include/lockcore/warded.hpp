// Warded lock (LOCKS.md §2.2): a spatial puzzle. A ward probe with an
// interchangeable bit is inserted (pick_depth), its tip height set (pick_lift)
// and turned (rotate, speed axis; tension = turning force). Fixed wards block
// the turn except through a gap; the right bit profile must be chosen before
// the turn (InputFrame::tool = bit slot), then the tip meets the spring bolt.
#pragma once

#include <array>
#include <memory>
#include <vector>

#include "lockcore/family.hpp"

namespace lockcore::warded {

inline constexpr std::string_view FAMILY_ID = "warded";
inline constexpr std::int32_t RULES_VERSION = 1;

enum Sub : std::uint16_t {
  SUB_SCRAPE = 1,  // "ward.scrape", base kind contact: the bit rubs a ward
};

// Bit profiles (slot = InputFrame::tool). Thicker bits are stiffer.
enum Bit : std::uint8_t { BIT_SQUARE = 0, BIT_HOOK = 1, BIT_FORK = 2 };
inline constexpr int BIT_COUNT = 3;
inline constexpr std::array<q16, BIT_COUNT> BIT_THICKNESS = {q16_milli(120), q16_milli(60), q16_milli(220)};
inline constexpr std::array<q16, BIT_COUNT> BIT_TAU_SAFE = {q16_milli(550), q16_milli(320), q16_milli(800)};
std::string_view bit_name(int bit);

struct Ward {
  q16 a_lo = 0, a_hi = 0;      // angular span (fraction of the full turn)
  q16 gap_lo = 0, gap_hi = 0;  // the only heights the bit may occupy inside the span
};

struct Params : FamilyParams {
  std::vector<Ward> wards;   // sorted by angle, not overlapping
  int bit_options = 1;       // slots 0..bit_options-1 are offered
  q16 a_bolt = 0;            // tip meets the bolt here
  q16 a_set = 0;             // bolt lifted (set)
  q16 bolt_lo = 0, bolt_hi = 0;  // tip heights that catch the bolt
  q16 bolt_spring = 0;       // turning force needed to lift the bolt
  q16 t_turn = 0;            // minimum force to turn at all
  q16 rot_speed = 0;         // turn per step at rotate = 1
  q16 insert_depth = 0;      // the probe turns only when inserted this deep
  q16 s_max = Q16_ONE;
  q16 stress_gain = 0;
  std::int32_t bend_limit = 0;  // stress episodes that break the probe (0: it only bends)
};

inline constexpr q16 T_TURN = q16_milli(50);
inline constexpr q16 ROT_SPEED = q16_per_step(q16_milli(667));  // a full turn in 1.5 s
inline constexpr q16 INSERT_DEPTH = q16_milli(850);
inline constexpr q16 WITHDRAWN_DEPTH = q16_milli(100);  // bits can be swapped only here, unturned
inline constexpr q16 A_BOLT = q16_milli(820);
inline constexpr q16 A_SET = q16_milli(920);
inline constexpr q16 STRESS_GAIN = q16_milli(80);

std::unique_ptr<FamilyModule> make_module();

}  // namespace lockcore::warded
