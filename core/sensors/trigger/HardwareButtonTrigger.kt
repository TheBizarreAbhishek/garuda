package com.project.garuda.sensors.trigger

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.util.Log

/**
 * Detects 3 rapid power/screen button toggles within a 1.5-second window
 * to silently trigger emergency SOS panic telemetry without unlocking the phone.
 */
class HardwareButtonTrigger(
    private val context: Context,
    private val onTriplePressDetected: () -> Unit
) {

    companion object {
        private const val TAG = "HardwareButtonTrigger"
        const val TRIPLE_PRESS_WINDOW_MS = 1500L
        const val REQUIRED_PRESS_COUNT = 3
    }

    private var pressCount = 0
    private var lastPressTimestamp = 0L
    private var isRegistered = false

    private val screenReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val action = intent?.action ?: return
            if (action == Intent.ACTION_SCREEN_OFF || action == Intent.ACTION_SCREEN_ON) {
                handleButtonPress()
            }
        }
    }

    fun startListening() {
        if (!isRegistered) {
            val filter = IntentFilter().apply {
                addAction(Intent.ACTION_SCREEN_OFF)
                addAction(Intent.ACTION_SCREEN_ON)
            }
            context.registerReceiver(screenReceiver, filter)
            isRegistered = true
            Log.d(TAG, "Hardware button trigger listener started")
        }
    }

    fun stopListening() {
        if (isRegistered) {
            try {
                context.unregisterReceiver(screenReceiver)
            } catch (e: Exception) {
                Log.e(TAG, "Error unregistering hardware button listener", e)
            }
            isRegistered = false
        }
    }

    fun handleButtonPress(currentTimeMs: Long = System.currentTimeMillis()) {
        if (currentTimeMs - lastPressTimestamp > TRIPLE_PRESS_WINDOW_MS) {
            pressCount = 1
        } else {
            pressCount++
        }
        lastPressTimestamp = currentTimeMs

        Log.d(TAG, "Power button press detected: count=$pressCount")

        if (pressCount >= REQUIRED_PRESS_COUNT) {
            Log.w(TAG, "TRIPLE PRESS DETECTED! Triggering Emergency SOS...")
            pressCount = 0
            onTriplePressDetected()
        }
    }
}
