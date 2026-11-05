// Ring combination padlock (LOCKS.md §2.3).
//
// Ring positions are fractions of a full turn (digit d sits at d / positions).
// pick_depth selects a ring, rotate turns it (speed axis). Pulling the shackle
// (tension) binds the unset ring with the lowest binding offset once T >= band_lo:
// it turns stiffly (drag) and only while T <= t_stick. When a bound ring reaches
// its gate it drops in (gate_align + set) and the next ring binds. A false notch
// (t3) catches a bound ring (false_set): it stops turning until the pull is
// eased below its band_lo. Letting go of the shackle (T < t_hold for drop_grace)
// loses nothing but the set flags: rings keep their positions, so re-pulling
// re-sets every ring already at its gate. No tool breaks here.
#include "lockcore/ring_combo.hpp"

#include <algorithm>
#include <deque>

#include "lockcore/bot.hpp"
#include "lockcore/hash.hpp"
#include "lockcore/lockfile.hpp"
#include "lockcore/session.hpp"

namespace lockcore::ring {

namespace {

using json::Value;

constexpr q16 DRAG_FRICTION = q16_milli(500);

q16 wrap(std::int64_t v) {
  v %= Q16_ONE;
  if (v < 0) v += Q16_ONE;
  return static_cast<q16>(v);
}
q16 cdist(q16 a, q16 b) {
  const q16 d = wrap(static_cast<std::int64_t>(a) - b);
  return d > Q16_ONE / 2 ? Q16_ONE - d : d;
}
// Forward (positive rotate) distance from a to b.
q16 fdist(q16 a, q16 b) { return wrap(static_cast<std::int64_t>(b) - a); }
std::int32_t nearest_digit(q16 pos, std::int32_t positions) {
  return static_cast<std::int32_t>(((static_cast<std::int64_t>(pos) * positions + Q16_ONE / 2) >> 16) % positions);
}

struct RingState {
  ElementState st = ElementState::free;
  q16 pos = 0;
  bool near = false;
};

struct State : FamilyState {
  std::shared_ptr<const Params> params;
  MaterialId material = MaterialId::brass;
  std::vector<RingState> rings;
  int pick = -1;
  q16 tension = 0;
  q16 rotate = 0;
  q16 resistance = 0;
  q16 drag = 0;
};

const Params& params_of(const LockSpec& spec) { return static_cast<const Params&>(*spec.params); }

class Module final : public FamilyModule {
 public:
  std::string_view id() const override { return FAMILY_ID; }
  std::int32_t rules_version() const override { return RULES_VERSION; }
  std::uint32_t input_mask() const override { return AXIS_TENSION | AXIS_DEPTH | AXIS_ROTATE; }
  ToolSet required_tools(const LockSpec&) const override { return ToolSet{TOOL_SHACKLE_PULLER}; }

  int min_tier() const override { return 2; }
  int max_tier() const override { return 3; }

  DifficultyVector difficulty_for_tier(int tier) const override {
    // LOCKS.md §2.3: 3->5 rings, gate_feel 0.8->0.35 (noise = 1 - gate_feel),
    // false notches from t3 (sec = false gates per ring).
    const int t = std::clamp(tier, 2, 3);
    DifficultyVector d;
    d.tier = t;
    d.n_min = t == 2 ? 3 : 4;
    d.n_max = t == 2 ? 4 : 5;
    d.sec_min = 0;
    d.sec_max = t == 2 ? 0 : 2;
    d.win_shear = GATE_WIN;
    d.tension_band = q16_milli(t == 2 ? 260 : 200);
    d.overset_margin = 0;
    d.noise = q16_milli(t == 2 ? 300 : 550);
    d.bind_spread = q16_milli(t == 2 ? 1000 : 500);
    d.drop_grace_ms = t == 2 ? 300 : 250;
    d.s_max = Q16_ONE;  // unused
    d.time_limit_s = t == 2 ? 90 : 120;
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
    if (spec.family != FAMILY_ID) e.push_back({"family", "not ring_combo"});
    const auto* pp = dynamic_cast<const Params*>(spec.params.get());
    if (pp == nullptr) {
      e.push_back({"spec", "missing or foreign parameters"});
      return e;
    }
    const Params& P = *pp;
    const int n = static_cast<int>(P.rings.size());
    if (n < 1 || n > 8) e.push_back({"spec.rings", "need 1..8 rings"});
    if (P.positions < 4 || P.positions > 20) e.push_back({"spec.positions", "need 4..20"});
    const q16 pitch = P.positions > 0 ? Q16_ONE / P.positions : Q16_ONE;
    if (P.gate_win <= 0 || P.gate_win >= pitch) e.push_back({"spec.gate_win_q16", "need 0 < gate_win < one digit"});
    if (P.tension_band <= 0) e.push_back({"spec.tension_band_q16", "must be > 0"});
    if (P.t_hold <= 0) e.push_back({"spec.t_hold_q16", "must be > 0"});
    if (P.drop_grace_steps < 1) e.push_back({"spec.drop_grace_steps", "must be >= 1"});
    if (P.gate_feel < 0 || P.gate_feel > Q16_ONE) e.push_back({"spec.gate_feel_q16", "out of range"});
    if (P.rot_speed <= 0 || P.bound_rot_speed <= 0 || P.snap_speed <= 0 || P.rot_speed >= pitch / 2 ||
        P.bound_rot_speed >= pitch / 2)
      e.push_back({"spec.rot_speed_q16", "speeds must be > 0 and below half a digit per step"});
    for (int i = 0; i < n; ++i) {
      const Ring& r = P.rings[static_cast<std::size_t>(i)];
      const std::string path = "spec.rings[" + std::to_string(i) + "]";
      if (r.gate < 0 || r.gate >= P.positions) e.push_back({path + ".gate", "out of range"});
      if (r.start < 0 || r.start >= P.positions) e.push_back({path + ".start", "out of range"});
      if (r.band_lo < P.t_hold || P.t_stick(r) > Q16_ONE) e.push_back({path + ".band_lo_q16", "need t_hold <= band_lo"});
      if (r.order < 0) e.push_back({path + ".order_q16", "negative"});
      for (std::int32_t g : r.false_gates) {
        if (g < 0 || g >= P.positions || g == r.gate) e.push_back({path + ".false_gates", "digit out of range or on the gate"});
      }
    }
    return e;
  }

