#include "helpers.hpp"
#include "testing.hpp"

using namespace lockcore;
using th::Log;

namespace {

const FamilyModule& fam() { return th::module(dial::FAMILY_ID); }

// Two wheels on a 20-division dial: wheel 0 gate 5, wheel 1 gate 12; mark 0.
std::shared_ptr<dial::Params> authored() {
  auto P = std::make_shared<dial::Params>();
  P->divisions = 20;
  P->dial_start = 0;
  P->open_mark = 0;
  P->gate_win = q16_ratio(24, 200);
  P->band_lo = q16_milli(200);
  P->band_hi = q16_milli(600);
  P->open_hold_steps = dial::OPEN_HOLD_STEPS;
  P->gate_feel = q16_milli(900);
  P->rot_speed = dial::ROT_SPEED;
  P->snap_speed = dial::SNAP_SPEED;
  dial::Wheel w0;
  w0.gate = 5;
  w0.start = 15;
  dial::Wheel w1;
  w1.gate = 12;
  w1.start = 18;
  P->wheels = {w0, w1};
  return P;
}

LockSpec spec_of(std::shared_ptr<dial::Params> P) {
  LockSpec spec;
  spec.family = std::string(dial::FAMILY_ID);
  spec.rules_version = dial::RULES_VERSION;
  spec.id = "test.dial";
  spec.source = "authored";
  spec.seed = 1;
  spec.difficulty = fam().difficulty_for_tier(1);
  spec.material = MaterialId::steel;
  spec.params = std::move(P);
  return spec;
}

constexpr q16 LISTEN = q16_milli(400);

InputFrame dial_in(q16 tension, q16 lift) {
  InputFrame f;
  f.tension = tension;
  f.pick_lift = lift;
  return f;
}

std::int32_t number(const LockSession& s) {
  const ViewModel v = s.describe();
  return static_cast<std::int32_t>(((static_cast<std::int64_t>(v.dial) * v.dial_divisions + Q16_ONE / 2) >> 16) % v.dial_divisions);
}

// Turns slowly in `dir` until `wheel` is carried and the dial shows `num`, then lets
// the detent settle. Returns false if it takes more than `turns` turns.
bool turn_to(LockSession& s, int dir, int wheel, std::int32_t num, q16 tension, Log& log, int turns = 4) {
  const q16 lift = dir * q16_milli(250);
  const int max_steps = turns * SIM_HZ * 5;
  bool carried = false;
  for (int i = 0; i < max_steps; ++i) {
    const auto& out = s.step(dial_in(tension, lift));
    log.events.insert(log.events.end(), out.events.begin(), out.events.end());
    const ElementState st = s.describe().elements[static_cast<std::size_t>(wheel)].state;
    carried = carried || st == ElementState::bound || st == ElementState::near;
    if (carried && number(s) == num) {
      th::run(s, dial_in(tension, 0), 30, log);
      return true;
    }
  }
  return false;
}

}  // namespace

TEST_CASE("dial: solver opens 200 seeds per tier") { th::check_family_solves(fam(), 200); }

TEST_CASE("dial: turning right picks the wheels up one by one; a carried wheel shows the dial's number") {
  LockSession s(fam(), spec_of(authored()));
  Log log;
  th::run(s, dial_in(LISTEN, q16_milli(500)), SIM_HZ * 5, log);
  CHECK_EQ(log.count(EventKind::bind, 1, dial::SUB_PICKUP), 1);
  CHECK_EQ(log.count(EventKind::bind, 0, dial::SUB_PICKUP), 1);
  CHECK(log.first(EventKind::bind, -2) < 0);  // pickups are sub events only
  const ViewModel v = s.describe();
  CHECK_EQ(v.elements[0].position, v.dial);
  CHECK_EQ(v.elements[1].position, v.dial);
  CHECK_EQ(v.pick_element, 0);  // listening reaches wheel 0 now
  CHECK(log.count(EventKind::contact, -1, dial::SUB_DETENT) >= 20);
  CHECK(fam().event_name(dial::SUB_PICKUP) == "safe.pickup");
}

TEST_CASE("dial: gates are heard only with the handle inside the listening band") {
  for (q16 tension : {q16_milli(100), LISTEN}) {
    LockSession s(fam(), spec_of(authored()));
    Log log;
    th::run(s, dial_in(tension, q16_milli(300)), SIM_HZ * 12, log);
    const bool heard = log.count(EventKind::gate_align, 0) > 0;
    CHECK(heard == (tension == LISTEN));
  }
  // Pressed too hard: the pack clamps, the dial does not turn, the thumb feels it.
  LockSession s(fam(), spec_of(authored()));
  Log log;
  const q16 before = s.describe().dial;
  q16 drag = 0;
  for (int i = 0; i < SIM_HZ; ++i) drag = q_max(drag, s.step(dial_in(q16_milli(800), q16_milli(500))).pick_drag);
  CHECK_EQ(s.describe().dial, before);
  CHECK(drag >= q16_milli(400));
  CHECK(s.describe().elements[1].state != ElementState::bound);
}

