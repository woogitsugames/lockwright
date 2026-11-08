extends GutTest
## VA-15: the debug FPS overlay is hidden by default (it covered "‹ Wstecz" in tester APKs);
## F3 (or a four-finger tap) shows it, the same again hides it.


func after_each() -> void:
	Quality.set_fps_overlay(false)


func test_overlay_hidden_by_default_and_toggled_by_f3() -> void:
	if Quality._fps_label == null:
		pass_test("release build: no overlay at all")
		return
	assert_false(Quality._fps_label.visible, "hidden unless asked for")
	var key := InputEventKey.new()
	key.keycode = KEY_F3
	key.pressed = true
	Quality._input(key)
	assert_true(Quality._fps_label.visible, "F3 shows it")
	var touch := InputEventScreenTouch.new()
	touch.index = 3
	touch.pressed = true
	Quality._input(touch)
	assert_false(Quality._fps_label.visible, "a four-finger tap hides it")
	var one := InputEventScreenTouch.new()
	one.index = 0
	one.pressed = true
	Quality._input(one)
	assert_false(Quality._fps_label.visible, "an ordinary tap does nothing")