  std::unique_ptr<FamilyState> init_state(const LockSpec& spec) const override {
    auto s = std::make_unique<State>();
    s->params = std::static_pointer_cast<const Params>(spec.params);
    s->material = spec.material;
    s->rings.resize(s->params->rings.size());
    for (std::size_t i = 0; i < s->rings.size(); ++i) s->rings[i].pos = s->params->digit_pos(s->params->rings[i].start);
    s->tool.init(Q16_ONE, 0, Q16_ONE);  // never loaded
    return s;
  }

  void step(FamilyState& base, const InputFrame& in, StepCtx& ctx) const override {
    State& S = static_cast<State&>(base);
    const Params& P = *S.params;
    EventSink& out = *ctx.events;
    const std::int64_t t = ctx.t_step;
    const int n = static_cast<int>(P.rings.size());
    const q16 T = in.tension;

    const int pick = locate_element(in.pick_depth, n);
    if (pick >= 0 && pick != S.pick) out.emit(t, EventKind::contact, pick, q_mul(material_hardness(S.material), q16_milli(600)), S.material);
    S.pick = pick;
    S.tension = T;
    S.rotate = in.rotate;

    // Letting go of the shackle: set flags are lost, positions stay.
    if (S.hold.update(T, P.t_hold, P.drop_grace_steps)) {
      int dropped = 0;
      for (auto& r : S.rings) {
        if (r.st == ElementState::set || r.st == ElementState::false_set) ++dropped;
        r.st = ElementState::free;
        r.near = false;
      }
      if (dropped > 0) out.emit(t, EventKind::drop, -1, q16_ratio(dropped, n), S.material);
    }

    auto try_gate = [&](int i) {
      RingState& r = S.rings[static_cast<std::size_t>(i)];
      const Ring& k = P.rings[static_cast<std::size_t>(i)];
      const q16 g = P.digit_pos(k.gate);
      const q16 dist = cdist(r.pos, g);
      if (dist * 2 <= P.gate_win) {
        r.st = ElementState::set;
        r.pos = g;
        r.near = false;
        out.emit(t, EventKind::gate_align, i, P.gate_feel, S.material);
        out.emit(t, EventKind::set, i, q16_milli(400) + q_mul(P.gate_feel, q16_milli(600)), S.material);
        return;
      }
      for (std::int32_t fg : k.false_gates) {
        const q16 f = P.digit_pos(fg);
        if (cdist(r.pos, f) * 2 <= P.gate_win) {
          r.st = ElementState::false_set;
          r.pos = f;
          r.near = false;
          out.emit(t, EventKind::false_set, i, q16_milli(250) + q_mul(P.gate_feel, q16_milli(400)), S.material);
          return;
        }
      }
      if (!r.near && dist * 2 <= P.gate_win * 3) {
        r.near = true;
        out.emit(t, EventKind::near_shear, i, P.gate_feel / 2, S.material);  // a faint "sink"
      } else if (r.near && dist * 2 > P.gate_win * 3) {
        r.near = false;
      }
    };

    // Binding: a caught ring blocks the others; easing below its band frees it.
    int caught = -1;
    q16 min_o = Q16_ONE * 64;
    for (int i = 0; i < n; ++i) {
      RingState& r = S.rings[static_cast<std::size_t>(i)];
      const Ring& k = P.rings[static_cast<std::size_t>(i)];
      if (r.st == ElementState::false_set && T < k.band_lo) r.st = ElementState::free;
      if (r.st == ElementState::false_set) caught = i;
      if (r.st == ElementState::free || r.st == ElementState::bound) min_o = q_min(min_o, k.order);
    }
    for (int i = 0; i < n; ++i) {
      RingState& r = S.rings[static_cast<std::size_t>(i)];
      const Ring& k = P.rings[static_cast<std::size_t>(i)];
      if (r.st != ElementState::free && r.st != ElementState::bound) continue;
      const bool want = caught < 0 && k.order == min_o && T >= k.band_lo;
      if (want && r.st == ElementState::free) {
        r.st = ElementState::bound;
        out.emit(t, EventKind::bind, i, T, S.material);
        try_gate(i);
      } else if (!want && r.st == ElementState::bound) {
        r.st = ElementState::free;
        r.near = false;
      }
    }

    // Turning the selected ring.
    q16 drag = 0;
    if (pick >= 0) {
      RingState& r = S.rings[static_cast<std::size_t>(pick)];
      const Ring& k = P.rings[static_cast<std::size_t>(pick)];
      const q16 mag = q_abs(in.rotate);
      const int dir = in.rotate > 0 ? 1 : -1;
      q16 move = 0;
      bool blocked = false;
      switch (r.st) {
        case ElementState::set:
        case ElementState::false_set: blocked = mag > 0; break;
        case ElementState::bound:
          if (T <= P.t_stick(k)) move = q_min(q_mul(mag, P.rot_speed), P.bound_rot_speed);
          else blocked = mag > 0;
          break;
        default: move = q_mul(mag, P.rot_speed); break;
      }
      if (blocked) drag = mag;
      else if (r.st == ElementState::bound && mag > 0) drag = q_max(q_mul(T, DRAG_FRICTION), q16_milli(40));
      const q16 old = r.pos;
      if (move > 0) {
        r.pos = wrap(static_cast<std::int64_t>(r.pos) + dir * move);
      } else if (mag == 0 && (r.st == ElementState::free || r.st == ElementState::bound)) {
        // Detent spring pulls the ring onto the nearest digit.
        const q16 target = P.digit_pos(nearest_digit(r.pos, P.positions));
        const q16 fd = fdist(r.pos, target);
        if (fd != 0) {
          const bool fwd = fd <= Q16_ONE / 2;
          const q16 dist = fwd ? fd : Q16_ONE - fd;
          r.pos = wrap(static_cast<std::int64_t>(r.pos) + (fwd ? 1 : -1) * q_min(dist, P.snap_speed));
        }
      }
      if (nearest_digit(old, P.positions) != nearest_digit(r.pos, P.positions)) {
        const q16 click = r.st == ElementState::bound ? q16_milli(350) : q16_milli(150);
        out.emit(t, EventKind::contact, pick, q_mul(click, q16_milli(500) + P.gate_feel / 2), S.material, SUB_DETENT);
      }
      if (r.st == ElementState::bound && r.pos != old) try_gate(pick);
    }

    if (!S.open && T >= P.t_hold &&
        std::all_of(S.rings.begin(), S.rings.end(), [](const RingState& r) { return r.st == ElementState::set; })) {
      S.open = true;
      out.emit(t, EventKind::open, -1, Q16_ONE, S.material);
    }

    bool any_bound = false;
    for (const auto& r : S.rings) any_bound = any_bound || r.st == ElementState::bound;
    S.resistance = caught >= 0 ? T : (any_bound ? q_mul(T, q16_milli(700)) : T / 4);
    S.drag = drag;
    ctx.tension_resistance = S.resistance;
    ctx.pick_drag = drag;
  }

