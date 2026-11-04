#include "lockcore/json.hpp"

#include <cstdint>
#include <limits>

namespace lockcore::json {

Value Value::boolean(bool b) {
  Value v;
  v.type_ = Type::boolean;
  v.bool_ = b;
  return v;
}
Value Value::integer(std::int64_t i) {
  Value v;
  v.type_ = Type::integer;
  v.int_ = i;
  v.uint_ = static_cast<std::uint64_t>(i);
  return v;
}
Value Value::uinteger(std::uint64_t u) {
  Value v;
  v.type_ = Type::integer;
  v.uint_ = u;
  v.int_ = static_cast<std::int64_t>(u);
  v.uint_only_ = u > static_cast<std::uint64_t>(std::numeric_limits<std::int64_t>::max());
  return v;
}
Value Value::string(std::string s) {
  Value v;
  v.type_ = Type::string;
  v.str_ = std::move(s);
  return v;
}
Value Value::array() {
  Value v;
  v.type_ = Type::array;
  return v;
}
Value Value::object() {
  Value v;
  v.type_ = Type::object;
  return v;
}

Value& Value::push(Value v) {
  items_.push_back(std::move(v));
  return items_.back();
}

Value& Value::set(std::string key, Value v) {
  for (auto& m : members_) {
    if (m.first == key) {
      m.second = std::move(v);
      return m.second;
    }
  }
  members_.emplace_back(std::move(key), std::move(v));
  return members_.back().second;
}

const Value* Value::find(std::string_view key) const {
  for (const auto& m : members_) {
    if (m.first == key) return &m.second;
  }
  return nullptr;
}

namespace {

class Parser {
 public:
  explicit Parser(std::string_view t) : t_(t) {}

  ParseResult run() {
    ParseResult r;
    ws();
    if (!value(r.value, 0)) {
      r.error = err_;
      return r;
    }
    ws();
    if (pos_ != t_.size()) {
      fail("trailing characters");
      r.error = err_;
      return r;
    }
    r.ok = true;
    return r;
  }

 private:
  static constexpr int kMaxDepth = 64;

  bool fail(const char* msg) {
    if (err_.empty()) {
      int line = 1, col = 1;
      for (std::size_t i = 0; i < pos_ && i < t_.size(); ++i) {
        if (t_[i] == '\n') {
          ++line;
          col = 1;
        } else {
          ++col;
        }
      }
      err_ = std::to_string(line) + ":" + std::to_string(col) + ": " + msg;
    }
    return false;
  }

  void ws() {
    while (pos_ < t_.size()) {
      const char c = t_[pos_];
      if (c == ' ' || c == '\t' || c == '\n' || c == '\r') {
        ++pos_;
      } else {
        break;
      }
    }
  }

  bool literal(std::string_view word) {
    if (t_.substr(pos_, word.size()) != word) return fail("invalid literal");
    pos_ += word.size();
    return true;
  }

  bool value(Value& out, int depth) {
    if (depth > kMaxDepth) return fail("nesting too deep");
    if (pos_ >= t_.size()) return fail("unexpected end");
    const char c = t_[pos_];
    if (c == '{') return object(out, depth);
    if (c == '[') return array(out, depth);
    if (c == '"') {
      std::string s;
      if (!string(s)) return false;
      out = Value::string(std::move(s));
      return true;
    }
    if (c == 't') {
      out = Value::boolean(true);
      return literal("true");
    }
    if (c == 'f') {
      out = Value::boolean(false);
      return literal("false");
    }
    if (c == 'n') {
      out = Value::null();
      return literal("null");
    }
    if (c == '-' || (c >= '0' && c <= '9')) return number(out);
    return fail("unexpected character");
  }

