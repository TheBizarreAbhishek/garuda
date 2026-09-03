package com.project.garuda.ui.navigation

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Campaign
import androidx.compose.material.icons.filled.Forum
import androidx.compose.material.icons.filled.Shield
import androidx.compose.material.icons.filled.Warning
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import com.project.garuda.ui.theme.AmberAlert
import com.project.garuda.ui.theme.EmergencyRed
import com.project.garuda.ui.theme.SafeGreen

enum class GarudaTab(
    val title: String,
    val icon: ImageVector,
    val activeColor: Color,
    val badgeCount: Int = 0
) {
    SOS(
        title = "Emergency",
        icon = Icons.Default.Warning,
        activeColor = EmergencyRed
    ),
    CHAT(
        title = "Mesh Chat",
        icon = Icons.Default.Forum,
        activeColor = Color(0xFF00E5FF)
    ),
    SHELTERS(
        title = "Shelters",
        icon = Icons.Default.Shield,
        activeColor = SafeGreen
    ),
    HAZARDS(
        title = "Hazards",
        icon = Icons.Default.Campaign,
        activeColor = AmberAlert
    )
}