  ViewModel describe(const FamilyState& base) const override {
    const State& S = static_cast<const State&>(base);
    const Params& P = *S.params;
    ViewModel v;
    int sets = 0;
    for (std::size_t i = 0; i < S.rings.size(); ++i) {
      const RingState& r = S.rings[i];
      ElementView e;
      e.state = (r.st == ElementState::bound && r.near) ? ElementState::near : r.st;
      e.position = r.pos;  // fraction of a turn; digit = position * positions
      const q16 g = P.digit_pos(P.rings[i].gate);
      e.window_lo = g - P.gate_win / 2;  // may wrap below 0 for digit 0
      e.window_hi = g + P.gate_win / 2;
      e.variant = static_cast<std::uint8_t>(P.rings[i].false_gates.size());
      v.elements.push_back(e);
      sets += r.st == ElementState::set ? 1 : 0;
    }
    v.pick_element = S.pick;
    v.pick_lift = 0;
    v.tension = S.tension;
    v.core_rotation = S.open ? Q16_ONE : q16_milli(20) * sets;  // shackle travel
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
    const auto order = binding_order(P);
    for (std::size_t i = 1; i < order.size(); ++i) {
      if (P.rings[static_cast<std::size_t>(order[i])].order == P.rings[static_cast<std::size_t>(order[i - 1])].order) {
        r.reason = "two rings share a binding offset";
        return r;
      }
    }
    if (P.gate_win * 2 < HUMAN_POSITION_PRECISION * 3) {
      r.reason = "gate window below 1.5x human precision";
      return r;
    }
    r.min_band = Q16_ONE;
    r.min_window = P.gate_win;
    const int n = static_cast<int>(P.rings.size());
    for (int idx : order) {
      const Ring& k = P.rings[static_cast<std::size_t>(idx)];
      const q16 lo = q_max(P.t_hold, k.band_lo);
      const q16 hi = P.t_stick(k);
      if (hi - lo < HUMAN_TENSION_BAND) {
        r.reason = "tension band of ring " + std::to_string(idx) + " narrower than delta_human";
        return r;
      }
      // The plan spins the ring loose (t_hold <= T < band_lo), then binds it one
      // digit before the gate: that digit must not hold a false notch.
      if (k.band_lo - P.t_hold < HUMAN_TENSION_BAND) {
        r.reason = "free-spin band of ring " + std::to_string(idx) + " narrower than delta_human";
        return r;
      }
      const std::int32_t pre = (k.gate + P.positions - 1) % P.positions;
      if (std::find(k.false_gates.begin(), k.false_gates.end(), pre) != k.false_gates.end()) {
        r.reason = "false notch next to the gate of ring " + std::to_string(idx);
        return r;
      }
      r.min_band = q_min(r.min_band, q_min(hi - lo, k.band_lo - P.t_hold));
      PlanStep st;
      st.element = idx;
      st.depth = element_center(idx, n);
      st.tension = (lo + hi) / 2;
      st.cr_tension = (P.t_hold + k.band_lo) / 2;  // free-spin tension
      st.approach_from = P.digit_pos(pre);         // turn position to bind at
      st.lift_cap = P.digit_pos(k.gate);            // gate position
      r.plan.steps.push_back(st);
    }
    r.plan.release_tension = 0;
    r.plan.t_hold = P.t_hold;
    r.plan.drop_all = true;
    r.ok = true;
    return r;
  }

