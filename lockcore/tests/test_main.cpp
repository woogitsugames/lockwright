#include <cstring>

#include "testing.hpp"

int main(int argc, char** argv) {
  const char* filter = argc > 1 ? argv[1] : nullptr;
  int run = 0;
  for (const auto& c : lt::registry()) {
    if (filter != nullptr && std::strstr(c.name, filter) == nullptr) continue;
    ++run;
    const int before = lt::failures();
    try {
      c.fn();
    } catch (const lt::RequireFailed&) {
    } catch (const std::exception& e) {
      lt::report(__FILE__, __LINE__, std::string("exception: ") + e.what());
    }
    std::cout << (lt::failures() == before ? "[ ok ] " : "[FAIL] ") << c.name << "\n";
  }
  std::cout << run << " test cases, " << lt::failures() << " failed checks\n";
  return lt::failures() == 0 && run > 0 ? 0 : 1;
}
