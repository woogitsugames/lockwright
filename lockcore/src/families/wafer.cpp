// Wafer lock (LOCKS.md §2.4).
//
// Like the pin tumbler, but a wafer is a single plate: once set it stays where it
// is (the core holds it), there are no security wafers, and an overset is easy to
// fix: easing tension below t_release (which is above t_hold) frees the wafer
// without dropping the others.
#include "lockcore/wafer.hpp"

#include <algorithm>

#include "lockcore/bot.hpp"
#include "lockcore/hash.hpp"
#include "lockcore/lockfile.hpp"

namespace lockcore::wafer {

namespace {

using json::Value;

constexpr q16 PRESS_CAP = q16_milli(500);
constexpr q16 SET_INTENSITY = q16_milli(800);
constexpr q16 RATTLE_SPEED = q16_milli(30);  // depth change per step that rattles
constexpr std::int32_t RATTLE_PERIOD = 10;

struct WaferState {
  ElementState st = ElementState::free;
  q16 p = 0;
  bool near = false;
};

struct State : FamilyState {
  std::shared_ptr<const Params> params;
  MaterialId material = MaterialId::steel;
  std::vector<WaferState> wafers;
  int pick = -1;
  q16 depth = 0;
  q16 lift = 0;
  q16 tension = 0;
  q16 resistance = 0;
  q16 drag = 0;
  std::int64_t rattle_last = -1000;
};

const Params& params_of(const LockSpec& spec) { return static_cast<const Params&>(*spec.params); }

class Module final : public FamilyModule {
 public:
  std::string_view id() const override { return FAMILY_ID; }
  std::int32_t rules_version() const override { return RULES_VERSION; }
  std::uint32_t input_mask() const override { return AXIS_TENSION | AXIS_DEPTH | AXIS_LIFT; }
  ToolSet required_tools(const LockSpec&) const override { return ToolSet{TOOL_TENSION_WRENCH | TOOL_HOOK}; }

  // The card's ranges (3->5 wafers, 14->10 % window, 0.30->0.22 band) are spread
  // over three tiers so the family can also serve as an early lock (D-15).
  int min_tier() const override { return 1; }
  int max_tier() const override { return 3; }

  DifficultyVector difficulty_for_tier(int tier) const override {
    struct Row {
      int n, win, band, margin, grace;
    };
    static constexpr Row rows[] = {{3, 140, 300, 120, 300}, {4, 120, 260, 100, 300}, {5, 100, 220, 80, 250}};
    const int t = std::clamp(tier, 1, 3);
    const Row& r = rows[t - 1];
    DifficultyVector d;
    d.tier = t;
    d.n_min = d.n_max = r.n;
    d.win_shear = q16_milli(r.win);
    d.tension_band = q16_milli(r.band);
    d.overset_margin = q16_milli(r.margin);
    d.bind_spread = Q16_ONE;
    d.multi_bind_p = 0;
    d.noise = 0;
    d.drop_grace_ms = r.grace;
    d.s_max = Q16_ONE;  // constant: the family that teaches breaking
    d.time_limit_s = 60;
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
    if (spec.family != FAMILY_ID) e.push_back({"family", "not wafer"});
    const auto* pp = dynamic_cast<const Params*>(spec.params.get());
    if (pp == nullptr) {
      e.push_back({"spec", "missing or foreign parameters"});
      return e;
    }
    const Params& P = *pp;
    const int n = static_cast<int>(P.wafers.size());
    if (n < 1 || n > 12) e.push_back({"spec.wafers", "need 1..12 wafers"});
    if (P.win_shear < q16_milli(20) || P.win_shear > q16_milli(400)) e.push_back({"spec.win_shear_q16", "out of range"});
    if (P.overset_margin < 0) e.push_back({"spec.overset_margin_q16", "negative"});
    if (P.tension_band <= 0) e.push_back({"spec.tension_band_q16", "must be > 0"});
    if (P.t_hold <= 0 || P.t_release <= P.t_hold) e.push_back({"spec.t_release_q16", "need 0 < t_hold < t_release"});
    if (P.tau_safe <= P.t_hold || P.tau_safe > Q16_ONE) e.push_back({"spec.tau_safe_q16", "need t_hold < tau_safe <= 1"});
    if (P.drop_grace_steps < 1) e.push_back({"spec.drop_grace_steps", "must be >= 1"});
    if (P.s_max <= 0 || P.stress_gain <= 0 || P.bound_speed <= 0) e.push_back({"spec.s_max_q16", "s_max, gain, speed must be > 0"});
    for (int i = 0; i < n; ++i) {
      const Wafer& w = P.wafers[static_cast<std::size_t>(i)];
      const std::string path = "spec.wafers[" + std::to_string(i) + "]";
      if (P.win_lo(w) < q16_milli(100) || P.win_hi(w) + P.overset_margin > q16_milli(980))
        e.push_back({path + ".target_q16", "window outside travel"});
      if (w.band_lo < P.t_release || P.t_stick(w) > Q16_ONE) e.push_back({path + ".band_lo_q16", "need t_release <= band_lo"});
      if (w.order < 0) e.push_back({path + ".order_q16", "negative"});
    }
    return e;
  }

