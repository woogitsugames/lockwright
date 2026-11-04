#include "helpers.hpp"
#include "testing.hpp"

using namespace lockcore;
using th::Log;

namespace {
const q16 kWork = q16_milli(340);  // inside the authored band [0.20, 0.48]
const q16 kRate = q16_milli(4);    // careful lift per step (0.48 / s)
}  // namespace

TEST_CASE("pin: too much tension for 0.5 s -> stress, then break") {
  LockSession s(th::pin_module(), th::pin_spec(th::pin_params()));
  Log log;
  th::run(s, th::frame(Q16_ONE, element_center(0, 3), Q16_ONE), SIM_HZ / 2, log);
  const auto t_stress = log.first(EventKind::stress);
  const auto t_break = log.first(EventKind::break_);
  REQUIRE(t_stress >= 0);
  REQUIRE(t_break >= 0);
  CHECK(t_stress < t_break);
  CHECK(t_break < SIM_HZ / 2);
  CHECK(s.failure() == FailureKind::break_);
  CHECK(s.finished());
  // The pin never moved: above t_stick it "won't go".
  CHECK_EQ(s.describe().elements[0].position, 0);
  // Session is frozen after failure.
  CHECK(s.step(th::frame(0, 0, 0)).events.empty());
}

TEST_CASE("pin: tension inside the band does not stress the tool") {
  LockSession s(th::pin_module(), th::pin_spec(th::pin_params()));
  Log log;
  th::run(s, th::frame(q16_milli(450), element_center(0, 3), Q16_ONE), SIM_HZ * 2, log);
  CHECK_EQ(log.count(EventKind::stress), 0);
  CHECK(s.failure() == FailureKind::none);
}

TEST_CASE("pin: binding order follows the offsets") {
  auto P = th::pin_params();
  P->stacks[0].order = q16_milli(200);
  P->stacks[1].order = q16_milli(0);
  P->stacks[2].order = q16_milli(100);
  LockSession s(th::pin_module(), th::pin_spec(P));
  Log log;
  th::run(s, th::frame(kWork, 0, 0), 2, log);
  CHECK_EQ(log.count(EventKind::bind, 1), 1);
  CHECK_EQ(log.count(EventKind::bind, 0), 0);
  CHECK(s.describe().elements[1].state == ElementState::bound);
  // A non-binding stack only follows the pick; it cannot set.
  CHECK(!th::lift_until(s, 0, kWork, kRate, q16_milli(700), EventKind::set, log));
  CHECK(th::lift_until(s, 1, kWork, kRate, q16_milli(700), EventKind::set, log));
  th::run(s, th::frame(kWork, 0, 0), 1, log);  // the next stack binds on the following step
  CHECK(s.describe().elements[2].state == ElementState::bound);
  CHECK(s.describe().elements[0].state == ElementState::free);
}

TEST_CASE("pin: near_shear precedes set") {
  LockSession s(th::pin_module(), th::pin_spec(th::pin_params()));
  Log log;
  REQUIRE(th::lift_until(s, 0, kWork, kRate, q16_milli(700), EventKind::set, log));
  const auto t_near = log.first(EventKind::near_shear, 0);
  CHECK(t_near >= 0);
  CHECK(t_near < log.first(EventKind::set, 0));
}

TEST_CASE("pin: too little tension -> drop of set stacks") {
  LockSession s(th::pin_module(), th::pin_spec(th::pin_params()));
  Log log;
  REQUIRE(th::lift_until(s, 0, kWork, kRate, q16_milli(700), EventKind::set, log));
  REQUIRE(th::lift_until(s, 1, kWork, kRate, q16_milli(700), EventKind::set, log));
  th::run(s, th::frame(kWork, 0, 0), 5, log);
  // A dip shorter than drop_grace is forgiven.
  th::run(s, th::frame(q16_milli(50), 0, 0), 30, log);
  th::run(s, th::frame(kWork, 0, 0), 5, log);
  CHECK_EQ(log.count(EventKind::drop), 0);
  CHECK(s.describe().elements[0].state == ElementState::set);
  // A longer one drops everything (drop_all).
  th::run(s, th::frame(q16_milli(50), 0, 0), 40, log);
  CHECK_EQ(log.count(EventKind::drop), 1);
  CHECK(s.describe().elements[0].state == ElementState::free);
  CHECK(s.describe().elements[1].state == ElementState::free);
}

