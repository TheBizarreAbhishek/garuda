package com.project.garuda.ui.sos

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.project.garuda.mesh.protocol.GarudaPacket
import com.project.garuda.mesh.service.MeshForegroundService
import com.project.garuda.network.FirebaseCloudGateway
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

    private var meshService: MeshForegroundService? = null
    val firebaseGateway = FirebaseCloudGateway(viewModelScope)

    init {
        observeFirebaseGovernmentAlerts()
        observeMeshTelemetry()
    }

    fun attachMeshService(service: MeshForegroundService) {
        this.meshService = service
    }

    private fun observeFirebaseGovernmentAlerts() {
        viewModelScope.launch {
            firebaseGateway.syncState.collect { syncState ->
                if (syncState.isEmergencyActive && _uiState.value.mode == DisasterMode.STANDBY && !_uiState.value.isGovernmentAlertDialogOpen) {
                    _uiState.update {
                        it.copy(
                            pendingGovAlert = GovernmentAlert(
                                headline = syncState.alertHeadline,
                                region = syncState.alertDistrict,
                                instructions = syncState.alertInstructions,
                                timestampFormatted = "Live from Command Grid"
                            ),
                            isGovernmentAlertDialogOpen = true
                        )
                    }
                }
            }
        }
    }

    private fun observeMeshTelemetry() {
        viewModelScope.launch {
            while (isActive) {
                delay(4000)
                if (_uiState.value.mode == DisasterMode.ACTIVE_EMERGENCY) {
                    _uiState.update { current ->
                        current.copy(
                            meshStatus = current.meshStatus.copy(
                                isMeshActive = true,
                                peersNearby = (current.meshStatus.peersNearby + ((-1..1).random())).coerceIn(2, 8),
                                packetsRelayed = current.meshStatus.packetsRelayed + 1,
                                lastSyncAgo = "Live"
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
        meshService?.setDutyCycleMode(MeshForegroundService.DutyCycleMode.HIGH_ALERT)
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
            meshService?.setDutyCycleMode(MeshForegroundService.DutyCycleMode.BACKGROUND_STANDBY)
        } else {
            meshService?.setDutyCycleMode(MeshForegroundService.DutyCycleMode.HIGH_ALERT)
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
        val randomPacketId = (System.currentTimeMillis() and 0xFFFFFFFFL).toInt()
        val randomPacketHex = "GD-" + Integer.toHexString(randomPacketId).uppercase().takeLast(4)
        val nowEpoch = System.currentTimeMillis() / 1000

        val mappedEmergencyByte = when (emergencyType) {
            EmergencyType.MEDICAL -> GarudaPacket.EMERGENCY_MEDICAL
            EmergencyType.TRAPPED -> GarudaPacket.EMERGENCY_TRAPPED
            EmergencyType.FIRE -> GarudaPacket.EMERGENCY_FIRE
            EmergencyType.FLOOD -> GarudaPacket.EMERGENCY_FLOOD
            EmergencyType.GENERAL -> GarudaPacket.EMERGENCY_NONE
        }

        val packet = GarudaPacket(
            packetType = GarudaPacket.TYPE_SOS,
            packetId = randomPacketId,
            deviceHash = "CITIZEN-DEVICE".hashCode(),
            timestamp = nowEpoch.toInt(),
            latitude = 11.6854,
            longitude = 76.1320,
            emergencyType = mappedEmergencyByte,
            hopCount = 0,
            ttl = 7
        )

        // 1. Broadcast locally over BLE mesh
        meshService?.meshRelayEngine?.broadcastPacket(packet)

        // 2. Upload to Firebase Firestore in Cloud
        viewModelScope.launch {
            val victimName = _uiState.value.medicalProfile.fullName
            firebaseGateway.uploadSosToFirestore(
                packet = packet,
                victimName = victimName,
                notes = "Live SOS beacon (${emergencyType.title}) with blood group ${_uiState.value.medicalProfile.bloodGroup}"
            )
        }

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
