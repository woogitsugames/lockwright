package org.woogitsugames.lockwright.hapticsnative

import android.os.Build
import android.os.Bundle
import android.os.SystemClock
import android.util.Log
import android.view.MotionEvent
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Text
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.ExperimentalComposeUiApi
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.pointer.pointerInteropFilter
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import org.woogitsugames.lockwright.hapticsprobe.HapticCore
import java.util.Locale

/**
 * Native control app for spikes 1/2: the same HapticCore as the Godot plugin, without Godot.
 * Tap = transient; horizontal drag = continuous resistance (intensity = x / width).
 * Shows touch time (MotionEvent, uptime clock) -> vibrator call time, and logs every tap:
 *   adb logcat -s LWHapticsNative
 */
class MainActivity : ComponentActivity() {
    private lateinit var core: HapticCore
    private val pl = Locale.getDefault().language == "pl"

    @OptIn(ExperimentalComposeUiApi::class)
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        core = HapticCore(applicationContext)
        val caps = core.capabilities()
        Log.i(TAG, "caps $caps")
        setContent {
            var info by remember { mutableStateOf("") }
            var flash by remember { mutableStateOf(false) }
            val lat = remember { ArrayList<Double>() }
            Box(
                Modifier.fillMaxSize()
                    .background(if (flash) Color(0xFFEBE6DA) else Color(0xFF1A1816))
                    .pointerInteropFilter { e: MotionEvent ->
                        val w = window.decorView.width.coerceAtLeast(1)
                        when (e.actionMasked) {
                            MotionEvent.ACTION_DOWN -> {
                                // touch timestamp on the uptime clock (ns on API 34+), converted to elapsedRealtime
                                val touchUptimeNs = if (Build.VERSION.SDK_INT >= 34) e.eventTimeNanos else e.eventTime * 1_000_000L
                                val offset = SystemClock.elapsedRealtimeNanos() - SystemClock.uptimeNanos()
                                val t = core.transient(0.9f, 0.85f)
                                val touchToCallMs = (t[0] - (touchUptimeNs + offset)) / 1e6
                                lat.add(touchToCallMs)
                                Log.i(TAG, "tap touch_to_call_ms=%.3f call_us=%.1f".format(touchToCallMs, (t[1] - t[0]) / 1e3))
                                core.continuousStart()
                                core.continuousUpdate(e.x / w * 0.55f, 0.3f)
                                flash = true
                            }
                            MotionEvent.ACTION_MOVE -> core.continuousUpdate(e.x / w * 0.55f, 0.3f)
                            MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> { core.continuousStop(); flash = false }
                        }
                        val s = lat.sorted()
                        val p50 = if (s.isEmpty()) 0.0 else s[s.size / 2]
                        val p95 = if (s.isEmpty()) 0.0 else s[(s.size * 95 / 100).coerceAtMost(s.size - 1)]
                        info = (if (pl) "Natywna aplikacja kontrolna (narzędzie testowe, nie gra)\n" else "Native control app (test tool, not a game)\n") +
                            "tier ${caps["tier"]}, SDK ${caps["sdk"]}, ${caps["model"]}\n" +
                            "amplitude ${caps["hasAmplitudeControl"]}, envelopes ${caps["envelopes"]}\n" +
                            "primitives ${caps["primitives"]}\n" +
                            (if (pl) "dotknięcia" else "taps") + " ${lat.size}: touch -> vibrate() p50 %.2f / p95 %.2f ms\n".format(p50, p95) +
                            (if (pl) "przesuń w poziomie: opór ciągły" else "drag horizontally: continuous resistance")
                        true
                    }
            ) {
                Text(info, color = Color(0xFFF0EBE0), fontSize = 15.sp, modifier = Modifier.padding(16.dp))
            }
        }
    }

    override fun onPause() {
        super.onPause()
        core.continuousStop()
    }

    companion object { const val TAG = "LWHapticsNative" }
}