TEST_CASE("pin: tier 2 drop releases only the last set stack") {
  auto P = th::pin_params();
  P->drop_all = false;
  LockSession s(th::pin_module(), th::pin_spec(P));
  Log log;
  REQUIRE(th::lift_until(s, 0, kWork, kRate, q16_milli(700), EventKind::set, log));
  REQUIRE(th::lift_until(s, 1, kWork, kRate, q16_milli(700), EventKind::set, log));
  th::run(s, th::frame(0, 0, 0), 40, log);
  CHECK_EQ(log.count(EventKind::drop), 1);
  CHECK(s.describe().elements[0].state == ElementState::set);
  CHECK(s.describe().elements[1].state == ElementState::free);
}

TEST_CASE("pin: spool -> false_set, then counter_rotate; easing tension -> set") {
  auto P = th::pin_params();
  P->stacks[0].variant = pin::Variant::spool;
  P->stacks[0].false_gate = q16_milli(330);
  LockSession s(th::pin_module(), th::pin_spec(P));
  Log log;
  REQUIRE(th::lift_until(s, 0, kWork, kRate, q16_milli(700), EventKind::false_set, log));
  CHECK_EQ(log.count(EventKind::set, 0), 0);
  CHECK(s.describe().elements[0].state == ElementState::false_set);
  // The other stacks are loose during a false set.
  CHECK(s.describe().elements[1].state == ElementState::free);
  CHECK(s.describe().core_rotation > 0);

  // Keep pushing with working tension: the core counter-rotates, the spool does not pass.
  const q16 gate_lift = s.describe().elements[0].position;
  CHECK(!th::lift_until(s, 0, kWork, kRate, gate_lift + q16_milli(80), EventKind::set, log, gate_lift));
  CHECK(log.count(EventKind::counter_rotate, 0) >= 2);
  CHECK(s.describe().elements[0].state == ElementState::false_set);
  CHECK(s.describe().elements[0].position == gate_lift);

  // Ease tension into the counter-rotation band and push through.
  th::run(s, th::frame(q16_milli(165), element_center(0, 3), gate_lift), 3, log);
  CHECK(th::lift_until(s, 0, q16_milli(165), q16_milli(2), q16_milli(700), EventKind::set, log, gate_lift));
  CHECK(s.describe().elements[0].state == ElementState::set);
  CHECK(s.failure() == FailureKind::none);
}

TEST_CASE("pin: spool with too little tension drops") {
  auto P = th::pin_params();
  P->stacks[0].variant = pin::Variant::spool;
  P->stacks[0].false_gate = q16_milli(330);
  LockSession s(th::pin_module(), th::pin_spec(P));
  Log log;
  REQUIRE(th::lift_until(s, 0, kWork, kRate, q16_milli(700), EventKind::false_set, log));
  th::run(s, th::frame(q16_milli(60), element_center(0, 3), q16_milli(400)), 40, log);
  CHECK_EQ(log.count(EventKind::drop), 1);
  CHECK(s.describe().elements[0].state != ElementState::false_set);
}

TEST_CASE("pin: overset blocks until tension is reduced below t_release") {
  LockSession s(th::pin_module(), th::pin_spec(th::pin_params()));
  Log log;
  REQUIRE(th::lift_until(s, 0, kWork, kRate, q16_milli(700), EventKind::set, log));
  // Keep pushing the set pin past window top + margin (0.61 + 0.10).
  REQUIRE(th::lift_until(s, 0, kWork, kRate, q16_milli(900), EventKind::overset, log, q16_milli(500)));
  CHECK(s.describe().elements[0].state == ElementState::overset);
  th::run(s, th::frame(kWork, element_center(0, 3), 0), 3, log);

  // While overset the core is jammed: nothing binds, nothing sets.
  const auto binds_before = log.count(EventKind::bind, 1);
  CHECK(!th::lift_until(s, 1, kWork, kRate, q16_milli(700), EventKind::set, log));
  CHECK_EQ(log.count(EventKind::bind, 1), binds_before);
  CHECK(s.describe().elements[1].state == ElementState::free);

  // Easing to just below t_hold is not enough.
  th::run(s, th::frame(q16_milli(80), 0, 0), 3, log);
  CHECK(s.describe().elements[0].state == ElementState::overset);
  // Below t_release the overset pin falls back.
  th::run(s, th::frame(q16_milli(30), 0, 0), 2, log);
  CHECK(s.describe().elements[0].state == ElementState::free);
  CHECK_EQ(log.count(EventKind::drop), 0);  // brief dip, within drop_grace
  th::run(s, th::frame(kWork, 0, 0), 2, log);
  CHECK(s.describe().elements[0].state == ElementState::bound);
  CHECK(th::lift_until(s, 0, kWork, kRate, q16_milli(700), EventKind::set, log));
}

