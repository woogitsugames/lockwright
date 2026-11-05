// replay_tool: record, play and inspect replays and lock files.
//
//   replay_tool record <family> <tier> <seed> <out.replay.json> [--clumsy|--feel]
//     --clumsy: record the clumsy bot (no overset knowledge), which exercises
//     overset / drop / counter-rotation paths
//     --feel: record the feeling bot (events and continuous signals only)
//   replay_tool play <file.replay.json>
//   replay_tool lock <family> <tier> <seed>          (prints lockwright.lock/1)
//   replay_tool trace <file.replay.json> <out.trace.json>
//     plays the replay like `play` and writes a per-step state/event trace
//     (lockwright.trace/1) for the debug visualiser mockups/tools/lockviz/.
//     Read-only with respect to the simulation: same session, same hash.
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
               "  replay_tool lock <family> <tier> <seed>\n"
               "  replay_tool trace <file> <out.trace.json>\n");
  return 2;
}

bool load_replay(const char* path, Replay& rp) {
  std::ifstream f(path, std::ios::binary);
  std::stringstream ss;
  ss << f.rdbuf();
  std::string err;
  if (!replay_from_json(ss.str(), rp, err)) {
    std::fprintf(stderr, "%s\n", err.c_str());
    return false;
  }
  return true;
}

