package com.brainrot.tracker.bridge

import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import com.brainrot.tracker.model.OperationalMode
import com.brainrot.tracker.service.BrainrotAccessibilityService
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Bidirectional bridge connecting Flutter Dart with the native Android Accessibility Service and Overlay.
 *
 * MethodChannel: com.brainrot.tracker/channel
 * EventChannel: com.brainrot.tracker/events
 */
object AccessibilityBridge : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    private const val METHOD_CHANNEL_NAME = "com.brainrot.tracker/channel"
    private const val EVENT_CHANNEL_NAME = "com.brainrot.tracker/events"

    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private var appContext: Context? = null

    /**
     * Initializes the MethodChannel and EventChannel handlers.
     */
    fun register(context: Context, messenger: BinaryMessenger) {
        appContext = context.applicationContext
        methodChannel = MethodChannel(messenger, METHOD_CHANNEL_NAME).apply {
            setMethodCallHandler(this@AccessibilityBridge)
        }
        eventChannel = EventChannel(messenger, EVENT_CHANNEL_NAME).apply {
            setStreamHandler(this@AccessibilityBridge)
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isAccessibilityServiceEnabled" -> {
                result.success(BrainrotAccessibilityService.isRunning)
            }

            "openAccessibilitySettings" -> {
                appContext?.let { ctx ->
                    val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    ctx.startActivity(intent)
                    result.success(true)
                } ?: result.error("NO_CONTEXT", "Application context unavailable", null)
            }

            "getTodayCount" -> {
                result.success(BrainrotAccessibilityService.getTodayCount())
            }

            "getPlatformStats" -> {
                result.success(BrainrotAccessibilityService.getPlatformStats())
            }

            "setOperationalMode" -> {
                val modeStr = call.argument<String>("mode")
                val mode = OperationalMode.fromString(modeStr)
                BrainrotAccessibilityService.setOperationalMode(mode)
                result.success(true)
            }

            "getOperationalMode" -> {
                result.success(BrainrotAccessibilityService.currentMode.name)
            }

            "setBankingMode" -> {
                val enabled = call.argument<Boolean>("enabled") ?: false
                BrainrotAccessibilityService.setBanking(enabled)
                result.success(true)
            }

            "isBankingMode" -> {
                result.success(BrainrotAccessibilityService.isBankingMode)
            }

            "resetTodayCount" -> {
                BrainrotAccessibilityService.resetCount()
                result.success(true)
            }

            "triggerIntervention" -> {
                val action = call.argument<String>("action")
                if (action == "HOME") {
                    BrainrotAccessibilityService.instance?.performGlobalAction(
                        android.accessibilityservice.AccessibilityService.GLOBAL_ACTION_HOME
                    )
                }
                result.success(true)
            }

            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    /**
     * Streams confirmed reel events to Flutter in real-time.
     */
    fun sendReelConfirmed(platform: String, count: Int, stage: Int, timestamp: Long) {
        mainHandler.post {
            eventSink?.success(
                mapOf(
                    "type" to "reel_confirmed",
                    "platform" to platform,
                    "count" to count,
                    "stage" to stage,
                    "timestamp" to timestamp
                )
            )
        }
    }

    /**
     * Streams foreground app session state transitions to Flutter.
     */
    fun sendSessionState(active: Boolean, platform: String?, mode: String) {
        mainHandler.post {
            eventSink?.success(
                mapOf(
                    "type" to "session_state",
                    "active" to active,
                    "platform" to (platform ?: "none"),
                    "mode" to mode
                )
            )
        }
    }

    /**
     * Streams anti-doomscroll intervention events (velocity limit, breathe pause) to Flutter.
     */
    fun sendIntervention(reason: String, value: Any) {
        sendInterventionTriggered(reason, value)
    }

    fun sendInterventionTriggered(reason: String, value: Any) {
        mainHandler.post {
            eventSink?.success(
                mapOf(
                    "type" to "intervention",
                    "reason" to reason,
                    "value" to value
                )
            )
        }
    }
}
