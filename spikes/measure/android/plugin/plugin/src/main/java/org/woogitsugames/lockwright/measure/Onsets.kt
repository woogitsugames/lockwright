package org.woogitsugames.lockwright.measure

import kotlin.math.abs
import kotlin.math.max
import kotlin.math.sqrt

/** Onset detection for the accelerometer and microphone (spikes/measure/SPEC.md). Times: monotonic ns. */
object Onsets {
    /** High-passed |a|: |a| minus a ~50 ms moving mean (removes gravity and slow tilt). */
    fun accelHp(tt: LongArray, vv: FloatArray): FloatArray {
        if (tt.size < 4) return FloatArray(tt.size)
        val rate = (tt.size - 1) * 1e9 / (tt.last() - tt.first()).toDouble()
        val k = max(3, (rate * 0.05).toInt())
        val pre = DoubleArray(vv.size + 1)
        for (i in vv.indices) pre[i + 1] = pre[i] + vv[i]
        return FloatArray(vv.size) {
            val a = max(0, it - k / 2); val b = minOf(vv.size, it + k / 2 + 1)
            abs(vv[it] - ((pre[b] - pre[a]) / (b - a)).toFloat())
        }
    }

    private fun median(x: List<Float>): Float = if (x.isEmpty()) 0f else x.sorted()[x.size / 2]

    private fun idxAt(tt: LongArray, ns: Long): Int {
        var lo = 0; var hi = tt.size
        while (lo < hi) { val m = (lo + hi) / 2; if (tt[m] < ns) lo = m + 1 else hi = m }
        return lo
    }

    /** First accelerometer onset in [from, to]; noise from [nFrom, nTo]. Returns ns or -1. */
    fun accelOnset(tt: LongArray, hp: FloatArray, from: Long, to: Long, nFrom: Long, nTo: Long,
                   minFactorOverStart: Float = 0f): Long {
        val n0 = idxAt(tt, nFrom); val n1 = idxAt(tt, nTo)
        val noise = median((n0 until minOf(n1, hp.size)).map { hp[it] })
        var thr = max(noise * 6f, 0.02f)
        val i0 = idxAt(tt, from); val i1 = idxAt(tt, to)
        if (i0 >= hp.size) return -1
        if (minFactorOverStart > 0f) {
            // the tap may still ring at `from`: require a clear rise above the level at `from`
            val lvl = (max(0, i0 - 2)..minOf(hp.size - 1, i0 + 1)).maxOf { hp[it] }
            thr = max(thr, lvl * minFactorOverStart)
        }
        for (i in i0 until minOf(i1, hp.size)) if (hp[i] > thr) return tt[i]
        return -1
    }

    /** Continuous resistance: longest gap (ms) where the 10 ms RMS of hp drops below the active threshold. */
    fun longestGapMs(tt: LongArray, hp: FloatArray, from: Long, to: Long, nFrom: Long, nTo: Long): Double {
        val n0 = idxAt(tt, nFrom); val n1 = idxAt(tt, nTo)
        val noise = median((n0 until minOf(n1, hp.size)).map { hp[it] })
        val thr = max(noise * 4f, 0.02f)
        val i0 = idxAt(tt, from); val i1 = minOf(idxAt(tt, to), hp.size)
        if (i1 - i0 < 10) return -1.0
        val rate = (i1 - i0 - 1) * 1e9 / (tt[i1 - 1] - tt[i0]).toDouble()
        val w = max(2, (rate * 0.01).toInt())
        var gapStart = -1L; var longest = 0.0
        for (i in i0 until i1) {
            var s = 0.0; var c = 0
            for (j in max(i0, i - w + 1)..i) { s += hp[j].toDouble() * hp[j]; c++ }
            val active = sqrt(s / c) > thr
            if (!active && gapStart < 0) gapStart = tt[i]
            if (active && gapStart >= 0) { longest = max(longest, (tt[i] - gapStart) / 1e6); gapStart = -1 }
        }
        if (gapStart >= 0) longest = max(longest, (tt[i1 - 1] - gapStart) / 1e6)
        return longest
    }

    /** Microphone envelope: moving mean of |x| over 0.5 ms. */
    fun micEnv(x: FloatArray, rate: Int): FloatArray {
        val k = max(1, rate / 2000)
        val out = FloatArray(x.size); var s = 0.0
        for (i in x.indices) {
            s += abs(x[i]); if (i >= k) s -= abs(x[i - k])
            out[i] = (s / minOf(i + 1, k)).toFloat()
        }
        return out
    }

    /** First mic onset (frame offset within env) in [a, b); noise from [na, nb). -1 if none. */
    fun micOnset(env: FloatArray, a: Int, b: Int, na: Int, nb: Int, minFactorOverStart: Float = 0f): Int {
        val noise = median((max(0, na) until minOf(nb, env.size)).map { env[it] })
        var thr = max(noise * 8f, 0.01f)
        if (a !in env.indices) return -1
        if (minFactorOverStart > 0f) thr = max(thr, env[a] * minFactorOverStart)
        for (i in a until minOf(b, env.size)) if (env[i] > thr) return i
        return -1
    }

    fun stats(xs: List<Double>): Map<String, Any> {
        val s = xs.sorted()
        fun p(q: Double) = if (s.isEmpty()) -1.0 else s[minOf(s.size - 1, (q * (s.size - 1) + 0.5).toInt())]
        return mapOf("n" to s.size, "p50_ms" to r1(p(0.5)), "p95_ms" to r1(p(0.95)),
            "samples_ms" to xs.map { r1(it) })
    }

    fun r1(v: Double) = Math.round(v * 10.0) / 10.0
}
