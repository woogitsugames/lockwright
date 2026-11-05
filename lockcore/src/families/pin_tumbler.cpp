// Pin tumbler (LOCKS.md §2.6).
//
// Model per stack (positions are Q16 fractions of the key-pin travel):
//  - free:      the key pin follows the pick tip and springs back when released;
//  - bound:     the unset stack with the lowest binding offset binds once
//               T >= band_lo; it rises toward the pick only while T <= t_stick
//               (friction), and pressing it while T > tau_safe loads the tool;
//  - near:      bound and within 1.5 windows below the shear window;
//  - set:       reached the window bottom; holds while T >= t_hold. Pushing the key
//               pin above window top + overset_margin oversets it;
//  - false_set: a spool caught at its false gate; only lifts while T is inside the
//               counter-rotation band [cr_lo, cr_hi] (emits counter_rotate);
//  - overset:   jams the core until T < t_release.
#include "lockcore/pin_tumbler.hpp"

#include <algorithm>

#include "lockcore/bot.hpp"
#include "lockcore/hash.hpp"
#include "lockcore/lockfile.hpp"

namespace lockcore::pin {

namespace {

using json::Value;

constexpr q16 PRESS_CAP = q16_milli(500);
constexpr q16 SET_INTENSITY = q16_milli(900);
constexpr q16 FALSE_SET_INTENSITY = q16_milli(600);
constexpr q16 SERRATION_INTENSITY = q16_milli(300);
constexpr std::int32_t COUNTER_ROTATE_PERIOD = 6;

struct StackState {
  ElementState st = ElementState::free;
  q16 p = 0;
  int serr_idx = 0;
  bool near = false;
  std::int64_t cr_last = -1000;
};

struct State : FamilyState {
  std::shared_ptr<const Params> params;
  MaterialId material = MaterialId::brass;
  std::vector<StackState> stacks;
  std::vector<int> set_order;
  int pick = -1;
  q16 lift = 0;
  q16 tension = 0;
  q16 resistance = 0;
  q16 drag = 0;
};

const Params& params_of(const LockSpec& spec) { return static_cast<const Params&>(*spec.params); }

void to_free(StackState& s) {
  s.st = ElementState::free;
  s.serr_idx = 0;
  s.near = false;
}

class Module final : public FamilyModule {
 public:
  std::string_view id() const override { return FAMILY_ID; }
  std::int32_t rules_version() const override { return RULES_VERSION; }
  std::uint32_t input_mask() const override { return AXIS_TENSION | AXIS_DEPTH | AXIS_LIFT; }
  ToolSet required_tools(const LockSpec&) const override { return ToolSet{TOOL_TENSION_WRENCH | TOOL_HOOK}; }

  int min_tier() const override { return 2; }
  int max_tier() const override { return 7; }

