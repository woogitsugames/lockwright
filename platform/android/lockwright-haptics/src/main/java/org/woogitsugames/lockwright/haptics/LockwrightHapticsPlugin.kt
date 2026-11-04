package org.woogitsugames.lockwright.haptics

import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.UsedByGodot

/**
 * Godot Android plugin v2 exposing the LockwrightHaptics singleton.
 * Method names are 1:1 with the GDScript facade (docs/TECH.md §2.5) —
 * Godot does NOT convert snake_case for plugin v2.
 */
class LockwrightHapticsPlugin(godot: Godot) : GodotPlugin(godot) {

    private val engine by lazy { HapticsEngine(godot) }

    override fun getPluginName(): String = "LockwrightHaptics"

    override fun getPluginSignals(): Set<String> = emptySet()

    @UsedByGodot
    fun play(event: String, intensity: Double, material: String) {
        engine.play(event, intensity.toFloat(), material)
    }

    @UsedByGodot
    fun begin_continuous(id: String) {
        engine.beginContinuous(id)
    }

    @UsedByGodot
    fun update_continuous(id: String, intensity: Double, sharpness: Double) {
        engine.updateContinuous(id, intensity.toFloat(), sharpness.toFloat())
    }

    @UsedByGodot
    fun end_continuous(id: String) {
        engine.endContinuous(id)
    }

    @UsedByGodot
    fun capabilities(): String = engine.capabilitiesJson()

    @UsedByGodot
    fun stop_all() {
        engine.stopAll()
    }
}
