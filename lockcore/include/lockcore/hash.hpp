// Small, dependency-free hashes: FNV-1a 64 for event streams and identifiers,
// SplitMix64 finaliser for deriving seeds.
#pragma once

#include <cstdint>
#include <string_view>

namespace lockcore {

inline constexpr std::uint64_t FNV64_OFFSET = 0xcbf29ce484222325ULL;
inline constexpr std::uint64_t FNV64_PRIME = 0x100000001b3ULL;

class Fnv1a64 {
 public:
  void byte(std::uint8_t b) {
    h_ ^= b;
    h_ *= FNV64_PRIME;
  }
  // Integers are always fed little-endian, independent of the host byte order.
  void u32(std::uint32_t v) {
    for (int i = 0; i < 4; ++i) byte(static_cast<std::uint8_t>(v >> (8 * i)));
  }
  void u64(std::uint64_t v) {
    for (int i = 0; i < 8; ++i) byte(static_cast<std::uint8_t>(v >> (8 * i)));
  }
  void i32(std::int32_t v) { u32(static_cast<std::uint32_t>(v)); }
  void i64(std::int64_t v) { u64(static_cast<std::uint64_t>(v)); }
  void str(std::string_view s) {
    for (char c : s) byte(static_cast<std::uint8_t>(c));
  }
  std::uint64_t value() const { return h_; }

 private:
  std::uint64_t h_ = FNV64_OFFSET;
};

constexpr std::uint64_t fnv1a64(std::string_view s) {
  std::uint64_t h = FNV64_OFFSET;
  for (char c : s) {
    h ^= static_cast<std::uint8_t>(c);
    h *= FNV64_PRIME;
  }
  return h;
}

constexpr std::uint64_t splitmix64(std::uint64_t x) {
  x += 0x9e3779b97f4a7c15ULL;
  x = (x ^ (x >> 30u)) * 0xbf58476d1ce4e5b9ULL;
  x = (x ^ (x >> 27u)) * 0x94d049bb133111ebULL;
  return x ^ (x >> 31u);
}

// seed_lock = hash64(seed, family_id, version, purpose) (LOCKS.md §1.1).
constexpr std::uint64_t derive_seed(std::uint64_t seed, std::string_view family, std::uint32_t version,
                                    std::string_view purpose) {
  std::uint64_t h = splitmix64(seed);
  h = splitmix64(h ^ fnv1a64(family));
  h = splitmix64(h ^ version);
  h = splitmix64(h ^ fnv1a64(purpose));
  return h;
}

constexpr std::uint64_t derive_stream(std::string_view family, std::string_view purpose) {
  return fnv1a64(family) ^ (fnv1a64(purpose) << 1u);
}

}  // namespace lockcore
