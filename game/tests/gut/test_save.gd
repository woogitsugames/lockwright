extends GutTest

func test_defaults() -> void:
	assert_eq(Save.data.get("schema", "save/1"), "save/1")
	assert_true(Save.get_value("tools/tw_angle/owned", false))

func test_migration_keeps_schema() -> void:
	var migrated: Dictionary = Save.migrate({"schema": "save/1", "coins": 42})
	assert_eq(migrated.get("schema"), "save/1")
	assert_eq(migrated.get("coins"), 42)

func test_migration_unknown_resets() -> void:
	var migrated: Dictionary = Save.migrate({"schema": "save/99"})
	assert_eq(migrated.get("schema"), "save/1")

func test_set_get_roundtrip() -> void:
	Save.set_value("stats/locks_opened", 7)
	assert_eq(Save.get_value("stats/locks_opened"), 7)
	Save.set_value("stats/locks_opened", 0)
