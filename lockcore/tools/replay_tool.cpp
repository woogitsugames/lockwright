// replay_tool: record, play and inspect replays and lock files.
//
//   replay_tool record <family> <tier> <seed> <out.replay.json> [--clumsy|--feel]
//     --clumsy: record the clumsy bot (no overset knowledge), which exercises
//     overset / drop / counter-rotation paths
//     --feel: record the feeling bot (events and continuous signals only)
//   replay_tool play <file.replay.json>
//   replay_tool lock <family> <tier> <seed>          (prints lockwright.lock/1)
#include <cstdio>
#include <cstdlib>
#include <fstream>
#include <iostream>
#include <sstream>
#include <string>

#include "lockcore/lockcore.hpp"

using namespace lockcore;

namespace {

int usage() {
  std::fprintf(stderr,
               "usage:\n  replay_tool record <family> <tier> <seed> <out> [--clumsy|--feel]\n  replay_tool play <file>\n"
               "  replay_tool lock <family> <tier> <seed>\n");
  return 2;
}

}  // namespace

int main(int argc, char** argv) {
  if (argc < 3) return usage();
  const std::string cmd = argv[1];
  const FamilyRegistry& reg = FamilyRegistry::builtin();

  const bool clumsy = argc == 7 && std::string(argv[6]) == "--clumsy";
  const bool feel = argc == 7 && std::string(argv[6]) == "--feel";
  if ((cmd == "record" && (argc == 6 || clumsy || feel)) || (cmd == "lock" && argc == 5)) {
    const FamilyModule* fam = reg.find(argv[2]);
    if (fam == nullptr) {
      std::fprintf(stderr, "unknown family %s\n", argv[2]);
      return 1;
    }
    const DifficultyVector d = fam->difficulty_for_tier(std::atoi(argv[3]));
    const std::uint64_t seed = std::strtoull(argv[4], nullptr, 10);
    const LockSpec spec = fam->generate(seed, d);
    if (cmd == "lock") {
      std::cout << lock_to_json(spec, *fam);
      return 0;
    }
    SolveOptions opt;
    opt.record_inputs = true;
    SolveReport r;
    if (clumsy) {
      r = fam->run_bot(BotKind::clumsy, spec, fam->required_tools(spec), opt);
    } else if (feel) {
      r = fam->run_bot(BotKind::feeling, spec, fam->required_tools(spec), opt);
    } else {
      r = fam->solver(spec, fam->required_tools(spec), opt);
    }
    if (!r.ok) {
      std::fprintf(stderr, "solver failed: %s\n", r.reason.c_str());
      return 1;
    }
    Replay rp;
    rp.family = std::string(fam->id());
    rp.rules_version = fam->rules_version();
    rp.seed = seed;
    rp.difficulty = d;
    rp.inputs = r.inputs;
    rp.expected_hash = r.event_hash;
    rp.expected_steps = r.steps;
    rp.expected_open = true;
    std::ofstream(argv[5], std::ios::binary) << replay_to_json(rp);
    std::printf("%s: %lld steps, %d drops, %d oversets, %d false sets, hash %s\n", argv[5],
                static_cast<long long>(r.steps), r.drops, r.oversets, r.false_sets, hash_hex(r.event_hash).c_str());
    return 0;
  }

  if (cmd == "play" && argc == 3) {
    std::ifstream f(argv[2], std::ios::binary);
    std::stringstream ss;
    ss << f.rdbuf();
    Replay rp;
    std::string err;
    if (!replay_from_json(ss.str(), rp, err)) {
      std::fprintf(stderr, "%s\n", err.c_str());
      return 1;
    }
    const ReplayResult res = run_replay(reg, rp);
    if (!res.ok) {
      std::fprintf(stderr, "%s\n", res.error.c_str());
      return 1;
    }
    const bool match = res.hash == rp.expected_hash;
    std::printf("steps %lld, open %d, hash %s (%s)\n", static_cast<long long>(res.steps), res.open ? 1 : 0,
                hash_hex(res.hash).c_str(), match ? "matches" : "MISMATCH");
    return match ? 0 : 1;
  }
  return usage();
}
