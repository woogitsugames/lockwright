class_name A11yHit
extends Control
## A touch area drawn by its parent (no text of its own) that a screen reader still sees as a
## named button: UiA11y.name_button() sets the localized name and the activate action (D-90).


func _notification(what: int) -> void:
	if what == NOTIFICATION_ACCESSIBILITY_UPDATE:
		UiA11y.update_button_role(self)
