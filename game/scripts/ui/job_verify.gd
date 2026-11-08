extends Control
## Verification scene (JOBS.md §2, N-04/C-01): the client lays out ID cards as
## physical items (no weights, no threshold shown). Player asks for more or decides.
## Refusal jobs (refuse_*): opening is impossible; refusing grants reputation.
## N-76: framed like the other job screens (arrival photo behind a shade, 16 dp + safe-area margins,
## Back in the header), the cards are G14 props on dark paper, and the three decisions of JOBS.md §2.2
## sit at the bottom: open / "I need one more thing" / decline. Asking for more lays out the next
## card; a job whose data has `ask_more.resolves` is settled by the question itself (job.wrong_floor:
## it is the neighbour's door) — paid as a visit, no lock. Declining a normal job says so.

const Arrival := preload("res://scripts/ui/job_arrival.gd")
## Pause before the scene changes after a decision, so its line can be read.
const DECISION_PAUSE_S := 1.4
const CARD_IMAGE_H := 132.0
## VA-08: the props grow with the room left (portrait: one row of cards up to this, landscape: the
## height beside the texts), never under CARD_IMAGE_H_MIN.
const CARD_IMAGE_H_MAX := 200.0
const CARD_IMAGE_H_MIN := 96.0
const CARD_LABEL_H := 52.0
## VA-08: landscape uses the width (texts | cards side by side, decisions in one row at the bottom).
const LANDSCAPE_COLUMN := 880.0
## The arrival photo stays readable behind the header (the door is the subject of the check).
const SHADE := 0.5

@onready var title_label: Label = $Frame/VBox/Header/Title
@onready var job_label: Label = $Frame/VBox/Scroll/Body/Side/Intro/Texts/Job
@onready var hint_label: Label = $Frame/VBox/Scroll/Body/Side/Intro/Texts/Hint
@onready var cards_box: GridContainer = $Frame/VBox/Scroll/Body/Cards
@onready var result_panel: PanelContainer = $Frame/VBox/Scroll/Body/Side/ResultPanel
@onready var result_label: Label = $Frame/VBox/Scroll/Body/Side/ResultPanel/Result
@onready var accept_button: Button = $Frame/VBox/Actions/AcceptButton
@onready var ask_more_button: Button = $Frame/VBox/Actions/AskMoreButton
@onready var refuse_button: Button = $Frame/VBox/Actions/RefuseButton
@onready var back_button: Button = $Frame/VBox/Header/BackButton
@onready var body: BoxContainer = $Frame/VBox/Scroll/Body
@onready var spacer: Control = $Frame/VBox/Scroll/Body/Spacer
@onready var side_box: VBoxContainer = $Frame/VBox/Scroll/Body/Side
@onready var actions: BoxContainer = $Frame/VBox/Actions

var _shown := 0
var _asked := {}  # card -> how many times the player tapped it (T73 exchange variant)
## Tests: skip the pause before a scene change / record the target instead of changing scene.
var decision_pause_s := DECISION_PAUSE_S
var go_override: Callable = Callable()


func _ready() -> void:
	ScreenFrame.fit(self, $Frame, LANDSCAPE_COLUMN)
	var job: Dictionary = JobRun.current_job
	ScreenFrame.backdrop(self, "res://assets/ui/gpt/arrival/" + _arrival_image(job), SHADE)
	title_label.text = I18n.t(&"verify.title")
	ScreenFrame.fit_title(title_label)  # VA-08: one line when it fits, never clipped in landscape
	job_label.text = I18n.t(job.get("i18n", {}).get("title", &"jobs.title"))
	hint_label.text = I18n.t(&"verify.hint")
	accept_button.text = I18n.t(&"job.accept")
	ask_more_button.text = I18n.t(&"verify.ask_more")
	refuse_button.text = I18n.t(&"job.refuse")
	back_button.text = "‹ " + I18n.t(&"common.back")
	_shown = mini(2, _cards().size())  # client shows 1-2 cards first
	_render_cards()
	Sfx.play_ui(&"paper_turn")  # audio/v2 UI: client lays out the cards
	# JOBS.md §2: in a refusal job the client has no right to the flat; opening is not an option
	if is_refusal_job(job):
		accept_button.visible = false
	elif JobRun.is_talk(job):
		accept_button.text = I18n.t(&"job.accept_talk")  # T43: settled on the spot, nothing is opened
	accept_button.pressed.connect(_accept)
	ask_more_button.pressed.connect(_ask_more)
	refuse_button.pressed.connect(_refuse)
	back_button.pressed.connect(func() -> void: _go("res://scenes/job_arrival.tscn"))
	resized.connect(_relayout)
	_relayout()
	ScreenFrame.wire_sounds(self)  # S05 enamel-plate sounds
	ScreenFrame.enter($Frame/VBox/Scroll)


