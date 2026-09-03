package com.project.garuda.ui.chat

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.horizontalScroll
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
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CellTower
import androidx.compose.material.icons.filled.Send
import androidx.compose.material.icons.filled.WifiOff
import androidx.compose.material3.AssistChip
import androidx.compose.material3.AssistChipDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.project.garuda.ui.theme.AmoledBlack
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

data class MeshChatMessage(
    val id: String,
    val senderName: String,
    val senderRole: String, // "Citizen", "Volunteer", "Medical Aid", "NDRF"
    val text: String,
    val timestamp: String,
    val hopCount: Int,
    val isFromMe: Boolean
)

@Composable
fun MeshChatScreen(
    peersCount: Int = 6,
    onSendMessage: (String) -> Unit = {}
) {
    val messages = remember {
        mutableStateListOf(
            MeshChatMessage(
                id = "1",
                senderName = "SDRF Control Relay",
                senderRole = "NDRF",
                text = "NDRF teams deployed in Sector 4 & 7. Stay in open elevated grounds.",
                timestamp = "10:14 AM",
                hopCount = 2,
                isFromMe = false
            ),
            MeshChatMessage(
                id = "2",
                senderName = "Volunteer Alpha",
                senderRole = "Volunteer",
                text = "Community center shelter has clean drinking water & power generator running.",
                timestamp = "10:18 AM",
                hopCount = 1,
                isFromMe = false
            ),
            MeshChatMessage(
                id = "3",
                senderName = "Citizen (Node #9102)",
                senderRole = "Citizen",
                text = "Underpass on Ring Road is flooded with 4ft water. Do not cross.",
                timestamp = "10:22 AM",
                hopCount = 1,
                isFromMe = false
            )
        )
    }

    var inputText by remember { mutableStateOf("") }

    val quickPhrases = listOf(
        "Need Clean Drinking Water",
        "Need First Aid / Medical Kit",
        "Shelter is Full Here",
        "We are Safe and Sheltered",
        "Road Blocked by Debris"
    )

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(AmoledBlack)
            .padding(16.dp)
    ) {
        // Top Header
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column {
                Text(
                    text = "Mesh Walkie-Talkie",
                    fontSize = 22.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color.White
                )
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Box(
                        modifier = Modifier
                            .size(8.dp)
                            .background(Color(0xFF00E5FF), CircleShape)
                    )
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(
                        text = "2.4GHz BLE Mesh • $peersCount Nearby Nodes",
                        fontSize = 12.sp,
                        color = Color(0xFF00E5FF),
                        fontWeight = FontWeight.SemiBold
                    )
                }
            }

            Card(
                colors = CardDefaults.cardColors(containerColor = Color(0xFF141E28)),
                shape = RoundedCornerShape(8.dp),
                border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFF00E5FF).copy(alpha = 0.3f))
            ) {
                Row(
                    modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.Default.WifiOff,
                        contentDescription = "Offline",
                        tint = Color(0xFF00E5FF),
                        modifier = Modifier.size(14.dp)
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(
                        text = "Zero Internet",
                        fontSize = 11.sp,
                        color = Color(0xFF00E5FF),
                        fontWeight = FontWeight.Medium
                    )
                }
            }
        }

        Spacer(modifier = Modifier.height(12.dp))

        // Quick Phrases Bar
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .horizontalScroll(rememberScrollState()),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            quickPhrases.forEach { phrase ->
                AssistChip(
                    onClick = {
                        val timeStr = SimpleDateFormat("h:mm a", Locale.getDefault()).format(Date())
                        messages.add(
                            MeshChatMessage(
                                id = System.currentTimeMillis().toString(),
                                senderName = "You (Node #Local)",
                                senderRole = "Citizen",
                                text = phrase,
                                timestamp = timeStr,
                                hopCount = 0,
                                isFromMe = true
                            )
                        )
                        onSendMessage(phrase)
                    },
                    label = { Text(phrase, fontSize = 11.sp, color = Color(0xFFCCCCCC)) },
                    colors = AssistChipDefaults.assistChipColors(
                        containerColor = Color(0xFF161616)
                    ),
                    border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFF2E2E2E))
                )
            }
        }

        Spacer(modifier = Modifier.height(12.dp))

        // Message List
        LazyColumn(
            modifier = Modifier
                .weight(1f)
                .fillMaxWidth(),
            verticalArrangement = Arrangement.spacedBy(10.dp),
            contentPadding = PaddingValues(vertical = 4.dp)
        ) {
            items(messages, key = { it.id }) { msg ->
                MessageBubble(msg)
            }
        }

        Spacer(modifier = Modifier.height(8.dp))

        // Message Input Row
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            OutlinedTextField(
                value = inputText,
                onValueChange = { inputText = it },
                modifier = Modifier.weight(1f),
                placeholder = { Text("Broadcast message to nearby nodes...", color = Color.Gray, fontSize = 13.sp) },
                shape = RoundedCornerShape(24.dp),
                colors = OutlinedTextFieldDefaults.colors(
                    focusedContainerColor = Color(0xFF121212),
                    unfocusedContainerColor = Color(0xFF121212),
                    focusedBorderColor = Color(0xFF00E5FF),
                    unfocusedBorderColor = Color(0xFF262626),
                    focusedTextColor = Color.White,
                    unfocusedTextColor = Color.White
                ),
                maxLines = 3
            )

            Spacer(modifier = Modifier.width(8.dp))

            IconButton(
                onClick = {
                    if (inputText.isNotBlank()) {
                        val timeStr = SimpleDateFormat("h:mm a", Locale.getDefault()).format(Date())
                        messages.add(
                            MeshChatMessage(
                                id = System.currentTimeMillis().toString(),
                                senderName = "You (Node #Local)",
                                senderRole = "Citizen",
                                text = inputText.trim(),
                                timestamp = timeStr,
                                hopCount = 0,
                                isFromMe = true
                            )
                        )
                        onSendMessage(inputText.trim())
                        inputText = ""
                    }
                },
                modifier = Modifier
                    .size(48.dp)
                    .background(Color(0xFF00E5FF), CircleShape)
            ) {
                Icon(
                    imageVector = Icons.Default.Send,
                    contentDescription = "Broadcast",
                    tint = Color.Black,
                    modifier = Modifier.size(20.dp)
                )
            }
        }
    }
}

