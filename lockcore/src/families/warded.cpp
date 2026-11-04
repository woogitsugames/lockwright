// Warded lock (LOCKS.md §2.2).
//
// State: probe depth, tip height h and turn angle theta (fraction of the full
// turn; open at 1). Ward k blocks the turn through its span [a_lo, a_hi] unless
// the whole bit [h - w/2, h + w/2] lies in its gap; inside the span the tip can
// only move within the gap (ward.scrape). Past the wards the tip meets the bolt
// at a_bolt: with h in the bolt band it catches it (bind); turning on needs
// bolt_spring <= T <= the bit's safe torque (above it the bit only bends), and
// at a_set the bolt is lifted (set); a full turn opens.
// Pressing against a ward or the end stop, or lifting the bolt, with T above the
// bit's safe torque bends the probe (stress). Thin bits pass narrow gaps but are
// weak; t1 probes only bend, from t2 the third stress episode breaks the probe.
// Bits are swapped (InputFrame::tool) only with the probe withdrawn and unturned.
#include "lockcore/warded.hpp"

#include <algorithm>
#include <deque>

#include "lockcore/bot.hpp"
#include "lockcore/hash.hpp"
#include "lockcore/lockfile.hpp"
#include "lockcore/session.hpp"

namespace lockcore::warded {

namespace {

using json::Value;

constexpr q16 APPROACH = q16_milli(60);
constexpr std::int32_t SCRAPE_PERIOD = 10;
constexpr q16 MIN_SPACING = q16_milli(40);

struct State : FamilyState {
  std::shared_ptr<const Params> params;
  MaterialId material = MaterialId::iron;
  int bit = 0;
  q16 theta = 0;
  q16 h = 0;
  q16 depth = 0;
  q16 tension = 0;
  bool engaged = false;
  bool bolt_set = false;
  bool end_hit = false;
  bool warned = false;
  std::int32_t bends = 0;
  int blocked_ward = -1;
  bool blocked = false;
  std::vector<char> aligned;
  std::int64_t scrape_last = -1000;
  q16 resistance = 0;
  q16 drag = 0;
};

const Params& params_of(const LockSpec& spec) { return static_cast<const Params&>(*spec.params); }

bool fits(q16 h, q16 half, const Ward& w) { return h - half >= w.gap_lo && h + half <= w.gap_hi; }

// The plan of the oracle, shared by the scripted and the clumsy bot.
struct WardPlan {
  bool ok = false;
  std::string reason;
  int bit = 0;
  q16 tension = 0;
  std::vector<q16> change_at;  // theta where the height changes (first: 0)
  std::vector<q16> height;     // tip height from there on
};

WardPlan make_plan(const Params& P) {
  WardPlan wp;
  const int n = static_cast<int>(P.wards.size());
  std::string why = "no offered bit fits every gap and lifts the bolt";
  for (int b = 0; b < P.bit_options; ++b) {
    const q16 w = BIT_THICKNESS[static_cast<std::size_t>(b)];
    bool ok = true;
    for (const Ward& k : P.wards) ok = ok && (k.gap_hi - k.gap_lo) - w >= (HUMAN_POSITION_PRECISION * 3) / 2;
    const q16 lo = q_max(P.t_turn, P.bolt_spring);
    const q16 hi = BIT_TAU_SAFE[static_cast<std::size_t>(b)];
    ok = ok && hi - lo >= HUMAN_TENSION_BAND;
    if (!ok) continue;
    wp.bit = b;
    wp.tension = (lo + hi) / 2;
    q16 prev_hi = 0;
    for (int i = 0; i < n; ++i) {
      const Ward& k = P.wards[static_cast<std::size_t>(i)];
      wp.change_at.push_back(i == 0 ? 0 : (prev_hi + k.a_lo) / 2);
      wp.height.push_back((k.gap_lo + k.gap_hi) / 2);
      prev_hi = k.a_hi;
    }
    wp.change_at.push_back(n == 0 ? 0 : (prev_hi + P.a_bolt) / 2);
    wp.height.push_back((P.bolt_lo + P.bolt_hi) / 2);
    wp.ok = true;
    return wp;
  }
  wp.reason = why;
  return wp;
}

class Module final : public FamilyModule {
 public:
  std::string_view id() const override { return FAMILY_ID; }
  std::int32_t rules_version() const override { return RULES_VERSION; }
  std::uint32_t input_mask() const override { return AXIS_TENSION | AXIS_DEPTH | AXIS_LIFT | AXIS_ROTATE; }
  ToolSet required_tools(const LockSpec&) const override { return ToolSet{TOOL_WARD_PROBE}; }

  int min_tier() const override { return 1; }
  int max_tier() const override { return 2; }

  DifficultyVector difficulty_for_tier(int tier) const override {
    // LOCKS.md §2.2: wards 1 -> 4 (procedural 1-3), ward_gap 30 % -> 14 %,
    // bit options (sec) 2 -> 3; t1 probes only bend, t2 breaks after 3 stresses.
    const int t = std::clamp(tier, 1, 2);
    DifficultyVector d;
    d.tier = t;
    d.n_min = t == 1 ? 1 : 2;
    d.n_max = t == 1 ? 2 : 3;
    d.sec_min = d.sec_max = t == 1 ? 2 : 3;
    d.win_shear = q16_milli(t == 1 ? 300 : 180);
    d.tension_band = HUMAN_TENSION_BAND;
    d.overset_margin = 0;
    d.drop_grace_ms = 0;
    d.s_max = Q16_ONE;
    d.time_limit_s = t == 1 ? 60 : 90;
    return d;
  }

