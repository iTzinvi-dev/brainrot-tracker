package com.brainrot.tracker.service

import android.accessibilityservice.AccessibilityService
import android.content.Context
import android.os.Build
import android.os.SystemClock
import android.view.accessibility.AccessibilityEvent
import com.brainrot.tracker.bridge.AccessibilityBridge
import com.brainrot.tracker.model.BrainRot
import com.brainrot.tracker.model.OperationalMode
import com.brainrot.tracker.overlay.OverlayController
import com.brainrot.tracker.receiver.ScreenReceiver
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Native Android Accessibility Service tracking doomscrolling across
 * Instagram Reels, YouTube Shorts, and TikTok with zero-tree-traversal.
 *
 * Listens purely to ViewPager scroll / page-settle events without text scraping.
 */
class BrainrotAccessibilityService : AccessibilityService() {

    private val detectors = mapOf(
        "com.instagram.android" to PlatformDetector("com.instagram.android"),
        "com.google.android.youtube" to PlatformDetector("com.google.android.youtube"),
        "com.zhiliaoapp.musically" to PlatformDetector("com.zhiliaoapp.musically"),
        "com.ss.android.ugc.trill" to PlatformDetector("com.ss.android.ugc.trill")
    )

    private lateinit var overlayController: OverlayController
    private lateinit var screenReceiver: ScreenReceiver

    private var lastEventProcessedTime = 0L

    // Sliding window velocity limiter: 40 swipes per min threshold
    private val velocityWindowMs = 60_000L
    private val velocityTimestamps = ArrayDeque<Long>()
    private val velocityThreshold = 40

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        isRunning = true

        overlayController = OverlayController(this)
        screenReceiver = ScreenReceiver(
            onScreenOff = { onScreenSleep() },
            onScreenOn = { onScreenWake() }
        )
        screenReceiver.register(this)

        loadPersistentState()
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        val packageName = event.packageName?.toString() ?: return

