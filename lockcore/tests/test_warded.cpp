#include "helpers.hpp"
#include "testing.hpp"

using namespace lockcore;
using th::Log;

namespace {

const FamilyModule& fam() { return th::module(warded::FAMILY_ID); }

// One ward at [0.30, 0.40] with gap [0.40, 0.60]; bolt band [0.20, 0.38], spring 0.40.
// Square fits and lifts; hook fits but is too weak; fork is too thick.
std::shared_ptr<warded::Params> authored(int bend_limit = 3) {
  auto P = std::make_shared<warded::Params>();
  P->bit_options = 3;
  P->a_bolt = warded::A_BOLT;
  P->a_set = warded::A_SET;
  P->bolt_lo = q16_milli(200);
  P->bolt_hi = q16_milli(380);
  P->bolt_spring = q16_milli(400);
  P->t_turn = warded::T_TURN;
  P->rot_speed = warded::ROT_SPEED;
  P->insert_depth = warded::INSERT_DEPTH;
  P->s_max = Q16_ONE;
  P->stress_gain = warded::STRESS_GAIN;
  P->bend_limit = bend_limit;
  warded::Ward w;
  w.a_lo = q16_milli(300);
  w.a_hi = q16_milli(400);
  w.gap_lo = q16_milli(400);
  w.gap_hi = q16_milli(600);
  P->wards.push_back(w);
  return P;
}

LockSpec spec_of(std::shared_ptr<warded::Params> P) {
  LockSpec spec;
  spec.family = std::string(warded::FAMILY_ID);
  spec.rules_version = warded::RULES_VERSION;
  spec.id = "test.warded";
  spec.source = "authored";
  spec.seed = 1;
  spec.difficulty = fam().difficulty_for_tier(2);
  spec.material = MaterialId::iron;
  spec.params = std::move(P);
  return spec;
}

InputFrame probe(q16 tension, q16 depth, q16 height, q16 rotate, std::uint8_t bit) {
  InputFrame f;
  f.tension = tension;
  f.pick_depth = depth;
  f.pick_lift = height;
  f.rotate = rotate;
  f.tool = bit;
  return f;
}

void choose_bit(LockSession& s, std::uint8_t bit, Log& log) { th::run(s, probe(0, 0, q16_milli(500), 0, bit), 2, log); }

}  // namespace

TEST_CASE("warded: solver opens 200 seeds per tier") { th::check_family_solves(fam(), 200); }

TEST_CASE("warded: authored spec validates; oracle picks the square bit") {
  const LockSpec spec = spec_of(authored());
  CHECK(fam().validate(spec).empty());
  const OracleReport o = fam().oracle(spec, ToolSet{TOOL_WARD_PROBE});
  REQUIRE(o.ok);
  CHECK(!fam().oracle(spec, ToolSet{}).ok);
  CHECK(warded::bit_name(warded::BIT_FORK) == "fork");
}

TEST_CASE("warded: a thick bit is stopped by the ward; the right one passes with gate_align") {
  {
    LockSession s(fam(), spec_of(authored()));
    Log log;
    choose_bit(s, warded::BIT_FORK, log);
    th::run(s, probe(q16_milli(300), Q16_ONE, q16_milli(500), Q16_ONE, warded::BIT_FORK), 240, log);
    CHECK(s.describe().core_rotation < q16_milli(300));
    CHECK(log.count(EventKind::contact, 0, warded::SUB_SCRAPE) >= 3);
    CHECK_EQ(log.count(EventKind::gate_align), 0);
    CHECK(s.describe().pick_drag > 0);
  }
  {
    LockSession s(fam(), spec_of(authored()));
    Log log;
    choose_bit(s, warded::BIT_SQUARE, log);
    th::run(s, probe(q16_milli(300), Q16_ONE, q16_milli(500), Q16_ONE, warded::BIT_SQUARE), 90, log);
    CHECK_EQ(log.count(EventKind::gate_align, 0), 1);
    CHECK(s.describe().core_rotation > q16_milli(400));
  }
}

