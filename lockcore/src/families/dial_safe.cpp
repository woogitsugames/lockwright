// Dial safe with a wheel pack (dial_safe.hpp, docs/LOCKS.md §2.18).
//
// Positions are unwrapped Q16 turns in int64 (the dial can turn many times). The
// dial drives wheel n-1, wheel i+1 drives wheel i; each link has LOST_MOTION of
// slack on both sides, so a carried wheel sits exactly half a turn behind its
// driver and its reading wrap(w + links/2) equals the dial reading. One pass of
// drag_chain() after a monotone dial move is exact.
//
// Listening: with the handle pressed inside [band_lo, band_hi] the fence rests
// on the pack and the gate of the lowest moving wheel (the one picked up last)
// is heard: near_shear before its gate, gate_align in the window, false_set in a
// false notch; when that wheel comes to rest in its gate, `set`. Above band_hi
// the pack clamps and the dial does not turn. Picking up a wheel that rested in a
// notch is a `drop`. All wheels resting in their gates + dial on the opening
// mark + handle pressed -> safe.fence_drop, then `open` after open_hold_steps.
#include "lockcore/dial_safe.hpp"

#include <algorithm>
#include <deque>

#include "lockcore/bot.hpp"
#include "lockcore/hash.hpp"
#include "lockcore/lockfile.hpp"
#include "lockcore/session.hpp"

namespace lockcore::dial {

namespace {

using json::Value;
constexpr std::int64_t H = LOST_MOTION;
constexpr std::int64_t TURN = Q16_ONE;

q16 wrap(std::int64_t v) {
  v %= TURN;
  if (v < 0) v += TURN;
  return static_cast<q16>(v);
}
// Shortest signed distance from a to b on the circle, in [-1/2, 1/2).
std::int64_t sdelta(std::int64_t a, std::int64_t b) {
  std::int64_t d = static_cast<std::int64_t>(wrap(b - a));
  return d >= TURN / 2 ? d - TURN : d;
}
q16 cdist(std::int64_t a, std::int64_t b) {
  const std::int64_t d = sdelta(a, b);
  return static_cast<q16>(d < 0 ? -d : d);
}
// Forward (dir = +1) or backward (dir = -1) distance from a to b on the circle.
q16 ddist(std::int64_t a, std::int64_t b, int dir) { return dir > 0 ? wrap(b - a) : wrap(a - b); }
std::int32_t nearest_digit(q16 reading, std::int32_t divisions) {
  return static_cast<std::int32_t>(((static_cast<std::int64_t>(reading) * divisions + Q16_ONE / 2) >> 16) % divisions);
}
// A wheel k links behind the dial sits k half-turns from it when carried, so its
// number (what the dial showed when it was left) is wrap(w + k * H).
q16 wheel_reading(std::int64_t w, int links) { return wrap(w + static_cast<std::int64_t>(links) * H); }

void drag_chain(std::int64_t dial, std::vector<std::int64_t>& w) {
  std::int64_t driver = dial;
  for (std::size_t k = w.size(); k-- > 0;) {
    if (w[k] < driver - H) w[k] = driver - H;
    else if (w[k] > driver + H) w[k] = driver + H;
    driver = w[k];
  }
}

// Dial position at which wheel i starts to move when the dial turns in `dir`.
std::int64_t pickup_point(std::int64_t dial, const std::vector<std::int64_t>& w, int i, int dir) {
  const int n = static_cast<int>(w.size());
  std::int64_t p = dial;
  for (int j = n - 1; j >= i; --j) {
    const std::int64_t reach = static_cast<std::int64_t>(n - j) * H;
    p = dir > 0 ? std::max(p, w[static_cast<std::size_t>(j)] + reach) : std::min(p, w[static_cast<std::size_t>(j)] - reach);
  }
  return p;
}

// Positions handed over: the dial on dial_start, each wheel showing `start`, every
// link within its slack.
void initial_positions(const Params& P, std::int64_t& dial, std::vector<std::int64_t>& w) {
  dial = P.digit_pos(P.dial_start);
  w.assign(P.wheels.size(), 0);
  std::int64_t driver = dial;
  for (std::size_t k = w.size(); k-- > 0;) {
    const std::int64_t r = static_cast<std::int64_t>(P.digit_pos(P.wheels[k].start)) - static_cast<std::int64_t>(w.size() - k) * H;
    std::int64_t off = sdelta(driver, r);  // [-1/2, 1/2)
    w[k] = driver + off;
    driver = w[k];
  }
}

enum class Pos : std::uint8_t { off, gate, false_gate };
Pos positional(const Params& P, std::size_t i, q16 reading) {
  const Wheel& k = P.wheels[i];
  if (cdist(reading, P.digit_pos(k.gate)) * 2 <= P.gate_win) return Pos::gate;
  for (std::int32_t f : k.false_gates)
    if (cdist(reading, P.digit_pos(f)) * 2 <= P.gate_win) return Pos::false_gate;
  return Pos::off;
}

struct WheelState {
  std::int64_t w = 0;
  ElementState st = ElementState::free;
  bool moving = false;
  int last_dir = 0;
  std::int32_t rest_steps = 1 << 20;
  bool near = false, in_gate = false, in_false = false;
  bool left = false;  // came to rest as the listened wheel (only such a wheel can be lost: drop)
};

struct State : FamilyState {
  std::shared_ptr<const Params> params;
  MaterialId material = MaterialId::steel;
  std::int64_t dial = 0;
  std::vector<WheelState> wheels;
  int last_dir = 0;
  int lowest_moving = -1;
  int listened = -1;
  bool jam = false;
  bool fence_down = false;
  bool bounce_armed = true;
  std::int32_t hold = 0;
  q16 tension = 0;
  q16 lift = 0;
  q16 resistance = 0;
  q16 drag = 0;
};

const Params& params_of(const LockSpec& spec) { return static_cast<const Params&>(*spec.params); }

struct Targets {
  std::vector<std::int64_t> dial;  // per wheel, then the opening mark
  std::vector<int> dir;
  std::string error;
};

// The textbook sequence (oracle, scripted bot): wheel 0 to the right, then
// alternate; every stop must leave >= 2 divisions before the next pickup.
Targets plan_targets(const Params& P) {
  Targets out;
  const int n = static_cast<int>(P.wheels.size());
  std::int64_t d = 0;
  std::vector<std::int64_t> w;
  initial_positions(P, d, w);
  const std::int64_t margin = 2 * static_cast<std::int64_t>(P.division());
  for (int i = 0; i <= n; ++i) {
    const int dir = (i % 2 == 0) ? 1 : -1;
    const bool mark = i == n;
    const std::int64_t start = mark ? d : pickup_point(d, w, i, dir);
    const q16 goal = P.digit_pos(mark ? P.open_mark : P.wheels[static_cast<std::size_t>(i)].gate);
    const std::int64_t target = start + dir * static_cast<std::int64_t>(ddist(start, goal, dir));
    const int guard = mark ? n - 1 : i - 1;
    if (guard >= 0) {
      const std::int64_t q = pickup_point(d, w, guard, dir);
      if (dir * (q - target) < margin) {
        out.error = mark ? "opening mark too close to the last number" : "number of wheel " + std::to_string(i) + " too close to the previous one";
        return out;
      }
    }
    d = target;
    drag_chain(d, w);
    out.dial.push_back(target);
    out.dir.push_back(dir);
  }
  for (int i = 0; i < n; ++i) {
    if (positional(P, static_cast<std::size_t>(i), wheel_reading(w[static_cast<std::size_t>(i)], n - i)) != Pos::gate) {
      out.error = "sequence does not leave wheel " + std::to_string(i) + " on its gate";
      return out;
    }
  }
  return out;
}

class Module final : public FamilyModule {
 public:
  std::string_view id() const override { return FAMILY_ID; }
  std::int32_t rules_version() const override { return RULES_VERSION; }
  std::uint32_t input_mask() const override { return AXIS_TENSION | AXIS_LIFT; }
  ToolSet required_tools(const LockSpec&) const override { return ToolSet{TOOL_LISTENING_CUP}; }

