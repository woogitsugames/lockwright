// Light fuzzing (LOCKS.md §1.10 p. 4): 100 000 steps of random inputs per family
// (random walk plus jumps, random tool slots), across many seeds and tiers.
// Checks invariants on every step; run it under ASan/UBSan (LOCKCORE_SANITIZE)
// to catch undefined behaviour. A hang would show up as a test timeout.
#include "helpers.hpp"
#include "testing.hpp"

using namespace lockcore;

namespace {

constexpr std::int64_t FUZZ_STEPS = 100000;
constexpr std::int64_t MAX_LOCK_STEPS = 120 * 40;

q16 walk(Pcg32& rng, q16 v, q16 lo, q16 hi) {
  if (rng.below(200) == 0) return rng.range(lo, hi);  // jump
  return q_clamp(v + rng.range(-q16_milli(25), q16_milli(25)), lo, hi);
}

bool in01(q16 v) { return v >= 0 && v <= Q16_ONE; }

}  // namespace

TEST_CASE("fuzz: 100k random steps per family keep the invariants") {
  for (const FamilyModule* fam : FamilyRegistry::builtin().all()) {
    Pcg32 rng(fnv1a64(fam->id()), 77);
    InputFrame in;
    std::int64_t done = 0;
    int locks = 0, bad = 0;
    std::uint64_t seed = 1;
    while (done < FUZZ_STEPS && bad < 5) {
      const int tier = fam->min_tier() + static_cast<int>(rng.below(static_cast<std::uint32_t>(fam->max_tier() - fam->min_tier() + 1)));
      const LockSpec spec = fam->generate(seed++, fam->difficulty_for_tier(tier));
      LockSession s(*fam, spec, fam->required_tools(spec));
      ++locks;
      const int n = static_cast<int>(s.describe().elements.size());
      for (std::int64_t k = 0; k < MAX_LOCK_STEPS && done < FUZZ_STEPS && !s.finished(); ++k, ++done) {
        in.tension = walk(rng, in.tension, 0, Q16_ONE);
        in.pick_depth = walk(rng, in.pick_depth, 0, Q16_ONE);
        in.pick_lift = walk(rng, in.pick_lift, -Q16_ONE, Q16_ONE);
        in.rotate = walk(rng, in.rotate, -Q16_ONE, Q16_ONE);
        in.push = walk(rng, in.push, 0, Q16_ONE);
        if (rng.below(300) == 0) in.tool = static_cast<std::uint8_t>(rng.below(4));
        const std::int64_t t = s.t_step();
        const StepOutput& out = s.step(in);
        bool ok = in01(out.tension_resistance) && in01(out.pick_drag);
        for (const auto& e : out.events) {
          ok = ok && e.t_step == t && in01(e.intensity) && e.element >= -1 && e.element < n &&
               static_cast<int>(e.kind) < EVENT_KIND_COUNT;
          if (e.sub != 0) ok = ok && !fam->event_name(e.sub).empty();
        }
        const ViewModel v = s.describe();
        ok = ok && static_cast<int>(v.elements.size()) == n && in01(v.stress) && in01(v.core_rotation) &&
             v.pick_element >= -1 && v.pick_element < n;
        for (const auto& el : v.elements) ok = ok && in01(el.position) && el.window_lo <= el.window_hi;
        ok = ok && s.state().tool.stress() >= 0;
        if (!ok && bad++ < 5) {
          std::cerr << "fuzz " << fam->id() << " t" << tier << " seed " << spec.seed << " step " << t
                    << ": invariant broken (res " << out.tension_resistance << " drag " << out.pick_drag << " stress "
                    << v.stress << " rot " << v.core_rotation << " pick " << v.pick_element << ")";
          for (const auto& e : out.events)
            std::cerr << " [" << event_kind_name(e.kind) << " sub " << e.sub << " el " << e.element << " i " << e.intensity << "]";
          for (const auto& el : v.elements) std::cerr << " p" << el.position;
          std::cerr << "\n";
        }
      }
    }
    CHECK_EQ(bad, 0);
    CHECK(done == FUZZ_STEPS);
    CHECK(locks >= 1);
  }
}
