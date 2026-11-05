#include "helpers.hpp"
#include "testing.hpp"

using namespace lockcore;
using th::Log;

namespace {

std::shared_ptr<lever::Params> authored(bool detector, int n = 3) {
  auto P = std::make_shared<lever::Params>();
  P->win_gate = q16_milli(120);
  P->overset_margin = q16_milli(100);
  P->tension_band = q16_milli(260);
  P->t_hold = lever::T_HOLD;
  P->t_release = lever::T_RELEASE;
  P->tau_safe = q16_milli(560);
  P->cr_lo = lever::CR_LO;
  P->cr_hi = lever::CR_HI;
  P->drop_grace_steps = 36;
  P->s_max = Q16_ONE;
  P->stress_gain = lever::STRESS_GAIN;
  P->bound_speed = lever::BOUND_SPEED;
  P->false_speed = lever::FALSE_SPEED;
  P->spring_speed = q16_per_step(q16_milli(1200));
  P->detector = detector;
  P->detector_margin = q16_milli(150);
  P->reset_steps = 60;
  P->max_trips = 3;
  P->reset_wear = 2;
  for (int i = 0; i < n; ++i) {
    lever::Lever l;
    l.target = q16_milli(550);
    l.order = q16_milli(100) * i;
    l.band_lo = q16_milli(240);
    P->levers.push_back(l);
  }
  return P;
}

LockSpec spec_of(std::shared_ptr<lever::Params> P) {
  const bool det = P->detector;
  const FamilyModule& fam = th::module(det ? lever::DETECTOR_FAMILY_ID : lever::FAMILY_ID);
  LockSpec spec;
  spec.family = std::string(fam.id());
  spec.rules_version = lever::RULES_VERSION;
  spec.id = "test.lever";
  spec.source = "authored";
  spec.seed = 1;
  spec.difficulty = fam.difficulty_for_tier(fam.min_tier());
  spec.params = std::move(P);
  return spec;
}

const FamilyModule& lever_fam() { return th::module(lever::FAMILY_ID); }
const FamilyModule& det_fam() { return th::module(lever::DETECTOR_FAMILY_ID); }
constexpr q16 WORK = q16_milli(370);

}  // namespace

TEST_CASE("lever: solver opens 100 seeds per tier (lever and lever_detector)") {
  th::check_family_solves(lever_fam(), 100);
  th::check_family_solves(det_fam(), 100);
}

TEST_CASE("lever: authored specs validate; detector flag must match the family") {
  CHECK(lever_fam().validate(spec_of(authored(false))).empty());
  CHECK(det_fam().validate(spec_of(authored(true))).empty());
  LockSpec wrong = spec_of(authored(false));
  wrong.family = std::string(lever::DETECTOR_FAMILY_ID);
  CHECK(!det_fam().validate(wrong).empty());
  CHECK(lever_fam().oracle(spec_of(authored(false)), ToolSet{TOOL_LEVER_CRANK}).ok);
  CHECK(!lever_fam().oracle(spec_of(authored(false)), ToolSet{}).ok);
}

TEST_CASE("lever: gate_align with set; a bound lever falls back on its spring") {
  LockSession s(lever_fam(), spec_of(authored(false)));
  Log log;
  // Lift lever 0 part way, then let go: it falls back (not held like a pin).
  th::lift_until(s, 0, WORK, q16_milli(5), q16_milli(300), EventKind::set, log);
  const q16 high = s.describe().elements[0].position;
  CHECK(high > q16_milli(200));
  th::run(s, th::frame(WORK, element_center(0, 3), 0), 30, log);
  CHECK(s.describe().elements[0].position < high / 2);
  REQUIRE(th::lift_until(s, 0, WORK, q16_milli(5), q16_milli(900), EventKind::set, log));
  CHECK_EQ(log.count(EventKind::gate_align, 0), 1);
  CHECK(log.first(EventKind::near_shear, 0) >= 0);
  CHECK(s.describe().elements[0].state == ElementState::set);
}