  int min_tier() const override { return 1; }
  int max_tier() const override { return 3; }

  DifficultyVector difficulty_for_tier(int tier) const override {
    // new-families.md §1: 2 -> 4 wheels, 20 -> 40 divisions, listening band
    // narrows around 0.40, false notches from t2 (sec = per wheel).
    const int t = std::clamp(tier, 1, 3);
    DifficultyVector d;
    d.tier = t;
    d.n_min = t == 1 ? 2 : 3;
    d.n_max = t == 1 ? 2 : (t == 2 ? 3 : 4);
    d.sec_min = t == 3 ? 1 : 0;
    d.sec_max = t == 1 ? 0 : 1;
    const std::int32_t divs = 10 + 10 * t;
    d.win_shear = q16_ratio(t == 3 ? 12 : 24, static_cast<std::int64_t>(divs) * 10);  // +-1.2 / +-0.6 divisions
    d.tension_band = q16_milli(t == 1 ? 400 : (t == 2 ? 300 : 220));
    d.overset_margin = 0;
    d.noise = q16_milli(t == 1 ? 100 : (t == 2 ? 300 : 450));
    d.bind_spread = Q16_ONE;
    d.drop_grace_ms = 0;
    d.s_max = Q16_ONE;  // unused
    d.time_limit_s = t == 1 ? 120 : (t == 2 ? 150 : 180);
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
    if (spec.family != FAMILY_ID) e.push_back({"family", "not dial_safe"});
    const auto* pp = dynamic_cast<const Params*>(spec.params.get());
    if (pp == nullptr) {
      e.push_back({"spec", "missing or foreign parameters"});
      return e;
    }
    const Params& P = *pp;
    const int n = static_cast<int>(P.wheels.size());
    if (n < 1 || n > 6) e.push_back({"spec.wheels", "need 1..6 wheels"});
    if (P.divisions < 8 || P.divisions > 100) e.push_back({"spec.divisions", "need 8..100"});
    const q16 div = P.division();
    auto digit_ok = [&](std::int32_t v) { return v >= 0 && v < P.divisions; };
    if (!digit_ok(P.dial_start)) e.push_back({"spec.dial_start", "out of range"});
    if (!digit_ok(P.open_mark)) e.push_back({"spec.open_mark", "out of range"});
    if (P.gate_win <= 0 || P.gate_win >= Q16_ONE / 4) e.push_back({"spec.gate_win_q16", "need 0 < gate_win < 1/4 turn"});
    if (P.band_lo <= 0 || P.band_hi <= P.band_lo || P.band_hi > Q16_ONE)
      e.push_back({"spec.band_lo_q16", "need 0 < band_lo < band_hi <= 1"});
    if (P.open_hold_steps < 1) e.push_back({"spec.open_hold_steps", "must be >= 1"});
    if (P.gate_feel < 0 || P.gate_feel > Q16_ONE) e.push_back({"spec.gate_feel_q16", "out of range"});
    if (P.rot_speed <= 0 || P.rot_speed >= div / 2 || P.snap_speed <= 0 || P.snap_speed >= div / 2)
      e.push_back({"spec.rot_speed_q16", "speeds must be > 0 and below half a division per step"});
    for (int i = 0; i < n; ++i) {
      const Wheel& k = P.wheels[static_cast<std::size_t>(i)];
      const std::string path = "spec.wheels[" + std::to_string(i) + "]";
      if (!digit_ok(k.gate)) e.push_back({path + ".gate", "out of range"});
      if (!digit_ok(k.start)) e.push_back({path + ".start", "out of range"});
      for (std::int32_t g : k.false_gates)
        if (!digit_ok(g) || g == k.gate) e.push_back({path + ".false_gates", "number out of range or on the gate"});
    }
    return e;
  }

