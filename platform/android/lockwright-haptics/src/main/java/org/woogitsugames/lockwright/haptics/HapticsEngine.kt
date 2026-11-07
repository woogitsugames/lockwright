package org.woogitsugames.lockwright.haptics

import android.content.Context
import android.media.AudioAttributes
import android.os.Build
import android.os.VibrationAttributes
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.os.Handler
import android.os.HandlerThread
import android.os.Process
import android.os.SystemClock
import android.util.Log

/**
 * Tiered haptics engine (docs/TECH.md §2.2). Every call is posted to a single
 * HandlerThread so the game thread never blocks on the vibrator.
 *
 * Tiers: A4 Builder (SDK_INT_FULL >= 370200) > A3 Envelope (API 36 +
 * areEnvelopeEffectsSupported) > A2 Composition (API 30+, primitives CLICK/TICK)
 * > A1 Waveform (hasAmplitudeControl) > A0 on/off > A- none.
 */
class HapticsEngine(context: Context) {

    enum class Tier { NONE, ON_OFF, AMPLITUDE, PRIMITIVES, ENVELOPE, BUILDER }

    private val appContext = context.applicationContext
    private val vibrator: Vibrator? = if (Build.VERSION.SDK_INT >= 31) {
        (appContext.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager)?.defaultVibrator
    } else {
        @Suppress("DEPRECATION")
        appContext.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
    }

    private val thread = HandlerThread("lockwright-haptics", Process.THREAD_PRIORITY_FOREGROUND).apply { start() }
    private val handler = Handler(thread.looper)

    val tier: Tier
    val primitives: List<String>
    val amplitudeControl: Boolean
    val envelopeSupported: Boolean

    private data class Continuous(var active: Boolean = false, var intensity: Float = 0f, var sharpness: Float = 0f)
    private val continuous = HashMap<String, Continuous>()
    private var lastSegmentAt = 0L
    private var transientUntilMs = 0L  // N-02: resistance segments pause while a transient plays

    init {
        val v = vibrator
        if (v == null || !v.hasVibrator()) {
            tier = Tier.NONE
            primitives = emptyList()
            amplitudeControl = false
            envelopeSupported = false
        } else {
            amplitudeControl = v.hasAmplitudeControl()
            envelopeSupported = Build.VERSION.SDK_INT >= 36 &&
                (runCatching { v.areEnvelopeEffectsSupported() }.getOrDefault(false) as Boolean)
            primitives = detectPrimitives(v)
            tier = when {
                // N-79: SDK_INT_FULL (major * 100000 + minor) is >= 370200 on every API 36 phone, so a
                // MOTOR_COIN_DC without primitives, envelopes or amplitude control was reported as
                // BUILDER and every composition fell back to 20 ms amplitude-scaled waveforms it
                // cannot play (and to continuous resistance an on/off motor should not get).
                Build.VERSION.SDK_INT_FULL >= 370200 && envelopeSupported -> Tier.BUILDER
                envelopeSupported -> Tier.ENVELOPE
                Build.VERSION.SDK_INT >= 30 && v.areAllPrimitivesSupported(
                    VibrationEffect.Composition.PRIMITIVE_CLICK,
                    VibrationEffect.Composition.PRIMITIVE_TICK
                ) -> Tier.PRIMITIVES
                amplitudeControl -> Tier.AMPLITUDE
                else -> Tier.ON_OFF
            }
        }
        Log.i(TAG, "tier=$tier primitives=$primitives amplitude=$amplitudeControl envelope=$envelopeSupported")
    }