  DifficultyVector difficulty_for_tier(int tier) const override {
    // LOCKS.md §2.6 generator table, t2..t7.
    struct Row {
      int n_min, n_max, win, band, margin, spread, mbp, sec_min, sec_max, noise, grace, limit;
    };
    static constexpr Row rows[] = {
        {3, 3, 120, 280, 100, 1000, 0, 0, 0, 0, 300, 60},        // t2
        {4, 4, 110, 240, 90, 800, 0, 0, 0, 50, 250, 120},        // t3
        {5, 5, 100, 200, 80, 600, 50, 1, 1, 80, 200, 120},       // t4
        {5, 6, 90, 180, 70, 500, 100, 1, 2, 100, 200, 120},      // t5 (n 5-6, D-34)
        {6, 6, 80, 150, 60, 400, 150, 2, 3, 120, 170, 150},      // t6
        {6, 7, 70, 120, 55, 300, 200, 3, 4, 150, 150, 150},      // t7 (overset 5.5 %, D-34)
    };
    const int t = std::clamp(tier, 2, 7);
    const Row& r = rows[t - 2];
    DifficultyVector d;
    d.tier = t;
    d.n_min = r.n_min;
    d.n_max = r.n_max;
    d.win_shear = q16_milli(r.win);
    d.tension_band = q16_milli(r.band);
    d.overset_margin = q16_milli(r.margin);
    d.bind_spread = q16_milli(r.spread);
    d.multi_bind_p = q16_milli(r.mbp);
    d.sec_min = r.sec_min;
    d.sec_max = r.sec_max;
    d.noise = q16_milli(r.noise);
    d.drop_grace_ms = r.grace;
    d.s_max = Q16_ONE;
    d.time_limit_s = r.limit;
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
    if (spec.family != FAMILY_ID) e.push_back({"family", "not pin_tumbler"});
    if (!spec.params) {
      e.push_back({"spec", "missing parameters"});
      return e;
    }
    const auto* pp = dynamic_cast<const Params*>(spec.params.get());
    if (pp == nullptr) {
      e.push_back({"spec", "parameters of another family"});
      return e;
    }
    const Params& P = *pp;
    const int n = static_cast<int>(P.stacks.size());
    if (n < 1 || n > 16) e.push_back({"spec.stacks", "need 1..16 stacks"});
    if (P.win_shear < q16_milli(20) || P.win_shear > q16_milli(400)) e.push_back({"spec.win_shear_q16", "out of range"});
    if (P.overset_margin < 0) e.push_back({"spec.overset_margin_q16", "negative"});
    if (P.tension_band <= 0) e.push_back({"spec.tension_band_q16", "must be > 0"});
    if (!(P.t_release > 0 && P.t_release < P.t_hold)) e.push_back({"spec.t_release_q16", "need 0 < t_release < t_hold"});
    if (P.tau_safe <= P.t_hold || P.tau_safe > Q16_ONE) e.push_back({"spec.tau_safe_q16", "need t_hold < tau_safe <= 1"});
    if (P.drop_grace_steps < 1) e.push_back({"spec.drop_grace_steps", "must be >= 1"});
    if (P.s_max <= 0 || P.stress_gain <= 0) e.push_back({"spec.s_max_q16", "s_max and stress_gain must be > 0"});
    if (P.bound_speed <= 0 || P.spool_speed <= 0) e.push_back({"spec.bound_speed_q16", "speeds must be > 0"});
    if (P.noise < 0 || P.noise > Q16_ONE) e.push_back({"spec.noise_q16", "out of range"});
    bool any_spool = false;
    for (int i = 0; i < n; ++i) {
      const Stack& s = P.stacks[static_cast<std::size_t>(i)];
      const std::string path = "spec.stacks[" + std::to_string(i) + "]";
      if (P.win_lo(s) < q16_milli(100) || P.win_hi(s) + P.overset_margin > q16_milli(980))
        e.push_back({path + ".target_q16", "window outside travel"});
      if (s.band_lo < P.t_hold || P.t_stick(s) > Q16_ONE) e.push_back({path + ".band_lo_q16", "need t_hold <= band_lo, band_lo + band <= 1"});
      if (s.order < 0) e.push_back({path + ".order_q16", "negative"});
      if (s.has_spool()) {
        any_spool = true;
        if (s.false_gate < q16_milli(50) || s.false_gate > P.win_lo(s) - q16_milli(20))
          e.push_back({path + ".false_gate_q16", "must lie below the window"});
      }
      const bool serrated = s.variant == Variant::serrated || s.variant == Variant::spool_serrated;
      if (serrated && s.serrations.empty()) e.push_back({path + ".serrations_q16", "serrated stack needs ledges"});
      if (!serrated && !s.serrations.empty()) e.push_back({path + ".serrations_q16", "only serrated stacks have ledges"});
      for (std::size_t k = 0; k < s.serrations.size(); ++k) {
        if (s.serrations[k] <= 0 || s.serrations[k] >= P.win_lo(s) || (k > 0 && s.serrations[k] <= s.serrations[k - 1]))
          e.push_back({path + ".serrations_q16", "must increase and lie below the window"});
      }
    }
    if (any_spool && !(P.cr_lo >= P.t_hold && P.cr_hi > P.cr_lo)) e.push_back({"spec.cr_lo_q16", "need t_hold <= cr_lo < cr_hi"});
    return e;
  }

  std::unique_ptr<FamilyState> init_state(const LockSpec& spec) const override {
    auto s = std::make_unique<State>();
    s->params = std::static_pointer_cast<const Params>(spec.params);
    s->material = spec.material;
    s->stacks.resize(s->params->stacks.size());
    s->tool.init(s->params->s_max, 0, s->params->stress_gain);
    return s;
  }

