package com.project.garuda.ui.shelter

import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ElectricBolt
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.LocalHospital
import androidx.compose.material.icons.filled.Navigation
import androidx.compose.material.icons.filled.NearMe
import androidx.compose.material.icons.filled.WaterDrop
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.project.garuda.ui.theme.AmoledBlack
import com.project.garuda.ui.theme.SafeGreen

data class ReliefShelter(
    val id: String,
    val name: String,
    val latitude: Double = 0.0,
    val longitude: Double = 0.0,
    val distanceMeters: Int = 0,
    val bearingDegrees: Float = 0f,
    val capacityCurrent: Int = 0,
    val capacityMax: Int = 100,
    val hasMedical: Boolean = true,
    val hasWater: Boolean = true,
    val hasPower: Boolean = true,
    val statusText: String = "Open",
    val phone: String = "112"
)

@Composable
fun ShelterRadarScreen(
    shelters: List<ReliefShelter> = emptyList(),
    onNavigateToShelter: (ReliefShelter) -> Unit = {},
    onCallShelter: (ReliefShelter) -> Unit = {}
) {
    val closest = shelters.firstOrNull()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(AmoledBlack)
            .padding(16.dp)
    ) {
        Text(
            text = "Offline Shelter Radar",
            fontSize = 22.sp,
            fontWeight = FontWeight.Bold,
            color = Color.White
        )
        Text(
            text = "Real GPS Compass Bearing • Live District Tracker (50km)",
            fontSize = 12.sp,
            color = SafeGreen,
            fontWeight = FontWeight.SemiBold
        )

        Spacer(modifier = Modifier.height(14.dp))

        if (closest == null) {
            // Clean Empty State when no shelters are in the 50km radius
            Box(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth(),
                contentAlignment = Alignment.Center
            ) {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(16.dp),
                    colors = CardDefaults.cardColors(containerColor = Color(0xFF121814)),
                    border = androidx.compose.foundation.BorderStroke(1.dp, SafeGreen.copy(alpha = 0.3f))
                ) {
                    Column(
                        modifier = Modifier.padding(24.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Box(
                            modifier = Modifier
                                .size(64.dp)
                                .background(SafeGreen.copy(alpha = 0.15f), CircleShape),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(
                                imageVector = Icons.Default.LocationOn,
                                contentDescription = null,
                                tint = SafeGreen,
                                modifier = Modifier.size(36.dp)
                            )
                        }

                        Spacer(modifier = Modifier.height(14.dp))

                        Text(
                            text = "No Relief Camps in Immediate Sector",
                            fontWeight = FontWeight.Bold,
                            color = Color.White,
                            fontSize = 16.sp,
                            textAlign = androidx.compose.ui.text.style.TextAlign.Center
                        )

                        Spacer(modifier = Modifier.height(6.dp))

                        Text(
                            text = "Only relief shelters within your 50km district perimeter appear on this radar. When the Command Center or NDRF deploys a camp nearby, it will sync automatically over Mesh / Cloud.",
                            color = Color.Gray,
                            fontSize = 12.sp,
                            textAlign = androidx.compose.ui.text.style.TextAlign.Center
                        )

                        Spacer(modifier = Modifier.height(18.dp))

                        androidx.compose.material3.OutlinedButton(
                            onClick = { onCallShelter(ReliefShelter(id = "help", name = "Helpline", phone = "1078")) },
                            colors = androidx.compose.material3.ButtonDefaults.outlinedButtonColors(contentColor = SafeGreen),
                            shape = RoundedCornerShape(8.dp),
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Text("Call National Disaster Helpline (1078)", fontWeight = FontWeight.Bold, fontSize = 12.sp)
                        }
                    }
                }
            }
        } else {
            // Big Radar Compass Card for Nearest Shelter
            RadarCompassCard(shelter = closest, onNavigate = { onNavigateToShelter(closest) })

            Spacer(modifier = Modifier.height(16.dp))

            Text(
                text = "Available Relief Shelters Nearby (${shelters.size})",
                fontSize = 15.sp,
                fontWeight = FontWeight.Bold,
                color = Color(0xFFDDDDDD)
            )

            Spacer(modifier = Modifier.height(8.dp))

            LazyColumn(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth(),
                verticalArrangement = Arrangement.spacedBy(10.dp),
                contentPadding = PaddingValues(vertical = 4.dp)
            ) {
                items(shelters, key = { it.id }) { shelter ->
                    ShelterItemCard(
                        shelter = shelter,
                        onNavigate = { onNavigateToShelter(shelter) },
                        onCall = { onCallShelter(shelter) }
                    )
                }
            }
        }
    }
}