  std::unique_ptr<FamilyState> init_state(const LockSpec& spec) const override {
    auto s = std::make_unique<State>();
    s->params = std::static_pointer_cast<const Params>(spec.params);
    s->material = spec.material;
    const Params& P = *s->params;
    std::vector<std::int64_t> w;
    initial_positions(P, s->dial, w);
    s->wheels.resize(w.size());
    for (std::size_t i = 0; i < w.size(); ++i) {
      s->wheels[i].w = w[i];
      s->wheels[i].st = rest_state(positional(P, i, wheel_reading(w[i], static_cast<int>(w.size() - i))));
    }
    s->tool.init(Q16_ONE, 0, Q16_ONE);  // never loaded
    return s;
  }

  void step(FamilyState& base, const InputFrame& in, StepCtx& ctx) const override {
    State& S = static_cast<State&>(base);
    const Params& P = *S.params;
    EventSink& out = *ctx.events;
    const std::int64_t t = ctx.t_step;
    const int n = static_cast<int>(P.wheels.size());
    const q16 T = in.tension;
    const bool stiff = T > P.band_hi;
    const bool listen = T >= P.band_lo && !stiff;
    const q16 mag = q_abs(in.pick_lift) < LIFT_DEADZONE ? 0 : q_abs(in.pick_lift);
    S.tension = T;
    S.lift = in.pick_lift;

    // Dial motion: turned by the thumb, or pulled onto the nearest division.
    std::int64_t delta = 0;
    q16 drag = 0;
    if (mag > 0) {
      if (stiff) drag = mag;
      else delta = (in.pick_lift > 0 ? 1 : -1) * static_cast<std::int64_t>(q_mul(mag, P.rot_speed));
    } else if (!stiff) {
      const q16 target = P.digit_pos(nearest_digit(wrap(S.dial), P.divisions));
      const std::int64_t to = sdelta(S.dial, target);
      delta = std::clamp<std::int64_t>(to, -P.snap_speed, P.snap_speed);
    }
    S.jam = stiff && mag > 0;
    const std::int32_t old_digit = nearest_digit(wrap(S.dial), P.divisions);
    S.dial += delta;
    if (delta != 0) S.last_dir = delta > 0 ? 1 : -1;
    std::vector<std::int64_t> w(static_cast<std::size_t>(n));
    for (int i = 0; i < n; ++i) w[static_cast<std::size_t>(i)] = S.wheels[static_cast<std::size_t>(i)].w;
    drag_chain(S.dial, w);

    int carried = 0, lowest = -1;
    for (int i = n - 1; i >= 0; --i) {
      if (w[static_cast<std::size_t>(i)] != S.wheels[static_cast<std::size_t>(i)].w) {
        ++carried;
        lowest = i;
      }
    }
    if (nearest_digit(wrap(S.dial), P.divisions) != old_digit) {
      const q16 click = q16_milli(150) + q16_milli(50) * carried;
      out.emit(t, EventKind::contact, -1, q_mul(click, q16_milli(500) + P.gate_feel / 2), S.material, SUB_DETENT);
    }

    // Wheels joining or leaving the carried pack.
    for (int i = n - 1; i >= 0; --i) {
      WheelState& ws = S.wheels[static_cast<std::size_t>(i)];
      const std::int64_t nw = w[static_cast<std::size_t>(i)];
      const bool moved = nw != ws.w;
      const int mdir = nw > ws.w ? 1 : -1;
      if (moved && !ws.moving) {
        if (ws.left && (ws.st == ElementState::set || ws.st == ElementState::false_set))
          out.emit(t, EventKind::drop, i, q16_ratio(1, n), S.material);
        ws.left = false;
        if (ws.last_dir != mdir || ws.rest_steps >= PICKUP_QUIET_STEPS)
          out.emit(t, EventKind::bind, i, q16_milli(350) + q16_milli(80) * (n - 1 - i), S.material, SUB_PICKUP);
      }
      const bool stopped = !moved && ws.moving;
      ws.w = nw;
      ws.moving = moved;
      if (moved) {
        ws.last_dir = mdir;
        ws.rest_steps = 0;
        ws.st = ElementState::bound;
      } else if (ws.rest_steps < (1 << 20)) {
        ++ws.rest_steps;
      }
      const q16 reading = wheel_reading(nw, n - i);
      const Pos pos = positional(P, static_cast<std::size_t>(i), reading);
      if (moved) {
        // Listening only reaches the wheel picked up last.
        const q16 dist = cdist(reading, P.digit_pos(P.wheels[static_cast<std::size_t>(i)].gate));
        const bool near = dist <= P.gate_win / 2 + 2 * P.division();
        const bool hear = listen && i == lowest;
        if (pos == Pos::gate && !ws.in_gate && hear) out.emit(t, EventKind::gate_align, i, P.gate_feel, S.material);
        else if (near && !ws.near && hear) out.emit(t, EventKind::near_shear, i, P.gate_feel / 2, S.material);
        if (pos == Pos::false_gate && !ws.in_false && hear)
          out.emit(t, EventKind::false_set, i, q16_milli(150) + q_mul(P.gate_feel, q16_milli(300)), S.material);
        ws.near = near;
      } else {
        ws.st = rest_state(pos);
        if (stopped && i == S.lowest_moving) ws.left = true;
        if (stopped && i == S.lowest_moving && listen) {
          if (pos == Pos::gate) out.emit(t, EventKind::set, i, q16_milli(400) + q_mul(P.gate_feel, q16_milli(500)), S.material);
          else if (pos == Pos::false_gate)
            out.emit(t, EventKind::false_set, i, q16_milli(250) + q_mul(P.gate_feel, q16_milli(300)), S.material);
        }
        ws.near = false;
      }
      ws.in_gate = pos == Pos::gate;
      ws.in_false = pos == Pos::false_gate;
    }
    S.lowest_moving = lowest;

    // The wheel the fence listens to: the lowest one engaged in the last direction.
    S.listened = -1;
    if (S.last_dir != 0) {
      std::int64_t driver = S.dial;
      for (int i = n - 1; i >= 0; --i) {
        const std::int64_t wi = S.wheels[static_cast<std::size_t>(i)].w;
        if (driver - wi != S.last_dir * H) break;
        S.listened = i;
        driver = wi;
      }
    }

    // Opening: every wheel resting in its gate, dial on the mark, handle pressed.
    const bool all_set = std::all_of(S.wheels.begin(), S.wheels.end(), [](const WheelState& x) { return x.st == ElementState::set; });
    const bool at_mark = cdist(S.dial, P.digit_pos(P.open_mark)) * 2 <= q_max(P.gate_win, P.division());
    const bool pressed = T >= P.band_lo;
    if (all_set && at_mark && pressed) {
      if (!S.fence_down) {
        S.fence_down = true;
        out.emit(t, EventKind::set, -1, q16_milli(600) + q_mul(P.gate_feel, q16_milli(400)), S.material, SUB_FENCE_DROP);
      }
      ++S.hold;
      if (!S.open && S.hold >= P.open_hold_steps) {
        S.open = true;
        out.emit(t, EventKind::open, -1, Q16_ONE, S.material);
      }
    } else {
      S.fence_down = false;
      S.hold = 0;
    }
    if (!all_set && at_mark && pressed && mag == 0 && S.bounce_armed) {
      out.emit(t, EventKind::contact, -1, q16_milli(500), S.material, SUB_FENCE_BOUNCE);
      S.bounce_armed = false;
    }
    if (!at_mark || !pressed) S.bounce_armed = true;

    if (!S.jam && delta != 0 && mag > 0) drag = q_min(Q16_ONE, q16_milli(40) + q16_milli(60) * carried);
    q16 res;
    if (S.fence_down) res = q_mul(T, q16_milli(300));
    else if (!pressed) res = T / 4;
    else if (stiff) res = T;
    else if (S.listened >= 0 && S.wheels[static_cast<std::size_t>(S.listened)].in_gate) res = T / 2;  // the handle gives
    else res = q_mul(T, q16_milli(800));
    S.resistance = res;
    S.drag = drag;
    ctx.tension_resistance = res;
    ctx.pick_drag = drag;
  }

