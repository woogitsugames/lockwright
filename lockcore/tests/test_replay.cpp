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

namespace {
// A small valid replay text to mutate in the negative tests.
std::string sample_replay() {
  Replay r;
  r.family = "wafer";
  r.rules_version = th::wafer_module().rules_version();
  r.seed = 77;
  r.difficulty = FamilyRegistry::builtin().find("wafer")->difficulty_for_tier(2);
  InputFrame f;
  f.tension = Q16_ONE / 4;
  r.inputs.assign(3, f);
  r.expected_hash = 0x0123456789abcdefULL;
  r.expected_steps = 3;
  return replay_to_json(r);
}
bool parses(const std::string& text) {
  Replay r;
  std::string err;
  return replay_from_json(text, r, err);
}
std::string replace(std::string s, const std::string& from, const std::string& to) {
  const auto p = s.find(from);
  if (p == std::string::npos) {
    ::lt::report(__FILE__, __LINE__, "pattern not found: " + from);
    return s;
  }
  return s.replace(p, from.size(), to);
}
}  // namespace

TEST_CASE("replay: strict parser rejects bad files (T25-04..08)") {
  const std::string ok = sample_replay();
  REQUIRE(parses(ok));
  // seed: digits only, no overflow, not empty
  CHECK(!parses(replace(ok, "\"seed\": \"77\"", "\"seed\": \"7x\"")));
  CHECK(!parses(replace(ok, "\"seed\": \"77\"", "\"seed\": \"\"")));
  CHECK(!parses(replace(ok, "\"seed\": \"77\"", "\"seed\": \"18446744073709551616\"")));
  CHECK(!parses(replace(ok, "\"seed\": \"77\"", "\"seed\": \"-1\"")));
  CHECK(parses(replace(ok, "\"seed\": \"77\"", "\"seed\": \"18446744073709551615\"")));
  // axes: range checked before scaling (no int64 overflow), tool 0..255
  CHECK(!parses(replace(ok, "[3, 64, 0, 0, 0, 0, 0]", "[3, 9223372036854775807, 0, 0, 0, 0, 0]")));
  CHECK(!parses(replace(ok, "[3, 64, 0, 0, 0, 0, 0]", "[3, 257, 0, 0, 0, 0, 0]")));
  CHECK(!parses(replace(ok, "[3, 64, 0, 0, 0, 0, 0]", "[3, -1, 0, 0, 0, 0, 0]")));
  CHECK(!parses(replace(ok, "[3, 64, 0, 0, 0, 0, 0]", "[3, 64, 0, -257, 0, 0, 0]")));
  CHECK(parses(replace(ok, "[3, 64, 0, 0, 0, 0, 0]", "[3, 64, 0, -256, 256, 0, 0]")));
  CHECK(!parses(replace(ok, "[3, 64, 0, 0, 0, 0, 0]", "[3, 64, 0, 0, 0, 0, 256]")));
  CHECK(!parses(replace(ok, "[3, 64, 0, 0, 0, 0, 0]", "[3, 64, 0, 0, 0, 0, -1]")));
  CHECK(parses(replace(ok, "[3, 64, 0, 0, 0, 0, 0]", "[3, 64, 0, 0, 0, 4, 255]")));
  CHECK(!parses(replace(ok, "[3, 64, 0, 0, 0, 0, 0]", "[3, 64, 0, 0, 0, 3, 0]")));  // push not on its 1/64 grid
  // frame limit over all runs, not per row
  CHECK(!parses(replace(ok, "[3, 64, 0, 0, 0, 0, 0]", "[0, 64, 0, 0, 0, 0, 0]")));
  CHECK(!parses(replace(ok, "[3, 64, 0, 0, 0, 0, 0]", "[432001, 64, 0, 0, 0, 0, 0]")));
  CHECK(!parses(replace(ok, "[3, 64, 0, 0, 0, 0, 0]", "[300000, 64, 0, 0, 0, 0, 0], [300000, 0, 0, 0, 0, 0, 0]")));
  CHECK(parses(replace(ok, "[3, 64, 0, 0, 0, 0, 0]", "[432000, 64, 0, 0, 0, 0, 0]")));
  // required header and expected block
  CHECK(!parses(replace(ok, "\"difficulty\"", "\"difficultyX\"")));
  CHECK(!parses(replace(ok, "\"input_unit\": \"1/256\"", "\"input_unit\": \"1/100\"")));
  CHECK(!parses(replace(ok, "\"pick_depth\", \"pick_lift\"", "\"pick_lift\", \"pick_depth\"")));
  CHECK(!parses(replace(ok, "\"expected\"", "\"expectedX\"")));
  CHECK(!parses(replace(ok, "\"event_hash_fnv1a64\"", "\"hash\"")));
  CHECK(!parses(replace(ok, "\"steps\": 3", "\"steps\": -3")));
}

TEST_CASE("replay: output is untouched on a failed parse (T25-08)") {
  Replay r;
  r.family = "keep";
  r.seed = 5;
  std::string err;
  CHECK(!replay_from_json(replace(sample_replay(), "\"expected\"", "\"expectedX\""), r, err));
  CHECK(r.family == "keep");
  CHECK_EQ(r.seed, 5u);
  CHECK(r.inputs.empty());
}
