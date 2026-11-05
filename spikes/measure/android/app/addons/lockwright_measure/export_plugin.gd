@tool
extends EditorExportPlugin

const AAR := "lockwright_measure/bin/lockwright-measure-release.aar"


func _get_name() -> String:
	return "LockwrightMeasure"


func _supports_platform(platform: EditorExportPlatform) -> bool:
	return platform is EditorExportPlatformAndroid


func _get_android_libraries(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
	if FileAccess.file_exists("res://addons/" + AAR):
		return PackedStringArray([AAR])
	push_warning("LockwrightMeasure: AAR missing at res://addons/%s" % AAR)
	return PackedStringArray()
