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

TEST_CASE("json: surrogates and raw UTF-8 are validated (T25-23)") {
  CHECK(!json::parse(R"("\uDC00")").ok);
  CHECK(!json::parse(R"("\uD800")").ok);
  CHECK(!json::parse(R"("\uD800A")").ok);
  auto pair = json::parse(R"("😀")");
  REQUIRE(pair.ok);
  CHECK(pair.value.as_string() == "\xF0\x9F\x98\x80");
  CHECK(json::parse("\"\xC5\x82\xC3\xB3" "d\xC5\xBA\"").ok);       // valid 2-byte sequences
  CHECK(json::parse("\"\xE2\x80\x9E\"").ok);                     // 3-byte
  CHECK(json::parse("\"\xF0\x9F\x98\x80\"").ok);                 // 4-byte
  CHECK(!json::parse("\"\xC3\"").ok);                            // truncated
  CHECK(!json::parse("\"\xC0\xAF\"").ok);                        // overlong
  CHECK(!json::parse("\"\xE0\x80\xAF\"").ok);                    // overlong 3-byte
  CHECK(!json::parse("\"\xED\xA0\x80\"").ok);                    // encoded surrogate
  CHECK(!json::parse("\"\xF4\x90\x80\x80\"").ok);                // > U+10FFFF
  CHECK(!json::parse("\"\x80\"").ok);                            // stray continuation
  CHECK(!json::parse("\"\xFF\"").ok);
}

TEST_CASE("lockfile: seeds above 48 bits round-trip (T25-12)") {
  const FamilyRegistry& reg = FamilyRegistry::builtin();
  for (const FamilyModule* fam : reg.all()) {
    for (std::uint64_t seed : {std::uint64_t{UINT64_MAX}, std::uint64_t{0x8000000000000001ULL}, std::uint64_t{0xffff000000000000ULL}}) {
      const LockSpec spec = fam->generate(seed, fam->difficulty_for_tier(fam->max_tier()));
      CHECK(fam->oracle(spec, fam->required_tools(spec)).ok);
      const std::string text = lock_to_json(spec, *fam);
      const LockParse back = lock_from_json(text, reg);
      REQUIRE(back.ok);
      CHECK_EQ(back.spec.seed, seed);
      CHECK(lock_to_json(back.spec, *fam) == text);
      CHECK(fam->solver(spec, fam->required_tools(spec)).ok);
    }
  }
}

TEST_CASE("lockfile: presentation.practice.lesson_target is accepted and not written back (D-54)") {
  // Practice locks carry game metadata under presentation.practice (order, i18n keys,
  // lesson_target). The parser accepts it, the spec is the same as without it, and
  // lock_to_json() does not write it (check_locks skips presentation in its format check).
  const auto& fam = th::pin_module();
  const LockSpec spec = fam.generate(77, fam.difficulty_for_tier(3));
  const std::string plain = lock_to_json(spec, fam);
  auto doc = json::parse(plain);
  REQUIRE(doc.ok);
  json::Value practice = json::Value::object();
  practice.set("order", json::Value::integer(7));
  practice.set("lesson_target", json::Value::string("overset"));
  json::Value pres = *doc.value.find("presentation");
  pres.set("practice", std::move(practice));
  doc.value.set("presentation", std::move(pres));
  const std::string with_target = json::write(doc.value);
  REQUIRE(with_target.find("lesson_target") != std::string::npos);
  const LockParse p = lock_from_json(with_target, FamilyRegistry::builtin());
  REQUIRE(p.ok);
  CHECK(lock_to_json(p.spec, fam) == plain);
  CHECK(lock_to_json(p.spec, fam).find("lesson_target") == std::string::npos);
}
