@tool
extends EditorExportPlugin
## Packages the native haptics AAR into Android exports.

func _get_name() -> String:
	return "LockwrightHaptics"

func _get_android_libraries(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
	var aar := "res://addons/lockwright_haptics/android/lockwright_haptics.aar"
	if ResourceLoader.exists(aar):
		return PackedStringArray([aar])
	return PackedStringArray()
