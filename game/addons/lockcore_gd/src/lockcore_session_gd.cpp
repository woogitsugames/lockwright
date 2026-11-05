#include "lockcore_session_gd.h"

#include <godot_cpp/variant/utility_functions.hpp>

#include <algorithm>

#include "lockcore/registry.hpp"
#include "lockcore/bot.hpp"

using namespace godot;

void LockcoreSession::_bind_methods() {
	ClassDB::bind_method(D_METHOD("create", "family", "seed", "tier"), &LockcoreSession::create);
	ClassDB::bind_method(D_METHOD("step", "tension", "pick_depth", "pick_lift", "rotate", "push", "tool"), &LockcoreSession::step, DEFVAL(0.0), DEFVAL(0.0), DEFVAL(0));
	ClassDB::bind_method(D_METHOD("describe"), &LockcoreSession::describe);
	ClassDB::bind_method(D_METHOD("is_open"), &LockcoreSession::is_open);
	ClassDB::bind_method(D_METHOD("finished"), &LockcoreSession::finished);
	ClassDB::bind_method(D_METHOD("failure"), &LockcoreSession::failure);
	ClassDB::bind_method(D_METHOD("event_hash"), &LockcoreSession::event_hash);
	ClassDB::bind_method(D_METHOD("t_step"), &LockcoreSession::t_step);
	ClassDB::bind_static_method("LockcoreSession", D_METHOD("solve", "family", "seed", "tier"), &LockcoreSession::solve);
	ClassDB::bind_static_method("LockcoreSession", D_METHOD("rules_version", "family"), &LockcoreSession::rules_version);
}

bool LockcoreSession::create(const String &family, std::uint64_t seed, int tier) {
	const lockcore::FamilyModule *module = lockcore::FamilyRegistry::builtin().find(
			std::string_view(family.utf8().get_data()));
	if (module == nullptr) {
		UtilityFunctions::printerr("LockcoreSession: unknown family ", family);
		return false;
	}
	lockcore::DifficultyVector d = module->difficulty_for_tier(tier);
	lockcore::LockSpec spec = module->generate(seed, d);
	spec.family = std::string(family.utf8().get_data());
	spec.seed = seed;
	session_ = std::make_unique<lockcore::LockSession>(*module, spec);
	return true;
}

Array LockcoreSession::step(double tension, double pick_depth, double pick_lift, double rotate, double push, int tool) {
	Array out;
	if (session_ == nullptr) {
		return out;
	}
	lockcore::InputFrame in;
	in.tension = lockcore::q16(std::lround(std::clamp(tension, 0.0, 1.0) * 256.0) / 256.0 * lockcore::Q16_ONE);
	in.pick_depth = lockcore::q16(std::lround(std::clamp(pick_depth, 0.0, 1.0) * 256.0) / 256.0 * lockcore::Q16_ONE);
	in.pick_lift = lockcore::q16(std::lround(std::clamp(pick_lift, -1.0, 1.0) * 256.0) / 256.0 * lockcore::Q16_ONE);
	in.rotate = lockcore::q16(std::lround(std::clamp(rotate, -1.0, 1.0) * 256.0) / 256.0 * lockcore::Q16_ONE);
	in.push = lockcore::q16(std::lround(std::clamp(push, 0.0, 1.0) * 64.0) / 64.0 * lockcore::Q16_ONE);
	in.tool = static_cast<std::uint8_t>(tool);
	const lockcore::StepOutput &so = session_->step(in);
	for (const lockcore::LockEvent &e : so.events) {
		Dictionary d;
		d["kind"] = StringName(lockcore::event_kind_name(e.kind).data());
		d["sub"] = e.sub;
		d["name"] = StringName((std::string(lockcore::event_kind_name(e.kind)) + "." + std::to_string(e.sub)).c_str());
		d["element"] = e.element;
		d["intensity"] = static_cast<double>(e.intensity) / lockcore::Q16_ONE;
		d["material"] = StringName(lockcore::material_name(e.material).data());
		d["tick"] = static_cast<int64_t>(e.t_step);
		out.push_back(d);
	}
	return out;
}

