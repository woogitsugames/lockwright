#include "lockcore/lever.hpp"
#include "lockcore/pin_tumbler.hpp"
#include "lockcore/registry.hpp"
#include "lockcore/ring_combo.hpp"
#include "lockcore/wafer.hpp"
#include "lockcore/warded.hpp"
#include "lockcore/wooden_pin.hpp"

namespace lockcore {

void register_builtin_families(FamilyRegistry& reg) {
  reg.add(pin::make_module());
  reg.add(wafer::make_module());
  reg.add(wooden::make_module());
  reg.add(lever::make_module());
  reg.add(lever::make_detector_module());
  reg.add(ring::make_module());
  reg.add(warded::make_module());
}

}  // namespace lockcore
