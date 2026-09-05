package com.project.garuda.sensors.motion

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.util.Log
import kotlin.math.sqrt

/**
 * Accelerometer-based Fall and Crash Detector for disaster environments.
 * Detects freefall (< 2.0 m/s^2) followed by high-G impact (> 25.0 m/s^2).
 */
class FallDetector(
    private val context: Context,
    private val onFallDetected: () -> Unit
) : SensorEventListener {

    companion object {
        private const val TAG = "FallDetector"
        const val FREEFALL_THRESHOLD = 2.0f   // m/s^2
        const val IMPACT_THRESHOLD = 25.0f    // m/s^2
        const val IMPACT_WINDOW_MS = 1000L
    }

    private val sensorManager = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
    private val accelerometer = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)

    private var freefallDetectedTimestamp = 0L
    private var isListening = false

    fun startListening() {
        if (accelerometer != null && !isListening) {
            sensorManager.registerListener(this, accelerometer, SensorManager.SENSOR_DELAY_GAME)
            isListening = true
            Log.d(TAG, "FallDetector accelerometer listener started")
        }
    }

    fun stopListening() {
        if (isListening) {
            sensorManager.unregisterListener(this)
            isListening = false
            Log.d(TAG, "FallDetector listener stopped")
        }
    }

    override fun onSensorChanged(event: SensorEvent?) {
        if (event == null || event.sensor.type != Sensor.TYPE_ACCELEROMETER) return

        val x = event.values[0]
        val y = event.values[1]
        val z = event.values[2]

        val totalAcc = sqrt((x * x + y * y + z * z).toDouble()).toFloat()
        val currentTimeMs = System.currentTimeMillis()

        // 1. Detect Freefall phase
        if (totalAcc < FREEFALL_THRESHOLD) {
            freefallDetectedTimestamp = currentTimeMs
            Log.d(TAG, "Freefall detected: acc=$totalAcc m/s^2")
        }

        // 2. Detect Impact phase following freefall within 1 second
        if (freefallDetectedTimestamp > 0 &&
            (currentTimeMs - freefallDetectedTimestamp) <= IMPACT_WINDOW_MS &&
            totalAcc > IMPACT_THRESHOLD
        ) {
            Log.w(TAG, "SUDDEN IMPACT DETECTED post-freefall! acc=$totalAcc m/s^2")
            freefallDetectedTimestamp = 0L
            onFallDetected()
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
}