    private fun detectPrimitives(v: Vibrator): List<String> {
        val all = listOf(
            "CLICK" to VibrationEffect.Composition.PRIMITIVE_CLICK,
            "TICK" to VibrationEffect.Composition.PRIMITIVE_TICK,
            "LOW_TICK" to VibrationEffect.Composition.PRIMITIVE_LOW_TICK,
            "THUD" to VibrationEffect.Composition.PRIMITIVE_THUD,
            "SPIN" to VibrationEffect.Composition.PRIMITIVE_SPIN,
            "QUICK_RISE" to VibrationEffect.Composition.PRIMITIVE_QUICK_RISE,
            "SLOW_RISE" to VibrationEffect.Composition.PRIMITIVE_SLOW_RISE,
            "QUICK_FALL" to VibrationEffect.Composition.PRIMITIVE_QUICK_FALL
        )
        val out = ArrayList<String>()
        for ((name, id) in all) {
            val ok = if (Build.VERSION.SDK_INT >= 31) {
                runCatching { v.arePrimitivesSupported(id).firstOrNull() == true }.getOrDefault(false)
            } else {
                id == VibrationEffect.Composition.PRIMITIVE_CLICK || id == VibrationEffect.Composition.PRIMITIVE_TICK
            }
            if (ok) out.add(name)
        }
        return out
    }

    fun capabilitiesJson(): String {
        val prims = primitives.joinToString(",") { "\"$it\"" }
        return ("{" +
            "\"tier\":\"$tier\"," +
            "\"primitives\":[$prims]," +
            "\"amplitude_control\":$amplitudeControl," +
            "\"envelope\":$envelopeSupported," +
            "\"native\":true}")
    }

    /** Transient event. intensity/sharpness in 0..1, material shifts the mapping. */
    fun play(event: String, intensity: Float, material: String) {
        val inten = intensity.coerceIn(0f, 1f)
        handler.post { playOnThread(event, inten, material) }
    }

    fun beginContinuous(id: String) {
        handler.post {
            continuous[id] = Continuous(active = true)
            lastSegmentAt = 0L
        }
    }

    fun updateContinuous(id: String, intensity: Float, sharpness: Float) {
        handler.post {
            val c = continuous[id] ?: return@post
            c.intensity = intensity.coerceIn(0f, 1f)
            c.sharpness = sharpness.coerceIn(0f, 1f)
            pumpContinuous(c)
        }
    }

    fun endContinuous(id: String) {
        handler.post {
            continuous.remove(id)
            vibrator?.cancel()
        }
    }

    /** N-70: Settings test pulse — a plain oneshot (default amplitude at 100 %). */
    fun testPulse(durationMs: Long, level: Float) {
        val ms = durationMs.coerceIn(MIN_PULSE_MS, 400L)
        handler.post {
            val v = vibrator ?: return@post
            if (tier == Tier.NONE) return@post
            vibrateGame(v, if (!amplitudeControl || level >= 0.99f) onOffPulse(ms, ms)
                else amplitudePulse(ms, (255 * level).toInt().coerceIn(60, 255)))
            transientUntilMs = SystemClock.uptimeMillis() + ms + 20L
        }
    }

    fun stopAll() {
        handler.post {
            continuous.clear()
            vibrator?.cancel()
        }
    }

    /** Re-arms a short resistance segment (50-60 ms), throttled to the segment length. */
    private fun pumpContinuous(c: Continuous) {
        if (!c.active) return
        val v = vibrator ?: return
        val now = SystemClock.uptimeMillis()
        if (now < transientUntilMs) return  // N-02: skip one segment instead of cutting the transient
        val segmentMs = 50L
        if (now - lastSegmentAt < segmentMs - 10) return
        lastSegmentAt = now
        val amp = (30 + 110 * c.intensity).toInt().coerceIn(1, 255)
        when (tier) {
            Tier.ENVELOPE, Tier.BUILDER -> {
                if (Build.VERSION.SDK_INT >= 36 && envelopeSupported) {
                    runCatching {
                        // N-07: continuous resistance as a real PWLE envelope segment (20/40 ms control points)
                        val ci = c.intensity.coerceIn(0.1f, 1f)
                        val cs = c.sharpness.coerceIn(0f, 1f)
                        val seg = VibrationEffect.BasicEnvelopeBuilder()
                            .setInitialSharpness(cs)
                            .addControlPoint(ci, cs, 20L)
                            .addControlPoint(ci, cs, 20L)
                            .addControlPoint(0f, cs, 20L)
                            .build()
                        vibrateGame(v, seg)
                    }.onFailure { vibrateWaveform(v, segmentMs, amp) }
                } else vibrateWaveform(v, segmentMs, amp)
            }
            Tier.PRIMITIVES, Tier.AMPLITUDE -> vibrateWaveform(v, segmentMs, amp)
            else -> { /* A0/A-: no continuous resistance */ }
        }
    }

