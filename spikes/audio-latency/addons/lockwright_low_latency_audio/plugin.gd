@tool
extends EditorPlugin
## Registers the export plugin that ships the Oboe AAR in Android exports.

var _export: EditorExportPlugin


func _enter_tree() -> void:
	_export = preload("res://addons/lockwright_low_latency_audio/export_plugin.gd").new()
	add_export_plugin(_export)


func _exit_tree() -> void:
	remove_export_plugin(_export)
	_export = null
