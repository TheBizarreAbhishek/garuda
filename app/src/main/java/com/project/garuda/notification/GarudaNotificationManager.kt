package com.project.garuda.notification

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.project.garuda.MainActivity
import java.util.concurrent.ConcurrentHashMap

object GarudaNotificationManager {

    private const val TAG = "GarudaNotification"
    const val CHANNEL_EMERGENCY_ALERTS = "garuda_emergency_alerts"
    const val CHANNEL_CITIZEN_NOTIFICATIONS = "garuda_citizen_notifications"

    private const val EMERGENCY_NOTIFICATION_ID = 9001
    private const val DEDUPLICATION_WINDOW_MS = 15_000L // 15 seconds debounce window

    // Deduplication cache to prevent dual notifications when both SSE and Firestore/FCM deliver the same alert
    private val recentNotificationTimestamps = ConcurrentHashMap<String, Long>()

    fun createNotificationChannels(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = context.getSystemService(NotificationManager::class.java) ?: return

            val alarmSound = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)

            val audioAttributes = AudioAttributes.Builder()
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .setUsage(AudioAttributes.USAGE_ALARM)
                .build()

            // 1. High-Priority Emergency Channel (Red Alert Siren + Vibration)
            val emergencyChannel = NotificationChannel(
                CHANNEL_EMERGENCY_ALERTS,
                "Disaster Emergency Declarations",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Critical geofenced disaster activation and immediate evacuation alerts"
                enableLights(true)
                lightColor = Color.RED
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 500, 200, 500, 200, 1000)
                setSound(alarmSound, audioAttributes)
                lockscreenVisibility = NotificationCompat.VISIBILITY_PUBLIC
            }

            // 2. Citizen Area Push Notification Channel
            val citizenChannel = NotificationChannel(
                CHANNEL_CITIZEN_NOTIFICATIONS,
                "Citizen Disaster Updates & Advisories",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Targeted relief updates, weather advisories, and food/medical camp locations"
                enableLights(true)
                lightColor = Color.BLUE
                enableVibration(true)
                lockscreenVisibility = NotificationCompat.VISIBILITY_PUBLIC
            }

            notificationManager.createNotificationChannel(emergencyChannel)
            notificationManager.createNotificationChannel(citizenChannel)
            Log.d(TAG, "Garuda Notification Channels initialized")
        }
    }

    fun showHeadsUpNotification(
        context: Context,
        title: String,
        message: String,
        targetArea: String = "Your Region",
        isEmergency: Boolean = false
    ) {
        // --- DEDUPLICATION CHECK ---
        val dedupKey = "$isEmergency|$title|$targetArea"
        val currentTime = System.currentTimeMillis()
        val lastSeen = recentNotificationTimestamps[dedupKey] ?: 0L

        if (currentTime - lastSeen < DEDUPLICATION_WINDOW_MS) {
            Log.d(TAG, "Suppressed duplicate notification within deduplication window: $dedupKey")
            return
        }
        recentNotificationTimestamps[dedupKey] = currentTime

        // Clean up old entries from cache
        if (recentNotificationTimestamps.size > 50) {
            val iterator = recentNotificationTimestamps.entries.iterator()
            while (iterator.hasNext()) {
                val entry = iterator.next()
                if (currentTime - entry.value > 60_000L) {
                    iterator.remove()
                }
            }
        }

        createNotificationChannels(context)

        val channelId = if (isEmergency) CHANNEL_EMERGENCY_ALERTS else CHANNEL_CITIZEN_NOTIFICATIONS
        
        // Stable notification ID so subsequent updates update in-place rather than stacking duplicates
        val notificationId = if (isEmergency) {
            EMERGENCY_NOTIFICATION_ID
        } else {
            (title.hashCode() xor targetArea.hashCode()).and(0x7FFFFFFF)
        }

        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("EXTRA_NOTIFICATION_TITLE", title)
            putExtra("EXTRA_NOTIFICATION_MESSAGE", message)
            putExtra("EXTRA_TARGET_AREA", targetArea)
            putExtra("EXTRA_IS_EMERGENCY", isEmergency)
        }

        val pendingIntent = PendingIntent.getActivity(
            context,
            notificationId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(android.R.drawable.stat_notify_error)
            .setContentTitle(if (isEmergency) "🚨 $title" else "📢 $title")
            .setContentText(message)
            .setStyle(NotificationCompat.BigTextStyle().bigText("📍 Target: $targetArea\n\n$message"))
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(if (isEmergency) NotificationCompat.CATEGORY_ALARM else NotificationCompat.CATEGORY_MESSAGE)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .setColor(if (isEmergency) Color.RED else Color.rgb(0, 122, 255))
            .setVibrate(longArrayOf(0, 500, 250, 500, 250, 1000))
            .setDefaults(NotificationCompat.DEFAULT_ALL)

        try {
            NotificationManagerCompat.from(context).notify(notificationId, builder.build())
            Log.d(TAG, "Successfully showed single deduplicated notification: '$title' for target [$targetArea]")
        } catch (e: SecurityException) {
            Log.e(TAG, "POST_NOTIFICATIONS permission not granted (Android 13+)", e)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to display notification", e)
        }
    }

    fun dismissEmergencyNotification(context: Context) {
        try {
            NotificationManagerCompat.from(context).cancel(EMERGENCY_NOTIFICATION_ID)
            Log.d(TAG, "Dismissed emergency notification upon standby/deactivation")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to dismiss emergency notification", e)
        }
    }
}
