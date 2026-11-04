#include "helpers.hpp"
#include "testing.hpp"

using namespace lockcore;

TEST_CASE("json: parse and write round trip") {
  const char* text = R"({"a": 1, "b": [true, false, null], "c": {"d": "x\"yé"}, "e": -9223372036854775808, "f": 18446744073709551615})";
  auto r = json::parse(text);
  REQUIRE(r.ok);
  CHECK_EQ(r.value.find("a")->as_int(), 1);
  CHECK(r.value.find("c")->find("d")->as_string() == "x\"y\xc3\xa9");
  CHECK_EQ(r.value.find("e")->as_int(), INT64_MIN);
  CHECK(r.value.find("f")->uint_only());
  const std::string w1 = json::write(r.value);
  auto r2 = json::parse(w1);
  REQUIRE(r2.ok);
  CHECK(json::write(r2.value) == w1);
}

TEST_CASE("json: rejects fractions, trailing garbage, duplicates") {
  CHECK(!json::parse("0.5").ok);
  CHECK(!json::parse("1e3").ok);
  CHECK(!json::parse("{} x").ok);
  CHECK(!json::parse(R"({"a":1,"a":2})").ok);
  CHECK(!json::parse("[1,]").ok);
  CHECK(!json::parse("01").ok);
  CHECK(json::parse("  [ ]  ").ok);
}

TEST_CASE("lockfile: generated specs round-trip bit-exact") {
  for (const FamilyModule* fam : FamilyRegistry::builtin().all()) {
    for (int tier = fam->min_tier(); tier <= fam->max_tier(); ++tier) {
      for (std::uint64_t seed = 1; seed <= 20; ++seed) {
        const LockSpec spec = fam->generate(seed * 7919, fam->difficulty_for_tier(tier));
        const std::string a = lock_to_json(spec, *fam);
        LockParse p = lock_from_json(a, FamilyRegistry::builtin());
        if (!p.ok) {
          for (const auto& e : p.errors) std::cerr << e.path << ": " << e.message << "\n";
        }
        REQUIRE(p.ok);
        CHECK(lock_to_json(p.spec, *fam) == a);
        CHECK(p.spec.difficulty == spec.difficulty);
        CHECK_EQ(p.spec.seed, spec.seed);
      }
    }
  }
}

TEST_CASE("lockfile: errors are reported with paths") {
  const auto& fam = th::pin_module();
  const LockSpec spec = fam.generate(5, fam.difficulty_for_tier(4));
  std::string text = lock_to_json(spec, fam);
  // Break the schema and a parameter.
  auto pos = text.find("lockwright.lock/1");
  text.replace(pos, 17, "lockwright.lock/9");
  LockParse p = lock_from_json(text, FamilyRegistry::builtin());
  CHECK(!p.ok);
  bool schema_err = false;
  for (const auto& e : p.errors) schema_err = schema_err || e.path == ".schema";
  CHECK(schema_err);

  auto P = th::pin_params();
  P->stacks[1].target = q16_milli(50);  // window below the travel
  const auto errs = fam.validate(th::pin_spec(P));
  REQUIRE(!errs.empty());
  CHECK(errs.front().path == "spec.stacks[1].target_q16");
}
