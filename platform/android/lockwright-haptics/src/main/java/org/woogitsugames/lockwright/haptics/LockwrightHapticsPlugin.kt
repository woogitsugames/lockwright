package org.woogitsugames.lockwright.haptics

import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.SignalInfo
import org.godotengine.godot.plugin.UsedByGodot

/**
 * Godot Android plugin v2 exposing the LockwrightHaptics singleton.
 * Method names are 1:1 with the GDScript facade (docs/TECH.md §2.5) —
 * Godot does NOT convert snake_case for plugin v2.
 */
class LockwrightHapticsPlugin(godot: Godot) : GodotPlugin(godot) {

    private val engine by lazy { HapticsEngine(getContext()) }
    private val frameHint by lazy { FrameHint(getContext()) }

    override fun getPluginName(): String = "LockwrightHaptics"

    override fun getPluginSignals(): Set<SignalInfo> = emptySet()

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

    /** Settings "Test pulse" (N-70): one long oneshot, perceptible on every motor. */
    @UsedByGodot
    fun test_pulse(durationMs: Int, level: Double) {
        engine.testPulse(durationMs.toLong(), level.toFloat())
    }

    @UsedByGodot
    fun stop_all() {
        engine.stopAll()
    }

    /** D-88: ADPF hint session bound to the calling (game) thread; false when unsupported. */
    @UsedByGodot
    fun perf_hint_start(targetUs: Int): Boolean = frameHint.start(targetUs.toLong() * 1000L)

    /** D-88: CPU work of the last frame in microseconds. */
    @UsedByGodot
    fun perf_hint_report(actualUs: Int) {
        frameHint.report(actualUs.toLong() * 1000L)
    }

    @UsedByGodot
    fun perf_hint_stop() {
        frameHint.stop()
    }
}