TEST_CASE("lever: false gate catches; escape only in the counter-rotation band") {
  auto P = authored(false, 2);
  P->levers[0].false_gates = {q16_milli(360)};
  LockSession s(lever_fam(), spec_of(P));
  Log log;
  REQUIRE(th::lift_until(s, 0, WORK, q16_milli(5), q16_milli(900), EventKind::false_set, log));
  CHECK_EQ(log.count(EventKind::false_set, 0, lever::SUB_FALSE_GATE), 1);
  CHECK(s.describe().elements[0].state == ElementState::false_set);
  // Working tension (above cr_hi): the lever does not rise, the crank is loaded.
  th::run(s, th::frame(WORK, element_center(0, 2), q16_milli(700)), 60, log);
  CHECK(s.describe().elements[0].state == ElementState::false_set);
  CHECK(log.count(EventKind::counter_rotate, 0) >= 3);
  CHECK(s.describe().stress > 0);
  // Ease into [cr_lo, cr_hi]: it rises into the gate.
  const q16 cr = (lever::CR_LO + lever::CR_HI) / 2;
  th::run(s, th::frame(cr, element_center(0, 2), q16_milli(700)), 90, log);
  CHECK(s.describe().elements[0].state == ElementState::set);
  CHECK_EQ(log.count(EventKind::drop), 0);
}

TEST_CASE("lever: set_speed keeps a lever that leaves a false gate from jumping over its gate") {
  // The lifter runs ahead of a caught lever (working tension, no rise). When the
  // tension is eased, the lever sets; with set_speed it then follows the lifter only
  // slowly (rules 2), with set_speed = 0 (rules 1) it jumps to the lifter and oversets.
  for (const bool slow : {true, false}) {
    auto P = authored(false, 2);
    P->levers[0].false_gates = {q16_milli(360)};
    P->set_speed = slow ? lever::SET_SPEED : 0;
    CHECK(lever_fam().validate(spec_of(P)).empty());
    LockSession s(lever_fam(), spec_of(P));
    Log log;
    REQUIRE(th::lift_until(s, 0, WORK, q16_milli(5), q16_milli(900), EventKind::false_set, log));
    th::run(s, th::frame(WORK, element_center(0, 2), q16_milli(900)), 30, log);
    const q16 cr = (lever::CR_LO + lever::CR_HI) / 2;
    for (int i = 0; i < 90 && log.first(EventKind::set, 0) < 0; ++i)
      th::run(s, th::frame(cr, element_center(0, 2), q16_milli(900)), 1, log);
    const std::int64_t t_set = log.first(EventKind::set, 0);
    REQUIRE(t_set >= 0);
    // A reaction time later (~170 ms) the slow lever is still well below the overset.
    th::run(s, th::frame(cr, element_center(0, 2), q16_milli(900)), 20, log);
    if (slow) {
      CHECK_EQ(log.count(EventKind::overset, 0), 0);
      CHECK(s.describe().elements[0].state == ElementState::set);
      CHECK(s.describe().elements[0].position <= P->levers[0].target - P->win_gate / 2 + 22 * lever::SET_SPEED);
    } else {
      CHECK_EQ(log.count(EventKind::overset, 0), 1);
      CHECK(log.first(EventKind::overset, 0) - t_set <= 1);
    }
  }
}

TEST_CASE("lever: overset jams until T < t_release, which drops") {
  LockSession s(lever_fam(), spec_of(authored(false)));
  Log log;
  REQUIRE(th::lift_until(s, 0, WORK, q16_milli(5), q16_milli(900), EventKind::set, log));
  th::run(s, th::frame(WORK, 0, 0), 2, log);
  REQUIRE(th::lift_until(s, 1, WORK, q16_milli(5), q16_milli(990), EventKind::overset, log));
  th::run(s, th::frame(WORK, 0, 0), 30, log);
  CHECK(s.describe().elements[1].state == ElementState::overset);
  th::run(s, th::frame(0, 0, 0), 40, log);
  CHECK(s.describe().elements[1].state == ElementState::free);
  CHECK_EQ(log.count(EventKind::drop), 1);
  CHECK(s.describe().elements[0].state == ElementState::free);
}

