class_name LockDiscDetainerView
extends LockComboView
## D-59: plan-B lock screen for the disc detainer (LOCKS.md §2.21). lockcore runs it on the ring_combo
## module, so the screen is the thumbwheel lock's view with its own Cycles plates
## (art/blender/plates/combo_plate.py --family disc_detainer): the same quarter cut-away of the core,
## six thin discs with an index line and detent nicks instead of digits (8 positions), and the sidebar
## UNDER the discs with one sprung finger per disc that rises into the disc's gate at 6 o'clock
## (layers.json tooth_dir -1). Torque let go = the fingers drop away from the rims; binding disc =
## its finger on the rim; set = finger up in the gate; open = the core's tail bolt is thrown.

const D_DIR := "res://assets/photoreal_families/disc_detainer/photo/"


func _dir() -> String:
	return D_DIR


## lockcore's disc position falls while the thumb pushes up: the band turns with the thumb.
func _reel_sign() -> float:
	return -1.0


func present(vm: Dictionary, input: Dictionary, delta: float = 1.0 / 120.0) -> void:
	super.present(vm, input, delta)
	_bar_dx = 0.0  # the sidebar does not slide along the core; it rises with its fingers