  void step(FamilyState& base, const InputFrame& in, StepCtx& ctx) const override {
    State& S = static_cast<State&>(base);
    const Params& P = *S.params;
    EventSink& out = *ctx.events;
    const std::int64_t t = ctx.t_step;
    const int n = static_cast<int>(P.stacks.size());
    const q16 T = in.tension;
    const q16 lift = q_max(0, in.pick_lift);
    const q16 hard = material_hardness(S.material);

    // Pick location and contact.
    const int pick = locate_element(in.pick_depth, n);
    if (pick >= 0 && pick != S.pick) out.emit(t, EventKind::contact, pick, hard, S.material);
    if (P.noise > 0 && pick >= 0 && lift != S.lift && ctx.rng->chance(P.noise / 4)) {
      // Spurious contact (readability axis): a neighbouring stack rubs the pick.
      const int other = std::clamp(pick + (ctx.rng->chance(Q16_ONE / 2) ? 1 : -1), 0, n - 1);
      out.emit(t, EventKind::contact, other, ctx.rng->range(hard / 3, hard), S.material);
    }
    S.pick = pick;
    S.lift = lift;
    S.tension = T;

    // 1. Drop: tension below t_hold for drop_grace steps.
    if (S.hold.update(T, P.t_hold, P.drop_grace_steps)) {
      // Tier 2 drops only the most recent progress (a caught spool, else the last
      // set stack); higher tiers drop everything.
      int caught_now = -1;
      for (int i = 0; i < n; ++i) {
        if (S.stacks[static_cast<std::size_t>(i)].st == ElementState::false_set) caught_now = i;
      }
      const int only = caught_now >= 0 ? caught_now : (S.set_order.empty() ? -1 : S.set_order.back());
      int dropped = 0;
      for (int i = 0; i < n; ++i) {
        StackState& s = S.stacks[static_cast<std::size_t>(i)];
        if (s.st != ElementState::set && s.st != ElementState::false_set) continue;
        if (!P.drop_all && i != only) continue;
        to_free(s);
        ++dropped;
        S.set_order.erase(std::remove(S.set_order.begin(), S.set_order.end(), i), S.set_order.end());
      }
      if (dropped > 0) out.emit(t, EventKind::drop, -1, q16_ratio(dropped, n), S.material);
    }

    // 2. Overset clears only when tension falls below t_release.
    if (T < P.t_release) {
      for (auto& s : S.stacks) {
        if (s.st == ElementState::overset) to_free(s);
      }
    }

    // 3. Binding order.
    bool jammed = false;
    int caught = -1;
    q16 min_o = Q16_ONE * 64;
    for (int i = 0; i < n; ++i) {
      const StackState& s = S.stacks[static_cast<std::size_t>(i)];
      if (s.st == ElementState::overset) jammed = true;
      if (s.st == ElementState::false_set) caught = i;
      if (s.st == ElementState::free || s.st == ElementState::bound)
        min_o = q_min(min_o, P.stacks[static_cast<std::size_t>(i)].order);
    }
    for (int i = 0; i < n; ++i) {
      StackState& s = S.stacks[static_cast<std::size_t>(i)];
      const Stack& k = P.stacks[static_cast<std::size_t>(i)];
      if (s.st != ElementState::free && s.st != ElementState::bound) continue;
      const bool want = !jammed && caught < 0 && k.order == min_o && T >= k.band_lo;
      if (want && s.st == ElementState::free) {
        s.st = ElementState::bound;
        out.emit(t, EventKind::bind, i, T, S.material);
        // A pin already pushed past the shear line when tension arrives is overset.
        if (s.p > P.win_hi(k)) {
          s.st = ElementState::overset;
          out.emit(t, EventKind::overset, i, Q16_ONE, S.material);
          continue;
        }
        s.serr_idx = static_cast<int>(std::count_if(k.serrations.begin(), k.serrations.end(), [&](q16 x) { return x <= s.p; }));
        s.near = s.p >= P.win_lo(k) - (P.win_shear * 3) / 2;
      } else if (!want && s.st == ElementState::bound) {
        to_free(s);
      }
    }

    // 4. Motion.
    q16 drag = 0;
    for (int i = 0; i < n; ++i) {
      StackState& s = S.stacks[static_cast<std::size_t>(i)];
      const Stack& k = P.stacks[static_cast<std::size_t>(i)];
      const q16 li = (i == pick) ? lift : 0;
      const q16 lo = P.win_lo(k);
      switch (s.st) {
        case ElementState::free: {
          const q16 old = s.p;
          s.p = li;
          if (old >= q16_milli(300) && s.p == 0) out.emit(t, EventKind::contact, i, old / 2, S.material, SUB_SPRING_BOUNCE);
          break;
        }
        case ElementState::bound:
        case ElementState::near: {
          if (li > s.p) {
            const q16 press = li - s.p;
            if (T <= P.t_stick(k)) s.p += q_min(press, P.bound_speed);
            if (T > P.tau_safe) S.tool.load(T - P.tau_safe, q_min(press, PRESS_CAP));
            drag = q_max(drag, press);
          }
          while (s.serr_idx < static_cast<int>(k.serrations.size()) &&
                 s.p >= k.serrations[static_cast<std::size_t>(s.serr_idx)]) {
            ++s.serr_idx;
            out.emit(t, EventKind::false_set, i, SERRATION_INTENSITY, S.material, SUB_SERRATION);
          }
          if (k.has_spool() && s.p >= k.false_gate) {
            // Spool caught at its false gate; from here it only rises through the
            // counter-rotation band.
            s.p = k.false_gate;
            s.st = ElementState::false_set;
            s.cr_last = t;
            out.emit(t, EventKind::false_set, i, FALSE_SET_INTENSITY, S.material);
            break;
          }
          if (s.p >= lo) {
            s.st = ElementState::set;
            s.near = false;
            S.set_order.push_back(i);
            out.emit(t, EventKind::set, i, SET_INTENSITY, S.material);
          } else if (!s.near && s.p >= lo - (P.win_shear * 3) / 2) {
            s.near = true;
            const q16 zone = (P.win_shear * 3) / 2;
            out.emit(t, EventKind::near_shear, i, q_div(s.p - (lo - zone), zone), S.material);
          }
          break;
        }
        case ElementState::false_set: {
          if (li > s.p) {
            const q16 press = li - s.p;
            if (t - s.cr_last >= COUNTER_ROTATE_PERIOD) {
              s.cr_last = t;
              out.emit(t, EventKind::counter_rotate, i, q_min(Q16_ONE, press * 4), S.material);
            }
            if (T >= P.cr_lo && T <= P.cr_hi) {
              s.p += q_min(press, P.spool_speed);
            } else if (T > P.cr_hi) {
              S.tool.load(T - P.cr_hi, q_min(press, PRESS_CAP));
            }
            drag = q_max(drag, press);
          }
          while (s.serr_idx < static_cast<int>(k.serrations.size()) &&
                 s.p >= k.serrations[static_cast<std::size_t>(s.serr_idx)]) {
            ++s.serr_idx;
            out.emit(t, EventKind::false_set, i, SERRATION_INTENSITY, S.material, SUB_SERRATION);
          }
          if (s.p >= lo) {
            s.st = ElementState::set;
            S.set_order.push_back(i);
            out.emit(t, EventKind::set, i, SET_INTENSITY, S.material);
          }
          break;
        }
        case ElementState::set:
          // The driver pin rests on the core; the key pin follows the pick.
          s.p = li;
          if (T >= P.t_hold && s.p > P.win_hi(k) + P.overset_margin) {
            s.st = ElementState::overset;
            S.set_order.erase(std::remove(S.set_order.begin(), S.set_order.end(), i), S.set_order.end());
            out.emit(t, EventKind::overset, i, Q16_ONE, S.material);
          }
          break;
        case ElementState::overset:
          s.p = q_max(P.win_hi(k) + P.overset_margin, li);
          break;
        case ElementState::jammed: break;
      }
    }

    // 5. Open.
    if (!S.open && T >= P.t_hold &&
        std::all_of(S.stacks.begin(), S.stacks.end(), [](const StackState& s) { return s.st == ElementState::set; })) {
      S.open = true;
      out.emit(t, EventKind::open, -1, Q16_ONE, S.material);
    }

    // 6. Tool stress (steel pick).
    S.tool.end_step(t, out, pick, MaterialId::steel);
    if (S.tool.broken()) S.failure = FailureKind::break_;

    // 7. Continuous signals.
    bool any_bound = false;
    for (const auto& s : S.stacks) any_bound = any_bound || s.st == ElementState::bound;
    q16 res = T / 4;
    if (jammed) res = T;
    else if (caught >= 0) res = q_min(Q16_ONE, T + drag / 2);
    else if (any_bound) res = q_mul(T, q16_milli(750));
    S.resistance = res;
    S.drag = drag;
    ctx.tension_resistance = res;
    ctx.pick_drag = drag;
  }

