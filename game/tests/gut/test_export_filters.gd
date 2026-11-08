extends GutTest

const TutorialScreen := preload("res://scripts/ui/tutorial.gd")
## N-74: every resource a game script (or scene) points at with a res:// literal must survive the
## export filters of the mobile presets. D-55 excludes unused files from the APK/IPA; when code starts
## loading one of them again, the file silently vanishes from the package (the tutorial cards
## g11-*-clean.png did: "No loader found for resource" on the phone, empty left column).
##
## Path forms understood (scripts):
##   "res://a/b.png"                    -> the file itself
##   "res://a/g11-%02d-%s.png" % [...]  -> every file in a/ matching the format (%0Nd = N digits,
##                                         %d = digits, %s = one path segment)
##   "res://a/b/" + expr                -> a/b/<literal> for every other "x.ext" literal in the same script
## Filters are matched like Godot's exporter: String.matchn against "res://path" and "path".

const MOBILE_PRESETS := ["Android", "iOS"]
const SCAN_DIRS := ["res://scripts", "res://scenes", "res://theme"]
const SCAN_EXT := ["gd", "tscn", "tres"]

var _literal_re := RegEx.create_from_string("\"(res://[^\"]+)\"")
var _name_re := RegEx.create_from_string("\"([A-Za-z0-9_.\\-]+\\.[A-Za-z0-9]{2,5})\"")


func _presets() -> Dictionary:
	# preset name -> PackedStringArray of exclude filters (only "all_resources" presets ship the game)
	var cfg := ConfigFile.new()
	assert_eq(cfg.load("res://export_presets.cfg"), OK, "export_presets.cfg readable")
	var out := {}
	for section in cfg.get_sections():
		if not cfg.has_section_key(section, "name"):
			continue
		var name := String(cfg.get_value(section, "name"))
		if name in MOBILE_PRESETS and String(cfg.get_value(section, "export_filter", "")) == "all_resources":
			var filters := PackedStringArray()
			for f in String(cfg.get_value(section, "exclude_filter", "")).split(",", false):
				filters.append(f.strip_edges())
			out[name] = filters
	return out


static func excluded_by(path: String, filters: PackedStringArray) -> String:
	var no_prefix := path.trim_prefix("res://")
	for f in filters:
		if path.matchn(f) or no_prefix.matchn(f):
			return f
	return ""


func _files(dir: String, exts: Array) -> PackedStringArray:
	var out := PackedStringArray()
	var d := DirAccess.open(dir)
	if d == null:
		return out
	for sub in d.get_directories():
		if not sub.begins_with("."):
			out.append_array(_files(dir.path_join(sub), exts))
	for f in d.get_files():
		if f.get_extension() in exts:
			out.append(dir.path_join(f))
	return out


## Files on disk a literal can resolve to (empty when it is not a file path we can resolve).
func resolve(literal: String, sibling_names: PackedStringArray) -> PackedStringArray:
	var out := PackedStringArray()
	if literal.ends_with("/"):
		for n in sibling_names:
			if FileAccess.file_exists(literal + n):
				out.append(literal + n)
		return out
	if not literal.contains("%"):
		if FileAccess.file_exists(literal):
			out.append(literal)
		return out
	var dir := literal.get_base_dir()
	if dir.contains("%"):
		# placeholder in a directory: expand one level (e.g. cast/%s/portrait.jpg)
		var parent := dir.get_base_dir()
		if parent.contains("%"):
			return out
		var d := DirAccess.open(parent)
		if d == null:
			return out
		var seg_re := RegEx.create_from_string("^" + _format_to_regex(dir.get_file()) + "$")
		for sub in d.get_directories():
			if seg_re.search(sub) != null:
				out.append_array(resolve(parent.path_join(sub).path_join(literal.get_file()), sibling_names))
		return out
	var re := RegEx.create_from_string("^" + _format_to_regex(literal.get_file()) + "$")
	var dd := DirAccess.open(dir)
	if dd == null:
		return out
	for f in dd.get_files():
		if re.search(f) != null:
			out.append(dir.path_join(f))
	return out


static func _format_to_regex(s: String) -> String:
	var spec := RegEx.create_from_string("%(0?)([0-9]*)([sdif])")
	var out := ""
	var pos := 0
	for m in spec.search_all(s):
		out += _escape(s.substr(pos, m.get_start() - pos))
		var kind := m.get_string(3)
		var width := m.get_string(2)
		if kind == "s":
			out += "[^/]+"
		elif m.get_string(1) == "0" and width != "":
			out += "[0-9]{%s,}" % width
		else:
			out += "[-0-9.]+"
		pos = m.get_end()
	return out + _escape(s.substr(pos))


static func _escape(s: String) -> String:
	var out := ""
	for c in s:
		out += ("\\" + c) if "\\^$.|?*+()[]{}".contains(c) else c
	return out


