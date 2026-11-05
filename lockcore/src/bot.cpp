#include "lockcore/bot.hpp"

#include <algorithm>
#include <deque>

#include "lockcore/hash.hpp"
#include "lockcore/session.hpp"

namespace lockcore {

namespace {

q16 approach(q16 cur, q16 target, q16 rate) {
  if (cur < target) return q_min(cur + rate, target);
  return q_max(cur - rate, target);
}

enum class Phase { lower, travel, fast, slow, spool, release, reset };

}  // namespace

SolveReport run_plan_bot(const FamilyModule& family, const LockSpec& spec, const ToolSet& tools,
                         const Plan& plan, const HumanLimits& lim, std::int64_t budget_steps,
                         const SolveOptions& opt) {
  SolveReport rep;
  if (plan.steps.empty()) {
    rep.reason = "empty plan";
    return rep;
  }
  LockSession session(family, spec, tools);
  Pcg32 rng(derive_seed(spec.seed ^ splitmix64(opt.bot_seed), family.id(),
                        static_cast<std::uint32_t>(family.rules_version()), "bot"),
            derive_stream(family.id(), "bot"));

  int n_elem = 0;
  for (const auto& s : plan.steps) n_elem = s.element + 1 > n_elem ? s.element + 1 : n_elem;
  std::vector<char> believed(static_cast<std::size_t>(n_elem), 0);
  std::vector<int> set_order;
  std::deque<LockEvent> perceived;  // events waiting for the reaction latency

  Phase ph = Phase::lower;
  std::int64_t phase_t = 0;
  std::int64_t mark_t = -1;  // dwell / cap timer
  q16 hand_t = 0, hand_d = plan.steps.front().depth, hand_l = 0;
  q16 noise_t = 0, noise_l = 0;
  std::int64_t all_set_since = -1;
  const q16 tol = q16_milli(10);
  q16 slow_rate = lim.slow_rate;
  q16 fine_rate = lim.fine_rate;
  bool felt_near = false;
  const bool can_reset = (family.input_mask() & AXIS_ROTATE) != 0;
  q16 hand_r = 0;

  auto go = [&](Phase p, std::int64_t t) {
    if (p != Phase::slow) felt_near = false;
    ph = p;
    phase_t = t;
    mark_t = -1;
  };
  auto current = [&]() -> int {
    for (std::size_t i = 0; i < plan.steps.size(); ++i) {
      if (!believed[static_cast<std::size_t>(plan.steps[i].element)]) return static_cast<int>(i);
    }
    return -1;
  };
  auto forget = [&](int e) {
    believed[static_cast<std::size_t>(e)] = 0;
    for (std::size_t i = 0; i < set_order.size(); ++i) {
      if (set_order[i] == e) {
        set_order.erase(set_order.begin() + static_cast<std::ptrdiff_t>(i));
        break;
      }
    }
  };

  for (std::int64_t t = 0; t < budget_steps; ++t) {
    // 1. Perceive events after the reaction latency.
    while (!perceived.empty() && perceived.front().t_step <= t - lim.latency_steps) {
      const LockEvent e = perceived.front();
      perceived.pop_front();
      const int ci = current();
      const int cur_elem = ci >= 0 ? plan.steps[static_cast<std::size_t>(ci)].element : -1;
      if (ph == Phase::reset && e.kind == EventKind::drop) {
        // Detector reset done (family event mapped on drop): every lever is loose.
        for (auto& b : believed) b = 0;
        set_order.clear();
        go(Phase::lower, t);
        continue;
      }
      if (e.sub != 0) continue;  // family flavour events (serration, rattle) are ignored
      if (e.kind == EventKind::detector_trip && can_reset) {
        ++rep.retries;
        go(Phase::reset, t);
        continue;
      }
      switch (e.kind) {
        case EventKind::set:
          if (e.element >= 0 && e.element < n_elem && !believed[static_cast<std::size_t>(e.element)]) {
            believed[static_cast<std::size_t>(e.element)] = 1;
            set_order.push_back(e.element);
            if (e.element == cur_elem && ph != Phase::release) go(Phase::lower, t);
          }
          break;
        case EventKind::false_set:
          if (e.element == cur_elem && ph != Phase::release) go(Phase::spool, t);
          break;
        case EventKind::near_shear:
          if (e.element == cur_elem) felt_near = true;
          break;
        case EventKind::overset:
          if (e.element >= 0 && e.element < n_elem) forget(e.element);
          if (lim.adaptive) {
            const q16 floor = q16_per_step(q16_milli(100));
            slow_rate = q_max(floor, slow_rate - slow_rate / 4);
            fine_rate = q_max(floor, fine_rate - fine_rate / 4);
          }
          go(Phase::release, t);
          break;
        case EventKind::drop:
          if (plan.drop_all) {
            for (auto& b : believed) b = 0;
            set_order.clear();
          } else if (!set_order.empty()) {
            forget(set_order.back());
          }
          if (ph != Phase::release) go(Phase::lower, t);
          break;
        default: break;
      }
    }

    // 2. Decide the intended hand position.
    const int ci = current();
    q16 target_t = hand_t, target_l = hand_l, target_d = hand_d;
    hand_r = 0;
    if (ph == Phase::reset) {
      target_t = 0;
      target_l = 0;
      if (hand_t == 0) hand_r = -Q16_ONE;
    } else if (ci < 0) {
      // Everything believed set: keep holding and wait for the open event.
      target_l = 0;
      if (all_set_since < 0) all_set_since = t;
      if (t - all_set_since > lim.latency_steps + 24) {
        // Beliefs are wrong (missed a drop); start over.
        for (auto& b : believed) b = 0;
        set_order.clear();
        ++rep.retries;
        all_set_since = -1;
        go(Phase::lower, t);
      }
    } else {
      all_set_since = -1;
      const PlanStep& st = plan.steps[static_cast<std::size_t>(ci)];
      switch (ph) {
        case Phase::lower:
          target_t = st.tension;
          target_l = 0;
          if (hand_l == 0 && t - phase_t >= lim.min_hold_steps) go(Phase::travel, t);
          break;
        case Phase::travel:
          target_t = st.tension;
          target_l = 0;
          target_d = st.depth;
          if (hand_d == st.depth && q_abs(hand_t - st.tension) <= tol && t - phase_t >= lim.min_hold_steps)
            go(Phase::fast, t);
          break;
        case Phase::fast:
          target_t = st.tension;
          target_d = st.depth;
          target_l = st.approach_from;
          if (hand_l >= st.approach_from) go(Phase::slow, t);
          break;
        case Phase::slow:
        case Phase::spool: {
          target_d = st.depth;
          const bool spool = ph == Phase::spool;
          target_t = spool ? st.cr_tension : st.tension;
          const q16 rate = spool ? lim.spool_rate : (felt_near ? q_min(fine_rate, slow_rate) : slow_rate);
          const bool tension_ready = !spool || q_abs(hand_t - st.cr_tension) <= tol;
          target_l = tension_ready ? q_min(hand_l + rate, st.lift_cap) : hand_l;
          if (hand_l >= st.lift_cap) {
            if (mark_t < 0) mark_t = t;
            if (t - mark_t > lim.latency_steps + lim.min_hold_steps) {
              ++rep.retries;
              go(Phase::lower, t);
            }
          }
          break;
        }
        case Phase::release:
          target_t = plan.release_tension;
          target_l = 0;
          if (hand_t <= plan.release_tension) {
            if (mark_t < 0) mark_t = t;
            if (t - mark_t >= lim.min_hold_steps) go(Phase::lower, t);
          }
          break;
        case Phase::reset: break;
      }
    }
    if (rep.retries > lim.max_retries) {
      rep.reason = "bot: too many retries";
      break;
    }

    // 3. Move the hand within human rate limits, add tremor, quantise.
    hand_t = approach(hand_t, target_t, lim.tension_rate);
    hand_l = approach(hand_l, target_l, lim.lift_rate);
    hand_d = approach(hand_d, target_d, lim.depth_rate);
    if (t % lim.noise_period_steps == 0) {
      noise_t = rng.range(-lim.tension_noise, lim.tension_noise);
      noise_l = rng.range(-lim.lift_noise, lim.lift_noise);
    }
    InputFrame in;
    in.tension = hand_t + noise_t;
    in.pick_depth = hand_d;
    in.pick_lift = q_mul(q_max(0, hand_l + noise_l), plan.lift_sign);
    in.rotate = hand_r;
    in = quantize(in);
    const StepOutput& out = session.step(in);
    if (opt.record_inputs) rep.inputs.push_back(in);
    for (const auto& e : out.events) {
      perceived.push_back(e);
      if (e.sub != 0) continue;
      if (e.kind == EventKind::drop) ++rep.drops;
      if (e.kind == EventKind::overset) ++rep.oversets;
      if (e.kind == EventKind::false_set) ++rep.false_sets;
    }
    if (session.finished()) break;
  }

  rep.steps = session.t_step();
  rep.event_hash = session.event_hash();
  rep.peak_stress = session.state().tool.peak_ratio();
  if (session.is_open()) {
    if (rep.peak_stress >= BOT_MAX_STRESS) {
      rep.reason = "bot: stress reached 0.8 S_max";
    } else {
      rep.ok = true;
    }
  } else if (session.failure() != FailureKind::none) {
    rep.reason = std::string("bot: failure ") + std::string(failure_name(session.failure()));
  } else if (rep.reason.empty()) {
    rep.reason = "bot: step budget exhausted";
  }
  return rep;
}

HumanLimits clumsy_human_limits() {
  HumanLimits h;
  h.tension_noise = q16_milli(60);
  h.lift_noise = q16_milli(20);
  h.slow_rate = q16_per_step(q16_milli(700));
  h.fine_rate = q16_per_step(q16_milli(300));
  h.spool_rate = q16_per_step(q16_milli(500));
  h.latency_steps = ms_to_steps(250);
  h.adaptive = true;
  return h;
}

HumanLimits feeling_human_limits() {
  HumanLimits h;  // a practised player in "dark" mode
  h.tension_noise = q16_milli(40);
  h.lift_noise = q16_milli(15);
  h.slow_rate = q16_per_step(q16_milli(400));
  h.fine_rate = q16_per_step(q16_milli(200));
  h.spool_rate = q16_per_step(q16_milli(200));
  h.latency_steps = ms_to_steps(220);
  h.max_retries = 400;
  return h;
}

namespace {

enum class Feel { probe_travel, probe_lift, lift, spool, flick, wait_open, reset };

struct DelayedSignal {
  std::vector<q16> buf;
  std::size_t head = 0;
  explicit DelayedSignal(std::int32_t latency) : buf(static_cast<std::size_t>(latency > 0 ? latency : 1), 0) {}
  // Pushes the newest sample and returns the one `latency` steps old.
  q16 push(q16 v) {
    const q16 old = buf[head];
    buf[head] = v;
    head = (head + 1) % buf.size();
    return old;
  }
};

}  // namespace

SolveReport run_feel_bot(const FamilyModule& family, const LockSpec& spec, const ToolSet& tools,
                         const HumanLimits& lim, std::int64_t budget_steps, const SolveOptions& opt) {
  SolveReport rep;
  LockSession session(family, spec, tools);
  Pcg32 rng(derive_seed(spec.seed ^ splitmix64(opt.bot_seed), family.id(),
                        static_cast<std::uint32_t>(family.rules_version()), "feel"),
            derive_stream(family.id(), "feel"));
  const int n = static_cast<int>(session.describe().elements.size());  // drawn, so known
  if (n <= 0) {
    rep.reason = "feel: no elements";
    return rep;
  }
  const bool can_reset = (family.input_mask() & AXIS_ROTATE) != 0;
  constexpr q16 DRAG_BOUND = q16_milli(30);
  constexpr q16 PROBE_HEIGHT = q16_milli(220);
  constexpr q16 LIFT_CAP = q16_milli(950);
  constexpr q16 T_START = q16_milli(150);
  constexpr q16 T_STEP = q16_milli(30);
  constexpr q16 T_MAX = q16_milli(900);
  const q16 probe_rate = lim.lift_rate;

  std::vector<char> believed(static_cast<std::size_t>(n), 0);
  std::vector<char> free_now(static_cast<std::size_t>(n), 0);
  std::vector<int> set_order;
  std::deque<LockEvent> perceived;
  DelayedSignal drag_sig(lim.latency_steps);

  Feel ph = Feel::probe_travel;
  std::int64_t phase_t = 0;
  int cand = 0;
  q16 work_t = T_START;   // believed working tension
  q16 spool_t = 0;        // tension used in a false gate
  q16 hand_t = 0, hand_d = element_center(0, n), hand_l = 0, hand_r = 0;
  q16 noise_t = 0, noise_l = 0;
  q16 max_drag = 0;
  bool felt_near = false;
  std::int64_t last_progress = 0;
  q16 last_drag = 0;  // continuous signal of the previous step
  bool fresh_t = true;  // work_t was just raised to the binding edge
  int caught = -1;      // element perceived in a false gate (it stays drawn there until set or drop)

  auto go = [&](Feel p, std::int64_t t) {
    ph = p;
    phase_t = t;
    max_drag = 0;
    felt_near = false;
  };
  auto next_candidate = [&](int from) -> int {
    for (int k = 1; k <= n; ++k) {
      const int c = (from + k) % n;
      if (!believed[static_cast<std::size_t>(c)] && !free_now[static_cast<std::size_t>(c)]) return c;
    }
    return -1;
  };
  auto unset_count = [&]() {
    int c = 0;
    for (char b : believed) c += b ? 0 : 1;
    return c;
  };
  auto start_probe = [&](std::int64_t t) {
    int c = next_candidate(cand);
    if (c < 0) {
      // Nothing binds at this tension: pull harder.
      for (auto& f : free_now) f = 0;
      work_t = work_t + T_STEP > T_MAX ? T_START : work_t + T_STEP;
      fresh_t = true;
      ++rep.retries;
      c = next_candidate(cand);
    }
    if (c < 0) c = 0;
    cand = c;
    go(Feel::probe_travel, t);
  };
  auto forget_last = [&](int count) {
    for (int k = 0; k < count && !set_order.empty(); ++k) {
      believed[static_cast<std::size_t>(set_order.back())] = 0;
      set_order.pop_back();
    }
  };

  for (std::int64_t t = 0; t < budget_steps; ++t) {
    // 1. Perception (delayed events and drag).
    while (!perceived.empty() && perceived.front().t_step <= t - lim.latency_steps) {
      const LockEvent e = perceived.front();
      perceived.pop_front();
      if (ph == Feel::reset) {
        if (e.kind == EventKind::drop) {
          for (auto& b : believed) b = 0;
          for (auto& f : free_now) f = 0;
          set_order.clear();
          caught = -1;
          start_probe(t);
        }
        continue;
      }
      if (e.sub != 0) continue;
      switch (e.kind) {
        case EventKind::set:
          if (e.element >= 0 && e.element < n && !believed[static_cast<std::size_t>(e.element)]) {
            believed[static_cast<std::size_t>(e.element)] = 1;
            set_order.push_back(e.element);
            for (auto& f : free_now) f = 0;
            if (e.element == caught) caught = -1;
            last_progress = t;
            if (unset_count() == 0) go(Feel::wait_open, t);
            else if (ph != Feel::flick) start_probe(t);
          }
          break;
        case EventKind::false_set:
          if ((ph == Feel::lift || ph == Feel::probe_lift) && e.element == cand) {
            caught = e.element;
            spool_t = spool_t > 0 ? spool_t : q_max(q16_milli(100), work_t - q16_milli(80));
            go(Feel::spool, t);
          }
          break;
        case EventKind::near_shear:
          if (e.element == cand) felt_near = true;
          break;
        case EventKind::overset:
          if (e.element >= 0 && e.element < n && believed[static_cast<std::size_t>(e.element)]) {
            believed[static_cast<std::size_t>(e.element)] = 0;
            set_order.erase(std::remove(set_order.begin(), set_order.end(), static_cast<int>(e.element)), set_order.end());
          }
          caught = -1;
          go(Feel::flick, t);
          break;
        case EventKind::drop: {
          const int lost = static_cast<int>((static_cast<std::int64_t>(e.intensity) * n + Q16_ONE / 2) >> 16);
          forget_last(lost > 0 ? lost : 1);
          caught = -1;
          if (ph == Feel::spool) spool_t += q16_milli(20);  // eased too far in the false gate
          if (ph != Feel::flick) start_probe(t);
          break;
        }
        case EventKind::stress:
          if (ph == Feel::spool) spool_t = q_max(q16_milli(60), spool_t - q16_milli(20));
          else work_t = q_max(T_START, work_t - T_STEP);
          break;
        case EventKind::detector_trip:
          if (can_reset) go(Feel::reset, t);
          break;
        default: break;
      }
    }
    const q16 felt_drag = drag_sig.push(last_drag);

    // 2. Decide.
    q16 target_t = work_t, target_l = hand_l, target_d = hand_d;
    hand_r = 0;
    const q16 depth = element_center(cand, n);
    switch (ph) {
      case Feel::probe_travel:
        target_l = 0;
        if (hand_l == 0) target_d = depth;
        if (hand_d == depth && hand_l == 0 && t - phase_t >= lim.min_hold_steps) go(Feel::probe_lift, t);
        break;
      case Feel::probe_lift:
        target_l = q_min(hand_l + probe_rate, PROBE_HEIGHT);
        if (t - phase_t > lim.latency_steps) max_drag = q_max(max_drag, felt_drag);
        if (max_drag >= DRAG_BOUND) {
          // Binding found at the edge: pull a little harder so tremor does not unbind it.
          if (fresh_t) work_t = q_min(T_MAX, work_t + T_STEP);
          fresh_t = false;
          go(Feel::lift, t);
        } else if (hand_l >= PROBE_HEIGHT && t - phase_t > 2 * lim.latency_steps + lim.min_hold_steps) {
          free_now[static_cast<std::size_t>(cand)] = 1;  // follows the pick: loose
          start_probe(t);
        }
        break;
      case Feel::lift: {
        const q16 rate = felt_near ? q_min(lim.fine_rate, lim.slow_rate) : lim.slow_rate;
        target_l = q_min(hand_l + rate, LIFT_CAP);
        if (hand_l >= LIFT_CAP && t - phase_t > lim.latency_steps) {
          // Bound but does not rise: too much tension.
          work_t = q_max(T_START, work_t - T_STEP);
          ++rep.retries;
          go(Feel::probe_travel, t);
        }
        break;
      }
      case Feel::spool:
        target_t = spool_t;
        if (q_abs(hand_t - spool_t) <= q16_milli(15)) target_l = q_min(hand_l + lim.spool_rate, LIFT_CAP);
        if ((hand_l >= LIFT_CAP && t - phase_t > lim.latency_steps) || t - phase_t > SIM_HZ * 3) {
          spool_t = q_max(q16_milli(60), spool_t - q16_milli(20));
          ++rep.retries;
          // v0.3: the caught element stays in its false gate (a player sees it there):
          // keep working it instead of probing below it, which found nothing and looped.
          if (caught >= 0) {
            cand = caught;
            go(Feel::spool, t);
          } else {
            go(Feel::probe_travel, t);
          }
        }
        break;
      case Feel::flick:
        target_t = 0;
        target_l = 0;
        if (hand_t == 0) start_probe(t);
        break;
      case Feel::wait_open:
        target_l = 0;
        if (t - phase_t > lim.latency_steps + SIM_HZ / 2) {
          for (auto& b : believed) b = 0;  // beliefs were wrong: start over
          set_order.clear();
          ++rep.retries;
          start_probe(t);
        }
        break;
      case Feel::reset:
        target_t = 0;
        target_l = 0;
        if (hand_t == 0) hand_r = -Q16_ONE;
        break;
    }
    if (rep.retries > lim.max_retries) {
      rep.reason = "feel: too many retries";
      break;
    }
    (void)last_progress;

    // 3. Hand.
    hand_t = bot_approach(hand_t, target_t, lim.tension_rate);
    hand_l = bot_approach(hand_l, target_l, ph == Feel::probe_lift ? probe_rate : lim.lift_rate);
    hand_d = bot_approach(hand_d, target_d, lim.depth_rate);
    if (t % lim.noise_period_steps == 0) {
      noise_t = rng.range(-lim.tension_noise, lim.tension_noise);
      noise_l = rng.range(-lim.lift_noise, lim.lift_noise);
    }
    InputFrame in;
    in.tension = hand_t == 0 ? 0 : hand_t + noise_t;
    in.pick_depth = hand_d;
    in.pick_lift = q_max(0, hand_l + noise_l);
    in.rotate = hand_r;
    in = quantize(in);
    const StepOutput& out = session.step(in);
    last_drag = out.pick_drag;
    if (opt.record_inputs) rep.inputs.push_back(in);
    for (const auto& e : out.events) {
      perceived.push_back(e);
      if (e.sub != 0) continue;
      if (e.kind == EventKind::drop) ++rep.drops;
      if (e.kind == EventKind::overset) ++rep.oversets;
      if (e.kind == EventKind::false_set) ++rep.false_sets;
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

SolveReport FamilyModule::run_bot(BotKind kind, const LockSpec& spec, const ToolSet& tools,
                                  const SolveOptions& opt) const {
  const std::int64_t full = static_cast<std::int64_t>(spec.difficulty.time_limit_s) * SIM_HZ;
  switch (kind) {
    case BotKind::scripted: return solver(spec, tools, opt);
    case BotKind::clumsy: {
      OracleReport o = oracle(spec, tools);
      if (!o.ok) {
        SolveReport r;
        r.reason = "oracle: " + o.reason;
        return r;
      }
      // A human does not know where the overset starts: no lift cap from the plan.
      for (auto& ps : o.plan.steps) ps.lift_cap = q16_milli(980);
      return run_plan_bot(*this, spec, tools, o.plan, clumsy_human_limits(), full, opt);
    }
    case BotKind::feeling: return run_feel_bot(*this, spec, tools, feeling_human_limits(), full, opt);
  }
  return {};
}

SolveReport FamilyModule::solver(const LockSpec& spec, const ToolSet& tools, const SolveOptions& opt) const {
  const OracleReport o = oracle(spec, tools);
  if (!o.ok) {
    SolveReport r;
    r.reason = "oracle: " + o.reason;
    return r;
  }
  const std::int64_t budget = static_cast<std::int64_t>(spec.difficulty.time_limit_s) * SIM_HZ / 2;
  return run_plan_bot(*this, spec, tools, o.plan, HumanLimits{}, budget, opt);
}

}  // namespace lockcore
