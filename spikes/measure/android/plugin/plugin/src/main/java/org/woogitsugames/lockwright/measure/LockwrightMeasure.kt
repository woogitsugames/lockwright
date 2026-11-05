package org.woogitsugames.lockwright.measure

import android.app.ActivityManager
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import org.godotengine.godot.Dictionary
import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.UsedByGodot
import org.json.JSONArray
import org.json.JSONObject
import org.woogitsugames.lockwright.hapticsprobe.HapticCore
import kotlin.math.PI
import kotlin.math.abs
import kotlin.math.exp
import kotlin.math.sin

internal object ClickNative {
    init { System.loadLibrary("lwaudio") }
    @JvmStatic external fun nativeStart(): Boolean
    @JvmStatic external fun nativeStop()
    @JvmStatic external fun nativeLoadSample(id: Int, pcm: ByteArray, rate: Int): Boolean
    @JvmStatic external fun nativePlay(id: Int, gain: Float, pitch: Float): Boolean
    @JvmStatic external fun nativeStatsInt(): LongArray
    @JvmStatic external fun nativeStatsReal(): DoubleArray
    @JvmStatic external fun nativeError(): String
}

/**
 * Owner-run latency measurement (D-33, spikes/measure/SPEC.md). Singleton: LockwrightMeasure.
 * Long steps run on a worker thread; GDScript polls status() and reads result_json() at the end.
 */
class LockwrightMeasure(godot: Godot) : GodotPlugin(godot) {
    private val ctx: Context get() = activity!!.applicationContext
    private val haptic by lazy { HapticCore(ctx) }
    private val accel by lazy { AccelRecorder(ctx) }
    private val mic = MicRecorder()
    private val metrics = JSONObject()
    private val notes = JSONArray()
    private val marks = HashMap<String, MutableList<Long>>()
    @Volatile private var status = "idle"
    @Volatile private var progress = 0.0
    private var audioReady = false

    override fun getPluginName() = "LockwrightMeasure"

    // ------------------------------------------------------------------ helpers
    private fun mark(kind: String): Long {
        val t = System.nanoTime()
        synchronized(marks) { marks.getOrPut(kind) { mutableListOf() }.add(t) }
        return t
    }

    private fun marksOf(kind: String) = synchronized(marks) { marks[kind]?.toList() ?: emptyList() }

    private fun runAsync(name: String, body: () -> Unit) {
        status = "running:$name"; progress = 0.0
        Thread {
            try { body(); status = "done:$name" } catch (e: Throwable) { status = "error:$name:${e.message}" }
        }.start()
    }

    /** 1 ms windowed 3 kHz burst with a 4 ms decay, 48 kHz mono PCM16: sharp onset for the mic. */
    private fun clickPcm(): ByteArray {
        val n = 48 * 8
        val out = ByteArray(n * 2)
        for (i in 0 until n) {
            val t = i / 48000.0
            val env = if (t < 0.001) sin(PI * t / 0.002) else exp(-(t - 0.001) / 0.0015)
            val v = (sin(2 * PI * 3000 * t) * env * 0.9 * 32767).toInt().coerceIn(-32768, 32767)
            out[2 * i] = (v and 0xff).toByte(); out[2 * i + 1] = (v shr 8).toByte()
        }
        return out
    }

    private fun ensureAudio(): Boolean {
        if (!audioReady) audioReady = ClickNative.nativeStart() && ClickNative.nativeLoadSample(0, clickPcm(), 48000)
        return audioReady
    }

    @UsedByGodot fun click_pcm(): ByteArray = clickPcm()

    @UsedByGodot fun status(): String = status
    @UsedByGodot fun progress(): Double = progress

    // ------------------------------------------------------------------ device
    @UsedByGodot
    fun device_info(): String {
        val d = JSONObject()
        d.put("platform", "android")
        d.put("manufacturer", Build.MANUFACTURER); d.put("model", Build.MODEL)
        d.put("os", Build.VERSION.RELEASE); d.put("sdk", Build.VERSION.SDK_INT)
        d.put("class", guessClass())
        d.put("haptic_tier", haptic.tier.name.replace("A_NONE", "none"))
        d.put("haptic_caps", JSONObject(haptic.capabilities()))
        val am = ctx.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val a = JSONObject()
        if (ensureAudio()) {
            val s = ClickNative.nativeStatsInt(); val r = ClickNative.nativeStatsReal()
            a.put("sample_rate", s[0]); a.put("frames_per_burst", s[1]); a.put("buffer_frames", s[2])
            a.put("sharing", if (s[6] == 0L) "Exclusive" else "Shared")
            a.put("api", when (s[7].toInt()) { 2 -> "AAudio"; 1 -> "OpenSLES"; else -> "?" })
            a.put("estimated_output_latency_ms", Onsets.r1(r[0]))
        }
        a.put("device_native_rate", am.getProperty(AudioManager.PROPERTY_OUTPUT_SAMPLE_RATE) ?: "")
        a.put("low_latency_feature", ctx.packageManager.hasSystemFeature("android.hardware.audio.low_latency"))
        a.put("pro_audio_feature", ctx.packageManager.hasSystemFeature("android.hardware.audio.pro"))
        d.put("audio", a)
        return d.toString()
    }