static func is_refusal_job(job: Dictionary) -> bool:
	return String(job.get("id", "")).begins_with("job.refuse")


static func _arrival_image(job: Dictionary) -> String:
	var by_place: Dictionary = Arrival.ARRIVAL_BG.get(String(job.get("place", "apartment")), Arrival.ARRIVAL_BG["apartment"])
	var time := String(job.get("time", "evening"))
	return String(by_place.get(time, by_place.get("", "02_apartment_evening.jpg")))


func _cards() -> Array:
	return JobRun.current_job.get("cards", ["id"])


## VA-08 layout. Portrait: the photo of the door shows under the header, the texts and the cards sit
## on the table just above the three decisions (bottom 40%), the cards as large as one row allows.
## Landscape: texts left, all cards in one row right, the decisions in one row at the bottom.
func is_landscape() -> bool:
	return size.x > size.y


func _relayout() -> void:
	var land := is_landscape()
	var n := maxi(cards_box.get_child_count(), 1)
	cards_box.columns = n if land else mini(n, 2)
	body.vertical = not land
	spacer.visible = not land
	actions.vertical = not land
	side_box.size_flags_stretch_ratio = 1.0
	cards_box.size_flags_stretch_ratio = 1.4 if n > 1 else 1.0
	var img_h := card_image_height(size, n, land)
	for c in cards_box.get_children():
		(c as Control).custom_minimum_size.y = img_h + CARD_LABEL_H
		var pic := c.get_node_or_null("Box/Pic") as Control
		if pic:
			pic.custom_minimum_size.y = img_h


## Prop picture height (dp) for a screen of `screen` dp with `n` cards (tests).
static func card_image_height(screen: Vector2, n: int, land: bool) -> float:
	if land:
		# header (~64) + decisions row (56) + margins and gaps (~70) + the card's caption
		return clampf(screen.y - 190.0 - CARD_LABEL_H, CARD_IMAGE_H_MIN, CARD_IMAGE_H_MAX)
	var rows := ceili(n / 2.0)
	# portrait: about a fifth of the height for one row; two rows keep the old size
	var h := screen.y * 0.2 if rows == 1 else (screen.y * 0.36) / rows - CARD_LABEL_H
	return clampf(h, CARD_IMAGE_H_MIN, CARD_IMAGE_H_MAX)


# G14 verification props: card type -> prop image (PL/EN by game language)
const CARD_PROP := {
	"id": "tenant", "witness": "note", "lease": "lease", "manager": "manager",
	"job": "job", "envelope": "envelope", "note": "note", "tenant": "tenant", "receipt": "receipt",
}


func _card_prop(card: String) -> Texture2D:
	var lang := "pl" if Settings.language() == "pl" else "en"
	var prop: String = CARD_PROP.get(card, "note")
	return load("res://assets/ui/gpt/verify/%s_%s.webp" % [prop, lang])


func _render_cards() -> void:
	for c in cards_box.get_children():
		cards_box.remove_child(c)
		c.queue_free()
	var cards := _cards()
	for i in mini(_shown, cards.size()):
		cards_box.add_child(_card_tile(String(cards[i])))
	_relayout()
	_update_ask_more()


