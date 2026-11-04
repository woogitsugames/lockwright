// replay_fuzz: cross-platform determinism check for lockcore (TECH.md spike 5).
//
//   replay_fuzz gen   --count N [--seed S] --out corpus.lwfz   record on the reference host
//   replay_fuzz check corpus.lwfz [--report mismatches.txt]   replay on the target, compare
//   replay_fuzz bench [--steps N]                              step() cost, p50/p99 in ns
//
// Each case is a lock (family, tier, seed) plus quantised input rows. Inputs come from
// three sources so that every code path is exercised: the scripted bot (opens the lock),
// the clumsy bot (overset / drop / counter-rotation) and a random "fumbling hand"
// (random walks with holds, jitter and slams). The expected values are the FNV-1a 64
// event hash every 60 steps, a state hash (view model) every 60 steps, and the final
// event hash / step count / outcome. The corpus is a little-endian binary file, so the
// reader does not depend on the host byte order or on any text parser.
#include <algorithm>
#include <chrono>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <iterator>
#include <memory>
#include <string>
#include <vector>

#include "lockcore/lockcore.hpp"

using namespace lockcore;

namespace {

constexpr std::uint32_t MAGIC = 0x5a46574cu;  // "LWFZ"
constexpr std::uint32_t VERSION = 2;
constexpr std::int64_t CHECK_EVERY = 60;

struct Case {
  std::string family;
  std::int32_t rules_version = 0;
  std::int32_t tier = 0;
  std::uint64_t seed = 0;
  std::uint8_t source = 0;  // 0 random hand, 1 bot, 2 clumsy bot
  std::vector<InputFrame> inputs;
  // expected
  std::vector<std::uint64_t> checkpoints;  // event hash and state hash, interleaved
  std::uint64_t final_hash = 0;
  std::int64_t steps = 0;
  std::uint8_t open = 0, failure = 0;
};

// ---------------------------------------------------------------- byte IO (little-endian)
struct Writer {
  std::vector<std::uint8_t> b;
  void u8(std::uint8_t v) { b.push_back(v); }
  void u32(std::uint32_t v) {
    for (int i = 0; i < 4; ++i) b.push_back(static_cast<std::uint8_t>(v >> (8 * i)));
  }
  void u64(std::uint64_t v) {
    for (int i = 0; i < 8; ++i) b.push_back(static_cast<std::uint8_t>(v >> (8 * i)));
  }
  void i32(std::int32_t v) { u32(static_cast<std::uint32_t>(v)); }
  void str(const std::string& s) {
    u32(static_cast<std::uint32_t>(s.size()));
    b.insert(b.end(), s.begin(), s.end());
  }
};
struct Reader {
  const std::vector<std::uint8_t>& b;
  size_t p = 0;
  bool bad = false;
  bool need(size_t n) {
    if (p + n > b.size()) bad = true;
    return !bad;
  }
  std::uint8_t u8() { return need(1) ? b[p++] : 0; }
  std::uint32_t u32() {
    if (!need(4)) return 0;
    std::uint32_t v = 0;
    for (int i = 0; i < 4; ++i) v |= static_cast<std::uint32_t>(b[p++]) << (8 * i);
    return v;
  }
  std::uint64_t u64() {
    if (!need(8)) return 0;
    std::uint64_t v = 0;
    for (int i = 0; i < 8; ++i) v |= static_cast<std::uint64_t>(b[p++]) << (8 * i);
    return v;
  }
  std::int32_t i32() { return static_cast<std::int32_t>(u32()); }
  std::string str() {
    const std::uint32_t n = u32();
    if (!need(n)) return {};
    std::string s(reinterpret_cast<const char*>(b.data() + p), n);
    p += n;
    return s;
  }
};

// Input rows: RLE of (run, axes in 1/256 units as int16, tool). Every quantised axis is a
// multiple of 256 in Q16 (push: of 1024), so the encoding is lossless; writing checks it.
void put16(Writer& w, std::int32_t q) {
  const std::int32_t u = q / 256;
  if (u * 256 != q || u < -32768 || u > 32767) {
    std::fprintf(stderr, "input not on the 1/256 grid: %d\n", q);
    std::exit(3);
  }
  const auto v = static_cast<std::uint16_t>(static_cast<std::int16_t>(u));
  w.u8(static_cast<std::uint8_t>(v & 0xff));
  w.u8(static_cast<std::uint8_t>(v >> 8));
}
std::int32_t get16(Reader& r) {
  const std::uint32_t lo = r.u8(), hi = r.u8();
  return static_cast<std::int32_t>(static_cast<std::int16_t>(static_cast<std::uint16_t>(lo | (hi << 8)))) * 256;
}
void write_inputs(Writer& w, const std::vector<InputFrame>& in) {
  std::vector<std::pair<std::uint32_t, InputFrame>> rows;
  for (const InputFrame& f : in) {
    if (!rows.empty() && rows.back().second == f && rows.back().first < 255) {
      ++rows.back().first;
    } else {
      rows.push_back({1, f});
    }
  }
  w.u32(static_cast<std::uint32_t>(rows.size()));
  for (auto& [run, f] : rows) {
    w.u8(static_cast<std::uint8_t>(run));
    put16(w, f.tension);
    put16(w, f.pick_depth);
    put16(w, f.pick_lift);
    put16(w, f.rotate);
    put16(w, f.push);
    w.u8(f.tool);
  }
}
std::vector<InputFrame> read_inputs(Reader& r) {
  std::vector<InputFrame> out;
  const std::uint32_t n = r.u32();
  if (n > 10000000) {
    r.bad = true;
    return out;
  }
  for (std::uint32_t i = 0; i < n && !r.bad; ++i) {
    const std::uint32_t run = r.u8();
    InputFrame f;
    f.tension = get16(r);
    f.pick_depth = get16(r);
    f.pick_lift = get16(r);
    f.rotate = get16(r);
    f.push = get16(r);
    f.tool = r.u8();
    out.insert(out.end(), run, f);
  }
  return out;
}

// ---------------------------------------------------------------- simulation + hashes
std::uint64_t state_hash(const LockSession& s) {
  const ViewModel v = s.describe();
  Fnv1a64 h;
  h.u32(static_cast<std::uint32_t>(v.elements.size()));
  for (const ElementView& e : v.elements) {
    h.u32(static_cast<std::uint32_t>(e.state));
    h.i32(e.position);
    h.i32(e.window_lo);
    h.i32(e.window_hi);
    h.byte(e.variant);
  }
  h.i32(v.pick_element);
  h.i32(v.pick_lift);
  h.i32(v.tension);
  h.i32(v.core_rotation);
  h.i32(v.tension_resistance);
  h.i32(v.pick_drag);
  h.i32(v.stress);
  h.byte(v.open ? 1 : 0);
  h.u32(static_cast<std::uint32_t>(v.failure));
  return h.value();
}

struct RunOut {
  std::vector<std::uint64_t> checkpoints;
  std::uint64_t final_hash = 0;
  std::int64_t steps = 0;
  bool open = false;
  FailureKind failure = FailureKind::none;
  std::int64_t first_bad_step = -1;  // filled when compared
};

std::int64_t g_event_count[EVENT_KIND_COUNT] = {};

RunOut simulate(const FamilyModule& fam, const Case& c) {
  RunOut o;
  const LockSpec spec = fam.generate(c.seed, fam.difficulty_for_tier(c.tier));
  LockSession s(fam, spec);
  for (const InputFrame& f : c.inputs) {
    if (s.finished()) break;
    for (const LockEvent& e : s.step(f).events) g_event_count[static_cast<int>(e.kind)]++;
    if (s.t_step() % CHECK_EVERY == 0) {
      o.checkpoints.push_back(s.event_hash());
      o.checkpoints.push_back(state_hash(s));
    }
  }
  o.final_hash = s.event_hash();
  o.steps = s.t_step();
  o.open = s.is_open();
  o.failure = s.failure();
  return o;
}

// ---------------------------------------------------------------- input generators
struct Rng {  // independent of lockcore's streams, integer only
  std::uint64_t x;
  std::uint64_t next() { return x = splitmix64(x); }
  std::int32_t range(std::int32_t lo, std::int32_t hi) {  // inclusive
    return lo + static_cast<std::int32_t>(next() % static_cast<std::uint64_t>(hi - lo + 1));
  }
  bool chance(int pct) { return range(0, 99) < pct; }
};

std::vector<InputFrame> random_hand(Rng& r, std::uint32_t mask, std::int64_t steps) {
  std::vector<InputFrame> out;
  out.reserve(static_cast<size_t>(steps));
  // Targets in 1/256 units; the hand moves towards them with a limited rate.
  std::int32_t t = 0, d = 0, l = 0, rot = 0, push = 0;
  std::int32_t tt = r.range(20, 90), td = r.range(0, 256), tl = 0, trot = 0, tpush = 0;
  std::int32_t hold = 0, jitter = 0, jitter_left = 0, lift_jit = 0;
  auto approach = [](std::int32_t v, std::int32_t target, std::int32_t rate) {
    if (v < target) return std::min(target, v + rate);
    return std::max(target, v - rate);
  };
  for (std::int64_t i = 0; i < steps; ++i) {
    if (--hold <= 0) {
      hold = r.range(1, 90);
      switch (r.range(0, 9)) {
        case 0: tt = r.range(0, 256); break;             // any tension (incl. slam / release)
        case 1: tt = r.range(15, 80); break;             // working band
        case 2: td = r.range(0, 256); break;             // move along the keyway
        case 3: tl = r.range(-256, 256); break;          // lift / press
        case 4: tl = r.range(0, 200); break;             // lift up
        case 5: tl = 0; break;                           // let go
        case 6: trot = r.range(-256, 256); break;
        case 7: tpush = r.range(0, 256); break;
        case 8: tt = r.range(0, 30); break;              // relax (drop path)
        default: hold = r.range(1, 8); break;            // short twitch
      }
    }
    const std::int32_t rate = r.chance(5) ? 64 : r.range(1, 6);
    t = approach(t, tt, rate);
    d = approach(d, td, r.range(1, 8));
    l = approach(l, tl, r.range(1, 10));
    rot = approach(rot, trot, r.range(1, 6));
    push = approach(push, tpush, r.range(1, 6));
    InputFrame f;
    if (--jitter_left <= 0) {  // tremor: a new offset every 25-100 ms
      jitter_left = r.range(3, 12);
      jitter = r.chance(40) ? r.range(-3, 3) : 0;
      lift_jit = r.chance(30) ? r.range(-2, 2) : 0;
    }
    f.tension = std::clamp(t + jitter, 0, 256) * 256;
    f.pick_depth = std::clamp(d, 0, 256) * 256;
    f.pick_lift = std::clamp(l + lift_jit, -256, 256) * 256;
    f.rotate = (mask & AXIS_ROTATE) ? rot * 256 : 0;
    f.push = (mask & AXIS_PUSH) ? std::clamp(push, 0, 256) * 256 : 0;
    f.tool = 0;
    out.push_back(quantize(f));
  }
  return out;
}

int usage() {
  std::fprintf(stderr,
               "usage:\n  replay_fuzz gen --count N [--seed S] --out FILE\n"
               "  replay_fuzz check FILE [--report FILE]\n  replay_fuzz bench [--steps N]\n");
  return 2;
}

const char* arg(int argc, char** argv, const char* name, const char* def) {
  for (int i = 2; i + 1 < argc; ++i)
    if (std::strcmp(argv[i], name) == 0) return argv[i + 1];
  return def;
}

const char* platform_name() {
#if defined(__ANDROID__)
  const char* os = "android";
#elif defined(__APPLE__)
  const char* os = "apple";
#elif defined(__linux__)
  const char* os = "linux";
#else
  const char* os = "other";
#endif
#if defined(__aarch64__)
  const char* arch = "arm64";
#elif defined(__x86_64__)
  const char* arch = "x86_64";
#else
  const char* arch = "other";
#endif
  static char buf[64];
  std::snprintf(buf, sizeof buf, "%s-%s", os, arch);
  return buf;
}

const char* compiler_name() {
  static char buf[96];
#if defined(__clang__)
  std::snprintf(buf, sizeof buf, "clang %s", __clang_version__);
#elif defined(__GNUC__)
  std::snprintf(buf, sizeof buf, "gcc %d.%d.%d", __GNUC__, __GNUC_MINOR__, __GNUC_PATCHLEVEL__);
#else
  std::snprintf(buf, sizeof buf, "unknown");
#endif
  return buf;
}

int cmd_gen(int argc, char** argv) {
  const int count = std::atoi(arg(argc, argv, "--count", "10000"));
  const std::uint64_t seed = std::strtoull(arg(argc, argv, "--seed", "20261104"), nullptr, 10);
  const char* out = arg(argc, argv, "--out", nullptr);
  if (out == nullptr || count <= 0) return usage();
  const FamilyRegistry& reg = FamilyRegistry::builtin();
  const auto fams = reg.all();
  Rng r{seed};
  Writer w;
  w.u32(MAGIC);
  w.u32(VERSION);
  w.u32(static_cast<std::uint32_t>(count));
  std::uint64_t corpus = FNV64_OFFSET;
  int by_source[3] = {0, 0, 0}, opened = 0;
  int by_failure[8] = {0, 0, 0, 0, 0, 0, 0, 0};
  std::int64_t total_steps = 0;
  for (int i = 0; i < count; ++i) {
    const FamilyModule& fam = *fams[static_cast<size_t>(r.range(0, static_cast<std::int32_t>(fams.size()) - 1))];
    Case c;
    c.family = std::string(fam.id());
    c.rules_version = fam.rules_version();
    c.tier = r.range(fam.min_tier(), fam.max_tier());
    c.seed = r.next();
    const DifficultyVector d = fam.difficulty_for_tier(c.tier);
    const int pick = r.range(0, 99);
    c.source = pick < 70 ? 0 : (pick < 85 ? 1 : 2);
    const LockSpec spec = fam.generate(c.seed, d);
    if (c.source != 0) {
      SolveOptions opt;
      opt.record_inputs = true;
      opt.bot_seed = r.next();
      SolveReport sr;
      if (c.source == 1) {
        sr = fam.solver(spec, fam.required_tools(spec), opt);
      } else {
        OracleReport o = fam.oracle(spec, fam.required_tools(spec));
        for (auto& ps : o.plan.steps) ps.lift_cap = q16_milli(980);
        sr = run_plan_bot(fam, spec, fam.required_tools(spec), o.plan, clumsy_human_limits(),
                          static_cast<std::int64_t>(d.time_limit_s) * SIM_HZ, opt);
      }
      c.inputs = sr.inputs;
      // Perturb a tail of bot runs so that some of them fail late (break / drop paths).
      if (!c.inputs.empty() && r.chance(30)) {
        const size_t from = static_cast<size_t>(r.range(0, static_cast<std::int32_t>(c.inputs.size()) - 1));
        for (size_t k = from; k < c.inputs.size(); ++k) {
          InputFrame f = c.inputs[k];
          f.tension = std::clamp(f.tension + r.range(-20, 40) * 256, 0, Q16_ONE);
          c.inputs[k] = quantize(f);
        }
      }
    }
    if (c.inputs.empty()) {
      c.source = 0;
      c.inputs = random_hand(r, fam.input_mask(), r.range(240, 2400));
    }
    const RunOut o = simulate(fam, c);
    c.checkpoints = o.checkpoints;
    c.final_hash = o.final_hash;
    c.steps = o.steps;
    c.open = o.open ? 1 : 0;
    c.failure = static_cast<std::uint8_t>(o.failure);
    by_source[c.source]++;
    opened += c.open;
    by_failure[c.failure & 7]++;
    total_steps += c.steps;
    corpus ^= c.final_hash;
    corpus *= FNV64_PRIME;

    w.str(c.family);
    w.i32(c.rules_version);
    w.i32(c.tier);
    w.u64(c.seed);
    w.u8(c.source);
    write_inputs(w, c.inputs);
    w.u32(static_cast<std::uint32_t>(c.checkpoints.size()));
    for (std::uint64_t h : c.checkpoints) w.u64(h);
    w.u64(c.final_hash);
    w.u64(static_cast<std::uint64_t>(c.steps));
    w.u8(c.open);
    w.u8(c.failure);
  }
  w.u64(corpus);
  std::ofstream(out, std::ios::binary).write(reinterpret_cast<const char*>(w.b.data()),
                                             static_cast<std::streamsize>(w.b.size()));
  std::printf("platform %s, %s\n", platform_name(), compiler_name());
  std::printf("wrote %s: %d cases (random %d, bot %d, clumsy %d), %d opened, %lld steps, corpus hash %s\n", out,
              count, by_source[0], by_source[1], by_source[2], opened, static_cast<long long>(total_steps),
              hash_hex(corpus).c_str());
  std::printf("outcomes by FailureKind (0 = none):");
  for (int k = 0; k < 8; ++k)
    if (by_failure[k] != 0) std::printf(" %d:%d", k, by_failure[k]);
  std::printf("\nevents by kind:");
  for (int k = 0; k < EVENT_KIND_COUNT; ++k)
    std::printf(" %s:%lld", std::string(event_kind_name(static_cast<EventKind>(k))).c_str(),
                static_cast<long long>(g_event_count[k]));
  std::printf("\n");
  return 0;
}

int cmd_check(int argc, char** argv) {
  if (argc < 3) return usage();
  std::ifstream f(argv[2], std::ios::binary);
  std::vector<std::uint8_t> buf((std::istreambuf_iterator<char>(f)), std::istreambuf_iterator<char>());
  Reader r{buf};
  if (r.u32() != MAGIC || r.u32() != VERSION) {
    std::fprintf(stderr, "not a replay_fuzz corpus (v%u)\n", VERSION);
    return 2;
  }
  const char* report = arg(argc, argv, "--report", nullptr);
  const std::uint32_t count = r.u32();
  const FamilyRegistry& reg = FamilyRegistry::builtin();
  std::uint32_t ok = 0, bad = 0, skipped = 0;
  std::uint64_t corpus = FNV64_OFFSET;
  std::int64_t total_steps = 0;
  std::string mismatches;
  for (std::uint32_t i = 0; i < count && !r.bad; ++i) {
    Case c;
    c.family = r.str();
    c.rules_version = r.i32();
    c.tier = r.i32();
    c.seed = r.u64();
    c.source = r.u8();
    c.inputs = read_inputs(r);
    const std::uint32_t nc = r.u32();
    if (nc > 10000000) {
      r.bad = true;
      break;
    }
    for (std::uint32_t k = 0; k < nc; ++k) c.checkpoints.push_back(r.u64());
    c.final_hash = r.u64();
    c.steps = static_cast<std::int64_t>(r.u64());
    c.open = r.u8();
    c.failure = r.u8();
    corpus ^= c.final_hash;
    corpus *= FNV64_PRIME;
    const FamilyModule* fam = reg.find(c.family);
    if (fam == nullptr || fam->rules_version() != c.rules_version) {
      ++skipped;
      continue;
    }
    const RunOut o = simulate(*fam, c);
    total_steps += o.steps;
    const bool same = o.final_hash == c.final_hash && o.steps == c.steps && o.checkpoints == c.checkpoints &&
                      (o.open ? 1 : 0) == c.open && static_cast<std::uint8_t>(o.failure) == c.failure;
    if (same) {
      ++ok;
      continue;
    }
    ++bad;
    std::int64_t first = -1;
    for (size_t k = 0; k < std::min(o.checkpoints.size(), c.checkpoints.size()); ++k)
      if (o.checkpoints[k] != c.checkpoints[k]) {
        first = static_cast<std::int64_t>(k / 2 + 1) * CHECK_EVERY;
        break;
      }
    char line[256];
    std::snprintf(line, sizeof line,
                  "case %u: %s t%d seed %llu source %u: expected %s/%lld steps, got %s/%lld steps; first differing "
                  "checkpoint at step %lld\n",
                  i, c.family.c_str(), c.tier, static_cast<unsigned long long>(c.seed), c.source,
                  hash_hex(c.final_hash).c_str(), static_cast<long long>(c.steps), hash_hex(o.final_hash).c_str(),
                  static_cast<long long>(o.steps), static_cast<long long>(first));
    if (bad <= 20) std::fputs(line, stdout);
    mismatches += line;
  }
  const std::uint64_t stored = r.u64();
  if (r.bad) {
    std::fprintf(stderr, "corpus truncated or corrupt\n");
    return 2;
  }
  if (stored != corpus) {
    std::fprintf(stderr, "corpus hash mismatch (file damaged?)\n");
    return 2;
  }
  if (report != nullptr) std::ofstream(report) << mismatches;
  std::printf("platform %s, %s\n", platform_name(), compiler_name());
  std::printf("checked %u cases, %lld steps: %u match, %u MISMATCH, %u skipped (rules_version); corpus %s\n", count,
              static_cast<long long>(total_steps), ok, bad, skipped, hash_hex(corpus).c_str());
  return bad == 0 && skipped == 0 ? 0 : 1;
}

int cmd_bench(int argc, char** argv) {
  const std::int64_t steps = std::atoll(arg(argc, argv, "--steps", "200000"));
  const FamilyRegistry& reg = FamilyRegistry::builtin();
  std::printf("platform %s, %s\n", platform_name(), compiler_name());
  for (const FamilyModule* fam : reg.all()) {
    const int tier = fam->max_tier();
    const LockSpec spec = fam->generate(1, fam->difficulty_for_tier(tier));
    Rng r{7};
    const std::vector<InputFrame> in = random_hand(r, fam->input_mask(), steps);
    std::vector<std::int64_t> ns;
    ns.reserve(static_cast<size_t>(steps));
    auto s = std::make_unique<LockSession>(*fam, spec);
    for (const InputFrame& f : in) {
      if (s->finished()) s = std::make_unique<LockSession>(*fam, spec);
      const auto t0 = std::chrono::steady_clock::now();
      s->step(f);
      const auto t1 = std::chrono::steady_clock::now();
      ns.push_back(std::chrono::duration_cast<std::chrono::nanoseconds>(t1 - t0).count());
    }
    std::sort(ns.begin(), ns.end());
    auto pct = [&](double p) { return ns[static_cast<size_t>(p * static_cast<double>(ns.size() - 1))]; };
    std::printf("%s t%d: step() p50 %lld ns, p99 %lld ns, p99.9 %lld ns, max %lld ns (%lld steps)\n",
                std::string(fam->id()).c_str(), tier, static_cast<long long>(pct(0.5)),
                static_cast<long long>(pct(0.99)), static_cast<long long>(pct(0.999)),
                static_cast<long long>(ns.back()), static_cast<long long>(steps));
  }
  return 0;
}

}  // namespace

int main(int argc, char** argv) {
  if (argc < 2) return usage();
  const std::string cmd = argv[1];
  if (cmd == "gen") return cmd_gen(argc, argv);
  if (cmd == "check") return cmd_check(argc, argv);
  if (cmd == "bench") return cmd_bench(argc, argv);
  return usage();
}