  LockSpec generate(std::uint64_t seed, const DifficultyVector& d) const override {
    LockSpec spec;
    for (std::uint32_t attempt = 0; attempt < 16; ++attempt) {
      spec = generate_once(seed, attempt, d);
      if (oracle(spec, required_tools(spec)).ok) break;
    }
    return spec;
  }

  std::vector<SpecError> validate(const LockSpec& spec) const override {
    std::vector<SpecError> e;
    if (spec.family != FAMILY_ID) e.push_back({"family", "not warded"});
    const auto* pp = dynamic_cast<const Params*>(spec.params.get());
    if (pp == nullptr) {
      e.push_back({"spec", "missing or foreign parameters"});
      return e;
    }
    const Params& P = *pp;
    const int n = static_cast<int>(P.wards.size());
    if (n > 6) e.push_back({"spec.wards", "at most 6 wards"});
    if (P.bit_options < 1 || P.bit_options > BIT_COUNT) e.push_back({"spec.bit_options", "need 1..3"});
    if (!(P.a_bolt > 0 && P.a_bolt < P.a_set && P.a_set < Q16_ONE)) e.push_back({"spec.a_bolt_q16", "need 0 < a_bolt < a_set < 1"});
    if (!(P.bolt_lo >= 0 && P.bolt_hi > P.bolt_lo && P.bolt_hi <= Q16_ONE)) e.push_back({"spec.bolt_lo_q16", "bolt band out of range"});
    if (P.bolt_spring <= 0 || P.bolt_spring > Q16_ONE) e.push_back({"spec.bolt_spring_q16", "need 0 < spring <= 1"});
    if (P.t_turn <= 0 || P.t_turn > Q16_ONE) e.push_back({"spec.t_turn_q16", "need 0 < t_turn <= 1"});
    if (P.rot_speed <= 0 || P.rot_speed > q16_milli(20)) e.push_back({"spec.rot_speed_q16", "need 0 < rot_speed <= 0.02"});
    if (P.insert_depth <= WITHDRAWN_DEPTH || P.insert_depth > Q16_ONE) e.push_back({"spec.insert_depth_q16", "out of range"});
    if (P.s_max <= 0 || P.stress_gain <= 0) e.push_back({"spec.s_max_q16", "s_max and stress_gain must be > 0"});
    if (P.bend_limit < 0 || P.bend_limit > 10) e.push_back({"spec.bend_limit", "need 0..10"});
    q16 prev = 0;
    for (int i = 0; i < n; ++i) {
      const Ward& w = P.wards[static_cast<std::size_t>(i)];
      const std::string path = "spec.wards[" + std::to_string(i) + "]";
      if (!(w.a_lo > prev && w.a_hi > w.a_lo && w.a_hi < P.a_bolt)) e.push_back({path + ".a_lo_q16", "spans must increase, apart, before the bolt"});
      if (!(w.gap_lo >= 0 && w.gap_hi > w.gap_lo && w.gap_hi <= Q16_ONE)) e.push_back({path + ".gap_lo_q16", "gap out of range"});
      prev = w.a_hi;
    }
    return e;
  }

  std::unique_ptr<FamilyState> init_state(const LockSpec& spec) const override {
    auto s = std::make_unique<State>();
    s->params = std::static_pointer_cast<const Params>(spec.params);
    s->material = spec.material;
    s->aligned.assign(s->params->wards.size(), 0);
    s->h = BIT_THICKNESS[0] / 2;
    s->tool.init(s->params->s_max, 0, s->params->stress_gain);
    return s;
  }

