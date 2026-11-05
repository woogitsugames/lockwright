// GDExtension wrapper over lockcore::LockSession (lockcore/include/lockcore/session.hpp).
// Exposed to GDScript as class LockcoreSession.
#pragma once

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/packed_string_array.hpp>

#include <memory>

#include "lockcore/session.hpp"

class LockcoreSession : public godot::RefCounted {
	GDCLASS(LockcoreSession, godot::RefCounted)

	std::unique_ptr<lockcore::LockSession> session_;
	godot::PackedStringArray errors_;
	godot::String id_;

protected:
	static void _bind_methods();

public:
	// Creates a session for a builtin family: create("pin_tumbler", seed, tier).
	bool create(const godot::String &family, std::uint64_t seed, int tier);
	// Creates a session from an authored `lockwright.lock/1` file (lockcore's strict parser,
	// lock_from_json + validate()). On failure returns false, keeps no session and
	// last_errors() lists "path: message" lines.
	bool create_from_json(const godot::String &json);
	godot::PackedStringArray last_errors() const;
	// Authored lock id ("pin.s1"); empty for generated locks.
	godot::String spec_id() const;
	// One 1/120 s step. Returns events as Array of Dictionary
	// {kind: StringName, sub: int, element: int, intensity: float, material: StringName, tick: int}.
	godot::Array step(double tension, double pick_depth, double pick_lift, double rotate = 0.0, double push = 0.0, int tool = 0);
	// Runs lockcore's own scripted bot (solver with recorded inputs) and returns
	// {ok, reason, steps, event_hash, inputs: Array of [tension, depth, lift, rotate, push, tool]}.
	static godot::Dictionary solve(const godot::String &family, std::uint64_t seed, int tier);
	static int rules_version(const godot::String &family);
	godot::Dictionary describe() const;
	bool is_open() const;
	bool finished() const;
	godot::StringName failure() const;
	std::uint64_t event_hash() const;
	int64_t t_step() const;
};
