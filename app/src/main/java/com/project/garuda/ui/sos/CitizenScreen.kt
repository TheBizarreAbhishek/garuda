package com.project.garuda.ui.sos

import androidx.compose.animation.Crossfade
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier

/**
 * CitizenScreen hosts the Emergency / SOS domain.
 * Transitions smoothly between Peace-Time Standby and Active Emergency modes.
 */
@Composable
fun CitizenScreen(
    state: CitizenUiState,
    viewModel: CitizenViewModel,
    modifier: Modifier = Modifier
) {
    Box(modifier = modifier.fillMaxSize()) {
        Crossfade(
            targetState = state.mode,
            label = "sos_mode_transition"
        ) { mode ->
            when (mode) {
                DisasterMode.STANDBY -> {
                    StandbyScreen(
                        state = state,
                        onToggleChecklist = { viewModel.toggleChecklistItem(it) },
                        onUpdateMedicalProfile = { viewModel.updateMedicalProfile(it) },
                        onSimulateGovAlert = { viewModel.triggerGovernmentEmergencyAlert() },
                        onEnterEmergencyMode = { viewModel.setDisasterMode(DisasterMode.ACTIVE_EMERGENCY) }
                    )
                }

                DisasterMode.ACTIVE_EMERGENCY -> {
                    ActiveEmergencyScreen(
                        state = state,
                        onStartCountdown = { viewModel.startSosCountdown() },
                        onCancelCountdown = { viewModel.cancelSosCountdown() },
                        onStopBroadcasting = { viewModel.stopBroadcasting() },
                        onMarkSafe = { viewModel.markUserSafe() },
                        onSelectEmergencyType = { viewModel.selectEmergencyType(it) },
                        onReturnToStandby = { viewModel.setDisasterMode(DisasterMode.STANDBY) },
                        onClearSafeMessage = { viewModel.clearSafeMessage() }
                    )
                }
            }
        }
    }
}