TEST_CASE("dial: reversing leaves the set wheel; one turn too far drags it off (drop)") {
  LockSession s(fam(), spec_of(authored()));
  Log log;
  REQUIRE(turn_to(s, 1, 0, 5, LISTEN, log));
  CHECK(s.describe().elements[0].state == ElementState::set);
  CHECK_EQ(log.count(EventKind::set, 0), 1);
  CHECK(log.count(EventKind::gate_align, 0) >= 1);
  // Left: wheel 1 is picked up again, wheel 0 stays on 5.
  REQUIRE(turn_to(s, -1, 1, 12, LISTEN, log));
  CHECK(s.describe().elements[0].state == ElementState::set);
  CHECK(s.describe().elements[1].state == ElementState::set);
  CHECK_EQ(log.count(EventKind::drop), 0);
  // Keep turning left: after another turn wheel 0 is picked up and lost.
  th::run(s, dial_in(LISTEN, -q16_milli(500)), SIM_HZ * 4, log);
  CHECK_EQ(log.count(EventKind::drop, 0), 1);
  CHECK(s.describe().elements[0].state != ElementState::set);
}

TEST_CASE("dial: right, left, then the mark: fence drops and the handle opens") {
  LockSession s(fam(), spec_of(authored()));
  Log log;
  REQUIRE(turn_to(s, 1, 0, 5, LISTEN, log));
  REQUIRE(turn_to(s, -1, 1, 12, LISTEN, log));
  // Back to the right onto 0 (less than a turn, so wheel 1 stays).
  for (int i = 0; i < SIM_HZ * 6 && number(s) != 0; ++i) {
    const auto& out = s.step(dial_in(LISTEN, q16_milli(250)));
    log.events.insert(log.events.end(), out.events.begin(), out.events.end());
  }
  CHECK_EQ(log.count(EventKind::drop), 0);
  th::run(s, dial_in(LISTEN, 0), SIM_HZ, log);
  CHECK_EQ(log.count(EventKind::set, -1, dial::SUB_FENCE_DROP), 1);
  CHECK(s.is_open());
  CHECK(s.describe().hold_progress == Q16_ONE);
}

TEST_CASE("dial: handle on the mark with a wheel off its gate bounces") {
  LockSession s(fam(), spec_of(authored()));
  Log log;
  th::run(s, dial_in(LISTEN, 0), 30, log);  // dial starts on the mark
  CHECK_EQ(log.count(EventKind::contact, -1, dial::SUB_FENCE_BOUNCE), 1);
  th::run(s, dial_in(LISTEN, 0), 60, log);
  CHECK_EQ(log.count(EventKind::contact, -1, dial::SUB_FENCE_BOUNCE), 1);  // once per arrival
  CHECK(!s.is_open());
}

TEST_CASE("dial: a false notch sounds different and does not count") {
  auto P = authored();
  P->wheels[0].false_gates = {9};
  LockSession s(fam(), spec_of(P));
  Log log;
  REQUIRE(turn_to(s, 1, 0, 9, LISTEN, log));
  CHECK(s.describe().elements[0].state == ElementState::false_set);
  CHECK(log.count(EventKind::false_set, 0) >= 1);
}

TEST_CASE("dial: oracle rejects a narrow band and numbers too close together") {
  auto P = authored();
  P->band_hi = P->band_lo + q16_milli(50);
  CHECK(!fam().oracle(spec_of(P), fam().required_tools(spec_of(P))).ok);
  auto Q = authored();
  Q->wheels[1].gate = 6;
  CHECK(!fam().oracle(spec_of(Q), fam().required_tools(spec_of(Q))).ok);
  CHECK(fam().oracle(spec_of(authored()), fam().required_tools(spec_of(authored()))).ok);
}

TEST_CASE("dial: lock file round trip") {
  const LockSpec spec = fam().generate(5, fam().difficulty_for_tier(3));
  const std::string text = lock_to_json(spec, fam());
  const LockParse back = lock_from_json(text, FamilyRegistry::builtin());
  REQUIRE(back.ok);
  CHECK(lock_to_json(back.spec, fam()) == text);
}