## One card on the table: the prop photo with its name under it, on dark paper; tap = ask about it.
func _card_tile(card: String) -> Button:
	var b := Button.new()
	b.name = "Card_" + card
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0, CARD_IMAGE_H + 52)
	var paper := get_theme_stylebox("panel", "PanelContainer")
	for st in ["normal", "hover", "focus", "disabled"]:
		b.add_theme_stylebox_override(st, paper)
	var down := paper.duplicate() as StyleBox
	if down is StyleBoxFlat:
		(down as StyleBoxFlat).border_color = Color(0.83, 0.67, 0.37)  # brass edge while pressed
		(down as StyleBoxFlat).set_border_width_all(2)
	b.add_theme_stylebox_override("pressed", down)
	b.add_theme_stylebox_override("hover_pressed", down)
	var box := VBoxContainer.new()
	box.name = "Box"
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 8
	box.offset_top = 8
	box.offset_right = -8
	box.offset_bottom = -6
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 4)
	b.add_child(box)
	var pic := TextureRect.new()
	pic.name = "Pic"
	pic.texture = _card_prop(card)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.custom_minimum_size = Vector2(0, CARD_IMAGE_H)
	pic.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(pic)
	var name_label := Label.new()
	name_label.name = "Name"
	name_label.text = I18n.t(StringName("verify.card.%s" % card))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.custom_minimum_size = Vector2(0, 0)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(name_label)
	b.pressed.connect(_ask_about.bind(card))
	return b


func card_names() -> PackedStringArray:
	var out := PackedStringArray()
	for c in cards_box.get_children():
		out.append(String(c.name).trim_prefix("Card_"))
	return out


func _show_result(text: String) -> void:
	result_label.text = text
	result_panel.visible = text != ""


## T73: tapping a card plays a short exchange — the locksmith's question and the client's
## answer — in one of two variants, so the check does not repeat word for word.
func _ask_about(card: String) -> void:
	var text := exchange_text(String(JobRun.current_job.get("id", "")), card, int(_asked.get(card, 0)))
	if text == "":
		return
	_asked[card] = int(_asked.get(card, 0)) + 1
	_show_result(text)
	Sfx.play_ui(&"paper_turn")


## "— question\n— answer" for a card, variant 1 or 2 picked from the job id and the tap count;
## "" when the card has no exchange texts.
static func exchange_text(job_id: String, card: String, taps: int) -> String:
	var v := (absi(hash(job_id + "/" + card)) + taps) % 2 + 1
	var ask := StringName("verify.ask.%s.%d" % [card, v])
	var reply := StringName("verify.reply.%s.%d" % [card, v])
	if not (I18n.has_key(ask) and I18n.has_key(reply)):
		return ""
	return "— %s\n— %s" % [I18n.t(ask), I18n.t(reply)]


static func ask_more_spec(job: Dictionary) -> Dictionary:
	var spec: Variant = job.get("ask_more", {})
	return spec if spec is Dictionary else {}


## The button stays while the client has another card or the question itself settles the job.
func _update_ask_more() -> void:
	var more := _shown < _cards().size() or bool(ask_more_spec(JobRun.current_job).get("resolves", false))
	ask_more_button.disabled = not more


## JOBS.md §2.2 "I need one more thing": the client lays out the next card (and the locksmith asks
## about it at once); with nothing left, a job with `ask_more.resolves` is settled by the question.
func _ask_more() -> void:
	var job: Dictionary = JobRun.current_job
	if _shown < _cards().size():
		_shown += 1
		_render_cards()
		var card := String(_cards()[_shown - 1])
		var text := exchange_text(String(job.get("id", "")), card, 0)
		_show_result(text if text != "" else I18n.t(&"verify.more_card"))
		if text != "":
			_asked[card] = 1
		Sfx.play_ui(&"paper_turn")
		return
	var spec := ask_more_spec(job)
	if not bool(spec.get("resolves", false)):
		_show_result(I18n.t(&"verify.no_more"))
		ask_more_button.disabled = true
		return
	_set_decided()
	var jid := String(job.get("id", ""))
	var rep := int(spec.get("reputation", 0))
	var text := "— %s\n— %s" % [I18n.t(StringName(jid + ".ask_more.ask")), I18n.t(StringName(jid + ".ask_more.reply"))]
	if rep != 0:
		Save.set_value("reputation", int(Save.get_value("reputation", 0)) + rep)
		text += "\n\n" + I18n.t(&"verify.asked_rep") % rep
	_show_result(text)
	Sfx.play_ui(&"paper_turn")
	await _decision_pause()
	# settled by talking: a visit fee without a tip, no lock scene (same path as T43 "talk" jobs)
	var settled := job.duplicate(true)
	settled["outcome"] = "talk"
	JobRun.current_job = settled
	_go("res://scenes/job_payment.tscn")


