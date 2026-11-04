// Minimal test runner (D-13): TEST_CASE / CHECK / REQUIRE, no dependencies.
#pragma once

#include <cstdint>
#include <functional>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>

namespace lt {

struct Case {
  const char* name;
  std::function<void()> fn;
};

inline std::vector<Case>& registry() {
  static std::vector<Case> cases;
  return cases;
}

struct Registrar {
  Registrar(const char* name, std::function<void()> fn) { registry().push_back({name, std::move(fn)}); }
};

struct RequireFailed {};

inline int& failures() {
  static int f = 0;
  return f;
}

inline void report(const char* file, int line, const std::string& expr) {
  ++failures();
  std::cerr << file << ":" << line << ": FAILED: " << expr << "\n";
}

}  // namespace lt

#define LT_CAT2(a, b) a##b
#define LT_CAT(a, b) LT_CAT2(a, b)
#define TEST_CASE(name)                                                         \
  static void LT_CAT(lt_case_, __LINE__)();                                     \
  static ::lt::Registrar LT_CAT(lt_reg_, __LINE__)(name, &LT_CAT(lt_case_, __LINE__)); \
  static void LT_CAT(lt_case_, __LINE__)()

#define CHECK(expr)                                         \
  do {                                                      \
    if (!(expr)) ::lt::report(__FILE__, __LINE__, #expr);   \
  } while (0)

#define REQUIRE(expr)                                       \
  do {                                                      \
    if (!(expr)) {                                          \
      ::lt::report(__FILE__, __LINE__, #expr);              \
      throw ::lt::RequireFailed{};                          \
    }                                                       \
  } while (0)

#define CHECK_EQ(a, b)                                                                   \
  do {                                                                                   \
    const auto lt_a = (a);                                                              \
    const auto lt_b = (b);                                                              \
    if (!(lt_a == lt_b)) {                                                               \
      std::ostringstream lt_os;                                                          \
      lt_os << #a " == " #b " (" << lt_a << " vs " << lt_b << ")";                       \
      ::lt::report(__FILE__, __LINE__, lt_os.str());                                     \
    }                                                                                    \
  } while (0)
