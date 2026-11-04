extends Node

func _ready() -> void:
	var s := FakeLockSession.create(&"pin_tumbler", 42, 2)
	var kinds := {}
	var opened := false
	for tick in 120 * 60:
		var t := 0.5 if (tick % 480) < 400 else 0.0
		var depth := float((tick / 96) % 5) / 5.0
		var lift := 0.6 if (tick % 96) > 48 else 0.0
		for e in s.step(t, depth, lift):
			kinds[e["kind"]] = kinds.get(e["kind"], 0) + 1
			if e["kind"] == &"open":
				opened = true
	print("events: ", kinds)
	print("open: ", opened, " pins: ", s.describe()["pins"].map(func(p): return p["state"]))
	get_tree().quit(0 if opened else 1)
