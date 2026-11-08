class_name SoundCaptions
extends PanelContainer
## HUD.md §9.1 (3) "sound captions" (D-90): a narrow paper strip above the tool roll that names the
## last gameplay sound for 1.2 s ("[crisp click]" for a set, "[dull double click]" for a false set ...).
## Off by default (Settings `sound_captions`); never in the dark (there the strip would be the only
## picture and spoil the challenge, HUD.md §9.1). Listens to Events.lock_event itself, so every
## lock family gets it without touching its view.

const SHOW_S := 1.2
## Sub-event names first (FEEL 7.2), then the base kind. Unknown / silent kinds show nothing.
const KEYS := {
	"pin.serration": &"a11y.sfx.serration",
	"wafer.rattle": &"a11y.sfx.wafer_rattle",
	"ward.scrape": &"a11y.sfx.ward_scrape",
	"wood.creak": &"a11y.sfx.wood_creak",
	"bind": &"a11y.sfx.bind",
	"near_shear": &"a11y.sfx.near_shear",
	"set": &"a11y.sfx.set",
	"false_set": &"a11y.sfx.false_set",
	"counter_rotate": &"a11y.sfx.counter_rotate",
	"overset": &"a11y.sfx.overset",
	"drop": &"a11y.sfx.drop",
	"stress": &"a11y.sfx.stress",
	"break": &"a11y.sfx.break",
	"gate_align": &"a11y.sfx.gate_align",
	"detector_trip": &"a11y.sfx.detector_trip",
	"open": &"a11y.sfx.open",
}
## Lower number wins while a caption is still showing (a set is never hidden by a scrape).
const RANK := {"open": 0, "break": 1, "overset": 2, "false_set": 3, "set": 4, "detector_trip": 4,
	"drop": 5, "stress": 6, "counter_rotate": 7, "gate_align": 8, "bind": 9, "near_shear": 10}

var label: Label
var dark := false
var _left := 0.0
var _rank := 99
var enabled_override := -1  # tests


func _ready() -> void:
	name = "SoundCaptions"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.93, 0.9, 0.82)        # label tape paper
	sb.border_color = Color(0.2, 0.16, 0.12)
	sb.set_border_width_all(1)
	sb.set_content_margin_all(6)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	add_theme_stylebox_override(&"panel", sb)
	label = Label.new()
	label.name = "Text"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override(&"font_color", Color(0.1, 0.08, 0.06))  # ink on paper ≈ 15:1
	label.add_theme_font_size_override(&"font_size", UiA11y.fs(16))
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.clip_text = true
	add_child(label)
	visible = false
	Events.lock_event.connect(_on_lock_event)


func enabled() -> bool:
	if enabled_override >= 0:
		return enabled_override == 1
	return bool(Settings.get_value("sound_captions", false))


static func caption_key(e: Dictionary) -> StringName:
	var nm := String(e.get("name", ""))
	if KEYS.has(nm):
		return KEYS[nm]
	return KEYS.get(String(e.get("kind", "")), &"")


func _on_lock_event(e: Dictionary) -> void:
	if not enabled() or dark or not is_inside_tree():
		return
	var key := caption_key(e)
	if key == &"":
		return
	var r := int(RANK.get(String(e.get("kind", "")), 9))
	if visible and _left > 0.0 and r > _rank:
		return
	_rank = r
	_left = SHOW_S
	label.text = I18n.t(key)
	visible = true


func _process(delta: float) -> void:
	if _left > 0.0:
		_left -= delta
		if _left <= 0.0:
			visible = false
			_rank = 99
