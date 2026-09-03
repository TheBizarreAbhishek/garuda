package com.project.garuda.ui.hazards

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
import androidx.compose.material.icons.filled.AddAlert
import androidx.compose.material.icons.filled.Campaign
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Dangerous
import androidx.compose.material.icons.filled.PersonSearch
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.Tab
import androidx.compose.material3.TabRow
import androidx.compose.material3.TabRowDefaults
import androidx.compose.material3.TabRowDefaults.tabIndicatorOffset
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.project.garuda.ui.theme.AmberAlert
import com.project.garuda.ui.theme.AmoledBlack
import com.project.garuda.ui.theme.EmergencyRed

data class HazardAlert(
    val id: String,
    val title: String,
    val location: String,
    val distanceMeters: Int,
    val severity: String, // "CRITICAL", "HIGH", "MODERATE"
    val reportedAgo: String,
    val confirmationCount: Int
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
    onReportHazardClick: () -> Unit = {}
) {
    var selectedSubTab by remember { mutableIntStateOf(0) }

    val hazards = listOf(
        HazardAlert(
            id = "1",
            title = "Collapsed Flyover Pillar & Debris",
            location = "Old Airport Road Junction",
            distanceMeters = 400,
            severity = "CRITICAL",
            reportedAgo = "12m ago",
            confirmationCount = 5
        ),
        HazardAlert(
            id = "2",
            title = "Severe Waterlogging (4-5 ft depth)",
            location = "Central Railway Underpass",
            distanceMeters = 850,
            severity = "HIGH",
            reportedAgo = "25m ago",
            confirmationCount = 8
        ),
        HazardAlert(
            id = "3",
            title = "Live High-Voltage Downed Cable",
            location = "Behind Market Complex St 11",
            distanceMeters = 1400,
            severity = "CRITICAL",
            reportedAgo = "40m ago",
            confirmationCount = 12
        )
    )

    val missingList = listOf(
        MissingPerson(
            id = "1",
            name = "Aarav Sharma",
            age = 8,
            lastSeenLocation = "Sector 3 Primary School during evacuation",
            lastSeenTime = "Today, 9:30 AM",
            contactPhone = "+91 98111 22334"
        ),
        MissingPerson(
            id = "2",
            name = "Kavita Devi",
            age = 67,
            lastSeenLocation = "Near Riverbank Market area",
            lastSeenTime = "Today, 8:45 AM",
            contactPhone = "+91 98450 67890"
        )
    )

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
                    text = "Mesh-Crowdsourced Field Reports",
                    fontSize = 12.sp,
                    color = AmberAlert,
                    fontWeight = FontWeight.SemiBold
                )
            }

            Button(
                onClick = onReportHazardClick,
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
                Text("Report", color = Color.Black, fontSize = 12.sp, fontWeight = FontWeight.Bold)
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
                text = { Text("Active Hazards (${hazards.size})", fontWeight = FontWeight.Bold) }
            )
            Tab(
                selected = selectedSubTab == 1,
                onClick = { selectedSubTab = 1 },
                text = { Text("Missing Bulletin (${missingList.size})", fontWeight = FontWeight.Bold) }
            )
        }

        Spacer(modifier = Modifier.height(12.dp))

        if (selectedSubTab == 0) {
            LazyColumn(
                modifier = Modifier.fillMaxWidth(),
                verticalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                items(hazards, key = { it.id }) { hazard ->
                    HazardCard(hazard)
                }
            }
        } else {
            LazyColumn(
                modifier = Modifier.fillMaxWidth(),
                verticalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                items(missingList, key = { it.id }) { person ->
                    MissingPersonCard(person)
                }
            }
        }
    }
}

@Composable
private fun HazardCard(hazard: HazardAlert) {
    val severityColor = when (hazard.severity) {
        "CRITICAL" -> EmergencyRed
        "HIGH" -> AmberAlert
        else -> Color(0xFFFFCC80)
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

                Text(
                    text = "${hazard.distanceMeters}m away • ${hazard.reportedAgo}",
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

            Spacer(modifier = Modifier.height(8.dp))

            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    imageVector = Icons.Default.CheckCircle,
                    contentDescription = null,
                    tint = Color(0xFF00E5FF),
                    modifier = Modifier.size(13.dp)
                )
                Spacer(modifier = Modifier.width(4.dp))
                Text(
                    text = "${hazard.confirmationCount} nearby mesh peer confirmations",
                    fontSize = 11.sp,
                    color = Color(0xFF00E5FF)
                )
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
