#include "helpers.hpp"
#include "testing.hpp"

using namespace lockcore;
using th::Log;

namespace {

const FamilyModule& fam() { return th::module(pin::MAGNETIC_FAMILY_ID); }

LockSpec spec_of(std::shared_ptr<pin::Params> P) {
  LockSpec spec = th::pin_spec(std::move(P));
  spec.family = std::string(pin::MAGNETIC_FAMILY_ID);
  spec.rules_version = pin::MAGNETIC_RULES_VERSION;
  spec.id = "test.magnetic";
  spec.difficulty = fam().difficulty_for_tier(1);
  spec.material = MaterialId::steel;
  return spec;
}

}  // namespace

TEST_CASE("magnetic: solver opens 200 seeds per tier") { th::check_family_solves(fam(), 200); }

TEST_CASE("magnetic: the pin trails the probe at the field speed") {
  auto P = th::pin_params();
  P->field_speed = q16_per_step(q16_milli(1200));
  LockSession s(fam(), spec_of(P));
  Log log;
  // A free pin under the probe: thumb jumps to 0.6, the pin needs 0.5 s to follow.
  th::run(s, th::frame(0, element_center(1, 3), q16_milli(600)), 12, log);
  const q16 p = s.describe().elements[1].position;
  CHECK(p > q16_milli(100));
  CHECK(p < q16_milli(150));
  th::run(s, th::frame(0, element_center(1, 3), q16_milli(600)), SIM_HZ, log);
  CHECK_EQ(s.describe().elements[1].position, quantize_256(q16_milli(600)));
  // Field 0: rigid like a hook (pin_tumbler behaviour).
  P->field_speed = 0;
  LockSession r(fam(), spec_of(P));
  th::run(r, th::frame(0, element_center(1, 3), q16_milli(600)), 1, log);
  CHECK_EQ(r.describe().elements[1].position, quantize_256(q16_milli(600)));
}

TEST_CASE("magnetic: probe tool, tiers 1-2, no security pins, round trip keeps field_speed") {
  CHECK_EQ(fam().max_tier(), 2);
  const LockSpec spec = fam().generate(5, fam().difficulty_for_tier(2));
  CHECK(fam().required_tools(spec).has(TOOL_MAGNET_PROBE));
  for (const auto& st : static_cast<const pin::Params&>(*spec.params).stacks) CHECK(st.variant == pin::Variant::standard);
  const std::string text = lock_to_json(spec, fam());
  CHECK(text.find("field_speed_q16") != std::string::npos);
  const LockParse back = lock_from_json(text, FamilyRegistry::builtin());
  REQUIRE(back.ok);
  CHECK(lock_to_json(back.spec, fam()) == text);
  CHECK(lock_to_json(th::pin_module().generate(5, th::pin_module().difficulty_for_tier(4)), th::pin_module())
            .find("field_speed") == std::string::npos);
}
