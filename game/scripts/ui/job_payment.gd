extends Control
## Payment + note after the lock opens (JOBS.md §3): the G14 receipt filled in by hand
## (receipt no., date, client, service, line items, total), coins as a diegetic counter,
## then progress is saved (JobRun.complete on Continue).
## N-66: the scene used to be a copy of the verify screen: blank client/situation labels,
## three blank verify/accept/refuse buttons and a blank back button over an empty receipt.

const INK := Color(0.10, 0.14, 0.30)  # blue ballpoint on cream paper (> 9:1)
const HAND_FONT := "res://assets/fonts/Caveat-wght.ttf"
# Field positions on the 1080×1500 receipt (PL and EN share the layout):
# name -> [x, y-centre, right edge] as fractions of the paper
const FIELDS := {
	"Number": [0.33, 0.248, 0.90],
	"Date": [0.26, 0.307, 0.90],
	"Client": [0.26, 0.376, 0.90],
	"Service": [0.26, 0.445, 0.90],
	"Line1": [0.093, 0.607, 0.68],
	"Amount1": [0.70, 0.607, 0.92],
	"Line2": [0.093, 0.653, 0.68],
	"Amount2": [0.70, 0.653, 0.92],
	"Total": [0.24, 0.749, 0.90],
	"Cash": [0.219, 0.815, 0.27],
}

@onready var paper: TextureRect = $Frame/VBox/Receipt/Paper
@onready var result_label: Label = $Frame/VBox/Result
@onready var reward_label: Label = $Frame/VBox/Reward
@onready var tip_label: Label = $Frame/VBox/Tip
@onready var continue_button: Button = $Frame/VBox/ContinueButton

var _fields := {}


func _ready() -> void:
	ScreenFrame.fit(self, $Frame)
	var job: Dictionary = JobRun.current_job
	var lang := "pl" if Settings.language() == "pl" else "en"
	paper.texture = load("res://assets/ui/gpt/verify/receipt_%s.webp" % lang)
	var reward := int(job.get("reward_coins", 0))
	var tip := expected_tip(reward)
	_fill_receipt(job, reward, tip)
	result_label.text = I18n.t(&"job.repaired" if String(job.get("family", "")) == "time_lock" else &"job.opened")  # D-60
	reward_label.text = I18n.t(&"job.reward_fmt").format({"n": reward})
	tip_label.text = I18n.t(&"job.tip_fmt").format({"n": tip}) if tip > 0 else ""
	tip_label.visible = tip > 0
	continue_button.text = I18n.t(&"common.continue")
	continue_button.pressed.connect(_settle)
	paper.resized.connect(_layout_fields)
	_layout_fields()
	_play_reward_sequence()  # audio/v2 rewards: door_open -> thanks -> coins (mix README)


func _settle() -> void:
	_complete_once()
	get_tree().change_scene_to_file("res://scenes/jobs_list.tscn")


func _complete_once() -> void:
	if not JobRun.current_job.is_empty():
		JobRun.complete()


## Nav (Android back): leaving the receipt settles the bill too (never drops the reward);
## Nav then goes to the jobs list as before.
func go_back() -> bool:
	_complete_once()
	return false


## The tip JobRun.complete() will pay (N-25: 25% for a clean opening). JobRun.last_tip is only
## set by complete(), which runs on Continue, so it cannot be read here.
static func expected_tip(reward: int) -> int:
	return int(reward * 0.25) if JobRun.clean and reward > 0 else 0


## Short client name for the receipt: the client line up to the first comma or full stop.
static func client_name(job: Dictionary) -> String:
	var key := String(job.get("i18n", {}).get("client", ""))
	if key == "":
		return "—"
	var full := I18n.t(StringName(key))
	var cut := full.length()
	for sep in [",", "."]:
		var i := full.find(sep)
		if i > 0:
			cut = mini(cut, i)
	var name := full.substr(0, cut).strip_edges()
	return name.substr(0, 1).to_upper() + name.substr(1) if name != "" else "—"


## T54: the service line names the lock family ("Wafer lock opening"; time_lock is a repair, D-60);
## falls back to the generic "Emergency lock opening".
static func service_text(job: Dictionary) -> String:
	var key := StringName("receipt.service." + String(job.get("family", "")))
	return I18n.t(key) if I18n.has_key(key) else I18n.t(&"receipt.service")


static func job_title(job: Dictionary) -> String:
	var key := String(job.get("i18n", {}).get("title", ""))
	return I18n.t(StringName(key)) if key != "" else I18n.t(&"receipt.service")


func _coins(n: int) -> String:
	return "%d %s" % [n, I18n.t(&"common.coins")]


func _fill_receipt(job: Dictionary, reward: int, tip: int) -> void:
	var completed: Array = Save.get_value("jobs_completed", [])
	var d := Time.get_date_dict_from_system()
	var values := {
		"Number": "%04d" % (completed.size() + 1),
		"Date": "%02d.%02d.%d" % [d["day"], d["month"], d["year"]],
		"Client": client_name(job),
		"Service": service_text(job),
		"Line1": job_title(job),
		"Amount1": _coins(reward),
		"Line2": I18n.t(&"receipt.tip") if tip > 0 else "",
		"Amount2": _coins(tip) if tip > 0 else "",
		"Total": _coins(reward + tip),
		"Cash": "x",
	}
	var font: Font = load(HAND_FONT)
	for key in FIELDS:
		var l := Label.new()
		l.name = key
		l.text = values[key]
		l.clip_text = true
		l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.add_theme_color_override("font_color", INK)
		if font:
			l.add_theme_font_override("font", font)
		paper.add_child(l)
		_fields[key] = l


## Labels follow the paper (keep-aspect inside the AspectRatioContainer): place by fractions.
func _layout_fields() -> void:
	var s := paper.size
	if s.x <= 0.0 or s.y <= 0.0:
		return
	var fs := maxi(int(s.y * 0.036), 14)
	for key in _fields:
		var f: Array = FIELDS[key]
		var l: Label = _fields[key]
		var h := fs * 1.4
		l.position = Vector2(s.x * f[0], s.y * f[1] - h * 0.5)
		l.size = Vector2(s.x * (f[2] - f[0]), h)
		l.add_theme_font_size_override("font_size", fs + (4 if key == "Total" else 0))


## Field texts (tests): name -> text.
func receipt_texts() -> Dictionary:
	var out := {}
	for key in _fields:
		out[key] = (_fields[key] as Label).text
	return out


func _play_reward_sequence() -> void:
	Sfx.play_jingle(&"jingle_door_open")
	Sfx.play_ui(&"coins_on_counter")  # S04 diegetic payment sound
	Sfx.play_reward(&"door_open")
	await get_tree().create_timer(1.4).timeout
	if not is_inside_tree():
		return
	Sfx.play_reward(&"thanks")
	await get_tree().create_timer(1.2).timeout
	if not is_inside_tree():
		return
	Sfx.play_reward(&"coins")
