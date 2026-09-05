package com.project.garuda.sensors

import com.project.garuda.sensors.watchdog.DeadManWatchdogTimer
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class DeadManWatchdogTimerTest {

    @Test
    fun testDeadManWatchdogTimerCountdownAndEmergencyTrigger() = runTest {
        val testDispatcher = StandardTestDispatcher(testScheduler)
        val testScope = TestScope(testDispatcher)

        var isEmergencyTriggered = false
        val watchdog = DeadManWatchdogTimer(
            scope = testScope,
            inactivityDurationMs = 2000L, // 2s inactivity
            warningDurationMs = 1000L,   // 1s warning prompt
            onEmergencyTriggered = {
                isEmergencyTriggered = true
            }
        )

        watchdog.startWatchdog()
        testDispatcher.scheduler.advanceTimeBy(1000L)
        assertTrue(watchdog.state.value is DeadManWatchdogTimer.WatchdogState.ActiveCountdown)

        // Advance past inactivity into warning prompt
        testDispatcher.scheduler.advanceTimeBy(1500L)
        assertTrue(watchdog.state.value is DeadManWatchdogTimer.WatchdogState.WarningPrompt)

        // Advance past warning into emergency triggered
        testDispatcher.scheduler.advanceTimeBy(1000L)
        assertEquals(DeadManWatchdogTimer.WatchdogState.EmergencyTriggered, watchdog.state.value)
        assertTrue(isEmergencyTriggered)
    }

    @Test
    fun testResetInactivityTimerPreventsEmergencyTrigger() = runTest {
        val testDispatcher = StandardTestDispatcher(testScheduler)
        val testScope = TestScope(testDispatcher)

        var isEmergencyTriggered = false
        val watchdog = DeadManWatchdogTimer(
            scope = testScope,
            inactivityDurationMs = 2000L,
            warningDurationMs = 1000L,
            onEmergencyTriggered = {
                isEmergencyTriggered = true
            }
        )

        watchdog.startWatchdog()
        testDispatcher.scheduler.advanceTimeBy(1000L)

        // User activity occurs -> reset timer
        watchdog.resetInactivityTimer()
        testDispatcher.scheduler.advanceTimeBy(1000L)

        // Still in active countdown, emergency not triggered
        assertTrue(watchdog.state.value is DeadManWatchdogTimer.WatchdogState.ActiveCountdown)
        assertTrue(!isEmergencyTriggered)

        watchdog.stopWatchdog()
        assertEquals(DeadManWatchdogTimer.WatchdogState.Idle, watchdog.state.value)
    }
}