    private fun vibrateWaveform(v: Vibrator, ms: Long, amp: Int) {
        if (tier == Tier.NONE) return
        vibrateGame(v, if (amplitudeControl) amplitudePulse(ms, amp) else onOffPulse(ms))
    }

    /**
     * N-79 / D-80: the ONLY two places that build raw pulses. Every pulse lasts at least
     * MIN_PULSE_MS (D-65); amplitude-scaled pulses keep a perceptibility floor of MIN_AMP.
     * Never call createWaveform/createOneShot elsewhere (GUT test_haptics checks this file).
     */
    private fun amplitudePulse(ms: Long, amp: Int): VibrationEffect =
        VibrationEffect.createWaveform(longArrayOf(0, ms.coerceAtLeast(MIN_PULSE_MS)), intArrayOf(0, amp.coerceIn(MIN_AMP, 255)), -1)

    private fun onOffPulse(ms: Long, maxMs: Long = MAX_ON_OFF_MS): VibrationEffect =
        VibrationEffect.createOneShot(ms.coerceIn(MIN_PULSE_MS, maxMs), VibrationEffect.DEFAULT_AMPLITUDE)

    private fun playOnThread(event: String, intensity: Float, material: String) {
        val v = vibrator ?: return
        if (tier == Tier.NONE) return
        val scale = when (material) {
            "steel" -> 1.05f
            "iron" -> 1.10f
            "wood" -> 0.90f
            else -> 1.0f
        }
        val i = (intensity * scale).coerceIn(0f, 1f)
        val effect = buildEventEffect(event, i, v)
        if (effect != null) {
            vibrateGame(v, effect)
            // N-02: remember how long the transient occupies the actuator (each vibrate() cancels the previous)
            // VibrationEffect.getDuration() is not public API; use the pattern's nominal length
            transientUntilMs = SystemClock.uptimeMillis() + 60L + 20L
        }
    }

