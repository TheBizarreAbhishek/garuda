package com.project.garuda.ui.sos

import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.project.garuda.ui.theme.AmberAlert
import com.project.garuda.ui.theme.AmoledBlack
import com.project.garuda.ui.theme.BlueMeshAccent
import com.project.garuda.ui.theme.BlueMeshContainer
import com.project.garuda.ui.theme.BorderAlert
import com.project.garuda.ui.theme.BorderSubtle
import com.project.garuda.ui.theme.EmergencyBloodRed
import com.project.garuda.ui.theme.EmergencyBloodRedDark
import com.project.garuda.ui.theme.EmergencyRedContainer
import com.project.garuda.ui.theme.GarudaTheme
import com.project.garuda.ui.theme.SafeGreen
import com.project.garuda.ui.theme.SafeGreenDark
import com.project.garuda.ui.theme.SafeGreenContainer
import com.project.garuda.ui.theme.SurfaceCard
import com.project.garuda.ui.theme.SurfaceCardLight
import com.project.garuda.ui.theme.SurfaceDark
import com.project.garuda.ui.theme.TextPrimaryDark
import com.project.garuda.ui.theme.TextSecondaryDark
import com.project.garuda.ui.theme.TextTertiaryDark

@Composable
fun ActiveEmergencyScreen(
    state: CitizenUiState,
    onStartCountdown: () -> Unit,
    onCancelCountdown: () -> Unit,
    onStopBroadcasting: () -> Unit,
    onMarkSafe: () -> Unit,
    onSelectEmergencyType: (EmergencyType) -> Unit,
    onReturnToStandby: () -> Unit,
    onClearSafeMessage: () -> Unit
) {
    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .background(AmoledBlack)
            .padding(horizontal = 16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        item {
            Spacer(modifier = Modifier.height(14.dp))
            // Active Emergency Alert Banner
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(12.dp))
                    .background(EmergencyRedContainer)
                    .border(1.5.dp, EmergencyBloodRed, RoundedCornerShape(12.dp))
                    .padding(vertical = 10.dp, horizontal = 14.dp)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Box(
                            modifier = Modifier
                                .size(10.dp)
                                .clip(CircleShape)
                                .background(EmergencyBloodRed)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = "EMERGENCY PROTOCOL ACTIVE",
                            color = Color.White,
                            fontSize = 13.sp,
                            fontWeight = FontWeight.Black,
                            letterSpacing = 0.5.sp
                        )
                    }

                    Text(
                        text = "Standby",
                        color = TextSecondaryDark,
                        fontSize = 12.sp,
                        fontWeight = FontWeight.SemiBold,
                        modifier = Modifier
                            .clip(RoundedCornerShape(6.dp))
                            .background(SurfaceCard)
                            .clickable { onReturnToStandby() }
                            .padding(horizontal = 8.dp, vertical = 4.dp)
                    )
                }
            }
        }

        // BIG RED SOS PANIC BUTTON SECTION
        item {
            SosPanicButtonSection(
                sosState = state.sosState,
                onStartCountdown = onStartCountdown,
                onCancelCountdown = onCancelCountdown,
                onStopBroadcasting = onStopBroadcasting
            )
        }

        // REAL-TIME MESH STATUS INDICATOR
        item {
            MeshStatusIndicatorCard(
                meshStatus = state.meshStatus,
                isBroadcasting = state.sosState is SosBroadcastState.Broadcasting
            )
        }

        // ONE-TAP "I AM SAFE" CHECK-IN BUTTON
        item {
            Card(
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = SurfaceDark),
                modifier = Modifier
                    .fillMaxWidth()
                    .border(1.dp, SafeGreenDark, RoundedCornerShape(16.dp))
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Text(
                        text = "Are You Out of Immediate Danger?",
                        fontSize = 14.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = Color.White
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = "Tapping 'I Am Safe' cancels active distress broadcasts and queues an automated SMS check-in to your family circle with GPS coordinates.",
                        fontSize = 12.sp,
                        color = TextSecondaryDark,
                        textAlign = TextAlign.Center,
                        lineHeight = 16.sp
                    )
                    Spacer(modifier = Modifier.height(12.dp))

                    Button(
                        onClick = onMarkSafe,
                        colors = ButtonDefaults.buttonColors(
                            containerColor = SafeGreen,
                            contentColor = Color.White
                        ),
                        shape = RoundedCornerShape(12.dp),
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(48.dp)
                    ) {
                        Text(
                            text = "✓  I AM SAFE — CHECK IN",
                            fontSize = 14.sp,
                            fontWeight = FontWeight.Bold,
                            letterSpacing = 0.5.sp
                        )
                    }
                }
            }
        }

        // EMERGENCY TRIAGE / SITUATION SELECTOR
        item {
            Card(
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = SurfaceDark),
                modifier = Modifier
                    .fillMaxWidth()
                    .border(1.dp, BorderSubtle, RoundedCornerShape(16.dp))
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text(
                        text = "Distress Triage Classification",
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Bold,
                        color = AmberAlert
                    )
                    Text(
                        text = "Encodes exact triage code into the 28-byte BLE mesh packet for NDRF rescue prioritization.",
                        fontSize = 12.sp,
                        color = TextSecondaryDark
                    )

                    Spacer(modifier = Modifier.height(10.dp))

                    EmergencyType.values().forEach { type ->
                        val isSelected = type == state.selectedEmergencyType
                        Card(
                            shape = RoundedCornerShape(10.dp),
                            colors = CardDefaults.cardColors(
                                containerColor = if (isSelected) EmergencyRedContainer else SurfaceCard
                            ),
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 4.dp)
                                .border(
                                    1.dp,
                                    if (isSelected) EmergencyBloodRed else BorderSubtle,
                                    RoundedCornerShape(10.dp)
                                )
                                .clickable { onSelectEmergencyType(type) }
                        ) {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(12.dp),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Column(modifier = Modifier.weight(1f)) {
                                    Text(
                                        text = type.title,
                                        fontSize = 13.sp,
                                        fontWeight = FontWeight.Bold,
                                        color = if (isSelected) Color.White else TextSecondaryDark
                                    )
                                    Text(
                                        text = type.description,
                                        fontSize = 11.sp,
                                        color = TextTertiaryDark
                                    )
                                }
                                if (isSelected) {
                                    Box(
                                        modifier = Modifier
                                            .size(8.dp)
                                            .clip(CircleShape)
                                            .background(EmergencyBloodRed)
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }

        // EMERGENCY CONTACTS QUICK DIAL
        item {
            Card(
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = SurfaceDark),
                modifier = Modifier
                    .fillMaxWidth()
                    .border(1.dp, BorderSubtle, RoundedCornerShape(16.dp))
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text(
                        text = "Emergency Quick-Dial",
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color.White
                    )
                    Spacer(modifier = Modifier.height(8.dp))

                    state.medicalProfile.emergencyContacts.forEach { contact ->
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 6.dp),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Column {
                                Text(
                                    text = "${contact.name} (${contact.relation})",
                                    color = Color.White,
                                    fontSize = 13.sp,
                                    fontWeight = FontWeight.SemiBold
                                )
                                Text(
                                    text = contact.phone,
                                    color = TextSecondaryDark,
                                    fontSize = 12.sp
                                )
                            }

                            Box(
                                modifier = Modifier
                                    .clip(RoundedCornerShape(8.dp))
                                    .background(SurfaceCardLight)
                                    .border(1.dp, BorderSubtle, RoundedCornerShape(8.dp))
                                    .padding(horizontal = 12.dp, vertical = 6.dp)
                            ) {
                                Text(
                                    text = "Call",
                                    color = SafeGreen,
                                    fontSize = 12.sp,
                                    fontWeight = FontWeight.Bold
                                )
                            }
                        }
                    }
                }
            }
        }

        item {
            Spacer(modifier = Modifier.height(24.dp))
        }
    }

    // Safety check-in confirmation dialog
    if (state.safeStatusMessage != null) {
        AlertDialog(
            onDismissRequest = onClearSafeMessage,
            title = {
                Text(
                    text = "Safety Check-In Confirmed",
                    color = SafeGreen,
                    fontWeight = FontWeight.Bold
                )
            },
            text = {
                Text(
                    text = state.safeStatusMessage,
                    color = Color.White,
                    fontSize = 13.sp
                )
            },
            confirmButton = {
                Button(
                    onClick = onClearSafeMessage,
                    colors = ButtonDefaults.buttonColors(containerColor = SafeGreen)
                ) {
                    Text("Understood", color = Color.White)
                }
            },
            containerColor = SurfaceDark
        )
    }
}