  bool number(Value& out) {
    bool neg = false;
    if (t_[pos_] == '-') {
      neg = true;
      ++pos_;
    }
    if (pos_ >= t_.size() || t_[pos_] < '0' || t_[pos_] > '9') return fail("invalid number");
    if (t_[pos_] == '0' && pos_ + 1 < t_.size() && t_[pos_ + 1] >= '0' && t_[pos_ + 1] <= '9')
      return fail("leading zero");
    std::uint64_t mag = 0;
    while (pos_ < t_.size() && t_[pos_] >= '0' && t_[pos_] <= '9') {
      const auto d = static_cast<std::uint64_t>(t_[pos_] - '0');
      if (mag > (std::numeric_limits<std::uint64_t>::max() - d) / 10) return fail("integer overflow");
      mag = mag * 10 + d;
      ++pos_;
    }
    if (pos_ < t_.size() && (t_[pos_] == '.' || t_[pos_] == 'e' || t_[pos_] == 'E'))
      return fail("fractional numbers are not allowed (use *_q16 integers)");
    if (neg) {
      constexpr std::uint64_t lim = static_cast<std::uint64_t>(std::numeric_limits<std::int64_t>::max()) + 1;
      if (mag > lim) return fail("integer overflow");
      out = Value::integer(mag == lim ? std::numeric_limits<std::int64_t>::min()
                                      : -static_cast<std::int64_t>(mag));
    } else {
      out = Value::uinteger(mag);
    }
    return true;
  }

  static void put_utf8(std::string& s, std::uint32_t cp) {
    if (cp < 0x80) {
      s.push_back(static_cast<char>(cp));
    } else if (cp < 0x800) {
      s.push_back(static_cast<char>(0xC0 | (cp >> 6)));
      s.push_back(static_cast<char>(0x80 | (cp & 0x3F)));
    } else if (cp < 0x10000) {
      s.push_back(static_cast<char>(0xE0 | (cp >> 12)));
      s.push_back(static_cast<char>(0x80 | ((cp >> 6) & 0x3F)));
      s.push_back(static_cast<char>(0x80 | (cp & 0x3F)));
    } else {
      s.push_back(static_cast<char>(0xF0 | (cp >> 18)));
      s.push_back(static_cast<char>(0x80 | ((cp >> 12) & 0x3F)));
      s.push_back(static_cast<char>(0x80 | ((cp >> 6) & 0x3F)));
      s.push_back(static_cast<char>(0x80 | (cp & 0x3F)));
    }
  }

  bool hex4(std::uint32_t& out) {
    if (pos_ + 4 > t_.size()) return fail("bad \\u escape");
    out = 0;
    for (int i = 0; i < 4; ++i) {
      const char c = t_[pos_++];
      out <<= 4;
      if (c >= '0' && c <= '9') out |= static_cast<std::uint32_t>(c - '0');
      else if (c >= 'a' && c <= 'f') out |= static_cast<std::uint32_t>(c - 'a' + 10);
      else if (c >= 'A' && c <= 'F') out |= static_cast<std::uint32_t>(c - 'A' + 10);
      else return fail("bad \\u escape");
    }
    return true;
  }

  bool string(std::string& out) {
    ++pos_;  // opening quote
    while (pos_ < t_.size()) {
      const char c = t_[pos_++];
      if (c == '"') return true;
      if (static_cast<unsigned char>(c) < 0x20) return fail("control character in string");
      if (c != '\\') {
        out.push_back(c);
        continue;
      }
      if (pos_ >= t_.size()) break;
      const char e = t_[pos_++];
      switch (e) {
        case '"': out.push_back('"'); break;
        case '\\': out.push_back('\\'); break;
        case '/': out.push_back('/'); break;
        case 'b': out.push_back('\b'); break;
        case 'f': out.push_back('\f'); break;
        case 'n': out.push_back('\n'); break;
        case 'r': out.push_back('\r'); break;
        case 't': out.push_back('\t'); break;
        case 'u': {
          std::uint32_t cp = 0;
          if (!hex4(cp)) return false;
          if (cp >= 0xD800 && cp <= 0xDBFF) {
            if (pos_ + 2 > t_.size() || t_[pos_] != '\\' || t_[pos_ + 1] != 'u') return fail("lone surrogate");
            pos_ += 2;
            std::uint32_t lo = 0;
            if (!hex4(lo)) return false;
            if (lo < 0xDC00 || lo > 0xDFFF) return fail("bad surrogate pair");
            cp = 0x10000 + ((cp - 0xD800) << 10) + (lo - 0xDC00);
          }
          put_utf8(out, cp);
          break;
        }
        default: return fail("bad escape");
      }
    }
    return fail("unterminated string");
  }

