extends GutTest
## S03v2: every speaker id used in jobs data (lines) has 8 loadable voices;
## episodic ids resolve to their own .ogg files, missing emotions fall back to greeting.

const EMOTIONS := [&"greeting", &"surprise", &"relief", &"thanks", &"impatient", &"sad", &"laugh", &"goodbye"]
const NOT_VOICED := ["locksmith"]  # the player character has no client voice
## Speakers whose S03v2 wordless reactions are not made yet: play_voice() is a silent no-op for them until the
## reactions arrive (then remove the id here). T43 and T18 speakers got theirs on 2026-11-06 (tools/voice_lines.py).
const S03_PENDING: Array[String] = []


func _speakers() -> Array:
	var out: Array = []
	for dir in ["res://data/jobs"]:
		for f in DirAccess.get_files_at(dir):
			if not f.ends_with(".json"):
				continue
			var j: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(dir + "/" + f))
			for spk in j.get("lines", []):
				if not spk in out and not spk in NOT_VOICED:
					out.append(spk)
	return out


func test_every_job_speaker_has_8_voices() -> void:
	var speakers := _speakers()
	assert_gt(speakers.size(), 40, "jobs data lists the cast + 39 episodic speakers")
	for spk in speakers:
		if spk in S03_PENDING:
			Sfx.play_voice(StringName(spk), &"greeting")  # must not fail without files
			continue
		var folder := String(Sfx.VOICE_DIR.get(StringName(spk), StringName(spk)))
		var dir := Sfx.VOICE_ROOT + "/" + folder + "/"
		for emo in EMOTIONS:
			var keys: Array = Sfx.voice_keys(StringName(spk), emo)
			assert_false(keys.is_empty(), "%s/%s: no voice" % [spk, emo])
			if keys.is_empty():
				continue
			var key: String = keys[0]
			assert_true(key.begins_with(dir), "%s/%s resolves inside its own folder" % [spk, emo])
			assert_false(key.get_file().begins_with("greeting") and emo != &"greeting",
				"%s/%s: has its own file, not the greeting fallback" % [spk, emo])
			assert_true(Sfx._cache[key] is AudioStream, "%s: loadable AudioStream" % key)


func test_episodic_voice_is_ogg_and_plays() -> void:
	var keys: Array = Sfx.voice_keys(&"zbyszek", &"thanks")
	assert_eq(keys.size(), 1)
	assert_true(Sfx._cache[keys[0]] is AudioStreamOggVorbis, "episodic voices ship as Ogg Vorbis")
	var before: int = Sfx._free.size()
	Sfx.play_voice(&"zbyszek", &"greeting")
	assert_eq(Sfx._free.size(), before - 1, "episodic greeting occupies a pool player")


func test_missing_emotion_falls_back_to_greeting() -> void:
	var keys: Array = Sfx.voice_keys(&"zbyszek", &"no_such_emotion")
	assert_eq(keys.size(), 1)
	assert_eq(String(keys[0]).get_file().get_basename(), "greeting")