  ViewModel describe(const FamilyState& base) const override {
    const State& S = static_cast<const State&>(base);
    const Params& P = *S.params;
    ViewModel v;
    int sets = 0;
    bool caught = false;
    for (std::size_t i = 0; i < S.stacks.size(); ++i) {
      const StackState& s = S.stacks[i];
      ElementView e;
      e.state = (s.st == ElementState::bound && s.near) ? ElementState::near : s.st;
      e.position = s.p;
      e.window_lo = P.win_lo(P.stacks[i]);
      e.window_hi = P.win_hi(P.stacks[i]);
      e.variant = static_cast<std::uint8_t>(P.stacks[i].variant);
      v.elements.push_back(e);
      sets += s.st == ElementState::set ? 1 : 0;
      caught = caught || s.st == ElementState::false_set;
    }
    v.pick_element = S.pick;
    v.pick_lift = S.lift;
    v.tension = S.tension;
    // Micro-rotation per set stack, a larger one for a false set (LOCKS.md §2.6).
    v.core_rotation = S.open ? Q16_ONE : q16_milli(20) * sets + (caught ? q16_milli(80) : 0);
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
    const int n = static_cast<int>(P.stacks.size());
    std::vector<int> order(static_cast<std::size_t>(n));
    for (int i = 0; i < n; ++i) order[static_cast<std::size_t>(i)] = i;
    std::stable_sort(order.begin(), order.end(), [&](int a, int b) {
      return P.stacks[static_cast<std::size_t>(a)].order < P.stacks[static_cast<std::size_t>(b)].order;
    });
    // At most two stacks may share a binding offset (multi-bind pair).
    for (int i = 2; i < n; ++i) {
      if (P.stacks[static_cast<std::size_t>(order[static_cast<std::size_t>(i)])].order ==
          P.stacks[static_cast<std::size_t>(order[static_cast<std::size_t>(i - 2)])].order) {
        r.reason = "more than two stacks bind together";
        return r;
      }
    }
    if (P.win_shear * 2 < HUMAN_POSITION_PRECISION * 3) {
      r.reason = "position window below 1.5x human precision";
      return r;
    }
    if (P.win_shear + P.overset_margin < HUMAN_POSITION_PRECISION * 3) {
      r.reason = "set-to-overset headroom below 3x human precision";
      return r;
    }
    r.min_band = Q16_ONE;
    r.min_window = P.win_shear;
    for (int idx : order) {
      const Stack& k = P.stacks[static_cast<std::size_t>(idx)];
      const q16 lo = q_max(P.t_hold, k.band_lo);
      const q16 hi = q_min(P.t_stick(k), P.tau_safe);
      if (hi - lo < HUMAN_TENSION_BAND) {
        r.reason = "tension band of stack " + std::to_string(idx) + " narrower than delta_human";
        return r;
      }
      r.min_band = q_min(r.min_band, hi - lo);
      PlanStep st;
      st.element = idx;
      st.depth = element_center(idx, n);
      st.tension = (lo + hi) / 2;
      const q16 zone = (P.win_shear * 3) / 2;
      const q16 first_feel = k.has_spool() ? k.false_gate : P.win_lo(k) - zone;
      st.approach_from = q_max(0, first_feel - q16_milli(60));
      st.lift_cap = P.win_hi(k) + P.overset_margin / 2;
      if (k.has_spool()) {
        const q16 clo = q_max(P.cr_lo, P.t_hold);
        if (P.cr_hi - clo < HUMAN_TENSION_BAND) {
          r.reason = "counter-rotation band narrower than delta_human";
          return r;
        }
        r.min_band = q_min(r.min_band, P.cr_hi - clo);
        st.has_false_gate = true;
        st.cr_tension = (clo + P.cr_hi) / 2;
      }
      r.plan.steps.push_back(st);
    }
    r.plan.release_tension = 0;
    r.plan.t_hold = P.t_hold;
    r.plan.drop_all = P.drop_all;
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
    o.set("cr_lo_q16", Value::integer(P.cr_lo));
    o.set("cr_hi_q16", Value::integer(P.cr_hi));
    o.set("drop_grace_steps", Value::integer(P.drop_grace_steps));
    o.set("drop_all", Value::boolean(P.drop_all));
    o.set("s_max_q16", Value::integer(P.s_max));
    o.set("stress_gain_q16", Value::integer(P.stress_gain));
    o.set("noise_q16", Value::integer(P.noise));
    o.set("bound_speed_q16", Value::integer(P.bound_speed));
    o.set("spool_speed_q16", Value::integer(P.spool_speed));
    Value arr = Value::array();
    for (const Stack& s : P.stacks) {
      Value so = Value::object();
      so.set("target_q16", Value::integer(s.target));
      so.set("order_q16", Value::integer(s.order));
      so.set("band_lo_q16", Value::integer(s.band_lo));
      so.set("variant", Value::string(std::string(variant_name(s.variant))));
      if (s.has_spool()) so.set("false_gate_q16", Value::integer(s.false_gate));
      if (!s.serrations.empty()) {
        Value ser = Value::array();
        for (q16 x : s.serrations) ser.push(Value::integer(x));
        so.set("serrations_q16", std::move(ser));
      }
      arr.push(std::move(so));
    }
    o.set("stacks", std::move(arr));
    return o;
  }

