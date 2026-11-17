extends GutTest
## D-140: visual QA round 2 (VISUAL-QA-2026-11-13, the "stays" items that code can fix).
##   VQA-24  a scrolled list fades under the header instead of a hard cut (ScreenFrame.soft_top_edge)
##   VQA-29  the tutorial's note and "Start" sit at the bottom, in the thumb zone
##   VQA-23  no empty band under "Calibration"; switch labels start where the slider labels start


func test_soft_top_edge_fades_only_when_scrolled() -> void:
	var scroll := ScrollContainer.new()
	scroll.size = Vector2(300, 200)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var body := VBoxContainer.new()
	body.custom_minimum_size = Vector2(280, 1200)
	scroll.add_child(body)
	add_child_autofree(scroll)
	ScreenFrame.soft_top_edge(scroll)
	await wait_process_frames(2)
	assert_eq(scroll.clip_children, CanvasItem.CLIP_CHILDREN_ONLY, "the children are masked")
	var at_top := scroll.get_theme_stylebox("panel") as StyleBoxTexture
	assert_not_null(at_top)
	var img_top := at_top.texture.get_image()
	assert_almost_eq(img_top.get_pixel(0, 0).a, 1.0, 0.01, "at the top of the list nothing is faded")
	assert_eq(at_top.content_margin_top, 0.0, "the mask changes no layout")
	scroll.scroll_vertical = 300
	await wait_process_frames(2)
	var scrolled := scroll.get_theme_stylebox("panel") as StyleBoxTexture
	var img := scrolled.texture.get_image()
	assert_lt(img.get_pixel(0, 0).a, 0.05, "scrolled: the top edge is transparent")
	assert_almost_eq(img.get_pixel(0, ScreenFrame.FADE_DP * 2 - 1).a, 1.0, 0.01, "and the rest opaque")
	assert_eq(scrolled.texture_margin_top, float(ScreenFrame.FADE_DP), "the ramp is FADE_DP high whatever the list")
	scroll.scroll_vertical = 0
	await wait_process_frames(2)
	assert_eq(scroll.get_theme_stylebox("panel"), at_top, "back at the top: no fade")


func test_screens_with_a_list_use_the_soft_edge() -> void:
	for path: String in ["res://scenes/jobs_list.tscn", "res://scenes/settings.tscn", "res://scenes/job_verify.tscn",
			"res://scenes/showcase.tscn", "res://scenes/workshop.tscn"]:
		var sc: Node = load(path).instantiate()
		add_child_autofree(sc)
		await wait_process_frames(2)
		var scroll := sc.get_node("Frame/VBox/Scroll") as ScrollContainer
		assert_eq(scroll.clip_children, CanvasItem.CLIP_CHILDREN_ONLY, path)


func test_tutorial_start_is_at_the_bottom() -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(412, 915)
	add_child_autofree(vp)
	var sc: Control = load("res://scenes/tutorial.tscn").instantiate()
	vp.add_child(sc)
	await wait_process_frames(4)
	var v := sc.get_node("Margin/Scroll/VBox")
	var push := v.get_node("PushDown") as Control
	assert_not_null(push)
	assert_eq(push.get_index(), v.get_node("Frames").get_index() + 1, "right under the frames")
	var start := v.get_node("StartButton") as Control
	assert_gt(start.get_global_rect().end.y, 915.0 * 0.75, "the plate is in the bottom quarter (thumb zone)")


func test_calibration_result_hidden_until_there_is_one() -> void:
	var sc: Node = load("res://scenes/settings.tscn").instantiate()
	add_child_autofree(sc)
	await wait_process_frames(2)
	assert_false(sc.calibration_result.visible, "no empty band under Calibration")
	sc.calibration_result.text = "x"
	sc.calibration_result.visible = true


func test_switch_label_has_no_left_padding() -> void:
	var cb := CheckButton.new()
	add_child_autofree(cb)
	for st: String in ["normal", "pressed", "hover", "hover_pressed", "disabled"]:
		assert_eq(cb.get_theme_stylebox(st).content_margin_left, 0.0, st)
