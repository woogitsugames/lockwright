package org.woogitsugames.lockwright.haptics

import android.content.Context
import android.graphics.Rect
import android.os.Build
import android.os.Bundle
import android.view.MotionEvent
import android.view.View
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityManager
import android.view.accessibility.AccessibilityNodeInfo
import android.view.accessibility.AccessibilityNodeProvider
import org.json.JSONArray

/**
 * D-97 (N-93): TalkBack bridge. Godot 4.7.2 has no AccessKit adapter on Android (the export template
 * contains no AccessibilityServerAccessKit / accesskit_android), so TalkBack sees only the SurfaceView.
 *
 * This transparent view sits on top of Godot's render view (GodotPlugin.onMainCreate) and exposes the
 * controls the game publishes (UiA11y -> a11y_set_nodes JSON: id, name, role, bounds in surface
 * pixels, state) as virtual accessibility nodes. Touches are never consumed (dispatchTouchEvent =
 * false), so with TalkBack off the game gets every touch as before. With TalkBack on, explore-by-touch
 * hover events land on the virtual node under the finger; a double tap / activate arrives as
 * ACTION_CLICK and is sent back to the game (onActivate -> Godot signal a11y_activate). Sliders get
 * scroll actions (onAdjust). A node with role "area" is the lock's play area: TalkBack names it and
 * reads its hint; the thumbs then work with TalkBack's own pass-through gesture (double tap and hold,
 * then drag) - Android has no per-node touch passthrough for apps.
 */
class A11yBridge(context: Context) : View(context) {

    data class Node(
        val id: Int, val name: String, val role: String, val bounds: Rect,
        val desc: String, val checked: Int, val value: String, val disabled: Boolean,
    )

    var onActivate: ((Int) -> Unit)? = null
    var onAdjust: ((Int, Int) -> Unit)? = null

    @Volatile private var nodes: List<Node> = emptyList()
    private var hovered = HOST
    private var focused = HOST
    private val am = context.getSystemService(Context.ACCESSIBILITY_SERVICE) as AccessibilityManager
    private val provider = Provider()

    init {
        importantForAccessibility = IMPORTANT_FOR_ACCESSIBILITY_YES
        isFocusable = false
        isClickable = false
    }

    /** Any accessibility client is listening (TalkBack, Switch Access, UI Automator): publish nodes. */
    fun active(): Boolean = am.isEnabled

    /** A spoken screen reader runs (TalkBack / Samsung TalkBack: touch exploration or spoken feedback). */
    fun screenReader(): Boolean = am.isEnabled && (am.isTouchExplorationEnabled ||
        am.getEnabledAccessibilityServiceList(android.accessibilityservice.AccessibilityServiceInfo.FEEDBACK_SPOKEN).isNotEmpty())

    /** Called on the UI thread with the JSON array from UiA11y. */
    fun setNodes(json: String) {
        val out = ArrayList<Node>()
        try {
            val arr = JSONArray(json)
            for (i in 0 until arr.length()) {
                val o = arr.getJSONObject(i)
                val r = Rect(o.getInt("x"), o.getInt("y"), o.getInt("x") + o.getInt("w"), o.getInt("y") + o.getInt("h"))
                out.add(Node(o.getInt("id"), o.optString("name"), o.optString("role", "button"), r,
                    o.optString("desc"), o.optInt("checked", -1), o.optString("value"), o.optBoolean("disabled")))
            }
        } catch (e: Exception) {
            return
        }
        val changed = out != nodes
        if (changed) android.util.Log.i(TAG, "nodes: ${out.size}")
        nodes = out
        if (changed) {
            if (nodes.none { it.id == focused }) focused = HOST
            sendEventForHost(AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED)
        }
    }

    fun announce(text: String) {
        if (!am.isEnabled || text.isEmpty()) return
        android.util.Log.i(TAG, "announce: $text")
        val e = AccessibilityEvent(AccessibilityEvent.TYPE_ANNOUNCEMENT)
        e.text.add(text)
        e.packageName = context.packageName
        e.className = javaClass.name
        e.setSource(this)
        parent?.requestSendAccessibilityEvent(this, e)
    }

    // ---------------------------------------------------------------- input
    override fun dispatchTouchEvent(event: MotionEvent?): Boolean = false   // touches always go to Godot
    override fun onTouchEvent(event: MotionEvent?): Boolean = false

    override fun dispatchHoverEvent(event: MotionEvent): Boolean {
        if (!am.isTouchExplorationEnabled) return false
        val id = nodeAt(event.x.toInt(), event.y.toInt())
        when (event.actionMasked) {
            MotionEvent.ACTION_HOVER_ENTER, MotionEvent.ACTION_HOVER_MOVE -> {
                if (id != hovered) {
                    android.util.Log.i(TAG, "hover -> $id")
                    val old = hovered
                    hovered = id
                    if (id != HOST) sendEvent(id, AccessibilityEvent.TYPE_VIEW_HOVER_ENTER)
                    if (old != HOST) sendEvent(old, AccessibilityEvent.TYPE_VIEW_HOVER_EXIT)
                }
            }
            MotionEvent.ACTION_HOVER_EXIT -> {
                if (hovered != HOST) sendEvent(hovered, AccessibilityEvent.TYPE_VIEW_HOVER_EXIT)
                hovered = HOST
            }
        }
        return id != HOST
    }

    private fun nodeAt(x: Int, y: Int): Int {
        // last published = topmost; skip the play area so buttons on top of it stay reachable
        for (n in nodes.asReversed()) if (n.role != "area" && n.bounds.contains(x, y)) return n.id
        for (n in nodes.asReversed()) if (n.bounds.contains(x, y)) return n.id
        return HOST
    }

