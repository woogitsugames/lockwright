package org.woogitsugames.lockwright.haptics

import android.app.Activity
import android.view.View
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

    /** D-97: TalkBack bridge over the render view (see A11yBridge). */
    private var bridge: A11yBridge? = null

    override fun getPluginSignals(): Set<SignalInfo> = setOf(
        SignalInfo("a11y_activate", Int::class.javaObjectType),
        SignalInfo("a11y_adjust", Int::class.javaObjectType, Int::class.javaObjectType),
    )

    override fun onMainCreate(activity: Activity?): View? {
        val act = activity ?: return null
        val b = A11yBridge(act)
        b.onActivate = { id -> runOnRenderThread { emitSignal("a11y_activate", id) } }
        b.onAdjust = { id, dir -> runOnRenderThread { emitSignal("a11y_adjust", id, dir) } }
        bridge = b
        return b
    }

    /** D-97: an accessibility client listens (publish the nodes). */
    @UsedByGodot
    fun a11y_active(): Boolean = bridge?.active() ?: false

    /** D-97: a spoken screen reader (TalkBack) runs. */
    @UsedByGodot
    fun a11y_screen_reader(): Boolean = bridge?.screenReader() ?: false

    /** D-97: the game's accessible controls as a JSON array (see A11yBridge.setNodes). */
    @UsedByGodot
    fun a11y_set_nodes(json: String) {
        val b = bridge ?: return
        runOnUiThread { b.setNodes(json) }
    }

    /** D-97: spoken by TalkBack (lock states, hints). */
    @UsedByGodot
    fun a11y_announce(text: String) {
        val b = bridge ?: return
        runOnUiThread { b.announce(text) }
    }

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

    /** D-93: total device RAM in bytes as a decimal string (ActivityManager; Godot's
     *  OS.get_memory_info() reports -1 on Android). "0" when unknown. */
    @UsedByGodot
    fun device_ram_bytes(): String = try {
        val am = getContext().getSystemService(android.app.ActivityManager::class.java)
        val info = android.app.ActivityManager.MemoryInfo()
        am?.getMemoryInfo(info)
        info.totalMem.toString()
    } catch (e: Exception) {
        "0"
    }

    @UsedByGodot
    fun perf_hint_stop() {
        frameHint.stop()
    }
}
