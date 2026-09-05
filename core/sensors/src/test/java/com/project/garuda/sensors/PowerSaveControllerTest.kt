package com.project.garuda.sensors

import com.project.garuda.sensors.power.PowerSaveController
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class PowerSaveControllerTest {

    @Test
    fun testCriticalBatteryThresholdEvaluation() {
        var isCriticalState = false
        val controller = PowerSaveController(
            context = object : android.content.ContextWrapper(null) {},
            onCriticalBatteryChanged = { isCritical ->
                isCriticalState = isCritical
            }
        )


        // Normal battery level
        controller.updateBatteryLevel(80)
        assertEquals(80, controller.batteryPercentage.value)
        assertFalse(controller.isCriticalBattery.value)

        // Critical threshold <= 15%
        controller.updateBatteryLevel(14)
        assertEquals(14, controller.batteryPercentage.value)
        assertTrue(controller.isCriticalBattery.value)
        assertTrue(isCriticalState)

        // Recovery > 15%
        controller.updateBatteryLevel(25)
        assertEquals(25, controller.batteryPercentage.value)
        assertFalse(controller.isCriticalBattery.value)
        assertFalse(isCriticalState)
    }
}
