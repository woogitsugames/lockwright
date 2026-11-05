#include "helpers.hpp"
#include "testing.hpp"

using namespace lockcore;

TEST_CASE("fixed: q16 helpers") {
  CHECK_EQ(q16_milli(1000), Q16_ONE);
  CHECK_EQ(q16_milli(500), Q16_ONE / 2);
  CHECK_EQ(q_mul(Q16_ONE / 2, Q16_ONE / 2), Q16_ONE / 4);
  CHECK_EQ(q_mul(-Q16_ONE / 2, Q16_ONE / 2), -Q16_ONE / 4);
  CHECK_EQ(q_div(Q16_ONE / 4, Q16_ONE / 2), Q16_ONE / 2);
  CHECK_EQ(ms_to_steps(300), 36);
  CHECK_EQ(ms_to_steps(180), 22);
  CHECK_EQ(quantize_256(300), 256);
  CHECK_EQ(quantize_256(-300), -256);
  CHECK_EQ(quantize_256(100), 0);
}

TEST_CASE("prng: PCG32 reference vector") {
  // pcg32-demo: seed 42, stream 54.
  Pcg32 r(42u, 54u);
  const std::uint32_t expected[] = {0xa15c02b7u, 0x7b47f409u, 0xba1d3330u, 0x83d2f293u, 0xbfa4784bu, 0xcbed606eu};
  for (std::uint32_t e : expected) CHECK_EQ(r.next(), e);
}

TEST_CASE("prng: bounded and streams") {
  Pcg32 a(7, 1), b(7, 2);
  bool differ = false;
  for (int i = 0; i < 16; ++i) differ = differ || a.next() != b.next();
  CHECK(differ);
  Pcg32 r(1, 1);
  for (int i = 0; i < 10000; ++i) {
    const auto v = r.range(-5, 5);
    CHECK(v >= -5 && v <= 5);
  }
}

TEST_CASE("hash: FNV-1a 64 reference") {
  CHECK_EQ(fnv1a64(""), 0xcbf29ce484222325ULL);
  CHECK_EQ(fnv1a64("a"), 0xaf63dc4c8601ec8cULL);
  CHECK(derive_seed(1, "pin_tumbler", 1, "gen") != derive_seed(1, "wafer", 1, "gen"));
}

TEST_CASE("input: quantisation to 1/256 and clamping") {
  InputFrame f;
  f.tension = Q16_ONE + 5000;
  f.pick_depth = -10;
  f.pick_lift = q16_milli(333);
  const InputFrame q = quantize(f);
  CHECK_EQ(q.tension, Q16_ONE);
  CHECK_EQ(q.pick_depth, 0);
  CHECK_EQ(q.pick_lift % INPUT_QUANTUM, 0);
  CHECK(q_abs(q.pick_lift - q16_milli(333)) <= INPUT_QUANTUM / 2);
}

TEST_CASE("components: pick magnet") {
  CHECK_EQ(locate_element(element_center(0, 5), 5), 0);
  CHECK_EQ(locate_element(element_center(4, 5), 5), 4);
  // Exactly between two elements: no contact.
  CHECK_EQ(locate_element(Q16_ONE / 5, 5), -1);
}

TEST_CASE("components: tension hold fires once after grace") {
  TensionHold h;
  int fired = 0;
  for (int i = 0; i < 100; ++i) fired += h.update(0, q16_milli(100), 36) ? 1 : 0;
  CHECK_EQ(fired, 1);
  CHECK(!h.update(q16_milli(200), q16_milli(100), 36));
  CHECK_EQ(h.below_steps(), 0);
}

TEST_CASE("components: tool wear lowers capacity, wear events every 10 points") {
  ToolStress a, b;
  a.init(Q16_ONE, 0, q16_milli(100));
  b.init(Q16_ONE, 100, q16_milli(100));
  CHECK(b.capacity() < a.capacity());
  std::vector<LockEvent> ev;
  EventSink sink(ev);
  for (int t = 0; t < 1000 && !a.broken(); ++t) {
    a.load(Q16_ONE / 2, Q16_ONE / 2);
    a.end_step(t, sink, 0, MaterialId::steel);
  }
  CHECK(a.broken());
  int wear = 0, stress = 0, brk = 0;
  for (const auto& e : ev) {
    wear += e.kind == EventKind::wear;
    stress += e.kind == EventKind::stress;
    brk += e.kind == EventKind::break_;
  }
  CHECK(wear >= 1);
  CHECK(stress >= 1);
  CHECK_EQ(brk, 1);
}