  std::unique_ptr<FamilyState> init_state(const LockSpec& spec) const override {
    auto s = std::make_unique<State>();
    s->params = std::static_pointer_cast<const Params>(spec.params);
    s->material = spec.material;
    s->wafers.resize(s->params->wafers.size());
    s->tool.init(s->params->s_max, 0, s->params->stress_gain);
    return s;
  }

  void step(FamilyState& base, const InputFrame& in, StepCtx& ctx) const override {
    State& S = static_cast<State&>(base);
    const Params& P = *S.params;
    EventSink& out = *ctx.events;
    const std::int64_t t = ctx.t_step;
    const int n = static_cast<int>(P.wafers.size());
    const q16 T = in.tension;
    const q16 lift = q_max(0, in.pick_lift);

    const int pick = locate_element(in.pick_depth, n);
    if (pick >= 0 && pick != S.pick) out.emit(t, EventKind::contact, pick, material_hardness(S.material), S.material);
    // Loose wafers rattle when the pick sweeps fast with some lift.
    if (lift > 0 && q_abs(in.pick_depth - S.depth) >= RATTLE_SPEED && t - S.rattle_last >= RATTLE_PERIOD) {
      S.rattle_last = t;
      out.emit(t, EventKind::contact, pick, q16_milli(250), S.material, SUB_RATTLE);
    }
    S.pick = pick;
    S.depth = in.pick_depth;
    S.lift = lift;
    S.tension = T;

    // Drop: every set wafer falls.
    if (S.hold.update(T, P.t_hold, P.drop_grace_steps)) {
      int dropped = 0;
      for (auto& w : S.wafers) {
        if (w.st == ElementState::set) {
          w = WaferState{};
          ++dropped;
        }
      }
      if (dropped > 0) out.emit(t, EventKind::drop, -1, q16_ratio(dropped, n), S.material);
    }
    if (T < P.t_release) {
      for (auto& w : S.wafers) {
        if (w.st == ElementState::overset) w = WaferState{};
      }
    }

    bool jammed = false;
    q16 min_o = Q16_ONE * 64;
    for (int i = 0; i < n; ++i) {
      const WaferState& w = S.wafers[static_cast<std::size_t>(i)];
      jammed = jammed || w.st == ElementState::overset;
      if (w.st == ElementState::free || w.st == ElementState::bound)
        min_o = q_min(min_o, P.wafers[static_cast<std::size_t>(i)].order);
    }
    for (int i = 0; i < n; ++i) {
      WaferState& w = S.wafers[static_cast<std::size_t>(i)];
      const Wafer& k = P.wafers[static_cast<std::size_t>(i)];
      if (w.st != ElementState::free && w.st != ElementState::bound) continue;
      const bool want = !jammed && k.order == min_o && T >= k.band_lo;
      if (want && w.st == ElementState::free) {
        w.st = ElementState::bound;
        out.emit(t, EventKind::bind, i, T, S.material);
        if (w.p > P.win_hi(k)) {
          w.st = ElementState::overset;
          out.emit(t, EventKind::overset, i, Q16_ONE, S.material);
          continue;
        }
        w.near = w.p >= P.win_lo(k) - (P.win_shear * 3) / 2;
      } else if (!want && w.st == ElementState::bound) {
        w.st = ElementState::free;
        w.near = false;
      }
    }

    q16 drag = 0;
    for (int i = 0; i < n; ++i) {
      WaferState& w = S.wafers[static_cast<std::size_t>(i)];
      const Wafer& k = P.wafers[static_cast<std::size_t>(i)];
      const q16 li = (i == pick) ? lift : 0;
      const q16 lo = P.win_lo(k);
      switch (w.st) {
        case ElementState::free: w.p = li; break;
        case ElementState::bound: {
          if (li > w.p) {
            const q16 press = li - w.p;
            if (T <= P.t_stick(k)) w.p += q_min(press, P.bound_speed);
            if (T > P.tau_safe) S.tool.load(T - P.tau_safe, q_min(press, PRESS_CAP));
            drag = q_max(drag, press);
          }
          const q16 zone = (P.win_shear * 3) / 2;
          if (w.p >= lo) {
            w.st = ElementState::set;
            w.near = false;
            out.emit(t, EventKind::set, i, SET_INTENSITY, S.material);
          } else if (!w.near && w.p >= lo - zone) {
            w.near = true;
            out.emit(t, EventKind::near_shear, i, q_div(w.p - (lo - zone), zone), S.material);
          }
          break;
        }
        case ElementState::set:
          // The core holds a set wafer in place; the pick can still push it higher.
          w.p = q_max(w.p, li);
          if (T >= P.t_hold && w.p > P.win_hi(k) + P.overset_margin) {
            w.st = ElementState::overset;
            out.emit(t, EventKind::overset, i, Q16_ONE, S.material);
          }
          break;
        case ElementState::overset: w.p = q_max(w.p, li); break;
        default: break;
      }
    }

    if (!S.open && T >= P.t_hold &&
        std::all_of(S.wafers.begin(), S.wafers.end(), [](const WaferState& w) { return w.st == ElementState::set; })) {
      S.open = true;
      out.emit(t, EventKind::open, -1, Q16_ONE, S.material);
    }

    S.tool.end_step(t, out, pick, MaterialId::steel);
    if (S.tool.broken()) S.failure = FailureKind::break_;

    bool any_bound = false;
    for (const auto& w : S.wafers) any_bound = any_bound || w.st == ElementState::bound;
    S.resistance = jammed ? T : (any_bound ? q_mul(T, q16_milli(700)) : T / 4);
    S.drag = drag;
    ctx.tension_resistance = S.resistance;
    ctx.pick_drag = drag;
  }

