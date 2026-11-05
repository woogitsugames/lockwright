@tool
extends EditorPlugin
## Enables the Lockwright haptics bridge in exports (R-41c: _enter_tree, not _enable_plugin).

var _export_plugin: EditorExportPlugin

func _enter_tree() -> void:
	_export_plugin = preload("res://addons/lockwright_haptics/export_plugin.gd").new()
	add_export_plugin(_export_plugin)

func _exit_tree() -> void:
	if _export_plugin != null:
		remove_export_plugin(_export_plugin)
		_export_plugin = null