  bool array(Value& out, int depth) {
    ++pos_;
    out = Value::array();
    ws();
    if (pos_ < t_.size() && t_[pos_] == ']') {
      ++pos_;
      return true;
    }
    for (;;) {
      ws();
      Value item;
      if (!value(item, depth + 1)) return false;
      out.push(std::move(item));
      ws();
      if (pos_ >= t_.size()) return fail("unterminated array");
      if (t_[pos_] == ',') {
        ++pos_;
        continue;
      }
      if (t_[pos_] == ']') {
        ++pos_;
        return true;
      }
      return fail("expected , or ]");
    }
  }

  bool object(Value& out, int depth) {
    ++pos_;
    out = Value::object();
    ws();
    if (pos_ < t_.size() && t_[pos_] == '}') {
      ++pos_;
      return true;
    }
    for (;;) {
      ws();
      if (pos_ >= t_.size() || t_[pos_] != '"') return fail("expected key");
      std::string key;
      if (!string(key)) return false;
      if (out.find(key) != nullptr) return fail("duplicate key");
      ws();
      if (pos_ >= t_.size() || t_[pos_] != ':') return fail("expected :");
      ++pos_;
      ws();
      Value item;
      if (!value(item, depth + 1)) return false;
      out.members().emplace_back(std::move(key), std::move(item));
      ws();
      if (pos_ >= t_.size()) return fail("unterminated object");
      if (t_[pos_] == ',') {
        ++pos_;
        continue;
      }
      if (t_[pos_] == '}') {
        ++pos_;
        return true;
      }
      return fail("expected , or }");
    }
  }

  std::string_view t_;
  std::size_t pos_ = 0;
  std::string err_;
};

void write_string(std::string& o, const std::string& s) {
  static const char* hex = "0123456789abcdef";
  o.push_back('"');
  for (char c : s) {
    switch (c) {
      case '"': o += "\\\""; break;
      case '\\': o += "\\\\"; break;
      case '\n': o += "\\n"; break;
      case '\r': o += "\\r"; break;
      case '\t': o += "\\t"; break;
      default:
        if (static_cast<unsigned char>(c) < 0x20) {
          o += "\\u00";
          o.push_back(hex[(c >> 4) & 0xF]);
          o.push_back(hex[c & 0xF]);
        } else {
          o.push_back(c);
        }
    }
  }
  o.push_back('"');
}

bool is_scalar(const Value& v) { return !v.is_array() && !v.is_object(); }

void write_value(std::string& o, const Value& v, int indent, int level) {
  const std::string pad(static_cast<std::size_t>(indent * (level + 1)), ' ');
  const std::string pad_close(static_cast<std::size_t>(indent * level), ' ');
  switch (v.type()) {
    case Value::Type::null: o += "null"; break;
    case Value::Type::boolean: o += v.as_bool() ? "true" : "false"; break;
    case Value::Type::integer:
      o += (v.uint_only() || v.as_int() >= 0) ? std::to_string(v.as_uint()) : std::to_string(v.as_int());
      break;
    case Value::Type::string: write_string(o, v.as_string()); break;
    case Value::Type::array: {
      if (v.items().empty()) {
        o += "[]";
        break;
      }
      bool flat = true;
      for (const auto& i : v.items()) flat = flat && is_scalar(i);
      if (flat) {
        o.push_back('[');
        for (std::size_t i = 0; i < v.items().size(); ++i) {
          if (i) o += ", ";
          write_value(o, v.items()[i], indent, level + 1);
        }
        o.push_back(']');
        break;
      }
      o += "[\n";
      for (std::size_t i = 0; i < v.items().size(); ++i) {
        o += pad;
        write_value(o, v.items()[i], indent, level + 1);
        if (i + 1 < v.items().size()) o.push_back(',');
        o.push_back('\n');
      }
      o += pad_close + "]";
      break;
    }
    case Value::Type::object: {
      if (v.members().empty()) {
        o += "{}";
        break;
      }
      o += "{\n";
      for (std::size_t i = 0; i < v.members().size(); ++i) {
        o += pad;
        write_string(o, v.members()[i].first);
        o += ": ";
        write_value(o, v.members()[i].second, indent, level + 1);
        if (i + 1 < v.members().size()) o.push_back(',');
        o.push_back('\n');
      }
      o += pad_close + "}";
      break;
    }
  }
}

}  // namespace

ParseResult parse(std::string_view text) { return Parser(text).run(); }

std::string write(const Value& v, int indent) {
  std::string o;
  write_value(o, v, indent, 0);
  o.push_back('\n');
  return o;
}

}  // namespace lockcore::json
