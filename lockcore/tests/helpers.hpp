#pragma once

#include <algorithm>
#include <iostream>
#include <memory>
#include <stdexcept>
#include <vector>

#include "lockcore/lever.hpp"
#include "lockcore/lockcore.hpp"
#include "lockcore/pin_tumbler.hpp"
#include "lockcore/ring_combo.hpp"
#include "lockcore/wafer.hpp"
#include "lockcore/warded.hpp"
#include "lockcore/wooden_pin.hpp"

namespace th {

using namespace lockcore;

inline const FamilyModule& pin_module() { return *FamilyRegistry::builtin().find(pin::FAMILY_ID); }
inline const FamilyModule& wafer_module() { return *FamilyRegistry::builtin().find(wafer::FAMILY_ID); }
inline const FamilyModule& module(std::string_view id) { return *FamilyRegistry::builtin().find(id); }

// Indices of elements sorted by a binding-offset accessor.
template <typename Vec, typename Get>
std::vector<int> binding_order(const Vec& v, Get get) {
  std::vector<int> order(v.size());
  for (std::size_t i = 0; i < v.size(); ++i) order[i] = static_cast<int>(i);
  std::stable_sort(order.begin(), order.end(), [&](int a, int b) {
    return get(v[static_cast<std::size_t>(a)]) < get(v[static_cast<std::size_t>(b)]);
  });
  return order;
}

// Every bot kind through the real step(): scripted must open, the others must at
// least run without failing in a forbidden way.
inline void check_family_solves(const FamilyModule& fam, std::uint64_t seeds) {
  for (int tier = fam.min_tier(); tier <= fam.max_tier(); ++tier) {
    for (std::uint64_t seed = 1; seed <= seeds; ++seed) {
      const LockSpec spec = fam.generate(seed, fam.difficulty_for_tier(tier));
      const auto errs = fam.validate(spec);
      if (!errs.empty()) std::cerr << fam.id() << " t" << tier << " seed " << seed << ": " << errs.front().message << "\n";
      const SolveReport r = fam.solver(spec, fam.required_tools(spec));
      if (!r.ok) std::cerr << fam.id() << " t" << tier << " seed " << seed << ": " << r.reason << "\n";
      if (!(errs.empty() && r.ok)) throw std::runtime_error("family does not solve");
    }
  }
}

// Authored 3-stack pin lock with round numbers, for scenario tests.
inline std::shared_ptr<pin::Params> pin_params() {
  auto P = std::make_shared<pin::Params>();
  P->win_shear = q16_milli(120);
  P->overset_margin = q16_milli(100);
  P->tension_band = q16_milli(280);
  P->t_hold = pin::T_HOLD;
  P->t_release = pin::T_RELEASE;
  P->tau_safe = q16_milli(500);
  P->cr_lo = pin::CR_LO;
  P->cr_hi = pin::CR_HI;
  P->drop_grace_steps = 36;
  P->drop_all = true;
  P->s_max = Q16_ONE;
  P->stress_gain = pin::STRESS_GAIN;
  P->noise = 0;
  P->bound_speed = pin::BOUND_SPEED;
  P->spool_speed = pin::SPOOL_SPEED;
  for (int i = 0; i < 3; ++i) {
    pin::Stack s;
    s.target = q16_milli(550);
    s.order = q16_milli(100) * i;  // binds front to back
    s.band_lo = q16_milli(200);
    P->stacks.push_back(s);
  }
  return P;
}

inline LockSpec pin_spec(std::shared_ptr<pin::Params> P) {
  LockSpec spec;
  spec.family = std::string(pin::FAMILY_ID);
  spec.rules_version = pin::RULES_VERSION;
  spec.id = "test.pin";
  spec.source = "authored";
  spec.seed = 1;
  spec.difficulty = pin_module().difficulty_for_tier(2);
  spec.params = std::move(P);
  return spec;
}

inline InputFrame frame(q16 tension, q16 depth, q16 lift) {
  InputFrame f;
  f.tension = tension;
  f.pick_depth = depth;
  f.pick_lift = lift;
  return f;
}

struct Log {
  std::vector<LockEvent> events;
  int count(EventKind k, int element = -2, std::uint16_t sub = 0) const {
    int c = 0;
    for (const auto& e : events) {
      if (e.kind == k && e.sub == sub && (element == -2 || e.element == element)) ++c;
    }
    return c;
  }
  std::int64_t first(EventKind k, int element = -2) const {
    for (const auto& e : events) {
      if (e.kind == k && e.sub == 0 && (element == -2 || e.element == element)) return e.t_step;
    }
    return -1;
  }
};

inline void run(LockSession& s, const InputFrame& f, int steps, Log& log) {
  for (int i = 0; i < steps; ++i) {
    const auto& out = s.step(f);
    log.events.insert(log.events.end(), out.events.begin(), out.events.end());
  }
}

// Lifts the pick on `element` by `rate` per step until `kind` is emitted for it
// (or the cap is reached). Returns true when the event happened.
inline bool lift_until(LockSession& s, int element, q16 tension, q16 rate, q16 cap, EventKind kind, Log& log,
                       q16 start = 0) {
  const int n = static_cast<int>(s.describe().elements.size());
  const q16 depth = element_center(element, n);
  for (q16 lift = start; lift <= cap; lift += rate) {
    const auto& out = s.step(frame(tension, depth, lift));
    log.events.insert(log.events.end(), out.events.begin(), out.events.end());
    for (const auto& e : out.events) {
      if (e.kind == kind && e.sub == 0 && e.element == element) return true;
    }
  }
  return false;
}

}  // namespace th
