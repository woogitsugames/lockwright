#include "helpers.hpp"
#include "testing.hpp"

using namespace lockcore;
using th::Log;

namespace {

const FamilyModule& fam() { return th::module(wooden::EGYPT_FAMILY_ID); }

// Three pegs at 0.5, bind order 0, 1, 2.
LockSpec authored() {
  auto P = std::make_shared<wooden::Params>();
  P->win_shear = q16_milli(180);
  P->overset_enabled = true;
  P->overset_margin = q16_milli(140);
  P->tension_band = q16_milli(300);
  P->t_hold = wooden::T_HOLD;
  P->t_release = wooden::T_RELEASE;
  P->tau_creak = q16_milli(700);
  P->drop_grace_steps = 48;
  P->open_hold_steps = ms_to_steps(wooden::EGYPT_OPEN_HOLD_MS);
  P->bound_speed = wooden::BOUND_SPEED;
  P->fall_speed = wooden::EGYPT_FALL_SPEED;
  for (int i = 0; i < 3; ++i) {
    wooden::Peg g;
    g.target = q16_milli(500);
    g.order = q16_milli(100) * i;
    g.band_lo = q16_milli(250);
    P->pegs.push_back(g);
  }
  LockSpec spec;
  spec.family = std::string(wooden::EGYPT_FAMILY_ID);
  spec.rules_version = wooden::EGYPT_RULES_VERSION;
  spec.id = "test.egyptian";
  spec.source = "authored";
  spec.seed = 1;
  spec.difficulty = fam().difficulty_for_tier(1);
  spec.material = MaterialId::wood;
  spec.params = P;
  return spec;
}

}  // namespace

TEST_CASE("egyptian: solver opens 200 seeds per tier") { th::check_family_solves(fam(), 200); }

TEST_CASE("egyptian: a peg let go falls by gravity, not at once") {
  LockSession s(fam(), authored());
  Log log;
  th::run(s, th::frame(0, element_center(1, 3), q16_milli(600)), 30, log);
  CHECK_EQ(s.describe().elements[1].position, quantize_256(q16_milli(600)));
  th::run(s, th::frame(0, element_center(1, 3), 0), 12, log);  // 0.1 s: falls 0.12
  const q16 p = s.describe().elements[1].position;
  CHECK(p > q16_milli(400));
  CHECK(p < q16_milli(600));
  th::run(s, th::frame(0, element_center(1, 3), 0), SIM_HZ, log);
  CHECK_EQ(s.describe().elements[1].position, 0);
}

TEST_CASE("egyptian: a peg still hanging high wedges when the bolt bites") {
  LockSession s(fam(), authored());
  Log log;
  // Lift peg 0 above its window, let go and pull the bolt at once.
  th::run(s, th::frame(0, element_center(0, 3), q16_milli(800)), 30, log);
  th::run(s, th::frame(q16_milli(350), element_center(2, 3), 0), 2, log);
  CHECK_EQ(log.count(EventKind::overset, 0), 1);
  CHECK(s.describe().elements[0].state == ElementState::overset);
  // Pushing the bolt back in (below t_release) frees it; it falls.
  th::run(s, th::frame(q16_milli(150), element_center(2, 3), 0), SIM_HZ, log);
  CHECK(s.describe().elements[0].state != ElementState::overset);
  CHECK_EQ(s.describe().elements[0].position, 0);
}

TEST_CASE("egyptian: tiers 1-2, bolt slides out for 0.5 s, round trip keeps fall_speed") {
  CHECK_EQ(fam().max_tier(), 2);
  const LockSpec spec = fam().generate(5, fam().difficulty_for_tier(2));
  CHECK_EQ(static_cast<const wooden::Params&>(*spec.params).open_hold_steps, 60);
  const std::string text = lock_to_json(spec, fam());
  CHECK(text.find("fall_speed_q16") != std::string::npos);
  const LockParse back = lock_from_json(text, FamilyRegistry::builtin());
  REQUIRE(back.ok);
  CHECK(lock_to_json(back.spec, fam()) == text);
  const FamilyModule& w = th::module(wooden::FAMILY_ID);
  CHECK(lock_to_json(w.generate(5, w.difficulty_for_tier(1)), w).find("fall_speed") == std::string::npos);
}