  std::shared_ptr<const FamilyParams> params_from_json(const Value& v, std::vector<SpecError>& errors) const override {
    auto P = std::make_shared<Params>();
    const std::string path = ".spec";
    std::int64_t x = 0;
    auto q = [&](std::string_view key, q16& out) {
      if (field::get_int(v, key, 0, 64 * static_cast<std::int64_t>(Q16_ONE), x, errors, path)) out = static_cast<q16>(x);
    };
    q("win_shear_q16", P->win_shear);
    q("overset_margin_q16", P->overset_margin);
    q("tension_band_q16", P->tension_band);
    q("t_hold_q16", P->t_hold);
    q("t_release_q16", P->t_release);
    q("tau_safe_q16", P->tau_safe);
    q("cr_lo_q16", P->cr_lo);
    q("cr_hi_q16", P->cr_hi);
    if (field::get_int(v, "drop_grace_steps", 1, 100000, x, errors, path)) P->drop_grace_steps = static_cast<std::int32_t>(x);
    field::get_bool(v, "drop_all", P->drop_all, errors, path);
    q("s_max_q16", P->s_max);
    q("stress_gain_q16", P->stress_gain);
    q("noise_q16", P->noise);
    q("bound_speed_q16", P->bound_speed);
    q("spool_speed_q16", P->spool_speed);
    const Value* stacks = v.find("stacks");
    if (stacks == nullptr || !stacks->is_array()) {
      errors.push_back({path + ".stacks", "expected array"});
      return P;
    }
    for (std::size_t i = 0; i < stacks->items().size(); ++i) {
      const Value& so = stacks->items()[i];
      const std::string sp = path + ".stacks[" + std::to_string(i) + "]";
      Stack s;
      if (!so.is_object()) {
        errors.push_back({sp, "expected object"});
        continue;
      }
      if (field::get_int(so, "target_q16", 0, Q16_ONE, x, errors, sp)) s.target = static_cast<q16>(x);
      if (field::get_int(so, "order_q16", 0, 64 * static_cast<std::int64_t>(Q16_ONE), x, errors, sp)) s.order = static_cast<q16>(x);
      if (field::get_int(so, "band_lo_q16", 0, Q16_ONE, x, errors, sp)) s.band_lo = static_cast<q16>(x);
      const Value* var = so.find("variant");
      bool known = false;
      if (var != nullptr && var->is_string()) {
        for (Variant cand : {Variant::standard, Variant::spool, Variant::serrated, Variant::spool_serrated}) {
          if (variant_name(cand) == var->as_string()) {
            s.variant = cand;
            known = true;
          }
        }
      }
      if (!known) errors.push_back({sp + ".variant", "unknown variant"});
      if (s.has_spool() && field::get_int(so, "false_gate_q16", 0, Q16_ONE, x, errors, sp)) s.false_gate = static_cast<q16>(x);
      if (const Value* ser = so.find("serrations_q16")) {
        if (!ser->is_array()) {
          errors.push_back({sp + ".serrations_q16", "expected array"});
        } else {
          for (const Value& e : ser->items()) {
            if (!e.is_int() || e.as_int() < 0 || e.as_int() > Q16_ONE) {
              errors.push_back({sp + ".serrations_q16", "expected q16 integers"});
              break;
            }
            s.serrations.push_back(static_cast<q16>(e.as_int()));
          }
        }
      }
      P->stacks.push_back(std::move(s));
    }
    return P;
  }