@Composable
private fun RadarCompassCard(
    shelter: ReliefShelter,
    onNavigate: () -> Unit = {}
) {
    val infiniteTransition = rememberInfiniteTransition(label = "pulse")
    val pulseAlpha by infiniteTransition.animateFloat(
        initialValue = 0.2f,
        targetValue = 0.5f,
        animationSpec = infiniteRepeatable(
            animation = tween(1200, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "radar_pulse"
    )

    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = Color(0xFF0F1E14)),
        border = androidx.compose.foundation.BorderStroke(1.dp, SafeGreen.copy(alpha = 0.4f))
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                // Animated Radar Compass Dial
                Box(
                    modifier = Modifier
                        .size(72.dp)
                        .background(SafeGreen.copy(alpha = pulseAlpha), CircleShape)
                        .border(2.dp, SafeGreen, CircleShape),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = Icons.Default.Navigation,
                        contentDescription = "Bearing",
                        tint = SafeGreen,
                        modifier = Modifier
                            .size(36.dp)
                            .rotate(shelter.bearingDegrees)
                    )
                }

                Spacer(modifier = Modifier.width(16.dp))

                Column(modifier = Modifier.weight(1f)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Box(
                            modifier = Modifier
                                .background(SafeGreen.copy(alpha = 0.2f), RoundedCornerShape(4.dp))
                                .padding(horizontal = 6.dp, vertical = 2.dp)
                        ) {
                            Text(
                                text = "NEAREST SHELTER",
                                fontSize = 9.sp,
                                fontWeight = FontWeight.Bold,
                                color = SafeGreen
                            )
                        }
                        Spacer(modifier = Modifier.width(6.dp))
                        Text(
                            text = if (shelter.distanceMeters >= 1000) "${String.format("%.1f", shelter.distanceMeters / 1000.0)}km away" else "${shelter.distanceMeters}m away",
                            fontSize = 12.sp,
                            color = Color.White,
                            fontWeight = FontWeight.Bold
                        )
                    }

                    Spacer(modifier = Modifier.height(4.dp))

                    Text(
                        text = shelter.name,
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color.White,
                        maxLines = 1
                    )

                    Text(
                        text = "Heading: ${shelter.bearingDegrees.toInt()}° Compass • ~${(shelter.distanceMeters / 80).coerceAtLeast(1)} min walk",
                        fontSize = 11.sp,
                        color = Color(0xFFB0BEC5)
                    )
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            androidx.compose.material3.Button(
                onClick = onNavigate,
                modifier = Modifier.fillMaxWidth(),
                colors = androidx.compose.material3.ButtonDefaults.buttonColors(containerColor = SafeGreen),
                shape = RoundedCornerShape(8.dp)
            ) {
                Icon(
                    imageVector = Icons.Default.NearMe,
                    contentDescription = null,
                    tint = Color.Black,
                    modifier = Modifier.size(16.dp)
                )
                Spacer(modifier = Modifier.width(6.dp))
                Text("Start Walking GPS Navigation", color = Color.Black, fontWeight = FontWeight.Bold, fontSize = 13.sp)
            }
        }
    }
}

@Composable
private fun ShelterItemCard(
    shelter: ReliefShelter,
    onNavigate: () -> Unit = {},
    onCall: () -> Unit = {}
) {
    val occupancyFraction = (shelter.capacityCurrent.toFloat() / shelter.capacityMax.toFloat().coerceAtLeast(1f)).coerceIn(0f, 1f)

    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = Color(0xFF141414)),
        border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFF262626))
    ) {
        Column(modifier = Modifier.padding(14.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = shelter.name,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color.White,
                    modifier = Modifier.weight(1f)
                )

                Text(
                    text = if (shelter.distanceMeters >= 1000) "${String.format("%.1f", shelter.distanceMeters / 1000.0)}km" else "${shelter.distanceMeters}m",
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Bold,
                    color = SafeGreen
                )
            }

            Spacer(modifier = Modifier.height(6.dp))

            // Resource badges
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                if (shelter.hasMedical) {
                    ResourcePill(icon = Icons.Default.LocalHospital, text = "Medical Tent", color = Color(0xFFE53935))
                }
                if (shelter.hasWater) {
                    ResourcePill(icon = Icons.Default.WaterDrop, text = "Clean Water", color = Color(0xFF00E5FF))
                }
                if (shelter.hasPower) {
                    ResourcePill(icon = Icons.Default.ElectricBolt, text = "Generator", color = Color(0xFFFFB300))
                }
            }

            Spacer(modifier = Modifier.height(10.dp))

            // Capacity progress
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    text = "Occupancy: ${shelter.capacityCurrent} / ${shelter.capacityMax}",
                    fontSize = 11.sp,
                    color = Color.Gray
                )
                Text(
                    text = shelter.statusText,
                    fontSize = 11.sp,
                    color = SafeGreen,
                    fontWeight = FontWeight.SemiBold
                )
            }

            Spacer(modifier = Modifier.height(4.dp))

            LinearProgressIndicator(
                progress = { occupancyFraction },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(6.dp),
                color = if (occupancyFraction > 0.85f) Color(0xFFE53935) else SafeGreen,
                trackColor = Color(0xFF222222)
            )

            Spacer(modifier = Modifier.height(10.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                androidx.compose.material3.OutlinedButton(
                    onClick = onCall,
                    modifier = Modifier.weight(1f),
                    shape = RoundedCornerShape(8.dp),
                    contentPadding = PaddingValues(vertical = 4.dp)
                ) {
                    Text("📞 Call Helpline", fontSize = 11.sp, color = SafeGreen)
                }

                androidx.compose.material3.Button(
                    onClick = onNavigate,
                    modifier = Modifier.weight(1f),
                    shape = RoundedCornerShape(8.dp),
                    colors = androidx.compose.material3.ButtonDefaults.buttonColors(containerColor = SafeGreen),
                    contentPadding = PaddingValues(vertical = 4.dp)
                ) {
                    Text("🗺️ Navigate", fontSize = 11.sp, color = Color.Black, fontWeight = FontWeight.Bold)
                }
            }
        }
    }
}

@Composable
private fun ResourcePill(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    text: String,
    color: Color
) {
    Row(
        modifier = Modifier
            .background(color.copy(alpha = 0.15f), RoundedCornerShape(4.dp))
            .padding(horizontal = 6.dp, vertical = 2.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = color,
            modifier = Modifier.size(11.dp)
        )
        Spacer(modifier = Modifier.width(3.dp))
        Text(
            text = text,
            fontSize = 9.sp,
            color = color,
            fontWeight = FontWeight.Bold
        )
    }
}
