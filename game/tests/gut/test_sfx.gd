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
