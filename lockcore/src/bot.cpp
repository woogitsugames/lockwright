#include "lockcore/bot.hpp"

#include <deque>

#include "lockcore/hash.hpp"
#include "lockcore/session.hpp"

namespace lockcore {

namespace {

q16 approach(q16 cur, q16 target, q16 rate) {
  if (cur < target) return q_min(cur + rate, target);
  return q_max(cur - rate, target);
}

enum class Phase { lower, travel, fast, slow, spool, release };

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
      if (e.sub != 0) continue;  // family flavour events (serration, rattle) are ignored
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
    if (ci < 0) {
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
