package com.project.garuda.ui.sos

import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

class CitizenViewModelTest {

    private lateinit var viewModel: CitizenViewModel

    @Before
    fun setUp() {
        viewModel = CitizenViewModel()
    }

    @Test
    fun initialState_isStandbyAndIdle() {
        val state = viewModel.uiState.value
        assertEquals(DisasterMode.STANDBY, state.mode)
        assertTrue(state.sosState is SosBroadcastState.Idle)
        assertFalse(state.isGovernmentAlertDialogOpen)
        assertEquals(EmergencyType.TRAPPED, state.selectedEmergencyType)
        assertTrue(state.survivalChecklist.isNotEmpty())
    }

    @Test
    fun toggleChecklistItem_togglesCheckedState() {
        val initialItem = viewModel.uiState.value.survivalChecklist.first()
        val initialChecked = initialItem.isChecked

        viewModel.toggleChecklistItem(initialItem.id)

        val updatedItem = viewModel.uiState.value.survivalChecklist.first { it.id == initialItem.id }
        assertEquals(!initialChecked, updatedItem.isChecked)
    }

    @Test
    fun updateMedicalProfile_updatesStateCorrectly() {
        val updatedProfile = MedicalProfile(
            fullName = "Rohit Kumar",
            bloodGroup = "B+ (Positive)",
            allergies = "None",
            chronicConditions = "None",
            emergencyContacts = listOf(
                EmergencyContact("1", "Ananya", "Sister", "+91 91234 56789")
            )
        )

        viewModel.updateMedicalProfile(updatedProfile)

        assertEquals("Rohit Kumar", viewModel.uiState.value.medicalProfile.fullName)
        assertEquals("B+ (Positive)", viewModel.uiState.value.medicalProfile.bloodGroup)
        assertEquals(1, viewModel.uiState.value.medicalProfile.emergencyContacts.size)
    }

    @Test
    fun governmentAlert_triggersDialogAndEntersEmergencyMode() {
        viewModel.triggerGovernmentEmergencyAlert()

        var state = viewModel.uiState.value
        assertTrue(state.isGovernmentAlertDialogOpen)
        assertNotNull(state.pendingGovAlert)

        viewModel.acknowledgeAlertAndEnterEmergency()

        state = viewModel.uiState.value
        assertFalse(state.isGovernmentAlertDialogOpen)
        assertEquals(DisasterMode.ACTIVE_EMERGENCY, state.mode)
        assertTrue(state.meshStatus.isMeshActive)
    }

    @Test
    fun sosCountdown_startsAndCanBeCancelled() {
        viewModel.startSosCountdown()

        var state = viewModel.uiState.value
        assertTrue(state.sosState is SosBroadcastState.Countdown)
        assertEquals(5, (state.sosState as SosBroadcastState.Countdown).secondsRemaining)

        viewModel.cancelSosCountdown()

        state = viewModel.uiState.value
        assertTrue(state.sosState is SosBroadcastState.Idle)
    }

    @Test
    fun selectEmergencyType_updatesTypeProperly() {
        viewModel.selectEmergencyType(EmergencyType.FLOOD)
        assertEquals(EmergencyType.FLOOD, viewModel.uiState.value.selectedEmergencyType)

        viewModel.selectEmergencyType(EmergencyType.FIRE)
        assertEquals(EmergencyType.FIRE, viewModel.uiState.value.selectedEmergencyType)
    }

    @Test
    fun markUserSafe_transitionsToResolvedSafe() {
        viewModel.startSosCountdown()
        viewModel.markUserSafe()

        val state = viewModel.uiState.value
        assertTrue(state.sosState is SosBroadcastState.ResolvedSafe)
        assertNotNull(state.safeStatusMessage)
        assertTrue(state.safeStatusMessage!!.contains("SAFE"))
    }
}