@Composable
fun SosPanicButtonSection(
    sosState: SosBroadcastState,
    onStartCountdown: () -> Unit,
    onCancelCountdown: () -> Unit,
    onStopBroadcasting: () -> Unit
) {
    val infiniteTransition = rememberInfiniteTransition(label = "pulse")
    val pulseScale by infiniteTransition.animateFloat(
        initialValue = 1f,
        targetValue = 1.25f,
        animationSpec = infiniteRepeatable(
            animation = tween(durationMillis = 1100, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "pulse_scale"
    )

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 12.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        when (sosState) {
            is SosBroadcastState.Idle -> {
                Box(
                    contentAlignment = Alignment.Center,
                    modifier = Modifier.size(220.dp)
                ) {
                    // Pulsing Ring Effect
                    Box(
                        modifier = Modifier
                            .size(200.dp)
                            .scale(pulseScale)
                            .clip(CircleShape)
                            .background(EmergencyBloodRed.copy(alpha = 0.22f))
                    )

                    // Secondary Inner Ring
                    Box(
                        modifier = Modifier
                            .size(175.dp)
                            .clip(CircleShape)
                            .background(EmergencyBloodRed.copy(alpha = 0.45f))
                    )

                    // Main Red Button
                    Box(
                        contentAlignment = Alignment.Center,
                        modifier = Modifier
                            .size(145.dp)
                            .clip(CircleShape)
                            .background(
                                Brush.radialGradient(
                                    colors = listOf(EmergencyBloodRed, EmergencyBloodRedDark)
                                )
                            )
                            .border(3.dp, Color.White.copy(alpha = 0.35f), CircleShape)
                            .clickable { onStartCountdown() }
                    ) {
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Text(
                                text = "SOS",
                                fontSize = 34.sp,
                                fontWeight = FontWeight.Black,
                                color = Color.White,
                                letterSpacing = 2.sp
                            )
                            Text(
                                text = "PANIC",
                                fontSize = 12.sp,
                                fontWeight = FontWeight.Bold,
                                color = Color.White.copy(alpha = 0.85f),
                                letterSpacing = 1.sp
                            )
                        }
                    }
                }
                Spacer(modifier = Modifier.height(10.dp))
                Text(
                    text = "Tap to trigger 5-second distress countdown",
                    fontSize = 12.sp,
                    color = TextSecondaryDark
                )
            }

            is SosBroadcastState.Countdown -> {
                Box(
                    contentAlignment = Alignment.Center,
                    modifier = Modifier.size(220.dp)
                ) {
                    Box(
                        modifier = Modifier
                            .size(190.dp)
                            .clip(CircleShape)
                            .background(AmberAlert.copy(alpha = 0.25f))
                    )
                    Box(
                        contentAlignment = Alignment.Center,
                        modifier = Modifier
                            .size(150.dp)
                            .clip(CircleShape)
                            .background(AmberAlert)
                            .border(3.dp, Color.White, CircleShape)
                    ) {
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Text(
                                text = "${sosState.secondsRemaining}",
                                fontSize = 52.sp,
                                fontWeight = FontWeight.Black,
                                color = Color.Black
                            )
                            Text(
                                text = "SECONDS",
                                fontSize = 11.sp,
                                fontWeight = FontWeight.Bold,
                                color = Color.Black.copy(alpha = 0.7f)
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.height(12.dp))

                Button(
                    onClick = onCancelCountdown,
                    colors = ButtonDefaults.buttonColors(
                        containerColor = SurfaceCardLight,
                        contentColor = Color.White
                    ),
                    shape = RoundedCornerShape(12.dp),
                    modifier = Modifier
                        .fillMaxWidth(0.7f)
                        .height(46.dp)
                ) {
                    Text(
                        text = "CANCEL COUNTDOWN",
                        fontWeight = FontWeight.Bold,
                        fontSize = 13.sp,
                        color = Color.White
                    )
                }
            }

            is SosBroadcastState.Broadcasting -> {
                val mins = sosState.elapsedSeconds / 60
                val secs = sosState.elapsedSeconds % 60
                val formattedTime = String.format("%02d:%02d", mins, secs)

                Box(
                    contentAlignment = Alignment.Center,
                    modifier = Modifier.size(220.dp)
                ) {
                    Box(
                        modifier = Modifier
                            .size(205.dp)
                            .scale(pulseScale)
                            .clip(CircleShape)
                            .background(EmergencyBloodRed.copy(alpha = 0.35f))
                    )
                    Box(
                        contentAlignment = Alignment.Center,
                        modifier = Modifier
                            .size(155.dp)
                            .clip(CircleShape)
                            .background(EmergencyBloodRed)
                            .border(3.dp, Color.White, CircleShape)
                    ) {
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Text(
                                text = "BEACON",
                                fontSize = 12.sp,
                                fontWeight = FontWeight.Bold,
                                color = Color.White.copy(alpha = 0.8f),
                                letterSpacing = 1.sp
                            )
                            Text(
                                text = formattedTime,
                                fontSize = 28.sp,
                                fontWeight = FontWeight.Black,
                                color = Color.White,
                                fontFamily = FontFamily.Monospace
                            )
                            Text(
                                text = sosState.packetId,
                                fontSize = 11.sp,
                                fontWeight = FontWeight.Bold,
                                color = AmberAlert,
                                fontFamily = FontFamily.Monospace
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.height(10.dp))

                Text(
                    text = "Broadcasting on 2.4GHz BLE Mesh (ID: ${sosState.packetId})",
                    fontSize = 12.sp,
                    color = EmergencyBloodRed,
                    fontWeight = FontWeight.Bold
                )

                Spacer(modifier = Modifier.height(8.dp))

                OutlinedButton(
                    onClick = onStopBroadcasting,
                    shape = RoundedCornerShape(10.dp),
                    modifier = Modifier.fillMaxWidth(0.6f)
                ) {
                    Text(
                        text = "Stop Distress Broadcast",
                        color = TextSecondaryDark,
                        fontSize = 12.sp
                    )
                }
            }

            is SosBroadcastState.ResolvedSafe -> {
                Box(
                    contentAlignment = Alignment.Center,
                    modifier = Modifier.size(200.dp)
                ) {
                    Box(
                        contentAlignment = Alignment.Center,
                        modifier = Modifier
                            .size(140.dp)
                            .clip(CircleShape)
                            .background(SafeGreen)
                            .border(3.dp, Color.White, CircleShape)
                    ) {
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Text(
                                text = "SAFE",
                                fontSize = 26.sp,
                                fontWeight = FontWeight.Black,
                                color = Color.White
                            )
                            Text(
                                text = "CHECKED IN",
                                fontSize = 10.sp,
                                fontWeight = FontWeight.Bold,
                                color = Color.White.copy(alpha = 0.8f)
                            )
                        }
                    }
                }
                Spacer(modifier = Modifier.height(8.dp))
                Button(
                    onClick = onStartCountdown,
                    colors = ButtonDefaults.buttonColors(containerColor = EmergencyBloodRed)
                ) {
                    Text("Re-Arm SOS Panic", color = Color.White, fontSize = 12.sp)
                }
            }
        }
    }
}

@Composable
fun MeshStatusIndicatorCard(
    meshStatus: MeshRelayStatus,
    isBroadcasting: Boolean
) {
    Card(
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = SurfaceDark),
        modifier = Modifier
            .fillMaxWidth()
            .border(
                1.dp,
                if (isBroadcasting) BlueMeshAccent else BorderSubtle,
                RoundedCornerShape(16.dp)
            )
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Box(
                        modifier = Modifier
                            .size(8.dp)
                            .clip(CircleShape)
                            .background(if (meshStatus.isMeshActive) BlueMeshAccent else Color.Gray)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = "GARUDA BLE MESH ENGINE",
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold,
                        color = BlueMeshAccent,
                        letterSpacing = 0.5.sp
                    )
                }

                Text(
                    text = meshStatus.lastSyncAgo,
                    fontSize = 11.sp,
                    color = TextTertiaryDark
                )
            }

            Spacer(modifier = Modifier.height(12.dp))

            Text(
                text = if (isBroadcasting) {
                    "Broadcasting SOS • Relayed by ${meshStatus.peersNearby} nearby peers"
                } else {
                    "Mesh Relay Listening • ${meshStatus.peersNearby} peers in vicinity"
                },
                fontSize = 14.sp,
                fontWeight = FontWeight.Bold,
                color = Color.White
            )

            Spacer(modifier = Modifier.height(10.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                MeshStatBox(
                    label = "Peers Connected",
                    value = "${meshStatus.peersNearby}",
                    modifier = Modifier.weight(1f)
                )
                Spacer(modifier = Modifier.width(8.dp))
                MeshStatBox(
                    label = "Relay Hops",
                    value = "${meshStatus.hopCount} hops",
                    modifier = Modifier.weight(1f)
                )
                Spacer(modifier = Modifier.width(8.dp))
                MeshStatBox(
                    label = "Packets Relayed",
                    value = "${meshStatus.packetsRelayed}",
                    modifier = Modifier.weight(1f)
                )
            }
        }
    }
}

@Composable
fun MeshStatBox(label: String, value: String, modifier: Modifier = Modifier) {
    Box(
        modifier = modifier
            .clip(RoundedCornerShape(8.dp))
            .background(SurfaceCard)
            .padding(vertical = 8.dp, horizontal = 10.dp)
    ) {
        Column {
            Text(
                text = label.uppercase(),
                fontSize = 9.sp,
                fontWeight = FontWeight.Bold,
                color = TextTertiaryDark
            )
            Spacer(modifier = Modifier.height(2.dp))
            Text(
                text = value,
                fontSize = 14.sp,
                fontWeight = FontWeight.Bold,
                color = Color.White
            )
        }
    }
}

@Preview(showBackground = true)
@Composable
fun ActiveEmergencyScreenPreview() {
    GarudaTheme {
        ActiveEmergencyScreen(
            state = CitizenUiState(
                mode = DisasterMode.ACTIVE_EMERGENCY,
                sosState = SosBroadcastState.Broadcasting(
                    emergencyType = EmergencyType.TRAPPED,
                    elapsedSeconds = 142,
                    packetId = "GD-9A4B",
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