TEST_CASE("lever_detector: trip jams everything, rotate-back resets, third trip blocks") {
  const LockSpec spec = spec_of(authored(true));
  const auto& P = static_cast<const lever::Params&>(*spec.params);
  LockSession s(det_fam(), spec);
  Log log;
  for (int trip = 1; trip <= 3; ++trip) {
    // A loose lever lifted above the detector height trips it.
    th::run(s, th::frame(0, element_center(2, 3), Q16_ONE), 4, log);
    CHECK_EQ(log.count(EventKind::detector_trip), trip);
    for (const auto& e : s.describe().elements) CHECK(e.state == ElementState::jammed);
    if (trip == 3) break;
    // Turning forward or holding tension does not reset.
    th::run(s, th::frame(WORK, 0, 0), P.reset_steps + 5, log);
    CHECK_EQ(log.count(EventKind::drop, -2, lever::SUB_DETECTOR_RESET), trip - 1);
    CHECK_EQ(s.describe().reset_progress, 0);  // forward / tension: no progress
    InputFrame back = th::frame(0, 0, 0);
    back.rotate = -Q16_ONE;
    q16 prev = 0;
    for (int i = 0; i < P.reset_steps; ++i) {
      const auto& out = s.step(back);
      log.events.insert(log.events.end(), out.events.begin(), out.events.end());
      const q16 r = s.describe().reset_progress;
      if (i + 1 < P.reset_steps) {
        CHECK(r > prev);
        CHECK(r < Q16_ONE);
        prev = r;
      } else {
        CHECK_EQ(r, 0);  // reset done: detector released
      }
    }
    CHECK_EQ(s.describe().hold_progress, 0);
    CHECK_EQ(log.count(EventKind::drop, -2, lever::SUB_DETECTOR_RESET), trip);
    CHECK(s.describe().elements[0].state == ElementState::free);
    CHECK_EQ(s.state().tool.wear(), 2 * trip);
  }
  CHECK(s.failure() == FailureKind::detector_trip);
  CHECK(s.finished());
}

TEST_CASE("lever_detector: letting go of the rotate-back clears reset_progress") {
  const LockSpec spec = spec_of(authored(true));
  LockSession s(det_fam(), spec);
  Log log;
  th::run(s, th::frame(0, element_center(2, 3), Q16_ONE), 4, log);
  REQUIRE(log.count(EventKind::detector_trip) == 1);
  InputFrame back = th::frame(0, 0, 0);
  back.rotate = -Q16_ONE;
  for (int i = 0; i < 10; ++i) s.step(back);
  CHECK(s.describe().reset_progress > 0);
  s.step(th::frame(0, 0, 0));
  CHECK_EQ(s.describe().reset_progress, 0);
}

TEST_CASE("progress fields stay 0 in families without them") {
  for (const char* id : {"pin_tumbler", "wafer", "warded", "lever", "ring_combo"}) {
    const FamilyModule& f = th::module(id);
    const LockSpec spec = f.generate(1, f.difficulty_for_tier(2));
    LockSession s(f, spec);
    for (int i = 0; i < 50; ++i) {
      s.step(th::frame(WORK, element_center(0, 3), q16_milli(300)));
      CHECK_EQ(s.describe().hold_progress, 0);
      CHECK_EQ(s.describe().reset_progress, 0);
    }
  }
}

TEST_CASE("lever_detector: overset or detector depends on the margins") {
  // overset_margin 0.10 < detector_margin 0.15: an overset comes first.
  LockSession s(det_fam(), spec_of(authored(true)));
  Log log;
  REQUIRE(th::lift_until(s, 0, WORK, q16_milli(5), q16_milli(900), EventKind::set, log));
  CHECK(th::lift_until(s, 0, WORK, q16_milli(2), q16_milli(990), EventKind::overset, log, q16_milli(500)));
  CHECK_EQ(log.count(EventKind::detector_trip), 0);
  // Narrow detector margin: the detector trips before any overset.
  auto P = authored(true);
  P->detector_margin = q16_milli(60);
  LockSession s2(det_fam(), spec_of(P));
  Log log2;
  REQUIRE(th::lift_until(s2, 0, WORK, q16_milli(5), q16_milli(900), EventKind::set, log2));
  CHECK(th::lift_until(s2, 0, WORK, q16_milli(2), q16_milli(990), EventKind::detector_trip, log2, q16_milli(500)));
  CHECK_EQ(log2.count(EventKind::overset), 0);
}

TEST_CASE("lever: lock file round trip (both families)") {
  for (const FamilyModule* fam : {&lever_fam(), &det_fam()}) {
    const LockSpec spec = fam->generate(9, fam->difficulty_for_tier(fam->max_tier()));
    const std::string text = lock_to_json(spec, *fam);
    const LockParse back = lock_from_json(text, FamilyRegistry::builtin());
    REQUIRE(back.ok);
    CHECK(lock_to_json(back.spec, *fam) == text);
  }
}
