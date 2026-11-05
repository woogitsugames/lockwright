@tool
extends EditorExportPlugin
## Packages the native haptics AAR into Android exports (R-41).

func _get_name() -> String:
	return "LockwrightHaptics"

func _supports_platform(platform: EditorExportPlatform) -> bool:
	return platform is EditorExportPlatformAndroid

func _get_android_libraries(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
	var out := PackedStringArray()
	for aar in ["res://addons/lockwright_haptics/android/lockwright_haptics.aar",
			"res://addons/lockwright_click_audio/android/lockwright_click_audio.aar"]:
		if FileAccess.file_exists(aar):  # R-41a: ResourceLoader.exists() is false for .aar
			out.append(aar)
	return out
