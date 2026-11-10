package com.brainrot.tracker.receiver

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter

/**
 * BroadcastReceiver monitoring screen power state changes (SCREEN_OFF / SCREEN_ON).
 * Allows the accessibility service to freeze animations and suspend tracking during screen sleep.
 */
class ScreenReceiver(
    private val onScreenOff: () -> Unit,
    private val onScreenOn: () -> Unit
) : BroadcastReceiver() {

    private var isRegistered = false

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_SCREEN_OFF -> onScreenOff()
            Intent.ACTION_SCREEN_ON, Intent.ACTION_USER_PRESENT -> onScreenOn()
        }
    }

    /**
     * Registers this receiver with the given context. Safe against duplicate registrations.
     */
    fun register(context: Context) {
        if (!isRegistered) {
            val filter = IntentFilter().apply {
                addAction(Intent.ACTION_SCREEN_OFF)
                addAction(Intent.ACTION_SCREEN_ON)
                addAction(Intent.ACTION_USER_PRESENT)
            }
            context.registerReceiver(this, filter)
            isRegistered = true
        }
    }

    /**
     * Unregisters this receiver. Safe against multiple calls or unregistered states.
     */
    fun unregister(context: Context) {
        if (isRegistered) {
            try {
                context.unregisterReceiver(this)
            } catch (_: IllegalArgumentException) {
                // Already unregistered
            }
            isRegistered = false
        }
    }
}