  ViewModel describe(const FamilyState& base) const override {
    const State& S = static_cast<const State&>(base);
    const Params& P = *S.params;
    ViewModel v;
    for (std::size_t i = 0; i < S.wheels.size(); ++i) {
      const WheelState& ws = S.wheels[i];
      ElementView e;
      e.state = ws.st;
      if (ws.moving && ws.near && static_cast<int>(i) == S.lowest_moving) e.state = ElementState::near;
      if (S.jam && S.listened >= 0 && static_cast<int>(i) >= S.listened) e.state = ElementState::jammed;
      e.position = wheel_reading(ws.w, static_cast<int>(S.wheels.size() - i));  // fraction of a turn; number = position * divisions
      const q16 g = P.digit_pos(P.wheels[i].gate);
      e.window_lo = g - P.gate_win / 2;  // may wrap below 0 for number 0
      e.window_hi = g + P.gate_win / 2;
      e.variant = static_cast<std::uint8_t>(P.wheels[i].false_gates.size());
      v.elements.push_back(e);
    }
    v.pick_element = S.listened;
    v.pick_lift = S.lift;
    v.tension = S.tension;
    v.hold_progress = S.open ? Q16_ONE : (S.fence_down ? q16_ratio(S.hold, P.open_hold_steps) : 0);
    v.core_rotation = v.hold_progress;  // bolt travel
    v.tension_resistance = S.resistance;
    v.pick_drag = S.drag;
    v.stress = 0;
    v.open = S.open;
    v.failure = S.failure;
    v.dial = wrap(S.dial);
    v.dial_divisions = P.divisions;
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
    if (P.band_hi - P.band_lo < HUMAN_TENSION_BAND) {
      r.reason = "listening band narrower than delta_human";
      return r;
    }
    if (P.gate_win < P.division()) {
      r.reason = "gate window below one division";
      return r;
    }
    const Targets tg = plan_targets(P);
    if (!tg.error.empty()) {
      r.reason = tg.error;
      return r;
    }
    r.min_band = P.band_hi - P.band_lo;
    r.min_window = P.gate_win;
    for (std::size_t i = 0; i < tg.dial.size(); ++i) {
      PlanStep st;
      st.element = static_cast<int>(i);  // == wheels.size(): the opening mark
      st.depth = 0;
      st.tension = (P.band_lo + P.band_hi) / 2;
      st.approach_from = static_cast<q16>(tg.dial[i]);  // unwrapped dial target (turns, Q16)
      st.lift_cap = tg.dir[i] * Q16_ONE;               // turning direction
      r.plan.steps.push_back(st);
    }
    r.plan.release_tension = 0;
    r.plan.t_hold = P.band_lo;
    r.plan.drop_all = false;
    r.ok = true;
    return r;
  }

