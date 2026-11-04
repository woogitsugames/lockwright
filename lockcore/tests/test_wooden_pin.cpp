#include "helpers.hpp"
#include "testing.hpp"

using namespace lockcore;
using th::Log;

namespace {

const FamilyModule& fam() { return th::module(wooden::FAMILY_ID); }

std::shared_ptr<wooden::Params> tutorial(int n, bool overset) {
  auto P = std::make_shared<wooden::Params>();
  P->win_shear = q16_milli(180);
  P->overset_enabled = overset;
  P->overset_margin = q16_milli(150);
  P->tension_band = q16_milli(300);
  P->t_hold = wooden::T_HOLD;
  P->t_release = wooden::T_RELEASE;
  P->tau_creak = q16_milli(620);
  P->drop_grace_steps = 36;
  P->open_hold_steps = 36;
  P->bound_speed = wooden::BOUND_SPEED;
  for (int i = 0; i < n; ++i) {
    wooden::Peg k;
    k.target = q16_milli(500);
    k.order = q16_milli(100) * i;
    k.band_lo = q16_milli(250);
    P->pegs.push_back(k);
  }
  return P;
}

LockSpec spec_of(std::shared_ptr<wooden::Params> P) {
  LockSpec spec;
  spec.family = std::string(wooden::FAMILY_ID);
  spec.rules_version = wooden::RULES_VERSION;
  spec.id = "test.wooden";
  spec.source = "authored";
  spec.seed = 1;
  spec.difficulty = fam().difficulty_for_tier(1);
  spec.material = MaterialId::wood;
  spec.params = std::move(P);
  return spec;
}

constexpr q16 WORK = q16_milli(400);

}  // namespace

TEST_CASE("wooden: solver opens 200 seeds") { th::check_family_solves(fam(), 200); }

TEST_CASE("wooden: authored tutorial validates; peg lifter only") {
  const LockSpec spec = spec_of(tutorial(2, false));
  CHECK(fam().validate(spec).empty());
  CHECK(fam().oracle(spec, ToolSet{TOOL_PEG_LIFTER}).ok);
  CHECK(!fam().oracle(spec, ToolSet{TOOL_TENSION_WRENCH | TOOL_HOOK}).ok);
}

TEST_CASE("wooden: pegs set in order, open needs the bolt held for 0.3 s") {
  LockSession s(fam(), spec_of(tutorial(2, true)));
  Log log;
  REQUIRE(th::lift_until(s, 0, WORK, q16_milli(5), q16_milli(800), EventKind::set, log));
  CHECK(log.first(EventKind::near_shear, 0) >= 0);
  th::run(s, th::frame(WORK, 0, 0), 2, log);
  REQUIRE(th::lift_until(s, 1, WORK, q16_milli(5), q16_milli(800), EventKind::set, log));
  CHECK(!s.is_open());
  th::run(s, th::frame(WORK, element_center(1, 2), 0), 34, log);
  CHECK(!s.is_open());
  th::run(s, th::frame(WORK, element_center(1, 2), 0), 3, log);
  CHECK(s.is_open());
  CHECK_EQ(log.count(EventKind::open), 1);
}

TEST_CASE("wooden: letting go of the bolt drops every set peg") {
  LockSession s(fam(), spec_of(tutorial(3, true)));
  Log log;
  REQUIRE(th::lift_until(s, 0, WORK, q16_milli(5), q16_milli(800), EventKind::set, log));
  th::run(s, th::frame(WORK, 0, 0), 2, log);
  REQUIRE(th::lift_until(s, 1, WORK, q16_milli(5), q16_milli(800), EventKind::set, log));
  th::run(s, th::frame(0, 0, 0), 36, log);
  CHECK_EQ(log.count(EventKind::drop), 1);
  CHECK(s.describe().elements[0].state == ElementState::free);
  CHECK(s.describe().elements[1].state == ElementState::free);
}

TEST_CASE("wooden: overset frees above t_hold without a drop; tutorial has no overset") {
  {
    LockSession s(fam(), spec_of(tutorial(3, true)));  // 3 pegs: the lock must not open meanwhile
    Log log;
    REQUIRE(th::lift_until(s, 0, WORK, q16_milli(5), q16_milli(800), EventKind::set, log));
    th::run(s, th::frame(WORK, 0, 0), 2, log);
    REQUIRE(th::lift_until(s, 1, WORK, q16_milli(5), q16_milli(990), EventKind::overset, log));
    th::run(s, th::frame((wooden::T_HOLD + wooden::T_RELEASE) / 2, 0, 0), 60, log);
    CHECK_EQ(log.count(EventKind::drop), 0);
    CHECK(s.describe().elements[0].state == ElementState::set);
    CHECK(s.describe().elements[1].state == ElementState::free);
  }
  {
    LockSession s(fam(), spec_of(tutorial(1, false)));
    Log log;
    REQUIRE(th::lift_until(s, 0, WORK, q16_milli(5), q16_milli(800), EventKind::set, log));
    th::run(s, th::frame(WORK, element_center(0, 1), Q16_ONE), 40, log);
    CHECK_EQ(log.count(EventKind::overset), 0);
    CHECK(s.is_open());
  }
}

TEST_CASE("wooden: a hard pull creaks but never breaks") {
  LockSession s(fam(), spec_of(tutorial(2, true)));
  Log log;
  th::run(s, th::frame(Q16_ONE, element_center(0, 2), q16_milli(300)), 600, log);
  CHECK(log.count(EventKind::stress, -2, wooden::SUB_CREAK) >= 10);
  CHECK_EQ(log.count(EventKind::break_), 0);
  CHECK(s.failure() == FailureKind::none);
  CHECK(fam().event_name(wooden::SUB_CREAK) == "wood.creak");
  // Above t_stick the bound peg does not rise.
  CHECK(s.describe().elements[0].position < q16_milli(100));
}

TEST_CASE("wooden: lock file round trip") {
  const LockSpec spec = fam().generate(42, fam().difficulty_for_tier(1));
  const std::string text = lock_to_json(spec, fam());
  const LockParse back = lock_from_json(text, FamilyRegistry::builtin());
  REQUIRE(back.ok);
  CHECK(lock_to_json(back.spec, fam()) == text);
}
