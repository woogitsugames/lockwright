#include "helpers.hpp"
#include "testing.hpp"

using namespace lockcore;
using th::Log;

namespace {

const FamilyModule& fam() { return th::module(ring::DISC_FAMILY_ID); }

// Four discs, 8 positions, bind order 0..3; gates 2, 5, 7, 1; all start on 4.
std::shared_ptr<ring::Params> authored() {
  auto P = std::make_shared<ring::Params>();
  P->positions = ring::DISC_POSITIONS;
  P->gate_win = ring::GATE_WIN;
  P->tension_band = q16_milli(300);
  P->t_hold = ring::T_HOLD;
  P->drop_grace_steps = 36;
  P->gate_feel = q16_milli(800);
  P->rot_speed = ring::ROT_SPEED;
  P->bound_rot_speed = ring::BOUND_ROT_SPEED;
  P->snap_speed = ring::SNAP_SPEED;
  P->overturn_speed = q_mul(q16_milli(600), ring::ROT_SPEED);
  const std::int32_t gates[] = {2, 5, 7, 1};
  for (int i = 0; i < 4; ++i) {
    ring::Ring r;
    r.gate = gates[i];
    r.start = 4;
    r.order = q16_milli(100) * i;
    r.band_lo = q16_milli(240);
    P->rings.push_back(r);
  }
  return P;
}

LockSpec spec_of(std::shared_ptr<ring::Params> P) {
  LockSpec spec;
  spec.family = std::string(ring::DISC_FAMILY_ID);
  spec.rules_version = ring::DISC_RULES_VERSION;
  spec.id = "test.disc";
  spec.source = "authored";
  spec.seed = 1;
  spec.difficulty = fam().difficulty_for_tier(1);
  spec.material = MaterialId::steel;
  spec.params = std::move(P);
  return spec;
}

constexpr q16 WORK = q16_milli(380);

InputFrame turn(q16 tension, int disc, q16 lift) {
  InputFrame f;
  f.tension = tension;
  f.pick_depth = element_center(disc, 4);
  f.pick_lift = lift;
  return f;
}

bool turn_until(LockSession& s, int disc, q16 tension, q16 lift, int steps, EventKind kind, Log& log, std::uint16_t sub = 0) {
  for (int i = 0; i < steps; ++i) {
    const auto& out = s.step(turn(tension, disc, lift));
    log.events.insert(log.events.end(), out.events.begin(), out.events.end());
    for (const auto& e : out.events)
      if (e.kind == kind && e.sub == sub && e.element == disc) return true;
  }
  return false;
}

}  // namespace

TEST_CASE("disc: solver opens 200 seeds per tier") { th::check_family_solves(fam(), 200); }

TEST_CASE("disc: thumb turns the binding disc both ways into its gate") {
  CHECK((fam().input_mask() & AXIS_LIFT) != 0);
  CHECK(fam().required_tools(spec_of(authored())).has(TOOL_DISC_PICK));
  LockSession s(fam(), spec_of(authored()));
  Log log;
  // Disc 0: from 4 down to its gate at 2.
  CHECK(turn_until(s, 0, WORK, -q16_milli(300), 600, EventKind::set, log));
  CHECK(fam().event_name(ring::SUB_DETENT) == "disc.detent");
  th::run(s, turn(WORK, 1, 0), 2, log);
  CHECK(s.describe().elements[1].state == ElementState::bound);
}

TEST_CASE("disc: a set disc turned too hard leaves its gate; gentle turns are blocked") {
  LockSession s(fam(), spec_of(authored()));
  Log log;
  REQUIRE(turn_until(s, 0, WORK, -q16_milli(300), 600, EventKind::set, log));
  const q16 pos = s.describe().elements[0].position;
  th::run(s, turn(WORK, 0, -q16_milli(300)), 60, log);  // gentle: held by the sidebar
  CHECK_EQ(s.describe().elements[0].position, pos);
  CHECK(s.describe().elements[0].state == ElementState::set);
  CHECK(turn_until(s, 0, WORK, -Q16_ONE, 30, EventKind::overset, log, ring::SUB_OVERTURN));
  CHECK(s.describe().elements[0].state != ElementState::set);
  CHECK(fam().event_name(ring::SUB_OVERTURN) == "disc.overturn");
  // It binds again and can be brought back.
  CHECK(turn_until(s, 0, WORK, q16_milli(300), 900, EventKind::set, log));
}

TEST_CASE("disc: lock file round trip keeps overturn_speed") {
  const LockSpec spec = fam().generate(5, fam().difficulty_for_tier(3));
  const std::string text = lock_to_json(spec, fam());
  CHECK(text.find("overturn_speed_q16") != std::string::npos);
  const LockParse back = lock_from_json(text, FamilyRegistry::builtin());
  REQUIRE(back.ok);
  CHECK(lock_to_json(back.spec, fam()) == text);
}
