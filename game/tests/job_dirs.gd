extends RefCounted
## D-131: where the career's data is on disk, for tests that walk every job file or text row. Chapters
## 13+ live in content pack sources (res://packs/<id>/, D-112), so "every job" is the base folder plus
## every pack folder. The sources are read straight from disk, whatever ContentPacks holds right now
## (tests of the pack mechanism point the autoload at fixtures).

const BASE_JOBS := "res://data/jobs"
const PACKS := "res://packs"
const BASE_CSVS := ["res://i18n/strings.csv", "res://i18n/content.csv"]


## Ids of the content pack source folders, sorted.
static func pack_ids() -> Array:
	var out := []
	if DirAccess.dir_exists_absolute(PACKS):
		for id in DirAccess.get_directories_at(PACKS):
			if FileAccess.file_exists("%s/%s/pack.json" % [PACKS, id]):
				out.append(id)
	out.sort()
	return out


## Every folder with job files: the base game's first, then each pack's.
static func all() -> Array:
	var out := [BASE_JOBS]
	for id: String in pack_ids():
		out.append("%s/%s/jobs" % [PACKS, id])
	return out


## Full paths of every job file (base game first, then the packs; sorted inside a folder).
static func files() -> Array:
	var out := []
	for dir: String in all():
		var names := Array(DirAccess.get_files_at(dir))
		names.sort()
		for f: String in names:
			if f.ends_with(".json"):
				out.append(dir.path_join(f))
	return out


## The text files of jobs and chapters: res://i18n/content.csv and every pack's i18n/content.csv.
static func content_csvs() -> Array:
	var out := ["res://i18n/content.csv"]
	for id: String in pack_ids():
		var p := "%s/%s/i18n/content.csv" % [PACKS, id]
		if FileAccess.file_exists(p):
			out.append(p)
	return out


## strings.csv plus content_csvs(): every text file of the game.
static func all_csvs() -> Array:
	return ["res://i18n/strings.csv"] + content_csvs()
