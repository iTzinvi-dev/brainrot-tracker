package com.brainrot.tracker

import com.brainrot.tracker.bridge.AccessibilityBridge
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

/**
 * Main Flutter Activity for Brainrot Tracker Pro.
 * Registers the bidirectional AccessibilityBridge platform channels.
 */
class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        AccessibilityBridge.register(this, flutterEngine.dartExecutor.binaryMessenger)
    }
}
