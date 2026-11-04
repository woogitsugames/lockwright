#include "helpers.hpp"
#include "testing.hpp"

using namespace lockcore;
using th::Log;

TEST_CASE("wafer: solver opens every tier") {
  const auto& fam = th::wafer_module();
  for (int tier = fam.min_tier(); tier <= fam.max_tier(); ++tier) {
    for (std::uint64_t seed = 1; seed <= 100; ++seed) {
      const LockSpec spec = fam.generate(seed, fam.difficulty_for_tier(tier));
      const SolveReport r = fam.solver(spec, ToolSet{});
      if (!r.ok) std::cerr << "wafer t" << tier << " seed " << seed << ": " << r.reason << "\n";
      CHECK(r.ok);
    }
  }
}

TEST_CASE("wafer: overset clears above t_hold, keeping set wafers") {
  const auto& fam = th::wafer_module();
  const LockSpec spec = fam.generate(3, fam.difficulty_for_tier(1));
  const auto& P = static_cast<const wafer::Params&>(*spec.params);
  const int n = static_cast<int>(P.wafers.size());
  std::vector<int> order(static_cast<std::size_t>(n));
  for (int i = 0; i < n; ++i) order[static_cast<std::size_t>(i)] = i;
  std::sort(order.begin(), order.end(), [&](int a, int b) {
    return P.wafers[static_cast<std::size_t>(a)].order < P.wafers[static_cast<std::size_t>(b)].order;
  });
  const q16 work = P.wafers[static_cast<std::size_t>(order[0])].band_lo + P.tension_band / 2;
  const q16 work2 = P.wafers[static_cast<std::size_t>(order[1])].band_lo + P.tension_band / 2;
  LockSession s(fam, spec);
  Log log;
  REQUIRE(th::lift_until(s, order[0], work, q16_milli(4), q16_milli(900), EventKind::set, log));
  th::run(s, th::frame(work2, 0, 0), 2, log);
  REQUIRE(th::lift_until(s, order[1], work2, q16_milli(4), q16_milli(990), EventKind::overset, log));
  CHECK(s.describe().elements[static_cast<std::size_t>(order[1])].state == ElementState::overset);
  // Ease to between t_hold and t_release for longer than drop_grace: no drop.
  th::run(s, th::frame((P.t_hold + P.t_release) / 2, 0, 0), P.drop_grace_steps + 10, log);
  CHECK_EQ(log.count(EventKind::drop), 0);
  CHECK(s.describe().elements[static_cast<std::size_t>(order[0])].state == ElementState::set);
  CHECK(s.describe().elements[static_cast<std::size_t>(order[1])].state == ElementState::free);
}

TEST_CASE("wafer: fast sweep rattles") {
  const auto& fam = th::wafer_module();
  LockSession s(fam, fam.generate(1, fam.difficulty_for_tier(2)));
  Log log;
  for (int i = 0; i < 30; ++i) {
    const auto& out = s.step(th::frame(0, (i % 2) ? q16_milli(900) : q16_milli(100), q16_milli(200)));
    log.events.insert(log.events.end(), out.events.begin(), out.events.end());
  }
  CHECK(log.count(EventKind::contact, -2, wafer::SUB_RATTLE) >= 2);
}
