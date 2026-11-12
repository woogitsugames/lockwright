// Lever lock (LOCKS.md §2.7) and detector lever lock (§2.8).
//
// Per lever (positions are fractions of the lever travel):
//  - free:      follows the lifter, the spring drops it when released;
//  - bound:     the unset lever with the lowest binding offset binds once
//               T >= band_lo (the bolt stump presses its front edge); it rises only
//               while T <= t_stick and falls back at spring speed when the lifter
//               drops; pressing it while T > tau_safe loads the crank;
//  - false_set: caught in a false notch below the gate ("lever.false_gate"); it
//               rises only with T in [cr_lo, cr_hi] (counter_rotate while pushed),
//               above that the crank is loaded; below t_hold it drops;
//  - set:       the gate reached the stump (gate_align + set); lifting it above the
//               gate by overset_margin oversets it, which jams the bolt until
//               T < t_release (costs a drop);
//  - detector:  any lever above gate top + detector_margin trips the detector:
//               every lever is jammed until the bolt is turned back (T < t_hold and
//               rotate <= -1/2 for reset_steps; "detector.reset", wear). The third
//               trip blocks the lock (failure detector_trip).
//
// axial_slider (v0.6, D-59, LOCKS.md §2.23): the same module with slider_ set
// (no detector). Sliders round the key axis are pressed in (pick_lift > 0) to the
// notch that clears the locking plate; spring return, binding order, false notches
// from t2 ("slider.false_notch", counter-rotation band), overset. Tiers 1-3,
// rules 1, own ids / seeds, slider pusher tool. lever / lever_detector unchanged.
#include "lockcore/lever.hpp"

#include <algorithm>

#include "lockcore/bot.hpp"
#include "lockcore/hash.hpp"
#include "lockcore/lockfile.hpp"

namespace lockcore::lever {

namespace {

using json::Value;

constexpr q16 PRESS_CAP = q16_milli(500);
constexpr q16 SET_INTENSITY = q16_milli(950);
constexpr q16 FALSE_SET_INTENSITY = q16_milli(650);
constexpr q16 FALSE_KNOCK_INTENSITY = q16_milli(450);
constexpr std::int32_t COUNTER_ROTATE_PERIOD = 6;

struct LeverState {
  ElementState st = ElementState::free;
  q16 p = 0;
  int fg_idx = 0;  // next false gate that can catch the lever
  bool near = false;
  std::int64_t cr_last = -1000;
};

struct State : FamilyState {
  std::shared_ptr<const Params> params;
  MaterialId material = MaterialId::brass;
  std::vector<LeverState> levers;
  int pick = -1;
  q16 lift = 0;
  q16 tension = 0;
  q16 resistance = 0;
  q16 drag = 0;
  bool tripped = false;
  std::int32_t trips = 0;
  std::int32_t reset_count = 0;
};

const Params& params_of(const LockSpec& spec) { return static_cast<const Params&>(*spec.params); }

void to_free(LeverState& s) {
  s.st = ElementState::free;
  s.fg_idx = 0;
  s.near = false;
}

class Module final : public FamilyModule {
 public:
  explicit Module(bool detector, bool slider = false) : detector_(detector), slider_(slider) {}

  std::string_view id() const override { return slider_ ? SLIDER_FAMILY_ID : (detector_ ? DETECTOR_FAMILY_ID : FAMILY_ID); }
  std::int32_t rules_version() const override { return slider_ ? SLIDER_RULES_VERSION : RULES_VERSION; }
  std::uint32_t input_mask() const override {
    return AXIS_TENSION | AXIS_DEPTH | AXIS_LIFT | (detector_ ? AXIS_ROTATE : 0u);
  }
  ToolSet required_tools(const LockSpec&) const override { return ToolSet{slider_ ? TOOL_SLIDER_PUSHER : TOOL_LEVER_CRANK}; }

  int min_tier() const override { return slider_ ? 1 : (detector_ ? 5 : 3); }
  int max_tier() const override { return slider_ ? 3 : (detector_ ? 6 : 5); }

