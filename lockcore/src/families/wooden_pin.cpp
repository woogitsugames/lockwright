// Wooden pin bolt (LOCKS.md §2.1).
//
// Pegs drop from the housing into holes of a wooden bolt. Pulling the bolt
// sideways (tension) makes the unset peg with the lowest binding offset bind;
// it rises with the peg lifter only while T <= t_stick. At the housing edge it
// sets and stays up while T >= t_hold. Releasing the bolt (T < t_hold for
// drop_grace) drops every set peg. Lifting a set peg above the window by
// overset_margin wedges it in the housing (overset, off in tutorials); easing
// below t_release (above t_hold) frees it without a drop. A hard pull only
// creaks (wood.creak): this family never breaks a tool. Opening needs every peg
// set and T >= t_hold for open_hold (the bolt slides out).
#include "lockcore/wooden_pin.hpp"

#include <algorithm>

#include "lockcore/bot.hpp"
#include "lockcore/hash.hpp"
#include "lockcore/lockfile.hpp"

namespace lockcore::wooden {

namespace {

using json::Value;

constexpr q16 SET_INTENSITY = q16_milli(600);  // soft wooden knock
constexpr std::int32_t CREAK_PERIOD = 18;

struct PegState {
  ElementState st = ElementState::free;
  q16 p = 0;
  bool near = false;
};

struct State : FamilyState {
  std::shared_ptr<const Params> params;
  MaterialId material = MaterialId::wood;
  std::vector<PegState> pegs;
  int pick = -1;
  q16 lift = 0;
  q16 tension = 0;
  q16 resistance = 0;
  q16 drag = 0;
  std::int32_t open_hold = 0;
  std::int64_t creak_last = -1000;
};

const Params& params_of(const LockSpec& spec) { return static_cast<const Params&>(*spec.params); }

class Module final : public FamilyModule {
 public:
  std::string_view id() const override { return FAMILY_ID; }
  std::int32_t rules_version() const override { return RULES_VERSION; }
  std::uint32_t input_mask() const override { return AXIS_TENSION | AXIS_DEPTH | AXIS_LIFT; }
  // The bolt is pulled by hand (left thumb): no tension wrench.
  ToolSet required_tools(const LockSpec&) const override { return ToolSet{TOOL_PEG_LIFTER}; }

  // The card's tutorials (1-3 pegs, no overset) are authored locks; the
  // procedural tier t1 uses 3-4 pegs with overset.
  int min_tier() const override { return 1; }
  int max_tier() const override { return 1; }

  DifficultyVector difficulty_for_tier(int) const override {
    DifficultyVector d;
    d.tier = 1;
    d.n_min = 3;
    d.n_max = 4;
    d.win_shear = q16_milli(150);
    d.tension_band = q16_milli(300);
    d.overset_margin = q16_milli(150);
    d.bind_spread = Q16_ONE;
    d.drop_grace_ms = 300;
    d.s_max = Q16_ONE;  // unused: the tool does not break
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
    if (spec.family != FAMILY_ID) e.push_back({"family", "not wooden_pin"});
    const auto* pp = dynamic_cast<const Params*>(spec.params.get());
    if (pp == nullptr) {
      e.push_back({"spec", "missing or foreign parameters"});
      return e;
    }
    const Params& P = *pp;
    const int n = static_cast<int>(P.pegs.size());
    if (n < 1 || n > 8) e.push_back({"spec.pegs", "need 1..8 pegs"});
    if (P.win_shear < q16_milli(20) || P.win_shear > q16_milli(400)) e.push_back({"spec.win_shear_q16", "out of range"});
    if (P.overset_margin < 0) e.push_back({"spec.overset_margin_q16", "negative"});
    if (P.tension_band <= 0) e.push_back({"spec.tension_band_q16", "must be > 0"});
    if (P.t_hold <= 0 || P.t_release <= P.t_hold) e.push_back({"spec.t_release_q16", "need 0 < t_hold < t_release"});
    if (P.tau_creak <= P.t_hold || P.tau_creak > Q16_ONE) e.push_back({"spec.tau_creak_q16", "need t_hold < tau_creak <= 1"});
    if (P.drop_grace_steps < 1) e.push_back({"spec.drop_grace_steps", "must be >= 1"});
    if (P.open_hold_steps < 1 || P.open_hold_steps > 600) e.push_back({"spec.open_hold_steps", "need 1..600"});
    if (P.bound_speed <= 0) e.push_back({"spec.bound_speed_q16", "must be > 0"});
    for (int i = 0; i < n; ++i) {
      const Peg& k = P.pegs[static_cast<std::size_t>(i)];
      const std::string path = "spec.pegs[" + std::to_string(i) + "]";
      const q16 top = P.win_hi(k) + (P.overset_enabled ? P.overset_margin : 0);
      if (P.win_lo(k) < q16_milli(100) || top > q16_milli(980)) e.push_back({path + ".target_q16", "window outside travel"});
      if (k.band_lo < P.t_release || P.t_stick(k) > Q16_ONE) e.push_back({path + ".band_lo_q16", "need t_release <= band_lo"});
      if (k.order < 0) e.push_back({path + ".order_q16", "negative"});
    }
    return e;
  }

