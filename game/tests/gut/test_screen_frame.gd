extends GutTest
## D-121: ScreenFrame's deferred first fit (fit_title, fit_button_text) used to capture the label in a
## lambda. A screen that closed in the same frame (GUT's autofree, a fast back tap) freed the label
## before the deferred call ran, and the full run printed "SCRIPT ERROR ... screen_frame.gd:149"
## (lambda capture freed). The fit now takes the instance id and does nothing for a node that is gone.


func _label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.size = Vector2(160, 40)
	return l


func test_title_freed_before_the_deferred_fit_is_no_error() -> void:
	var l := _label("Pogotowie zamkowe")
	add_child(l)
	ScreenFrame.fit_title(l)
	l.free()
	await wait_process_frames(2)
	assert_engine_error_count(0, "no script error from the deferred fit of a freed title")
	var q := _label("Pogotowie zamkowe")
	add_child(q)
	ScreenFrame.fit_title(q)
	q.queue_free()
	await wait_process_frames(2)
	assert_engine_error_count(0, "nor from a title that was queued for deletion")


func test_button_freed_before_the_deferred_fit_is_no_error() -> void:
	var b := Button.new()
	b.text = "Ćwiczenia"
	add_child(b)
	ScreenFrame.fit_button_text(b)
	b.free()
	await wait_process_frames(2)
	assert_engine_error_count(0, "no script error from the deferred fit of a freed button")


func test_fit_of_a_stale_id_does_nothing() -> void:
	var l := _label("x")
	var id := l.get_instance_id()
	l.free()
	ScreenFrame._fit_title_now(id, 28, 17, 22)
	ScreenFrame._fit_button_now(id, 16, 13)
	ScreenFrame._fit_title_now(get_instance_id(), 28, 17, 22)  # not a Label
	assert_engine_error_count(0)


func test_title_still_fits_now_and_on_resize() -> void:
	var l := _label("Bardzo długi tytuł ekranu ustawień dostępności")
	l.size = Vector2(400, 40)
	add_child_autofree(l)
	ScreenFrame.fit_title(l)
	await wait_process_frames(2)
	var font := l.get_theme_font(&"font")
	var wide := l.get_theme_font_size(&"font_size")
	assert_eq(wide, ScreenFrame.title_size(font, l.text, 400.0, UiA11y.fs(28), UiA11y.fs(17), UiA11y.fs(22)), "first fit ran (deferred)")
	assert_gt(l.custom_minimum_size.y, 0.0, "the row height follows the fitted text")
	l.size = Vector2(150, 40)  # emits resized
	await wait_process_frames(2)
	var narrow := l.get_theme_font_size(&"font_size")
	assert_eq(narrow, ScreenFrame.title_size(font, l.text, 150.0, UiA11y.fs(28), UiA11y.fs(17), UiA11y.fs(22)), "fits again when the label is resized")
	assert_lt(narrow, wide, "a narrower header gets smaller type")
	assert_true(l.has_meta(&"fit_title"))
	ScreenFrame.fit_title(l)  # a second call (new text) does not connect twice
	assert_eq(l.resized.get_connections().size(), 1)