  DifficultyVector difficulty_for_tier(int tier) const override {
    // LOCKS.md §2.7 (t3->t5) and §2.8 (t5->t6). sec = false gates per lever.
    struct Row {
      int tier, n, win, band, margin, sec_min, sec_max, grace, limit;
    };
    static constexpr Row lever_rows[] = {
        {3, 3, 140, 260, 100, 0, 0, 300, 120},
        {4, 4, 115, 220, 90, 0, 1, 250, 120},
        {5, 5, 90, 180, 80, 1, 2, 200, 150},
    };
    static constexpr Row detector_rows[] = {
        {5, 5, 90, 180, 80, 1, 1, 200, 150},
        {6, 6, 85, 160, 80, 1, 2, 170, 180},  // gate 8.5 % (D-116; was 8 %)
    };
    // axial_slider (new-families.md §6): 4 -> 6 sliders, false notches from t2.
    static constexpr Row slider_rows[] = {
        {1, 4, 140, 280, 120, 0, 0, 300, 90},
        {2, 5, 120, 240, 100, 0, 1, 250, 120},
        {3, 6, 100, 200, 90, 1, 1, 220, 150},
    };
    const Row& r = slider_ ? slider_rows[std::clamp(tier, 1, 3) - 1]
                           : (detector_ ? detector_rows[std::clamp(tier, 5, 6) - 5] : lever_rows[std::clamp(tier, 3, 5) - 3]);
    DifficultyVector d;
    d.tier = r.tier;
    d.n_min = d.n_max = r.n;
    d.sec_min = r.sec_min;
    d.sec_max = r.sec_max;
    d.win_shear = q16_milli(r.win);
    d.tension_band = q16_milli(r.band);
    d.overset_margin = q16_milli(r.margin);
    d.bind_spread = Q16_ONE;
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
    if (spec.family != id()) e.push_back({"family", "not " + std::string(id())});
    const auto* pp = dynamic_cast<const Params*>(spec.params.get());
    if (pp == nullptr) {
      e.push_back({"spec", "missing or foreign parameters"});
      return e;
    }
    const Params& P = *pp;
    const int n = static_cast<int>(P.levers.size());
    if (P.detector != detector_) e.push_back({"spec.detector", detector_ ? "lever_detector needs detector" : "lever has no detector"});
    if (n < 1 || n > 12) e.push_back({"spec.levers", "need 1..12 levers"});
    if (P.win_gate < q16_milli(20) || P.win_gate > q16_milli(400)) e.push_back({"spec.win_gate_q16", "out of range"});
    if (P.overset_margin < 0) e.push_back({"spec.overset_margin_q16", "negative"});
    if (P.tension_band <= 0) e.push_back({"spec.tension_band_q16", "must be > 0"});
    if (!(P.t_release > 0 && P.t_release < P.t_hold)) e.push_back({"spec.t_release_q16", "need 0 < t_release < t_hold"});
    if (P.tau_safe <= P.t_hold || P.tau_safe > Q16_ONE) e.push_back({"spec.tau_safe_q16", "need t_hold < tau_safe <= 1"});
    if (P.drop_grace_steps < 1) e.push_back({"spec.drop_grace_steps", "must be >= 1"});
    if (P.s_max <= 0 || P.stress_gain <= 0) e.push_back({"spec.s_max_q16", "s_max and stress_gain must be > 0"});
    if (P.bound_speed <= 0 || P.false_speed <= 0 || P.spring_speed <= 0) e.push_back({"spec.bound_speed_q16", "speeds must be > 0"});
    if (P.set_speed < 0) e.push_back({"spec.set_speed_q16", "negative"});
    if (P.detector) {
      if (P.detector_margin <= 0) e.push_back({"spec.detector_margin_q16", "must be > 0"});
      if (P.reset_steps < 1 || P.reset_steps > 1200) e.push_back({"spec.reset_steps", "need 1..1200"});
      if (P.max_trips < 1 || P.max_trips > 10) e.push_back({"spec.max_trips", "need 1..10"});
      if (P.reset_wear < 0 || P.reset_wear > 100) e.push_back({"spec.reset_wear", "need 0..100"});
    }
    bool any_false = false;
    for (int i = 0; i < n; ++i) {
      const Lever& l = P.levers[static_cast<std::size_t>(i)];
      const std::string path = "spec.levers[" + std::to_string(i) + "]";
      q16 top = P.win_hi(l) + P.overset_margin;
      if (P.detector) top = q_max(top, P.detector_h(l));
      if (P.win_lo(l) < q16_milli(100) || top > q16_milli(980)) e.push_back({path + ".target_q16", "gate outside travel"});
      if (l.band_lo < P.t_hold || P.t_stick(l) > Q16_ONE) e.push_back({path + ".band_lo_q16", "need t_hold <= band_lo, band_lo + band <= 1"});
      if (l.order < 0) e.push_back({path + ".order_q16", "negative"});
      if (l.false_gates.size() > 3) e.push_back({path + ".false_gates_q16", "at most 3"});
      for (std::size_t k = 0; k < l.false_gates.size(); ++k) {
        any_false = true;
        const q16 g = l.false_gates[k];
        if (g < q16_milli(50) || g > P.win_lo(l) - q16_milli(20) || (k > 0 && g <= l.false_gates[k - 1]))
          e.push_back({path + ".false_gates_q16", "must increase and lie below the gate"});
      }
    }
    if (any_false && !(P.cr_lo >= P.t_hold && P.cr_hi > P.cr_lo)) e.push_back({"spec.cr_lo_q16", "need t_hold <= cr_lo < cr_hi"});
    return e;
  }

