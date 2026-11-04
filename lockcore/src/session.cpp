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

LockSession::LockSession(const FamilyModule& family, LockSpec spec, ToolSet tools, ToolCondition tool)
    : family_(family),
      spec_(std::move(spec)),
      tools_(tools),
      state_(family.init_state(spec_)),
      rng_(derive_seed(spec_.seed, family.id(), static_cast<std::uint32_t>(family.rules_version()), "sim"),
           derive_stream(family.id(), "sim")) {
  state_->tool.set_wear(tool.wear);
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

bool LockSession::is_open() const { return family_.is_open(*state_); }
FailureKind LockSession::failure() const { return family_.failure(*state_); }
ViewModel LockSession::describe() const { return family_.describe(*state_); }

}  // namespace lockcore
