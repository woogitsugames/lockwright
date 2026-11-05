extends Node3D
## Lock screen controller. No UI panels (D-12): only a 48 dp pause button in the
## safe-area corner; thumb zones are invisible. Lock events go through
## FeedbackDirector to Haptics and Sfx in the same physics step, never waiting for
## a render frame (ARCHITECTURE.md §5, R-21).

@onready var sampler: InputSampler = $InputSampler
@onready var pause_button: Button = $UILayer/PauseButton
@onready var pause_menu: Control = $UILayer/PauseMenu

var session: RefCounted  # LockcoreSession (GDExtension) or FakeLockSession fallback
var _pins_visual: Array = []
var _core: MeshInstance3D
var _pick: MeshInstance3D
var _tensioner: MeshInstance3D
var _dark_mode := false
var _paused := false
var _vm: Dictionary = {}


func _ready() -> void:
	if ClassDB.class_exists("LockcoreSession"):
		session = ClassDB.instantiate("LockcoreSession")
		session.create(&"pin_tumbler", 42, 2)
	else:
		session = FakeLockSession.create(&"pin_tumbler", 42, 2)
	pause_button.text = I18n.t(&"lock.pause")
	pause_button.pressed.connect(_on_pause_pressed)
	pause_menu.visible = false
	$UILayer/PauseMenu/VBox/Title.text = I18n.t(&"pause.title")
	$UILayer/PauseMenu/VBox/ResumeButton.text = I18n.t(&"pause.resume")
	$UILayer/PauseMenu/VBox/DarkModeCheck.text = I18n.t(&"pause.dark_mode")
	$UILayer/PauseMenu/VBox/QuitButton.text = I18n.t(&"pause.quit")
	$UILayer/PauseMenu/VBox/ResumeButton.pressed.connect(_on_resume_pressed)
	$UILayer/PauseMenu/VBox/DarkModeCheck.toggled.connect(_on_dark_mode_toggled)
	$UILayer/PauseMenu/VBox/QuitButton.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	_apply_safe_area()
	_build_placeholder_meshes()
	_collect_visuals()
	Sfx.begin_loop(&"tension_resistance", &"brass")
	Sfx.begin_loop(&"pick_drag", &"steel")
	Haptics.begin_continuous(&"tension_resistance")
	get_tree().root.focus_exited.connect(_on_focus_lost)  # R-03: auto-pause on backgrounding


func _apply_safe_area() -> void:
	# R-32: pause button lives inside the display safe area (notch / Dynamic Island)
	var safe := DisplayServer.get_display_safe_area()
	var size := get_viewport().get_visible_rect().size
	pause_button.position = Vector2(size.x - safe.position.x - safe.size.x + safe.position.x, 0)  # placeholder, refined below
	pause_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	pause_button.offset_left = -104.0
	pause_button.offset_top = safe.position.y + 8.0
	pause_button.offset_right = -maxf(8.0, size.x - (safe.position.x + safe.size.x))
	pause_button.offset_bottom = pause_button.offset_top + 48.0 * DisplayServer.screen_get_scale()


func _build_placeholder_meshes() -> void:
	# Temporary PBR placeholder until glTF models from art/ land.
	var brass := StandardMaterial3D.new()
	brass.metallic = 0.9
	brass.roughness = 0.35
	brass.albedo_color = Color(0.72, 0.55, 0.25)
	var steel := StandardMaterial3D.new()
	steel.metallic = 0.95
	steel.roughness = 0.25
	steel.albedo_color = Color(0.6, 0.62, 0.66)
	var housing := BoxMesh.new()
	housing.size = Vector3(6.0, 2.2, 2.4)
	$LockRig/Housing.mesh = housing
	$LockRig/Housing.material_override = brass
	var core := CylinderMesh.new()
	core.top_radius = 0.8
	core.bottom_radius = 0.8
	core.height = 5.6
	core.radial_segments = 32
	$LockRig/Core.mesh = core
	$LockRig/Core.material_override = steel
	$LockRig/Core.rotation.z = PI / 2.0
	for i in 5:
		var pin := MeshInstance3D.new()
		var m := CylinderMesh.new()
		m.top_radius = 0.12
		m.bottom_radius = 0.12
		m.height = 1.2
		pin.mesh = m
		pin.material_override = steel.duplicate()
		pin.position = Vector3(-2.0 + i * 1.0, 2.0, 0.0)
		$LockRig/Pins.add_child(pin)
	var pick := BoxMesh.new()
	pick.size = Vector3(0.08, 0.08, 4.4)
	$LockRig/Pick.mesh = pick
	$LockRig/Pick.material_override = steel
	var tensioner := BoxMesh.new()
	tensioner.size = Vector3(0.3, 0.3, 2.0)
	$LockRig/Tensioner.mesh = tensioner
	$LockRig/Tensioner.material_override = brass
	$LockRig/Tensioner.position = Vector3(0.0, 0.2, 1.6)