    private fun guessClass(): String {
        val man = Build.MANUFACTURER.lowercase(); val model = Build.MODEL.uppercase()
        if (man == "google") return "pixel"
        if (man == "samsung") return if (model.startsWith("SM-A") || model.startsWith("SM-M")) "samsung_a" else "pixel"
        val mi = ActivityManager.MemoryInfo()
        (ctx.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager).getMemoryInfo(mi)
        return if (mi.totalMem >= 6L * 1024 * 1024 * 1024) "samsung_a" else "budget"
    }

    // ------------------------------------------------------------------ step 2: haptic API -> vibration (no touch)
    @UsedByGodot
    fun run_haptic_auto(trials: Int) = runAsync("haptic") {
        accel.start(); Thread.sleep(700)
        val ms = mutableListOf<Long>()
        for (k in 0 until trials) {
            ms.add(System.nanoTime()); haptic.transient(0.9f, 0.85f)
            Thread.sleep(400); progress = (k + 1.0) / trials
        }
        Thread.sleep(200)
        val (tt, vv) = accel.snapshot(); accel.stop()
        val hp = Onsets.accelHp(tt, vv)
        val lat = ms.mapNotNull { m ->
            val o = Onsets.accelOnset(tt, hp, m, m + 250_000_000, m - 300_000_000, m - 20_000_000)
            if (o > 0) (o - m) / 1e6 else null
        }
        val rate = if (tt.size > 1) (tt.size - 1) * 1e9 / (tt.last() - tt.first()) else 0.0
        metrics.put("haptic_call", JSONObject(Onsets.stats(lat) + mapOf("rejected" to (ms.size - lat.size))))
        metrics.put("accel_hz", Onsets.r1(rate))
        if (rate < 200) notes.put("Akcelerometr ${rate.toInt()} Hz: dokładność około ±${(1000 / rate).toInt()} ms.")
    }

    // ------------------------------------------------------------------ step 3: continuous resistance
    @UsedByGodot
    fun run_continuous(seconds: Double) = runAsync("continuous") {
        accel.start(); Thread.sleep(700)
        val t0 = System.nanoTime()
        haptic.continuousStart(); haptic.continuousUpdate(0.5f, 0.3f)
        val end = t0 + (seconds * 1e9).toLong()
        while (System.nanoTime() < end) { Thread.sleep(50); progress = (System.nanoTime() - t0) / (seconds * 1e9) }
        haptic.continuousStop()
        val t1 = System.nanoTime()
        Thread.sleep(150)
        val (tt, vv) = accel.snapshot(); accel.stop()
        val hp = Onsets.accelHp(tt, vv)
        val gap = Onsets.longestGapMs(tt, hp, t0 + 300_000_000, t1 - 100_000_000, t0 - 600_000_000, t0 - 50_000_000)
        metrics.put("continuous_max_gap_ms", Onsets.r1(gap))
        metrics.put("continuous_tier", haptic.tier.name)
        if (haptic.tier == HapticCore.Tier.A0 || haptic.tier == HapticCore.Tier.A_NONE)
            notes.put("Ten telefon nie ma ciągłego oporu (tier ${haptic.tier.name}) — zgodnie z TECH §2.2.")
    }

    // ------------------------------------------------------------------ step 4: audio call -> mic onset
    @UsedByGodot fun mic_start(): Boolean = mic.start().also { if (it) notes.put("Mikrofon: źródło ${mic.source}.") }
    @UsedByGodot fun mic_stop() = mic.stop()

    /** Marks the moment GDScript asks Godot's AudioStreamPlayer to play (engine path). */
    @UsedByGodot fun mark_engine(): Long { return mark("engine") }

    @UsedByGodot
    fun run_audio_fast(trials: Int) = runAsync("audio_fast") {
        if (!ensureAudio()) throw IllegalStateException("Oboe: ${ClickNative.nativeError()}")
        for (k in 0 until trials) {
            mark("fast"); ClickNative.nativePlay(0, 1f, 1f)
            Thread.sleep(300); progress = (k + 1.0) / trials
        }
    }

    /** Analyses the marks of kind "fast" or "engine" against the mic recording; stores audio_call_<kind>. */
    @UsedByGodot
    fun analyze_audio(kind: String): String {
        val lat = audioLatencies(marksOf(kind), 0)
        metrics.put("audio_call_$kind", JSONObject(Onsets.stats(lat) + mapOf("rejected" to (marksOf(kind).size - lat.size))))
        return metrics.optJSONObject("audio_call_$kind")?.toString() ?: "{}"
    }

