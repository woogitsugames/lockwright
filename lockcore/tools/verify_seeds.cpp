// verify_seeds: verifier run over many seeds per family and tier (LOCKS.md §1.10,
// DESIGN.md A3). For every seed: generate, validate, oracle, lock-file round trip,
// scripted bot through step(); for the first seeds also a replay of the bot's
// inputs (determinism). Exit code 1 on any failure.
//
// Soft metric (report only): a "clumsy" bot with worse limits (more tremor, faster
// lifting, slower reactions) runs the same plan with the full time budget. Its
// success rate, drops and oversets indicate how forgiving each tier is.
//
//   verify_seeds [--seeds N] [--family ID] [--tier T] [--csv FILE] [--replays N]
#include <algorithm>
#include <chrono>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <string>
#include <vector>

#include "lockcore/lockcore.hpp"

using namespace lockcore;

namespace {

struct Stats {
  std::vector<std::int64_t> steps;
  std::vector<std::int32_t> drops;
  std::int64_t oversets = 0, false_sets = 0, retries = 0;
  q16 peak_stress = 0;
  int failures = 0;
  std::vector<std::string> failure_samples;
  // clumsy bot
  std::int64_t c_ok = 0, c_runs = 0, c_drops = 0, c_oversets = 0, c_breaks = 0;
  std::vector<std::int64_t> c_steps;
  std::vector<std::string> c_fail_samples;
};



template <typename T>
T pct(std::vector<T> v, int p) {
  if (v.empty()) return 0;
  std::sort(v.begin(), v.end());
  const std::size_t i = std::min(v.size() - 1, (v.size() * static_cast<std::size_t>(p)) / 100);
  return v[i];
}

// Seeds are spread with SplitMix64 so neighbouring indices do not correlate.
std::uint64_t seed_at(std::uint64_t i) { return splitmix64(0x4c4f434bULL + i) & 0xffffffffffffULL; }

std::string ms(std::int64_t steps) {
  char buf[32];
  std::snprintf(buf, sizeof buf, "%lld.%02llds", static_cast<long long>(steps / SIM_HZ),
                static_cast<long long>((steps % SIM_HZ) * 100 / SIM_HZ));
  return buf;
}

}  // namespace

