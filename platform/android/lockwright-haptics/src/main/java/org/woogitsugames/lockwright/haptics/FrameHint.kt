package org.woogitsugames.lockwright.haptics

import android.content.Context
import android.os.Build
import android.os.PerformanceHintManager
import android.os.Process
import android.util.Log

/**
 * D-88: Android Dynamic Performance Framework (ADPF) hint session for the game thread.
 *
 * Without touch the governor keeps the CPU low and a lock-screen frame (~13 ms of CPU on a
 * Helio G99 little core) misses vsync: 41-44 FPS on SM-A165F, 60 FPS under the thumb (touch
 * boost). The game reports each frame's work time against a 16.7 ms target and the system
 * raises the clock just enough. start() must be called on the game (Vulkan) thread: the
 * session is bound to the calling thread id. API 31+ only; older systems return false.
 */
class FrameHint(private val context: Context) {

    private var session: Any? = null   // PerformanceHintManager.Session (API 31+)

    fun start(targetNs: Long): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return false
        if (session != null) return true
        return try {
            val mgr = context.getSystemService(PerformanceHintManager::class.java) ?: return false
            if (mgr.preferredUpdateRateNanos < 0) return false
            session = mgr.createHintSession(intArrayOf(Process.myTid()), targetNs)
            session != null
        } catch (e: Exception) {
            Log.w(TAG, "ADPF hint session unavailable: ${e.message}")
            false
        }
    }

    fun report(actualNs: Long) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return
        val s = session as? PerformanceHintManager.Session ?: return
        try {
            s.reportActualWorkDuration(actualNs.coerceAtLeast(1L))
        } catch (e: Exception) {
            Log.w(TAG, "ADPF report failed: ${e.message}")
            stop()
        }
    }

    fun stop() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return
        (session as? PerformanceHintManager.Session)?.close()
        session = null
    }

    companion object {
        private const val TAG = "LockwrightFrameHint"
    }
}
