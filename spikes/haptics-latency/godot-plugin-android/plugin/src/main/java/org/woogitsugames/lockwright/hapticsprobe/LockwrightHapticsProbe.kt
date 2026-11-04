package org.woogitsugames.lockwright.hapticsprobe

import android.os.SystemClock
import org.godotengine.godot.Dictionary
import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.UsedByGodot

/**
 * Spike 1/2 measurement plugin (not the production bridge in platform/android).
 * Singleton: LockwrightHapticsProbe. Times are elapsedRealtimeNanos as strings
 * (64-bit safe through the JNI Variant conversion).
 */
class LockwrightHapticsProbe(godot: Godot) : GodotPlugin(godot) {
    private val core by lazy { HapticCore(activity!!.applicationContext) }

    override fun getPluginName(): String = "LockwrightHapticsProbe"

    @UsedByGodot
    fun now_ns(): String = SystemClock.elapsedRealtimeNanos().toString()

    @UsedByGodot
    fun transient(intensity: Float, sharpness: Float): Dictionary {
        val t = core.transient(intensity, sharpness)
        val d = Dictionary()
        d["call_ns"] = t[0].toString()
        d["return_ns"] = t[1].toString()
        d["call_us"] = (t[1] - t[0]) / 1000.0
        return d
    }

    @UsedByGodot
    fun continuous_start() = core.continuousStart()

    @UsedByGodot
    fun continuous_update(intensity: Float, sharpness: Float): String =
        core.continuousUpdate(intensity, sharpness).toString()

    @UsedByGodot
    fun continuous_stop() = core.continuousStop()

    @UsedByGodot
    fun set_touch_usage(touch: Boolean) { core.useTouchUsage = touch }

    @UsedByGodot
    fun capabilities(): Dictionary {
        val d = Dictionary()
        for ((k, v) in core.capabilities()) d[k] = v
        return d
    }

    override fun onMainPause() = core.continuousStop()
}
