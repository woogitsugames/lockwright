extends Control
## Verification scene (JOBS.md §2, N-04/C-01): the client lays out ID cards as
## physical items (no weights, no threshold shown). Player asks for more or decides.
## Refusal jobs (refuse_*): opening is impossible; refusing grants reputation.

@onready var title_label: Label = $VBox/Title
@onready var hint_label: Label = $VBox/Hint
@onready var cards_box: HBoxContainer = $VBox/Cards
@onready var accept_button: Button = $VBox/AcceptButton
@onready var refuse_button: Button = $VBox/RefuseButton
@onready var back_button: Button = $BackButton

var _shown := 0
var _asked := {}  # card -> how many times the player tapped it (T73 exchange variant)


func _ready() -> void:
	SafeArea.apply(self)
	var job: Dictionary = JobRun.current_job
	title_label.text = I18n.t(job.get("i18n", {}).get("title", &"jobs.title"))
	hint_label.text = I18n.t(&"verify.hint")
	accept_button.text = I18n.t(&"job.accept")
	refuse_button.text = I18n.t(&"job.refuse")
	back_button.text = I18n.t(&"common.back")
	_shown = mini(2, job.get("cards", ["id"]).size())  # client shows 1-2 cards first
	_render_cards()
	Sfx.play_ui(&"paper_turn")  # audio/v2 UI: client lays out the cards
	# JOBS.md §2: in a refusal job the client has no right to the flat; opening is not an option
	if String(job.get("id", "")).begins_with("job.refuse"):
		accept_button.visible = false
	elif JobRun.is_talk(job):
		accept_button.text = I18n.t(&"job.accept_talk")  # T43: settled on the spot, nothing is opened
	accept_button.pressed.connect(_accept)
	refuse_button.pressed.connect(_refuse)
	back_button.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/job_arrival.tscn"))


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
		c.queue_free()
	var cards: Array = JobRun.current_job.get("cards", ["id"])
	for i in mini(_shown, cards.size()):
		var b := Button.new()
		b.text = I18n.t(&"verify.card.%s" % cards[i])
		b.custom_minimum_size = Vector2(0, 48)
		var tex := _card_prop(cards[i])
		if tex != null:
			b.icon = tex
			b.expand_icon = true
		b.pressed.connect(_ask_about.bind(String(cards[i])))
		cards_box.add_child(b)


## T73: tapping a card plays a short exchange — the locksmith's question and the client's
## answer — in one of two variants, so the check does not repeat word for word.
func _ask_about(card: String) -> void:
	var label := get_node_or_null("VBox/Result") as Label
	if label == null:
		return
	var text := exchange_text(String(JobRun.current_job.get("id", "")), card, int(_asked.get(card, 0)))
	if text == "":
		return
	_asked[card] = int(_asked.get(card, 0)) + 1
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.text = text
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


func _accept() -> void:
	if JobRun.is_talk(JobRun.current_job):
		get_tree().change_scene_to_file("res://scenes/job_payment.tscn")  # T43: no lock scene
		return
	get_tree().change_scene_to_file(JobRun.lock_scene_path())


func _refuse() -> void:
	# N-15: refusal = +5 reputation, once per job, and the job is closed (saved + hidden)
	accept_button.disabled = true
	refuse_button.disabled = true
	var jid: String = JobRun.current_job.get("id", "")
	Sfx.play_jingle(&"jingle_dignified_refusal")
	if jid.begins_with("job.refuse"):
		var refused: Array = Save.get_value("jobs_refused", [])
		if not refused.has(jid):
			refused.append(jid)
			Save.set_value("jobs_refused", refused)
			Save.set_value("reputation", Save.get_value("reputation", 0) + 5)
		DayAfter.note_finished(JobRun.current_job)  # V04/D-78: a refusal has its "day after" too
		$VBox/Hint.text = I18n.t(&"verify.refused_rep")
		await get_tree().create_timer(1.2).timeout
	JobRun.current_job = {}
	get_tree().change_scene_to_file("res://scenes/jobs_list.tscn")