int main(int argc, char** argv) {
  std::int64_t n_seeds = 10000;
  std::int64_t n_replays = 100;
  std::string only_family;
  int only_tier = -1;
  std::string csv_path;
  for (int i = 1; i < argc; ++i) {
    const std::string a = argv[i];
    auto next = [&]() -> std::string {
      if (i + 1 >= argc) {
        std::fprintf(stderr, "missing value for %s\n", a.c_str());
        std::exit(2);
      }
      return argv[++i];
    };
    if (a == "--seeds") n_seeds = std::atoll(next().c_str());
    else if (a == "--replays") n_replays = std::atoll(next().c_str());
    else if (a == "--family") only_family = next();
    else if (a == "--tier") only_tier = std::atoi(next().c_str());
    else if (a == "--csv") csv_path = next();
    else {
      std::fprintf(stderr, "usage: verify_seeds [--seeds N] [--family ID] [--tier T] [--csv FILE] [--replays N]\n");
      return 2;
    }
  }

  std::ofstream csv;
  if (!csv_path.empty()) {
    csv.open(csv_path);
    csv << "family,tier,seeds,failures,steps_p50,steps_p90,steps_max,drops_mean_x100,drops_p90,drops_max,"
           "oversets,false_sets,retries,peak_stress_q16\n";
  }

  const auto t0 = std::chrono::steady_clock::now();
  const FamilyRegistry& reg = FamilyRegistry::builtin();
  int total_failures = 0;
  std::vector<std::string> clumsy;
  std::printf("%-12s %4s %7s %5s | %8s %8s %8s | %6s %5s %5s | %7s %7s %6s %6s\n", "family", "tier", "seeds",
              "fail", "t_p50", "t_p90", "t_max", "drop/l", "d_p90", "d_max", "overset", "f_set", "retry", "S_pk");
  for (const FamilyModule* fam : reg.all()) {
    if (!only_family.empty() && fam->id() != only_family) continue;
    for (int tier = fam->min_tier(); tier <= fam->max_tier(); ++tier) {
      if (only_tier >= 0 && tier != only_tier) continue;
      const DifficultyVector d = fam->difficulty_for_tier(tier);
      Stats st;
      auto fail = [&](std::uint64_t seed, const std::string& why) {
        ++st.failures;
        if (st.failure_samples.size() < 5) st.failure_samples.push_back("seed " + std::to_string(seed) + ": " + why);
      };
      for (std::int64_t i = 0; i < n_seeds; ++i) {
        const std::uint64_t seed = seed_at(static_cast<std::uint64_t>(i));
        const LockSpec spec = fam->generate(seed, d);
        if (const auto errs = fam->validate(spec); !errs.empty()) {
          fail(seed, "validate: " + errs.front().path + ": " + errs.front().message);
          continue;
        }
        const std::string text = lock_to_json(spec, *fam);
        const LockParse back = lock_from_json(text, reg);
        if (!back.ok || lock_to_json(back.spec, *fam) != text) {
          fail(seed, "lock file round trip");
          continue;
        }
        SolveOptions opt;
        opt.record_inputs = i < n_replays;
        const SolveReport r = fam->solver(spec, fam->required_tools(spec), opt);
        if (!r.ok) {
          fail(seed, r.reason);
          continue;
        }
        if (opt.record_inputs) {
          Replay rp;
          rp.family = std::string(fam->id());
          rp.rules_version = fam->rules_version();
          rp.seed = seed;
          rp.difficulty = d;
          rp.inputs = r.inputs;
          Replay parsed;
          std::string err;
          if (!replay_from_json(replay_to_json(rp), parsed, err)) {
            fail(seed, "replay parse: " + err);
            continue;
          }
          const ReplayResult rr = run_replay(reg, parsed);
          if (!rr.ok || rr.hash != r.event_hash || !rr.open) {
            fail(seed, "replay hash mismatch");
            continue;
          }
        }
        {
          OracleReport o = fam->oracle(spec, fam->required_tools(spec));
          // A human does not know where the overset starts: no lift cap from the plan.
          for (auto& ps : o.plan.steps) ps.lift_cap = q16_milli(980);
          const std::int64_t budget = static_cast<std::int64_t>(d.time_limit_s) * SIM_HZ;
          SolveOptions copt;
          copt.bot_seed = 2;
          const SolveReport c = run_plan_bot(*fam, spec, fam->required_tools(spec), o.plan, clumsy_human_limits(), budget, copt);
          ++st.c_runs;
          st.c_ok += c.ok ? 1 : 0;
          st.c_drops += c.drops;
          st.c_oversets += c.oversets;
          st.c_breaks += c.reason.find("failure break") != std::string::npos ? 1 : 0;
          if (c.ok) st.c_steps.push_back(c.steps);
          if (!c.ok && st.c_fail_samples.size() < 3) st.c_fail_samples.push_back("seed " + std::to_string(seed) + ": " + c.reason);
        }
        st.steps.push_back(r.steps);
        st.drops.push_back(r.drops);
        st.oversets += r.oversets;
        st.false_sets += r.false_sets;
        st.retries += r.retries;
        st.peak_stress = q_max(st.peak_stress, r.peak_stress);
      }
      std::int64_t drop_sum = 0;
      std::int32_t drop_max = 0;
      for (auto x : st.drops) {
        drop_sum += x;
        drop_max = std::max(drop_max, x);
      }
      const std::int64_t ok = static_cast<std::int64_t>(st.steps.size());
      const std::int64_t drops_x100 = ok ? (drop_sum * 100) / ok : 0;
      const std::int64_t smax = st.steps.empty() ? 0 : *std::max_element(st.steps.begin(), st.steps.end());
      std::printf("%-12s %4d %7lld %5d | %8s %8s %8s | %3lld.%02lld %5d %5d | %7lld %7lld %6lld %3lld.%02lld\n",
                  std::string(fam->id()).c_str(), tier, static_cast<long long>(n_seeds), st.failures,
                  ms(pct(st.steps, 50)).c_str(), ms(pct(st.steps, 90)).c_str(), ms(smax).c_str(),
                  static_cast<long long>(drops_x100 / 100), static_cast<long long>(drops_x100 % 100),
                  pct(st.drops, 90), drop_max, static_cast<long long>(st.oversets),
                  static_cast<long long>(st.false_sets), static_cast<long long>(st.retries),
                  static_cast<long long>(st.peak_stress / Q16_ONE),
                  static_cast<long long>((st.peak_stress % Q16_ONE) * 100 / Q16_ONE));
      for (const auto& s : st.failure_samples) std::printf("    FAIL %s\n", s.c_str());
      {
        const std::int64_t runs = st.c_runs ? st.c_runs : 1;
        const std::int64_t ok_x1000 = (st.c_ok * 1000) / runs;
        const std::int64_t d_x100 = (st.c_drops * 100) / runs;
        const std::int64_t o_x100 = (st.c_oversets * 100) / runs;
        char line[256];
        std::snprintf(line, sizeof line,
                      "%s t%d: success %lld.%01lld%%, drops/lock %lld.%02lld, oversets/lock %lld.%02lld, breaks %lld, t_p50 %s",
                      std::string(fam->id()).c_str(), tier, static_cast<long long>(ok_x1000 / 10),
                      static_cast<long long>(ok_x1000 % 10), static_cast<long long>(d_x100 / 100),
                      static_cast<long long>(d_x100 % 100), static_cast<long long>(o_x100 / 100),
                      static_cast<long long>(o_x100 % 100), static_cast<long long>(st.c_breaks),
                      ms(pct(st.c_steps, 50)).c_str());
        clumsy.push_back(line);
      }
      for (const auto& f : st.c_fail_samples) clumsy.push_back("    e.g. " + f);
      if (csv.is_open()) {
        csv << fam->id() << "," << tier << "," << n_seeds << "," << st.failures << "," << pct(st.steps, 50) << ","
            << pct(st.steps, 90) << "," << smax << "," << drops_x100 << "," << pct(st.drops, 90) << "," << drop_max
            << "," << st.oversets << "," << st.false_sets << "," << st.retries << "," << st.peak_stress << "\n";
      }
      total_failures += st.failures;
    }
  }
  std::printf("\nclumsy bot (soft metric: tremor +-0.06, lift 0.7/s, 0.3/s after near_shear, slows after oversets, 250 ms reaction, no overset knowledge):\n");
  for (const auto& c : clumsy) std::printf("  %s\n", c.c_str());
  const auto secs = std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::steady_clock::now() - t0).count();
  std::printf("total failures: %d (%lld ms)\n", total_failures, static_cast<long long>(secs));
  return total_failures == 0 ? 0 : 1;
}
