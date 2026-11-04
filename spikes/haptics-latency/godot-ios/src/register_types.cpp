#include <gdextension_interface.h>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/defs.hpp>
#include <godot_cpp/godot.hpp>

#include "haptics_probe_ios.h"

using namespace godot;

static void init_module(ModuleInitializationLevel level) {
  if (level == MODULE_INITIALIZATION_LEVEL_SCENE) GDREGISTER_CLASS(lw::LockwrightHapticsProbeIOS);
}
static void uninit_module(ModuleInitializationLevel) {}

extern "C" GDExtensionBool GDE_EXPORT lw_haptics_probe_init(GDExtensionInterfaceGetProcAddress get, GDExtensionClassLibraryPtr lib,
                                                           GDExtensionInitialization* init) {
  GDExtensionBinding::InitObject o(get, lib, init);
  o.register_initializer(init_module);
  o.register_terminator(uninit_module);
  o.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);
  return o.init();
}
