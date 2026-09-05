package com.project.garuda.ui.sos

import androidx.compose.animation.AnimatedVisibility
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
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Checkbox
import androidx.compose.material3.CheckboxDefaults
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import com.project.garuda.ui.theme.AmberAlert
import com.project.garuda.ui.theme.AmberAlertContainer
import com.project.garuda.ui.theme.AmoledBlack

import com.project.garuda.ui.theme.BorderSubtle
import com.project.garuda.ui.theme.EmergencyBloodRed
import com.project.garuda.ui.theme.GarudaTheme
import com.project.garuda.ui.theme.SafeGreen
import com.project.garuda.ui.theme.SafeGreenContainer
import com.project.garuda.ui.theme.SurfaceCard
import com.project.garuda.ui.theme.SurfaceCardLight
import com.project.garuda.ui.theme.SurfaceDark
import com.project.garuda.ui.theme.SurfaceElevated
import com.project.garuda.ui.theme.TextPrimaryDark
import com.project.garuda.ui.theme.TextSecondaryDark
import com.project.garuda.ui.theme.TextTertiaryDark

@Composable
fun StandbyScreen(
    state: CitizenUiState,
    onToggleChecklist: (String) -> Unit,
    onUpdateMedicalProfile: (MedicalProfile) -> Unit,
    onSimulateGovAlert: () -> Unit,
    onEnterEmergencyMode: () -> Unit
) {
    var selectedCategory by remember { mutableStateOf(ChecklistCategory.GO_BAG) }
    var showProfileEditDialog by remember { mutableStateOf(false) }

    val currentCategoryItems = state.survivalChecklist.filter { it.category == selectedCategory }
    val totalChecked = currentCategoryItems.count { it.isChecked }
    val progress = if (currentCategoryItems.isNotEmpty()) totalChecked.toFloat() / currentCategoryItems.size else 0f

    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .background(AmoledBlack)
            .padding(horizontal = 16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        item {
            Spacer(modifier = Modifier.height(16.dp))
            // Header with App Identity & Peace-Time Status Badge
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column {
                    Text(
                        text = "GARUDA CITIZEN",
                        fontSize = 24.sp,
                        fontWeight = FontWeight.Black,
                        color = Color.White,
                        letterSpacing = 1.sp
                    )
                    Text(
                        text = "Smart India Hackathon 2026",
                        fontSize = 12.sp,
                        color = TextTertiaryDark
                    )
                }

                // Status Badge: Real-time Live BLE Mesh Peer Count
                val peerCount = state.meshStatus.peersNearby
                val peerColor = if (peerCount > 0) SafeGreen else AmberAlert
                val peerContainer = if (peerCount > 0) SafeGreenContainer else AmberAlertContainer

                Box(
                    modifier = Modifier
                        .clip(RoundedCornerShape(20.dp))
                        .background(peerContainer)
                        .border(1.dp, peerColor, RoundedCornerShape(20.dp))
                        .padding(horizontal = 12.dp, vertical = 6.dp)
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Box(
                            modifier = Modifier
                                .size(8.dp)
                                .clip(CircleShape)
                                .background(peerColor)
                        )
                        Spacer(modifier = Modifier.width(6.dp))
                        Text(
                            text = if (peerCount > 0) "Peers: $peerCount" else "Mesh Active (0 Peer)",
                            color = peerColor,
                            fontSize = 12.sp,
                            fontWeight = FontWeight.Bold
                        )
                    }
                }
            }
        }

        // Subtitle Card: Standby Peace / Active Emergency status
        item {
            val isGovEmergencyDeclared = state.pendingGovAlert != null
            Card(
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(
                    containerColor = if (isGovEmergencyDeclared) AmberAlertContainer else SurfaceDark
                ),
                modifier = Modifier
                    .fillMaxWidth()
                    .border(
                        1.dp,
                        if (isGovEmergencyDeclared) AmberAlert else BorderSubtle,
                        RoundedCornerShape(16.dp)
                    )
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text(
                        text = if (isGovEmergencyDeclared) (state.pendingGovAlert?.headline ?: "DISASTER ALERT ACTIVE") else "No Active Disaster in your Region",
                        fontSize = 16.sp,
                        fontWeight = FontWeight.Bold,
                        color = if (isGovEmergencyDeclared) AmberAlert else Color.White
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = if (isGovEmergencyDeclared) (state.pendingGovAlert?.instructions ?: "Emergency Directive Received.") else "Your device is standing by. Prepare your emergency supplies, review survival manuals, and keep your offline medical profile updated.",
                        fontSize = 13.sp,
                        color = if (isGovEmergencyDeclared) Color.White else TextSecondaryDark,
                        lineHeight = 18.sp
                    )

                    Spacer(modifier = Modifier.height(4.dp))

                }
            }
        }


        // Medical Profile Setup Card
        item {
            MedicalProfileCard(
                profile = state.medicalProfile,
                onEditClick = { showProfileEditDialog = true }
            )
        }

        // Offline Survival Kits & Checklist Section
        item {
            Text(
                text = "Offline Survival Guides & Kits",
                fontSize = 18.sp,
                fontWeight = FontWeight.Bold,
                color = Color.White
            )
            Text(
                text = "All checklists and manuals are stored locally on your device for total offline availability.",
                fontSize = 12.sp,
                color = TextSecondaryDark
            )

            Spacer(modifier = Modifier.height(10.dp))

            // Category filter chips
            LazyRow(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                items(ChecklistCategory.values()) { category ->
                    val isSelected = category == selectedCategory
                    FilterChip(
                        selected = isSelected,
                        onClick = { selectedCategory = category },
                        label = {
                            Text(
                                text = category.label,
                                fontSize = 12.sp,
                                fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal
                            )
                        },
                        colors = FilterChipDefaults.filterChipColors(
                            selectedContainerColor = SurfaceCardLight,
                            selectedLabelColor = Color.White,
                            containerColor = SurfaceDark,
                            labelColor = TextSecondaryDark
                        ),
                        border = FilterChipDefaults.filterChipBorder(
                            enabled = true,
                            selected = isSelected,
                            borderColor = if (isSelected) SafeGreen else BorderSubtle
                        )
                    )
                }
            }

            Spacer(modifier = Modifier.height(10.dp))

            // Progress bar
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(12.dp))
                    .background(SurfaceDark)
                    .border(1.dp, BorderSubtle, RoundedCornerShape(12.dp))
                    .padding(14.dp)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "${selectedCategory.label} Readiness",
                        fontSize = 13.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = Color.White
                    )
                    Text(
                        text = "$totalChecked / ${currentCategoryItems.size} Completed",
                        fontSize = 12.sp,
                        color = SafeGreen,
                        fontWeight = FontWeight.Bold
                    )
                }
                Spacer(modifier = Modifier.height(8.dp))
                LinearProgressIndicator(
                    progress = { progress },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(8.dp)
                        .clip(CircleShape),
                    color = SafeGreen,
                    trackColor = SurfaceElevated
                )
            }
        }

        // Checklist Items
        items(currentCategoryItems) { item ->
            ChecklistItemRow(
                item = item,
                onToggle = { onToggleChecklist(item.id) }
            )
        }

        // First Aid Quick Manual Card
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
                        text = "Emergency First Aid Quick Rules",
                        fontSize = 16.sp,
                        fontWeight = FontWeight.Bold,
                        color = AmberAlert
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    FirstAidGuideline(
                        title = "DRSABCD Protocol",
                        text = "Danger -> Response -> Send for help -> Airway -> Breathing -> CPR -> Defibrillation"
                    )
                    FirstAidGuideline(
                        title = "Severe Bleeding",
                        text = "Apply direct, firm pressure with sterile gauze. Elevate wound if possible. Do NOT remove soaked pads; layer more on top."
                    )
                    FirstAidGuideline(
                        title = "Burn Care",
                        text = "Cool burn under gentle cool running water for 20 minutes. Do NOT use ice, butter, or grease. Cover with clean non-stick dressing."
                    )
                    FirstAidGuideline(
                        title = "Adult CPR Rhythm",
                        text = "30 chest compressions at 100-120 bpm (staying alive rhythm) followed by 2 rescue breaths."
                    )
                }
            }
        }

        item {
            Spacer(modifier = Modifier.height(32.dp))
        }
    }

    if (showProfileEditDialog) {
        EditProfileDialog(
            currentProfile = state.medicalProfile,
            onDismiss = { showProfileEditDialog = false },
            onSave = { updated ->
                onUpdateMedicalProfile(updated)
                showProfileEditDialog = false
            }
        )
    }
}

