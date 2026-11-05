#include "helpers.hpp"
#include "testing.hpp"

using namespace lockcore;
using th::Log;

namespace {

const FamilyModule& fam() { return th::module(ring::COMBO_FAMILY_ID); }

// Three thumbwheels, bind order 0, 1, 2; gates 3, 7, 0; all start on digit 5.
std::shared_ptr<ring::Params> authored() {
  auto P = std::make_shared<ring::Params>();
  P->positions = 10;
  P->gate_win = ring::GATE_WIN;
  P->tension_band = q16_milli(300);
  P->t_hold = ring::T_HOLD;
  P->drop_grace_steps = 42;
  P->gate_feel = q16_milli(850);
  P->rot_speed = ring::ROT_SPEED;
  P->bound_rot_speed = ring::BOUND_ROT_SPEED;
  P->snap_speed = ring::SNAP_SPEED;
  P->slip_speed = q_mul(q16_milli(700), ring::ROT_SPEED);
  const std::int32_t gates[] = {3, 7, 0};
  for (int i = 0; i < 3; ++i) {
    ring::Ring r;
    r.gate = gates[i];
    r.start = 5;
    r.order = q16_milli(100) * i;
    r.band_lo = q16_milli(240);
    P->rings.push_back(r);
  }
  return P;
}

LockSpec spec_of(std::shared_ptr<ring::Params> P) {
  LockSpec spec;
  spec.family = std::string(ring::COMBO_FAMILY_ID);
  spec.rules_version = ring::COMBO_RULES_VERSION;
  spec.id = "test.combo";
  spec.source = "authored";
  spec.seed = 1;
  spec.difficulty = fam().difficulty_for_tier(1);
  spec.params = std::move(P);
  return spec;
}

constexpr q16 WORK = q16_milli(380);

InputFrame spin(q16 tension, int wheel, q16 lift) {
  InputFrame f;
  f.tension = tension;
  f.pick_depth = element_center(wheel, 3);
  f.pick_lift = lift;
  return f;
}

bool spin_until(LockSession& s, int wheel, q16 tension, q16 lift, int steps, EventKind kind, Log& log,
                std::uint16_t sub = 0) {
  for (int i = 0; i < steps; ++i) {
    const auto& out = s.step(spin(tension, wheel, lift));
    log.events.insert(log.events.end(), out.events.begin(), out.events.end());
    for (const auto& e : out.events)
      if (e.kind == kind && e.sub == sub && e.element == wheel) return true;
  }
  return false;
}

}  // namespace

TEST_CASE("combo: solver opens 200 seeds per tier") { th::check_family_solves(fam(), 200); }

TEST_CASE("combo: thumb spins the wheel through pick_lift; rotate is ignored") {
  CHECK((fam().input_mask() & AXIS_ROTATE) == 0);
  CHECK((fam().input_mask() & AXIS_LIFT) != 0);
  LockSession s(fam(), spec_of(authored()));
  Log log;
  InputFrame f = spin(0, 2, 0);
  f.rotate = Q16_ONE;
  th::run(s, f, SIM_HZ, log);
  CHECK_EQ(log.count(EventKind::contact, 2, ring::SUB_DETENT), 0);
  th::run(s, spin(0, 2, Q16_ONE), SIM_HZ, log);
  const int clicks = log.count(EventKind::contact, 2, ring::SUB_DETENT);
  CHECK(clicks >= 4 && clicks <= 6);
  CHECK(fam().event_name(ring::SUB_DETENT) == "combo.detent");
  CHECK(fam().event_name(ring::SUB_SLIP) == "combo.slip");
}

TEST_CASE("combo: the bound wheel drops into its gate when spun slowly under pull") {
  LockSession s(fam(), spec_of(authored()));
  Log log;
  CHECK(spin_until(s, 0, WORK, q16_milli(400), 600, EventKind::set, log));
  CHECK_EQ(log.count(EventKind::gate_align, 0), 1);
  th::run(s, spin(WORK, 1, 0), 2, log);
  CHECK(s.describe().elements[1].state == ElementState::bound);
}

TEST_CASE("combo: spun too fast under pull the sleeve slips and the notch goes by") {
  LockSession s(fam(), spec_of(authored()));
  Log log;
  // Full deflection on the bound wheel: slip, no set during two full turns.
  const bool set = spin_until(s, 0, WORK, Q16_ONE, SIM_HZ * 4, EventKind::set, log);
  CHECK(!set);
  CHECK_EQ(log.count(EventKind::overset, 0, ring::SUB_SLIP), 1);  // once per slip episode
  CHECK(s.describe().elements[0].state == ElementState::overset);
  // Slow down: it catches on the next pass.
  CHECK(spin_until(s, 0, WORK, q16_milli(400), 600, EventKind::set, log));
  CHECK(s.describe().elements[0].state == ElementState::set);
  // A free (unbound) wheel never slips.
  LockSession s2(fam(), spec_of(authored()));
  Log log2;
  th::run(s2, spin(0, 2, Q16_ONE), SIM_HZ * 2, log2);
  CHECK_EQ(log2.count(EventKind::overset, -2, ring::SUB_SLIP), 0);
}

TEST_CASE("combo: tiers 1-4, t1 has no false notches, t3+ has some") {
  CHECK_EQ(fam().min_tier(), 1);
  CHECK_EQ(fam().max_tier(), 4);
  CHECK_EQ(fam().difficulty_for_tier(1).sec_max, 0);
  CHECK(fam().difficulty_for_tier(3).sec_max >= 1);
  const LockSpec spec = fam().generate(9, fam().difficulty_for_tier(1));
  CHECK_EQ(spec.family, std::string("combo"));
  CHECK(static_cast<const ring::Params&>(*spec.params).slip_speed > 0);
}

TEST_CASE("combo: lock file round trip keeps slip_speed") {
  const LockSpec spec = fam().generate(5, fam().difficulty_for_tier(3));
  const std::string text = lock_to_json(spec, fam());
  CHECK(text.find("slip_speed_q16") != std::string::npos);
  const LockParse back = lock_from_json(text, FamilyRegistry::builtin());
  REQUIRE(back.ok);
  CHECK(lock_to_json(back.spec, fam()) == text);
  // ring_combo files never carry it.
  const FamilyModule& ringf = th::module(ring::FAMILY_ID);
  CHECK(lock_to_json(ringf.generate(5, ringf.difficulty_for_tier(3)), ringf).find("slip_speed") == std::string::npos);
}
