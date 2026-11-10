package com.brainrot.tracker.overlay

import android.accessibilityservice.AccessibilityService
import android.annotation.SuppressLint
import android.content.Context
import android.graphics.PixelFormat
import android.view.Gravity
import android.view.MotionEvent
import android.view.ViewConfiguration
import android.view.WindowManager
import com.brainrot.tracker.model.OperationalMode
import kotlin.math.abs
import kotlin.math.roundToInt

/**
 * Controller for the floating rotting brain overlay.
 * Uses WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY provided by the AccessibilityService
 * context. Requires NO SYSTEM_ALERT_WINDOW permission.
 *
 * Window flags: FLAG_NOT_FOCUSABLE or FLAG_NOT_TOUCH_MODAL or FLAG_LAYOUT_NO_LIMITS
 * Touch events outside the 92x104 dp brain frame pass directly to Instagram, YouTube, or TikTok.
 * Touches on the brain drag it with edge snapping (4dp margin) and persistent position storage.
 */
class OverlayController(
    private val service: AccessibilityService
) {
    private val windowManager = service.getSystemService(WindowManager::class.java)
    private val preferences = service.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    private var counterView: BrainCounterView? = null
    private var layoutParams: WindowManager.LayoutParams? = null
    private var isVisible = false
    private var currentMode = OperationalMode.BALANCED
    private var lastCount = 0
    private var dragTouchListener: DragTouchListener? = null

    /**
     * Displays the floating overlay over the short-form video feed.
     */
    fun show() {
        if (isVisible && counterView != null) return

        val view = BrainCounterView(service).apply {
            setOperationalMode(currentMode)
            setCount(lastCount)
        }

        val lp = WindowManager.LayoutParams(
            dp(BrainCounterView.W),
            dp(BrainCounterView.H),
            WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            val (savedX, savedY) = loadSavedPosition()
            x = savedX
            y = savedY
        }

        try {
            windowManager.addView(view, lp)
            counterView = view
            layoutParams = lp
            isVisible = true
            val listener = DragTouchListener(view, lp)
            dragTouchListener = listener
            view.setOnTouchListener(listener)
        } catch (_: RuntimeException) {
            // Window token invalid or service disconnecting
            counterView = null
            layoutParams = null
            dragTouchListener = null
            isVisible = false
        }
    }

    /**
     * Hides and detaches the floating overlay from the window manager.
     */
    fun hide() {
        dragTouchListener?.cancelSnap()
        counterView?.let { view ->
            runCatching { windowManager.removeView(view) }
        }
        counterView = null
        layoutParams = null
        dragTouchListener = null
        isVisible = false
    }

    /**
     * Updates the reel count displayed on the overlay badge and brain sprite.
     */
    fun updateCount(count: Int) {
        lastCount = count
        counterView?.setCount(count)
    }

    /**
     * Updates operational power mode on the active overlay.
     */
    fun setOperationalMode(mode: OperationalMode) {
        currentMode = mode
        counterView?.setOperationalMode(mode)
    }

    /**
     * Pauses overlay animations during display sleep.
     */
    fun pauseAnimations() {
        counterView?.pauseAnimations()
    }

    /**
     * Resumes overlay animations when display powers on.
     */
    fun resumeAnimations() {
        counterView?.resumeAnimations()
    }

    fun isShowing(): Boolean = isVisible

    // ------------------------------------------------------------------ Persistence & Geometry

    private fun loadSavedPosition(): Pair<Int, Int> {
        val (screenWidth, screenHeight) = getScreenDimensions()
        val widthDp = dp(BrainCounterView.W)
        val heightDp = dp(BrainCounterView.H)

        // Default position: top right below social app header
        val defaultX = screenWidth - widthDp - dp(8)
        val defaultY = dp(96)

        val x = preferences.getInt(KEY_X, defaultX)
        val y = preferences.getInt(KEY_Y, defaultY)

        val clampedX = x.coerceIn(0, (screenWidth - widthDp).coerceAtLeast(0))
        val clampedY = y.coerceIn(0, (screenHeight - heightDp).coerceAtLeast(0))
        return clampedX to clampedY
    }

    private fun persistPosition(x: Int, y: Int) {
        preferences.edit()
            .putInt(KEY_X, x)
            .putInt(KEY_Y, y)
            .apply()
    }

    private fun getScreenDimensions(): Pair<Int, Int> {
        val displayMetrics = service.resources.displayMetrics
        return displayMetrics.widthPixels to displayMetrics.heightPixels
    }

    private fun dp(value: Int): Int = (value * service.resources.displayMetrics.density).toInt()

    // ------------------------------------------------------------------ Touch & Edge Snapping

    private inner class DragTouchListener(
        private val view: BrainCounterView,
        private val lp: WindowManager.LayoutParams
    ) : android.view.View.OnTouchListener {

        private val touchSlop = ViewConfiguration.get(service).scaledTouchSlop
        private var initialRawX = 0f
        private var initialRawY = 0f
        private var initialWindowX = 0
        private var initialWindowY = 0
        private var isDragging = false
        private var snapAnimator: android.animation.ValueAnimator? = null

        fun cancelSnap() {
            snapAnimator?.cancel()
            snapAnimator = null
        }

        @SuppressLint("ClickableViewAccessibility")
        override fun onTouch(v: android.view.View, event: MotionEvent): Boolean {
            when (event.actionMasked) {
                MotionEvent.ACTION_DOWN -> {
                    cancelSnap()
                    initialRawX = event.rawX
                    initialRawY = event.rawY
                    initialWindowX = lp.x
                    initialWindowY = lp.y
                    isDragging = false
                    view.animate().scaleX(1.08f).scaleY(1.08f).setDuration(120).start()
                }

                MotionEvent.ACTION_MOVE -> {
                    val deltaX = event.rawX - initialRawX
                    val deltaY = event.rawY - initialRawY

                    if (!isDragging && (abs(deltaX) > touchSlop || abs(deltaY) > touchSlop)) {
                        isDragging = true
                    }

                    if (isDragging) {
                        val (screenWidth, screenHeight) = getScreenDimensions()
                        lp.x = (initialWindowX + deltaX.roundToInt()).coerceIn(0, screenWidth - lp.width)
                        lp.y = (initialWindowY + deltaY.roundToInt()).coerceIn(0, screenHeight - lp.height)
                        runCatching { windowManager.updateViewLayout(view, lp) }
                    }
                }

                MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                    view.animate().scaleX(1f).scaleY(1f).setDuration(160).start()
                    if (isDragging) {
                        snapToNearestHorizontalEdge()
                    } else if (event.actionMasked == MotionEvent.ACTION_UP) {
                        view.poke()
                    }
                    isDragging = false
                }
            }
            return true
        }

        /**
         * Snaps the overlay to the left or right screen margin (4dp) using ValueAnimator.
         */
        private fun snapToNearestHorizontalEdge() {
            val (screenWidth, _) = getScreenDimensions()
            val margin = dp(4)
            val centerPoint = lp.x + lp.width / 2
            val targetX = if (centerPoint < screenWidth / 2) {
                margin
            } else {
                screenWidth - lp.width - margin
            }

            val startX = lp.x
            cancelSnap()
            snapAnimator = android.animation.ValueAnimator.ofInt(startX, targetX).apply {
                duration = 220
                interpolator = android.view.animation.DecelerateInterpolator()
                addUpdateListener { animator ->
                    lp.x = animator.animatedValue as Int
                    runCatching { windowManager.updateViewLayout(view, lp) }
                }
                addListener(object : android.animation.AnimatorListenerAdapter() {
                    override fun onAnimationEnd(animation: android.animation.Animator) {
                        persistPosition(lp.x, lp.y)
                        snapAnimator = null
                    }
                })
                start()
            }
        }
    }

    companion object {
        private const val PREFS_NAME = "brainrot_overlay_prefs"
        private const val KEY_X = "overlay_x"
        private const val KEY_Y = "overlay_y"
    }
}