  void step(FamilyState& base, const InputFrame& in, StepCtx& ctx) const override {
    State& S = static_cast<State&>(base);
    const Params& P = *S.params;
    EventSink& out = *ctx.events;
    const std::int64_t t = ctx.t_step;
    const int n = static_cast<int>(P.wards.size());
    const int bolt_el = n;
    const q16 T = in.tension;
    const q16 r = in.rotate;
    S.tension = T;

    // Bit swap: only withdrawn and unturned.
    if (in.tool != S.bit && in.tool < P.bit_options && S.theta == 0 && in.pick_depth <= WITHDRAWN_DEPTH) {
      S.bit = in.tool;
      out.emit(t, EventKind::contact, -1, q16_milli(300), MaterialId::steel);
    }
    const q16 half = BIT_THICKNESS[static_cast<std::size_t>(S.bit)] / 2;
    const q16 tau_b = BIT_TAU_SAFE[static_cast<std::size_t>(S.bit)];

    // Depth: once turned, the keyhole holds the probe in.
    S.depth = S.theta > 0 ? q_max(in.pick_depth, P.insert_depth) : in.pick_depth;
    const bool inserted = S.depth >= P.insert_depth;

    // Tip height.
    auto inside = [&](q16 th) {
      for (int i = 0; i < n; ++i) {
        const Ward& w = P.wards[static_cast<std::size_t>(i)];
        if (th >= w.a_lo && th <= w.a_hi) return i;
      }
      return -1;
    };
    q16 want_h = q_clamp(in.pick_lift, half, Q16_ONE - half);
    bool scraped = false;
    if (const int k = inside(S.theta); k >= 0) {
      const Ward& w = P.wards[static_cast<std::size_t>(k)];
      if (w.gap_hi - w.gap_lo >= 2 * half) {
        const q16 c = q_clamp(want_h, w.gap_lo + half, w.gap_hi - half);
        scraped = c != want_h;
        want_h = c;
      } else {
        want_h = S.h;
      }
    }
    if (S.theta >= P.a_bolt) {
      if (S.engaged) want_h = q_clamp(want_h, P.bolt_lo, P.bolt_hi);
      else if (S.h < P.bolt_lo) want_h = q_min(want_h, P.bolt_lo - 1);
      else want_h = q_max(want_h, P.bolt_hi + 1);
    }
    S.h = want_h;

    // Turn.
    S.blocked_ward = -1;
    bool blocked_bolt = false;
    q16 d = 0;
    if (inserted && T >= P.t_turn && r != 0) {
      d = q_mul(r, P.rot_speed);
      q16 target = q_clamp(S.theta + d, 0, Q16_ONE);
      if (d > 0) {
        for (int i = 0; i < n; ++i) {
          const Ward& w = P.wards[static_cast<std::size_t>(i)];
          if (S.theta < w.a_lo && target >= w.a_lo && !fits(S.h, half, w)) {
            target = w.a_lo - 1;
            S.blocked_ward = i;
            break;
          }
        }
        if (!S.engaged && S.theta < P.a_bolt && target >= P.a_bolt && S.h >= P.bolt_lo && S.h <= P.bolt_hi) {
          S.engaged = true;
          out.emit(t, EventKind::bind, bolt_el, T, S.material);
        }
        // Too little force does not lift the bolt; more than the bit takes only bends it.
        if (S.engaged && target > q_max(S.theta, P.a_bolt) && (T < P.bolt_spring || T > tau_b)) {
          target = q_max(S.theta, P.a_bolt);
          blocked_bolt = true;
        }
      } else {
        for (int i = n - 1; i >= 0; --i) {
          const Ward& w = P.wards[static_cast<std::size_t>(i)];
          if (S.theta > w.a_hi && target <= w.a_hi && !fits(S.h, half, w)) {
            target = w.a_hi + 1;
            S.blocked_ward = i;
            break;
          }
        }
        if (S.engaged && target < P.a_bolt) {
          S.engaged = false;
          if (S.bolt_set) {
            S.bolt_set = false;
            out.emit(t, EventKind::drop, bolt_el, Q16_ONE, S.material);
          }
        }
      }
      S.theta = target;
      if (S.engaged && !S.bolt_set && S.theta >= P.a_set) {
        S.bolt_set = true;
        out.emit(t, EventKind::set, bolt_el, q16_milli(850), S.material);
      }
      if (S.theta == Q16_ONE && !S.open) {
        if (S.bolt_set) {
          S.open = true;
          out.emit(t, EventKind::open, -1, Q16_ONE, S.material);
        } else if (!S.end_hit) {
          S.end_hit = true;
          out.emit(t, EventKind::contact, -1, material_hardness(S.material), S.material);  // end stop
        }
      }
    }
    if (S.theta < Q16_ONE) S.end_hit = false;
    const bool at_end = S.theta == Q16_ONE && !S.open && d > 0;
    S.blocked = S.blocked_ward >= 0 || blocked_bolt || at_end;

    if ((S.blocked_ward >= 0 || scraped) && t - S.scrape_last >= SCRAPE_PERIOD) {
      S.scrape_last = t;
      const int k = S.blocked_ward >= 0 ? S.blocked_ward : inside(S.theta);
      out.emit(t, EventKind::contact, k, q16_milli(450), S.material, SUB_SCRAPE);
    }

    // Bending: pressing against something, or lifting the bolt, above the bit's limit.
    if ((S.blocked || (S.engaged && d > 0)) && T > tau_b) {
      const q16 press = q_abs(r);
      const q16 inc = q_mul(q_mul(T - tau_b, press), P.s_max > 0 ? P.stress_gain : 0);
      // t1 probes bend but never break: keep S below the breaking point.
      if (P.bend_limit > 0 || S.tool.stress() + inc < S.tool.capacity() - S.tool.capacity() / 10) S.tool.load(T - tau_b, press);
    }

    // gate_align: the bit lines up with the gap of the ward ahead.
    for (int i = 0; i < n; ++i) {
      const Ward& w = P.wards[static_cast<std::size_t>(i)];
      const bool facing = S.theta < w.a_lo && S.theta >= w.a_lo - APPROACH;
      const bool now = facing && fits(S.h, half, w);
      if (now && !S.aligned[static_cast<std::size_t>(i)]) out.emit(t, EventKind::gate_align, i, Q16_ONE, S.material);
      S.aligned[static_cast<std::size_t>(i)] = now ? 1 : 0;
    }

    S.tool.end_step(t, out, S.blocked_ward >= 0 ? S.blocked_ward : (S.engaged ? bolt_el : -1), MaterialId::steel);
    const q16 ratio = S.tool.ratio();
    if (ratio >= ToolStress::STRESS_WARN && !S.warned) {
      S.warned = true;
      ++S.bends;
    } else if (ratio < ToolStress::STRESS_WARN / 2) {
      S.warned = false;
    }
    if (S.tool.broken()) {
      S.failure = FailureKind::break_;
    } else if (P.bend_limit > 0 && S.bends >= P.bend_limit && S.failure == FailureKind::none) {
      S.failure = FailureKind::break_;
      out.emit(t, EventKind::break_, -1, Q16_ONE, MaterialId::steel);
    }

    S.drag = S.blocked ? q_abs(r) : (S.engaged && d > 0 ? P.bolt_spring / 2 : 0);
    S.resistance = S.blocked ? T : (S.engaged ? q_min(T, P.bolt_spring) : T / 4);
    ctx.tension_resistance = S.resistance;
    ctx.pick_drag = S.drag;
  }