  ViewModel describe(const FamilyState& base) const override {
    const State& S = static_cast<const State&>(base);
    const Params& P = *S.params;
    ViewModel v;
    int sets = 0;
    for (std::size_t i = 0; i < S.wafers.size(); ++i) {
      const WaferState& w = S.wafers[i];
      ElementView e;
      e.state = (w.st == ElementState::bound && w.near) ? ElementState::near : w.st;
      e.position = w.p;
      e.window_lo = P.win_lo(P.wafers[i]);
      e.window_hi = P.win_hi(P.wafers[i]);
      v.elements.push_back(e);
      sets += w.st == ElementState::set ? 1 : 0;
    }
    v.pick_element = S.pick;
    v.pick_lift = S.lift;
    v.tension = S.tension;
    v.core_rotation = S.open ? Q16_ONE : q16_milli(15) * sets;
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
    const int n = static_cast<int>(P.wafers.size());
    std::vector<int> order(static_cast<std::size_t>(n));
    for (int i = 0; i < n; ++i) order[static_cast<std::size_t>(i)] = i;
    std::stable_sort(order.begin(), order.end(), [&](int a, int b) {
      return P.wafers[static_cast<std::size_t>(a)].order < P.wafers[static_cast<std::size_t>(b)].order;
    });
    if (P.win_shear * 2 < HUMAN_POSITION_PRECISION * 3 || P.win_shear + P.overset_margin < HUMAN_POSITION_PRECISION * 3) {
      r.reason = "position window too narrow for a human";
      return r;
    }
    // The overset fix must be reachable without starting a drop: a human needs
    // room between t_hold and t_release.
    if (P.t_release - P.t_hold < HUMAN_TENSION_BAND) {
      r.reason = "release band narrower than delta_human";
      return r;
    }
    r.min_band = Q16_ONE;
    r.min_window = P.win_shear;
    for (int idx : order) {
      const Wafer& k = P.wafers[static_cast<std::size_t>(idx)];
      const q16 lo = q_max(P.t_release, k.band_lo);
      const q16 hi = q_min(P.t_stick(k), P.tau_safe);
      if (hi - lo < HUMAN_TENSION_BAND) {
        r.reason = "tension band of wafer " + std::to_string(idx) + " narrower than delta_human";
        return r;
      }
      r.min_band = q_min(r.min_band, hi - lo);
      PlanStep st;
      st.element = idx;
      st.depth = element_center(idx, n);
      st.tension = (lo + hi) / 2;
      st.approach_from = q_max(0, P.win_lo(k) - (P.win_shear * 3) / 2 - q16_milli(60));
      st.lift_cap = P.win_hi(k) + P.overset_margin / 2;
      r.plan.steps.push_back(st);
    }
    r.plan.release_tension = (P.t_hold + P.t_release) / 2;
    r.plan.t_hold = P.t_hold;
    r.plan.drop_all = true;
    r.ok = true;
    return r;
  }

