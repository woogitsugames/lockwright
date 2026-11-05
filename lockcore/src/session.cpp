#include "lockcore/session.hpp"

namespace lockcore {

void hash_event(Fnv1a64& h, const LockEvent& e) {
  h.i64(e.t_step);
  h.byte(static_cast<std::uint8_t>(e.kind));
  h.u32(e.sub);
  h.i32(e.element);
  h.i32(e.intensity);
  h.byte(static_cast<std::uint8_t>(e.material));
}

std::string session_input_error(const FamilyModule& family, const LockSpec& spec, const ToolSet& tools) {
  if (spec.family != family.id()) return "spec is for family '" + spec.family + "', module is '" + std::string(family.id()) + "'";
  if (const auto errs = family.validate(spec); !errs.empty()) return "invalid spec: " + errs.front().path + ": " + errs.front().message;
  if (!tools.has(family.required_tools(spec).bits)) return "missing required tools";
  return {};
}

namespace {
ToolSet tools_for(const FamilyModule& family, const LockSpec& spec) {
  // required_tools() may read the parameter block, so only for a valid spec.
  return family.validate(spec).empty() ? family.required_tools(spec) : ToolSet{};
}
}  // namespace

LockSession::LockSession(const FamilyModule& family, LockSpec spec)
    : LockSession(family, spec, tools_for(family, spec)) {}

LockSession::LockSession(const FamilyModule& family, LockSpec spec, ToolSet tools, ToolCondition tool)
    : family_(family),
      spec_(std::move(spec)),
      tools_(tools),
      error_(session_input_error(family, spec_, tools_)),
      rng_(derive_seed(spec_.seed, family.id(), static_cast<std::uint32_t>(family.rules_version()), "sim"),
           derive_stream(family.id(), "sim")) {
  if (!error_.empty()) return;
  state_ = family.init_state(spec_);
  state_->tool.set_wear(tool.wear);
}

const FamilyState& LockSession::state() const {
  static const FamilyState rejected = [] {
    FamilyState s;
    s.failure = FailureKind::invalid_spec;
    return s;
  }();
  return state_ ? *state_ : rejected;
}

const StepOutput& LockSession::step(const InputFrame& in) {
  out_.events.clear();
  out_.tension_resistance = 0;
  out_.pick_drag = 0;
  if (finished()) return out_;

  EventSink sink(out_.events);
  StepCtx ctx;
  ctx.t_step = t_;
  ctx.rng = &rng_;
  ctx.events = &sink;
  ctx.tools = &tools_;
  family_.step(*state_, quantize(in), ctx);
  out_.tension_resistance = ctx.tension_resistance;
  out_.pick_drag = ctx.pick_drag;
  for (const auto& e : out_.events) hash_event(hash_, e);
  ++t_;
  return out_;
}

bool LockSession::is_open() const { return state_ && family_.is_open(*state_); }
FailureKind LockSession::failure() const { return state_ ? family_.failure(*state_) : FailureKind::invalid_spec; }
ViewModel LockSession::describe() const {
  if (state_) return family_.describe(*state_);
  ViewModel vm;
  vm.failure = FailureKind::invalid_spec;
  return vm;
}

}  // namespace lockcore