TEST_CASE("pin: serrated stack clicks before the window") {
  auto P = th::pin_params();
  P->stacks[0].variant = pin::Variant::serrated;
  P->stacks[0].serrations = {q16_milli(300), q16_milli(380), q16_milli(440)};
  LockSession s(th::pin_module(), th::pin_spec(P));
  Log log;
  REQUIRE(th::lift_until(s, 0, kWork, kRate, q16_milli(700), EventKind::set, log));
  CHECK_EQ(log.count(EventKind::false_set, 0, pin::SUB_SERRATION), 3);
  CHECK_EQ(log.count(EventKind::false_set, 0), 0);  // no real false set
  CHECK(th::pin_module().event_name(pin::SUB_SERRATION) == "pin.serration");
}

TEST_CASE("pin: authored lock opens when every stack is set") {
  LockSession s(th::pin_module(), th::pin_spec(th::pin_params()));
  Log log;
  for (int i = 0; i < 3; ++i) REQUIRE(th::lift_until(s, i, kWork, kRate, q16_milli(700), EventKind::set, log));
  CHECK(s.is_open());
  CHECK_EQ(log.count(EventKind::open), 1);
  CHECK_EQ(s.describe().core_rotation, Q16_ONE);
}

TEST_CASE("pin: solver opens 3-pin t2 locks") {
  const auto& fam = th::pin_module();
  const DifficultyVector d = fam.difficulty_for_tier(2);
  for (std::uint64_t seed = 1; seed <= 200; ++seed) {
    const LockSpec spec = fam.generate(seed, d);
    const auto& P = static_cast<const pin::Params&>(*spec.params);
    CHECK_EQ(P.stacks.size(), static_cast<std::size_t>(3));
    CHECK(fam.validate(spec).empty());
    const SolveReport r = fam.solver(spec, fam.required_tools(spec));
    if (!r.ok) std::cerr << "seed " << seed << ": " << r.reason << "\n";
    CHECK(r.ok);
    CHECK(r.peak_stress < BOT_MAX_STRESS);
  }
}

TEST_CASE("pin: generator is deterministic and tiers add security") {
  const auto& fam = th::pin_module();
  const auto a = lock_to_json(fam.generate(99, fam.difficulty_for_tier(6)), fam);
  const auto b = lock_to_json(fam.generate(99, fam.difficulty_for_tier(6)), fam);
  const auto c = lock_to_json(fam.generate(100, fam.difficulty_for_tier(6)), fam);
  CHECK(a == b);
  CHECK(a != c);
  int spools = 0;
  for (std::uint64_t seed = 1; seed <= 50; ++seed) {
    const auto spec = fam.generate(seed, fam.difficulty_for_tier(7));
    for (const auto& st : static_cast<const pin::Params&>(*spec.params).stacks) spools += st.has_spool();
  }
  CHECK(spools > 0);
}

TEST_CASE("pin: oracle rejects a band narrower than delta_human") {
  auto P = th::pin_params();
  P->tension_band = q16_milli(60);
  const auto r = th::pin_module().oracle(th::pin_spec(P), ToolSet{});
  CHECK(!r.ok);
  CHECK(r.reason.find("delta_human") != std::string::npos);
}

TEST_CASE("pin: same inputs, same event hash") {
  const auto& fam = th::pin_module();
  const LockSpec spec = fam.generate(1234, fam.difficulty_for_tier(7));
  SolveOptions opt;
  opt.record_inputs = true;
  const SolveReport r = fam.solver(spec, ToolSet{}, opt);
  REQUIRE(r.ok);
  LockSession s(fam, spec);
  for (const auto& f : r.inputs) s.step(f);
  CHECK_EQ(s.event_hash(), r.event_hash);
  CHECK(s.is_open());
}
