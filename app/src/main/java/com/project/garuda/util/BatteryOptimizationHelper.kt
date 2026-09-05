package com.project.garuda.util

import android.annotation.SuppressLint
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.util.Log

object BatteryOptimizationHelper {
    private const val TAG = "BatteryOptHelper"

    /**
     * Checks if the app is currently whitelisted from battery optimizations.
     */
    fun isIgnoringBatteryOptimizations(context: Context): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val powerManager = context.getSystemService(Context.POWER_SERVICE) as? PowerManager ?: return true
            return powerManager.isIgnoringBatteryOptimizations(context.packageName)
        }
        return true
    }

    /**
     * Requests the user to disable battery optimizations for Garuda so Android never kills
     * the BLE Mesh relay background service or push notification listener during disasters.
     */
    @SuppressLint("BatteryLife")
    fun requestIgnoreBatteryOptimization(activity: Activity) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val powerManager = activity.getSystemService(Context.POWER_SERVICE) as? PowerManager
            if (powerManager != null && !powerManager.isIgnoringBatteryOptimizations(activity.packageName)) {
                try {
                    val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                        data = Uri.parse("package:${activity.packageName}")
                    }
                    activity.startActivity(intent)
                    Log.d(TAG, "Launched ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS for ${activity.packageName}")
                } catch (e: Exception) {
                    Log.w(TAG, "Direct request failed, launching battery optimization settings fallback", e)
                    try {
                        val fallbackIntent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                        activity.startActivity(fallbackIntent)
                    } catch (ex: Exception) {
                        Log.e(TAG, "Failed to launch battery settings", ex)
                    }
                }
            } else {
                Log.d(TAG, "App is already whitelisted from battery optimizations")
            }
        }
    }
}
