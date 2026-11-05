extends Control
## Replays a corpus through LockcoreSession (GDExtension lockcore_gd) and compares event hashes with the host.
## Host:    godot --headless --path . -- --gen 4 --out corpus.json   (writes res corpus with expected hashes)
## Any:     run the project (APK or host) -> replays res://corpus.json, prints LW_DET_DONE, writes user://det_result.json
## Inputs are stored as integers in 1/256 units with run-length (like lockcore golden replays), so every platform
## receives bit-identical float inputs.

const FAMILIES := ["pin_tumbler", "wafer", "warded", "lever", "lever_detector", "ring_combo", "wooden_pin"]


func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	if "--gen" in a:
		var n := int(a[a.find("--gen") + 1])
		var out: String = a[a.find("--out") + 1] if "--out" in a else "res://corpus.json"
		_gen(n, out)
		get_tree().quit()
		return
	_replay.call_deferred()


static func _q(v: float) -> int:
	return clampi(roundi(v * 256.0), -65536, 65536)


static func _rle(rows: Array) -> Array:
	var out := []
	for r in rows:
		if not out.is_empty() and out[-1].slice(1) == r:
			out[-1][0] += 1
		else:
			out.append([1] + r)
	return out


func _run(family: String, seed: int, tier: int, rle: Array) -> Dictionary:
	var s: RefCounted = ClassDB.instantiate("LockcoreSession")
	s.create(family, seed, tier)
	var steps := 0
	for r in rle:
		for k in int(r[0]):
			if s.finished():
				break
			s.step(r[1] / 256.0, r[2] / 256.0, r[3] / 256.0, r[4] / 256.0, r[5] / 256.0, int(r[6]))
			steps += 1
	return {"hash": "%016x" % s.event_hash(), "steps": steps, "open": s.is_open(), "t": s.t_step()}


func _gen(n: int, out: String) -> void:
	var corpus := []
	for fam in FAMILIES:
		for tier in [1, 2, 3]:
			for i in n:
				var seed: int = 1000 * tier + 17 * i + 3
				var sol: Dictionary = ClassDB.class_call_static("LockcoreSession", "solve", fam, seed, tier)
				if not sol.get("ok", false):
					continue
				var rows := []
				for r in sol["inputs"]:
					rows.append([_q(r[0]), _q(r[1]), _q(r[2]), _q(r[3]), _q(r[4]), int(r[5])])
				# variants: the solver's hand, a clumsy hand (deterministic integer jitter), an abandoned attempt
				var clumsy := []
				for k in rows.size():
					var r: Array = rows[k].duplicate()
					var j: int = ((k * 7919 + seed * 31) % 23) - 11
					r[0] = clampi(r[0] + j, 0, 256)
					r[2] = clampi(r[2] + ((k * 104729 + seed) % 15) - 7, -256, 256)
					clumsy.append(r)
				var half: Array = rows.slice(0, rows.size() * 3 / 5)
				for v in [["solver", rows], ["clumsy", clumsy], ["partial", half]]:
					var rle: Array = _rle(v[1])
					var res: Dictionary = _run(fam, seed, tier, rle)
					corpus.append({"family": fam, "seed": seed, "tier": tier, "variant": v[0], "inputs": rle,
						"expected": res})
	var f := FileAccess.open(out, FileAccess.WRITE)
	f.store_string(JSON.stringify({"schema": "lockwright.det-corpus/1", "platform": OS.get_name(),
		"arch": Engine.get_architecture_name(), "replays": corpus}))
	f.close()
	print("LW_DET_GEN replays=%d out=%s" % [corpus.size(), out])


func _replay() -> void:
	var label: Label = $Label
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://corpus.json"))
	var ok := 0
	var bad := []
	var digest := HashingContext.new()
	digest.start(HashingContext.HASH_SHA256)
	var t0 := Time.get_ticks_msec()
	for e in data["replays"]:
		var res: Dictionary = _run(e["family"], int(e["seed"]), int(e["tier"]), e["inputs"])
		digest.update(("%s/%d/%d/%s=%s;" % [e["family"], int(e["seed"]), int(e["tier"]), e["variant"], res["hash"]]).to_utf8_buffer())
		var ex: Dictionary = e["expected"]
		if res["hash"] == ex["hash"] and int(res["steps"]) == int(ex["steps"]) and res["open"] == ex["open"]:
			ok += 1
		else:
			bad.append({"family": e["family"], "seed": e["seed"], "tier": e["tier"], "variant": e["variant"],
				"got": res, "expected": ex})
	var dg := digest.finish().hex_encode()
	var result := {"schema": "lockwright.det-result/1", "platform": OS.get_name(), "arch": Engine.get_architecture_name(),
		"model": OS.get_model_name(), "replays": data["replays"].size(), "ok": ok, "bad": bad.size(),
		"mismatches": bad.slice(0, 20), "digest": dg, "ms": Time.get_ticks_msec() - t0,
		"corpus_from": "%s/%s" % [data.get("platform", "?"), data.get("arch", "?")]}
	var f := FileAccess.open("user://det_result.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(result))
	f.close()
	for m in bad.slice(0, 5):
		print("LW_DET_MISMATCH ", JSON.stringify(m))
	print("LW_DET_DONE platform=%s arch=%s replays=%d ok=%d bad=%d digest=%s ms=%d" % [
		result["platform"], result["arch"], result["replays"], ok, bad.size(), dg, result["ms"]])
	label.text = "Determinizm lockcore_gd\n%s %s\n%d / %d zgodnych\n%s" % [result["platform"], result["arch"], ok, result["replays"], dg.substr(0, 16)]
	if OS.get_name() != "Android":
		get_tree().quit(0 if bad.is_empty() else 1)