  SolveReport solver(const LockSpec& spec, const ToolSet& tools, const SolveOptions& opt) const override {
    return run_bot(BotKind::scripted, spec, tools, opt);
  }

  SolveReport run_bot(BotKind kind, const LockSpec& spec, const ToolSet& tools, const SolveOptions& opt) const override {
    // The feeling bot skips the oracle gate, not the input check (T25-14).
    if (std::string e = session_input_error(*this, spec, tools); !e.empty()) {
      SolveReport r;
      r.reason = e;
      return r;
    }
    const OracleReport o = oracle(spec, tools);
    if (!o.ok && kind != BotKind::feeling) {
      SolveReport r;
      r.reason = "oracle: " + o.reason;
      return r;
    }
    const std::int64_t full = static_cast<std::int64_t>(spec.difficulty.time_limit_s) * SIM_HZ;
    switch (kind) {
      case BotKind::scripted: return plan_bot(spec, tools, o.plan, HumanLimits{}, full / 2, opt, false);
      case BotKind::clumsy: return plan_bot(spec, tools, o.plan, clumsy_human_limits(), full, opt, true);
      case BotKind::feeling: return feel_bot(spec, tools, feeling_human_limits(), full, opt);
    }
    return {};
  }

  Value params_to_json(const FamilyParams& fp) const override {
    const Params& P = static_cast<const Params&>(fp);
    Value o = Value::object();
    o.set("positions", Value::integer(P.positions));
    o.set("gate_win_q16", Value::integer(P.gate_win));
    o.set("tension_band_q16", Value::integer(P.tension_band));
    o.set("t_hold_q16", Value::integer(P.t_hold));
    o.set("drop_grace_steps", Value::integer(P.drop_grace_steps));
    o.set("gate_feel_q16", Value::integer(P.gate_feel));
    o.set("rot_speed_q16", Value::integer(P.rot_speed));
    o.set("bound_rot_speed_q16", Value::integer(P.bound_rot_speed));
    o.set("snap_speed_q16", Value::integer(P.snap_speed));
    Value arr = Value::array();
    for (const Ring& r : P.rings) {
      Value ro = Value::object();
      ro.set("gate", Value::integer(r.gate));
      ro.set("start", Value::integer(r.start));
      ro.set("order_q16", Value::integer(r.order));
      ro.set("band_lo_q16", Value::integer(r.band_lo));
      Value fg = Value::array();
      for (std::int32_t g : r.false_gates) fg.push(Value::integer(g));
      ro.set("false_gates", std::move(fg));
      arr.push(std::move(ro));
    }
    o.set("rings", std::move(arr));
    return o;
  }

