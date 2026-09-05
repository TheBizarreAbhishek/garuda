package com.project.garuda.notification

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Test

class GarudaNotificationTest {

    @Test
    fun testNotificationChannelConstants() {
        assertEquals("garuda_emergency_alerts", GarudaFirebaseMessagingService.CHANNEL_EMERGENCY_ALERTS)
        assertEquals("garuda_citizen_notifications", GarudaFirebaseMessagingService.CHANNEL_CITIZEN_NOTIFICATIONS)
    }

    @Test
    fun testNotificationPayloadParsing() {
        val payload = mapOf(
            "title" to "Flash Flood Red Alert",
            "message" to "Immediate evacuation order for low-lying areas.",
            "targetDistrict" to "Jehanabad, Bihar",
            "severity" to "Level 3 - Critical / Red Alert",
            "isEmergency" to "true"
        )

        assertEquals("Flash Flood Red Alert", payload["title"])
        assertEquals("Immediate evacuation order for low-lying areas.", payload["message"])
        assertEquals("Jehanabad, Bihar", payload["targetDistrict"])
        assertEquals(true, payload["isEmergency"]?.toBoolean())
        assertNotNull(payload["severity"])
    }
}
