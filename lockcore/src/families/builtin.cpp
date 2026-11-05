#include "lockcore/dial_safe.hpp"
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
  reg.add(dial::make_module());
  reg.add(ring::make_combo_module());
  reg.add(pin::make_dimple_module());
  reg.add(ring::make_disc_module());
  reg.add(wooden::make_egyptian_module());
  reg.add(lever::make_slider_module());
  reg.add(wafer::make_clock_module());
  reg.add(pin::make_magnetic_module());
}

}  // namespace lockcore