// Per-step trace. All numbers stay integers (Q16 raw, 65536 = 1.0); the viewer
// does the division. Frame k is the state after input k was stepped.
int trace(const FamilyRegistry& reg, const char* in_path, const char* out_path) {
  Replay rp;
  if (!load_replay(in_path, rp)) return 1;
  const FamilyModule* fam = reg.find(rp.family);
  if (fam == nullptr) {
    std::fprintf(stderr, "unknown family %s\n", rp.family.c_str());
    return 1;
  }
  if (fam->rules_version() != rp.rules_version) {
    std::fprintf(stderr, "rules_version mismatch\n");
    return 1;
  }
  // Same construction as run_replay(), so the hash is identical.
  LockSpec spec = fam->generate(rp.seed, rp.difficulty);
  LockSession s(*fam, spec);
  using json::Value;
  Value frames = Value::array();
  Value events = Value::array();
  auto element_info = [](const ViewModel& vm) {
    Value a = Value::array();
    for (const ElementView& e : vm.elements) {
      Value row = Value::array();
      row.push(Value::integer(e.window_lo));
      row.push(Value::integer(e.window_hi));
      row.push(Value::integer(e.variant));
      a.push(std::move(row));
    }
    return a;
  };
  const Value elements0 = element_info(s.describe());
  for (const InputFrame& in : rp.inputs) {
    if (s.finished()) break;
    const StepOutput& out = s.step(in);
    const ViewModel vm = s.describe();
    Value fr = Value::array();
    for (q16 x : {in.tension, in.pick_depth, in.pick_lift, in.rotate, in.push}) fr.push(Value::integer(x));
    fr.push(Value::integer(in.tool));
    fr.push(Value::integer(out.tension_resistance));
    fr.push(Value::integer(out.pick_drag));
    fr.push(Value::integer(vm.stress));
    fr.push(Value::integer(vm.core_rotation));
    fr.push(Value::integer(vm.pick_element));
    fr.push(Value::integer(vm.pick_lift));
    fr.push(Value::integer(static_cast<std::int64_t>(vm.failure)));
    for (const ElementView& e : vm.elements) {
      fr.push(Value::integer(static_cast<std::int64_t>(e.state)));
      fr.push(Value::integer(e.position));
    }
    frames.push(std::move(fr));
    for (const LockEvent& e : out.events) {
      Value ev = Value::array();
      ev.push(Value::integer(e.t_step));
      ev.push(Value::integer(static_cast<std::int64_t>(e.kind)));
      ev.push(Value::integer(e.sub));
      ev.push(Value::integer(e.element));
      ev.push(Value::integer(e.intensity));
      ev.push(Value::integer(static_cast<std::int64_t>(e.material)));
      events.push(std::move(ev));
    }
  }
  Value names = Value::array();
  for (int k = 0; k < EVENT_KIND_COUNT; ++k) names.push(Value::string(std::string(event_kind_name(static_cast<EventKind>(k)))));
  Value states = Value::array();
  for (int k = 0; k <= static_cast<int>(ElementState::jammed); ++k)
    states.push(Value::string(std::string(element_state_name(static_cast<ElementState>(k)))));
  Value fails = Value::array();
  for (int k = 0; k <= static_cast<int>(FailureKind::timeout); ++k)
    fails.push(Value::string(std::string(failure_name(static_cast<FailureKind>(k)))));
  Value mats = Value::array();
  for (int k = 0; k <= static_cast<int>(MaterialId::steel); ++k)
    mats.push(Value::string(std::string(material_name(static_cast<MaterialId>(k)))));
  Value subs = Value::object();
  for (const Value& ev : events.items()) {
    const std::int64_t sub = ev.items()[2].as_int();
    if (sub == 0) continue;
    const std::string key = std::to_string(sub);
    if (subs.find(key) == nullptr) subs.set(key, Value::string(std::string(fam->event_name(static_cast<std::uint16_t>(sub)))));
  }
  Value frame_fields = Value::array();
  for (const char* f : {"tension", "pick_depth", "pick_lift", "rotate", "push", "tool", "tension_resistance", "pick_drag",
                        "stress", "core_rotation", "pick_element", "view_pick_lift", "failure"})
    frame_fields.push(Value::string(f));
  Value event_fields = Value::array();
  for (const char* f : {"t_step", "kind", "sub", "element", "intensity", "material"}) event_fields.push(Value::string(f));

  Value o = Value::object();
  o.set("schema", Value::string("lockwright.trace/1"));
  o.set("source", Value::string(in_path));
  o.set("family", Value::string(rp.family));
  o.set("rules_version", Value::integer(rp.rules_version));
  o.set("seed", Value::string(std::to_string(rp.seed)));
  o.set("tier", Value::integer(rp.difficulty.tier));
  o.set("q16_one", Value::integer(Q16_ONE));
  o.set("step_hz", Value::integer(120));
  o.set("element_states", std::move(states));
  o.set("event_kinds", std::move(names));
  o.set("event_sub_names", std::move(subs));
  o.set("failures", std::move(fails));
  o.set("materials", std::move(mats));
  o.set("elements", elements0);  // [window_lo, window_hi, variant] at t = 0
  o.set("frame_fields", std::move(frame_fields));
  o.set("frame_element_fields", [] {
    Value a = Value::array();
    a.push(Value::string("state"));
    a.push(Value::string("position"));
    return a;
  }());
  o.set("frames", std::move(frames));
  o.set("event_fields", std::move(event_fields));
  o.set("events", std::move(events));
  Value res = Value::object();
  res.set("steps", Value::integer(s.t_step()));
  res.set("open", Value::boolean(s.is_open()));
  res.set("failure", Value::string(std::string(failure_name(s.failure()))));
  res.set("event_hash_fnv1a64", Value::string(hash_hex(s.event_hash())));
  res.set("hash_matches", Value::boolean(s.event_hash() == rp.expected_hash));
  o.set("result", std::move(res));
  std::ofstream(out_path, std::ios::binary) << json::write(o, 1);
  std::printf("%s: %lld frames, %zu events, hash %s (%s)\n", out_path, static_cast<long long>(s.t_step()),
              o.find("events")->items().size(), hash_hex(s.event_hash()).c_str(),
              s.event_hash() == rp.expected_hash ? "matches" : "MISMATCH");
  return s.event_hash() == rp.expected_hash ? 0 : 1;
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

  if (cmd == "trace" && argc == 4) return trace(reg, argv[2], argv[3]);

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