  ViewModel describe(const FamilyState& base) const override {
    const State& S = static_cast<const State&>(base);
    const Params& P = *S.params;
    const int n = static_cast<int>(P.wards.size());
    ViewModel v;
    int facing = -1;
    for (int i = 0; i < n; ++i) {
      const Ward& w = P.wards[static_cast<std::size_t>(i)];
      ElementView e;
      e.state = S.blocked_ward == i ? ElementState::bound : (S.aligned[static_cast<std::size_t>(i)] ? ElementState::near : ElementState::free);
      e.position = (w.gap_lo + w.gap_hi) / 2;  // wards do not move: the gap centre
      e.window_lo = w.gap_lo;
      e.window_hi = w.gap_hi;
      e.variant = 0;
      v.elements.push_back(e);
      if (facing < 0 && S.theta <= w.a_hi) facing = i;
    }
    ElementView bolt;
    bolt.state = S.bolt_set ? ElementState::set : (S.engaged ? ElementState::bound : ElementState::free);
    bolt.position = S.engaged ? q_clamp(q_div(S.theta - P.a_bolt, Q16_ONE - P.a_bolt), 0, Q16_ONE) : 0;
    bolt.window_lo = P.bolt_lo;
    bolt.window_hi = P.bolt_hi;
    bolt.variant = 1;
    v.elements.push_back(bolt);
    v.pick_element = facing >= 0 ? facing : n;
    v.pick_lift = S.h;
    v.tension = S.tension;
    v.core_rotation = S.theta;  // 1.0 = the full opening turn
    v.tension_resistance = S.resistance;
    v.pick_drag = S.drag;
    v.stress = S.tool.ratio();
    v.open = S.open;
    v.failure = S.failure;
    return v;
  }

  OracleReport oracle(const LockSpec& spec, const ToolSet& tools) const override {
    OracleReport r;
    const auto errors = validate(spec);
    if (!errors.empty()) {
      r.reason = "invalid spec: " + errors.front().path + ": " + errors.front().message;
      return r;
    }
    if (!tools.has(required_tools(spec).bits)) {
      r.reason = "missing tools";
      return r;
    }
    const Params& P = params_of(spec);
    const int n = static_cast<int>(P.wards.size());
    q16 prev = 0;
    for (int i = 0; i < n; ++i) {
      const Ward& w = P.wards[static_cast<std::size_t>(i)];
      if (w.a_lo - prev < MIN_SPACING) {
        r.reason = "no room to change height before ward " + std::to_string(i);
        return r;
      }
      prev = w.a_hi;
    }
    if (P.a_bolt - prev < MIN_SPACING) {
      r.reason = "no room to change height before the bolt";
      return r;
    }
    if ((P.bolt_hi - P.bolt_lo) * 2 < HUMAN_POSITION_PRECISION * 3) {
      r.reason = "bolt band below 1.5x human precision";
      return r;
    }
    const WardPlan wp = make_plan(P);
    if (!wp.ok) {
      r.reason = wp.reason;
      return r;
    }
    const q16 half = BIT_THICKNESS[static_cast<std::size_t>(wp.bit)] / 2;
    if (P.bolt_lo + (P.bolt_hi - P.bolt_lo) / 2 < half || P.bolt_hi - (P.bolt_hi - P.bolt_lo) / 2 > Q16_ONE - half) {
      r.reason = "bolt band out of the bit's reach";
      return r;
    }
    r.min_band = BIT_TAU_SAFE[static_cast<std::size_t>(wp.bit)] - q_max(P.t_turn, P.bolt_spring);
    r.min_window = P.bolt_hi - P.bolt_lo;
    for (std::size_t i = 0; i < wp.height.size(); ++i) {
      PlanStep st;
      st.element = static_cast<int>(i);  // wards, then the bolt (element n)
      st.depth = q_max(P.insert_depth, q16_milli(950));
      st.tension = wp.tension;
      st.approach_from = wp.change_at[i];  // turn angle where the tip height changes
      st.lift_cap = wp.height[i];          // tip height from there on
      if (i < static_cast<std::size_t>(n)) {
        const Ward& w = P.wards[i];
        r.min_window = q_min(r.min_window, (w.gap_hi - w.gap_lo) - 2 * half);
      }
      r.plan.steps.push_back(st);
    }
    r.plan.release_tension = 0;
    r.plan.t_hold = 0;
    r.plan.drop_all = false;
    r.ok = true;
    return r;
  }

  SolveReport solver(const LockSpec& spec, const ToolSet& tools, const SolveOptions& opt) const override {
    return run_bot(BotKind::scripted, spec, tools, opt);
  }

  SolveReport run_bot(BotKind kind, const LockSpec& spec, const ToolSet& tools, const SolveOptions& opt) const override {
    const OracleReport o = oracle(spec, tools);
    if (!o.ok && kind != BotKind::feeling) {
      SolveReport r;
      r.reason = "oracle: " + o.reason;
      return r;
    }
    const std::int64_t full = static_cast<std::int64_t>(spec.difficulty.time_limit_s) * SIM_HZ;
    switch (kind) {
      case BotKind::scripted: return plan_bot(spec, tools, HumanLimits{}, full / 2, opt, false);
      case BotKind::clumsy: return plan_bot(spec, tools, clumsy_human_limits(), full, opt, true);
      case BotKind::feeling: return feel_bot(spec, tools, feeling_human_limits(), full, opt);
    }
    return {};
  }

