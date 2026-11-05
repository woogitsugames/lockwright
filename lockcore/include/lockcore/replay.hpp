// Replays (ARCHITECTURE.md §7): seed + difficulty + quantised inputs (RLE).
// Re-running a replay must give the identical event-stream hash on every platform.
#pragma once

#include <cstdint>
#include <string>
#include <string_view>
#include <vector>

#include "lockcore/registry.hpp"

namespace lockcore {

inline constexpr std::string_view REPLAY_SCHEMA = "lockwright.replay/1";
// Upper bound on the expanded input frames of one replay: the longest tier time
// limit a difficulty vector accepts (3600 s) at SIM_HZ (T25-06).
inline constexpr std::size_t MAX_REPLAY_STEPS = 3600u * SIM_HZ;

struct Replay {
  std::string family;
  std::int32_t rules_version = 0;
  std::uint64_t seed = 0;
  DifficultyVector difficulty;
  std::vector<InputFrame> inputs;  // one per step, already quantised
  // Expected outcome (golden files).
  std::uint64_t expected_hash = 0;
  std::int64_t expected_steps = 0;
  bool expected_open = false;
};

std::string replay_to_json(const Replay& r);
// Strict parser: every header field, the expected block and canonical (quantised,
// in-range) inputs are required. `out` is assigned only on success.
bool replay_from_json(std::string_view text, Replay& out, std::string& error);

struct ReplayResult {
  bool ok = false;
  std::string error;
  std::uint64_t hash = 0;
  std::int64_t steps = 0;
  bool open = false;
  FailureKind failure = FailureKind::none;
};

// Regenerates the lock from seed + difficulty and plays the inputs. Rejects a replay
// recorded under different rules_version explicitly.
ReplayResult run_replay(const FamilyRegistry& registry, const Replay& r);

std::string hash_hex(std::uint64_t h);

}  // namespace lockcore