  Value params_to_json(const FamilyParams& fp) const override {
    const Params& P = static_cast<const Params&>(fp);
    Value o = Value::object();
    o.set("win_shear_q16", Value::integer(P.win_shear));
    o.set("overset_margin_q16", Value::integer(P.overset_margin));
    o.set("tension_band_q16", Value::integer(P.tension_band));
    o.set("t_hold_q16", Value::integer(P.t_hold));
    o.set("t_release_q16", Value::integer(P.t_release));
    o.set("tau_safe_q16", Value::integer(P.tau_safe));
    o.set("drop_grace_steps", Value::integer(P.drop_grace_steps));
    o.set("s_max_q16", Value::integer(P.s_max));
    o.set("stress_gain_q16", Value::integer(P.stress_gain));
    o.set("noise_q16", Value::integer(P.noise));
    o.set("bound_speed_q16", Value::integer(P.bound_speed));
    Value arr = Value::array();
    for (const Wafer& w : P.wafers) {
      Value wo = Value::object();
      wo.set("target_q16", Value::integer(w.target));
      wo.set("order_q16", Value::integer(w.order));
      wo.set("band_lo_q16", Value::integer(w.band_lo));
      arr.push(std::move(wo));
    }
    o.set("wafers", std::move(arr));
    return o;
  }

