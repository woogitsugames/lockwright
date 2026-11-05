// GDExtension wrapper over lockcore::LockSession (lockcore/include/lockcore/session.hpp).
// Exposed to GDScript as class LockcoreSession.
#pragma once

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/core/class_db.hpp>

#include <memory>

#include "lockcore/session.hpp"

class LockcoreSession : public godot::RefCounted {
	GDCLASS(LockcoreSession, godot::RefCounted)

	std::unique_ptr<lockcore::LockSession> session_;

protected:
	static void _bind_methods();

public:
	// Creates a session for a builtin family: create("pin_tumbler", seed, tier).
	bool create(const godot::String &family, std::uint64_t seed, int tier);
	// One 1/120 s step. Returns events as Array of Dictionary
	// {kind: StringName, sub: int, element: int, intensity: float, material: StringName, tick: int}.
	godot::Array step(double tension, double pick_depth, double pick_lift, double rotate = 0.0, double push = 0.0, int tool = 0);
	godot::Dictionary describe() const;
	bool is_open() const;
	bool finished() const;
	godot::StringName failure() const;
	std::uint64_t event_hash() const;
	int64_t t_step() const;
};
