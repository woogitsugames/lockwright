// `lockwright.lock/1` serialisation (ARCHITECTURE.md §6).
#pragma once

#include <string>
#include <string_view>
#include <vector>

#include "lockcore/registry.hpp"

namespace lockcore {

inline constexpr std::string_view LOCK_SCHEMA = "lockwright.lock/1";

json::Value difficulty_to_json(const DifficultyVector& d);
bool difficulty_from_json(const json::Value& v, DifficultyVector& out, std::vector<SpecError>& errors,
                          const std::string& path = "difficulty");

json::Value lock_to_value(const LockSpec& spec, const FamilyModule& family);
std::string lock_to_json(const LockSpec& spec, const FamilyModule& family);

struct LockParse {
  bool ok = false;
  LockSpec spec;
  std::vector<SpecError> errors;
};
LockParse lock_from_json(std::string_view text, const FamilyRegistry& registry);

// Helpers for family parameter blocks.
namespace field {
bool get_int(const json::Value& obj, std::string_view key, std::int64_t lo, std::int64_t hi, std::int64_t& out,
             std::vector<SpecError>& errors, const std::string& path);
// Strict decimal uint64 (digits only, no sign, no overflow); used for seeds.
bool parse_u64(const std::string& s, std::uint64_t& out);
bool get_bool(const json::Value& obj, std::string_view key, bool& out, std::vector<SpecError>& errors,
              const std::string& path);
}  // namespace field

}  // namespace lockcore
