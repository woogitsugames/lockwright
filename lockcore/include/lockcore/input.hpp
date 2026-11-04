// Per-step input sample (ARCHITECTURE.md §3, LOCKS.md §1.3).
#pragma once

#include <cstdint>

#include "lockcore/fixed.hpp"

namespace lockcore {

struct InputFrame {
  q16 tension = 0;     // [0, 1]  torque on the core
  q16 pick_depth = 0;  // [0, 1]  position along the keyway
  q16 pick_lift = 0;   // [-1, 1] lift; negative = press down
  q16 rotate = 0;      // [-1, 1] optional family axis (rotation speed)
  q16 push = 0;        // [0, 1]  optional family axis (press-in)
  std::uint8_t tool = 0;  // active tool slot

  friend bool operator==(const InputFrame&, const InputFrame&) = default;
};

// Clamps every axis to its range and snaps it to 1/256 (push: 1/64).
constexpr InputFrame quantize(InputFrame in) {
  InputFrame q;
  q.tension = quantize_256(q_clamp(in.tension, 0, Q16_ONE));
  q.pick_depth = quantize_256(q_clamp(in.pick_depth, 0, Q16_ONE));
  q.pick_lift = quantize_256(q_clamp(in.pick_lift, -Q16_ONE, Q16_ONE));
  q.rotate = quantize_256(q_clamp(in.rotate, -Q16_ONE, Q16_ONE));
  const q16 push = q_clamp(in.push, 0, Q16_ONE);
  constexpr q16 push_quantum = Q16_ONE / 64;
  q.push = ((push + push_quantum / 2) / push_quantum) * push_quantum;
  q.tool = in.tool;
  return q;
}

// Input axes a family reads; the UI shows only these controls.
enum InputAxis : std::uint32_t {
  AXIS_TENSION = 1u << 0,
  AXIS_DEPTH = 1u << 1,
  AXIS_LIFT = 1u << 2,
  AXIS_ROTATE = 1u << 3,
  AXIS_PUSH = 1u << 4,
};

}  // namespace lockcore