  std::shared_ptr<const FamilyParams> params_from_json(const Value& v, std::vector<SpecError>& errors) const override {
    auto P = std::make_shared<Params>();
    const std::string path = ".spec";
    std::int64_t x = 0;
    auto q = [&](const Value& obj, std::string_view key, q16& out, const std::string& p) {
      if (field::get_int(obj, key, 0, 64 * static_cast<std::int64_t>(Q16_ONE), x, errors, p)) out = static_cast<q16>(x);
    };
    auto i32 = [&](const Value& obj, std::string_view key, std::int64_t lo, std::int64_t hi, std::int32_t& out, const std::string& p) {
      if (field::get_int(obj, key, lo, hi, x, errors, p)) out = static_cast<std::int32_t>(x);
    };
    i32(v, "positions", 1, 100, P->positions, path);
    q(v, "gate_win_q16", P->gate_win, path);
    q(v, "tension_band_q16", P->tension_band, path);
    q(v, "t_hold_q16", P->t_hold, path);
    i32(v, "drop_grace_steps", 1, 100000, P->drop_grace_steps, path);
    q(v, "gate_feel_q16", P->gate_feel, path);
    q(v, "rot_speed_q16", P->rot_speed, path);
    q(v, "bound_rot_speed_q16", P->bound_rot_speed, path);
    q(v, "snap_speed_q16", P->snap_speed, path);
    const Value* arr = v.find("rings");
    if (arr == nullptr || !arr->is_array()) {
      errors.push_back({path + ".rings", "expected array"});
      return P;
    }
    for (std::size_t i = 0; i < arr->items().size(); ++i) {
      const Value& ro = arr->items()[i];
      const std::string rp = path + ".rings[" + std::to_string(i) + "]";
      if (!ro.is_object()) {
        errors.push_back({rp, "expected object"});
        continue;
      }
      Ring r;
      i32(ro, "gate", 0, 99, r.gate, rp);
      i32(ro, "start", 0, 99, r.start, rp);
      q(ro, "order_q16", r.order, rp);
      q(ro, "band_lo_q16", r.band_lo, rp);
      const Value* fg = ro.find("false_gates");
      if (fg == nullptr || !fg->is_array()) {
        errors.push_back({rp + ".false_gates", "expected array"});
      } else {
        for (const Value& g : fg->items()) {
          if (!g.is_int() || g.as_int() < 0 || g.as_int() > 99) {
            errors.push_back({rp + ".false_gates", "expected digits"});
            break;
          }
          r.false_gates.push_back(static_cast<std::int32_t>(g.as_int()));
        }
      }
      P->rings.push_back(std::move(r));
    }
    return P;
  }

  std::string_view event_name(std::uint16_t sub) const override {
    return sub == SUB_DETENT ? std::string_view("ring.detent") : std::string_view();
  }

 private:
  static std::vector<int> binding_order(const Params& P) {
    std::vector<int> order(P.rings.size());
    for (std::size_t i = 0; i < order.size(); ++i) order[i] = static_cast<int>(i);
    std::stable_sort(order.begin(), order.end(), [&](int a, int b) {
      return P.rings[static_cast<std::size_t>(a)].order < P.rings[static_cast<std::size_t>(b)].order;
    });
    return order;
  }

