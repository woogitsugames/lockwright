// Minimal JSON for lockcore data files (D-13).
//
// Deliberately restricted: numbers must be integers (int64 range, or uint64 for
// non-negative values). Fractions and exponents are rejected, because every
// fractional quantity in lockcore data is stored as integer Q16 (`*_q16` keys).
// This keeps parsing bit-exact and float-free. Objects keep insertion order so the
// writer output is deterministic.
#pragma once

#include <cstdint>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace lockcore::json {

class Value {
 public:
  enum class Type : std::uint8_t { null, boolean, integer, string, array, object };

  Value() = default;
  static Value null() { return Value(); }
  static Value boolean(bool b);
  static Value integer(std::int64_t v);
  static Value uinteger(std::uint64_t v);
  static Value string(std::string s);
  static Value array();
  static Value object();

  Type type() const { return type_; }
  bool is_null() const { return type_ == Type::null; }
  bool is_bool() const { return type_ == Type::boolean; }
  bool is_int() const { return type_ == Type::integer; }
  bool is_string() const { return type_ == Type::string; }
  bool is_array() const { return type_ == Type::array; }
  bool is_object() const { return type_ == Type::object; }

  bool as_bool() const { return bool_; }
  std::int64_t as_int() const { return int_; }
  std::uint64_t as_uint() const { return uint_; }
  bool uint_only() const { return uint_only_; }  // > INT64_MAX
  const std::string& as_string() const { return str_; }

  // Arrays
  std::vector<Value>& items() { return items_; }
  const std::vector<Value>& items() const { return items_; }
  Value& push(Value v);

  // Objects (ordered)
  std::vector<std::pair<std::string, Value>>& members() { return members_; }
  const std::vector<std::pair<std::string, Value>>& members() const { return members_; }
  Value& set(std::string key, Value v);
  const Value* find(std::string_view key) const;

 private:
  Type type_ = Type::null;
  bool bool_ = false;
  bool uint_only_ = false;
  std::int64_t int_ = 0;
  std::uint64_t uint_ = 0;
  std::string str_;
  std::vector<Value> items_;
  std::vector<std::pair<std::string, Value>> members_;
};

struct ParseResult {
  Value value;
  bool ok = false;
  std::string error;  // "line:col: message"
};

ParseResult parse(std::string_view text);

// Pretty printer. Arrays whose items are all scalars go on one line.
std::string write(const Value& v, int indent = 2);

}  // namespace lockcore::json
