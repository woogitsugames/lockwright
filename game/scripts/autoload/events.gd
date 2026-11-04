extends Node
## Events: central signal bus. Decouples lockcore events from feedback channels.

# Lock lifecycle
signal lock_event(event: Dictionary)  # {tick, kind, element, intensity, material}
signal lock_opened
signal lock_failed(reason: StringName)
# Feedback routing (same frame as lock_event, never waits for render — ARCHITECTURE.md §5)
signal feedback(event: Dictionary)
# Scene navigation
signal scene_change_requested(scene: StringName)
