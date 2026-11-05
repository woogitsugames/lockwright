#include "helpers.hpp"
#include "testing.hpp"

using namespace lockcore;
using th::Log;

namespace {

const FamilyModule& fam() { return th::module(pin::DIMPLE_FAMILY_ID); }

LockSpec spec_of(std::shared_ptr<pin::Params> P) {
  LockSpec spec = th::pin_spec(std::move(P));
  spec.family = std::string(pin::DIMPLE_FAMILY_ID);
  spec.rules_version = pin::DIMPLE_RULES_VERSION;
  spec.id = "test.dimple";
  spec.difficulty = fam().difficulty_for_tier(2);
  return spec;
}

}  // namespace

TEST_CASE("dimple: solver opens 200 seeds per tier") { th::check_family_solves(fam(), 200); }

TEST_CASE("dimple: flag pick tool, tiers 1-3, telescoping pins from t2") {
  CHECK(fam().required_tools(fam().generate(1, fam().difficulty_for_tier(1))).has(TOOL_DIMPLE_FLAG));
  CHECK(!fam().required_tools(fam().generate(1, fam().difficulty_for_tier(1))).has(TOOL_HOOK));
  CHECK_EQ(fam().min_tier(), 1);
  CHECK_EQ(fam().max_tier(), 3);
  CHECK_EQ(fam().difficulty_for_tier(1).sec_max, 0);
  for (std::uint64_t seed = 1; seed <= 20; ++seed) {
    const LockSpec spec = fam().generate(seed, fam().difficulty_for_tier(2));
    int tele = 0;
    for (const auto& s : static_cast<const pin::Params&>(*spec.params).stacks) {
      CHECK(s.variant == pin::Variant::standard || s.variant == pin::Variant::spool);  // no serrations
      tele += s.has_spool() ? 1 : 0;
    }
    CHECK_EQ(tele, 1);
  }
}

TEST_CASE("dimple: telescoping pin: sleeve catches (false_set), inner pin needs the lighter band") {
  auto P = th::pin_params();
  P->stacks[0].variant = pin::Variant::spool;
  P->stacks[0].false_gate = P->win_lo(P->stacks[0]) - q16_milli(120);
  LockSession s(fam(), spec_of(P));
  Log log;
  CHECK(th::lift_until(s, 0, q16_milli(300), q16_milli(4), q16_milli(700), EventKind::false_set, log));
  CHECK(s.describe().elements[0].state == ElementState::false_set);
  // Inside the counter-rotation band the inner pin goes up to the shear line.
  CHECK(th::lift_until(s, 0, (pin::CR_LO + pin::CR_HI) / 2, q16_milli(2), q16_milli(800), EventKind::set, log,
                       s.describe().elements[0].position));
  CHECK(log.count(EventKind::counter_rotate, 0) >= 1);
}

TEST_CASE("dimple: odd pins are drawn in the side row") {
  LockSession s(fam(), spec_of(th::pin_params()));
  const ViewModel v = s.describe();
  CHECK((v.elements[0].variant & pin::DIMPLE_SIDE_ROW) == 0);
  CHECK((v.elements[1].variant & pin::DIMPLE_SIDE_ROW) != 0);
}

TEST_CASE("dimple: lock file round trip") {
  const LockSpec spec = fam().generate(5, fam().difficulty_for_tier(3));
  const std::string text = lock_to_json(spec, fam());
  const LockParse back = lock_from_json(text, FamilyRegistry::builtin());
  REQUIRE(back.ok);
  CHECK(lock_to_json(back.spec, fam()) == text);
}