  SolveReport solver(const LockSpec& spec, const ToolSet& tools, const SolveOptions& opt) const override {
    return run_bot(BotKind::scripted, spec, tools, opt);
  }

  SolveReport run_bot(BotKind kind, const LockSpec& spec, const ToolSet& tools, const SolveOptions& opt) const override {
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
      case BotKind::clumsy:
      case BotKind::heavy:  // the tool is never loaded here: nothing for a heavy hand to break (D-118)
        return plan_bot(spec, tools, o.plan, clumsy_human_limits(), full, opt, true);
      case BotKind::feeling: return feel_bot(spec, tools, feeling_human_limits(), full, opt);
    }
    return {};
  }

  Value params_to_json(const FamilyParams& fp) const override {
    const Params& P = static_cast<const Params&>(fp);
    Value o = Value::object();
    o.set("divisions", Value::integer(P.divisions));
    o.set("dial_start", Value::integer(P.dial_start));
    o.set("open_mark", Value::integer(P.open_mark));
    o.set("gate_win_q16", Value::integer(P.gate_win));
    o.set("band_lo_q16", Value::integer(P.band_lo));
    o.set("band_hi_q16", Value::integer(P.band_hi));
    o.set("open_hold_steps", Value::integer(P.open_hold_steps));
    o.set("gate_feel_q16", Value::integer(P.gate_feel));
    o.set("rot_speed_q16", Value::integer(P.rot_speed));
    o.set("snap_speed_q16", Value::integer(P.snap_speed));
    Value arr = Value::array();
    for (const Wheel& k : P.wheels) {
      Value wo = Value::object();
      wo.set("gate", Value::integer(k.gate));
      wo.set("start", Value::integer(k.start));
      Value fg = Value::array();
      for (std::int32_t g : k.false_gates) fg.push(Value::integer(g));
      wo.set("false_gates", std::move(fg));
      arr.push(std::move(wo));
    }
    o.set("wheels", std::move(arr));
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
    i32(v, "divisions", 1, 1000, P->divisions, path);
    i32(v, "dial_start", 0, 999, P->dial_start, path);
    i32(v, "open_mark", 0, 999, P->open_mark, path);
    q(v, "gate_win_q16", P->gate_win, path);
    q(v, "band_lo_q16", P->band_lo, path);
    q(v, "band_hi_q16", P->band_hi, path);
    i32(v, "open_hold_steps", 1, 100000, P->open_hold_steps, path);
    q(v, "gate_feel_q16", P->gate_feel, path);
    q(v, "rot_speed_q16", P->rot_speed, path);
    q(v, "snap_speed_q16", P->snap_speed, path);
    const Value* arr = v.find("wheels");
    if (arr == nullptr || !arr->is_array()) {
      errors.push_back({path + ".wheels", "expected array"});
      return P;
    }
    for (std::size_t i = 0; i < arr->items().size(); ++i) {
      const Value& wo = arr->items()[i];
      const std::string wp = path + ".wheels[" + std::to_string(i) + "]";
      if (!wo.is_object()) {
        errors.push_back({wp, "expected object"});
        continue;
      }
      Wheel k;
      i32(wo, "gate", 0, 999, k.gate, wp);
      i32(wo, "start", 0, 999, k.start, wp);
      const Value* fg = wo.find("false_gates");
      if (fg == nullptr || !fg->is_array()) {
        errors.push_back({wp + ".false_gates", "expected array"});
      } else {
        for (const Value& g : fg->items()) {
          if (!g.is_int() || g.as_int() < 0 || g.as_int() > 999) {
            errors.push_back({wp + ".false_gates", "expected numbers"});
            break;
          }
          k.false_gates.push_back(static_cast<std::int32_t>(g.as_int()));
        }
      }
      P->wheels.push_back(std::move(k));
    }
    return P;
  }

  std::string_view event_name(std::uint16_t sub) const override {
    switch (sub) {
      case SUB_DETENT: return "safe.detent";
      case SUB_PICKUP: return "safe.pickup";
      case SUB_FENCE_DROP: return "safe.fence_drop";
      case SUB_FENCE_BOUNCE: return "safe.fence_bounce";
      default: return {};
    }
  }

