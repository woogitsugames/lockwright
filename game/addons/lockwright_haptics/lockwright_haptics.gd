@tool
extends EditorPlugin
## Enables the Lockwright haptics bridge (Android AAR / iOS) in exports.

func _enable_plugin() -> void:
	add_export_plugin(preload("res://addons/lockwright_haptics/export_plugin.gd").new())

func _disable_plugin() -> void:
	pass
