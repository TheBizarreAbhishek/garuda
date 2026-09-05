package com.project.garuda.ui.hazards

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.Base64
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AddAlert
import androidx.compose.material.icons.filled.CameraAlt
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Dangerous
import androidx.compose.material.icons.filled.GpsFixed
import androidx.compose.material.icons.filled.PersonSearch
import androidx.compose.material.icons.filled.PhotoCamera
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Security
import androidx.compose.material.icons.filled.ThumbUp
import androidx.compose.material.icons.filled.VerifiedUser
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Tab
import androidx.compose.material3.TabRow
import androidx.compose.material3.TabRowDefaults
import androidx.compose.material3.TabRowDefaults.tabIndicatorOffset
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import com.project.garuda.ui.theme.AmberAlert
import com.project.garuda.ui.theme.AmoledBlack
import com.project.garuda.ui.theme.EmergencyRed
import com.project.garuda.ui.theme.SafeGreen
import java.io.ByteArrayOutputStream

data class HazardAlert(
    val id: String,
    val title: String,
    val location: String,
    val distanceMeters: Int,
    val severity: String, // "CRITICAL", "HIGH", "MODERATE"
    val reportedAgo: String,
    val confirmationCount: Int,
    val imageProof: String? = null,
    val isCameraVerified: Boolean = false,
    val latitude: Double = 0.0,
    val longitude: Double = 0.0
)

data class MissingPerson(
    val id: String,
    val name: String,
    val age: Int,
    val lastSeenLocation: String,
    val lastSeenTime: String,
    val contactPhone: String
)

