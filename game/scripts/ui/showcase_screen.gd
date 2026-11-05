extends Control
## Showcase: historical notes from game/data/showcase/*.json with source field.

@onready var notes_list: VBoxContainer = $VBox/Scroll/VBox/NotesList
@onready var back_button: Button = $BackButton

const SHOWCASE_DIR := "res://data/showcase"


func _show_notebook_entry() -> void:
	var keys: Array = []
	for k in I18n.all_keys():
		if String(k).begins_with("notebook.extra."):
			keys.append(k)
	if keys.is_empty():
		return
	var card := VBoxContainer.new()
	var lbl := Label.new()
	lbl.text = I18n.t(&"showcase.notebook_prefix") + " " + I18n.t(keys[randi() % keys.size()])
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_child(lbl)
	# G10 notebook page (PL/EN by game language)
	var lang := "pl" if Settings.language() == "pl" else "en"
	var page := load("res://assets/ui/gpt/notebook/03-five-rules-%s.jpg" % lang)
	if page != null:
		var tex := TextureRect.new()
		tex.texture = page
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tex.custom_minimum_size = Vector2(0, 160)
		card.add_child(tex)
	notes_list.add_child(card)


func _exhibit_photo(nid: String) -> Texture2D:
	# G16 showcase photos: showcase.<slug> -> <NN>_<slug>.jpg
	var slug := nid.replace("showcase.", "")
	for f in DirAccess.get_files_at("res://assets/ui/gpt/showcase"):
		if f.ends_with("_%s.jpg" % slug):
			return load("res://assets/ui/gpt/showcase/" + f)
	return null


# N-40: a note unlocks with progress — every `job.*` reference in `unlocks` must be
# a completed job, and a tier ref T<n> needs a completed job of tier >= n.
func _note_unlocked(note: Dictionary) -> bool:
	var completed: Array = Save.get_value("jobs_completed", [])
	var unlocks: String = note.get("unlocks", "")
	if unlocks == "":
		return true
	var re := RegEx.new()
	re.compile("`([^`]+)`")
	var max_tier := 0
	for j in completed:
		max_tier = maxi(max_tier, JobRun.tier_for(JobRun.job_by_id(j)))
	for m in re.search_all(unlocks):
		var token := m.get_string(1)
		if token.begins_with("job."):
			if not completed.has(token):
				return false
		elif token.begins_with("T") and token.substr(1).is_valid_int():
			if max_tier < token.substr(1).to_int():
				return false
	return true


# markdown emphasis *...* -> BBCode [i]...[/i]
func _bbcode(text: String) -> String:
	var re := RegEx.new()
	re.compile("\\*([^*]+)\\*")
	return re.sub(text, "[i]$1[/i]", true)


func _ready() -> void:
	Sfx.play_ambience(&"workshop")
	Sfx.play_music(&"menu_workshop")
	SafeArea.apply(self)
	$VBox/Title.text = I18n.t(&"showcase.title")
	back_button.text = I18n.t(&"common.back")
	back_button.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	_show_notebook_entry()  # task 10: master's notebook entries (contrib/gpt/T10 notebook_extra.csv)
	for path in DirAccess.get_files_at(SHOWCASE_DIR):
		if not path.ends_with(".json"):
			continue
		var note: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SHOWCASE_DIR + "/" + path))
		var nid: String = note.get("id", path.get_basename())
		var unlocked: bool = _note_unlocked(note)
		var card := VBoxContainer.new()
		var photo := _exhibit_photo(nid)
		if photo != null and unlocked:
			var tex := TextureRect.new()
			tex.texture = photo
			tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			tex.custom_minimum_size = Vector2(0, 160)
			card.add_child(tex)
		var title := Button.new()
		title.text = I18n.t(note.get("i18n", {}).get("title", &"showcase.title"))
		if not unlocked:
			title.text += " — " + I18n.t(&"showcase.locked")
			title.disabled = true
		title.alignment = HORIZONTAL_ALIGNMENT_LEFT
		title.custom_minimum_size = Vector2(0, 48)
		var body := RichTextLabel.new()
		body.bbcode_enabled = true
		body.text = _bbcode(I18n.t(note.get("i18n", {}).get("body", &"showcase.title")))
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.fit_content = true
		body.visible = false
		var source := Label.new()
		var src: String = note.get("source", "")
		source.text = "%s: %s" % [I18n.t(&"showcase.source"), src if src != "" else I18n.t(&"showcase.unknown_source")]
		source.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		source.visible = false
		title.pressed.connect(func() -> void:
			body.visible = not body.visible
			source.visible = body.visible)
		card.add_child(title)
		card.add_child(body)
		card.add_child(source)
		notes_list.add_child(card)
