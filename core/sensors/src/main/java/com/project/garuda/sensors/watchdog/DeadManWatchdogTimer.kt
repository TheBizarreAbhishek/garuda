package com.project.garuda.sensors.watchdog

import android.util.Log
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch

/**
 * Inactivity Dead-Man Watchdog Timer for unconscious or trapped disaster victims.
 * Automatically initiates a 60-second warning countdown before triggering panic SOS broadcast
 * if no user interaction occurs.
 */
class DeadManWatchdogTimer(
    private val scope: CoroutineScope = CoroutineScope(Dispatchers.Default),
    private val inactivityDurationMs: Long = DEFAULT_INACTIVITY_MS,
    private val warningDurationMs: Long = DEFAULT_WARNING_MS,
    private val onEmergencyTriggered: () -> Unit
) {

    companion object {
        private const val TAG = "DeadManWatchdogTimer"
        const val DEFAULT_INACTIVITY_MS = 30 * 60 * 1000L // 30 Minutes
        const val DEFAULT_WARNING_MS = 60 * 1000L           // 60 Seconds Warning
    }

    sealed class WatchdogState {
        object Idle : WatchdogState()
        data class ActiveCountdown(val remainingSeconds: Long) : WatchdogState()
        data class WarningPrompt(val remainingWarningSeconds: Long) : WatchdogState()
        object EmergencyTriggered : WatchdogState()
    }

    private val _state = MutableStateFlow<WatchdogState>(WatchdogState.Idle)
    val state: StateFlow<WatchdogState> = _state.asStateFlow()

    private var timerJob: Job? = null

    fun startWatchdog() {
        resetInactivityTimer()
    }

    fun resetInactivityTimer() {
        timerJob?.cancel()
        Log.d(TAG, "Resetting Dead-Man Watchdog Timer ($inactivityDurationMs ms)")

        timerJob = scope.launch {
            _state.value = WatchdogState.ActiveCountdown(inactivityDurationMs / 1000)

            // Phase 1: Silent inactivity countdown
            var remainingMs = inactivityDurationMs
            while (remainingMs > 0 && isActive) {
                delay(1000L)
                remainingMs -= 1000L
                _state.value = WatchdogState.ActiveCountdown(remainingMs / 1000)
            }

            if (!isActive) return@launch

            // Phase 2: Loud Pre-Alarm Warning Prompt (60 Seconds)
            Log.w(TAG, "User inactive! Starting 60-second loud Pre-Alarm Warning...")
            var warningRemainingMs = warningDurationMs
            while (warningRemainingMs > 0 && isActive) {
                _state.value = WatchdogState.WarningPrompt(warningRemainingMs / 1000)
                delay(1000L)
                warningRemainingMs -= 1000L
            }

            if (!isActive) return@launch

            // Phase 3: Trigger Panic Emergency SOS
            Log.e(TAG, "Dead-Man Watchdog EXPIRED! Triggering Automatic Emergency SOS!")
            _state.value = WatchdogState.EmergencyTriggered
            onEmergencyTriggered()
        }
    }

    fun stopWatchdog() {
        timerJob?.cancel()
        _state.value = WatchdogState.Idle
        Log.d(TAG, "Stopped Dead-Man Watchdog Timer")
    }
}
