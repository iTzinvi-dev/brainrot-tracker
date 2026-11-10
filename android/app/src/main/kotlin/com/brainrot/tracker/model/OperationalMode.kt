package com.brainrot.tracker.model

/**
 * Operational power modes for Brainrot Tracker Pro.
 * Controls event debounce timing and particle animation rendering intensity.
 */
enum class OperationalMode(
    val debounceMs: Long,
    val fxEnabled: Boolean,
    val notificationTimeout: Int,
    val maxDroplets: Int
) {
    /**
     * Battery Saver: Minimal power consumption.
     * Throttled event processing, all particle effects disabled (no smoke, no droplets).
     */
    BATTERY_SAVER(
        debounceMs = 300L,
        fxEnabled = false,
        notificationTimeout = 150,
        maxDroplets = 0
    ),

    /**
     * Balanced: Default operational mode.
     * Responsive 80ms debounce with standard animations and single droplet physics.
     */
    BALANCED(
        debounceMs = 80L,
        fxEnabled = true,
        notificationTimeout = 80,
        maxDroplets = 1
    ),

    /**
     * Performance: High precision mode for 90Hz/120Hz displays.
     * 40ms debounce with full particle effects and multi-droplets.
     */
    PERFORMANCE(
        debounceMs = 40L,
        fxEnabled = true,
        notificationTimeout = 40,
        maxDroplets = 3
    );

    companion object {
        fun fromString(value: String?): OperationalMode {
            return when (value?.uppercase()?.replace(" ", "_")?.replace("-", "_")) {
                "BATTERY_SAVER", "BATTERY", "SAVER", "LOW" -> BATTERY_SAVER
                "PERFORMANCE", "HIGH" -> PERFORMANCE
                else -> BALANCED
            }
        }
    }
}
