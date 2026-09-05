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
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import com.project.garuda.MainActivity
import com.project.garuda.R

class GarudaFirebaseMessagingService : FirebaseMessagingService() {

    companion object {
        private const val TAG = "GarudaFCM"
        const val CHANNEL_EMERGENCY_ALERTS = "garuda_emergency_alerts"
        const val CHANNEL_CITIZEN_NOTIFICATIONS = "garuda_citizen_notifications"

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
                Log.d(TAG, "Garuda Notification Channels initialized successfully")
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannels(this)
    }

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        Log.d(TAG, "New Firebase FCM Device Token generated: $token")
    }

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)
        Log.d(TAG, "FCM Message received from: ${remoteMessage.from}")

        val data = remoteMessage.data
        val notification = remoteMessage.notification

        val title = data["title"] ?: notification?.title ?: "🚨 GARUDA DISASTER ALERT"
        val message = data["message"] ?: data["instructions"] ?: notification?.body ?: "Emergency disaster directive received."
        val targetArea = data["targetDistrict"] ?: data["targetArea"] ?: "Your Region"
        val severity = data["severity"] ?: "CRITICAL"
        val isEmergency = data["isEmergency"]?.toBoolean() ?: (severity.contains("Critical", true) || severity.contains("Red", true))

        GarudaNotificationManager.showHeadsUpNotification(
            context = this,
            title = title,
            message = message,
            targetArea = targetArea,
            isEmergency = isEmergency
        )
    }
}