 private:
  static ElementState rest_state(Pos p) {
    return p == Pos::gate ? ElementState::set : (p == Pos::false_gate ? ElementState::false_set : ElementState::free);
  }

  LockSpec generate_once(std::uint64_t seed, std::uint32_t attempt, const DifficultyVector& d) const {
    Pcg32 rng(derive_seed(seed ^ splitmix64(attempt), FAMILY_ID, RULES_VERSION, "gen"), derive_stream(FAMILY_ID, "gen"));
    auto P = std::make_shared<Params>();
    const int n = rng.range(d.n_min, d.n_max);
    P->divisions = 10 + 10 * std::clamp(d.tier, 1, 9);
    P->gate_win = d.win_shear;
    P->band_lo = q_max(q16_milli(50), q16_milli(400) - d.tension_band / 2);
    P->band_hi = q_min(Q16_ONE, P->band_lo + d.tension_band);
    P->open_hold_steps = OPEN_HOLD_STEPS;
    P->gate_feel = q_clamp(Q16_ONE - d.noise, 0, Q16_ONE);
    P->rot_speed = ROT_SPEED;
    P->snap_speed = SNAP_SPEED;
    P->open_mark = 0;
    P->dial_start = rng.range(0, P->divisions - 1);
    const std::int32_t D = P->divisions;
    const std::int32_t margin = (D + 4) / 5;  // GATE_MARGIN in divisions, rounded up
    auto ddig = [&](std::int32_t a, std::int32_t b) {
      const std::int32_t x = ((a - b) % D + D) % D;
      return std::min(x, D - x);
    };
    P->wheels.resize(static_cast<std::size_t>(n));
    for (int i = 0; i < n; ++i) {
      Wheel& k = P->wheels[static_cast<std::size_t>(i)];
      for (int tries = 0; tries < 32; ++tries) {
        k.gate = rng.range(0, D - 1);
        const bool prev_ok = i == 0 || ddig(k.gate, P->wheels[static_cast<std::size_t>(i - 1)].gate) >= margin;
        const bool mark_ok = i != n - 1 || ddig(k.gate, P->open_mark) >= margin;
        if (prev_ok && mark_ok) break;
      }
      const int fgs = rng.range(d.sec_min, d.sec_max);
      for (int f = 0; f < fgs; ++f) {
        for (int tries = 0; tries < 8; ++tries) {
          const std::int32_t g = rng.range(0, D - 1);
          if (ddig(g, k.gate) >= 3 && std::find(k.false_gates.begin(), k.false_gates.end(), g) == k.false_gates.end()) {
            k.false_gates.push_back(g);
            break;
          }
        }
      }
      std::sort(k.false_gates.begin(), k.false_gates.end());
      for (int tries = 0; tries < 16; ++tries) {
        k.start = rng.range(0, D - 1);
        bool ok = ddig(k.start, k.gate) >= 2;
        for (std::int32_t g : k.false_gates) ok = ok && ddig(k.start, g) >= 2;
        if (ok) break;
      }
    }
    LockSpec spec;
    spec.family = std::string(FAMILY_ID);
    spec.rules_version = RULES_VERSION;
    spec.id = "gen.dial_safe.t" + std::to_string(d.tier) + "." + std::to_string(seed);
    spec.source = "generated";
    spec.seed = seed;
    spec.difficulty = d;
    spec.material = MaterialId::steel;
    spec.params = P;
    return spec;
  }

  // Tracks the dial as a player sees it: the drawn number arrives `latency` steps
  // late; the player adds the turn their own thumb commanded since then.
  struct DialEye {
    std::deque<q16> seen;  // dial readings, oldest first
    std::deque<std::int64_t> moves;
    std::int64_t vis = 0;  // unwrapped estimate of the delayed reading
    q16 last = 0;
    std::int64_t predicted() const {
      std::int64_t p = vis;
      for (std::int64_t m : moves) p += m;
      return p;
    }
    void init(q16 dial0, std::int32_t latency) {
      seen.assign(static_cast<std::size_t>(latency), dial0);
      moves.assign(static_cast<std::size_t>(latency), 0);
      vis = dial0;
      last = dial0;
    }
    void push(q16 reading, std::int64_t commanded) {
      seen.push_back(reading);
      moves.push_back(commanded);
      const q16 r = seen.front();
      seen.pop_front();
      moves.pop_front();
      vis += sdelta(last, r);
      last = r;
    }
  };