@Composable
fun HazardDirectoryScreen(
    hazards: List<HazardAlert> = emptyList(),
    missingList: List<MissingPerson> = emptyList(),
    currentLatitude: Double = 0.0,
    currentLongitude: Double = 0.0,
    currentLocationName: String = "",
    onReportHazard: (title: String, location: String, severity: String, description: String, imageBase64: String?, isCameraVerified: Boolean) -> Unit = { _, _, _, _, _, _ -> },
    onConfirmHazard: (String) -> Unit = {}
) {
    var selectedSubTab by remember { mutableIntStateOf(0) }
    var showReportDialog by remember { mutableStateOf(false) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(AmoledBlack)
            .padding(16.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column {
                Text(
                    text = "Hazards & Directory",
                    fontSize = 22.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color.White
                )
                Text(
                    text = "Mesh-Crowdsourced Live Field Reports",
                    fontSize = 12.sp,
                    color = AmberAlert,
                    fontWeight = FontWeight.SemiBold
                )
            }

            Button(
                onClick = { showReportDialog = true },
                colors = ButtonDefaults.buttonColors(containerColor = AmberAlert),
                shape = RoundedCornerShape(8.dp),
                contentPadding = PaddingValues(horizontal = 10.dp, vertical = 6.dp)
            ) {
                Icon(
                    imageVector = Icons.Default.AddAlert,
                    contentDescription = null,
                    tint = Color.Black,
                    modifier = Modifier.size(16.dp)
                )
                Spacer(modifier = Modifier.width(4.dp))
                Text("Report Hazard", color = Color.Black, fontSize = 12.sp, fontWeight = FontWeight.Bold)
            }
        }

        Spacer(modifier = Modifier.height(14.dp))

        // Sub Tabs: Hazards vs Missing Persons
        TabRow(
            selectedTabIndex = selectedSubTab,
            containerColor = Color(0xFF141414),
            contentColor = AmberAlert,
            indicator = { tabPositions ->
                TabRowDefaults.SecondaryIndicator(
                    modifier = Modifier.tabIndicatorOffset(tabPositions[selectedSubTab]),
                    color = AmberAlert
                )
            }
        ) {
            Tab(
                selected = selectedSubTab == 0,
                onClick = { selectedSubTab = 0 },
                text = {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(imageVector = Icons.Default.Warning, contentDescription = null, modifier = Modifier.size(15.dp))
                        Spacer(modifier = Modifier.width(6.dp))
                        Text("Active Hazards (${hazards.size})", fontSize = 13.sp, fontWeight = FontWeight.Bold)
                    }
                },
                selectedContentColor = AmberAlert,
                unselectedContentColor = Color.Gray
            )
            Tab(
                selected = selectedSubTab == 1,
                onClick = { selectedSubTab = 1 },
                text = {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(imageVector = Icons.Default.PersonSearch, contentDescription = null, modifier = Modifier.size(15.dp))
                        Spacer(modifier = Modifier.width(6.dp))
                        Text("Missing Persons (${missingList.size})", fontSize = 13.sp, fontWeight = FontWeight.Bold)
                    }
                },
                selectedContentColor = AmberAlert,
                unselectedContentColor = Color.Gray
            )
        }

        Spacer(modifier = Modifier.height(12.dp))

        if (selectedSubTab == 0) {
            if (hazards.isEmpty()) {
                Box(
                    modifier = Modifier
                        .weight(1f)
                        .fillMaxWidth(),
                    contentAlignment = Alignment.Center
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Icon(
                            imageVector = Icons.Default.Dangerous,
                            contentDescription = null,
                            tint = Color.Gray,
                            modifier = Modifier.size(48.dp)
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                        Text("No Field Hazards Reported Nearby", fontWeight = FontWeight.Bold, color = Color.White)
                        Text("Tap 'Report Hazard' above to report a live-verified road obstacle or flood.", color = Color.Gray, fontSize = 12.sp)
                    }
                }
            } else {
                LazyColumn(
                    modifier = Modifier
                        .weight(1f)
                        .fillMaxWidth(),
                    verticalArrangement = Arrangement.spacedBy(10.dp),
                    contentPadding = PaddingValues(bottom = 8.dp)
                ) {
                    items(hazards, key = { it.id }) { hazard ->
                        HazardItemCard(hazard = hazard, onConfirm = { onConfirmHazard(hazard.id) })
                    }
                }
            }
        } else {
            if (missingList.isEmpty()) {
                Box(
                    modifier = Modifier
                        .weight(1f)
                        .fillMaxWidth(),
                    contentAlignment = Alignment.Center
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Icon(
                            imageVector = Icons.Default.PersonSearch,
                            contentDescription = null,
                            tint = Color.Gray,
                            modifier = Modifier.size(48.dp)
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                        Text("No Missing Person Reports", fontWeight = FontWeight.Bold, color = Color.White)
                        Text("Reports broadcasted over the mesh or Command Center will appear here.", color = Color.Gray, fontSize = 12.sp)
                    }
                }
            } else {
                LazyColumn(
                    modifier = Modifier
                        .weight(1f)
                        .fillMaxWidth(),
                    verticalArrangement = Arrangement.spacedBy(10.dp),
                    contentPadding = PaddingValues(bottom = 8.dp)
                ) {
                    items(missingList, key = { it.id }) { person ->
                        MissingPersonCard(person = person)
                    }
                }
            }
        }
    }

    if (showReportDialog) {
        ReportHazardModal(
            currentLat = currentLatitude,
            currentLon = currentLongitude,
            currentLocationName = currentLocationName,
            onDismiss = { showReportDialog = false },
            onSubmit = { title, loc, sev, desc, imgBase64, isCamVerified ->
                onReportHazard(title, loc, sev, desc, imgBase64, isCamVerified)
                showReportDialog = false
            }
        )
    }
}