  LockSpec generate_once(std::uint64_t seed, std::uint32_t attempt, const DifficultyVector& d) const {
    Pcg32 rng(derive_seed(seed ^ splitmix64(attempt), FAMILY_ID, RULES_VERSION, "gen"), derive_stream(FAMILY_ID, "gen"));
    auto P = std::make_shared<Params>();
    const int n = rng.range(d.n_min, d.n_max);
    P->positions = 10;
    P->gate_win = d.win_shear;
    P->tension_band = d.tension_band;
    P->t_hold = T_HOLD;
    P->drop_grace_steps = ms_to_steps(d.drop_grace_ms);
    P->gate_feel = q_clamp(Q16_ONE - d.noise, 0, Q16_ONE);
    P->rot_speed = ROT_SPEED;
    P->bound_rot_speed = BOUND_ROT_SPEED;
    P->snap_speed = SNAP_SPEED;
    P->rings.resize(static_cast<std::size_t>(n));
    std::vector<int> perm(static_cast<std::size_t>(n));
    for (int i = 0; i < n; ++i) perm[static_cast<std::size_t>(i)] = i;
    for (int i = n - 1; i > 0; --i) std::swap(perm[static_cast<std::size_t>(i)], perm[rng.below(static_cast<std::uint32_t>(i + 1))]);
    const q16 unit = q_max(1, q_mul(d.bind_spread, q16_milli(100)));
    for (int r = 0; r < n; ++r) {
      Ring& k = P->rings[static_cast<std::size_t>(perm[static_cast<std::size_t>(r)])];
      k.order = unit * r;
      k.band_lo = T_BIND_BASE + rng.range(0, T_BIND_JITTER);
    }
    for (Ring& k : P->rings) {
      k.gate = rng.range(0, P->positions - 1);
      k.start = (k.gate + rng.range(2, P->positions - 2)) % P->positions;
      const int fgs = rng.range(d.sec_min, d.sec_max);
      for (int f = 0; f < fgs; ++f) {
        // Not on the gate or next to it: a false notch must be told apart by feel.
        for (int tries = 0; tries < 8; ++tries) {
          const std::int32_t g = (k.gate + rng.range(2, P->positions - 2)) % P->positions;
          if (std::find(k.false_gates.begin(), k.false_gates.end(), g) == k.false_gates.end()) {
            k.false_gates.push_back(g);
            break;
          }
        }
      }
      std::sort(k.false_gates.begin(), k.false_gates.end());
    }
    LockSpec spec;
    spec.family = std::string(FAMILY_ID);
    spec.rules_version = RULES_VERSION;
    spec.id = "gen.ring_combo.t" + std::to_string(d.tier) + "." + std::to_string(seed);
    spec.source = "generated";
    spec.seed = seed;
    spec.difficulty = d;
    spec.material = MaterialId::brass;
    spec.params = P;
    return spec;
  }

  // Scripted bot (stage 2): per ring in binding order, spin it loose to the digit
  // before the gate (dead reckoning on its own turn input), bind it with the
  // working pull and creep into the gate until `set` is felt.
  SolveReport plan_bot(const LockSpec& spec, const ToolSet& tools, const Plan& plan, const HumanLimits& lim,
                       std::int64_t budget, const SolveOptions& opt, bool clumsy) const {
    const Params& P = params_of(spec);
    SolveReport rep;
    LockSession session(*this, spec, tools);
    Pcg32 rng(derive_seed(spec.seed ^ splitmix64(opt.bot_seed), FAMILY_ID, RULES_VERSION, "bot"), derive_stream(FAMILY_ID, "bot"));
    const int n = static_cast<int>(P.rings.size());
    std::vector<q16> est(static_cast<std::size_t>(n));
    for (int i = 0; i < n; ++i) est[static_cast<std::size_t>(i)] = P.digit_pos(P.rings[static_cast<std::size_t>(i)].start);
    std::vector<char> believed(static_cast<std::size_t>(n), 0);
    std::deque<LockEvent> perceived;
    enum class Ph { travel, spin, settle, bind, creep, hold };
    Ph ph = Ph::travel;
    std::int64_t phase_t = 0;
    std::size_t si = 0;
    q16 hand_t = 0, hand_d = plan.steps.empty() ? 0 : plan.steps.front().depth, noise_t = 0;
    q16 crept = 0;
    const q16 spin_in = clumsy ? q16_milli(900) : q16_milli(500);
    const q16 creep_in = clumsy ? q16_milli(700) : q16_milli(300);
    auto go = [&](Ph p, std::int64_t t) {
      ph = p;
      phase_t = t;
    };
    for (std::int64_t t = 0; t < budget; ++t) {
      while (!perceived.empty() && perceived.front().t_step <= t - lim.latency_steps) {
        const LockEvent e = perceived.front();
        perceived.pop_front();
        if (e.sub != 0) continue;
        if (e.kind == EventKind::set && e.element >= 0 && e.element < n) believed[static_cast<std::size_t>(e.element)] = 1;
        if (e.kind == EventKind::drop) {
          for (auto& b : believed) b = 0;
          ++rep.retries;
          si = 0;
          go(Ph::travel, t);
        }
      }
      while (si < plan.steps.size() && believed[static_cast<std::size_t>(plan.steps[si].element)] && ph != Ph::creep) ++si;
      q16 target_t = hand_t, target_d = hand_d, rot = 0;
      if (si >= plan.steps.size()) {
        ph = Ph::hold;
      }
      const PlanStep* st = si < plan.steps.size() ? &plan.steps[si] : nullptr;
      const std::size_t ei = st ? static_cast<std::size_t>(st->element) : 0;
      switch (ph) {
        case Ph::travel:
          target_t = st->cr_tension;
          target_d = st->depth;
          if (hand_d == st->depth && q_abs(hand_t - st->cr_tension) <= q16_milli(10) && t - phase_t >= lim.min_hold_steps)
            go(Ph::spin, t);
          break;
        case Ph::spin: {
          target_t = st->cr_tension;
          const q16 left = fdist(est[ei], st->approach_from);
          const q16 v = q_mul(spin_in, P.rot_speed);
          if (left > v && left < Q16_ONE - P.gate_win) {
            rot = spin_in;
          } else {
            go(Ph::settle, t);
          }
          break;
        }
        case Ph::settle:
          target_t = st->cr_tension;
          if (t - phase_t >= lim.min_hold_steps) {
            est[ei] = st->approach_from;  // the detent snapped onto the digit
            go(Ph::bind, t);
          }
          break;
        case Ph::bind:
          target_t = st->tension;
          if (q_abs(hand_t - st->tension) <= q16_milli(10) && t - phase_t >= lim.min_hold_steps) {
            crept = 0;
            go(Ph::creep, t);
          }
          break;
        case Ph::creep:
          target_t = st->tension;
          if (believed[ei]) {
            est[ei] = st->lift_cap;
            go(Ph::travel, t);
            ++si;
            if (si >= plan.steps.size()) go(Ph::hold, t);
            break;
          }
          rot = creep_in;
          if (crept > Q16_ONE + Q16_ONE / 2) {
            rep.reason = "bot: ring never dropped into its gate";
            t = budget;
          }
          break;
        case Ph::hold: break;
      }
      hand_t = bot_approach(hand_t, target_t, lim.tension_rate);
      hand_d = bot_approach(hand_d, target_d, lim.depth_rate);
      if (t % lim.noise_period_steps == 0) noise_t = rng.range(-lim.tension_noise, lim.tension_noise);
      InputFrame in;
      in.tension = hand_t + noise_t;
      in.pick_depth = hand_d;
      in.rotate = rot;
      in = quantize(in);
      if (ph == Ph::spin) est[ei] = wrap(static_cast<std::int64_t>(est[ei]) + q_mul(in.rotate, P.rot_speed));
      if (ph == Ph::creep) crept += q_min(q_mul(in.rotate, P.rot_speed), P.bound_rot_speed);
      const StepOutput& out = session.step(in);
      if (opt.record_inputs) rep.inputs.push_back(in);
      for (const auto& e : out.events) {
        perceived.push_back(e);
        if (e.sub != 0) continue;
        if (e.kind == EventKind::drop) ++rep.drops;
        if (e.kind == EventKind::false_set) ++rep.false_sets;
      }
      if (session.finished() || rep.retries > lim.max_retries) break;
    }
    return finish(session, rep, "bot");
  }

