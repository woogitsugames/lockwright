extends RefCounted
## Tier range of every lockcore family for tests: lockcore/tiers.json (D-118), the checked-in copy that
## `verify_seeds --tiers` writes and ctest `tiers_json_in_sync` keeps equal to the families'
## min_tier()/max_tier(). The one place GUT reads it, so no test carries a copied table (D-120).
## Reachable when the project runs from the repository (CI, local); {} from an exported pack.

static func path() -> String:
	return ProjectSettings.globalize_path("res://").path_join("../lockcore/tiers.json").simplify_path()


## {family: [min tier, max tier]}; {} when the file is not reachable or not a lockcore.tiers/1 file.
static func ranges() -> Dictionary:
	var out := {}
	if not FileAccess.file_exists(path()):
		return out
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(path()))
	if typeof(d) != TYPE_DICTIONARY or String(d.get("schema", "")) != "lockcore.tiers/1":
		return out
	for fam: String in d.get("families", {}):
		out[fam] = [int(d["families"][fam]["min"]), int(d["families"][fam]["max"])]
	return out