@Composable
private fun MessageBubble(msg: MeshChatMessage) {
    val roleColor = when (msg.senderRole) {
        "NDRF" -> Color(0xFFE53935)
        "Volunteer" -> Color(0xFF00E5FF)
        "Medical Aid" -> Color(0xFF43A047)
        else -> Color(0xFFFFB300)
    }

    val bubbleBg = if (msg.isFromMe) Color(0xFF1B2C3B) else Color(0xFF171717)
    val alignment = if (msg.isFromMe) Alignment.End else Alignment.Start

    Column(
        modifier = Modifier.fillMaxWidth(),
        horizontalAlignment = alignment
    ) {
        Card(
            shape = RoundedCornerShape(14.dp),
            colors = CardDefaults.cardColors(containerColor = bubbleBg),
            border = androidx.compose.foundation.BorderStroke(
                1.dp,
                if (msg.isFromMe) Color(0xFF00E5FF).copy(alpha = 0.4f) else Color(0xFF242424)
            )
        ) {
            Column(modifier = Modifier.padding(12.dp)) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    Text(
                        text = msg.senderName,
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color.White
                    )

                    Box(
                        modifier = Modifier
                            .background(roleColor.copy(alpha = 0.2f), RoundedCornerShape(4.dp))
                            .padding(horizontal = 5.dp, vertical = 2.dp)
                    ) {
                        Text(
                            text = msg.senderRole,
                            fontSize = 9.sp,
                            fontWeight = FontWeight.Bold,
                            color = roleColor
                        )
                    }

                    Spacer(modifier = Modifier.weight(1f))

                    Text(
                        text = if (msg.hopCount == 0) "Direct" else "${msg.hopCount} hops",
                        fontSize = 10.sp,
                        color = Color.Gray
                    )
                }

                Spacer(modifier = Modifier.height(6.dp))

                Text(
                    text = msg.text,
                    fontSize = 14.sp,
                    color = Color(0xFFE0E0E0),
                    lineHeight = 18.sp
                )

                Spacer(modifier = Modifier.height(4.dp))

                Text(
                    text = msg.timestamp,
                    fontSize = 10.sp,
                    color = Color.Gray,
                    modifier = Modifier.align(Alignment.End)
                )
            }
        }
    }
}
