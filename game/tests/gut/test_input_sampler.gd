extends GutTest
## R-02: releasing the right thumb must reset lift/rotate/push; releasing the left
## thumb must reset tension; a new right-thumb touch with a different index is accepted.

func _make_sampler() -> InputSampler:
	var s := InputSampler.new()
	add_child_autofree(s)
	return s

func _touch(idx: int, pos: Vector2, pressed: bool) -> InputEventScreenTouch:
	var t := InputEventScreenTouch.new()
	t.index = idx
	t.position = pos
	t.pressed = pressed
	return t

func _drag(idx: int, pos: Vector2) -> InputEventScreenDrag:
	var d := InputEventScreenDrag.new()
	d.index = idx
	d.position = pos
	return d

func _size(s: InputSampler) -> Vector2:
	var v := s.get_viewport().get_visible_rect().size
	return v if v.x > 0.0 and v.y > 0.0 else Vector2(412, 915)


func test_right_thumb_release_resets_lift() -> void:
	var s := _make_sampler()
	var sz := _size(s)
	var right_x := sz.x * 0.75
	s._unhandled_input(_touch(0, Vector2(right_x, sz.y * 0.6), true))   # right zone press
	s._unhandled_input(_drag(0, Vector2(right_x, sz.y * 0.3)))           # lift up
	s._physics_process(0.016)
	assert_gt(s.pick_lift, 0.0, "lift should be positive after drag")
	s._unhandled_input(_touch(0, Vector2(right_x, sz.y * 0.3), false))  # release
	for i in 8:
		s._physics_process(0.016)
	assert_eq(s._touch_pick, -1, "pick touch index must reset on release")
	assert_lt(absf(s.pick_lift), 0.02, "lift must decay to 0 after release (R-02)")

func test_left_thumb_release_resets_tension() -> void:
	var s := _make_sampler()
	var sz := _size(s)
	s._unhandled_input(_touch(1, Vector2(sz.x * 0.25, sz.y * 0.2), true))  # left zone, top = high tension
	s._physics_process(0.016)
	assert_gt(s.tension, 0.3)
	s._unhandled_input(_touch(1, Vector2(sz.x * 0.25, sz.y * 0.2), false))
	for i in 8:
		s._physics_process(0.016)
	assert_eq(s._touch_tension, -1)
	assert_lt(s.tension, 0.02, "tension must decay to 0 after release")

func test_new_right_thumb_index_accepted_after_release() -> void:
	var s := _make_sampler()
	var sz := _size(s)
	var right_x := sz.x * 0.75
	s._unhandled_input(_touch(0, Vector2(right_x, sz.y * 0.5), true))
	s._unhandled_input(_touch(0, Vector2(right_x, sz.y * 0.5), false))
	s._unhandled_input(_touch(3, Vector2(right_x, sz.y * 0.5), true))   # different index
	s._physics_process(0.016)
	assert_eq(s._touch_pick, 3, "a new right-zone touch must register (R-02)")