    /**
     * N-70: game haptics use the MEDIA usage (as the latency probe did: scale NONE) instead of
     * the implicit TOUCH usage, which Samsung scales by the system touch-feedback setting
     * (LOW 0.71 on the test phone) and mutes when touch vibration is off. The game has its own
     * on/off switch and intensity slider.
     */
    private fun vibrateGame(v: Vibrator, effect: VibrationEffect) {
        if (Build.VERSION.SDK_INT >= 33) {
            v.vibrate(effect, VibrationAttributes.createForUsage(VibrationAttributes.USAGE_MEDIA))
        } else {
            @Suppress("DEPRECATION")
            v.vibrate(effect, AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_GAME)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build())
        }
    }

    private fun buildEventEffect(event: String, i: Float, v: Vibrator): VibrationEffect? {
        return when (tier) {
            Tier.PRIMITIVES, Tier.ENVELOPE, Tier.BUILDER -> compositionFor(event, i, v)
            Tier.AMPLITUDE -> waveformFor(event, i)
            Tier.ON_OFF -> oneShotFor(event, i)  // null: no pulse for this event on an on/off motor
            Tier.NONE -> null
        }
    }

    /**
     * A2+: composition built ONLY from individually-supported primitives — one
     * unsupported primitive voids the whole composition, so each candidate is
     * checked via arePrimitivesSupported and unsupported ones are replaced/skipped.
     */
    private fun compositionFor(event: String, i: Float, v: Vibrator): VibrationEffect? {
        fun supported(id: Int): Boolean =
            Build.VERSION.SDK_INT < 31 ||
                runCatching { v.arePrimitivesSupported(id).firstOrNull() == true }.getOrDefault(false)

        fun comp(vararg steps: Pair<Int, Float>): VibrationEffect? {
            val c = VibrationEffect.startComposition()
            var delay = 0L
            for ((id, scale) in steps) {
                if (!supported(id)) return null
                c.addPrimitive(id, scale.coerceIn(0f, 1f), delay.toInt())
                delay += 30L
            }
            return runCatching { c.compose() }.getOrNull()
        }

        val click = VibrationEffect.Composition.PRIMITIVE_CLICK
        val tick = VibrationEffect.Composition.PRIMITIVE_TICK
        val lowTick = VibrationEffect.Composition.PRIMITIVE_LOW_TICK
        val thud = VibrationEffect.Composition.PRIMITIVE_THUD
        val quickRise = VibrationEffect.Composition.PRIMITIVE_QUICK_RISE
        val slowRise = VibrationEffect.Composition.PRIMITIVE_SLOW_RISE
        val quickFall = VibrationEffect.Composition.PRIMITIVE_QUICK_FALL

        val effect = when (event) {
            "set" -> comp(click to (0.9f * i).coerceAtLeast(0.05f))
            "false_set" -> comp(click to (0.85f * i).coerceAtLeast(0.05f))
                ?: comp(tick to (0.85f * i), tick to 0.2f)
            "break" -> comp(click to i, quickFall to 0.6f) ?: comp(click to i)
            "open" -> comp(slowRise to 0.3f, click to i) ?: comp(click to i)
            "detector_trip" -> comp(thud to 0.7f) ?: comp(click to 0.7f)
            "drop" -> comp(tick to (0.7f * i), tick to (0.55f * i), tick to (0.4f * i))
            "overset" -> comp(thud to (0.6f * i)) ?: comp(click to 0.4f)
            "bind" -> comp(lowTick to (0.5f * i)) ?: comp(tick to 0.4f)
            "counter_rotate" -> comp(lowTick to (0.35f * i)) ?: comp(tick to 0.3f)
            "contact" -> comp(tick to (0.35f * i).coerceAtLeast(0.05f))
            "near_shear" -> comp(quickRise to (0.2f * i).coerceAtLeast(0.05f))
            "stress" -> comp(tick to (0.3f * i).coerceAtLeast(0.05f))
            "gate_align" -> comp(click to (0.5f * i).coerceAtLeast(0.05f)) ?: comp(tick to 0.6f)
            else -> comp(tick to (0.3f * i).coerceAtLeast(0.05f))
        }
        return effect ?: waveformFor(event, i)
    }

    /**
     * Amplitude-scaled single pulse. N-79: without amplitude control the amplitude is ignored
     * (a 20 ms pulse "at 0.18" played as a 20 ms full-on blip nobody felt), so such a motor gets
     * the on/off policy instead: length is the only lever, only events with an a0_ms pulse.
     */
    private fun waveformFor(event: String, i: Float): VibrationEffect? {
        if (!amplitudeControl) return oneShotFor(event, i)
        val ms = when (event) {
            "set", "false_set" -> 18L
            "break" -> 40L
            "drop" -> 12L
            "detector_trip" -> 60L
            "open" -> 30L
            else -> 15L
        }
        if (i <= 0f) return null
        return amplitudePulse(ms, (255 * i).toInt())
    }

    /**
     * A0 on/off motor (cheap ERM, e.g. MOTOR_COIN_DC): only events with an a0_ms in
     * data/haptics_patterns.json pulse, never shorter than MIN_PULSE_MS (N-70: 1-19 ms pulses
     * were registered by the vibrator service but not felt). Intensity shortens the pulse a
     * little, like Haptics.fallback_pulse_ms() in GDScript; 0 = no pulse.
     */
    private fun oneShotFor(event: String, i: Float): VibrationEffect? {
        val a0 = when (event) {
            "set", "false_set", "overset" -> 30f
            "counter_rotate", "gate_align" -> 25f
            "open" -> 50f
            "drop", "break", "detector_trip" -> 60f
            else -> return null
        }
        if (i <= 0f) return null
        return onOffPulse((a0 * (0.75f + 0.25f * i.coerceIn(0f, 1f))).toLong())
    }

    companion object {
        private const val TAG = "LockwrightHaptics"
        /** D-65/D-80: no pulse shorter than this on any motor (== Haptics.ERM_MIN_MS in GDScript). */
        private const val MIN_PULSE_MS = 30L
        /** == Haptics.ERM_MAX_MS. */
        private const val MAX_ON_OFF_MS = 120L
        /** D-80: amplitude floor (~25 %) for amplitude-scaled pulses; quieter ones are not felt. */
        private const val MIN_AMP = 64
    }
}
