package com.project.garuda.ui.navigation

import android.content.Intent
import android.net.Uri
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
import androidx.compose.ui.platform.LocalContext
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
    val context = LocalContext.current
    val state by viewModel.uiState.collectAsState()
    val chatMessages by viewModel.chatMessages.collectAsState()
    val shelters by viewModel.shelters.collectAsState()
    val hazardList by viewModel.hazardList.collectAsState()
    val privateContacts by viewModel.privateContacts.collectAsState()
    val locState by (viewModel.firebaseGateway.hardwareManager?.locationFlow ?: kotlinx.coroutines.flow.MutableStateFlow(null)).collectAsState()
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
                        messages = chatMessages,
                        peersCount = state.meshStatus.peersNearby,
                        myDeviceId = viewModel.myDeviceId,
                        privateContacts = privateContacts,
                        onSendMessage = { text, targetId, audioBase64, durationSec ->
                            viewModel.sendMeshChatMessage(text, targetId, audioBase64, durationSec)
                        },
                        onAddPrivateContact = { name, deviceId, relation ->
                            viewModel.addPrivateContact(name, deviceId, relation)
                        }
                    )
                }

                GarudaTab.SHELTERS -> {
                    ShelterRadarScreen(
                        shelters = shelters,
                        onNavigateToShelter = { shelter ->
                            try {
                                val gmmIntentUri = Uri.parse("geo:0,0?q=${shelter.latitude},${shelter.longitude}(${Uri.encode(shelter.name)})")
                                val mapIntent = Intent(Intent.ACTION_VIEW, gmmIntentUri).apply {
                                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                                }
                                context.startActivity(mapIntent)
                            } catch (e: Exception) {
                                try {
                                    val browserUri = Uri.parse("https://www.google.com/maps/search/?api=1&query=${shelter.latitude},${shelter.longitude}")
                                    val browserIntent = Intent(Intent.ACTION_VIEW, browserUri).apply {
                                        flags = Intent.FLAG_ACTIVITY_NEW_TASK
                                    }
                                    context.startActivity(browserIntent)
                                } catch (_: Exception) {}
                            }
                        },
                        onCallShelter = { shelter ->
                            try {
                                val callIntent = Intent(Intent.ACTION_DIAL, Uri.parse("tel:${shelter.phone}")).apply {
                                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                                }
                                context.startActivity(callIntent)
                            } catch (_: Exception) {}
                        }
                    )
                }

                GarudaTab.HAZARDS -> {
                    HazardDirectoryScreen(
                        hazards = hazardList,
                        currentLatitude = locState?.latitude ?: 0.0,
                        currentLongitude = locState?.longitude ?: 0.0,
                        currentLocationName = locState?.locationName ?: "",
                        onReportHazard = { title, location, severity, description, imageBase64, isCamVerified ->
                            viewModel.reportHazard(title, location, severity, description, imageBase64, isCamVerified)
                        },
                        onConfirmHazard = { hazardId ->
                            viewModel.confirmHazard(hazardId)
                        }
                    )
                }
            }
        }
    }
}
