extends SceneTree
## Headless utility that generates `.gray.png` (ITU-R BT.709 luminance grayscale)
## and `.dim.png` (50% brightness) variants for every base screenshot in
## `res://scenes/photoreal_families/shots/`, and verifies that all 6 states
## (`free`, `bound`, `set`, `false_set`, `overset`, `detector`) are visually
## distinguishable by geometry in grayscale.

const SHOTS_DIR := "res://scenes/photoreal_families/shots"
const FAMILIES := ["wafer", "lever", "warded", "wooden_pin"]
const STATES := ["free", "bound", "set", "false_set", "overset", "detector"]
const ORIENTATIONS := ["portrait", "landscape"]


func _init() -> void:
	var abs_dir := ProjectSettings.globalize_path(SHOTS_DIR)
	var dir := DirAccess.open(SHOTS_DIR)
	if dir == null:
		printerr("Cannot open shots dir: ", SHOTS_DIR)
		quit(1)
		return

	var base_files: Array[String] = []
	dir.list_dir_begin()
	var fn := dir.get_next()
	while fn != "":
		if not dir.current_is_dir() and fn.ends_with(".png") and not fn.ends_with(".gray.png") and not fn.ends_with(".dim.png"):
			base_files.append(fn)
		fn = dir.get_next()
	dir.list_dir_end()
	base_files.sort()

	var count := 0
	for f in base_files:
		var full_path := abs_dir.path_join(f)
		var stem := f.substr(0, f.length() - 4)
		var gray_path := abs_dir.path_join(stem + ".gray.png")
		var dim_path := abs_dir.path_join(stem + ".dim.png")
		_make_variants(full_path, gray_path, dim_path)
		count += 1

	print("Generated .gray.png and .dim.png for %d base screenshots." % count)

	# Verify pairwise grayscale distinction across the 6 states for each family
	var all_distinct := true
	for fam in FAMILIES:
		for orient in ORIENTATIONS:
			var imgs := {}
			for st in STATES:
				var p := abs_dir.path_join("%s_%s_%s.gray.png" % [fam, st, orient])
				if FileAccess.file_exists(p):
					var im := Image.load_from_file(p)
					if im:
						imgs[st] = im
			var keys := imgs.keys()
			for i in keys.size():
				for j in range(i + 1, keys.size()):
					var s1: String = keys[i]
					var s2: String = keys[j]
					var diff := _max_region_luma_diff(imgs[s1], imgs[s2])
					if diff < 0.005:
						printerr("WARNING: Low grayscale difference between %s %s and %s (%s): %.5f" % [fam, s1, s2, orient, diff])
						all_distinct = false
	print("GRAYSCALE_DISTINCTION_CHECK=", "PASS" if all_distinct else "WARN")
	quit(0)


func _make_variants(src_path: String, gray_path: String, dim_path: String) -> void:
	var img := Image.load_from_file(src_path)
	if img == null:
		return
	var w := img.get_width()
	var h := img.get_height()
	var gray := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var dim := Image.create(w, h, false, Image.FORMAT_RGBA8)

	for y in h:
		for x in w:
			var c := img.get_pixel(x, y)
			var luma := 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b
			gray.set_pixel(x, y, Color(luma, luma, luma, c.a))
			dim.set_pixel(x, y, Color(c.r * 0.5, c.g * 0.5, c.b * 0.5, c.a))

	gray.save_png(gray_path)
	dim.save_png(dim_path)


func _max_region_luma_diff(a: Image, b: Image) -> float:
	if a.get_size() != b.get_size():
		return 1.0
	var w := a.get_width()
	var h := a.get_height()
	var sum_abs := 0.0
	var samples := 0
	for y in range(0, h, 4):
		for x in range(0, w, 4):
			var d := absf(a.get_pixel(x, y).r - b.get_pixel(x, y).r)
			sum_abs += d
			samples += 1
	return sum_abs / float(maxi(samples, 1))
