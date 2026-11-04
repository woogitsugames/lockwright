extends Node3D
## Lock screen controller. No UI panels (D-12): only a 48 dp pause button in the
## corner; thumb zones are invisible. Lock events go to Haptics and Sfx in the same
## physics step, never waiting for a render frame (ARCHITECTURE.md §5).

@onready var sampler: InputSampler = $InputSampler
@onready var pause_button: Button = $UILayer/PauseButton
@onready var pause_menu: Control = $UILayer/PauseMenu

var session: FakeLockSession
var _pins_visual: Array = []
var _core: MeshInstance3D
var _pick: MeshInstance3D
var _dark_mode := false
var _paused := false


func _ready() -> void:
	session = FakeLockSession.create(&"pin_tumbler", 42, 2)
	pause_button.text = I18n.t(&"lock.pause")
	pause_button.pressed.connect(_on_pause_pressed)
	pause_menu.visible = false
	$UILayer/PauseMenu/Title.text = I18n.t(&"pause.title")
	$UILayer/PauseMenu/ResumeButton.text = I18n.t(&"pause.resume")
	$UILayer/PauseMenu/DarkModeCheck.text = I18n.t(&"pause.dark_mode")
	$UILayer/PauseMenu/QuitButton.text = I18n.t(&"pause.quit")
	$UILayer/PauseMenu/ResumeButton.pressed.connect(_on_resume_pressed)
	$UILayer/PauseMenu/DarkModeCheck.toggled.connect(_on_dark_mode_toggled)
	$UILayer/PauseMenu/QuitButton.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))
	_build_placeholder_meshes()
	_collect_visuals()
	Sfx.begin_loop(&"tension_resistance", &"brass")
	Sfx.begin_loop(&"pick_drag", &"steel")
	Haptics.begin_continuous(&"tension_resistance")


func _build_placeholder_meshes() -> void:
	# Temporary PBR placeholder until glTF models from art/ land (task 7 note).
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


func _collect_visuals() -> void:
	_core = $LockRig/Core
	_pick = $LockRig/Pick
	for i in 5:
		_pins_visual.append($LockRig/Pins.get_child(i))


func _physics_process(_delta: float) -> void:
	if _paused or session.finished():
		return
	var input := sampler.sample()
	var events := session.step(input["tension"], input["pick_depth"], input["pick_lift"])
	for e in events:
		Haptics.play(e["kind"], e["intensity"], e["material"])
		Sfx.play(e["kind"], e["material"], 0.0, 1.0)
	Events.lock_event.emit(e)
		if e["kind"] == &"open":
			Events.lock_opened.emit()
		if e["kind"] == &"break":
			Events.lock_failed.emit(&"break")
	var vm := session.describe()
	Haptics.update_continuous(&"tension_resistance", vm["resistance"], 0.3)
	Sfx.update_loop(&"tension_resistance", vm["resistance"])
	Sfx.update_loop(&"pick_drag", vm["pick_drag"])
	_update_visuals(vm, input)


func _update_visuals(vm: Dictionary, input: Dictionary) -> void:
	for i in _pins_visual.size():
		var pin: Dictionary = vm["pins"][i]
		_pins_visual[i].position.y = 2.0 + pin["pos"] * 0.35
		match pin["state"]:
			"set": _pins_visual[i].get_surface_override_material(0).albedo_color = Color(0.55, 0.75, 0.45)
			"false_set": _pins_visual[i].get_surface_override_material(0).albedo_color = Color(0.75, 0.55, 0.3)
			"overset": _pins_visual[i].get_surface_override_material(0).albedo_color = Color(0.7, 0.3, 0.3)
			"bound": _pins_visual[i].get_surface_override_material(0).albedo_color = Color(0.8, 0.7, 0.4)
			_: _pins_visual[i].get_surface_override_material(0).albedo_color = Color(0.75, 0.72, 0.68)
	_core.rotation.y = vm["tension"] * 0.5 + (0.6 if vm["open"] else 0.0)
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


func _on_dark_mode_toggled(on: bool) -> void:
	_dark_mode = on
	var env := $WorldEnvironment.environment
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
