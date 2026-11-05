#include "lockcore/events.hpp"

#include <array>

#include "lockcore/family.hpp"
#include "lockcore/spec.hpp"

namespace lockcore {

namespace {
constexpr std::array<std::string_view, EVENT_KIND_COUNT> kEventNames = {
    "contact", "bind",  "near_shear", "set",        "false_set",     "counter_rotate", "overset",
    "drop",    "stress", "break",     "wear",       "gate_align",    "detector_trip",  "open",
};
}  // namespace

std::string_view event_kind_name(EventKind k) { return kEventNames[static_cast<std::size_t>(k)]; }

bool event_kind_from_name(std::string_view name, EventKind& out) {
  for (std::size_t i = 0; i < kEventNames.size(); ++i) {
    if (kEventNames[i] == name) {
      out = static_cast<EventKind>(i);
      return true;
    }
  }
  return false;
}

std::string_view material_name(MaterialId m) {
  switch (m) {
    case MaterialId::none: return "none";
    case MaterialId::wood: return "wood";
    case MaterialId::iron: return "iron";
    case MaterialId::brass: return "brass";
    case MaterialId::steel: return "steel";
  }
  return "none";
}

int event_priority(EventKind k) {
  switch (k) {
    case EventKind::break_: return 14;
    case EventKind::stress: return 13;
    case EventKind::open: return 12;
    case EventKind::set: return 11;
    case EventKind::false_set: return 10;
    case EventKind::counter_rotate: return 9;
    case EventKind::overset: return 8;
    case EventKind::drop: return 7;
    case EventKind::detector_trip: return 6;
    case EventKind::gate_align: return 5;
    case EventKind::near_shear: return 4;
    case EventKind::bind: return 3;
    case EventKind::contact: return 2;
    case EventKind::wear: return 1;
  }
  return 0;
}

q16 material_hardness(MaterialId m) {
  switch (m) {
    case MaterialId::none: return 0;
    case MaterialId::wood: return q16_milli(200);
    case MaterialId::iron: return q16_milli(650);
    case MaterialId::brass: return q16_milli(500);
    case MaterialId::steel: return q16_milli(800);
  }
  return 0;
}

std::string_view failure_name(FailureKind f) {
  switch (f) {
    case FailureKind::none: return "none";
    case FailureKind::break_: return "break";
    case FailureKind::detector_trip: return "detector_trip";
    case FailureKind::timeout: return "timeout";
    case FailureKind::invalid_spec: return "invalid_spec";
  }
  return "none";
}

std::string_view element_state_name(ElementState s) {
  switch (s) {
    case ElementState::free: return "free";
    case ElementState::bound: return "bound";
    case ElementState::near: return "near";
    case ElementState::set: return "set";
    case ElementState::false_set: return "false_set";
    case ElementState::overset: return "overset";
    case ElementState::jammed: return "jammed";
  }
  return "free";
}

}  // namespace lockcore