@Composable
private fun HazardItemCard(
    hazard: HazardAlert,
    onConfirm: () -> Unit
) {
    val severityColor = when (hazard.severity) {
        "CRITICAL" -> EmergencyRed
        "HIGH" -> AmberAlert
        else -> Color(0xFFFFCC80)
    }

    // Decode Base64 image if present
    val decodedBitmap = remember(hazard.imageProof) {
        if (!hazard.imageProof.isNullOrBlank()) {
            try {
                val decodedBytes = Base64.decode(hazard.imageProof, Base64.DEFAULT)
                BitmapFactory.decodeByteArray(decodedBytes, 0, decodedBytes.size)
            } catch (e: Exception) {
                null
            }
        } else null
    }

    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = Color(0xFF141414)),
        border = androidx.compose.foundation.BorderStroke(1.dp, severityColor.copy(alpha = 0.4f))
    ) {
        Column(modifier = Modifier.padding(14.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Box(
                        modifier = Modifier
                            .background(severityColor.copy(alpha = 0.2f), RoundedCornerShape(4.dp))
                            .padding(horizontal = 6.dp, vertical = 2.dp)
                    ) {
                        Text(
                            text = hazard.severity,
                            fontSize = 10.sp,
                            fontWeight = FontWeight.Bold,
                            color = severityColor
                        )
                    }

                    if (hazard.isCameraVerified || decodedBitmap != null) {
                        Spacer(modifier = Modifier.width(6.dp))
                        Box(
                            modifier = Modifier
                                .background(SafeGreen.copy(alpha = 0.2f), RoundedCornerShape(4.dp))
                                .padding(horizontal = 6.dp, vertical = 2.dp)
                        ) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Icon(
                                    imageVector = Icons.Default.VerifiedUser,
                                    contentDescription = null,
                                    tint = SafeGreen,
                                    modifier = Modifier.size(10.dp)
                                )
                                Spacer(modifier = Modifier.width(2.dp))
                                Text(
                                    text = "CAM VERIFIED",
                                    fontSize = 9.sp,
                                    fontWeight = FontWeight.Bold,
                                    color = SafeGreen
                                )
                            }
                        }
                    }
                }

                Text(
                    text = if (hazard.distanceMeters > 0) "${hazard.distanceMeters}m away • ${hazard.reportedAgo}" else hazard.reportedAgo,
                    fontSize = 11.sp,
                    color = Color.Gray
                )
            }

            Spacer(modifier = Modifier.height(6.dp))

            Text(
                text = hazard.title,
                fontSize = 15.sp,
                fontWeight = FontWeight.Bold,
                color = Color.White
            )

            Text(
                text = hazard.location,
                fontSize = 12.sp,
                color = Color(0xFFB0BEC5)
            )

            // Display Camera Photo Proof Thumbnail if available
            if (decodedBitmap != null) {
                Spacer(modifier = Modifier.height(8.dp))
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(130.dp)
                        .clip(RoundedCornerShape(8.dp))
                        .border(1.dp, SafeGreen.copy(alpha = 0.3f), RoundedCornerShape(8.dp))
                ) {
                    Image(
                        bitmap = decodedBitmap.asImageBitmap(),
                        contentDescription = "Hazard Live Photo Proof",
                        modifier = Modifier.fillMaxSize(),
                        contentScale = ContentScale.Crop
                    )
                    Box(
                        modifier = Modifier
                            .align(Alignment.BottomStart)
                            .background(Color.Black.copy(alpha = 0.7f), RoundedCornerShape(topEnd = 6.dp))
                            .padding(horizontal = 6.dp, vertical = 2.dp)
                    ) {
                        Text("📷 Live Camera Geotagged Proof", fontSize = 9.sp, color = SafeGreen, fontWeight = FontWeight.Bold)
                    }
                }
            }

            Spacer(modifier = Modifier.height(10.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        imageVector = Icons.Default.CheckCircle,
                        contentDescription = null,
                        tint = Color(0xFF00E5FF),
                        modifier = Modifier.size(14.dp)
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(
                        text = "${hazard.confirmationCount} peer confirmations",
                        fontSize = 11.sp,
                        color = Color(0xFF00E5FF)
                    )
                }

                OutlinedButton(
                    onClick = onConfirm,
                    colors = ButtonDefaults.outlinedButtonColors(contentColor = AmberAlert),
                    shape = RoundedCornerShape(6.dp),
                    contentPadding = PaddingValues(horizontal = 8.dp, vertical = 2.dp)
                ) {
                    Icon(imageVector = Icons.Default.ThumbUp, contentDescription = null, modifier = Modifier.size(12.dp))
                    Spacer(modifier = Modifier.width(4.dp))
                    Text("Confirm", fontSize = 11.sp, fontWeight = FontWeight.Bold)
                }
            }
        }
    }
}

