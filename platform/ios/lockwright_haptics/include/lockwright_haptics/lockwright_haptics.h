// LockwrightHaptics — GDExtension singleton bridging to Core Haptics (docs/TECH.md §2.1, §2.5).
// iOS only: continuous resistance via CHHapticAdvancedPatternPlayer + sendParameters,
// transients in a separate player, engine stopped/reset handlers, UIImpactFeedbackGenerator
// fallback, log-only on devices without haptics (iPad).
#pragma once

#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/core/class_db.hpp>

namespace lockwright {

class LockwrightHaptics : public godot::Node {
	GDCLASS(LockwrightHaptics, godot::Node)

	void *engine_impl = nullptr; // opaque ObjC++ bridge (CHHapticEngine etc.)

public:
	static void _bind_methods();

	LockwrightHaptics();
	~LockwrightHaptics();

	void play(const godot::StringName &event, double intensity, const godot::StringName &material);
	void begin_continuous(const godot::StringName &id);
	void update_continuous(const godot::StringName &id, double intensity, double sharpness);
	void end_continuous(const godot::StringName &id);
	godot::Dictionary capabilities() const;
	void stop_all();
};

} // namespace lockwright