@Composable
fun ChecklistItemRow(
    item: ChecklistItem,
    onToggle: () -> Unit
) {
    Card(
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = SurfaceDark),
        modifier = Modifier
            .fillMaxWidth()
            .border(1.dp, BorderSubtle, RoundedCornerShape(12.dp))
            .clickable { onToggle() }
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Checkbox(
                checked = item.isChecked,
                onCheckedChange = { onToggle() },
                colors = CheckboxDefaults.colors(
                    checkedColor = SafeGreen,
                    uncheckedColor = TextSecondaryDark,
                    checkmarkColor = Color.White
                )
            )
            Spacer(modifier = Modifier.width(10.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = item.title,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Medium,
                    color = if (item.isChecked) TextSecondaryDark else Color.White
                )
                if (item.detail.isNotEmpty()) {
                    Spacer(modifier = Modifier.height(2.dp))
                    Text(
                        text = item.detail,
                        fontSize = 12.sp,
                        color = TextTertiaryDark
                    )
                }
            }
        }
    }
}

@Composable
fun MedicalProfileCard(
    profile: MedicalProfile,
    onEditClick: () -> Unit
) {
    Card(
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = SurfaceDark),
        modifier = Modifier
            .fillMaxWidth()
            .border(1.dp, BorderSubtle, RoundedCornerShape(16.dp))
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Medical ID & Emergency Contacts",
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color.White
                )
                Text(
                    text = "Edit",
                    color = SafeGreen,
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Bold,
                    modifier = Modifier.clickable { onEditClick() }
                )
            }

            Spacer(modifier = Modifier.height(12.dp))

            Row(modifier = Modifier.fillMaxWidth()) {
                ProfileField(label = "Full Name", value = profile.fullName, modifier = Modifier.weight(1f))
                ProfileField(label = "Blood Group", value = profile.bloodGroup, modifier = Modifier.weight(1f))
            }

            Spacer(modifier = Modifier.height(8.dp))

            Row(modifier = Modifier.fillMaxWidth()) {
                ProfileField(label = "Allergies", value = profile.allergies, modifier = Modifier.weight(1f))
                ProfileField(label = "Conditions", value = profile.chronicConditions, modifier = Modifier.weight(1f))
            }

            Spacer(modifier = Modifier.height(10.dp))
            HorizontalDivider(color = BorderSubtle)
            Spacer(modifier = Modifier.height(10.dp))

            Text(
                text = "EMERGENCY CONTACTS (OFFLINE AUTO-SMS)",
                fontSize = 11.sp,
                fontWeight = FontWeight.Bold,
                color = TextTertiaryDark
            )

            Spacer(modifier = Modifier.height(6.dp))

            profile.emergencyContacts.forEach { contact ->
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 3.dp),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(
                        text = "${contact.name} (${contact.relation})",
                        color = Color.White,
                        fontSize = 13.sp
                    )
                    Text(
                        text = contact.phone,
                        color = TextSecondaryDark,
                        fontSize = 13.sp,
                        fontWeight = FontWeight.Medium
                    )
                }
            }
        }
    }
}

