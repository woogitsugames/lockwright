package org.woogitsugames.lockwright.measure

import android.annotation.SuppressLint
import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.AudioTimestamp
import android.media.MediaRecorder
import android.os.Handler
import android.os.HandlerThread
import android.os.SystemClock
import kotlin.math.sqrt

/** All times in this package are CLOCK_MONOTONIC nanoseconds (System.nanoTime()). */
object Clock {
    /** elapsedRealtimeNanos (CLOCK_BOOTTIME, sensor timestamps) -> CLOCK_MONOTONIC. Constant while awake. */
    fun bootToMono(): Long = SystemClock.elapsedRealtimeNanos() - System.nanoTime()
}

/** Accelerometer at the fastest rate; |a| with timestamps converted to the monotonic clock. */
class AccelRecorder(context: Context) : SensorEventListener {
    private val sm = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
    private val sensor: Sensor? = sm.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
    private val thread = HandlerThread("lw-accel").apply { start() }
    private val cap = 1 shl 16
    private val t = LongArray(cap)
    private val v = FloatArray(cap)
    @Volatile private var n = 0
    private var offset = 0L
    val available get() = sensor != null

    fun start() {
        n = 0
        offset = Clock.bootToMono()
        sensor?.let { sm.registerListener(this, it, SensorManager.SENSOR_DELAY_FASTEST, Handler(thread.looper)) }
    }

    fun stop() = sm.unregisterListener(this)

    override fun onSensorChanged(e: SensorEvent) {
        val i = n % cap
        t[i] = e.timestamp - offset
        v[i] = sqrt(e.values[0] * e.values[0] + e.values[1] * e.values[1] + e.values[2] * e.values[2])
        n++
    }

    override fun onAccuracyChanged(s: Sensor?, a: Int) {}

    /** Copy of the last samples (time ns, |a| m/s^2). */
    fun snapshot(): Pair<LongArray, FloatArray> {
        val count = minOf(n, cap)
        val start = n - count
        val tt = LongArray(count) { t[(start + it) % cap] }
        val vv = FloatArray(count) { v[(start + it) % cap] }
        return tt to vv
    }

    fun rateHz(): Double {
        val (tt, _) = snapshot()
        if (tt.size < 20) return 0.0
        return (tt.size - 1) * 1e9 / (tt.last() - tt.first()).toDouble()
    }
}

/** Microphone at 48 kHz mono; frame index -> monotonic time from AudioRecord.getTimestamp. */
class MicRecorder {
    val rate = 48000
    private var rec: AudioRecord? = null
    private var thread: Thread? = null
    @Volatile private var running = false
    private val cap = rate * 40
    private val buf = ShortArray(cap)
    @Volatile private var frames = 0L
    // anchor: (frame position, monotonic ns) from the latest timestamp
    @Volatile private var anchorFrame = -1L
    @Volatile private var anchorNs = 0L
    var source = "?"
        private set

    @SuppressLint("MissingPermission")
    fun start(): Boolean {
        val min = AudioRecord.getMinBufferSize(rate, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT)
        for (src in intArrayOf(MediaRecorder.AudioSource.UNPROCESSED, MediaRecorder.AudioSource.VOICE_RECOGNITION, MediaRecorder.AudioSource.MIC)) {
            try {
                val r = AudioRecord(src, rate, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT, maxOf(min, 4096) * 2)
                if (r.state == AudioRecord.STATE_INITIALIZED) {
                    rec = r
                    source = when (src) { MediaRecorder.AudioSource.UNPROCESSED -> "UNPROCESSED"; MediaRecorder.AudioSource.VOICE_RECOGNITION -> "VOICE_RECOGNITION"; else -> "MIC" }
                    break
                }
                r.release()
            } catch (e: Exception) { }
        }
        val r = rec ?: return false
        frames = 0; anchorFrame = -1
        running = true
        r.startRecording()
        thread = Thread {
            val chunk = ShortArray(240)
            val ts = AudioTimestamp()
            while (running) {
                val got = r.read(chunk, 0, chunk.size)
                if (got <= 0) continue
                for (k in 0 until got) buf[((frames + k) % cap).toInt()] = chunk[k]
                frames += got
                if (r.getTimestamp(ts, AudioTimestamp.TIMEBASE_MONOTONIC) == AudioRecord.SUCCESS) {
                    anchorFrame = ts.framePosition; anchorNs = ts.nanoTime
                }
            }
        }.apply { priority = Thread.MAX_PRIORITY; start() }
        return true
    }

    fun stop() {
        running = false
        thread?.join(500)
        rec?.stop(); rec?.release(); rec = null
    }

    /** Monotonic ns of captured frame index f (needs a timestamp anchor). */
    fun frameTime(f: Long): Long = anchorNs + (f - anchorFrame) * 1_000_000_000L / rate

    fun hasAnchor() = anchorFrame >= 0

    /** Samples (as Float -1..1) for frames [f0, f1). */
    fun slice(f0: Long, f1: Long): FloatArray {
        val a = maxOf(f0, frames - cap + 1, 0L)
        val b = minOf(f1, frames)
        if (b <= a) return FloatArray(0)
        return FloatArray((b - a).toInt()) { buf[((a + it) % cap).toInt()] / 32768f }
    }

    /** Frame index at monotonic time ns. */
    fun frameAt(ns: Long): Long = anchorFrame + (ns - anchorNs) * rate / 1_000_000_000L

    fun captured() = frames
}
