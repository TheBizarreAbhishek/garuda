package com.project.garuda.ui.sos

import androidx.compose.animation.Crossfade
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Scaffold
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import com.project.garuda.ui.theme.GarudaTheme

@Composable
fun CitizenScreen(
    viewModel: CitizenViewModel = remember { CitizenViewModel() }
) {
    val state by viewModel.uiState.collectAsState()

    Scaffold(
        modifier = Modifier.fillMaxSize()
    ) { innerPadding ->
        Crossfade(
            targetState = state.mode,
            modifier = Modifier.padding(innerPadding),
            label = "mode_transition"
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

        // High priority government emergency activation popup
        if (state.isGovernmentAlertDialogOpen && state.pendingGovAlert != null) {
            EmergencyActivationDialog(
                alert = state.pendingGovAlert!!,
                onAcknowledge = { viewModel.acknowledgeAlertAndEnterEmergency() },
                onDismiss = { viewModel.dismissGovernmentAlert() }
            )
        }
    }
}

@Preview(showBackground = true)
@Composable
fun CitizenScreenStandbyPreview() {
    GarudaTheme {
        StandbyScreen(
            state = CitizenUiState(mode = DisasterMode.STANDBY),
            onToggleChecklist = {},
            onUpdateMedicalProfile = {},
            onSimulateGovAlert = {},
            onEnterEmergencyMode = {}
        )
    }
}

@Preview(showBackground = true)
@Composable
fun CitizenScreenActivePreview() {
    GarudaTheme {
        ActiveEmergencyScreen(
            state = CitizenUiState(
                mode = DisasterMode.ACTIVE_EMERGENCY,
                sosState = SosBroadcastState.Broadcasting(
                    emergencyType = EmergencyType.TRAPPED,
                    elapsedSeconds = 85,
                    packetId = "GD-4744",
                    timestampEpoch = 1772615400
                )
            ),
            onStartCountdown = {},
            onCancelCountdown = {},
            onStopBroadcasting = {},
            onMarkSafe = {},
            onSelectEmergencyType = {},
            onReturnToStandby = {},
            onClearSafeMessage = {}
        )
    }
}
