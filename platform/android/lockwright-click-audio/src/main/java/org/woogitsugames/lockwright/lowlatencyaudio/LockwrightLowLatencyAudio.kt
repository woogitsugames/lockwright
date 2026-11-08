package org.woogitsugames.lockwright.lowlatencyaudio

import android.media.AudioManager
import android.content.Context
import org.godotengine.godot.Dictionary
import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.UsedByGodot

/**
 * Godot Android plugin v2 (spike 3, docs/TECH.md §1.6): low-latency clicks through Oboe/AAudio,
 * next to Godot's own OpenSL ES output. Singleton name: LockwrightLowLatencyAudio.
 *
 * GDScript:
 *   var a = Engine.get_singleton("LockwrightLowLatencyAudio")
 *   a.load_sample("set_brass", pcm_s16le_mono, 48000)
 *   a.play("set_brass", 1.0, 1.0)
 *   print(a.stats())
 *
 * Sample ids are strings for GDScript and small ints for the native mixer (no allocation on play).
 */
class LockwrightLowLatencyAudio(godot: Godot) : GodotPlugin(godot) {

    private val ids = HashMap<String, Int>()
    @Volatile private var started = false

    override fun getPluginName(): String = "LockwrightLowLatencyAudio"

    private fun ensureStarted(): Boolean {
        if (!started) started = NativeBridge.nativeStart()
        return started
    }

    @UsedByGodot
    fun load_sample(id: String, pcm_bytes: ByteArray, rate: Int): Boolean {
        ensureStarted()
        val slot = synchronized(ids) { ids.getOrPut(id) { ids.size } }
        return NativeBridge.nativeLoadSample(slot, pcm_bytes, rate)
    }

    @UsedByGodot
    fun play(id: String, gain: Float, pitch: Float): Boolean {
        val slot = ids[id] ?: return false
        return NativeBridge.nativePlay(slot, gain, pitch)
    }

    @UsedByGodot
    fun stats(): Dictionary {
        val d = Dictionary()
        val i = NativeBridge.nativeStatsInt()
        val r = NativeBridge.nativeStatsReal()
        val keys = arrayOf("sampleRate", "framesPerBurst", "bufferSize", "bufferCapacity", "channelCount",
            "performanceMode", "sharingMode", "audioApi", "xRunCount", "opens", "droppedTriggers",
            "voicesStolen", "plays", "samplesLoaded", "sampleBytes")
        for (k in keys.indices) d[keys[k]] = i[k]
        d["performanceModeName"] = when (i[5].toInt()) { 12 -> "LowLatency"; 11 -> "PowerSaving"; 10 -> "None"; else -> i[5].toString() }
        d["sharingModeName"] = if (i[6].toInt() == 0) "Exclusive" else "Shared"
        d["audioApiName"] = when (i[7].toInt()) { 2 -> "AAudio"; 1 -> "OpenSLES"; else -> "Unspecified" }
        d["estimatedLatencyMs"] = r[0]
        d["callToMixP50Ms"] = r[1]
        d["callToMixP95Ms"] = r[2]
        d["callbackP95Us"] = r[3]
        d["error"] = NativeBridge.nativeError()
        val am = activity?.getSystemService(Context.AUDIO_SERVICE) as? AudioManager
        d["deviceNativeRate"] = am?.getProperty(AudioManager.PROPERTY_OUTPUT_SAMPLE_RATE) ?: ""
        d["deviceNativeBurst"] = am?.getProperty(AudioManager.PROPERTY_OUTPUT_FRAMES_PER_BUFFER) ?: ""
        d["proAudio"] = activity?.packageManager?.hasSystemFeature("android.hardware.audio.pro") ?: false
        d["lowLatencyFeature"] = activity?.packageManager?.hasSystemFeature("android.hardware.audio.low_latency") ?: false
        return d
    }

    @UsedByGodot
    fun stop() {
        NativeBridge.nativeStop()
        started = false
    }

    override fun onMainPause() {
        // Release the exclusive stream in the background (other apps may need it).
        if (started) { NativeBridge.nativeStop(); started = false }
    }

    override fun onMainResume() {
        ensureStarted()
    }
}
