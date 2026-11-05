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
		cards_box.add_child(b)


func _accept() -> void:
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
		$VBox/Hint.text = I18n.t(&"verify.refused_rep")
		await get_tree().create_timer(1.2).timeout
	JobRun.current_job = {}
	get_tree().change_scene_to_file("res://scenes/jobs_list.tscn")
