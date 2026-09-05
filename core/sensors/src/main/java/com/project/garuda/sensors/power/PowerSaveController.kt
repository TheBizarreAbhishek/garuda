package com.project.garuda.sensors.power

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.util.Log
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/**
 * Adaptive Power Saving Controller monitoring battery level and OS Power Save Mode.
 * Enforces critical battery mode (<15%) to lower BLE scan/advertise duty cycle
 * (5s scan / 55s idle) and enforce pitch black AMOLED theme.
 */
class PowerSaveController(
    private val context: Context,
    private val onCriticalBatteryChanged: (Boolean) -> Unit
) {

    companion object {
        private const val TAG = "PowerSaveController"
        const val CRITICAL_BATTERY_THRESHOLD = 15 // 15%
    }

    private val _batteryPercentage = MutableStateFlow(100)
    val batteryPercentage: StateFlow<Int> = _batteryPercentage.asStateFlow()

    private val _isCriticalBattery = MutableStateFlow(false)
    val isCriticalBattery: StateFlow<Boolean> = _isCriticalBattery.asStateFlow()

    private var isMonitoring = false

    private val batteryReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == Intent.ACTION_BATTERY_CHANGED) {
                val level = intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
                val scale = intent.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
                val pct = if (level >= 0 && scale > 0) (level * 100) / scale else 100

                updateBatteryLevel(pct)
            }
        }
    }

    fun startMonitoring() {
        if (!isMonitoring) {
            val filter = IntentFilter(Intent.ACTION_BATTERY_CHANGED)
            val initialIntent = context.registerReceiver(batteryReceiver, filter)
            isMonitoring = true

            initialIntent?.let {
                val level = it.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
                val scale = it.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
                val pct = if (level >= 0 && scale > 0) (level * 100) / scale else 100
                updateBatteryLevel(pct)
            }

            Log.d(TAG, "PowerSaveController battery monitoring started")
        }
    }

    fun stopMonitoring() {
        if (isMonitoring) {
            try {
                context.unregisterReceiver(batteryReceiver)
            } catch (e: Exception) {
                Log.e(TAG, "Error unregistering battery receiver", e)
            }
            isMonitoring = false
        }
    }

    fun updateBatteryLevel(percentage: Int) {
        val clampedPct = percentage.coerceIn(0, 100)
        _batteryPercentage.value = clampedPct

        val isCritical = clampedPct <= CRITICAL_BATTERY_THRESHOLD
        if (_isCriticalBattery.value != isCritical) {
            _isCriticalBattery.value = isCritical
            Log.w(TAG, "Critical Battery threshold state changed: isCritical=$isCritical ($clampedPct%)")
            onCriticalBatteryChanged(isCritical)
        }
    }
}
