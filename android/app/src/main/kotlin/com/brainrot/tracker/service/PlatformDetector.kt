package com.brainrot.tracker.service

import android.os.Build
import android.view.accessibility.AccessibilityEvent
import kotlin.math.abs

/**
 * Zero-tree-traversal short-form video feed settle detector for Instagram Reels, YouTube Shorts, and TikTok.
 *
 * Strategies:
 * 1. ViewPager / RecyclerView page settle detection:
 *    - Settled when fromIndex == toIndex and toIndex >= 0
 *    - Deduplicates re-visits using seenIndices
 *    - Pull-to-refresh epoch tracking: increments epoch and resets seen set when:
 *      (toIndex == 0 && lastIndex > 0) || (itemCount < lastItemCount && toIndex < lastIndex) || (lastIndex > 2 && toIndex < lastIndex - 1)
 * 2. Fallback for feeds with toIndex == -1:
 *    - Directional accumulated vertical scroll delta (|sum(scrollDeltaY)| >= 400px) with 600ms gesture debounce
 *    - Cancels accumulation on direction reversal to eliminate bidirectional jitter false positives
 */
class PlatformDetector(val packageName: String) {

    private val seenIndices = HashSet<Int>()
    private var epoch = 0
    private var lastIndex = -1
    private var lastItemCount = -1

    private var accumulatedDeltaY = 0
    private var lastDeltaTime = 0L
    private val deltaDebounceWindowMs = 600L
    private val deltaThresholdPx = 400

    /**
     * Evaluates an AccessibilityEvent without tree traversal.
     * Safely extracts scrollDeltaY guarding against NoSuchMethodError on API < 28 (Android 8.0/8.1).
     */
    fun accept(event: AccessibilityEvent, nowMs: Long): Boolean {
        val deltaY = getSafeScrollDeltaY(event)
        return accept(
            fromIndex = event.fromIndex,
            toIndex = event.toIndex,
            itemCount = event.itemCount,
            scrollDeltaY = deltaY,
            nowMs = nowMs
        )
    }

    /**
     * Evaluates a scroll event without tree traversal.
     * Returns true if a new distinct short-form video was settled on.
     */
    fun accept(fromIndex: Int, toIndex: Int, itemCount: Int, scrollDeltaY: Int, nowMs: Long): Boolean {
        // Strategy 1: Page index settle detection
        if (toIndex >= 0 && itemCount >= 0) {
            // Ignore mid-swipe events where from != to
            if (fromIndex >= 0 && fromIndex != toIndex) {
                return false
            }

            // Pull-to-refresh / feed reload detection (supports equal/larger batch reloads)
            val isReload = (toIndex == 0 && lastIndex > 0) ||
                (itemCount < lastItemCount && toIndex < lastIndex) ||
                (lastIndex > 2 && toIndex < lastIndex - 1)

            if (isReload) {
                epoch++
                seenIndices.clear()
            }
            lastItemCount = itemCount
            lastIndex = toIndex

            val key = epoch * 100_000 + toIndex
            return seenIndices.add(key)
        }

        // Strategy 2: Directional accumulated scroll delta fallback (when pager indices are not provided)
        if (scrollDeltaY != 0) {
            val timedOut = (nowMs - lastDeltaTime > deltaDebounceWindowMs)
            val directionReversed = (accumulatedDeltaY > 0 && scrollDeltaY < 0) ||
                                    (accumulatedDeltaY < 0 && scrollDeltaY > 0)

            if (timedOut || directionReversed) {
                accumulatedDeltaY = 0
            }
            lastDeltaTime = nowMs
            accumulatedDeltaY += scrollDeltaY

            if (abs(accumulatedDeltaY) >= deltaThresholdPx) {
                accumulatedDeltaY = 0
                return true
            }
        }

        return false
    }

    /**
     * Resets detector state when clearing session or across date rollovers.
     */
    fun reset() {
        seenIndices.clear()
        epoch = 0
        lastIndex = -1
        lastItemCount = -1
        accumulatedDeltaY = 0
        lastDeltaTime = 0L
    }

    companion object {
        /**
         * Safely extracts scrollDeltaY from an AccessibilityRecord/Event.
         * Guarded with API 28 check to prevent NoSuchMethodError crash on Android 8.0/8.1 (minSdk 26).
         */
        fun getSafeScrollDeltaY(event: AccessibilityEvent): Int {
            return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                event.scrollDeltaY
            } else {
                0
            }
        }
    }
}