@Composable
fun ProfileField(label: String, value: String, modifier: Modifier = Modifier) {
    Column(modifier = modifier) {
        Text(
            text = label.uppercase(),
            fontSize = 10.sp,
            fontWeight = FontWeight.Bold,
            color = TextTertiaryDark
        )
        Text(
            text = value,
            fontSize = 13.sp,
            fontWeight = FontWeight.SemiBold,
            color = Color.White
        )
    }
}

@Composable
fun FirstAidGuideline(title: String, text: String) {
    Column(modifier = Modifier.padding(vertical = 4.dp)) {
        Text(
            text = "• $title",
            color = Color.White,
            fontWeight = FontWeight.Bold,
            fontSize = 13.sp
        )
        Text(
            text = text,
            color = TextSecondaryDark,
            fontSize = 12.sp,
            lineHeight = 16.sp,
            modifier = Modifier.padding(start = 12.dp)
        )
    }
}

@Composable
fun EditProfileDialog(
    currentProfile: MedicalProfile,
    onDismiss: () -> Unit,
    onSave: (MedicalProfile) -> Unit
) {
    var name by remember { mutableStateOf(currentProfile.fullName) }
    var bloodGroup by remember { mutableStateOf(currentProfile.bloodGroup) }
    var allergies by remember { mutableStateOf(currentProfile.allergies) }
    var conditions by remember { mutableStateOf(currentProfile.chronicConditions) }

    Dialog(onDismissRequest = onDismiss) {
        Card(
            shape = RoundedCornerShape(16.dp),
            colors = CardDefaults.cardColors(containerColor = SurfaceDark),
            modifier = Modifier
                .fillMaxWidth()
                .border(1.dp, BorderSubtle, RoundedCornerShape(16.dp))
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(20.dp)
            ) {
                Text(
                    text = "Edit Medical Profile",
                    fontSize = 18.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color.White
                )

                Spacer(modifier = Modifier.height(14.dp))

                OutlinedTextField(
                    value = name,
                    onValueChange = { name = it },
                    label = { Text("Full Name") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )

                Spacer(modifier = Modifier.height(8.dp))

                OutlinedTextField(
                    value = bloodGroup,
                    onValueChange = { bloodGroup = it },
                    label = { Text("Blood Group (e.g. O+, A-, B+)") },
                    singleLine = true,
                    modifier = Modifier.fillMaxWidth()
                )

                Spacer(modifier = Modifier.height(8.dp))

                OutlinedTextField(
                    value = allergies,
                    onValueChange = { allergies = it },
                    label = { Text("Allergies") },
                    modifier = Modifier.fillMaxWidth()
                )

                Spacer(modifier = Modifier.height(8.dp))

                OutlinedTextField(
                    value = conditions,
                    onValueChange = { conditions = it },
                    label = { Text("Chronic Conditions / Inhaler / Insulin") },
                    modifier = Modifier.fillMaxWidth()
                )

                Spacer(modifier = Modifier.height(16.dp))

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.End
                ) {
                    OutlinedButton(onClick = onDismiss) {
                        Text("Cancel")
                    }
                    Spacer(modifier = Modifier.width(8.dp))
                    Button(
                        onClick = {
                            onSave(
                                currentProfile.copy(
                                    fullName = name,
                                    bloodGroup = bloodGroup,
                                    allergies = allergies,
                                    chronicConditions = conditions
                                )
                            )
                        },
                        colors = ButtonDefaults.buttonColors(containerColor = SafeGreen)
                    ) {
                        Text("Save Profile", color = Color.White)
                    }
                }
            }
        }
    }
}

@Preview(showBackground = true)
@Composable
fun StandbyScreenPreview() {
    GarudaTheme {
        StandbyScreen(
            state = CitizenUiState(),
            onToggleChecklist = {},
            onUpdateMedicalProfile = {},
            onSimulateGovAlert = {},
            onEnterEmergencyMode = {}
        )
    }
}