        when (event.eventType) {
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> {
                currentForegroundPackage = packageName
                if (isTargetPackage(packageName)) {
                    if (!isBankingMode && !isScreenSleeping) {
                        overlayController.show()
                        overlayController.updateCount(todayReelCount)
                    }
                } else {
                    overlayController.hide()
                }
            }

            AccessibilityEvent.TYPE_VIEW_SCROLLED, AccessibilityEvent.TYPE_VIEW_SELECTED -> {
                if (!isTargetPackage(packageName) || isBankingMode || isScreenSleeping) return

                val now = SystemClock.elapsedRealtime()
                if (now - lastEventProcessedTime < currentMode.debounceMs) return

                val detector = detectors[packageName] ?: return
                val deltaY = PlatformDetector.getSafeScrollDeltaY(event)
                val confirmed = detector.accept(
                    fromIndex = event.fromIndex,
                    toIndex = event.toIndex,
                    itemCount = event.itemCount,
                    scrollDeltaY = deltaY,
                    nowMs = now
                )

                if (confirmed) {
                    lastEventProcessedTime = now
                    onReelConfirmed(packageName, now)
                }
            }
        }
    }

    private fun onReelConfirmed(packageName: String, nowMs: Long) {
        checkDateRollover()
        todayReelCount++
        val platformKey = mapPackageToPlatform(packageName)
        val platformCount = (platformStatsMap[platformKey] ?: 0) + 1
        platformStatsMap[platformKey] = platformCount

        persistState()
        overlayController.updateCount(todayReelCount)

        val stage = BrainRot.stage(todayReelCount)
        AccessibilityBridge.sendReelConfirmed(
            platform = platformKey,
            count = todayReelCount,
            stage = stage,
            timestamp = System.currentTimeMillis()
        )

        // Velocity Limiter Check
        velocityTimestamps.addLast(nowMs)
        while (velocityTimestamps.isNotEmpty() && nowMs - velocityTimestamps.first() > velocityWindowMs) {
            velocityTimestamps.removeFirst()
        }

        if (velocityTimestamps.size >= velocityThreshold) {
            val rate = (velocityTimestamps.size * 60_000.0) / velocityWindowMs
            AccessibilityBridge.sendInterventionTriggered(
                reason = "velocity_spike",
                value = rate
            )
        }
    }

    private fun onScreenSleep() {
        isScreenSleeping = true
        overlayController.hide()
    }

    private fun onScreenWake() {
        isScreenSleeping = false
        if (isTargetPackage(currentForegroundPackage) && !isBankingMode) {
            overlayController.show()
            overlayController.updateCount(todayReelCount)
        }
    }

    private fun checkDateRollover() {
        Companion.checkDateRollover()
    }

    private fun isTargetPackage(pkg: String?): Boolean = detectors.containsKey(pkg)

    private fun mapPackageToPlatform(pkg: String): String = when (pkg) {
        "com.instagram.android" -> "instagram"
        "com.google.android.youtube" -> "youtube"
        "com.zhiliaoapp.musically", "com.ss.android.ugc.trill" -> "tiktok"
        else -> "other"
    }

    private fun loadPersistentState() {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        Companion.checkDateRollover()
        val today = currentDate
        todayReelCount = prefs.getInt("count_$today", 0)
        platformStatsMap["instagram"] = prefs.getInt("instagram_$today", 0)
        platformStatsMap["youtube"] = prefs.getInt("youtube_$today", 0)
        platformStatsMap["tiktok"] = prefs.getInt("tiktok_$today", 0)
        val savedMode = prefs.getString(KEY_MODE, OperationalMode.BALANCED.name)
        currentMode = OperationalMode.fromString(savedMode)
        isBankingMode = prefs.getBoolean(KEY_BANKING, false)
        overlayController.setOperationalMode(currentMode)
        overlayController.updateCount(todayReelCount)
    }

    private fun persistState() {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit()
            .putInt("count_$currentDate", todayReelCount)
            .putInt("instagram_$currentDate", platformStatsMap["instagram"] ?: 0)
            .putInt("youtube_$currentDate", platformStatsMap["youtube"] ?: 0)
            .putInt("tiktok_$currentDate", platformStatsMap["tiktok"] ?: 0)
            .putString(KEY_MODE, currentMode.name)
            .putBoolean(KEY_BANKING, isBankingMode)
            .apply()
    }

    private fun persistOperationalState() {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit()
            .putString(KEY_MODE, currentMode.name)
            .putBoolean(KEY_BANKING, isBankingMode)
            .apply()
    }

    override fun onInterrupt() {}

    override fun onDestroy() {
        isRunning = false
        instance = null
        if (::screenReceiver.isInitialized) screenReceiver.unregister(this)
        if (::overlayController.isInitialized) overlayController.hide()
        super.onDestroy()
    }

    companion object {
        private const val PREFS_NAME = "brainrot_prefs"
        private const val KEY_MODE = "operational_mode"
        private const val KEY_BANKING = "is_banking_mode"

        var instance: BrainrotAccessibilityService? = null
        var isRunning = false
        var isBankingMode = false
        var isScreenSleeping = false
        var todayReelCount = 0
        var currentDate = ""
        var currentForegroundPackage: String? = null
        var currentMode = OperationalMode.BALANCED
        private val platformStatsMap = mutableMapOf<String, Int>()

        fun checkDateRollover() {
            val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
            if (currentDate != today) {
                currentDate = today
                todayReelCount = 0
                platformStatsMap.clear()
                instance?.detectors?.values?.forEach { it.reset() }
                instance?.persistState()
                instance?.overlayController?.updateCount(0)
            }
        }

        fun getTodayCount(): Int {
            checkDateRollover()
            return todayReelCount
        }

        fun getPlatformStats(): Map<String, Int> {
            checkDateRollover()
            return HashMap(platformStatsMap)
        }

        fun setOperationalMode(mode: OperationalMode) {
            currentMode = mode
            instance?.overlayController?.setOperationalMode(mode)
            instance?.persistOperationalState()
        }

        fun setBanking(enabled: Boolean) {
            isBankingMode = enabled
            instance?.persistOperationalState()
            if (enabled) {
                instance?.overlayController?.hide()
            } else if (instance?.isTargetPackage(currentForegroundPackage) == true && !isScreenSleeping) {
                instance?.overlayController?.show()
            }
        }

        fun resetCount() {
            todayReelCount = 0
            platformStatsMap.clear()
            instance?.persistState()
            instance?.overlayController?.updateCount(0)
        }
    }
}
