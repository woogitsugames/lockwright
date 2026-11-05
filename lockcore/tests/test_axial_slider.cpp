#include "helpers.hpp"
#include "testing.hpp"

using namespace lockcore;
using th::Log;

namespace {

const FamilyModule& fam() { return th::module(lever::SLIDER_FAMILY_ID); }

}  // namespace

TEST_CASE("slider: solver opens 200 seeds per tier") { th::check_family_solves(fam(), 200); }

TEST_CASE("slider: tiers 1-3, pusher tool, no detector, false notches from t2") {
  CHECK_EQ(fam().min_tier(), 1);
  CHECK_EQ(fam().max_tier(), 3);
  CHECK((fam().input_mask() & AXIS_ROTATE) == 0);
  const LockSpec spec = fam().generate(4, fam().difficulty_for_tier(3));
  CHECK(fam().required_tools(spec).has(TOOL_SLIDER_PUSHER));
  const auto& P = static_cast<const lever::Params&>(*spec.params);
  CHECK(!P.detector);
  CHECK_EQ(static_cast<int>(P.levers.size()), 6);
  for (const auto& l : P.levers) CHECK_EQ(static_cast<int>(l.false_gates.size()), 1);
  CHECK_EQ(fam().difficulty_for_tier(1).sec_max, 0);
  CHECK(fam().event_name(lever::SUB_FALSE_GATE) == "slider.false_notch");
}

TEST_CASE("slider: a false notch catches; the counter-rotation band lets the slider on to its gate") {
  LockSpec spec = fam().generate(4, fam().difficulty_for_tier(3));
  const auto& P = static_cast<const lever::Params&>(*spec.params);
  const auto order = th::binding_order(P.levers, [](const lever::Lever& l) { return l.order; });
  const int first = order[0];
  const int n = static_cast<int>(P.levers.size());
  LockSession s(fam(), spec);
  Log log;
  const q16 work = P.levers[static_cast<std::size_t>(first)].band_lo + P.tension_band / 2;
  REQUIRE(th::lift_until(s, first, work, q16_milli(3), q16_milli(900), EventKind::false_set, log));
  CHECK(s.describe().elements[static_cast<std::size_t>(first)].state == ElementState::false_set);
  const q16 at = s.describe().elements[static_cast<std::size_t>(first)].position;
  (void)n;
  CHECK(th::lift_until(s, first, (P.cr_lo + P.cr_hi) / 2, q16_milli(2), q16_milli(900), EventKind::set, log, at));
  CHECK(log.count(EventKind::counter_rotate, first) >= 1);
}

TEST_CASE("slider: lock file round trip") {
  const LockSpec spec = fam().generate(5, fam().difficulty_for_tier(2));
  const std::string text = lock_to_json(spec, fam());
  const LockParse back = lock_from_json(text, FamilyRegistry::builtin());
  REQUIRE(back.ok);
  CHECK(lock_to_json(back.spec, fam()) == text);
}
