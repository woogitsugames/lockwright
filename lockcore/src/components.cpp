#include "lockcore/components.hpp"

namespace lockcore {

void ToolStress::init(q16 s_max, std::int32_t wear_points, q16 gain) {
  // Wear lowers capacity: 100 wear points leave 60% of S_max (TOOLS.md).
  const std::int32_t w = wear_points < 0 ? 0 : (wear_points > 100 ? 100 : wear_points);
  wear_ = w;
  base_s_max_ = s_max;
  s_max_ = static_cast<q16>((static_cast<std::int64_t>(s_max) * (250 - w)) / 250);
  if (s_max_ < 1) s_max_ = 1;
  gain_ = gain;
  s_ = 0;
  peak_ratio_ = 0;
  wear_acc_ = 0;
  broken_ = false;
  loaded_ = false;
  last_stress_t_ = -1000;
}

void ToolStress::load(q16 over, q16 press) {
  if (broken_ || over <= 0 || press <= 0) return;
  const q16 inc = q_mul(q_mul(over, press), gain_);
  if (inc <= 0) return;
  loaded_ = true;
  s_ += inc;
  wear_acc_ += inc;
}

void ToolStress::end_step(std::int64_t t, EventSink& sink, int element, MaterialId material) {
  if (broken_) return;
  if (!loaded_) {
    const q16 decay = s_max_ / DECAY_STEPS > 0 ? s_max_ / DECAY_STEPS : 1;
    s_ = s_ > decay ? s_ - decay : 0;
  }
  loaded_ = false;

  // Wear: one point per 1/10 of capacity absorbed; `wear` event every 10 points.
  const std::int64_t per_point = s_max_ / 10 > 0 ? s_max_ / 10 : 1;
  while (wear_acc_ >= per_point && wear_ < 100) {
    wear_acc_ -= per_point;
    ++wear_;
    if (wear_ % 10 == 0) sink.emit(t, EventKind::wear, -1, q16_ratio(wear_, 100), material);
  }

  const q16 r = ratio();
  if (r > peak_ratio_) peak_ratio_ = r;
  if (s_ >= s_max_) {
    broken_ = true;
    sink.emit(t, EventKind::break_, element, Q16_ONE, material);
    return;
  }
  if (r >= STRESS_WARN && t - last_stress_t_ >= STRESS_REPEAT_STEPS) {
    last_stress_t_ = t;
    sink.emit(t, EventKind::stress, element, r, material);
  }
}

int locate_element(q16 depth, int n) {
  if (n <= 0) return -1;
  const std::int64_t pitch = Q16_ONE / n;
  std::int64_t i = (static_cast<std::int64_t>(depth) * n) >> 16;
  if (i >= n) i = n - 1;
  if (i < 0) i = 0;
  const std::int64_t center = element_center(static_cast<int>(i), n);
  std::int64_t d = depth - center;
  if (d < 0) d = -d;
  return (d * 10 <= pitch * 3) ? static_cast<int>(i) : -1;
}

q16 element_center(int index, int n) {
  return static_cast<q16>(((2 * static_cast<std::int64_t>(index) + 1) * Q16_ONE) / (2 * n));
}

}  // namespace lockcore