func _references() -> Array:
	# [source_file, line_no, literal, resolved_path]
	var refs := []
	for dir in SCAN_DIRS:
		for src in _files(dir, SCAN_EXT):
			var text := FileAccess.get_file_as_string(src)
			var names := PackedStringArray()
			for m in _name_re.search_all(text):
				names.append(m.get_string(1))
			var line_no := 0
			for line in text.split("\n"):
				line_no += 1
				for m in _literal_re.search_all(line):
					var lit := m.get_string(1)
					for p in resolve(lit, names):
						refs.append([src, line_no, lit, p])
	return refs


func test_presets_found() -> void:
	var presets := _presets()
	for name in MOBILE_PRESETS:
		assert_true(presets.has(name), "preset %s with export_filter=all_resources" % name)


func test_resolver_understands_the_forms_used_by_the_game() -> void:
	var cards := resolve("res://assets/ui/gpt/tutorial/g11-%02d-%s.png", PackedStringArray())
	assert_true(cards.has("res://assets/ui/gpt/tutorial/g11-03-clean.png"), "format path expands")
	assert_false(cards.has("res://assets/ui/gpt/tutorial/stamp-g11-stamp-pl.png"), "anchored to the pattern")
	var plates := resolve("res://assets/ui/gpt/plates/plate_%02d.png", PackedStringArray())
	assert_false(plates.has("res://assets/ui/gpt/plates/plate_sign_dozorca_pl.png"), "%02d is digits only")
	var portraits := resolve("res://assets/ui/gpt/cast/%s/portrait.jpg", PackedStringArray())
	assert_gt(portraits.size(), 0, "placeholder in a directory expands one level")
	var bg := resolve("res://assets/ui/gpt/workshop/", PackedStringArray(["01-workshop-morning-portrait.webp"]))
	assert_eq(bg.size(), 1, "prefix + sibling literal")
	assert_eq(excluded_by("res://tests/x.gd", PackedStringArray(["tests/*"])), "tests/*", "matchn without res://")


## The N-74 guard itself.
func test_every_referenced_resource_survives_mobile_export_filters() -> void:
	var presets := _presets()
	var refs := _references()
	assert_gt(refs.size(), 100, "scanner finds the game's res:// references (sanity)")
	var problems := PackedStringArray()
	for preset in presets:
		var filters: PackedStringArray = presets[preset]
		for r in refs:
			var src: String = r[0]
			if excluded_by(src, filters) != "":
				continue  # the referencing script/scene is itself not shipped (dev tools, plan-B sources)
			var hit := excluded_by(r[3], filters)
			if hit != "":
				problems.append("%s: %s:%d loads %s, excluded by '%s'" % [preset, src, r[1], r[3], hit])
	assert_eq(problems.size(), 0, "referenced files excluded from the package (fix exclude_filter in export_presets.cfg, D-55):\n" + "\n".join(problems))


func test_tutorial_cards_ship() -> void:
	# VA-07 (D-98): the photoreal cards ship; the G11 sketches they replaced stay out of the package
	var presets := _presets()
	for preset in presets:
		for frames in TutorialScreen.FRAMES + [TutorialScreen.FRAMES_AUTO_S1]:
			for f in frames:
				var p: String = TutorialScreen.CARD_DIR % f[0]
				assert_true(ResourceLoader.exists(p), p)
				assert_eq(excluded_by(p, presets[preset]), "", "%s ships %s" % [preset, p])
		for i in range(1, 13):
			var g := "res://assets/ui/gpt/tutorial/g11-%02d-clean.png" % i
			assert_ne(excluded_by(g, presets[preset]), "", "%s leaves out the replaced sketch %s" % [preset, g])


## D-100: only EN voice lines ship in the mobile package; PL, DE, FR and ES are voice packs
## (each with its own data-only "Voice <lang>" preset for tools/build_voice_packs.py).
func test_only_en_voice_lines_ship() -> void:
	var presets := _presets()
	for name in presets:
		var f: PackedStringArray = presets[name]
		assert_eq(excluded_by("res://assets/audio/lines/en/job.cat_bathroom.line.1.ogg", f), "", "%s keeps EN" % name)
		for lang in ["pl", "de", "fr", "es"]:
			assert_ne(excluded_by("res://assets/audio/lines/%s/job.cat_bathroom.line.1.ogg" % lang, f), "",
				"%s leaves %s out (voice pack)" % [name, lang.to_upper()])
	var cfg := ConfigFile.new()
	cfg.load("res://export_presets.cfg")
	var packs := {}
	for section in cfg.get_sections():
		if cfg.has_section_key(section, "name") and String(cfg.get_value(section, "name")).begins_with("Voice "):
			packs[String(cfg.get_value(section, "name")).trim_prefix("Voice ")] = String(cfg.get_value(section, "include_filter", ""))
	for lang in ["pl", "de", "fr", "es"]:
		assert_eq(packs.get(lang, ""), "assets/audio/lines/%s/*.ogg" % lang, "preset Voice %s" % lang)
	assert_false(packs.has("en"), "EN is never a pack")