    // ---------------------------------------------------------------- events
    private fun sendEventForHost(type: Int) {
        if (!am.isEnabled) return
        val e = AccessibilityEvent(type)
        e.setSource(this)
        e.packageName = context.packageName
        if (type == AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED) {
            e.contentChangeTypes = AccessibilityEvent.CONTENT_CHANGE_TYPE_SUBTREE
        }
        parent?.requestSendAccessibilityEvent(this, e)
    }

    private fun sendEvent(id: Int, type: Int) {
        if (!am.isEnabled) return
        val n = nodes.firstOrNull { it.id == id } ?: return
        val e = AccessibilityEvent(type)
        e.setSource(this, id)
        e.packageName = context.packageName
        e.className = className(n.role)
        e.text.add(n.name)
        e.contentDescription = n.name
        e.isEnabled = !n.disabled
        parent?.requestSendAccessibilityEvent(this, e)
    }

    override fun getAccessibilityNodeProvider(): AccessibilityNodeProvider = provider

    private fun className(role: String): String = when (role) {
        "check" -> "android.widget.Switch"
        "slider" -> "android.widget.SeekBar"
        "option" -> "android.widget.Spinner"
        "text" -> "android.widget.TextView"
        "area" -> "android.view.View"
        else -> "android.widget.Button"
    }

    private inner class Provider : AccessibilityNodeProvider() {
        override fun createAccessibilityNodeInfo(virtualViewId: Int): AccessibilityNodeInfo? {
            if (virtualViewId == HOST_ID) {
                val info = AccessibilityNodeInfo.obtain(this@A11yBridge)
                onInitializeAccessibilityNodeInfo(info)
                info.className = this@A11yBridge.javaClass.name
                for (n in nodes) info.addChild(this@A11yBridge, n.id)
                return info
            }
            val n = nodes.firstOrNull { it.id == virtualViewId } ?: return null
            val info = AccessibilityNodeInfo.obtain(this@A11yBridge, n.id)
            info.setParent(this@A11yBridge)
            info.packageName = context.packageName
            info.className = className(n.role)
            info.contentDescription = if (n.value.isNotEmpty()) "${n.name}, ${n.value}" else n.name
            if (n.role == "text") info.text = n.name
            if (n.desc.isNotEmpty() && Build.VERSION.SDK_INT >= 26) info.hintText = n.desc
            info.isEnabled = !n.disabled
            info.isVisibleToUser = true
            info.isFocusable = true
            info.isScreenReaderFocusable = true
            info.setBoundsInParent(n.bounds)
            val loc = IntArray(2)
            getLocationOnScreen(loc)
            val screen = Rect(n.bounds)
            screen.offset(loc[0], loc[1])
            info.setBoundsInScreen(screen)
            if (n.checked >= 0) {
                info.isCheckable = true
                info.isChecked = n.checked == 1
            }
            if (n.role != "text" && n.role != "area" && !n.disabled) {
                info.isClickable = true
                info.addAction(AccessibilityNodeInfo.AccessibilityAction.ACTION_CLICK)
            }
            if (n.role == "slider") {
                info.addAction(AccessibilityNodeInfo.AccessibilityAction.ACTION_SCROLL_FORWARD)
                info.addAction(AccessibilityNodeInfo.AccessibilityAction.ACTION_SCROLL_BACKWARD)
            }
            if (focused == n.id) {
                info.isAccessibilityFocused = true
                info.addAction(AccessibilityNodeInfo.AccessibilityAction.ACTION_CLEAR_ACCESSIBILITY_FOCUS)
            } else {
                info.addAction(AccessibilityNodeInfo.AccessibilityAction.ACTION_ACCESSIBILITY_FOCUS)
            }
            return info
        }

        override fun performAction(virtualViewId: Int, action: Int, arguments: Bundle?): Boolean {
            android.util.Log.i(TAG, "action $action on $virtualViewId")
            if (virtualViewId == HOST_ID) return performAccessibilityAction(action, arguments)
            val n = nodes.firstOrNull { it.id == virtualViewId } ?: return false
            return when (action) {
                AccessibilityNodeInfo.ACTION_ACCESSIBILITY_FOCUS -> {
                    focused = n.id
                    invalidate()
                    sendEvent(n.id, AccessibilityEvent.TYPE_VIEW_ACCESSIBILITY_FOCUSED)
                    true
                }
                AccessibilityNodeInfo.ACTION_CLEAR_ACCESSIBILITY_FOCUS -> {
                    if (focused == n.id) focused = HOST
                    sendEvent(n.id, AccessibilityEvent.TYPE_VIEW_ACCESSIBILITY_FOCUS_CLEARED)
                    true
                }
                AccessibilityNodeInfo.ACTION_CLICK -> {
                    if (n.disabled) return false
                    onActivate?.invoke(n.id)
                    sendEvent(n.id, AccessibilityEvent.TYPE_VIEW_CLICKED)
                    true
                }
                AccessibilityNodeInfo.ACTION_SCROLL_FORWARD -> { onAdjust?.invoke(n.id, 1); true }
                AccessibilityNodeInfo.ACTION_SCROLL_BACKWARD -> { onAdjust?.invoke(n.id, -1); true }
                else -> false
            }
        }
    }

    companion object {
        private const val TAG = "LockwrightA11y"
        private const val HOST = -1
        private const val HOST_ID = View.NO_ID  // AccessibilityNodeProvider.HOST_VIEW_ID
    }
}
