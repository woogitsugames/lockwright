extends GutTest

const EVENTS := ["contact", "bind", "near_shear", "set", "false_set", "counter_rotate", "overset",
	"drop", "stress", "break", "wear", "gate_align", "detector_trip", "open"]
const LOOPS := ["tension_resistance", "pick_drag"]
const MATERIALS := ["brass", "steel", "iron", "wood"]

func test_every_event_has_4_materials() -> void:
	for e in EVENTS + LOOPS:
		for m in MATERIALS:
			var nv := 4 if e in LOOPS else 6
			for n in range(1, nv + 1):
				var path := "res://assets/audio/sfx/%s/%s_%d.wav" % [e, m, n]
				assert_true(ResourceLoader.exists(path), "missing sample: %s" % path)

func test_play_does_not_crash_headless() -> void:
	Sfx.play(&"set", &"brass")
	Sfx.play(&"break", &"steel")
	Sfx.begin_loop(&"tension_resistance", &"brass")
	Sfx.update_loop(&"tension_resistance", 0.5)
	Sfx.end_loop(&"tension_resistance")
	assert_true(true)

func test_play_voice_finds_plain_file_and_shared_folder() -> void:
	# N-48: <root>/<speaker>/<kind>.wav (not only <kind>_NN.wav), ola/krystyna -> ola_krystyna
	# earlier suites leave long one-shots (jingles, foley) in the pool: start from a free pool
	Sfx.stop_all_one_shots()
	var before: int = Sfx._free.size()
	Sfx.play_voice(&"halina", &"greeting")
	assert_eq(Sfx._free.size(), before - 1, "halina/greeting.wav must occupy a player from the pool")
	Sfx.play_voice(&"ola", &"greeting")
	assert_eq(Sfx._free.size(), before - 2, "ola must resolve to the shared ola_krystyna folder")
