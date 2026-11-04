#include "lockcore/registry.hpp"

namespace lockcore {

void FamilyRegistry::add(std::unique_ptr<FamilyModule> module) { modules_.push_back(std::move(module)); }

const FamilyModule* FamilyRegistry::find(std::string_view id) const {
  for (const auto& m : modules_) {
    if (m->id() == id) return m.get();
  }
  return nullptr;
}

std::vector<const FamilyModule*> FamilyRegistry::all() const {
  std::vector<const FamilyModule*> out;
  out.reserve(modules_.size());
  for (const auto& m : modules_) out.push_back(m.get());
  return out;
}

const FamilyRegistry& FamilyRegistry::builtin() {
  static const FamilyRegistry reg = [] {
    FamilyRegistry r;
    register_builtin_families(r);
    return r;
  }();
  return reg;
}

}  // namespace lockcore
