extends "res://tests/gut/test_tutorial_hints.gd"
func test_dbg() -> void:
	var o: Array = await _open(false)
	var scene: Node = o[0]
	var hints: TutorialHints = o[2]
	for k in 8:
		_idle(scene, 0.5)
		print("DBG t=", (k + 1) * 0.5, " stuck=", hints.ladder._stuck_s, " step=", hints.step)
	var s: RefCounted = scene.session
	var kinds := {}
	for i in 600:
		for e in s.step(0.0, 0.5, 0.0):
			kinds[e["kind"]] = kinds.get(e["kind"], 0) + 1
	print("DBG kinds ", kinds)