  std::shared_ptr<const FamilyParams> params_from_json(const Value& v, std::vector<SpecError>& errors) const override {
    auto P = std::make_shared<Params>();
    const std::string path = ".spec";
    std::int64_t x = 0;
    auto q = [&](const Value& obj, std::string_view key, q16& out, const std::string& p) {
      if (field::get_int(obj, key, 0, 64 * static_cast<std::int64_t>(Q16_ONE), x, errors, p)) out = static_cast<q16>(x);
    };
    q(v, "win_shear_q16", P->win_shear, path);
    q(v, "overset_margin_q16", P->overset_margin, path);
    q(v, "tension_band_q16", P->tension_band, path);
    q(v, "t_hold_q16", P->t_hold, path);
    q(v, "t_release_q16", P->t_release, path);
    q(v, "tau_safe_q16", P->tau_safe, path);
    if (field::get_int(v, "drop_grace_steps", 1, 100000, x, errors, path)) P->drop_grace_steps = static_cast<std::int32_t>(x);
    q(v, "s_max_q16", P->s_max, path);
    q(v, "stress_gain_q16", P->stress_gain, path);
    q(v, "noise_q16", P->noise, path);
    q(v, "bound_speed_q16", P->bound_speed, path);
    const Value* arr = v.find("wafers");
    if (arr == nullptr || !arr->is_array()) {
      errors.push_back({path + ".wafers", "expected array"});
      return P;
    }
    for (std::size_t i = 0; i < arr->items().size(); ++i) {
      const Value& wo = arr->items()[i];
      const std::string wp = path + ".wafers[" + std::to_string(i) + "]";
      if (!wo.is_object()) {
        errors.push_back({wp, "expected object"});
        continue;
      }
      Wafer w;
      q(wo, "target_q16", w.target, wp);
      q(wo, "order_q16", w.order, wp);
      q(wo, "band_lo_q16", w.band_lo, wp);
      P->wafers.push_back(w);
    }
    return P;
  }

  std::string_view event_name(std::uint16_t sub) const override {
    return sub == SUB_RATTLE ? std::string_view("wafer.rattle") : std::string_view();
  }

 private:
  LockSpec generate_once(std::uint64_t seed, std::uint32_t attempt, const DifficultyVector& d) const {
    Pcg32 rng(derive_seed(seed ^ splitmix64(attempt), FAMILY_ID, RULES_VERSION, "gen"),
              derive_stream(FAMILY_ID, "gen"));
    auto P = std::make_shared<Params>();
    const int n = rng.range(d.n_min, d.n_max);
    P->win_shear = d.win_shear;
    P->overset_margin = d.overset_margin;
    P->tension_band = d.tension_band;
    P->t_hold = T_HOLD;
    P->t_release = T_RELEASE;
    P->drop_grace_steps = ms_to_steps(d.drop_grace_ms);
    P->s_max = d.s_max;
    P->stress_gain = STRESS_GAIN;
    P->noise = d.noise;
    P->bound_speed = BOUND_SPEED;
    P->wafers.resize(static_cast<std::size_t>(n));
    std::vector<int> perm(static_cast<std::size_t>(n));
    for (int i = 0; i < n; ++i) perm[static_cast<std::size_t>(i)] = i;
    for (int i = n - 1; i > 0; --i) std::swap(perm[static_cast<std::size_t>(i)], perm[rng.below(static_cast<std::uint32_t>(i + 1))]);
    const q16 unit = q_max(1, q_mul(d.bind_spread, q16_milli(100)));
    q16 max_stick = 0;
    for (int r = 0; r < n; ++r) {
      Wafer& w = P->wafers[static_cast<std::size_t>(perm[static_cast<std::size_t>(r)])];
      w.order = unit * r;
      w.band_lo = T_BIND_BASE + rng.range(0, T_BIND_JITTER);
    }
    for (Wafer& w : P->wafers) {
      w.target = rng.range(q16_milli(400), q16_milli(700));
      max_stick = q_max(max_stick, w.band_lo + P->tension_band);
    }
    P->tau_safe = q_min(Q16_ONE, max_stick + TAU_SAFE_MARGIN);

    LockSpec spec;
    spec.family = std::string(FAMILY_ID);
    spec.rules_version = RULES_VERSION;
    spec.id = "gen.wafer.t" + std::to_string(d.tier) + "." + std::to_string(seed);
    spec.source = "generated";
    spec.seed = seed;
    spec.difficulty = d;
    spec.material = MaterialId::steel;
    spec.params = P;
    return spec;
  }
};

}  // namespace

std::unique_ptr<FamilyModule> make_module() { return std::make_unique<Module>(); }

}  // namespace lockcore::wafer
