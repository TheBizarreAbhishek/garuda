package com.project.garuda.ui.sos

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch

class CitizenViewModel : ViewModel() {

    private val _uiState = MutableStateFlow(CitizenUiState())
    val uiState: StateFlow<CitizenUiState> = _uiState.asStateFlow()

    private var countdownJob: Job? = null
    private var broadcastingJob: Job? = null

    init {
        // Setup initial state
        observeSimulatedMeshTelemetry()
    }

    private fun observeSimulatedMeshTelemetry() {
        viewModelScope.launch {
            while (isActive) {
                delay(8000)
                if (_uiState.value.mode == DisasterMode.ACTIVE_EMERGENCY) {
                    _uiState.update { current ->
                        val newPeers = (current.meshStatus.peersNearby + ((-1..1).random())).coerceIn(2, 9)
                        val newRelayed = current.meshStatus.packetsRelayed + (1..3).random()
                        current.copy(
                            meshStatus = current.meshStatus.copy(
                                peersNearby = newPeers,
                                packetsRelayed = newRelayed,
                                lastSyncAgo = "Just now"
                            )
                        )
                    }
                }
            }
        }
    }

    fun toggleChecklistItem(id: String) {
        _uiState.update { current ->
            val updated = current.survivalChecklist.map { item ->
                if (item.id == id) item.copy(isChecked = !item.isChecked) else item
            }
            current.copy(survivalChecklist = updated)
        }
    }

    fun updateMedicalProfile(profile: MedicalProfile) {
        _uiState.update { it.copy(medicalProfile = profile) }
    }

    fun selectEmergencyType(type: EmergencyType) {
        _uiState.update { it.copy(selectedEmergencyType = type) }
    }

    fun triggerGovernmentEmergencyAlert() {
        _uiState.update {
            it.copy(
                pendingGovAlert = GovernmentAlert(),
                isGovernmentAlertDialogOpen = true
            )
        }
    }

    fun dismissGovernmentAlert() {
        _uiState.update { it.copy(isGovernmentAlertDialogOpen = false) }
    }

    fun acknowledgeAlertAndEnterEmergency() {
        _uiState.update {
            it.copy(
                mode = DisasterMode.ACTIVE_EMERGENCY,
                isGovernmentAlertDialogOpen = false,
                meshStatus = it.meshStatus.copy(isMeshActive = true)
            )
        }
    }

    fun setDisasterMode(mode: DisasterMode) {
        if (mode == DisasterMode.STANDBY) {
            cancelSosCountdown()
            stopBroadcasting()
        }
        _uiState.update { it.copy(mode = mode) }
    }

    fun startSosCountdown() {
        if (_uiState.value.sosState is SosBroadcastState.Broadcasting) return
        countdownJob?.cancel()

        _uiState.update { it.copy(sosState = SosBroadcastState.Countdown(5)) }

        countdownJob = viewModelScope.launch {
            for (sec in 4 downTo 1) {
                delay(1000)
                _uiState.update {
                    if (it.sosState is SosBroadcastState.Countdown) {
                        it.copy(sosState = SosBroadcastState.Countdown(sec))
                    } else it
                }
            }
            delay(1000)
            triggerActiveBroadcasting()
        }
    }

    fun cancelSosCountdown() {
        countdownJob?.cancel()
        countdownJob = null
        _uiState.update { it.copy(sosState = SosBroadcastState.Idle) }
    }

    private fun triggerActiveBroadcasting() {
        val emergencyType = _uiState.value.selectedEmergencyType
        val randomPacketHex = "GD-" + (1000..9999).random().toString(16).uppercase()
        val nowEpoch = System.currentTimeMillis() / 1000

        _uiState.update {
            it.copy(
                mode = DisasterMode.ACTIVE_EMERGENCY,
                sosState = SosBroadcastState.Broadcasting(
                    emergencyType = emergencyType,
                    elapsedSeconds = 0,
                    packetId = randomPacketHex,
                    timestampEpoch = nowEpoch
                ),
                meshStatus = it.meshStatus.copy(
                    isMeshActive = true,
                    peersNearby = (it.meshStatus.peersNearby).coerceAtLeast(3)
                )
            )
        }

        broadcastingJob?.cancel()
        broadcastingJob = viewModelScope.launch {
            var seconds = 0
            while (isActive) {
                delay(1000)
                seconds++
                _uiState.update { current ->
                    if (current.sosState is SosBroadcastState.Broadcasting) {
                        current.copy(
                            sosState = current.sosState.copy(elapsedSeconds = seconds)
                        )
                    } else current
                }
            }
        }
    }

    fun stopBroadcasting() {
        broadcastingJob?.cancel()
        broadcastingJob = null
        _uiState.update { it.copy(sosState = SosBroadcastState.Idle) }
    }

    fun markUserSafe() {
        countdownJob?.cancel()
        broadcastingJob?.cancel()
        val contactsCount = _uiState.value.medicalProfile.emergencyContacts.size

        _uiState.update {
            it.copy(
                sosState = SosBroadcastState.ResolvedSafe(
                    checkInTimestamp = System.currentTimeMillis(),
                    smsSentCount = contactsCount
                ),
                safeStatusMessage = "You are marked SAFE. Dispatching automated SMS status to $contactsCount contacts."
            )
        }
    }

    fun clearSafeMessage() {
        _uiState.update { it.copy(safeStatusMessage = null) }
    }
}