  std::unique_ptr<FamilyState> init_state(const LockSpec& spec) const override {
    auto s = std::make_unique<State>();
    s->params = std::static_pointer_cast<const Params>(spec.params);
    s->material = spec.material;
    s->levers.resize(s->params->levers.size());
    s->tool.init(s->params->s_max, 0, s->params->stress_gain);
    return s;
  }

  void step(FamilyState& base, const InputFrame& in, StepCtx& ctx) const override {
    State& S = static_cast<State&>(base);
    const Params& P = *S.params;
    EventSink& out = *ctx.events;
    const std::int64_t t = ctx.t_step;
    const int n = static_cast<int>(P.levers.size());
    const q16 T = in.tension;
    const q16 lift = q_max(0, in.pick_lift);

    const int pick = locate_element(in.pick_depth, n);
    if (pick >= 0 && pick != S.pick) out.emit(t, EventKind::contact, pick, material_hardness(S.material), S.material);
    S.pick = pick;
    S.lift = lift;
    S.tension = T;

    if (S.tripped) {
      // Detector engaged: the bolt is dead until it is turned back.
      if (S.failure == FailureKind::none && T < P.t_hold && in.rotate <= -Q16_ONE / 2) {
        if (++S.reset_count >= P.reset_steps) {
          S.tripped = false;
          S.reset_count = 0;
          for (auto& l : S.levers) {
            to_free(l);
            l.p = 0;
          }
          S.hold.reset();
          S.tool.add_wear(P.reset_wear);  // keeps stress history (T25-15)
          out.emit(t, EventKind::drop, -1, Q16_ONE, S.material, SUB_DETECTOR_RESET);
        }
      } else {
        S.reset_count = 0;
      }
      S.resistance = T;
      S.drag = lift;
      ctx.tension_resistance = T;
      ctx.pick_drag = lift;
      S.tool.end_step(t, out, pick, MaterialId::steel);
      return;
    }

    // 1. Drop: every set or caught lever falls.
    if (S.hold.update(T, P.t_hold, P.drop_grace_steps)) {
      int dropped = 0;
      for (auto& l : S.levers) {
        if (l.st != ElementState::set && l.st != ElementState::false_set) continue;
        to_free(l);
        ++dropped;
      }
      if (dropped > 0) out.emit(t, EventKind::drop, -1, q16_ratio(dropped, n), S.material);
    }
    // 2. Overset clears below t_release.
    if (T < P.t_release) {
      for (auto& l : S.levers) {
        if (l.st == ElementState::overset) to_free(l);
      }
    }

    // 3. Binding order.
    bool jammed = false;
    int caught = -1;
    q16 min_o = Q16_ONE * 64;
    for (int i = 0; i < n; ++i) {
      const LeverState& l = S.levers[static_cast<std::size_t>(i)];
      if (l.st == ElementState::overset) jammed = true;
      if (l.st == ElementState::false_set) caught = i;
      if (l.st == ElementState::free || l.st == ElementState::bound) min_o = q_min(min_o, P.levers[static_cast<std::size_t>(i)].order);
    }
    for (int i = 0; i < n; ++i) {
      LeverState& l = S.levers[static_cast<std::size_t>(i)];
      const Lever& k = P.levers[static_cast<std::size_t>(i)];
      if (l.st != ElementState::free && l.st != ElementState::bound) continue;
      const bool want = !jammed && caught < 0 && k.order == min_o && T >= k.band_lo;
      if (want && l.st == ElementState::free) {
        l.st = ElementState::bound;
        out.emit(t, EventKind::bind, i, T, S.material);
        if (l.p > P.win_hi(k)) {
          l.st = ElementState::overset;
          out.emit(t, EventKind::overset, i, Q16_ONE, S.material);
          continue;
        }
        l.fg_idx = static_cast<int>(std::count_if(k.false_gates.begin(), k.false_gates.end(), [&](q16 g) { return g < l.p; }));
        l.near = l.p >= P.win_lo(k) - (P.win_gate * 3) / 2;
      } else if (!want && l.st == ElementState::bound) {
        to_free(l);
      }
    }

    // 4. Motion.
    q16 drag = 0;
    for (int i = 0; i < n; ++i) {
      LeverState& l = S.levers[static_cast<std::size_t>(i)];
      const Lever& k = P.levers[static_cast<std::size_t>(i)];
      const q16 li = (i == pick) ? lift : 0;
      const q16 lo = P.win_lo(k);
      const int n_fg = static_cast<int>(k.false_gates.size());
      auto catch_false = [&]() {
        if (l.fg_idx < n_fg && l.p >= k.false_gates[static_cast<std::size_t>(l.fg_idx)]) {
          l.p = k.false_gates[static_cast<std::size_t>(l.fg_idx)];
          ++l.fg_idx;
          l.st = ElementState::false_set;
          l.near = false;
          l.cr_last = t;
          out.emit(t, EventKind::false_set, i, FALSE_SET_INTENSITY, S.material);
          out.emit(t, EventKind::false_set, i, FALSE_KNOCK_INTENSITY, S.material, SUB_FALSE_GATE);
          return true;
        }
        return false;
      };
      auto gate = [&]() {
        if (l.p >= lo) {
          l.st = ElementState::set;
          l.near = false;
          out.emit(t, EventKind::gate_align, i, Q16_ONE, S.material);
          out.emit(t, EventKind::set, i, SET_INTENSITY, S.material);
        }
      };
      switch (l.st) {
        case ElementState::free: l.p = li; break;
        case ElementState::bound: {
          if (li > l.p) {
            const q16 press = li - l.p;
            if (T <= P.t_stick(k)) l.p += q_min(press, P.bound_speed);
            if (T > P.tau_safe) S.tool.load(T - P.tau_safe, q_min(press, PRESS_CAP));
            drag = q_max(drag, press);
          } else if (li < l.p) {
            l.p = q_max(li, l.p - P.spring_speed);
          }
          if (catch_false()) break;
          gate();
          if (l.st == ElementState::bound) {
            const q16 zone = (P.win_gate * 3) / 2;
            if (!l.near && l.p >= lo - zone) {
              l.near = true;
              out.emit(t, EventKind::near_shear, i, q_div(l.p - (lo - zone), zone), S.material);
            } else if (l.near && l.p < lo - zone) {
              l.near = false;
            }
          }
          break;
        }
        case ElementState::false_set: {
          if (li > l.p) {
            const q16 press = li - l.p;
            if (t - l.cr_last >= COUNTER_ROTATE_PERIOD) {
              l.cr_last = t;
              out.emit(t, EventKind::counter_rotate, i, q_min(Q16_ONE, press * 4), S.material);
            }
            if (T >= P.cr_lo && T <= P.cr_hi) l.p += q_min(press, P.false_speed);
            else if (T > P.cr_hi) S.tool.load(T - P.cr_hi, q_min(press, PRESS_CAP));
            drag = q_max(drag, press);
          }
          if (catch_false()) break;
          gate();
          break;
        }
        case ElementState::set: {
          // The stump sits in the gate; the lifter can still raise the lever, but
          // (rules 2) only at set_speed, so a lifter that ran ahead of a caught
          // lever does not throw it over the gate in one step.
          const q16 want = q_max(lo, li);
          l.p = (P.set_speed > 0 && want > l.p) ? q_min(want, l.p + P.set_speed) : want;
          if (T >= P.t_hold && l.p > P.win_hi(k) + P.overset_margin) {
            l.st = ElementState::overset;
            out.emit(t, EventKind::overset, i, Q16_ONE, S.material);
          }
          break;
        }
        case ElementState::overset: l.p = q_max(P.win_hi(k) + P.overset_margin, li); break;
        default: break;
      }
    }

    // 5. Detector.
    if (P.detector) {
      for (int i = 0; i < n && !S.tripped; ++i) {
        if (S.levers[static_cast<std::size_t>(i)].p <= P.detector_h(P.levers[static_cast<std::size_t>(i)])) continue;
        S.tripped = true;
        S.reset_count = 0;
        ++S.trips;
        for (auto& l : S.levers) l.st = ElementState::jammed;
        out.emit(t, EventKind::detector_trip, i, Q16_ONE, S.material);
        if (S.trips >= P.max_trips) S.failure = FailureKind::detector_trip;
      }
    }

    // 6. Open: the bolt retracts.
    if (!S.tripped && !S.open && T >= P.t_hold &&
        std::all_of(S.levers.begin(), S.levers.end(), [](const LeverState& l) { return l.st == ElementState::set; })) {
      S.open = true;
      out.emit(t, EventKind::open, -1, Q16_ONE, S.material);
    }

    S.tool.end_step(t, out, pick, MaterialId::steel, !S.open);  // open wins over break (T25-16)
    if (S.tool.broken()) S.failure = FailureKind::break_;

    bool any_bound = false;
    for (const auto& l : S.levers) any_bound = any_bound || l.st == ElementState::bound;
    q16 res = T / 4;
    if (jammed || S.tripped) res = T;
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
    for (std::size_t i = 0; i < S.levers.size(); ++i) {
      const LeverState& l = S.levers[i];
      ElementView e;
      e.state = (l.st == ElementState::bound && l.near) ? ElementState::near : l.st;
      e.position = q_clamp(l.p, 0, Q16_ONE);
      e.window_lo = P.win_lo(P.levers[i]);
      e.window_hi = P.win_hi(P.levers[i]);
      e.variant = static_cast<std::uint8_t>(P.levers[i].false_gates.size());  // false notches
      v.elements.push_back(e);
      sets += l.st == ElementState::set ? 1 : 0;
    }
    v.pick_element = S.pick;
    v.pick_lift = S.lift;
    v.tension = S.tension;
    // core_rotation = bolt travel (fraction of the throw).
    v.core_rotation = S.open ? Q16_ONE : q16_milli(15) * sets;
    v.tension_resistance = S.resistance;
    v.pick_drag = S.drag;
    v.stress = S.tool.ratio();
    // reset_count is only advanced while tripped (detector family); 0 otherwise.
    v.reset_progress = (S.tripped && P.reset_steps > 0) ? q16_ratio(q_min(S.reset_count, P.reset_steps), P.reset_steps) : 0;
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
    const int n = static_cast<int>(P.levers.size());
    std::vector<int> order(static_cast<std::size_t>(n));
    for (int i = 0; i < n; ++i) order[static_cast<std::size_t>(i)] = i;
    std::stable_sort(order.begin(), order.end(), [&](int a, int b) {
      return P.levers[static_cast<std::size_t>(a)].order < P.levers[static_cast<std::size_t>(b)].order;
    });
    for (std::size_t i = 1; i < order.size(); ++i) {
      if (P.levers[static_cast<std::size_t>(order[i])].order == P.levers[static_cast<std::size_t>(order[i - 1])].order) {
        r.reason = "two levers share a binding offset";
        return r;
      }
    }
    const q16 headroom = P.detector ? q_min(P.overset_margin, P.detector_margin) : P.overset_margin;
    if (P.win_gate * 2 < HUMAN_POSITION_PRECISION * 3) {
      r.reason = "gate below 1.5x human precision";
      return r;
    }
    if (P.win_gate + headroom < HUMAN_POSITION_PRECISION * 3) {
      r.reason = "gate-to-overset/detector headroom below 3x human precision";
      return r;
    }
    r.min_band = Q16_ONE;
    r.min_window = P.win_gate;
    for (int idx : order) {
      const Lever& k = P.levers[static_cast<std::size_t>(idx)];
      const q16 lo = q_max(P.t_hold, k.band_lo);
      const q16 hi = q_min(P.t_stick(k), P.tau_safe);
      if (hi - lo < HUMAN_TENSION_BAND) {
        r.reason = "tension band of lever " + std::to_string(idx) + " narrower than delta_human";
        return r;
      }
      r.min_band = q_min(r.min_band, hi - lo);
      PlanStep st;
      st.element = idx;
      st.depth = element_center(idx, n);
      st.tension = (lo + hi) / 2;
      const q16 zone = (P.win_gate * 3) / 2;
      const q16 first_feel = k.false_gates.empty() ? P.win_lo(k) - zone : k.false_gates.front();
      st.approach_from = q_max(0, first_feel - q16_milli(60));
      st.lift_cap = P.win_hi(k) + headroom / 2;
      if (!k.false_gates.empty()) {
        const q16 clo = q_max(P.cr_lo, P.t_hold);
        if (P.cr_hi - clo < HUMAN_TENSION_BAND) {
          r.reason = "false-gate band narrower than delta_human";
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
    r.plan.drop_all = true;
    r.ok = true;
    return r;
  }

  Value params_to_json(const FamilyParams& fp) const override {
    const Params& P = static_cast<const Params&>(fp);
    Value o = Value::object();
    o.set("win_gate_q16", Value::integer(P.win_gate));
    o.set("overset_margin_q16", Value::integer(P.overset_margin));
    o.set("tension_band_q16", Value::integer(P.tension_band));
    o.set("t_hold_q16", Value::integer(P.t_hold));
    o.set("t_release_q16", Value::integer(P.t_release));
    o.set("tau_safe_q16", Value::integer(P.tau_safe));
    o.set("cr_lo_q16", Value::integer(P.cr_lo));
    o.set("cr_hi_q16", Value::integer(P.cr_hi));
    o.set("drop_grace_steps", Value::integer(P.drop_grace_steps));
    o.set("s_max_q16", Value::integer(P.s_max));
    o.set("stress_gain_q16", Value::integer(P.stress_gain));
    o.set("bound_speed_q16", Value::integer(P.bound_speed));
    o.set("false_speed_q16", Value::integer(P.false_speed));
    o.set("spring_speed_q16", Value::integer(P.spring_speed));
    if (P.set_speed > 0) o.set("set_speed_q16", Value::integer(P.set_speed));
    o.set("detector", Value::boolean(P.detector));
    if (P.detector) {
      o.set("detector_margin_q16", Value::integer(P.detector_margin));
      o.set("reset_steps", Value::integer(P.reset_steps));
      o.set("max_trips", Value::integer(P.max_trips));
      o.set("reset_wear", Value::integer(P.reset_wear));
    }
    Value arr = Value::array();
    for (const Lever& l : P.levers) {
      Value lo = Value::object();
      lo.set("target_q16", Value::integer(l.target));
      lo.set("order_q16", Value::integer(l.order));
      lo.set("band_lo_q16", Value::integer(l.band_lo));
      Value fg = Value::array();
      for (q16 g : l.false_gates) fg.push(Value::integer(g));
      lo.set("false_gates_q16", std::move(fg));
      arr.push(std::move(lo));
    }
    o.set("levers", std::move(arr));
    return o;
  }

  std::shared_ptr<const FamilyParams> params_from_json(const Value& v, std::vector<SpecError>& errors) const override {
    auto P = std::make_shared<Params>();
    const std::string path = ".spec";
    std::int64_t x = 0;
    auto q = [&](const Value& obj, std::string_view key, q16& out, const std::string& p) {
      if (field::get_int(obj, key, 0, 64 * static_cast<std::int64_t>(Q16_ONE), x, errors, p)) out = static_cast<q16>(x);
    };
    auto i32 = [&](std::string_view key, std::int64_t lo, std::int64_t hi, std::int32_t& out) {
      if (field::get_int(v, key, lo, hi, x, errors, path)) out = static_cast<std::int32_t>(x);
    };
    q(v, "win_gate_q16", P->win_gate, path);
    q(v, "overset_margin_q16", P->overset_margin, path);
    q(v, "tension_band_q16", P->tension_band, path);
    q(v, "t_hold_q16", P->t_hold, path);
    q(v, "t_release_q16", P->t_release, path);
    q(v, "tau_safe_q16", P->tau_safe, path);
    q(v, "cr_lo_q16", P->cr_lo, path);
    q(v, "cr_hi_q16", P->cr_hi, path);
    i32("drop_grace_steps", 1, 100000, P->drop_grace_steps);
    q(v, "s_max_q16", P->s_max, path);
    q(v, "stress_gain_q16", P->stress_gain, path);
    q(v, "bound_speed_q16", P->bound_speed, path);
    q(v, "false_speed_q16", P->false_speed, path);
    q(v, "spring_speed_q16", P->spring_speed, path);
    if (v.find("set_speed_q16") != nullptr) q(v, "set_speed_q16", P->set_speed, path);  // optional (rules 1 files)
    field::get_bool(v, "detector", P->detector, errors, path);
    if (P->detector) {
      q(v, "detector_margin_q16", P->detector_margin, path);
      i32("reset_steps", 1, 1200, P->reset_steps);
      i32("max_trips", 1, 10, P->max_trips);
      i32("reset_wear", 0, 100, P->reset_wear);
    }
    const Value* arr = v.find("levers");
    if (arr == nullptr || !arr->is_array()) {
      errors.push_back({path + ".levers", "expected array"});
      return P;
    }
    for (std::size_t i = 0; i < arr->items().size(); ++i) {
      const Value& lo = arr->items()[i];
      const std::string lp = path + ".levers[" + std::to_string(i) + "]";
      if (!lo.is_object()) {
        errors.push_back({lp, "expected object"});
        continue;
      }
      Lever l;
      q(lo, "target_q16", l.target, lp);
      q(lo, "order_q16", l.order, lp);
      q(lo, "band_lo_q16", l.band_lo, lp);
      const Value* fg = lo.find("false_gates_q16");
      if (fg == nullptr || !fg->is_array()) {
        errors.push_back({lp + ".false_gates_q16", "expected array"});
      } else {
        for (const Value& g : fg->items()) {
          if (!g.is_int() || g.as_int() < 0 || g.as_int() > Q16_ONE) {
            errors.push_back({lp + ".false_gates_q16", "expected q16 integers"});
            break;
          }
          l.false_gates.push_back(static_cast<q16>(g.as_int()));
        }
      }
      P->levers.push_back(std::move(l));
    }
    return P;
  }

  std::string_view event_name(std::uint16_t sub) const override {
    switch (sub) {
      case SUB_FALSE_GATE: return slider_ ? "slider.false_notch" : "lever.false_gate";
      case SUB_DETECTOR_RESET: return detector_ ? std::string_view("detector.reset") : std::string_view();
      default: return {};
    }
  }

 private:
  bool detector_;
  bool slider_;

  LockSpec generate_once(std::uint64_t seed, std::uint32_t attempt, const DifficultyVector& d) const {
    const std::string_view fid = id();
    Pcg32 rng(derive_seed(seed ^ splitmix64(attempt), fid, static_cast<std::uint32_t>(rules_version()), "gen"), derive_stream(fid, "gen"));
    auto P = std::make_shared<Params>();
    const int n = rng.range(d.n_min, d.n_max);
    P->win_gate = d.win_shear;
    P->overset_margin = d.overset_margin;
    P->tension_band = d.tension_band;
    P->t_hold = T_HOLD;
    P->t_release = T_RELEASE;
    P->cr_lo = CR_LO;
    P->cr_hi = CR_HI;
    P->drop_grace_steps = ms_to_steps(d.drop_grace_ms);
    P->s_max = d.s_max;
    P->stress_gain = STRESS_GAIN;
    P->bound_speed = BOUND_SPEED;
    P->false_speed = FALSE_SPEED;
    // spring_force 0.3 (t3) -> 0.5 (t5+): levers fall back 4x that per second.
    const int sf = std::clamp(300 + 100 * (d.tier - (slider_ ? 1 : 3)), 300, 500);
    P->spring_speed = q16_per_step(q16_milli(4 * sf));
    P->set_speed = SET_SPEED;
    P->detector = detector_;
    if (detector_) {
      // detector_margin 10 % (t5) -> 8.3 % (t6) (rules 2, D-34; was 12 % -> 6 %); reset 1.5 s -> 2.5 s.
      const bool hard = d.tier >= 6;
      P->detector_margin = hard ? DETECTOR_MARGIN_T6 : DETECTOR_MARGIN_T5;
      P->reset_steps = ms_to_steps(hard ? 2500 : 1500);
      P->max_trips = 3;
      P->reset_wear = 2;
    }
    P->levers.resize(static_cast<std::size_t>(n));
    std::vector<int> perm(static_cast<std::size_t>(n));
    for (int i = 0; i < n; ++i) perm[static_cast<std::size_t>(i)] = i;
    for (int i = n - 1; i > 0; --i) std::swap(perm[static_cast<std::size_t>(i)], perm[rng.below(static_cast<std::uint32_t>(i + 1))]);
    const q16 unit = q_max(1, q_mul(d.bind_spread, q16_milli(100)));
    q16 max_stick = 0;
    for (int r = 0; r < n; ++r) {
      Lever& l = P->levers[static_cast<std::size_t>(perm[static_cast<std::size_t>(r)])];
      l.order = unit * r;
      l.band_lo = T_BIND_BASE + rng.range(0, T_BIND_JITTER);
    }
    for (Lever& l : P->levers) {
      l.target = rng.range(q16_milli(450), q16_milli(680));
      max_stick = q_max(max_stick, l.band_lo + P->tension_band);
      const int fgs = rng.range(d.sec_min, d.sec_max);
      q16 g = P->win_lo(l);
      for (int k = 0; k < fgs; ++k) {
        g -= k == 0 ? rng.range(q16_milli(100), q16_milli(140)) : rng.range(q16_milli(80), q16_milli(100));
        l.false_gates.insert(l.false_gates.begin(), g);
      }
    }
    P->tau_safe = q_min(Q16_ONE, max_stick + TAU_SAFE_MARGIN);

    LockSpec spec;
    spec.family = std::string(fid);
    spec.rules_version = rules_version();
    spec.id = "gen." + std::string(fid) + ".t" + std::to_string(d.tier) + "." + std::to_string(seed);
    spec.source = "generated";
    spec.seed = seed;
    spec.difficulty = d;
    spec.material = slider_ ? MaterialId::steel : MaterialId::brass;
    spec.params = P;
    return spec;
  }
};

}  // namespace

std::unique_ptr<FamilyModule> make_module() { return std::make_unique<Module>(false); }
std::unique_ptr<FamilyModule> make_detector_module() { return std::make_unique<Module>(true); }
std::unique_ptr<FamilyModule> make_slider_module() { return std::make_unique<Module>(false, true); }

}  // namespace lockcore::lever
