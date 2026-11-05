#include "helpers.hpp"
#include "testing.hpp"

using namespace lockcore;
using th::Log;

namespace {

const FamilyModule& fam() { return th::module(wafer::CLOCK_FAMILY_ID); }

// Three wheels at 0.5, train order 0, 1, 2; run 2 s at T in [0.24, 0.62].
LockSpec authored() {
  auto P = std::make_shared<wafer::Params>();
  P->win_shear = q16_milli(140);
  P->overset_margin = q16_milli(120);
  P->tension_band = q16_milli(300);
  P->t_hold = wafer::T_HOLD;
  P->t_release = wafer::T_RELEASE;
  P->tau_safe = q16_milli(620);
  P->drop_grace_steps = 36;
  P->s_max = Q16_ONE;
  P->stress_gain = wafer::STRESS_GAIN;
  P->bound_speed = wafer::BOUND_SPEED;
  P->run_steps = 240;
  P->run_lo = q16_milli(240);
  for (int i = 0; i < 3; ++i) {
    wafer::Wafer w;
    w.target = q16_milli(500);
    w.order = q16_milli(100) * i;
    w.band_lo = q16_milli(240);
    P->wafers.push_back(w);
  }
  LockSpec spec;
  spec.family = std::string(wafer::CLOCK_FAMILY_ID);
  spec.rules_version = wafer::CLOCK_RULES_VERSION;
  spec.id = "test.time_lock";
  spec.source = "authored";
  spec.seed = 1;
  spec.difficulty = fam().difficulty_for_tier(1);
  spec.material = MaterialId::brass;
  spec.params = P;
  return spec;
}

constexpr q16 WIND = q16_milli(400);

void mesh_all(LockSession& s, Log& log) {
  for (int i = 0; i < 3; ++i) {
    REQUIRE(th::lift_until(s, i, WIND, q16_milli(4), q16_milli(560), EventKind::set, log));
    th::run(s, th::frame(WIND, element_center(i, 3), 0), 20, log);
  }
}

}  // namespace

TEST_CASE("time_lock: solver opens 200 seeds per tier") { th::check_family_solves(fam(), 200); }

TEST_CASE("time_lock: the train meshes from the barrel in order") {
  const LockSpec spec = fam().generate(3, fam().difficulty_for_tier(2));
  const auto& P = static_cast<const wafer::Params&>(*spec.params);
  for (std::size_t i = 1; i < P.wafers.size(); ++i) CHECK(P.wafers[i].order > P.wafers[i - 1].order);
  CHECK(P.run_steps == 360);
  CHECK(fam().required_tools(spec).has(TOOL_CLOCK_KIT));
}

TEST_CASE("time_lock: all wheels meshed + key in the band: ticks, progress, then it runs") {
  LockSession s(fam(), authored());
  Log log;
  mesh_all(s, log);
  CHECK(!s.is_open());
  th::run(s, th::frame(WIND, 0, 0), 120, log);
  CHECK(s.describe().hold_progress > q16_milli(300));
  CHECK(log.count(EventKind::contact, -1, wafer::SUB_TICK) >= 2);
  // Key out of the band (too slack, still above t_hold): beat off, the run restarts.
  th::run(s, th::frame(q16_milli(150), 0, 0), 4, log);
  CHECK_EQ(log.count(EventKind::near_shear, -1, wafer::SUB_BEAT_OFF), 1);
  CHECK_EQ(s.describe().hold_progress, 0);
  th::run(s, th::frame(WIND, 0, 0), 250, log);
  CHECK(s.is_open());
  CHECK(fam().event_name(wafer::SUB_TICK) == "time.tick");
}

TEST_CASE("time_lock: an overwound spring breaks") {
  LockSession s(fam(), authored());
  Log log;
  th::run(s, th::frame(Q16_ONE, 0, 0), SIM_HZ * 10, log);
  CHECK(log.count(EventKind::stress) >= 1);
  CHECK(s.failure() == FailureKind::break_);
}

TEST_CASE("time_lock: lock file round trip keeps the run fields") {
  const LockSpec spec = fam().generate(5, fam().difficulty_for_tier(2));
  const std::string text = lock_to_json(spec, fam());
  CHECK(text.find("run_steps") != std::string::npos);
  const LockParse back = lock_from_json(text, FamilyRegistry::builtin());
  REQUIRE(back.ok);
  CHECK(lock_to_json(back.spec, fam()) == text);
  CHECK(lock_to_json(th::wafer_module().generate(5, th::wafer_module().difficulty_for_tier(2)), th::wafer_module())
            .find("run_steps") == std::string::npos);
}