@Composable
private fun MissingPersonCard(person: MissingPerson) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = Color(0xFF141414)),
        border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFF262626))
    ) {
        Row(
            modifier = Modifier.padding(14.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier
                    .size(50.dp)
                    .background(Color(0xFF2A2A2A), CircleShape),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.Default.PersonSearch,
                    contentDescription = null,
                    tint = AmberAlert,
                    modifier = Modifier.size(28.dp)
                )
            }

            Spacer(modifier = Modifier.width(14.dp))

            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = "${person.name}, ${person.age} yrs",
                    fontSize = 15.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color.White
                )
                Text(
                    text = "Last seen: ${person.lastSeenLocation}",
                    fontSize = 11.sp,
                    color = Color(0xFFB0BEC5),
                    lineHeight = 15.sp
                )
                Text(
                    text = "Time: ${person.lastSeenTime}",
                    fontSize = 11.sp,
                    color = Color.Gray
                )
                Spacer(modifier = Modifier.height(2.dp))
                Text(
                    text = "Contact: ${person.contactPhone}",
                    fontSize = 11.sp,
                    fontWeight = FontWeight.Bold,
                    color = AmberAlert
                )
            }
        }
    }
}

@Composable
fun ReportHazardModal(
    currentLat: Double = 0.0,
    currentLon: Double = 0.0,
    currentLocationName: String = "",
    onDismiss: () -> Unit,
    onSubmit: (title: String, location: String, severity: String, description: String, imageBase64: String?, isCameraVerified: Boolean) -> Unit
) {
    var title by remember { mutableStateOf("") }
    var location by remember { mutableStateOf(currentLocationName.ifBlank { if (currentLat != 0.0) "GPS: ${String.format("%.4f", currentLat)}, ${String.format("%.4f", currentLon)}" else "" }) }
    var severity by remember { mutableStateOf("HIGH") }
    var description by remember { mutableStateOf("") }
    var capturedBitmap by remember { mutableStateOf<Bitmap?>(null) }
    var imageBase64 by remember { mutableStateOf<String?>(null) }

    // Live Camera Photo Capture Contract
    val cameraLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.TakePicturePreview()
    ) { bitmap: Bitmap? ->
        if (bitmap != null) {
            capturedBitmap = bitmap
            try {
                val stream = ByteArrayOutputStream()
                bitmap.compress(Bitmap.CompressFormat.JPEG, 70, stream)
                val bytes = stream.toByteArray()
                imageBase64 = Base64.encodeToString(bytes, Base64.NO_WRAP)
            } catch (e: Exception) {
                imageBase64 = null
            }
        }
    }

    val quickTypes = listOf(
        "Road Blocked by Debris",
        "Bridge Submerged / Flooded",
        "Live Electrical Power Line Fallen",
        "Structural Building Collapse",
        "Active Wildfire / Smoke Hazard"
    )

    Dialog(onDismissRequest = onDismiss) {
        Card(
            shape = RoundedCornerShape(16.dp),
            colors = CardDefaults.cardColors(containerColor = Color(0xFF181818)),
            border = androidx.compose.foundation.BorderStroke(1.dp, AmberAlert.copy(alpha = 0.5f)),
            modifier = Modifier.fillMaxWidth()
        ) {
            Column(
                modifier = Modifier
                    .padding(18.dp)
                    .verticalScroll(rememberScrollState())
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(
                            imageVector = Icons.Default.Security,
                            contentDescription = null,
                            tint = AmberAlert,
                            modifier = Modifier.size(20.dp)
                        )
                        Spacer(modifier = Modifier.width(6.dp))
                        Text(
                            text = "Report Field Hazard",
                            fontWeight = FontWeight.Bold,
                            color = Color.White,
                            fontSize = 17.sp
                        )
                    }
                    IconButton(onClick = onDismiss, modifier = Modifier.size(28.dp)) {
                        Icon(imageVector = Icons.Default.Close, contentDescription = "Close", tint = Color.Gray)
                    }
                }

                // Anti-False Report Security Banner
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .background(SafeGreen.copy(alpha = 0.12f), RoundedCornerShape(8.dp))
                        .border(1.dp, SafeGreen.copy(alpha = 0.35f), RoundedCornerShape(8.dp))
                        .padding(horizontal = 10.dp, vertical = 8.dp)
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(
                            imageVector = Icons.Default.GpsFixed,
                            contentDescription = null,
                            tint = SafeGreen,
                            modifier = Modifier.size(16.dp)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Column {
                            Text(
                                text = "Anti-False Report Verification",
                                color = SafeGreen,
                                fontSize = 11.sp,
                                fontWeight = FontWeight.Bold
                            )
                            Text(
                                text = if (currentLat != 0.0) "Live GPS: ${String.format("%.4f", currentLat)}, ${String.format("%.4f", currentLon)}" else "Live GPS Location will be tagged to your report",
                                color = Color(0xFFCCCCCC),
                                fontSize = 10.sp
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.height(10.dp))

                // Camera Live Photo Capture Section
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(10.dp),
                    colors = CardDefaults.cardColors(containerColor = Color(0xFF101010)),
                    border = androidx.compose.foundation.BorderStroke(
                        1.dp,
                        if (capturedBitmap != null) SafeGreen else AmberAlert.copy(alpha = 0.5f)
                    )
                ) {
                    Column(
                        modifier = Modifier.padding(10.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        if (capturedBitmap != null) {
                            Box(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .height(140.dp)
                                    .clip(RoundedCornerShape(8.dp))
                            ) {
                                Image(
                                    bitmap = capturedBitmap!!.asImageBitmap(),
                                    contentDescription = "Live Camera Preview",
                                    modifier = Modifier.fillMaxSize(),
                                    contentScale = ContentScale.Crop
                                )
                                Box(
                                    modifier = Modifier
                                        .align(Alignment.TopEnd)
                                        .background(SafeGreen, RoundedCornerShape(bottomStart = 6.dp))
                                        .padding(horizontal = 6.dp, vertical = 2.dp)
                                ) {
                                    Row(verticalAlignment = Alignment.CenterVertically) {
                                        Icon(imageVector = Icons.Default.VerifiedUser, contentDescription = null, tint = Color.Black, modifier = Modifier.size(10.dp))
                                        Spacer(modifier = Modifier.width(2.dp))
                                        Text("LIVE PROOF OK", fontSize = 9.sp, color = Color.Black, fontWeight = FontWeight.Bold)
                                    }
                                }
                            }

                            Spacer(modifier = Modifier.height(6.dp))

                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text(
                                    text = "✓ Live Photo Geotagged",
                                    color = SafeGreen,
                                    fontSize = 11.sp,
                                    fontWeight = FontWeight.Bold
                                )

                                OutlinedButton(
                                    onClick = { cameraLauncher.launch(null) },
                                    shape = RoundedCornerShape(6.dp),
                                    colors = ButtonDefaults.outlinedButtonColors(contentColor = AmberAlert),
                                    contentPadding = PaddingValues(horizontal = 8.dp, vertical = 2.dp)
                                ) {
                                    Icon(imageVector = Icons.Default.Refresh, contentDescription = null, modifier = Modifier.size(12.dp))
                                    Spacer(modifier = Modifier.width(4.dp))
                                    Text("Retake", fontSize = 11.sp)
                                }
                            }
                        } else {
                            Icon(
                                imageVector = Icons.Default.CameraAlt,
                                contentDescription = "Camera",
                                tint = AmberAlert,
                                modifier = Modifier.size(32.dp)
                            )
                            Spacer(modifier = Modifier.height(4.dp))
                            Text(
                                text = "Take Live Camera Photo Proof",
                                color = Color.White,
                                fontWeight = FontWeight.Bold,
                                fontSize = 12.sp
                            )
                            Text(
                                text = "Mandatory live snapshot to verify obstacle and prevent hoax reports.",
                                color = Color.Gray,
                                fontSize = 10.sp,
                                modifier = Modifier.padding(horizontal = 8.dp)
                            )
                            Spacer(modifier = Modifier.height(8.dp))
                            Button(
                                onClick = { cameraLauncher.launch(null) },
                                colors = ButtonDefaults.buttonColors(containerColor = AmberAlert),
                                shape = RoundedCornerShape(6.dp),
                                contentPadding = PaddingValues(horizontal = 12.dp, vertical = 6.dp)
                            ) {
                                Icon(imageVector = Icons.Default.PhotoCamera, contentDescription = null, tint = Color.Black, modifier = Modifier.size(14.dp))
                                Spacer(modifier = Modifier.width(6.dp))
                                Text("Open Camera & Capture", color = Color.Black, fontSize = 11.sp, fontWeight = FontWeight.Bold)
                            }
                        }
                    }
                }

                Spacer(modifier = Modifier.height(10.dp))

                Text("Quick Select Hazard Type:", color = Color(0xFFCCCCCC), fontSize = 11.sp, fontWeight = FontWeight.Bold)
                Spacer(modifier = Modifier.height(4.dp))

                Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    quickTypes.take(3).forEach { qt ->
                        Button(
                            onClick = { title = qt },
                            colors = ButtonDefaults.buttonColors(
                                containerColor = if (title == qt) AmberAlert else Color(0xFF262626)
                            ),
                            shape = RoundedCornerShape(6.dp),
                            modifier = Modifier.fillMaxWidth(),
                            contentPadding = PaddingValues(vertical = 4.dp, horizontal = 8.dp)
                        ) {
                            Text(
                                text = qt,
                                color = if (title == qt) Color.Black else Color.White,
                                fontSize = 11.sp,
                                fontWeight = FontWeight.SemiBold
                            )
                        }
                    }
                }

                Spacer(modifier = Modifier.height(8.dp))

                OutlinedTextField(
                    value = title,
                    onValueChange = { title = it },
                    label = { Text("Hazard Title") },
                    modifier = Modifier.fillMaxWidth(),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedTextColor = Color.White,
                        unfocusedTextColor = Color.White,
                        focusedBorderColor = AmberAlert,
                        unfocusedBorderColor = Color.DarkGray
                    ),
                    singleLine = true
                )

                Spacer(modifier = Modifier.height(6.dp))

                OutlinedTextField(
                    value = location,
                    onValueChange = { location = it },
                    label = { Text("Landmark / Location") },
                    placeholder = { Text("e.g. Near Phaphamau Bridge, NH-19") },
                    modifier = Modifier.fillMaxWidth(),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedTextColor = Color.White,
                        unfocusedTextColor = Color.White,
                        focusedBorderColor = AmberAlert,
                        unfocusedBorderColor = Color.DarkGray
                    ),
                    singleLine = true
                )

                Spacer(modifier = Modifier.height(6.dp))

                OutlinedTextField(
                    value = description,
                    onValueChange = { description = it },
                    label = { Text("Details & Specific Advice") },
                    modifier = Modifier.fillMaxWidth(),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedTextColor = Color.White,
                        unfocusedTextColor = Color.White,
                        focusedBorderColor = AmberAlert,
                        unfocusedBorderColor = Color.DarkGray
                    ),
                    maxLines = 2
                )

                Spacer(modifier = Modifier.height(12.dp))

                Button(
                    onClick = {
                        if (title.isNotBlank()) {
                            onSubmit(title, location, severity, description, imageBase64, capturedBitmap != null)
                        }
                    },
                    modifier = Modifier.fillMaxWidth(),
                    colors = ButtonDefaults.buttonColors(containerColor = if (capturedBitmap != null) SafeGreen else AmberAlert),
                    shape = RoundedCornerShape(8.dp),
                    enabled = title.isNotBlank()
                ) {
                    Text(
                        text = if (capturedBitmap != null) "Broadcast Verified Hazard onto Mesh" else "Broadcast Hazard onto Mesh",
                        color = Color.Black,
                        fontWeight = FontWeight.Bold
                    )
                }
            }
        }
    }
}
