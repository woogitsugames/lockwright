#include "lockcore_session_gd.h"

#include <godot_cpp/variant/utility_functions.hpp>

#include <algorithm>

#include "lockcore/registry.hpp"

using namespace godot;

void LockcoreSession::_bind_methods() {
	ClassDB::bind_method(D_METHOD("create", "family", "seed", "tier"), &LockcoreSession::create);
	ClassDB::bind_method(D_METHOD("step", "tension", "pick_depth", "pick_lift"), &LockcoreSession::step);
	ClassDB::bind_method(D_METHOD("describe"), &LockcoreSession::describe);
	ClassDB::bind_method(D_METHOD("is_open"), &LockcoreSession::is_open);
	ClassDB::bind_method(D_METHOD("finished"), &LockcoreSession::finished);
	ClassDB::bind_method(D_METHOD("failure"), &LockcoreSession::failure);
	ClassDB::bind_method(D_METHOD("event_hash"), &LockcoreSession::event_hash);
	ClassDB::bind_method(D_METHOD("t_step"), &LockcoreSession::t_step);
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

Array LockcoreSession::step(double tension, double pick_depth, double pick_lift) {
	Array out;
	if (session_ == nullptr) {
		return out;
	}
	lockcore::InputFrame in;
	in.tension = lockcore::q16(std::clamp(tension, 0.0, 1.0) * lockcore::Q16_ONE);
	in.pick_depth = lockcore::q16(std::clamp(pick_depth, 0.0, 1.0) * lockcore::Q16_ONE);
	in.pick_lift = lockcore::q16(std::clamp(pick_lift, -1.0, 1.0) * lockcore::Q16_ONE);
	const lockcore::StepOutput &so = session_->step(in);
	for (const lockcore::LockEvent &e : so.events) {
		Dictionary d;
		d["kind"] = StringName(lockcore::event_kind_name(e.kind).data());
		d["sub"] = e.sub;
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
		elements.push_back(ed);
	}
	vm["elements"] = elements;
	vm["pick_element"] = v.pick_element;
	vm["tension"] = static_cast<double>(v.tension) / lockcore::Q16_ONE;
	vm["core_rotation"] = static_cast<double>(v.core_rotation) / lockcore::Q16_ONE;
	vm["tension_resistance"] = static_cast<double>(v.tension_resistance) / lockcore::Q16_ONE;
	vm["pick_drag"] = static_cast<double>(v.pick_drag) / lockcore::Q16_ONE;
	vm["stress"] = static_cast<double>(v.stress) / lockcore::Q16_ONE;
	vm["open"] = v.open;
	vm["failure"] = StringName(lockcore::failure_name(v.failure).data());
	return vm;
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
