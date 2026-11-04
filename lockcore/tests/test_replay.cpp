#include <filesystem>
#include <fstream>
#include <sstream>

#include "helpers.hpp"
#include "testing.hpp"

using namespace lockcore;

namespace {
std::string read_file(const std::filesystem::path& p) {
  std::ifstream f(p, std::ios::binary);
  std::ostringstream ss;
  ss << f.rdbuf();
  return ss.str();
}
}  // namespace

TEST_CASE("replay: JSON round trip with RLE") {
  const auto& fam = th::pin_module();
  const DifficultyVector d = fam.difficulty_for_tier(5);
  SolveOptions opt;
  opt.record_inputs = true;
  const SolveReport rep = fam.solver(fam.generate(77, d), ToolSet{}, opt);
  REQUIRE(rep.ok);
  Replay r;
  r.family = std::string(fam.id());
  r.rules_version = fam.rules_version();
  r.seed = 77;
  r.difficulty = d;
  r.inputs = rep.inputs;
  r.expected_hash = rep.event_hash;
  r.expected_steps = rep.steps;
  r.expected_open = true;
  const std::string text = replay_to_json(r);
  Replay back;
  std::string err;
  REQUIRE(replay_from_json(text, back, err));
  CHECK(back.inputs == r.inputs);
  CHECK(back.difficulty == r.difficulty);
  CHECK_EQ(back.expected_hash, r.expected_hash);
  const ReplayResult res = run_replay(FamilyRegistry::builtin(), back);
  REQUIRE(res.ok);
  CHECK_EQ(res.hash, rep.event_hash);
  CHECK(res.open);
}

TEST_CASE("replay: rejects a different rules_version") {
  Replay r;
  r.family = "pin_tumbler";
  r.rules_version = 999;
  r.difficulty = th::pin_module().difficulty_for_tier(2);
  CHECK(!run_replay(FamilyRegistry::builtin(), r).ok);
}

TEST_CASE("replay: golden files give the recorded event hash") {
  int checked = 0;
  for (const auto& entry : std::filesystem::directory_iterator(LOCKCORE_GOLDEN_DIR)) {
    if (entry.path().extension() != ".json" || entry.path().string().find(".replay.") == std::string::npos) continue;
    Replay r;
    std::string err;
    const bool parsed = replay_from_json(read_file(entry.path()), r, err);
    if (!parsed) std::cerr << entry.path() << ": " << err << "\n";
    REQUIRE(parsed);
    const ReplayResult res = run_replay(FamilyRegistry::builtin(), r);
    REQUIRE(res.ok);
    if (res.hash != r.expected_hash)
      std::cerr << entry.path() << ": hash " << hash_hex(res.hash) << " expected " << hash_hex(r.expected_hash) << "\n";
    CHECK_EQ(res.hash, r.expected_hash);
    CHECK_EQ(res.steps, r.expected_steps);
    CHECK(res.open == r.expected_open);
    ++checked;
  }
  CHECK(checked >= 5);
}
