// Event vocabulary shared by all families (LOCKS.md §1.6, ARCHITECTURE.md §4).
#pragma once

#include <cstdint>
#include <string_view>

#include "lockcore/fixed.hpp"

namespace lockcore {

enum class EventKind : std::uint8_t {
  contact,
  bind,
  near_shear,
  set,
  false_set,
  counter_rotate,
  overset,
  drop,
  stress,
  break_,  // "break" is a keyword; serialised as "break"
  wear,
  gate_align,
  detector_trip,
  open,
};
inline constexpr int EVENT_KIND_COUNT = 14;

enum class MaterialId : std::uint8_t { none, wood, iron, brass, steel };

// A family-specific event (e.g. "pin.serration") carries the nearest base kind in
// `kind` and a non-zero family sub-id in `sub`; the presentation layer may play it
// as the base kind when it has no dedicated asset. sub == 0 means a base event.
struct LockEvent {
  std::int64_t t_step = 0;
  EventKind kind = EventKind::contact;
  std::uint16_t sub = 0;
  std::int16_t element = -1;  // -1: not tied to one element
  q16 intensity = 0;          // [0, 1]
  MaterialId material = MaterialId::none;

  friend bool operator==(const LockEvent&, const LockEvent&) = default;
};

std::string_view event_kind_name(EventKind k);
bool event_kind_from_name(std::string_view name, EventKind& out);
std::string_view material_name(MaterialId m);

// Presentation priority, higher wins (LOCKS.md §1.6):
// break > stress > open > set > false_set > counter_rotate > overset > drop >
// detector_trip > gate_align > near_shear > bind > contact > wear.
int event_priority(EventKind k);

// Material hardness used as `contact` intensity (wood 0.2 ... steel 0.8).
q16 material_hardness(MaterialId m);

}  // namespace lockcore