  Value params_to_json(const FamilyParams& fp) const override {
    const Params& P = static_cast<const Params&>(fp);
    Value o = Value::object();
    o.set("bit_options", Value::integer(P.bit_options));
    o.set("a_bolt_q16", Value::integer(P.a_bolt));
    o.set("a_set_q16", Value::integer(P.a_set));
    o.set("bolt_lo_q16", Value::integer(P.bolt_lo));
    o.set("bolt_hi_q16", Value::integer(P.bolt_hi));
    o.set("bolt_spring_q16", Value::integer(P.bolt_spring));
    o.set("t_turn_q16", Value::integer(P.t_turn));
    o.set("rot_speed_q16", Value::integer(P.rot_speed));
    o.set("insert_depth_q16", Value::integer(P.insert_depth));
    o.set("s_max_q16", Value::integer(P.s_max));
    o.set("stress_gain_q16", Value::integer(P.stress_gain));
    o.set("bend_limit", Value::integer(P.bend_limit));
    Value arr = Value::array();
    for (const Ward& w : P.wards) {
      Value wo = Value::object();
      wo.set("a_lo_q16", Value::integer(w.a_lo));
      wo.set("a_hi_q16", Value::integer(w.a_hi));
      wo.set("gap_lo_q16", Value::integer(w.gap_lo));
      wo.set("gap_hi_q16", Value::integer(w.gap_hi));
      arr.push(std::move(wo));
    }
    o.set("wards", std::move(arr));
    return o;
  }

  std::shared_ptr<const FamilyParams> params_from_json(const Value& v, std::vector<SpecError>& errors) const override {
    auto P = std::make_shared<Params>();
    const std::string path = ".spec";
    std::int64_t x = 0;
    auto q = [&](const Value& obj, std::string_view key, q16& out, const std::string& p) {
      if (field::get_int(obj, key, 0, 64 * static_cast<std::int64_t>(Q16_ONE), x, errors, p)) out = static_cast<q16>(x);
    };
    if (field::get_int(v, "bit_options", 1, BIT_COUNT, x, errors, path)) P->bit_options = static_cast<int>(x);
    q(v, "a_bolt_q16", P->a_bolt, path);
    q(v, "a_set_q16", P->a_set, path);
    q(v, "bolt_lo_q16", P->bolt_lo, path);
    q(v, "bolt_hi_q16", P->bolt_hi, path);
    q(v, "bolt_spring_q16", P->bolt_spring, path);
    q(v, "t_turn_q16", P->t_turn, path);
    q(v, "rot_speed_q16", P->rot_speed, path);
    q(v, "insert_depth_q16", P->insert_depth, path);
    q(v, "s_max_q16", P->s_max, path);
    q(v, "stress_gain_q16", P->stress_gain, path);
    if (field::get_int(v, "bend_limit", 0, 10, x, errors, path)) P->bend_limit = static_cast<std::int32_t>(x);
    const Value* arr = v.find("wards");
    if (arr == nullptr || !arr->is_array()) {
      errors.push_back({path + ".wards", "expected array"});
      return P;
    }
    for (std::size_t i = 0; i < arr->items().size(); ++i) {
      const Value& wo = arr->items()[i];
      const std::string wp = path + ".wards[" + std::to_string(i) + "]";
      if (!wo.is_object()) {
        errors.push_back({wp, "expected object"});
        continue;
      }
      Ward w;
      q(wo, "a_lo_q16", w.a_lo, wp);
      q(wo, "a_hi_q16", w.a_hi, wp);
      q(wo, "gap_lo_q16", w.gap_lo, wp);
      q(wo, "gap_hi_q16", w.gap_hi, wp);
      P->wards.push_back(w);
    }
    return P;
  }

  std::string_view event_name(std::uint16_t sub) const override {
    return sub == SUB_SCRAPE ? std::string_view("ward.scrape") : std::string_view();
  }

