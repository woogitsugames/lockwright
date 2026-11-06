# GPU APK device check

Samsung SM-A165F, APK run 42185136957, commit 4766aaca. Install -r succeeded and preserved data. Main menu was blank because res://assets/ui/menu/menu_layout.json is missing. No menu assets are tracked at that path. Restored working APK 42163108394 without uninstalling or clearing data. Session A owns the menu integration fix and CI. New detector device checks remain blocked by this entry screen.