func _go(path: String) -> void:
	if go_override.is_valid():
		go_override.call(path)
		return
	get_tree().change_scene_to_file(path)


func _set_decided() -> void:
	accept_button.disabled = true
	ask_more_button.disabled = true
	refuse_button.disabled = true


func _decision_pause() -> void:
	if decision_pause_s > 0.0 and is_inside_tree():
		await get_tree().create_timer(decision_pause_s).timeout


## D-85 (JOBS.md job.wrong_floor): data `wrong_open: {reputation, lines, backdrop}` — opening without
## checking is the wrong door. No lock: the scene with the person who really lives there, the reputation
## loss, no coins, and the job leaves the list (Save `jobs_wrong_open`); its kind "day after" never comes.
static func wrong_open_spec(job: Dictionary) -> Dictionary:
	var spec: Variant = job.get("wrong_open", {})
	return spec if spec is Dictionary else {}


## The wrong-door scene's lines: speakers from the data, texts `<job_id>.wrong_open.N`.
static func wrong_open_lines(job: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var jid := String(job.get("id", ""))
	var speakers: Array = wrong_open_spec(job).get("lines", [])
	for i in speakers.size():
		var key := "%s.wrong_open.%d" % [jid, i + 1]
		if I18n.has_key(StringName(key)):
			out.append({"speaker": String(speakers[i]), "key": key, "text": I18n.t(StringName(key))})
	return out


var wrong_scene: DayAfter


func _open_wrong_door() -> void:
	_set_decided()
	var job: Dictionary = JobRun.current_job
	var jid := String(job.get("id", ""))
	var spec := wrong_open_spec(job)
	var loss := absi(int(spec.get("reputation", -25)))
	var closed: Array = Save.get_value("jobs_wrong_open", [])
	if not closed.has(jid):  # once per job
		closed.append(jid)
		Save.set_value("jobs_wrong_open", closed)
		Save.set_value("reputation", maxi(0, int(Save.get_value("reputation", 0)) - loss))
	DayAfter.mark_seen(jid)  # the thank-you cake for not opening will not come
	wrong_scene = DayAfter.show_scene(self, job, wrong_open_lines(job), &"wrongopen.title", String(spec.get("backdrop", "")))
	await wrong_scene.closed
	_show_result(I18n.t(&"verify.lost_rep") % loss)
	await _decision_pause()
	JobRun.current_job = {}
	_go("res://scenes/jobs_list.tscn")


func _accept() -> void:
	if not wrong_open_spec(JobRun.current_job).is_empty():
		_open_wrong_door()
		return
	if JobRun.is_talk(JobRun.current_job):
		_go("res://scenes/job_payment.tscn")  # T43: no lock scene
		return
	_go(JobRun.lock_scene_path())


func _refuse() -> void:
	# N-15: refusal = +5 reputation, once per job, and the job is closed (saved + hidden)
	_set_decided()
	var jid: String = JobRun.current_job.get("id", "")
	Sfx.play_jingle(&"jingle_dignified_refusal")
	if jid.begins_with("job.refuse"):
		var refused: Array = Save.get_value("jobs_refused", [])
		if not refused.has(jid):
			refused.append(jid)
			Save.set_value("jobs_refused", refused)
			Save.set_value("reputation", Save.get_value("reputation", 0) + 5)
		DayAfter.note_finished(JobRun.current_job)  # V04/D-78: a refusal has its "day after" too
		_show_result(I18n.t(&"verify.refused_rep"))
	else:
		# N-76: a normal job stays on the list (the player may come back to it); say so
		_show_result(I18n.t(&"verify.declined"))
	await _decision_pause()
	JobRun.current_job = {}
	_go("res://scenes/jobs_list.tscn")
