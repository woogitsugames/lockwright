#include "helpers.hpp"
#include "testing.hpp"

using namespace lockcore;
using th::Log;

namespace {

const FamilyModule& fam() { return th::module(ring::FAMILY_ID); }

// Three rings, bind order 0, 1, 2; gates 3, 7, 0; all start on digit 5.
std::shared_ptr<ring::Params> authored() {
  auto P = std::make_shared<ring::Params>();
  P->positions = 10;
  P->gate_win = ring::GATE_WIN;
  P->tension_band = q16_milli(250);
  P->t_hold = ring::T_HOLD;
  P->drop_grace_steps = 36;
  P->gate_feel = q16_milli(700);
  P->rot_speed = ring::ROT_SPEED;
  P->bound_rot_speed = ring::BOUND_ROT_SPEED;
  P->snap_speed = ring::SNAP_SPEED;
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
  spec.family = std::string(ring::FAMILY_ID);
  spec.rules_version = ring::RULES_VERSION;
  spec.id = "test.ring";
  spec.source = "authored";
  spec.seed = 1;
  spec.difficulty = fam().difficulty_for_tier(2);
  spec.params = std::move(P);
  return spec;
}

constexpr q16 WORK = q16_milli(360);

InputFrame turn(q16 tension, int ring, q16 rotate) {
  InputFrame f;
  f.tension = tension;
  f.pick_depth = element_center(ring, 3);
  f.rotate = rotate;
  return f;
}

// Turns `ring` until `kind` is emitted for it or `steps` pass; returns the max drag seen.
q16 turn_until(LockSession& s, int ring, q16 tension, q16 rotate, int steps, EventKind kind, Log& log, bool* hit = nullptr) {
  q16 max_drag = 0;
  if (hit) *hit = false;
  for (int i = 0; i < steps; ++i) {
    const auto& out = s.step(turn(tension, ring, rotate));
    log.events.insert(log.events.end(), out.events.begin(), out.events.end());
    max_drag = q_max(max_drag, out.pick_drag);
    for (const auto& e : out.events) {
      if (e.kind == kind && e.sub == 0 && e.element == ring) {
        if (hit) *hit = true;
        return max_drag;
      }
    }
  }
  return max_drag;
}

}  // namespace

TEST_CASE("ring: solver opens 200 seeds per tier") { th::check_family_solves(fam(), 200); }

TEST_CASE("ring: only the bound ring resists; it drops into its gate, then the next binds") {
  LockSession s(fam(), spec_of(authored()));
  Log log;
  // Ring 1 is not the binding one: it turns freely, no drag, no set.
  CHECK_EQ(turn_until(s, 1, WORK, q16_milli(400), 240, EventKind::set, log), 0);
  bool hit = false;
  const q16 drag = turn_until(s, 0, WORK, q16_milli(400), 600, EventKind::set, log, &hit);
  CHECK(hit);
  CHECK(drag > 0);
  CHECK_EQ(log.count(EventKind::gate_align, 0), 1);
  CHECK(log.first(EventKind::near_shear, 0) >= 0);
  // A set ring is held while the shackle is pulled; the next ring binds.
  const q16 pos = s.describe().elements[0].position;
  th::run(s, turn(WORK, 0, Q16_ONE), 60, log);
  CHECK(log.first(EventKind::bind, 1) > log.first(EventKind::set, 0));
  CHECK_EQ(s.describe().elements[0].position, pos);
}

TEST_CASE("ring: one detent click per digit") {
  LockSession s(fam(), spec_of(authored()));
  Log log;
  // Loose ring, full speed for one second = half a turn = 5 digits.
  th::run(s, turn(0, 2, Q16_ONE), SIM_HZ, log);
  const int clicks = log.count(EventKind::contact, 2, ring::SUB_DETENT);
  CHECK(clicks >= 4 && clicks <= 6);
  CHECK(fam().event_name(ring::SUB_DETENT) == "ring.detent");
}

TEST_CASE("ring: pulling too hard locks the bound ring") {
  LockSession s(fam(), spec_of(authored()));
  Log log;
  const q16 before = s.describe().elements[0].position;
  const q16 drag = turn_until(s, 0, Q16_ONE, q16_milli(400), 240, EventKind::set, log);
  CHECK_EQ(s.describe().elements[0].position, before);
  CHECK(drag >= q16_milli(300));
  CHECK_EQ(log.count(EventKind::break_), 0);
}

TEST_CASE("ring: a false notch catches until the pull is eased") {
  auto P = authored();
  P->rings[0].false_gates = {1};  // between start 5 and gate 3 going down
  LockSession s(fam(), spec_of(P));
  Log log;
  bool hit = false;
  turn_until(s, 0, WORK, -q16_milli(400), 600, EventKind::false_set, log, &hit);
  REQUIRE(!hit);  // turning down from 5 reaches the gate (3) before the notch (1)
  LockSession s2(fam(), spec_of(P));
  Log log2;
  turn_until(s2, 0, WORK, q16_milli(400), 600, EventKind::false_set, log2, &hit);  // 5 -> 6 ... 0 -> 1
  REQUIRE(hit);
  CHECK(s2.describe().elements[0].state == ElementState::false_set);
  CHECK_EQ(log2.count(EventKind::bind, 1), 0);  // the catch blocks the others
  const q16 caught = s2.describe().elements[0].position;
  th::run(s2, turn(WORK, 0, q16_milli(400)), 60, log2);
  CHECK_EQ(s2.describe().elements[0].position, caught);
  // Ease below band_lo (still above t_hold): free again, turn past, pull, it sets.
  th::run(s2, turn(q16_milli(150), 0, q16_milli(400)), 40, log2);
  CHECK(s2.describe().elements[0].state != ElementState::false_set);
  turn_until(s2, 0, WORK, q16_milli(400), 600, EventKind::set, log2, &hit);
  CHECK(hit);
  CHECK_EQ(log2.count(EventKind::drop), 0);
}

TEST_CASE("ring: letting go loses nothing but the set flags") {
  LockSession s(fam(), spec_of(authored()));
  Log log;
  bool hit = false;
  turn_until(s, 0, WORK, q16_milli(400), 600, EventKind::set, log, &hit);
  REQUIRE(hit);
  th::run(s, turn(0, 0, 0), 40, log);
  CHECK_EQ(log.count(EventKind::drop), 1);
  CHECK(s.describe().elements[0].state == ElementState::free);
  // Pull again: ring 0 is still at its gate and re-sets at once.
  th::run(s, turn(WORK, 1, 0), 2, log);
  CHECK_EQ(log.count(EventKind::set, 0), 2);
  CHECK(s.describe().elements[1].state == ElementState::bound);
}

TEST_CASE("ring: lock file round trip") {
  const LockSpec spec = fam().generate(5, fam().difficulty_for_tier(3));
  const std::string text = lock_to_json(spec, fam());
  const LockParse back = lock_from_json(text, FamilyRegistry::builtin());
  REQUIRE(back.ok);
  CHECK(lock_to_json(back.spec, fam()) == text);
}
