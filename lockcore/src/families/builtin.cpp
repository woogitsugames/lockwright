#include "lockcore/pin_tumbler.hpp"
#include "lockcore/registry.hpp"
#include "lockcore/wafer.hpp"
#include "lockcore/wooden_pin.hpp"

namespace lockcore {

void register_builtin_families(FamilyRegistry& reg) {
  reg.add(pin::make_module());
  reg.add(wafer::make_module());
  reg.add(wooden::make_module());
}

}  // namespace lockcore
