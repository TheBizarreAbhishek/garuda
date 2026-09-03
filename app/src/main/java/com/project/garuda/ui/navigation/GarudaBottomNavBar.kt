package com.project.garuda.ui.navigation

import androidx.compose.animation.animateColorAsState
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Badge
import androidx.compose.material3.BadgedBox
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.project.garuda.ui.theme.AmoledBlack

@Composable
fun GarudaBottomNavBar(
    selectedTab: GarudaTab,
    onTabSelected: (GarudaTab) -> Unit,
    isEmergencyActive: Boolean = false,
    modifier: Modifier = Modifier
) {
    NavigationBar(
        modifier = modifier
            .fillMaxWidth()
            .height(82.dp)
            .border(
                width = 1.dp,
                color = Color(0xFF1E1E1E),
                shape = RoundedCornerShape(topStart = 16.dp, topEnd = 16.dp)
            )
            .clip(RoundedCornerShape(topStart = 16.dp, topEnd = 16.dp)),
        containerColor = Color(0xFF0C0C0C),
        tonalElevation = 12.dp
    ) {
        GarudaTab.values().forEach { tab ->
            val isSelected = tab == selectedTab
            val iconColor by animateColorAsState(
                targetValue = if (isSelected) tab.activeColor else Color(0xFF888888),
                label = "tab_icon_color"
            )

            NavigationBarItem(
                selected = isSelected,
                onClick = { onTabSelected(tab) },
                icon = {
                    BadgedBox(
                        badge = {
                            if (tab == GarudaTab.SOS && isEmergencyActive) {
                                Badge(
                                    containerColor = Color(0xFFE53935),
                                    modifier = Modifier.size(8.dp)
                                )
                            }
                        }
                    ) {
                        Icon(
                            imageVector = tab.icon,
                            contentDescription = tab.title,
                            tint = iconColor,
                            modifier = Modifier.size(24.dp)
                        )
                    }
                },
                label = {
                    Text(
                        text = tab.title,
                        color = iconColor,
                        fontSize = 11.sp,
                        fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium
                    )
                },
                colors = NavigationBarItemDefaults.colors(
                    selectedIconColor = tab.activeColor,
                    selectedTextColor = tab.activeColor,
                    indicatorColor = tab.activeColor.copy(alpha = 0.15f),
                    unselectedIconColor = Color(0xFF888888),
                    unselectedTextColor = Color(0xFF888888)
                )
            )
        }
    }
}
