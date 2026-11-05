package org.woogitsugames.lockwright.hapticsprobe

import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import android.os.SystemClock
import android.os.VibrationAttributes
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager

/**
 * Spike 1/2 measurement core (docs/TECH.md §2.2, §4): one transient + one continuous "resistance",
 * with the tier ladder A3 (envelopes) -> A2 (primitives) -> A1 (amplitude waveform) -> A0 (on/off).
 * Shared verbatim by the Godot plugin and the native Compose control app, so the only difference
 * between the two measurements is the engine in front of it.
 *
 * Every call returns SystemClock.elapsedRealtimeNanos() taken right before and after the
 * vibrator call; MotionEvent.getEventTimeNanos() (API 34+) uses the uptime clock, so both are
 * reported: elapsedRealtimeNanos and uptimeNanos (= SystemClock.uptimeNanos() equivalent).
 */
class HapticCore(context: Context) {
    val vibrator: Vibrator = if (Build.VERSION.SDK_INT >= 31) {
        (context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager).defaultVibrator
    } else {
        @Suppress("DEPRECATION")
        context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
    }

    enum class Tier { A_NONE, A0, A1, A2, A3 }

    var useTouchUsage = false   // USAGE_TOUCH follows the system "touch feedback" switch; USAGE_MEDIA does not
    val tier: Tier = detect()
    private val thread = HandlerThread("lw-haptic-continuous").apply { start() }
    private val handler = Handler(thread.looper)
    @Volatile private var contIntensity = 0f
    @Volatile private var contSharpness = 0.3f
    @Volatile private var contRunning = false
    @Volatile var lastUpdateNs = 0L
        private set
    var calls = 0L
        private set

    private fun detect(): Tier {
        if (!vibrator.hasVibrator()) return Tier.A_NONE
        if (Build.VERSION.SDK_INT >= 36 && envelopeSupported()) return Tier.A3
        if (Build.VERSION.SDK_INT >= 30 &&
            vibrator.areAllPrimitivesSupported(VibrationEffect.Composition.PRIMITIVE_CLICK, VibrationEffect.Composition.PRIMITIVE_TICK)) return Tier.A2
        if (vibrator.hasAmplitudeControl()) return Tier.A1
        return Tier.A0
    }

    private fun envelopeSupported(): Boolean = try {
        Vibrator::class.java.getMethod("areEnvelopeEffectsSupported").invoke(vibrator) as Boolean
    } catch (e: Throwable) { false }

    private fun attrs(): VibrationAttributes = VibrationAttributes.createForUsage(
        if (useTouchUsage) VibrationAttributes.USAGE_TOUCH else VibrationAttributes.USAGE_MEDIA)

    private fun vibrate(effect: VibrationEffect) {
        calls++
        vibrator.vibrate(effect, attrs())
    }

    /** Short "set"-like click. Returns [before_ns, after_ns] (elapsedRealtimeNanos). */
    fun transient(intensity: Float, sharpness: Float): LongArray {
        val t0 = SystemClock.elapsedRealtimeNanos()
        val i = intensity.coerceIn(0f, 1f)
        when (tier) {
            Tier.A3, Tier.A2 -> {
                val prim = if (sharpness >= 0.5f) VibrationEffect.Composition.PRIMITIVE_CLICK else VibrationEffect.Composition.PRIMITIVE_TICK
                vibrate(VibrationEffect.startComposition().addPrimitive(prim, i).compose())
            }
            Tier.A1 -> vibrate(VibrationEffect.createOneShot(18, (i * 255).toInt().coerceIn(1, 255)))
            Tier.A0 -> vibrate(VibrationEffect.createOneShot(40, VibrationEffect.DEFAULT_AMPLITUDE))  // TECH §2.2 upper bound; 30 ms did not move a coin ERM (GEM3)
            Tier.A_NONE -> {}
        }
        return longArrayOf(t0, SystemClock.elapsedRealtimeNanos())
    }

    /** Continuous resistance: A3 = 60 ms envelopes re-sent every 50 ms; A1/A2 = 40 ms amplitude segment
     *  repeated, re-sent every 100 ms (each vibrate() cancels the previous one). A0: nothing (TECH §2.2). */
    fun continuousStart() {
        if (contRunning || tier == Tier.A0 || tier == Tier.A_NONE) return
        contRunning = true
        handler.post(object : Runnable {
            override fun run() {
                if (!contRunning) return
                sendContinuous()
                handler.postDelayed(this, if (tier == Tier.A3) 50 else 100)
            }
        })
    }

    fun continuousUpdate(intensity: Float, sharpness: Float): Long {
        contIntensity = intensity.coerceIn(0f, 1f)
        contSharpness = sharpness.coerceIn(0f, 1f)
        lastUpdateNs = SystemClock.elapsedRealtimeNanos()
        return lastUpdateNs
    }

    fun continuousStop() {
        contRunning = false
        handler.removeCallbacksAndMessages(null)
        vibrator.cancel()
    }

    private fun sendContinuous() {
        val i = contIntensity
        if (i <= 0.01f) return
        if (tier == Tier.A3 && Build.VERSION.SDK_INT >= 36) {
            // Basic envelope (API 36): intensity/sharpness 0..1, framework maps to the actuator.
            val b = VibrationEffect.BasicEnvelopeBuilder()
                .setInitialSharpness(contSharpness)
                .addControlPoint(i, contSharpness, 20)
                .addControlPoint(i, contSharpness, 40)
            vibrate(b.build())
        } else {
            val amp = (i * 140 + 30).toInt().coerceIn(1, 255)    // TECH §3.3: amp 30-140
            vibrate(VibrationEffect.createWaveform(longArrayOf(40), intArrayOf(amp), 0))
        }
    }

    fun capabilities(): Map<String, Any> {
        val m = HashMap<String, Any>()
        m["tier"] = tier.name
        m["sdk"] = Build.VERSION.SDK_INT
        m["model"] = "${Build.MANUFACTURER} ${Build.MODEL}"
        m["hasAmplitudeControl"] = vibrator.hasAmplitudeControl()
        m["envelopes"] = envelopeSupported()
        if (Build.VERSION.SDK_INT >= 30) {
            val p = intArrayOf(
                VibrationEffect.Composition.PRIMITIVE_CLICK, VibrationEffect.Composition.PRIMITIVE_TICK,
                VibrationEffect.Composition.PRIMITIVE_LOW_TICK, VibrationEffect.Composition.PRIMITIVE_THUD,
                VibrationEffect.Composition.PRIMITIVE_QUICK_RISE, VibrationEffect.Composition.PRIMITIVE_SLOW_RISE,
                VibrationEffect.Composition.PRIMITIVE_QUICK_FALL)
            val names = arrayOf("CLICK", "TICK", "LOW_TICK", "THUD", "QUICK_RISE", "SLOW_RISE", "QUICK_FALL")
            val sup = vibrator.arePrimitivesSupported(*p)
            val dur = if (Build.VERSION.SDK_INT >= 31) vibrator.getPrimitiveDurations(*p) else IntArray(p.size)
            m["primitives"] = names.indices.joinToString(",") { "${names[it]}:${if (sup[it]) dur[it] else -1}" }
        }
        m["usage"] = if (useTouchUsage) "TOUCH" else "MEDIA"
        return m
    }

    fun close() {
        continuousStop()
        thread.quitSafely()
    }
}