  std::string_view event_name(std::uint16_t sub) const override {
    switch (sub) {
      case SUB_SERRATION: return "pin.serration";
      case SUB_SPRING_BOUNCE: return "pin.spring_bounce";
      default: return {};
    }
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
    P->cr_lo = CR_LO;
    P->cr_hi = CR_HI;
    P->drop_grace_steps = ms_to_steps(d.drop_grace_ms);
    P->drop_all = d.tier >= 3;  // the easiest tier drops only the last set stack
    P->s_max = d.s_max;
    P->stress_gain = STRESS_GAIN;
    P->noise = d.noise;
    P->bound_speed = BOUND_SPEED;
    P->spool_speed = SPOOL_SPEED;
    P->stacks.resize(static_cast<std::size_t>(n));

    // Binding order: random permutation; offsets spaced by bind_spread.
    std::vector<int> perm(static_cast<std::size_t>(n));
    for (int i = 0; i < n; ++i) perm[static_cast<std::size_t>(i)] = i;
    for (int i = n - 1; i > 0; --i) std::swap(perm[static_cast<std::size_t>(i)], perm[rng.below(static_cast<std::uint32_t>(i + 1))]);
    const q16 unit = q_max(1, q_mul(d.bind_spread, q16_milli(100)));
    q16 o = 0;
    bool prev_paired = false;
    q16 prev_band_lo = 0;
    for (int r = 0; r < n; ++r) {
      Stack& s = P->stacks[static_cast<std::size_t>(perm[static_cast<std::size_t>(r)])];
      const bool pair = r > 0 && !prev_paired && rng.chance(d.multi_bind_p);
      if (!pair && r > 0) o += unit;
      s.order = o;
      s.band_lo = pair ? prev_band_lo : T_BIND_BASE + rng.range(0, T_BIND_JITTER);
      prev_band_lo = s.band_lo;
      prev_paired = pair;
    }
    q16 max_stick = 0;
    for (Stack& s : P->stacks) {
      s.target = rng.range(q16_milli(420), q16_milli(700));
      max_stick = q_max(max_stick, s.band_lo + P->tension_band);
    }
    P->tau_safe = max_stick + TAU_SAFE_MARGIN;

    // Security pins.
    const int sec = std::min(rng.range(d.sec_min, d.sec_max), n);
    std::vector<int> pool = perm;
    for (int i = n - 1; i > 0; --i) std::swap(pool[static_cast<std::size_t>(i)], pool[rng.below(static_cast<std::uint32_t>(i + 1))]);
    for (int j = 0; j < sec; ++j) {
      Stack& s = P->stacks[static_cast<std::size_t>(pool[static_cast<std::size_t>(j)])];
      const int kinds = d.tier >= 7 ? 3 : 2;
      const int pickv = rng.range(0, kinds - 1);
      s.variant = pickv == 0 ? Variant::spool : (pickv == 1 ? Variant::serrated : Variant::spool_serrated);
      const q16 lo = P->win_lo(s);
      if (s.has_spool()) s.false_gate = lo - rng.range(q16_milli(100), q16_milli(140));
      if (s.variant == Variant::serrated || s.variant == Variant::spool_serrated) {
        const int ledges = rng.range(2, 4);
        const q16 from = lo - q16_milli(240);
        const q16 span = q16_milli(210);
        for (int m = 0; m < ledges; ++m) {
          s.serrations.push_back(from + (span * (m + 1)) / (ledges + 1) + rng.range(-q16_milli(10), q16_milli(10)));
        }
      }
    }

    LockSpec spec;
    spec.family = std::string(FAMILY_ID);
    spec.rules_version = RULES_VERSION;
    spec.id = "gen.pin_tumbler.t" + std::to_string(d.tier) + "." + std::to_string(seed);
    spec.source = "generated";
    spec.seed = seed;
    spec.difficulty = d;
    spec.material = MaterialId::brass;
    spec.params = P;
    return spec;
  }
};

}  // namespace

std::string_view variant_name(Variant v) {
  switch (v) {
    case Variant::standard: return "standard";
    case Variant::spool: return "spool";
    case Variant::serrated: return "serrated";
    case Variant::spool_serrated: return "spool_serrated";
  }
  return "standard";
}

std::unique_ptr<FamilyModule> make_module() { return std::make_unique<Module>(); }

}  // namespace lockcore::pin
