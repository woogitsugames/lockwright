// Family registry. Adding a family means adding a module and registering it; the
// core stays unchanged.
#pragma once

#include <memory>
#include <string_view>
#include <vector>

#include "lockcore/family.hpp"

namespace lockcore {

class FamilyRegistry {
 public:
  void add(std::unique_ptr<FamilyModule> module);
  const FamilyModule* find(std::string_view id) const;
  std::vector<const FamilyModule*> all() const;

  // Registry with every family shipped in lockcore.
  static const FamilyRegistry& builtin();

 private:
  std::vector<std::unique_ptr<FamilyModule>> modules_;
};

// Explicit registration (no static-initialisation tricks).
void register_builtin_families(FamilyRegistry& reg);

}  // namespace lockcore