TEST_CASE("events: names and priorities") {
  CHECK(event_kind_name(EventKind::break_) == "break");
  EventKind k{};
  CHECK(event_kind_from_name("counter_rotate", k) && k == EventKind::counter_rotate);
  CHECK(event_priority(EventKind::break_) > event_priority(EventKind::stress));
  CHECK(event_priority(EventKind::stress) > event_priority(EventKind::open));
  CHECK(event_priority(EventKind::set) > event_priority(EventKind::false_set));
  CHECK(event_priority(EventKind::contact) > event_priority(EventKind::wear));
}

TEST_CASE("registry: builtin families") {
  const auto& reg = FamilyRegistry::builtin();
  CHECK(reg.find("pin_tumbler") != nullptr);
  CHECK(reg.find("wafer") != nullptr);
  for (const char* id : {"wooden_pin", "lever", "lever_detector", "ring_combo", "warded", "dial_safe", "combo"}) CHECK(reg.find(id) != nullptr);
  CHECK(reg.find("no_such_family") == nullptr);
  CHECK_EQ(reg.all().size(), static_cast<std::size_t>(9));
}

TEST_CASE("fixed: edge domains are total (T25-17..21)") {
  // In-range values are unchanged.
  CHECK_EQ(q16_ratio(1, 2), Q16_ONE / 2);
  CHECK_EQ(q16_ratio(-3, 4), -(3 * Q16_ONE) / 4);
  CHECK_EQ(q16_ratio(30, 100), 19660);
  // Out of domain: no UB, saturation / 0.
  CHECK_EQ(q16_ratio(1, 0), 0);
  CHECK_EQ(q16_ratio(INT64_MAX, 1), INT32_MAX);
  CHECK_EQ(q16_ratio(INT64_MIN + 1, 1), INT32_MIN);
  CHECK_EQ(q16_ratio(INT64_MAX, INT64_MAX), Q16_ONE);
  CHECK_EQ(q16_ratio(1000000, 1), INT32_MAX);
  CHECK_EQ(q_div(Q16_ONE, 1), INT32_MAX);
  CHECK_EQ(q_div(-Q16_ONE, 1), INT32_MIN);
  CHECK_EQ(q_abs(INT32_MIN), INT32_MAX);
  CHECK_EQ(q_abs(-5), 5);
  CHECK_EQ(ms_to_steps(INT32_MAX), static_cast<std::int32_t>((static_cast<std::int64_t>(INT32_MAX) * 120 + 500) / 1000));
  CHECK_EQ(ms_to_steps(20000000), 2400000);
  CHECK_EQ(quantize_256(INT32_MAX), INT32_MAX / 256 * 256);
  CHECK_EQ(quantize_256(INT32_MIN), INT32_MIN);
  CHECK_EQ(quantize_256(INT32_MAX) % INPUT_QUANTUM, 0);
}

TEST_CASE("prng: full int32 range (T25-22)") {
  Pcg32 a(9, 3), b(9, 3);
  // Same sequence as before for ordinary ranges.
  for (int i = 0; i < 1000; ++i) CHECK_EQ(a.range(10, 20), 10 + static_cast<std::int32_t>(b.below(11)));
  Pcg32 r(5, 5), raw(5, 5);
  for (int i = 0; i < 100; ++i) CHECK_EQ(r.range(INT32_MIN, INT32_MAX), static_cast<std::int32_t>(static_cast<std::int64_t>(INT32_MIN) + raw.next()));
  Pcg32 w(1, 2);
  for (int i = 0; i < 1000; ++i) {
    const std::int32_t v = w.range(INT32_MIN, 7);
    CHECK(v <= 7);
  }
}

TEST_CASE("components: stress ratio with a tiny capacity (T25-18)") {
  ToolStress t;
  t.init(1, 0, Q16_ONE);  // S_max = 1 (smallest legal)
  t.load(Q16_ONE, Q16_ONE);
  std::vector<LockEvent> ev;
  EventSink sink(ev);
  t.end_step(0, sink, 0, MaterialId::steel);
  CHECK_EQ(t.ratio(), Q16_ONE);
  CHECK_EQ(t.peak_ratio(), Q16_ONE);
  CHECK(t.broken());
}

