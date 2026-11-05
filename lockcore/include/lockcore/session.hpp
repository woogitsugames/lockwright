// LockSession: one attempt at one lock, stepped at a fixed 120 Hz.
#pragma once

#include <cstdint>
#include <memory>
#include <string>
#include <vector>

#include "lockcore/family.hpp"
#include "lockcore/hash.hpp"

namespace lockcore {

struct StepOutput {
  std::vector<LockEvent> events;  // events of this step, in emission order
  q16 tension_resistance = 0;     // continuous signal, sampled every step
  q16 pick_drag = 0;              // continuous signal, sampled every step
};

// Checks what a session accepts (v0.5, T25-01/02): spec.family names this module,
// family.validate(spec) is empty (so the parameter block exists and has the right
// type) and `tools` holds family.required_tools(spec). Empty string = accepted.
std::string session_input_error(const FamilyModule& family, const LockSpec& spec, const ToolSet& tools);

class LockSession {
 public:
  // With the tools the lock requires (family.required_tools(spec)).
  LockSession(const FamilyModule& family, LockSpec spec);
  // With the player's tools. A spec or tool set that session_input_error() refuses
  // gives a rejected session: valid() false, finished() at t = 0 with
  // FailureKind::invalid_spec, step() a no-op; init_state() is never called.
  LockSession(const FamilyModule& family, LockSpec spec, ToolSet tools, ToolCondition tool = {});

  // Advances one step (1/120 s). Inputs are quantised to 1/256 first. After the
  // lock opens or fails, step() is a no-op returning no events.
  const StepOutput& step(const InputFrame& in);

  bool valid() const { return state_ != nullptr; }
  const std::string& error() const { return error_; }  // why the session was rejected

  bool is_open() const;
  FailureKind failure() const;
  bool finished() const { return is_open() || failure() != FailureKind::none; }
  std::int64_t t_step() const { return t_; }
  ViewModel describe() const;
  const LockSpec& spec() const { return spec_; }
  const FamilyModule& family() const { return family_; }
  // For a rejected session: an empty base state (failure = invalid_spec).
  const FamilyState& state() const;

  // FNV-1a 64 over every event emitted so far (fields fed little-endian).
  std::uint64_t event_hash() const { return hash_.value(); }

 private:
  const FamilyModule& family_;
  LockSpec spec_;
  ToolSet tools_;
  std::unique_ptr<FamilyState> state_;  // null when rejected
  std::string error_;
  Pcg32 rng_;
  std::int64_t t_ = 0;
  StepOutput out_;
  Fnv1a64 hash_;
};

void hash_event(Fnv1a64& h, const LockEvent& e);

}  // namespace lockcore
