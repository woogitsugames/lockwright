// Lock specification: the family-independent envelope of `lockwright.lock/1`
// (ARCHITECTURE.md §6) plus a family-owned parameter block.
#pragma once

#include <cstdint>
#include <memory>
#include <string>
#include <vector>

#include "lockcore/difficulty.hpp"
#include "lockcore/events.hpp"

namespace lockcore {

// Family parameters; each family derives its own struct.
struct FamilyParams {
  virtual ~FamilyParams() = default;
};

struct LockSpec {
  std::string family;
  std::int32_t rules_version = 0;
  std::string id;
  std::string source = "generated";  // authored | generated | daily | dlc:<pack>
  std::uint64_t seed = 0;
  DifficultyVector difficulty;
  MaterialId material = MaterialId::brass;
  std::shared_ptr<const FamilyParams> params;
};

struct SpecError {
  std::string path;
  std::string message;
};

// invalid_spec (v0.5): a LockSession refused the spec or the tool set (T25-01/02).
enum class FailureKind : std::uint8_t { none, break_, detector_trip, timeout, invalid_spec };
std::string_view failure_name(FailureKind f);

// Tool capabilities available to the player (TOOLS.md).
enum ToolBits : std::uint32_t {
  TOOL_TENSION_WRENCH = 1u << 0,
  TOOL_HOOK = 1u << 1,
  TOOL_RAKE = 1u << 2,
  // v0.2 (additive): tools of the new families.
  TOOL_PEG_LIFTER = 1u << 3,      // wooden_pin
  TOOL_WARD_PROBE = 1u << 4,      // warded (interchangeable bits, InputFrame::tool = bit)
  TOOL_LEVER_CRANK = 1u << 5,     // lever, lever_detector
  TOOL_SHACKLE_PULLER = 1u << 6,  // ring_combo, combo
  // v0.6 (additive)
  TOOL_LISTENING_CUP = 1u << 7,   // dial_safe
  TOOL_DIMPLE_FLAG = 1u << 8,     // dimple (flat "flag" pick for side-drilled pins)
  TOOL_DISC_PICK = 1u << 9,       // disc_detainer (tension tip + disc turner)
};
struct ToolSet {
  std::uint32_t bits = TOOL_TENSION_WRENCH | TOOL_HOOK;
  bool has(std::uint32_t b) const { return (bits & b) == b; }
};

// Persistent tool condition carried between locks (save game).
struct ToolCondition {
  std::int32_t wear = 0;  // 0..100 points; lowers stress capacity
};

}  // namespace lockcore
