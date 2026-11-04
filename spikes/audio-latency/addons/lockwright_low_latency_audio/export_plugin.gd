@tool
extends EditorExportPlugin
## Adds bin/lockwright-low-latency-audio-release.aar (built by Gradle, copied by CI) to Android exports.
## Paths returned by _get_android_libraries are relative to res://addons/.

const AAR := "lockwright_low_latency_audio/bin/lockwright-low-latency-audio-release.aar"


func _get_name() -> String:
	return "LockwrightLowLatencyAudio"


func _supports_platform(platform: EditorExportPlatform) -> bool:
	return platform is EditorExportPlatformAndroid


func _get_android_libraries(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
	if FileAccess.file_exists("res://addons/" + AAR):
		return PackedStringArray([AAR])
	push_warning("LockwrightLowLatencyAudio: AAR missing at res://addons/%s, exporting without it" % AAR)
	return PackedStringArray()
