// Shared mechanics used by every tension family (LOCKS.md §1.5), so that the "feel"
// stays consistent between families.
#pragma once

#include <cstdint>
#include <vector>

#include "lockcore/events.hpp"
#include "lockcore/fixed.hpp"

namespace lockcore {

class EventSink {
 public:
  explicit EventSink(std::vector<LockEvent>& out) : out_(out) {}
  void emit(std::int64_t t, EventKind kind, int element, q16 intensity, MaterialId material,
            std::uint16_t sub = 0) {
    LockEvent e;
    e.t_step = t;
    e.kind = kind;
    e.sub = sub;
    e.element = static_cast<std::int16_t>(element);
    e.intensity = q_clamp(intensity, 0, Q16_ONE);
    e.material = material;
    out_.push_back(e);
  }

 private:
  std::vector<LockEvent>& out_;
};

// Tension band thresholds shared by tension families.
struct TensionBand {
  q16 lo = 0;  // binds at T >= lo
  q16 hi = 0;  // t_stick: above this the element "won't go"
  q16 width() const { return hi - lo; }
};

// Drop timer: fires once when T stays below t_hold for `grace` consecutive steps.
class TensionHold {
 public:
  bool update(q16 tension, q16 t_hold, std::int32_t grace_steps) {
    if (tension >= t_hold) {
      below_ = 0;
      return false;
    }
    ++below_;
    return below_ == grace_steps;
  }
  std::int32_t below_steps() const { return below_; }
  void reset() { below_ = 0; }

 private:
  std::int32_t below_ = 0;
};

// Tool stress and wear (LOCKS.md §1.5, TOOLS.md).
// Each step a family may call load() any number of times; end_step() then applies
// decay (if nothing loaded), and emits stress / break / wear events.
class ToolStress {
 public:
  static constexpr q16 STRESS_WARN = q16_milli(600);  // stress event at 0.6 * S_max
  static constexpr std::int32_t STRESS_REPEAT_STEPS = 12;
  static constexpr std::int32_t DECAY_STEPS = 180;  // full capacity decays in 1.5 s

  void init(q16 s_max, std::int32_t wear_points, q16 gain);
  // Re-applies tool wear to the base capacity given to init().
  void set_wear(std::int32_t wear_points) { init(base_s_max_, wear_points, gain_); }

  // over: how far tension exceeds the safe limit; press: how hard the tool pushes
  // an element that does not move. Both Q16 >= 0.
  void load(q16 over, q16 press);

  void end_step(std::int64_t t, EventSink& sink, int element, MaterialId material);

  q16 stress() const { return s_; }
  q16 capacity() const { return s_max_; }
  q16 ratio() const { return s_max_ > 0 ? q_div(s_, s_max_) : 0; }
  q16 peak_ratio() const { return peak_ratio_; }
  bool broken() const { return broken_; }
  std::int32_t wear() const { return wear_; }

 private:
  q16 s_ = 0;
  q16 s_max_ = Q16_ONE;
  q16 base_s_max_ = Q16_ONE;
  q16 gain_ = 0;
  q16 peak_ratio_ = 0;
  std::int64_t wear_acc_ = 0;
  std::int32_t wear_ = 0;
  std::int64_t last_stress_t_ = -1000;
  bool loaded_ = false;
  bool broken_ = false;
};

// Maps pick_depth to an element index with a magnet of +-30% of the pitch
// (LOCKS.md §1.3). Returns -1 between elements.
int locate_element(q16 depth, int n);
q16 element_center(int index, int n);

}  // namespace lockcore