  // Scripted bot (stage 2): the textbook sequence from the oracle, turning by the
  // drawn dial: fast, then one division per ~0.7 s for the last three divisions.
  SolveReport plan_bot(const LockSpec& spec, const ToolSet& tools, const Plan& plan, const HumanLimits& lim,
                       std::int64_t budget, const SolveOptions& opt, bool clumsy) const {
    const Params& P = params_of(spec);
    SolveReport rep;
    LockSession session(*this, spec, tools);
    Pcg32 rng(derive_seed(spec.seed ^ splitmix64(opt.bot_seed), FAMILY_ID, RULES_VERSION, "bot"), derive_stream(FAMILY_ID, "bot"));
    DialEye eye;
    eye.init(session.describe().dial, lim.latency_steps);
    std::size_t si = 0;
    std::int64_t still = 0;
    q16 hand_t = 0, noise_t = 0, noise_l = 0;
    const q16 fast = clumsy ? Q16_ONE : q16_milli(800);
    const q16 slow = q_max(LIFT_DEADZONE + LIFT_DEADZONE / 2, q_div(P.division(), P.rot_speed * SIM_HZ));
    const std::int64_t tol = P.division() / 16;
    const std::int64_t slow_zone = 3 * static_cast<std::int64_t>(P.division());
    for (std::int64_t t = 0; t < budget; ++t) {
      q16 lift = 0;
      const q16 target_t = plan.steps.empty() ? 0 : plan.steps.front().tension;
      if (si < plan.steps.size()) {
        const PlanStep& st = plan.steps[si];
        const int dir = st.lift_cap > 0 ? 1 : -1;
        const std::int64_t rem = dir * (static_cast<std::int64_t>(st.approach_from) - eye.predicted());
        if (rem > slow_zone) lift = dir * fast;
        else if (rem > tol) lift = dir * slow;
        if (lift == 0) {
          if (++still >= lim.min_hold_steps + lim.latency_steps) {
            ++si;
            still = 0;
          }
        } else {
          still = 0;
        }
      }
      hand_t = bot_approach(hand_t, target_t, lim.tension_rate);
      if (t % lim.noise_period_steps == 0) {
        noise_t = rng.range(-lim.tension_noise, lim.tension_noise);
        noise_l = rng.range(-lim.lift_noise, lim.lift_noise);
      }
      InputFrame in;
      in.tension = hand_t + noise_t;
      in.pick_lift = lift == 0 ? 0 : lift + noise_l;
      in = quantize(in);
      const q16 mag = q_abs(in.pick_lift) < LIFT_DEADZONE ? 0 : q_abs(in.pick_lift);
      const std::int64_t commanded = in.tension > P.band_hi ? 0 : (in.pick_lift > 0 ? 1 : -1) * static_cast<std::int64_t>(q_mul(mag, P.rot_speed));
      const StepOutput& out = session.step(in);
      eye.push(session.describe().dial, commanded);
      if (opt.record_inputs) rep.inputs.push_back(in);
      for (const auto& e : out.events) {
        if (e.sub != 0) continue;
        if (e.kind == EventKind::drop) ++rep.drops;
        if (e.kind == EventKind::false_set) ++rep.false_sets;
      }
      if (session.finished()) break;
      if (si >= plan.steps.size() && still == 0) still = 1;
      if (si >= plan.steps.size() && ++still > SIM_HZ * 2) {
        rep.reason = "bot: handle pressed on the mark but the fence did not drop";
        break;
      }
    }
    return finish(session, rep, "bot");
  }