func _collect_visuals() -> void:
	_core = $LockRig/Core
	_pick = $LockRig/Pick
	_tensioner = $LockRig/Tensioner
	for i in 5:
		_pins_visual.append($LockRig/Pins.get_child(i))


func _physics_process(_delta: float) -> void:
	if _paused or session.finished():
		_check_finished()
		return
	var input := sampler.sample()
	var events: Array = session.step(input["tension"], input["pick_depth"], input["pick_lift"], input.get("rotate", 0.0), input.get("push", 0.0), input.get("tool", 0))
	for e in events:
		FeedbackDirector.emit_event(e)  # R-21: priorities, limits, ducking
		Events.lock_event.emit(e)
	_check_finished()


func _check_finished() -> void:
	# R-08: every terminal state emits, not just break
	if session.finished():
		if session.is_open():
			Events.lock_opened.emit()
		else:
			Events.lock_failed.emit(session.failure())
		set_physics_process(false)


func _process(_delta: float) -> void:
	# R-23: describe() once per render frame, not per physics step
	if _paused or session == null:
		return
	_vm = session.describe()
	var resistance: float = _vm.get("tension_resistance", _vm.get("resistance", 0.0))
	FeedbackDirector.update_continuous(&"tension_resistance", resistance, 0.3)
	Sfx.update_loop(&"tension_resistance", resistance)
	Sfx.update_loop(&"pick_drag", _vm.get("pick_drag", 0.0))
	_update_visuals(_vm, sampler.sample())


func _update_visuals(vm: Dictionary, input: Dictionary) -> void:
	var elements: Array = vm.get("elements", vm.get("pins", []))
	for i in mini(_pins_visual.size(), elements.size()):
		var pin: Dictionary = elements[i]
		var pos: float = pin.get("position", pin.get("pos", 0.0))
		_pins_visual[i].position.y = 2.0 + pos * 0.35
		# R-29: neutral grayscale-coded states (shape carries meaning, not color — DESIGN §1)
		match String(pin.get("state", "free")):
			"set": _pins_visual[i].material_override.albedo_color = Color(0.85, 0.85, 0.85)
			"false_set": _pins_visual[i].material_override.albedo_color = Color(0.55, 0.55, 0.58)
			"overset": _pins_visual[i].material_override.albedo_color = Color(0.25, 0.25, 0.27)
			"bound", "near": _pins_visual[i].material_override.albedo_color = Color(0.7, 0.68, 0.6)
			_: _pins_visual[i].material_override.albedo_color = Color(0.75, 0.72, 0.68)
	_core.rotation.y = vm.get("core_rotation", vm.get("tension", 0.0)) * 1.5
	_tensioner.rotation.z = vm.get("tension", 0.0) * 0.25  # HUD §3: tensioner arm 0→14°
	_pick.position.z = -2.0 + input["pick_depth"] * 4.0
	_pick.position.y = 0.4 + input["pick_lift"] * 0.5


func _on_pause_pressed() -> void:
	_paused = true
	pause_menu.visible = true
	get_tree().paused = true


func _on_resume_pressed() -> void:
	_paused = false
	pause_menu.visible = false
	get_tree().paused = false


func _on_focus_lost() -> void:
	# R-03: auto-pause when the app goes to background
	if not _paused and not session.finished():
		_on_pause_pressed()


func _on_dark_mode_toggled(on: bool) -> void:
	_dark_mode = on
	var env: Environment = $WorldEnvironment.environment
	if on:
		env.background_energy_multiplier = 0.05
		env.ambient_light_energy = 0.05
	else:
		env.background_energy_multiplier = 1.0
		env.ambient_light_energy = 0.6


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if _paused:
			_on_resume_pressed()
		else:
			_on_pause_pressed()