    private fun audioLatencies(ms: List<Long>, preMs: Int): List<Double> {
        if (!mic.hasAnchor()) return emptyList()
        val out = mutableListOf<Double>()
        for (m in ms) {
            val f0 = mic.frameAt(m - 250_000_000); val fm = mic.frameAt(m); val f1 = mic.frameAt(m + 280_000_000)
            val x = mic.slice(f0, f1); if (x.isEmpty()) continue
            val env = Onsets.micEnv(x, mic.rate)
            val a = (fm - f0).toInt()
            val o = Onsets.micOnset(env, a, env.size, a - 12000, a - 480)
            if (o >= 0) out.add(((o - a) * 1000.0) / mic.rate)
        }
        return out
    }

    // ------------------------------------------------------------------ step 5: taps
    @UsedByGodot
    fun taps_begin(): Boolean {
        synchronized(marks) { marks.remove("tap") }
        accel.start()
        return ensureAudio()
    }

    /** Called from the touch handler: vibration + fast click at once. */
    @UsedByGodot
    fun tap() {
        mark("tap"); haptic.transient(0.9f, 0.85f); ClickNative.nativePlay(0, 1f, 1f)
    }

    @UsedByGodot
    fun taps_end(): String = run {
        Thread.sleep(300)
        val (tt, vv) = accel.snapshot(); accel.stop()
        val hp = Onsets.accelHp(tt, vv)
        val hapticTap = mutableListOf<Double>(); val audioTap = mutableListOf<Double>(); val sync = mutableListOf<Double>()
        for (m in marksOf("tap")) {
            // physical tap happened before the app saw the event: look back up to 200 ms
            val tap = Onsets.accelOnset(tt, hp, m - 200_000_000, m, m - 700_000_000, m - 350_000_000)
            val vib = Onsets.accelOnset(tt, hp, m + 1_000_000, m + 250_000_000, m - 700_000_000, m - 350_000_000, 2f)
            if (tap > 0 && vib > 0) hapticTap.add((vib - tap) / 1e6)
            if (mic.hasAnchor()) {
                val f0 = mic.frameAt(m - 700_000_000); val fm = mic.frameAt(m); val f1 = mic.frameAt(m + 280_000_000)
                val x = mic.slice(f0, f1)
                if (x.isNotEmpty()) {
                    val env = Onsets.micEnv(x, mic.rate); val a = (fm - f0).toInt()
                    val knock = Onsets.micOnset(env, a - 9600, a, 0, a - 16800)
                    val click = Onsets.micOnset(env, a + 48, env.size, 0, a - 16800, 2f)
                    if (knock >= 0 && click >= 0) {
                        audioTap.add((click - knock) * 1000.0 / mic.rate)
                        if (vib > 0) sync.add(abs(mic.frameTime(f0 + click) - vib) / 1e6)
                    }
                }
            }
        }
        val n = marksOf("tap").size
        metrics.put("haptic_tap", JSONObject(Onsets.stats(hapticTap) + mapOf("rejected" to (n - hapticTap.size))))
        metrics.put("audio_tap", JSONObject(Onsets.stats(audioTap) + mapOf("rejected" to (n - audioTap.size))))
        metrics.put("audio_haptic_sync", JSONObject(Onsets.stats(sync) + mapOf("rejected" to (n - sync.size))))
        metrics.toString()
    }

    // ------------------------------------------------------------------ results
    @UsedByGodot fun result_json(): String = JSONObject().put("metrics", metrics).put("notes", notes).toString()

    @UsedByGodot fun reset() { metrics.keys().asSequence().toList().forEach { metrics.remove(it) }; while (notes.length() > 0) notes.remove(0); synchronized(marks) { marks.clear() } }

    /** Saves to Downloads (visible in the Files app) and returns a user-readable location. */
    @UsedByGodot
    fun save_download(name: String, text: String): String = try {
        val v = ContentValues().apply {
            put(MediaStore.Downloads.DISPLAY_NAME, name); put(MediaStore.Downloads.MIME_TYPE, "application/json")
            put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS + "/Lockwright")
        }
        val uri = ctx.contentResolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, v)!!
        ctx.contentResolver.openOutputStream(uri)!!.use { it.write(text.toByteArray()) }
        "Pobrane/Lockwright/$name"
    } catch (e: Exception) { "" }

    /** System share sheet with the JSON as text (e-mail, Messenger, Drive, notes...). */
    @UsedByGodot
    fun share_text(subject: String, text: String) {
        val a = activity ?: return
        a.runOnUiThread {
            val i = Intent(Intent.ACTION_SEND).apply {
                type = "text/plain"; putExtra(Intent.EXTRA_SUBJECT, subject); putExtra(Intent.EXTRA_TEXT, text)
            }
            a.startActivity(Intent.createChooser(i, subject))
        }
    }

    override fun onMainPause() { haptic.continuousStop() }
}
