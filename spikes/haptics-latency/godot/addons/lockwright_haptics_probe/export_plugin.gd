@tool
extends EditorExportPlugin
## Android: ships bin/lockwright-haptics-probe-release.aar (built by CI). iOS: the GDExtension in
## lockwright_haptics_probe.gdextension is picked up by Godot itself.

const AAR := "lockwright_haptics_probe/bin/lockwright-haptics-probe-release.aar"


func _get_name() -> String:
	return "LockwrightHapticsProbe"


func _supports_platform(platform: EditorExportPlatform) -> bool:
	return platform is EditorExportPlatformAndroid


func _get_android_libraries(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
	if FileAccess.file_exists("res://addons/" + AAR):
		return PackedStringArray([AAR])
	push_warning("LockwrightHapticsProbe: AAR missing at res://addons/%s" % AAR)
	return PackedStringArray()