TEST_CASE("warded: inside a ward the tip stays in the gap") {
  LockSession s(fam(), spec_of(authored()));
  Log log;
  choose_bit(s, warded::BIT_SQUARE, log);
  // Turn into the ward span (theta ~0.35) and stop there.
  for (int i = 0; i < 300 && s.describe().core_rotation < q16_milli(340); ++i) {
    const auto& out = s.step(probe(q16_milli(300), Q16_ONE, q16_milli(500), q16_milli(300), warded::BIT_SQUARE));
    log.events.insert(log.events.end(), out.events.begin(), out.events.end());
  }
  th::run(s, probe(q16_milli(300), Q16_ONE, q16_milli(100), 0, warded::BIT_SQUARE), 20, log);
  CHECK(s.describe().pick_lift >= q16_milli(400) + warded::BIT_THICKNESS[0] / 2);
  CHECK(log.count(EventKind::contact, 0, warded::SUB_SCRAPE) >= 1);
  // Bits cannot be swapped while turned.
  th::run(s, probe(q16_milli(300), 0, q16_milli(500), 0, warded::BIT_HOOK), 5, log);
  th::run(s, probe(q16_milli(300), Q16_ONE, q16_milli(500), Q16_ONE, warded::BIT_HOOK), 60, log);
  CHECK(s.describe().core_rotation > q16_milli(400));  // still the square bit: it passed
}

TEST_CASE("warded: the bolt needs the right height and force") {
  // Off height: the tip passes beside the bolt to the end stop.
  {
    LockSession s(fam(), spec_of(authored()));
    Log log;
    choose_bit(s, warded::BIT_SQUARE, log);
    th::run(s, probe(q16_milli(450), Q16_ONE, q16_milli(500), Q16_ONE, warded::BIT_SQUARE), 240, log);
    CHECK_EQ(s.describe().core_rotation, Q16_ONE);
    CHECK(!s.is_open());
    CHECK_EQ(log.count(EventKind::bind), 0);
    CHECK(log.count(EventKind::contact, -1) >= 1);
  }
  // On height but too little force: caught, then held at the bolt.
  {
    LockSession s(fam(), spec_of(authored()));
    Log log;
    choose_bit(s, warded::BIT_SQUARE, log);
    th::run(s, probe(q16_milli(300), Q16_ONE, q16_milli(500), Q16_ONE, warded::BIT_SQUARE), 70, log);  // past the ward
    th::run(s, probe(q16_milli(300), Q16_ONE, q16_milli(290), Q16_ONE, warded::BIT_SQUARE), 120, log);
    CHECK_EQ(log.count(EventKind::bind, 1), 1);
    CHECK(!s.is_open());
    CHECK(s.describe().pick_drag > 0);
    // More force: the bolt lifts, the lock opens.
    th::run(s, probe(q16_milli(470), Q16_ONE, q16_milli(290), Q16_ONE, warded::BIT_SQUARE), 60, log);
    CHECK_EQ(log.count(EventKind::set, 1), 1);
    CHECK(s.is_open());
    CHECK_EQ(log.count(EventKind::stress), 0);
  }
}

TEST_CASE("warded: a weak bit bends on the bolt; t2 breaks after three stresses, t1 never") {
  for (const int limit : {3, 0}) {
    LockSession s(fam(), spec_of(authored(limit)));
    Log log;
    choose_bit(s, warded::BIT_HOOK, log);
    th::run(s, probe(q16_milli(300), Q16_ONE, q16_milli(500), Q16_ONE, warded::BIT_HOOK), 70, log);
    th::run(s, probe(q16_milli(300), Q16_ONE, q16_milli(290), Q16_ONE, warded::BIT_HOOK), 60, log);
    // The hook needs T >= 0.40 for the bolt but is safe only to 0.32: press, ease, repeat.
    for (int round = 0; round < 4 && !s.finished(); ++round) {
      th::run(s, probe(q16_milli(500), Q16_ONE, q16_milli(290), Q16_ONE, warded::BIT_HOOK), 55, log);
      CHECK(!s.is_open());
      th::run(s, probe(q16_milli(300), Q16_ONE, q16_milli(290), -Q16_ONE, warded::BIT_HOOK), 30, log);
      th::run(s, probe(q16_milli(300), Q16_ONE, q16_milli(290), 0, warded::BIT_HOOK), 240, log);
      th::run(s, probe(q16_milli(300), Q16_ONE, q16_milli(290), Q16_ONE, warded::BIT_HOOK), 30, log);
    }
    CHECK(log.count(EventKind::stress) >= 3);
    if (limit > 0) {
      CHECK(s.failure() == FailureKind::break_);
      CHECK_EQ(log.count(EventKind::break_), 1);
    } else {
      CHECK(s.failure() == FailureKind::none);
      CHECK_EQ(log.count(EventKind::break_), 0);
    }
  }
}

TEST_CASE("warded: lock file round trip") {
  const LockSpec spec = fam().generate(8, fam().difficulty_for_tier(2));
  const std::string text = lock_to_json(spec, fam());
  const LockParse back = lock_from_json(text, FamilyRegistry::builtin());
  REQUIRE(back.ok);
  CHECK(lock_to_json(back.spec, fam()) == text);
}
