extends Node
## Headless check that a session (LockcoreSession if present, else FakeLockSession)
## emits lock events and can be stepped deterministically.

func _make_session() -> RefCounted:
	if ClassDB.class_exists("LockcoreSession"):
		var s: RefCounted = ClassDB.instantiate("LockcoreSession")
		assert(s.create(&"pin_tumbler", 42, 2))
		return s
	return FakeLockSession.create(&"pin_tumbler", 42, 2)

func _ready() -> void:
	var s := _make_session()
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
	var vm: Dictionary = s.describe()
	print("events: ", kinds)
	print("open: ", opened, " elements: ", vm.get("elements", vm.get("pins")))
	var fail := 0
	if kinds.is_empty():
		printerr("LOCKTEST FAIL: no events emitted")
		fail = 1
	if not (kinds.has(&"bind") or kinds.has(&"contact")):
		printerr("LOCKTEST FAIL: expected bind/contact events")
		fail = 1
	print("LOCKTEST %s" % ("OK" if fail == 0 else "FAIL"))
	get_tree().quit(fail)
