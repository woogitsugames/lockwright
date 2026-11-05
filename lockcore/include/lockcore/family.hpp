// The family interface (ARCHITECTURE.md §3). The core never knows concrete
// families; it talks to them only through FamilyModule.
#pragma once

#include <cstdint>
#include <memory>
#include <string>
#include <string_view>
#include <vector>

#include "lockcore/components.hpp"
#include "lockcore/difficulty.hpp"
#include "lockcore/events.hpp"
#include "lockcore/input.hpp"
#include "lockcore/json.hpp"
#include "lockcore/prng.hpp"
#include "lockcore/spec.hpp"

namespace lockcore {

// Common element states (LOCKS.md §1.4); families map their sub-states onto these.
enum class ElementState : std::uint8_t { free, bound, near, set, false_set, overset, jammed };
std::string_view element_state_name(ElementState s);

struct ElementView {
  ElementState state = ElementState::free;
  q16 position = 0;   // 0 = rest, 1 = full travel
  q16 window_lo = 0;  // set window, for tutorial overlays
  q16 window_hi = 0;
  std::uint8_t variant = 0;  // family-defined (e.g. standard / spool / serrated)
};

// Read-only snapshot for the presentation layer.
struct ViewModel {
  std::vector<ElementView> elements;
  int pick_element = -1;
  q16 pick_lift = 0;
  q16 tension = 0;
  q16 core_rotation = 0;  // fraction of the opening rotation (1.0 = 90 degrees)
  q16 tension_resistance = 0;
  q16 pick_drag = 0;
  q16 stress = 0;  // S / S_max
  bool open = false;
  FailureKind failure = FailureKind::none;
  // v0.4 (additive, read-only; not part of any hash). 0 where not applicable.
  q16 hold_progress = 0;   // wooden_pin: all pegs set and bolt held, fraction of open_hold_steps
  q16 reset_progress = 0;  // lever_detector: rotate-back held while tripped, fraction of reset_steps
};

// Base of every family's mutable state. Common components live here so that the
// session can expose them uniformly.
struct FamilyState {
  virtual ~FamilyState() = default;
  ToolStress tool;
  TensionHold hold;
  bool open = false;
  FailureKind failure = FailureKind::none;
};

// Per-step context. Families get randomness only from here (no wall clock).
struct StepCtx {
  std::int64_t t_step = 0;
  Pcg32* rng = nullptr;  // session stream for this family
  EventSink* events = nullptr;
  const ToolSet* tools = nullptr;
  // Continuous signals, written by the family every step.
  q16 tension_resistance = 0;
  q16 pick_drag = 0;
};

// Plan produced by the analytic oracle and executed by the scripted bot.
// It is expressed in generic "lift an element" terms so one bot serves every
// lift-based family.
struct PlanStep {
  int element = 0;
  q16 depth = 0;          // pick_depth that addresses the element
  q16 tension = 0;        // tension to hold while lifting
  q16 approach_from = 0;  // lift quickly up to here, then slowly
  q16 lift_cap = 0;       // never lift above this
  bool has_false_gate = false;  // spool: expect false_set, then use cr_tension
  q16 cr_tension = 0;
};

struct Plan {
  std::vector<PlanStep> steps;
  q16 release_tension = 0;  // tension that clears an overset
  q16 t_hold = 0;
  bool drop_all = true;     // drop clears every set element (else only the last)
  q16 lift_sign = Q16_ONE;  // +1 lift up
};

struct OracleReport {
  bool ok = false;
  std::string reason;
  Plan plan;
  q16 min_band = 0;    // narrowest tension band over the plan
  q16 min_window = 0;  // narrowest position window over the plan
};

struct SolveReport {
  bool ok = false;
  std::string reason;
  std::int64_t steps = 0;
  std::int32_t drops = 0;
  std::int32_t oversets = 0;
  std::int32_t false_sets = 0;
  std::int32_t retries = 0;
  q16 peak_stress = 0;  // max S / S_max seen
  std::uint64_t event_hash = 0;
  std::vector<InputFrame> inputs;  // quantised input log (filled when requested)
};

struct SolveOptions {
  std::uint64_t bot_seed = 1;
  bool record_inputs = false;
};

// Verifier bots (LOCKS.md §1.9), v0.2 (additive).
//  scripted: stage 2, the hard gate (same as solver());
//  clumsy:   oracle plan with worse human limits and no overset knowledge (soft metric);
//  feeling:  stage 3, sees only events and the continuous signals, never the state
//            or the spec (soft metric for difficulty calibration).
enum class BotKind : std::uint8_t { scripted, clumsy, feeling };

class FamilyModule {
 public:
  virtual ~FamilyModule() = default;

  virtual std::string_view id() const = 0;
  virtual std::int32_t rules_version() const = 0;
  virtual std::uint32_t input_mask() const = 0;
  virtual ToolSet required_tools(const LockSpec& spec) const = 0;

  // Tiers this family supports and the difficulty vector of each.
  virtual int min_tier() const = 0;
  virtual int max_tier() const = 0;
  virtual DifficultyVector difficulty_for_tier(int tier) const = 0;

  // Pure and deterministic. Retries internally (seed' = hash(seed, attempt)) until
  // the oracle accepts the lock. If all 16 attempts are refused (only possible for a
  // difficulty vector outside difficulty_for_tier()), the last attempt is returned
  // anyway: callers with their own vectors check oracle(spec, required_tools(spec)).ok
  // (run_replay() does, T25-03).
  virtual LockSpec generate(std::uint64_t seed, const DifficultyVector& d) const = 0;
  virtual std::vector<SpecError> validate(const LockSpec& spec) const = 0;

  virtual std::unique_ptr<FamilyState> init_state(const LockSpec& spec) const = 0;
  virtual void step(FamilyState& state, const InputFrame& in, StepCtx& ctx) const = 0;
  virtual bool is_open(const FamilyState& s) const { return s.open; }
  virtual FailureKind failure(const FamilyState& s) const { return s.failure; }
  virtual ViewModel describe(const FamilyState& s) const = 0;

  // Verifier: analytic oracle, then the scripted human-limited bot through step().
  virtual OracleReport oracle(const LockSpec& spec, const ToolSet& tools) const = 0;
  virtual SolveReport solver(const LockSpec& spec, const ToolSet& tools,
                             const SolveOptions& opt = {}) const;
  // v0.2 (additive). Budget: scripted = half the tier time limit, clumsy and
  // feeling = the full tier time limit. The default serves lift-based families
  // (run_plan_bot / run_feel_bot); other families override it.
  virtual SolveReport run_bot(BotKind kind, const LockSpec& spec, const ToolSet& tools,
                              const SolveOptions& opt = {}) const;

  // `lockwright.lock/1` "spec" block.
  virtual json::Value params_to_json(const FamilyParams& p) const = 0;
  virtual std::shared_ptr<const FamilyParams> params_from_json(const json::Value& v,
                                                               std::vector<SpecError>& errors) const = 0;

  // Name of a family event sub-id ("pin.serration"); empty for unknown.
  virtual std::string_view event_name(std::uint16_t sub) const = 0;
};

}  // namespace lockcore