 private:
  LockSpec generate_once(std::uint64_t seed, std::uint32_t attempt, const DifficultyVector& d) const {
    Pcg32 rng(derive_seed(seed ^ splitmix64(attempt), FAMILY_ID, RULES_VERSION, "gen"), derive_stream(FAMILY_ID, "gen"));
    auto P = std::make_shared<Params>();
    const int n = rng.range(d.n_min, d.n_max);
    P->bit_options = std::clamp(d.sec_max, 1, BIT_COUNT);
    P->a_bolt = A_BOLT;
    P->a_set = A_SET;
    P->t_turn = T_TURN;
    P->rot_speed = ROT_SPEED;
    P->insert_depth = INSERT_DEPTH;
    P->s_max = d.s_max;
    P->stress_gain = STRESS_GAIN;
    P->bend_limit = d.tier >= 2 ? 3 : 0;

    // The right bit: exactly one offered profile fits every gap and lifts the bolt.
    const int c = rng.range(0, P->bit_options - 1);
    const q16 slack = q16_milli(d.tier >= 2 ? 20 : 60);
    const q16 fit = BIT_THICKNESS[static_cast<std::size_t>(c)] + (HUMAN_POSITION_PRECISION * 3) / 2;
    q16 thicker = Q16_ONE;  // thinnest offered bit thicker than c: must not fit
    q16 weaker = 0;         // strongest offered bit weaker than c: must not lift the bolt
    for (int b = 0; b < P->bit_options; ++b) {
      if (BIT_THICKNESS[static_cast<std::size_t>(b)] > BIT_THICKNESS[static_cast<std::size_t>(c)])
        thicker = q_min(thicker, BIT_THICKNESS[static_cast<std::size_t>(b)]);
      if (BIT_TAU_SAFE[static_cast<std::size_t>(b)] < BIT_TAU_SAFE[static_cast<std::size_t>(c)])
        weaker = q_max(weaker, BIT_TAU_SAFE[static_cast<std::size_t>(b)]);
    }
    const q16 g_min = fit + rng.range(0, q_max(0, q_min(slack, thicker - fit - q16_milli(5))));
    const q16 tau_c = BIT_TAU_SAFE[static_cast<std::size_t>(c)];
    const q16 sp_lo = weaker > 0 ? weaker + q16_milli(70) : q16_milli(150);
    const q16 sp_hi = tau_c - HUMAN_TENSION_BAND - q16_milli(10);
    P->bolt_spring = rng.range(q_min(sp_lo, sp_hi), sp_hi);

    // Wards: one per slot of [0.06, a_bolt - 0.06], apart by >= MIN_SPACING.
    const q16 from = q16_milli(60), to = P->a_bolt - q16_milli(60);
    const q16 slot = (to - from) / q_max(1, n);
    const int narrow = n > 0 ? rng.range(0, n - 1) : 0;
    for (int i = 0; i < n; ++i) {
      Ward w;
      const q16 width = rng.range(q16_milli(70), q_min(q16_milli(140), slot - MIN_SPACING - q16_milli(10)));
      w.a_lo = from + slot * i + rng.range(MIN_SPACING / 2, slot - width - MIN_SPACING / 2);
      w.a_hi = w.a_lo + width;
      const q16 gap = i == narrow ? g_min : rng.range(g_min, q_max(g_min, q_min(d.win_shear, thicker - q16_milli(5))));
      w.gap_lo = rng.range(q16_milli(50), Q16_ONE - q16_milli(50) - gap);
      w.gap_hi = w.gap_lo + gap;
      P->wards.push_back(w);
    }
    P->bolt_lo = rng.range(q16_milli(150), q16_milli(650));
    P->bolt_hi = P->bolt_lo + q16_milli(180);

    LockSpec spec;
    spec.family = std::string(FAMILY_ID);
    spec.rules_version = RULES_VERSION;
    spec.id = "gen.warded.t" + std::to_string(d.tier) + "." + std::to_string(seed);
    spec.source = "generated";
    spec.seed = seed;
    spec.difficulty = d;
    spec.material = MaterialId::iron;
    spec.params = P;
    return spec;
  }

  // Scripted bot (stage 2): picks the plan's bit, inserts, holds the plan's
  // force and turns, changing the tip height between the wards (dead reckoning
  // on its own turn input), until the open event.
  SolveReport plan_bot(const LockSpec& spec, const ToolSet& tools, const HumanLimits& lim, std::int64_t budget,
                       const SolveOptions& opt, bool clumsy) const {
    const Params& P = params_of(spec);
    const WardPlan wp = make_plan(P);
    SolveReport rep;
    LockSession session(*this, spec, tools);
    Pcg32 rng(derive_seed(spec.seed ^ splitmix64(opt.bot_seed), FAMILY_ID, RULES_VERSION, "bot"), derive_stream(FAMILY_ID, "bot"));
    enum class Ph { select, insert, height, turn, back };
    Ph ph = Ph::select;
    std::int64_t phase_t = 0;
    std::size_t j = 0;  // next height change
    q16 est = 0, hand_t = 0, hand_d = 0, hand_l = wp.height.empty() ? 0 : wp.height.front();
    q16 noise_t = 0, noise_l = 0;
    std::int64_t turned_out = -1;
    const q16 turn_in = clumsy ? q16_milli(900) : q16_milli(600);
    const q16 depth_in = q16_milli(950);
    auto go = [&](Ph p, std::int64_t t) {
      ph = p;
      phase_t = t;
    };
    for (std::int64_t t = 0; t < budget; ++t) {
      q16 target_t = wp.tension, target_d = hand_d, target_l = hand_l, rot = 0;
      switch (ph) {
        case Ph::select:
          target_d = 0;
          if (t - phase_t >= lim.min_hold_steps) go(Ph::insert, t);
          break;
        case Ph::insert:
          target_d = depth_in;
          target_l = wp.height[0];
          if (hand_d == depth_in && hand_l == wp.height[0] && q_abs(hand_t - wp.tension) <= q16_milli(10) &&
              t - phase_t >= lim.min_hold_steps) {
            j = 1;
            go(Ph::turn, t);
          }
          break;
        case Ph::height:
          target_l = wp.height[j];
          if (hand_l == wp.height[j] && t - phase_t >= lim.min_hold_steps) {
            ++j;
            go(Ph::turn, t);
          }
          break;
        case Ph::turn: {
          const q16 v = q_mul(turn_in, P.rot_speed);
          if (j < wp.change_at.size() && est + v >= wp.change_at[j]) {
            go(Ph::height, t);
          } else {
            rot = turn_in;
            if (est >= Q16_ONE) {
              if (turned_out < 0) turned_out = t;
              if (t - turned_out > lim.latency_steps + SIM_HZ) {
                // The open never came: turn all the way back and try again.
                ++rep.retries;
                turned_out = -1;
                go(Ph::back, t);
              }
            }
          }
          break;
        }
        case Ph::back:
          target_l = hand_l;
          rot = -Q16_ONE;
          if (est <= 0) {
            j = 0;
            go(Ph::insert, t);
          }
          break;
      }
      if (rep.retries > 3) {
        rep.reason = "bot: too many retries";
        break;
      }
      hand_t = bot_approach(hand_t, target_t, lim.tension_rate);
      hand_d = bot_approach(hand_d, target_d, lim.depth_rate);
      hand_l = bot_approach(hand_l, target_l, lim.lift_rate);
      if (t % lim.noise_period_steps == 0) {
        noise_t = rng.range(-lim.tension_noise, lim.tension_noise);
        noise_l = rng.range(-lim.lift_noise, lim.lift_noise);
      }
      InputFrame in;
      in.tension = hand_t + noise_t;
      in.pick_depth = hand_d;
      in.pick_lift = hand_l + noise_l;
      in.rotate = rot;
      in.tool = static_cast<std::uint8_t>(wp.bit);
      in = quantize(in);
      if (in.tension >= P.t_turn && hand_d >= P.insert_depth) est = q_clamp(est + q_mul(in.rotate, P.rot_speed), 0, Q16_ONE);
      const StepOutput& out = session.step(in);
      if (opt.record_inputs) rep.inputs.push_back(in);
      for (const auto& e : out.events) {
        if (e.sub == 0 && e.kind == EventKind::drop) ++rep.drops;
      }
      if (session.finished()) break;
    }
    rep.steps = session.t_step();
    rep.event_hash = session.event_hash();
    rep.peak_stress = session.state().tool.peak_ratio();
    if (session.is_open()) {
      if (rep.peak_stress >= BOT_MAX_STRESS) rep.reason = "bot: stress reached 0.8 S_max";
      else rep.ok = true;
    } else if (session.failure() != FailureKind::none) {
      rep.reason = std::string("bot: failure ") + std::string(failure_name(session.failure()));
    } else if (rep.reason.empty()) {
      rep.reason = "bot: step budget exhausted";
    }
    return rep;
  }

