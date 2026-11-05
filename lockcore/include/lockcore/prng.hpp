// PCG32 (O'Neill, pcg-random.org, XSH-RR 64/32), implemented here so that the
// sequence never depends on a standard library or engine implementation.
// Streams: the `stream` argument selects one of 2^63 independent sequences; each
// family and purpose (generator, simulation, bot) gets its own stream (D-14).
#pragma once

#include <cstdint>

#include "lockcore/fixed.hpp"

namespace lockcore {

class Pcg32 {
 public:
  Pcg32(std::uint64_t seed, std::uint64_t stream) {
    state_ = 0;
    inc_ = (stream << 1u) | 1u;
    next();
    state_ += seed;
    next();
  }

  std::uint32_t next() {
    const std::uint64_t old = state_;
    state_ = old * 6364136223846793005ULL + inc_;
    const auto xorshifted = static_cast<std::uint32_t>(((old >> 18u) ^ old) >> 27u);
    const auto rot = static_cast<std::uint32_t>(old >> 59u);
    return (xorshifted >> rot) | (xorshifted << ((0u - rot) & 31u));
  }

  // Uniform integer in [0, bound). Unbiased (rejection), deterministic.
  std::uint32_t below(std::uint32_t bound) {
    if (bound <= 1) return 0;
    const std::uint32_t threshold = (0u - bound) % bound;
    for (;;) {
      const std::uint32_t r = next();
      if (r >= threshold) return r % bound;
    }
  }

  // Uniform integer in [lo, hi] (inclusive).
  std::int32_t range(std::int32_t lo, std::int32_t hi) {
    if (hi <= lo) return lo;
    // Span in uint32 (well defined, equals hi - lo); the full int32 range has
    // 2^32 values, which every next() covers uniformly (T25-22).
    const std::uint32_t span = static_cast<std::uint32_t>(hi) - static_cast<std::uint32_t>(lo);
    const std::uint32_t off = span == UINT32_MAX ? next() : below(span + 1u);
    return static_cast<std::int32_t>(static_cast<std::int64_t>(lo) + off);
  }

  // True with probability p (Q16).
  bool chance(q16 p) {
    if (p <= 0) return false;
    if (p >= Q16_ONE) return true;
    return static_cast<q16>(next() >> 16u) < p;
  }

  std::uint64_t state() const { return state_; }

 private:
  std::uint64_t state_;
  std::uint64_t inc_;
};

}  // namespace lockcore