TEST_CASE("session: refuses missing tools, missing / foreign params (T25-01/02/14)") {
  const FamilyRegistry& reg = FamilyRegistry::builtin();
  const FamilyModule& pin = *reg.find("pin_tumbler");
  for (const FamilyModule* fam : reg.all()) {
    const LockSpec spec = fam->generate(3, fam->difficulty_for_tier(fam->min_tier()));
    const ToolSet need = fam->required_tools(spec);
    {
      LockSession ok(*fam, spec);  // required tools by default
      CHECK(ok.valid());
      CHECK(ok.failure() == FailureKind::none);
      LockSession explicit_ok(*fam, spec, need);
      CHECK(explicit_ok.valid());
    }
    // No tools at all: rejected, finished at t = 0, step() is a no-op.
    LockSession none(*fam, spec, ToolSet{0});
    CHECK(!none.valid());
    CHECK(none.finished());
    CHECK(!none.is_open());
    CHECK(none.failure() == FailureKind::invalid_spec);
    CHECK(none.error().find("tools") != std::string::npos);
    InputFrame f;
    f.tension = Q16_ONE / 4;
    CHECK(none.step(f).events.empty());
    CHECK_EQ(none.t_step(), 0);
    CHECK(none.describe().elements.empty());
    CHECK(none.state().failure == FailureKind::invalid_spec);
    // Missing parameter block, parameters of another family, wrong family id.
    LockSpec bare = spec;
    bare.params.reset();
    CHECK(!LockSession(*fam, bare, need).valid());
    CHECK(!LockSession(*fam, bare).valid());
    if (fam != &pin) {
      LockSpec foreign = spec;
      foreign.params = pin.generate(3, pin.difficulty_for_tier(2)).params;
      CHECK(!LockSession(*fam, foreign, need).valid());
    }
    LockSpec renamed = spec;
    renamed.family = "something_else";
    CHECK(!LockSession(*fam, renamed, need).valid());
    // Every bot reports the rejection instead of running (feeling included).
    for (BotKind k : {BotKind::scripted, BotKind::clumsy, BotKind::feeling}) {
      const SolveReport r = fam->run_bot(k, spec, ToolSet{0});
      CHECK(!r.ok);
      const SolveReport rb = fam->run_bot(k, bare, need);
      CHECK(!rb.ok);
    }
  }
}

TEST_CASE("components: add_wear keeps the stress history (T25-15)") {
  ToolStress t;
  t.init(Q16_ONE, 0, Q16_ONE);
  std::vector<LockEvent> ev;
  EventSink sink(ev);
  t.load(q16_milli(700), Q16_ONE);  // S = 0.7
  t.end_step(0, sink, 0, MaterialId::steel);
  const q16 peak = t.peak_ratio();
  const q16 s = t.stress();
  CHECK(peak >= q16_milli(690));
  const std::int32_t w0 = t.wear();  // loading itself wore the tool
  t.add_wear(2);
  CHECK_EQ(t.wear(), w0 + 2);
  CHECK_EQ(t.peak_ratio(), peak);
  CHECK_EQ(t.stress(), s);
  CHECK_EQ(t.capacity(), static_cast<q16>((static_cast<std::int64_t>(Q16_ONE) * (250 - w0 - 2)) / 250));
  // set_wear() (save-game wear at session start) still starts from scratch.
  t.set_wear(2);
  CHECK_EQ(t.peak_ratio(), 0);
  t.add_wear(500);
  CHECK_EQ(t.wear(), 100);
}

TEST_CASE("components: end_step without breaking (T25-16)") {
  ToolStress t;
  t.init(Q16_ONE / 2, 0, Q16_ONE);
  std::vector<LockEvent> ev;
  EventSink sink(ev);
  t.load(Q16_ONE, Q16_ONE);  // S = 1 > S_max
  t.end_step(5, sink, 0, MaterialId::steel, false);
  CHECK(!t.broken());
  for (const auto& e : ev) CHECK(e.kind != EventKind::break_);
  t.load(Q16_ONE, Q16_ONE);
  t.end_step(6, sink, 0, MaterialId::steel);
  CHECK(t.broken());
}
