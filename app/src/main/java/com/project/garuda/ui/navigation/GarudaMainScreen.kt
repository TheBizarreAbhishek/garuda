package com.project.garuda.ui.navigation

import androidx.compose.animation.Crossfade
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Scaffold
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import com.project.garuda.ui.chat.MeshChatScreen
import com.project.garuda.ui.hazards.HazardDirectoryScreen
import com.project.garuda.ui.shelter.ShelterRadarScreen
import com.project.garuda.ui.sos.CitizenScreen
import com.project.garuda.ui.sos.CitizenViewModel
import com.project.garuda.ui.sos.DisasterMode
import com.project.garuda.ui.theme.AmoledBlack

/**
 * GarudaMainScreen is the root navigation container.
 * Hosts the 4-destination bottom navigation bar and coordinates feature domains cleanly.
 */
@Composable
fun GarudaMainScreen(
    viewModel: CitizenViewModel = remember { CitizenViewModel() }
) {
    val state by viewModel.uiState.collectAsState()
    var selectedTab by remember { mutableStateOf(GarudaTab.SOS) }

    Scaffold(
        modifier = Modifier.fillMaxSize(),
        containerColor = AmoledBlack,
        bottomBar = {
            GarudaBottomNavBar(
                selectedTab = selectedTab,
                onTabSelected = { selectedTab = it },
                isEmergencyActive = state.mode == DisasterMode.ACTIVE_EMERGENCY
            )
        }
    ) { innerPadding ->
        Crossfade(
            targetState = selectedTab,
            modifier = Modifier.padding(innerPadding),
            label = "root_tab_crossfade"
        ) { tab ->
            when (tab) {
                GarudaTab.SOS -> {
                    CitizenScreen(
                        state = state,
                        viewModel = viewModel
                    )
                }

                GarudaTab.CHAT -> {
                    MeshChatScreen(
                        peersCount = state.meshStatus.peersNearby,
                        onSendMessage = { /* Broadcast via BLE Mesh */ }
                    )
                }

                GarudaTab.SHELTERS -> {
                    ShelterRadarScreen(
                        onNavigateToShelter = { /* Navigate */ }
                    )
                }

                GarudaTab.HAZARDS -> {
                    HazardDirectoryScreen(
                        onReportHazardClick = { /* Report */ }
                    )
                }
            }
        }
    }
}