Dictionary LockcoreSession::describe() const {
	Dictionary vm;
	if (session_ == nullptr) {
		return vm;
	}
	lockcore::ViewModel v = session_->describe();
	Array elements;
	for (const lockcore::ElementView &e : v.elements) {
		Dictionary ed;
		ed["state"] = StringName(lockcore::element_state_name(e.state).data());
		ed["position"] = static_cast<double>(e.position) / lockcore::Q16_ONE;
		ed["variant"] = e.variant;
		ed["window_lo"] = static_cast<double>(e.window_lo) / lockcore::Q16_ONE;
		ed["window_hi"] = static_cast<double>(e.window_hi) / lockcore::Q16_ONE;
		elements.push_back(ed);
	}
	vm["elements"] = elements;
	vm["pick_element"] = v.pick_element;
	vm["tension"] = static_cast<double>(v.tension) / lockcore::Q16_ONE;
	vm["pick_lift"] = static_cast<double>(v.pick_lift) / lockcore::Q16_ONE;
	vm["core_rotation"] = static_cast<double>(v.core_rotation) / lockcore::Q16_ONE;
	vm["tension_resistance"] = static_cast<double>(v.tension_resistance) / lockcore::Q16_ONE;
	vm["pick_drag"] = static_cast<double>(v.pick_drag) / lockcore::Q16_ONE;
	vm["stress"] = static_cast<double>(v.stress) / lockcore::Q16_ONE;
	vm["hold_progress"] = static_cast<double>(v.hold_progress) / lockcore::Q16_ONE;  // v0.4, FEEL F-07
	vm["reset_progress"] = static_cast<double>(v.reset_progress) / lockcore::Q16_ONE;
	vm["open"] = v.open;
	vm["failure"] = StringName(lockcore::failure_name(v.failure).data());
	return vm;
}

Dictionary LockcoreSession::solve(const String &family, std::uint64_t seed, int tier) {
	Dictionary out;
	const lockcore::FamilyModule *module = lockcore::FamilyRegistry::builtin().find(
			std::string_view(family.utf8().get_data()));
	if (module == nullptr) {
		out["ok"] = false;
		out["reason"] = "unknown family";
		return out;
	}
	lockcore::LockSpec spec = module->generate(seed, module->difficulty_for_tier(tier));
	spec.family = std::string(family.utf8().get_data());
	spec.seed = seed;
	lockcore::SolveOptions opt;
	opt.record_inputs = true;
	lockcore::SolveReport rep = module->solver(spec, module->required_tools(spec), opt);
	out["ok"] = rep.ok;
	out["reason"] = String(rep.reason.c_str());
	out["steps"] = static_cast<int64_t>(rep.steps);
	out["event_hash"] = static_cast<int64_t>(rep.event_hash);
	Array inputs;
	for (const lockcore::InputFrame &f : rep.inputs) {
		Array row;
		row.append(static_cast<double>(f.tension) / lockcore::Q16_ONE);
		row.append(static_cast<double>(f.pick_depth) / lockcore::Q16_ONE);
		row.append(static_cast<double>(f.pick_lift) / lockcore::Q16_ONE);
		row.append(static_cast<double>(f.rotate) / lockcore::Q16_ONE);
		row.append(static_cast<double>(f.push) / lockcore::Q16_ONE);
		row.append(static_cast<int64_t>(f.tool));
		inputs.append(row);
	}
	out["inputs"] = inputs;
	return out;
}

int LockcoreSession::rules_version(const String &family) {
	const lockcore::FamilyModule *module = lockcore::FamilyRegistry::builtin().find(
			std::string_view(family.utf8().get_data()));
	return module == nullptr ? 0 : module->rules_version();
}

bool LockcoreSession::is_open() const { return session_ != nullptr && session_->is_open(); }
bool LockcoreSession::finished() const { return session_ != nullptr && session_->finished(); }

StringName LockcoreSession::failure() const {
	if (session_ == nullptr) {
		return StringName("none");
	}
	return StringName(lockcore::failure_name(session_->failure()).data());
}

std::uint64_t LockcoreSession::event_hash() const { return session_ == nullptr ? 0 : session_->event_hash(); }
int64_t LockcoreSession::t_step() const { return session_ == nullptr ? 0 : session_->t_step(); }