  // Feeling bot (stage 3): knows the offered bits only. Turns until blocked; a
  // ward (scrape) is searched by sweeping the tip height while pressing; a bolt
  // that will not lift gets more force; stress means the bit is too weak, a
  // sweep without a gap means it is too thick; the end stop without the bolt
  // means the tip passed beside it.
  SolveReport feel_bot(const LockSpec& spec, const ToolSet& tools, const HumanLimits& lim, std::int64_t budget,
                       const SolveOptions& opt) const {
    const Params& P = params_of(spec);  // bit_options only: the slots offered on the probe
    SolveReport rep;
    LockSession session(*this, spec, tools);
    Pcg32 rng(derive_seed(spec.seed ^ splitmix64(opt.bot_seed), FAMILY_ID, RULES_VERSION, "feel"), derive_stream(FAMILY_ID, "feel"));
    std::deque<LockEvent> perceived;
    std::vector<q16> drag_buf(static_cast<std::size_t>(lim.latency_steps), 0);
    std::size_t drag_head = 0;
    std::vector<char> too_thick(BIT_COUNT, 0), too_weak(BIT_COUNT, 0);
    enum class Ph { withdraw, insert, turn, sweep, push_bolt, back_off, reset };
    Ph ph = Ph::withdraw;
    std::int64_t phase_t = 0;
    int bit = 0;
    q16 work_t = q16_milli(250), hand_t = 0, hand_d = 0, hand_l = q16_milli(500), noise_t = 0, noise_l = 0;
    q16 last_drag = 0, sweep_dir = Q16_ONE;
    int sweep_turns = 0, end_tries = 0;
    std::int64_t free_back = 0;
    bool engaged = false, last_ward = false;
    std::int64_t blocked_since = -1;
    constexpr q16 HEIGHTS[] = {q16_milli(500), q16_milli(300), q16_milli(700), q16_milli(200), q16_milli(800),
                               q16_milli(400), q16_milli(600), q16_milli(120), q16_milli(880)};
    auto go = [&](Ph p, std::int64_t t) {
      ph = p;
      phase_t = t;
      blocked_since = -1;
    };
    auto change_bit = [&](std::int64_t t) {
      // Prefer the untried neighbour: thinner after "too thick", stronger after "too weak".
      int best = -1;
      for (int b = 0; b < P.bit_options; ++b) {
        if (too_thick[static_cast<std::size_t>(b)] || too_weak[static_cast<std::size_t>(b)]) continue;
        bool ok = true;
        for (int o = 0; o < P.bit_options; ++o) {
          if (too_thick[static_cast<std::size_t>(o)] && BIT_THICKNESS[static_cast<std::size_t>(b)] >= BIT_THICKNESS[static_cast<std::size_t>(o)]) ok = false;
          if (too_weak[static_cast<std::size_t>(o)] && BIT_TAU_SAFE[static_cast<std::size_t>(b)] <= BIT_TAU_SAFE[static_cast<std::size_t>(o)]) ok = false;
        }
        if (ok) best = b;
      }
      if (best < 0) {
        for (auto& x : too_thick) x = 0;
        for (auto& x : too_weak) x = 0;
        best = (bit + 1) % P.bit_options;
      }
      bit = best;
      work_t = q16_milli(250);
      engaged = false;
      end_tries = 0;
      ++rep.retries;
      free_back = 0;
      go(Ph::reset, t);
    };
    for (std::int64_t t = 0; t < budget; ++t) {
      while (!perceived.empty() && perceived.front().t_step <= t - lim.latency_steps) {
        const LockEvent e = perceived.front();
        perceived.pop_front();
        if (e.sub == SUB_SCRAPE) last_ward = true;
        if (e.sub != 0) continue;
        if (e.kind == EventKind::bind) engaged = true;
        if (e.kind == EventKind::drop) engaged = false;
        if (e.kind == EventKind::stress && ph != Ph::reset && ph != Ph::withdraw) {
          too_weak[static_cast<std::size_t>(bit)] = 1;
          change_bit(t);
        }
        if (e.kind == EventKind::contact && e.element == -1 && ph == Ph::turn && !engaged) {
          // End stop: the tip went past the bolt.
          ++end_tries;
          go(Ph::back_off, t);
        }
      }
      const q16 felt = drag_buf[drag_head];
      drag_buf[drag_head] = last_drag;
      drag_head = (drag_head + 1) % drag_buf.size();
      const bool blocked = felt >= q16_milli(150);
      q16 target_t = work_t, target_d = hand_d, target_l = hand_l, rot = 0;
      switch (ph) {
        case Ph::withdraw:
          target_d = 0;
          target_t = 0;
          if (hand_d == 0 && t - phase_t >= lim.min_hold_steps) go(Ph::insert, t);
          break;
        case Ph::insert:
          target_d = Q16_ONE;
          if (hand_d == Q16_ONE && t - phase_t >= lim.min_hold_steps) go(Ph::turn, t);
          break;
        case Ph::turn:
          rot = q16_milli(500);
          if (blocked) {
            if (blocked_since < 0) blocked_since = t;
            if (t - blocked_since > lim.latency_steps / 2) {
              if (engaged) go(Ph::push_bolt, t);
              else if (last_ward) {
                sweep_turns = 0;
                go(Ph::sweep, t);
              }
            }
          } else {
            blocked_since = -1;
          }
          break;
        case Ph::sweep:
          // Press lightly and sweep the tip height; the turn goes on when the bit fits.
          rot = q16_milli(300);
          target_l = hand_l + q_mul(sweep_dir, q16_per_step(q16_milli(500)));
          if (target_l >= q16_milli(950) || target_l <= q16_milli(50)) {
            sweep_dir = -sweep_dir;
            ++sweep_turns;
          }
          if (!blocked && t - phase_t > lim.latency_steps) {
            last_ward = false;
            go(Ph::turn, t);
          } else if (sweep_turns >= 3) {
            too_thick[static_cast<std::size_t>(bit)] = 1;
            change_bit(t);
          }
          break;
        case Ph::push_bolt:
          rot = q16_milli(500);
          if (blocked && t - phase_t > lim.latency_steps + lim.min_hold_steps) {
            work_t = q_min(Q16_ONE, work_t + q16_milli(40));
            phase_t = t;
          }
          if (!blocked && t - phase_t > lim.latency_steps) go(Ph::turn, t);
          break;
        case Ph::back_off:
          rot = -Q16_ONE;
          if (t - phase_t > SIM_HZ / 3) {
            target_l = HEIGHTS[static_cast<std::size_t>(end_tries) % (sizeof HEIGHTS / sizeof HEIGHTS[0])];
            if (hand_l == target_l) go(Ph::turn, t);
            rot = 0;
          }
          if (end_tries > 12) {
            too_thick[static_cast<std::size_t>(bit)] = 1;
            change_bit(t);
          }
          break;
        case Ph::reset:
          // Turn all the way back (sweeping the tip through ward gaps when held),
          // then withdraw and swap the bit.
          rot = -Q16_ONE;
          target_t = work_t;
          if (blocked) {
            free_back = 0;
            target_l = hand_l + q_mul(sweep_dir, q16_per_step(q16_milli(500)));
            if (target_l >= q16_milli(950) || target_l <= q16_milli(50)) sweep_dir = -sweep_dir;
          } else if (t - phase_t > lim.latency_steps) {
            ++free_back;
          }
          if (free_back > SIM_HZ * 2) go(Ph::withdraw, t);
          break;
      }
      if (rep.retries > 30) {
        rep.reason = "feel: too many retries";
        break;
      }
      hand_t = bot_approach(hand_t, target_t, lim.tension_rate);
      hand_d = bot_approach(hand_d, target_d, lim.depth_rate);
      hand_l = bot_approach(hand_l, q_clamp(target_l, 0, Q16_ONE), lim.lift_rate);
      if (t % lim.noise_period_steps == 0) {
        noise_t = rng.range(-lim.tension_noise, lim.tension_noise);
        noise_l = rng.range(-lim.lift_noise, lim.lift_noise);
      }
      InputFrame in;
      in.tension = hand_t + noise_t;
      in.pick_depth = hand_d;
      in.pick_lift = hand_l + noise_l;
      in.rotate = rot;
      in.tool = static_cast<std::uint8_t>(bit);
      in = quantize(in);
      const StepOutput& out = session.step(in);
      last_drag = out.pick_drag;
      if (opt.record_inputs) rep.inputs.push_back(in);
      for (const auto& e : out.events) {
        perceived.push_back(e);
        if (e.sub == 0 && e.kind == EventKind::drop) ++rep.drops;
      }
      if (session.finished()) break;
    }
    rep.steps = session.t_step();
    rep.event_hash = session.event_hash();
    rep.peak_stress = session.state().tool.peak_ratio();
    rep.ok = session.is_open();
    if (!rep.ok && rep.reason.empty()) {
      rep.reason = session.failure() != FailureKind::none
                       ? std::string("feel: failure ") + std::string(failure_name(session.failure()))
                       : std::string("feel: step budget exhausted");
    }
    return rep;
  }
};

}  // namespace

std::string_view bit_name(int bit) {
  switch (bit) {
    case BIT_SQUARE: return "square";
    case BIT_HOOK: return "hook";
    case BIT_FORK: return "fork";
    default: return {};
  }
}

std::unique_ptr<FamilyModule> make_module() { return std::make_unique<Module>(); }

}  // namespace lockcore::warded