  // Feeling bot (stage 3): knows the number of rings and digits only. Searches the
  // pull, turns each unset ring and feels for drag; a stiff ring is turned until
  // it drops in; a false notch is escaped by easing the pull for a moment.
  SolveReport feel_bot(const LockSpec& spec, const ToolSet& tools, const HumanLimits& lim, std::int64_t budget,
                       const SolveOptions& opt) const {
    SolveReport rep;
    LockSession session(*this, spec, tools);
    Pcg32 rng(derive_seed(spec.seed ^ splitmix64(opt.bot_seed), FAMILY_ID, RULES_VERSION, "feel"), derive_stream(FAMILY_ID, "feel"));
    const int n = static_cast<int>(session.describe().elements.size());
    std::vector<char> believed(static_cast<std::size_t>(n), 0), loose(static_cast<std::size_t>(n), 0);
    std::deque<LockEvent> perceived;
    std::vector<q16> drag_buf(static_cast<std::size_t>(lim.latency_steps), 0);
    std::size_t drag_head = 0;
    enum class Ph { travel, probe, turn, escape, wait_open };
    Ph ph = Ph::travel;
    std::int64_t phase_t = 0;
    int cand = 0;
    q16 work_t = q16_milli(150), hand_t = 0, hand_d = element_center(0, n), noise_t = 0;
    q16 max_drag = 0, last_drag = 0;
    std::int32_t clicks = 0;
    bool fresh = true;
    constexpr q16 DRAG_BOUND = q16_milli(60);
    auto go = [&](Ph p, std::int64_t t) {
      ph = p;
      phase_t = t;
      max_drag = 0;
      clicks = 0;
    };
    auto next = [&](std::int64_t t) {
      int c = -1;
      for (int k = 1; k <= n && c < 0; ++k) {
        const int i = (cand + k) % n;
        if (!believed[static_cast<std::size_t>(i)] && !loose[static_cast<std::size_t>(i)]) c = i;
      }
      if (c < 0) {
        for (auto& l : loose) l = 0;
        work_t = work_t + q16_milli(30) > q16_milli(900) ? q16_milli(150) : work_t + q16_milli(30);
        fresh = true;
        ++rep.retries;
        for (int k = 1; k <= n && c < 0; ++k) {
          const int i = (cand + k) % n;
          if (!believed[static_cast<std::size_t>(i)]) c = i;
        }
      }
      cand = c < 0 ? 0 : c;
      go(Ph::travel, t);
    };
    for (std::int64_t t = 0; t < budget; ++t) {
      while (!perceived.empty() && perceived.front().t_step <= t - lim.latency_steps) {
        const LockEvent e = perceived.front();
        perceived.pop_front();
        if (e.sub == SUB_DETENT && e.element == cand) ++clicks;
        if (e.sub != 0) continue;
        if (e.kind == EventKind::set && e.element >= 0 && e.element < n) {
          believed[static_cast<std::size_t>(e.element)] = 1;
          for (auto& l : loose) l = 0;
          bool all = true;
          for (char b : believed) all = all && b;
          if (all) go(Ph::wait_open, t);
          else if (e.element == cand) next(t);
        } else if (e.kind == EventKind::false_set && e.element == cand && ph == Ph::turn) {
          go(Ph::escape, t);
        } else if (e.kind == EventKind::drop) {
          for (auto& b : believed) b = 0;
          next(t);
        }
      }
      const q16 felt = drag_buf[drag_head];
      drag_buf[drag_head] = last_drag;
      drag_head = (drag_head + 1) % drag_buf.size();
      q16 target_t = work_t, target_d = hand_d, rot = 0;
      const q16 depth = element_center(cand, n);
      switch (ph) {
        case Ph::travel:
          target_d = depth;
          if (hand_d == depth && t - phase_t >= lim.min_hold_steps) go(Ph::probe, t);
          break;
        case Ph::probe:
          rot = q16_milli(300);
          if (t - phase_t > lim.latency_steps) max_drag = q_max(max_drag, felt);
          if (max_drag >= DRAG_BOUND) {
            if (fresh) work_t = q_min(q16_milli(900), work_t + q16_milli(30));
            fresh = false;
            go(Ph::turn, t);
          } else if (t - phase_t > lim.latency_steps + SIM_HZ) {
            loose[static_cast<std::size_t>(cand)] = 1;
            next(t);
          }
          break;
        case Ph::turn:
          rot = q16_milli(300);
          if (t - phase_t > lim.latency_steps) max_drag = q_max(max_drag, felt);
          if (t - phase_t > SIM_HZ * 2 && clicks == 0) {
            // Stiff and not turning: pulling too hard.
            work_t = q_max(q16_milli(150), work_t - q16_milli(30));
            ++rep.retries;
            go(Ph::travel, t);
          } else if (clicks > 12) {
            // More than a full turn without dropping in: it was not the bound ring.
            ++rep.retries;
            next(t);
          }
          break;
        case Ph::escape:
          // Ease the pull for a moment and turn on past the notch.
          target_t = q_max(q16_milli(100), work_t - q16_milli(130));
          rot = q16_milli(300);
          if (t - phase_t > SIM_HZ / 2) go(Ph::turn, t);
          break;
        case Ph::wait_open:
          if (t - phase_t > lim.latency_steps + SIM_HZ / 2) {
            for (auto& b : believed) b = 0;
            ++rep.retries;
            next(t);
          }
          break;
      }
      if (rep.retries > lim.max_retries) {
        rep.reason = "feel: too many retries";
        break;
      }
      hand_t = bot_approach(hand_t, target_t, lim.tension_rate);
      hand_d = bot_approach(hand_d, target_d, lim.depth_rate);
      if (t % lim.noise_period_steps == 0) noise_t = rng.range(-lim.tension_noise, lim.tension_noise);
      InputFrame in;
      in.tension = hand_t + noise_t;
      in.pick_depth = hand_d;
      in.rotate = hand_d == depth ? rot : 0;
      in = quantize(in);
      const StepOutput& out = session.step(in);
      last_drag = out.pick_drag;
      if (opt.record_inputs) rep.inputs.push_back(in);
      for (const auto& e : out.events) {
        perceived.push_back(e);
        if (e.sub == 0 && e.kind == EventKind::drop) ++rep.drops;
        if (e.sub == 0 && e.kind == EventKind::false_set) ++rep.false_sets;
      }
      if (session.finished()) break;
    }
    return finish(session, rep, "feel");
  }

  static SolveReport finish(const LockSession& session, SolveReport rep, const char* who) {
    rep.steps = session.t_step();
    rep.event_hash = session.event_hash();
    rep.peak_stress = session.state().tool.peak_ratio();
    rep.ok = session.is_open();
    if (!rep.ok && rep.reason.empty()) rep.reason = std::string(who) + ": step budget exhausted";
    if (rep.ok) rep.reason.clear();
    return rep;
  }
};

}  // namespace

std::unique_ptr<FamilyModule> make_module() { return std::make_unique<Module>(); }

}  // namespace lockcore::ring