  // Feeling bot (stage 3): knows the number of wheels and divisions (drawn) and
  // reads the dial; everything else from events. Per wheel: turn (right for wheel
  // 0, then alternating) until that wheel's pickup is heard, listen for its gate,
  // stop a little after gate_align, confirm with `set`. An overshoot that picks up
  // the previous wheel, or a missed confirmation, starts over from wheel 0.
  SolveReport feel_bot(const LockSpec& spec, const ToolSet& tools, const HumanLimits& lim, std::int64_t budget,
                       const SolveOptions& opt) const {
    SolveReport rep;
    LockSession session(*this, spec, tools);
    Pcg32 rng(derive_seed(spec.seed ^ splitmix64(opt.bot_seed), FAMILY_ID, RULES_VERSION, "feel"), derive_stream(FAMILY_ID, "feel"));
    const ViewModel v0 = session.describe();
    const int n = static_cast<int>(v0.elements.size());
    const std::int32_t D = v0.dial_divisions;
    const std::int64_t div = Q16_ONE / D;
    DialEye eye;
    eye.init(v0.dial, lim.latency_steps);
    std::deque<LockEvent> perceived;
    std::vector<std::int64_t> history;  // predicted dial per step (own memory)
    enum class Ph { pause, gather, seek, settle, mark, hold };
    Ph ph = Ph::pause;
    std::int64_t phase_t = 0;
    int wheel = 0, dir = 1;
    bool heard_prev = false;    // pickup of wheel+1 heard: own pickup is near
    std::int64_t pickup_at = 0;  // predicted dial when the wheel's pickup was heard
    std::int64_t stop_at = 0;
    bool slow_now = false, confirmed = false;
    q16 work_t = q16_milli(350), hand_t = 0, noise_t = 0, noise_l = 0, felt_drag = 0;
    // Speeds as dial lift: fast ~0.56 turn/s, seek ~9 divisions/s, slow ~1.5 divisions/s.
    const q16 rot_s = q16_milli(800);  // the player knows how fast the dial turns
    auto lift_for = [&](std::int64_t div_per_s) {
      return q_clamp(q16_ratio(div_per_s * Q16_ONE, static_cast<std::int64_t>(D) * rot_s), LIFT_DEADZONE + LIFT_DEADZONE / 2, Q16_ONE);
    };
    const q16 fast = q16_milli(700);
    const q16 seek = q_min(fast, lift_for(9));
    const q16 slow = lift_for(2);
    auto go = [&](Ph p, std::int64_t t) {
      ph = p;
      phase_t = t;
    };
    auto restart = [&](std::int64_t t) {
      wheel = 0;
      dir = 1;
      heard_prev = false;
      ++rep.retries;
      go(Ph::pause, t);
    };
    for (std::int64_t t = 0; t < budget; ++t) {
      while (!perceived.empty() && perceived.front().t_step <= t - lim.latency_steps) {
        const LockEvent e = perceived.front();
        perceived.pop_front();
        const std::int64_t at = e.t_step < static_cast<std::int64_t>(history.size()) ? history[static_cast<std::size_t>(e.t_step)] : eye.predicted();
        if (e.kind == EventKind::bind && e.sub == SUB_PICKUP) {
          if (ph == Ph::gather && e.element == wheel + 1) heard_prev = true;
          if (ph == Ph::gather && e.element == wheel) {
            pickup_at = at;
            slow_now = false;
            go(Ph::seek, t);
          } else if ((ph == Ph::seek || ph == Ph::settle) && e.element == wheel - 1) {
            restart(t);  // turned too far: the previous wheel came along
          } else if (ph == Ph::mark && e.element == n - 1) {
            restart(t);
          }
        } else if (e.sub == SUB_FENCE_BOUNCE && ph == Ph::hold) {
          restart(t);
        } else if (e.sub != 0) {
          continue;
        } else if (e.kind == EventKind::near_shear && e.element == wheel && ph == Ph::seek) {
          slow_now = true;
        } else if (e.kind == EventKind::gate_align && e.element == wheel && ph == Ph::seek) {
          // The gate starts half a window before its number: stop about 0.6
          // divisions past where the click was heard, on a whole number.
          const std::int64_t raw = at + dir * (div * 6 / 10) + div / 2;
          stop_at = (raw / div - (raw < 0 && raw % div != 0 ? 1 : 0)) * div;
          slow_now = true;
          go(Ph::settle, t);
          confirmed = false;
        } else if (e.kind == EventKind::set && e.element == wheel && ph == Ph::settle) {
          confirmed = true;
        }
      }
      felt_drag = 0;
      q16 lift = 0;
      switch (ph) {
        case Ph::pause:
          // Let the pack rest so every wheel clicks when it is picked up again.
          if (t - phase_t > PICKUP_QUIET_STEPS + lim.latency_steps) go(Ph::gather, t);
          break;
        case Ph::gather: {
          // The wheel's own pickup is near once the one before it was heard (or
          // right after a reversal for the wheel next to the dial).
          lift = dir * (heard_prev || (wheel == n - 1 && wheel > 0) ? seek : fast);
          if (t - phase_t > SIM_HZ * 20) restart(t);
          break;
        }
        case Ph::seek: {
          lift = dir * (slow_now ? slow : seek);
          // More than a full turn without a gate: the handle is not in the band.
          if (dir * (eye.predicted() - pickup_at) > Q16_ONE + Q16_ONE / 8) {
            work_t = work_t + q16_milli(40) > q16_milli(700) ? q16_milli(250) : work_t + q16_milli(40);
            if (wheel == 0) {
              pickup_at = eye.predicted();
            } else {
              restart(t);
            }
          }
          break;
        }
        case Ph::settle: {
          const std::int64_t rem = dir * (stop_at - eye.predicted());
          if (rem > div / 16) {
            lift = dir * slow;
            phase_t = t;
          } else if (confirmed) {
            ++wheel;
            dir = -dir;
            heard_prev = false;
            go(wheel == n ? Ph::mark : Ph::gather, t);
          } else if (t - phase_t > lim.latency_steps + PICKUP_QUIET_STEPS) {
            // Stopped, but no `set`: missed the gate.
            if (wheel == 0) {
              slow_now = false;
              pickup_at = eye.predicted();
              go(Ph::seek, t);
            } else {
              restart(t);
            }
          }
          break;
        }
        case Ph::mark: {
          const std::int64_t mark = 0;  // the opening mark is drawn at 0
          const std::int64_t p = eye.predicted();
          const std::int64_t rem = dir > 0 ? static_cast<std::int64_t>(wrap(mark - p)) : static_cast<std::int64_t>(wrap(p - mark));
          const std::int64_t remc = rem > Q16_ONE - div / 4 ? 0 : rem;
          if (remc > 3 * div) lift = dir * seek;
          else if (remc > div / 16) lift = dir * slow;
          else if (t - phase_t > 0) go(Ph::hold, t);
          break;
        }
        case Ph::hold:
          if (t - phase_t > SIM_HZ * 2) restart(t);
          break;
      }
      if (rep.retries > lim.max_retries) {
        rep.reason = "feel: too many retries";
        break;
      }
      hand_t = bot_approach(hand_t, work_t, lim.tension_rate);
      if (t % lim.noise_period_steps == 0) {
        noise_t = rng.range(-lim.tension_noise, lim.tension_noise);
        noise_l = rng.range(-lim.lift_noise, lim.lift_noise);
      }
      InputFrame in;
      in.tension = hand_t + noise_t;
      in.pick_lift = lift == 0 ? 0 : lift + noise_l;
      in = quantize(in);
      const q16 mag = q_abs(in.pick_lift) < LIFT_DEADZONE ? 0 : q_abs(in.pick_lift);
      const std::int64_t commanded = (in.pick_lift > 0 ? 1 : -1) * static_cast<std::int64_t>(q_mul(mag, q16_per_step(rot_s)));
      const StepOutput& out = session.step(in);
      // A stiff dial: the bot feels it under the thumb and eases the handle.
      felt_drag = out.pick_drag;
      if (felt_drag >= q16_milli(500)) work_t = q_max(q16_milli(150), work_t - q16_milli(2));
      eye.push(session.describe().dial, felt_drag >= q16_milli(500) ? 0 : commanded);
      history.push_back(eye.predicted());
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

}  // namespace lockcore::dial
