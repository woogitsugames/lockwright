extends InputSampler
## QA: replaces the touch sampler in the lock scene with the inputs of lockcore's scripted bot
## (LockcoreSession.solve), one row per physics step. sample() is a pure getter like the real sampler
## (the lock scene calls it more than once per step); the row advances once per physics tick.
## Injected by career.gd into a COPY of game/.

var rows: Array = []
var i := 0


func _physics_process(_delta: float) -> void:
	# runs after the parent lock scene's _physics_process (tree order), so step k uses row k
	if i < rows.size():
		i += 1


func sample() -> Dictionary:
	if i < rows.size():
		var r: Array = rows[i]
		return {"tension": float(r[0]), "pick_depth": float(r[1]), "pick_lift": float(r[2]),
			"rotate": float(r[3]) if r.size() > 3 else 0.0, "push": float(r[4]) if r.size() > 4 else 0.0,
			"tool": int(r[5]) if r.size() > 5 else 0}
	return {"tension": 0.0, "pick_depth": 0.0, "pick_lift": 0.0, "rotate": 0.0, "push": 0.0, "tool": 0}
