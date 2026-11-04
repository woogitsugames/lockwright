// Spike 1 Godot module for iOS: same effect as native-ios/Sources/HapticCore.swift, in Objective-C++
// (Core Haptics has an Objective-C API; a Swift static library would need the Swift runtime linked into
// Godot's exported Xcode project, which this spike avoids).
#pragma once
#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/dictionary.hpp>

namespace lw {

class LockwrightHapticsProbeIOS : public godot::RefCounted {
  GDCLASS(LockwrightHapticsProbeIOS, godot::RefCounted)

 public:
  LockwrightHapticsProbeIOS();
  ~LockwrightHapticsProbeIOS() override;

  godot::Dictionary transient(double intensity, double sharpness);
  void continuous_start();
  double continuous_update(double intensity, double sharpness);
  void continuous_stop();
  godot::Dictionary capabilities();

 protected:
  static void _bind_methods();

 private:
  void* impl_ = nullptr;  // LWProbeImpl (Objective-C, retained)
};

}  // namespace lw