  std::unique_ptr<FamilyState> init_state(const LockSpec& spec) const override {
    auto s = std::make_unique<State>();
    s->params = std::static_pointer_cast<const Params>(spec.params);
    s->material = spec.material;
    s->pegs.resize(s->params->pegs.size());
    s->tool.init(Q16_ONE, 0, Q16_ONE);  // never loaded
    return s;
  }

  void step(FamilyState& base, const InputFrame& in, StepCtx& ctx) const override {
    State& S = static_cast<State&>(base);
    const Params& P = *S.params;
    EventSink& out = *ctx.events;
    const std::int64_t t = ctx.t_step;
    const int n = static_cast<int>(P.pegs.size());
    const q16 T = in.tension;
    const q16 lift = q_max(0, in.pick_lift);

    const int pick = locate_element(in.pick_depth, n);
    if (pick >= 0 && pick != S.pick) out.emit(t, EventKind::contact, pick, material_hardness(S.material), S.material);
    S.pick = pick;
    S.lift = lift;
    S.tension = T;

    // Releasing the bolt drops every set peg.
    if (S.hold.update(T, P.t_hold, P.drop_grace_steps)) {
      int dropped = 0;
      for (auto& g : S.pegs) {
        if (g.st == ElementState::set) {
          g = PegState{};
          ++dropped;
        }
      }
      if (dropped > 0) out.emit(t, EventKind::drop, -1, q16_ratio(dropped, n), S.material);
    }
    if (T < P.t_release) {
      for (auto& g : S.pegs) {
        if (g.st == ElementState::overset) g = PegState{};
      }
    }

    bool jammed = false;
    q16 min_o = Q16_ONE * 64;
    for (int i = 0; i < n; ++i) {
      const PegState& g = S.pegs[static_cast<std::size_t>(i)];
      jammed = jammed || g.st == ElementState::overset;
      if (g.st == ElementState::free || g.st == ElementState::bound) min_o = q_min(min_o, P.pegs[static_cast<std::size_t>(i)].order);
    }
    for (int i = 0; i < n; ++i) {
      PegState& g = S.pegs[static_cast<std::size_t>(i)];
      const Peg& k = P.pegs[static_cast<std::size_t>(i)];
      if (g.st != ElementState::free && g.st != ElementState::bound) continue;
      const bool want = !jammed && k.order == min_o && T >= k.band_lo;
      if (want && g.st == ElementState::free) {
        g.st = ElementState::bound;
        out.emit(t, EventKind::bind, i, T, S.material);
        if (P.overset_enabled && g.p > P.win_hi(k)) {
          g.st = ElementState::overset;
          out.emit(t, EventKind::overset, i, Q16_ONE, S.material);
          continue;
        }
        g.near = g.p >= P.win_lo(k) - (P.win_shear * 3) / 2;
      } else if (!want && g.st == ElementState::bound) {
        g.st = ElementState::free;
        g.near = false;
      }
    }

    q16 drag = 0;
    bool pressing = false;
    for (int i = 0; i < n; ++i) {
      PegState& g = S.pegs[static_cast<std::size_t>(i)];
      const Peg& k = P.pegs[static_cast<std::size_t>(i)];
      const q16 li = (i == pick) ? lift : 0;
      const q16 lo = P.win_lo(k);
      switch (g.st) {
        case ElementState::free: g.p = li; break;
        case ElementState::bound: {
          if (li > g.p) {
            const q16 press = li - g.p;
            if (T <= P.t_stick(k)) g.p += q_min(press, P.bound_speed);
            pressing = true;
            drag = q_max(drag, press);
          }
          const q16 zone = (P.win_shear * 3) / 2;
          if (g.p >= lo) {
            g.st = ElementState::set;
            g.near = false;
            out.emit(t, EventKind::set, i, SET_INTENSITY, S.material);
          } else if (!g.near && g.p >= lo - zone) {
            g.near = true;
            out.emit(t, EventKind::near_shear, i, q_div(g.p - (lo - zone), zone), S.material);
          }
          break;
        }
        case ElementState::set:
          // The pulled bolt holds the peg at the housing edge; the lifter can push it higher.
          g.p = q_max(g.p, li);
          if (P.overset_enabled && T >= P.t_hold && g.p > P.win_hi(k) + P.overset_margin) {
            g.st = ElementState::overset;
            out.emit(t, EventKind::overset, i, Q16_ONE, S.material);
          }
          break;
        case ElementState::overset: g.p = q_max(g.p, li); break;
        default: break;
      }
    }

    // A hard pull creaks; nothing breaks (learning family).
    if (T > P.tau_creak && (pressing || jammed) && t - S.creak_last >= CREAK_PERIOD) {
      S.creak_last = t;
      out.emit(t, EventKind::stress, pick, q_div(T - P.tau_creak, Q16_ONE - P.tau_creak + 1), S.material, SUB_CREAK);
    }

    const bool all_set =
        std::all_of(S.pegs.begin(), S.pegs.end(), [](const PegState& g) { return g.st == ElementState::set; });
    S.open_hold = (all_set && T >= P.t_hold) ? S.open_hold + 1 : 0;
    if (!S.open && S.open_hold >= P.open_hold_steps) {
      S.open = true;
      out.emit(t, EventKind::open, -1, Q16_ONE, S.material);
    }

    bool any_bound = false;
    for (const auto& g : S.pegs) any_bound = any_bound || g.st == ElementState::bound;
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
    for (std::size_t i = 0; i < S.pegs.size(); ++i) {
      const PegState& g = S.pegs[i];
      ElementView e;
      e.state = (g.st == ElementState::bound && g.near) ? ElementState::near : g.st;
      e.position = g.p;
      e.window_lo = P.win_lo(P.pegs[i]);
      e.window_hi = P.win_hi(P.pegs[i]);
      v.elements.push_back(e);
      sets += g.st == ElementState::set ? 1 : 0;
    }
    v.pick_element = S.pick;
    v.pick_lift = S.lift;
    v.tension = S.tension;
    // core_rotation = bolt travel: a small shift per set peg, then the slide-out.
    const q16 slide = q_ratio_safe(S.open_hold, P.open_hold_steps);
    v.core_rotation = S.open ? Q16_ONE : q16_milli(20) * sets + q_mul(slide, q16_milli(100));
    v.tension_resistance = S.resistance;
    v.pick_drag = S.drag;
    v.stress = 0;
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
    const int n = static_cast<int>(P.pegs.size());
    std::vector<int> order(static_cast<std::size_t>(n));
    for (int i = 0; i < n; ++i) order[static_cast<std::size_t>(i)] = i;
    std::stable_sort(order.begin(), order.end(), [&](int a, int b) {
      return P.pegs[static_cast<std::size_t>(a)].order < P.pegs[static_cast<std::size_t>(b)].order;
    });
    for (std::size_t i = 1; i < order.size(); ++i) {
      if (P.pegs[static_cast<std::size_t>(order[i])].order == P.pegs[static_cast<std::size_t>(order[i - 1])].order) {
        r.reason = "two pegs share a binding offset";
        return r;
      }
    }
    if (P.win_shear * 2 < HUMAN_POSITION_PRECISION * 3 ||
        (P.overset_enabled && P.win_shear + P.overset_margin < HUMAN_POSITION_PRECISION * 3)) {
      r.reason = "position window too narrow for a human";
      return r;
    }
    if (P.t_release - P.t_hold < HUMAN_TENSION_BAND) {
      r.reason = "release band narrower than delta_human";
      return r;
    }
    r.min_band = Q16_ONE;
    r.min_window = P.win_shear;
    for (int idx : order) {
      const Peg& k = P.pegs[static_cast<std::size_t>(idx)];
      const q16 lo = q_max(P.t_release, k.band_lo);
      const q16 hi = q_min(P.t_stick(k), P.tau_creak);
      if (hi - lo < HUMAN_TENSION_BAND) {
        r.reason = "tension band of peg " + std::to_string(idx) + " narrower than delta_human";
        return r;
      }
      r.min_band = q_min(r.min_band, hi - lo);
      PlanStep st;
      st.element = idx;
      st.depth = element_center(idx, n);
      st.tension = (lo + hi) / 2;
      st.approach_from = q_max(0, P.win_lo(k) - (P.win_shear * 3) / 2 - q16_milli(60));
      st.lift_cap = P.overset_enabled ? P.win_hi(k) + P.overset_margin / 2 : P.win_hi(k);
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
    o.set("overset_enabled", Value::boolean(P.overset_enabled));
    o.set("overset_margin_q16", Value::integer(P.overset_margin));
    o.set("tension_band_q16", Value::integer(P.tension_band));
    o.set("t_hold_q16", Value::integer(P.t_hold));
    o.set("t_release_q16", Value::integer(P.t_release));
    o.set("tau_creak_q16", Value::integer(P.tau_creak));
    o.set("drop_grace_steps", Value::integer(P.drop_grace_steps));
    o.set("open_hold_steps", Value::integer(P.open_hold_steps));
    o.set("bound_speed_q16", Value::integer(P.bound_speed));
    Value arr = Value::array();
    for (const Peg& k : P.pegs) {
      Value po = Value::object();
      po.set("target_q16", Value::integer(k.target));
      po.set("order_q16", Value::integer(k.order));
      po.set("band_lo_q16", Value::integer(k.band_lo));
      arr.push(std::move(po));
    }
    o.set("pegs", std::move(arr));
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
    field::get_bool(v, "overset_enabled", P->overset_enabled, errors, path);
    q(v, "overset_margin_q16", P->overset_margin, path);
    q(v, "tension_band_q16", P->tension_band, path);
    q(v, "t_hold_q16", P->t_hold, path);
    q(v, "t_release_q16", P->t_release, path);
    q(v, "tau_creak_q16", P->tau_creak, path);
    if (field::get_int(v, "drop_grace_steps", 1, 100000, x, errors, path)) P->drop_grace_steps = static_cast<std::int32_t>(x);
    if (field::get_int(v, "open_hold_steps", 1, 600, x, errors, path)) P->open_hold_steps = static_cast<std::int32_t>(x);
    q(v, "bound_speed_q16", P->bound_speed, path);
    const Value* arr = v.find("pegs");
    if (arr == nullptr || !arr->is_array()) {
      errors.push_back({path + ".pegs", "expected array"});
      return P;
    }
    for (std::size_t i = 0; i < arr->items().size(); ++i) {
      const Value& po = arr->items()[i];
      const std::string pp = path + ".pegs[" + std::to_string(i) + "]";
      if (!po.is_object()) {
        errors.push_back({pp, "expected object"});
        continue;
      }
      Peg k;
      q(po, "target_q16", k.target, pp);
      q(po, "order_q16", k.order, pp);
      q(po, "band_lo_q16", k.band_lo, pp);
      P->pegs.push_back(k);
    }
    return P;
  }

  std::string_view event_name(std::uint16_t sub) const override {
    return sub == SUB_CREAK ? std::string_view("wood.creak") : std::string_view();
  }

 private:
  static q16 q_ratio_safe(std::int32_t a, std::int32_t b) { return b > 0 ? q16_ratio(q_min(a, b), b) : 0; }

  LockSpec generate_once(std::uint64_t seed, std::uint32_t attempt, const DifficultyVector& d) const {
    Pcg32 rng(derive_seed(seed ^ splitmix64(attempt), FAMILY_ID, RULES_VERSION, "gen"), derive_stream(FAMILY_ID, "gen"));
    auto P = std::make_shared<Params>();
    const int n = rng.range(d.n_min, d.n_max);
    P->win_shear = d.win_shear;
    P->overset_enabled = d.overset_margin > 0;
    P->overset_margin = d.overset_margin;
    P->tension_band = d.tension_band;
    P->t_hold = T_HOLD;
    P->t_release = T_RELEASE;
    P->drop_grace_steps = ms_to_steps(d.drop_grace_ms);
    P->open_hold_steps = ms_to_steps(OPEN_HOLD_MS);
    P->bound_speed = BOUND_SPEED;
    P->pegs.resize(static_cast<std::size_t>(n));
    std::vector<int> perm(static_cast<std::size_t>(n));
    for (int i = 0; i < n; ++i) perm[static_cast<std::size_t>(i)] = i;
    for (int i = n - 1; i > 0; --i) std::swap(perm[static_cast<std::size_t>(i)], perm[rng.below(static_cast<std::uint32_t>(i + 1))]);
    const q16 unit = q_max(1, q_mul(d.bind_spread, q16_milli(100)));
    q16 max_stick = 0;
    for (int r = 0; r < n; ++r) {
      Peg& k = P->pegs[static_cast<std::size_t>(perm[static_cast<std::size_t>(r)])];
      k.order = unit * r;
      k.band_lo = T_BIND_BASE + rng.range(0, T_BIND_JITTER);
    }
    for (Peg& k : P->pegs) {
      k.target = rng.range(q16_milli(400), q16_milli(650));
      max_stick = q_max(max_stick, k.band_lo + P->tension_band);
    }
    P->tau_creak = q_min(Q16_ONE, max_stick + CREAK_MARGIN);

    LockSpec spec;
    spec.family = std::string(FAMILY_ID);
    spec.rules_version = RULES_VERSION;
    spec.id = "gen.wooden_pin.t" + std::to_string(d.tier) + "." + std::to_string(seed);
    spec.source = "generated";
    spec.seed = seed;
    spec.difficulty = d;
    spec.material = MaterialId::wood;
    spec.params = P;
    return spec;
  }
};

}  // namespace

std::unique_ptr<FamilyModule> make_module() { return std::make_unique<Module>(); }

}  // namespace lockcore::wooden
