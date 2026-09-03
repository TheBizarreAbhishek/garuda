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
    val distanceMeters: Int,
    val bearingDegrees: Float,
    val capacityCurrent: Int,
    val capacityMax: Int,
    val hasMedical: Boolean,
    val hasWater: Boolean,
    val hasPower: Boolean,
    val statusText: String
)

@Composable
fun ShelterRadarScreen(
    onNavigateToShelter: (ReliefShelter) -> Unit = {}
) {
    val shelters = listOf(
        ReliefShelter(
            id = "1",
            name = "Community Hall Relief Camp Sector 4",
            distanceMeters = 650,
            bearingDegrees = 42f,
            capacityCurrent = 142,
            capacityMax = 300,
            hasMedical = true,
            hasWater = true,
            hasPower = true,
            statusText = "Open • 158 Spots Available"
        ),
        ReliefShelter(
            id = "2",
            name = "Government High School Multi-Purpose Hall",
            distanceMeters = 1200,
            bearingDegrees = 115f,
            capacityCurrent = 390,
            capacityMax = 450,
            hasMedical = true,
            hasWater = true,
            hasPower = false,
            statusText = "Open • Near Capacity"
        ),
        ReliefShelter(
            id = "3",
            name = "District Indoor Stadium Evacuation Hub",
            distanceMeters = 2400,
            bearingDegrees = 270f,
            capacityCurrent = 520,
            capacityMax = 1200,
            hasMedical = true,
            hasWater = true,
            hasPower = true,
            statusText = "Open • Helipad & Trauma Center"
        )
    )

    val closest = shelters.first()

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
            text = "GPS Compass Bearing • Cached Offline Map Data",
            fontSize = 12.sp,
            color = SafeGreen,
            fontWeight = FontWeight.SemiBold
        )

        Spacer(modifier = Modifier.height(14.dp))

        // Big Radar Compass Card for Nearest Shelter
        RadarCompassCard(shelter = closest)

        Spacer(modifier = Modifier.height(16.dp))

        Text(
            text = "Available Relief Shelters Nearby",
            fontSize = 15.sp,
            fontWeight = FontWeight.Bold,
            color = Color(0xFFDDDDDD)
        )

        Spacer(modifier = Modifier.height(8.dp))

        LazyColumn(
            modifier = Modifier.fillMaxWidth(),
            verticalArrangement = Arrangement.spacedBy(10.dp),
            contentPadding = PaddingValues(bottom = 8.dp)
        ) {
            items(shelters, key = { it.id }) { shelter ->
                ShelterItemCard(shelter = shelter)
            }
        }
    }
}

@Composable
private fun RadarCompassCard(shelter: ReliefShelter) {
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
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
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
                        text = "${shelter.distanceMeters}m away",
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
                    text = "Heading: 42° North-East • ~8 min walk",
                    fontSize = 11.sp,
                    color = Color(0xFFB0BEC5)
                )
            }
        }
    }
}

@Composable
private fun ShelterItemCard(shelter: ReliefShelter) {
    val occupancyFraction = shelter.capacityCurrent.toFloat() / shelter.capacityMax.toFloat()

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
                    text = if (shelter.distanceMeters >= 1000) "${shelter.distanceMeters / 1000.0}km" else "${shelter.distanceMeters}m",
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
