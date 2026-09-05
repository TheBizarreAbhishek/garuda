package com.project.garuda.ui.chat

import android.widget.Toast
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
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
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.CellTower
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material.icons.filled.GraphicEq
import androidx.compose.material.icons.filled.Mic
import androidx.compose.material.icons.filled.Pause
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Send
import androidx.compose.material.icons.filled.Stop
import androidx.compose.material.icons.filled.WifiOff
import androidx.compose.material3.AssistChip
import androidx.compose.material3.AssistChipDefaults
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
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
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import com.project.garuda.audio.WalkieTalkieAudioManager
import com.project.garuda.data.PrivateMeshContact
import com.project.garuda.ui.theme.AmberAlert
import com.project.garuda.ui.theme.AmoledBlack
import com.project.garuda.ui.theme.EmergencyRed
import com.project.garuda.ui.theme.SafeGreen

data class MeshChatMessage(
    val id: String,
    val senderName: String,
    val senderId: String = "",
    val targetId: String = "", // empty = Public Broadcast, non-empty = Private Direct
    val senderRole: String = "Citizen",
    val text: String,
    val audioBase64: String? = null,
    val audioDurationSec: Int = 0,
    val timestamp: String,
    val hopCount: Int = 0,
    val isFromMe: Boolean = false,
    val isVoiceMessage: Boolean = false
)

@Composable
fun MeshChatScreen(
    messages: List<MeshChatMessage> = emptyList(),
    peersCount: Int = 0,
    myDeviceId: String = "GD-NODE",
    privateContacts: List<PrivateMeshContact> = emptyList(),
    onSendMessage: (text: String, targetDeviceId: String, audioBase64: String?, audioDurationSec: Int) -> Unit = { _, _, _, _ -> },
    onAddPrivateContact: (name: String, deviceId: String, relation: String) -> Unit = { _, _, _ -> }
) {
    val context = LocalContext.current
    val clipboardManager = LocalClipboardManager.current

    var selectedChatTab by remember { mutableIntStateOf(0) } // 0 = Public, 1 = Private Family
    var selectedContact by remember { mutableStateOf<PrivateMeshContact?>(null) }
    var showAddContactDialog by remember { mutableStateOf(false) }

    var inputText by remember { mutableStateOf("") }
    var isRecordingAudio by remember { mutableStateOf(false) }
    var playingMessageId by remember { mutableStateOf<String?>(null) }

    val quickPhrases = listOf(
        "Need Clean Drinking Water",
        "Need First Aid / Medical Kit",
        "Shelter is Full Here",
        "We are Safe and Sheltered",
        "Road Blocked by Debris"
    )

    // Filter messages for active tab
    val currentMessages = if (selectedChatTab == 0) {
        messages.filter { it.targetId.isEmpty() }
    } else {
        if (selectedContact != null) {
            messages.filter {
                (it.targetId.equals(selectedContact!!.deviceId, ignoreCase = true) && it.isFromMe) ||
                (it.senderId.equals(selectedContact!!.deviceId, ignoreCase = true) && !it.isFromMe)
            }
        } else {
            messages.filter { it.targetId.isNotEmpty() }
        }
    }

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
                        contentDescription = null,
                        tint = Color(0xFF00E5FF),
                        modifier = Modifier.size(14.dp)
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(
                        text = "Zero-Internet Radio",
                        fontSize = 10.sp,
                        color = Color(0xFF00E5FF),
                        fontWeight = FontWeight.Bold
                    )
                }
            }
        }

        Spacer(modifier = Modifier.height(12.dp))

        // Public vs Private Mode Tabs
        TabRow(
            selectedTabIndex = selectedChatTab,
            containerColor = Color(0xFF141414),
            contentColor = Color(0xFF00E5FF),
            indicator = { tabPositions ->
                TabRowDefaults.SecondaryIndicator(
                    modifier = Modifier.tabIndicatorOffset(tabPositions[selectedChatTab]),
                    color = if (selectedChatTab == 0) Color(0xFF00E5FF) else AmberAlert
                )
            }
        ) {
            Tab(
                selected = selectedChatTab == 0,
                onClick = { selectedChatTab = 0 },
                text = {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(imageVector = Icons.Default.CellTower, contentDescription = null, modifier = Modifier.size(14.dp))
                        Spacer(modifier = Modifier.width(6.dp))
                        Text("Public Mesh (All)", fontSize = 13.sp, fontWeight = FontWeight.Bold)
                    }
                },
                selectedContentColor = Color(0xFF00E5FF),
                unselectedContentColor = Color.Gray
            )
            Tab(
                selected = selectedChatTab == 1,
                onClick = { selectedChatTab = 1 },
                text = {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(imageVector = Icons.Default.Person, contentDescription = null, modifier = Modifier.size(14.dp))
                        Spacer(modifier = Modifier.width(6.dp))
                        Text("Private (Family Direct)", fontSize = 13.sp, fontWeight = FontWeight.Bold)
                    }
                },
                selectedContentColor = AmberAlert,
                unselectedContentColor = Color.Gray
            )
        }

        Spacer(modifier = Modifier.height(10.dp))

        if (selectedChatTab == 1) {
            // Private Mode Info Bar: Own Device ID with 1-Tap Copy
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(10.dp),
                colors = CardDefaults.cardColors(containerColor = Color(0xFF1B1A14)),
                border = androidx.compose.foundation.BorderStroke(1.dp, AmberAlert.copy(alpha = 0.4f))
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 12.dp, vertical = 8.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column {
                        Text("YOUR MESH DEVICE ID", fontSize = 10.sp, fontWeight = FontWeight.Bold, color = AmberAlert)
                        Text(myDeviceId, fontSize = 15.sp, fontWeight = FontWeight.Black, color = Color.White)
                    }

                    Button(
                        onClick = {
                            clipboardManager.setText(AnnotatedString(myDeviceId))
                            Toast.makeText(context, "Copied $myDeviceId to clipboard!", Toast.LENGTH_SHORT).show()
                        },
                        colors = ButtonDefaults.buttonColors(containerColor = AmberAlert),
                        contentPadding = PaddingValues(horizontal = 10.dp, vertical = 4.dp),
                        shape = RoundedCornerShape(6.dp)
                    ) {
                        Icon(imageVector = Icons.Default.ContentCopy, contentDescription = null, tint = Color.Black, modifier = Modifier.size(12.dp))
                        Spacer(modifier = Modifier.width(4.dp))
                        Text("Copy ID", color = Color.Black, fontWeight = FontWeight.Bold, fontSize = 11.sp)
                    }
                }
            }

            Spacer(modifier = Modifier.height(10.dp))

            // Family Contacts Row
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .horizontalScroll(rememberScrollState()),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Add Contact Chip
                AssistChip(
                    onClick = { showAddContactDialog = true },
                    label = { Text("+ Add Family ID", fontSize = 11.sp, fontWeight = FontWeight.Bold, color = AmberAlert) },
                    colors = AssistChipDefaults.assistChipColors(containerColor = Color(0xFF241D12)),
                    border = androidx.compose.foundation.BorderStroke(1.dp, AmberAlert.copy(alpha = 0.5f))
                )

                // All Contacts Chip
                AssistChip(
                    onClick = { selectedContact = null },
                    label = { Text("All Family (${privateContacts.size})", fontSize = 11.sp, color = if (selectedContact == null) Color.Black else Color.White) },
                    colors = AssistChipDefaults.assistChipColors(
                        containerColor = if (selectedContact == null) AmberAlert else Color(0xFF1E1E1E)
                    )
                )

                // Individual Contact Chips
                privateContacts.forEach { contact ->
                    val isSel = selectedContact?.id == contact.id
                    AssistChip(
                        onClick = { selectedContact = contact },
                        label = { Text("${contact.name} (${contact.deviceId})", fontSize = 11.sp, color = if (isSel) Color.Black else Color.White) },
                        colors = AssistChipDefaults.assistChipColors(
                            containerColor = if (isSel) AmberAlert else Color(0xFF1E1E1E)
                        )
                    )
                }
            }
        } else {
            // Quick Emergency Broadcast Chips for Public Mode
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .horizontalScroll(rememberScrollState()),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                quickPhrases.forEach { phrase ->
                    AssistChip(
                        onClick = {
                            onSendMessage(phrase, "", null, 0)
                        },
                        label = { Text(phrase, fontSize = 11.sp, color = Color(0xFFCCCCCC)) },
                        colors = AssistChipDefaults.assistChipColors(containerColor = Color(0xFF161616)),
                        border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFF2E2E2E))
                    )
                }
            }
        }

        Spacer(modifier = Modifier.height(10.dp))

        // Message List
        if (currentMessages.isEmpty()) {
            Box(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth(),
                contentAlignment = Alignment.Center
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Icon(
                        imageVector = if (selectedChatTab == 0) Icons.Default.CellTower else Icons.Default.Person,
                        contentDescription = null,
                        tint = if (selectedChatTab == 0) Color(0xFF00E5FF).copy(alpha = 0.5f) else AmberAlert.copy(alpha = 0.5f),
                        modifier = Modifier.size(48.dp)
                    )
                    Spacer(modifier = Modifier.height(10.dp))
                    Text(
                        text = if (selectedChatTab == 0) "BLE Public Walkie-Talkie Ready" else "No Private Family Messages Yet",
                        fontWeight = FontWeight.Bold,
                        color = Color.White,
                        fontSize = 15.sp
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = if (selectedChatTab == 0) "Broadcast text or hold Walkie-Talkie mic to speak to all nearby phones across multi-hop Bluetooth mesh."
                        else "Send private messages and voice memos directly to your family over multi-hop mesh by entering their Device ID.",
                        color = Color.Gray,
                        fontSize = 12.sp,
                        textAlign = androidx.compose.ui.text.style.TextAlign.Center,
                        modifier = Modifier.padding(horizontal = 32.dp)
                    )
                }
            }
        } else {
            LazyColumn(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth(),
                verticalArrangement = Arrangement.spacedBy(10.dp),
                contentPadding = PaddingValues(vertical = 6.dp)
            ) {
                items(currentMessages, key = { it.id }) { msg ->
                    ChatBubbleItem(
                        message = msg,
                        isPlaying = playingMessageId == msg.id,
                        onPlayAudio = {
                            if (msg.audioBase64 != null) {
                                if (playingMessageId == msg.id) {
                                    WalkieTalkieAudioManager.stopAudio()
                                    playingMessageId = null
                                } else {
                                    WalkieTalkieAudioManager.playAudio(
                                        context = context,
                                        msgId = msg.id,
                                        base64Audio = msg.audioBase64,
                                        onFinished = { playingMessageId = null }
                                    )
                                    playingMessageId = msg.id
                                }
                            }
                        }
                    )
                }
            }
        }

        Spacer(modifier = Modifier.height(8.dp))

        // Recording Waveform Bar (Active while PTT is held)
        AnimatedVisibility(visible = isRecordingAudio) {
            val infiniteTransition = rememberInfiniteTransition(label = "recording_pulse")
            val pulseAlpha by infiniteTransition.animateFloat(
                initialValue = 0.4f,
                targetValue = 1.0f,
                animationSpec = infiniteRepeatable(
                    animation = tween(600, easing = FastOutSlowInEasing),
                    repeatMode = RepeatMode.Reverse
                ),
                label = "rec_pulse"
            )

            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = 8.dp),
                colors = CardDefaults.cardColors(containerColor = EmergencyRed.copy(alpha = 0.2f)),
                border = androidx.compose.foundation.BorderStroke(1.dp, EmergencyRed)
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(12.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Box(
                            modifier = Modifier
                                .size(12.dp)
                                .background(EmergencyRed.copy(alpha = pulseAlpha), CircleShape)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Icon(imageVector = Icons.Default.GraphicEq, contentDescription = null, tint = EmergencyRed, modifier = Modifier.size(20.dp))
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = "Recording Walkie-Talkie Voice...",
                            fontWeight = FontWeight.Bold,
                            color = EmergencyRed,
                            fontSize = 13.sp
                        )
                    }

                    Button(
                        onClick = {
                            isRecordingAudio = false
                            val result = WalkieTalkieAudioManager.stopRecording()
                            if (result != null) {
                                val target = if (selectedChatTab == 1) (selectedContact?.deviceId ?: "") else ""
                                onSendMessage("", target, result.first, result.second)
                                Toast.makeText(context, "Voice memo transmitted over BLE mesh!", Toast.LENGTH_SHORT).show()
                            }
                        },
                        colors = ButtonDefaults.buttonColors(containerColor = EmergencyRed),
                        shape = RoundedCornerShape(6.dp),
                        contentPadding = PaddingValues(horizontal = 10.dp, vertical = 4.dp)
                    ) {
                        Icon(imageVector = Icons.Default.Stop, contentDescription = null, tint = Color.White, modifier = Modifier.size(14.dp))
                        Spacer(modifier = Modifier.width(4.dp))
                        Text("Send Memo", color = Color.White, fontWeight = FontWeight.Bold, fontSize = 11.sp)
                    }
                }
            }
        }

        // Input & Walkie-Talkie Controls Bar
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            OutlinedTextField(
                value = inputText,
                onValueChange = { inputText = it },
                placeholder = {
                    Text(
                        text = if (selectedChatTab == 0) "Broadcast to nearby nodes..."
                        else if (selectedContact != null) "Message ${selectedContact!!.name} (${selectedContact!!.deviceId})..."
                        else "Private message to family...",
                        fontSize = 13.sp,
                        color = Color.Gray
                    )
                },
                modifier = Modifier.weight(1f),
                colors = OutlinedTextFieldDefaults.colors(
                    focusedTextColor = Color.White,
                    unfocusedTextColor = Color.White,
                    focusedBorderColor = if (selectedChatTab == 0) Color(0xFF00E5FF) else AmberAlert,
                    unfocusedBorderColor = Color(0xFF262626),
                    focusedContainerColor = Color(0xFF141414),
                    unfocusedContainerColor = Color(0xFF141414)
                ),
                shape = RoundedCornerShape(24.dp),
                maxLines = 3
            )

            Spacer(modifier = Modifier.width(8.dp))

            // Walkie-Talkie Voice PTT Button
            IconButton(
                onClick = {
                    if (isRecordingAudio) {
                        isRecordingAudio = false
                        val result = WalkieTalkieAudioManager.stopRecording()
                        if (result != null) {
                            val target = if (selectedChatTab == 1) (selectedContact?.deviceId ?: "") else ""
                            onSendMessage("", target, result.first, result.second)
                            Toast.makeText(context, "Voice memo transmitted!", Toast.LENGTH_SHORT).show()
                        }
                    } else {
                        val started = WalkieTalkieAudioManager.startRecording(context)
                        if (started) {
                            isRecordingAudio = true
                        } else {
                            Toast.makeText(context, "Mic permission needed for Walkie-Talkie audio", Toast.LENGTH_SHORT).show()
                        }
                    }
                },
                modifier = Modifier
                    .size(44.dp)
                    .background(if (isRecordingAudio) EmergencyRed else Color(0xFF202020), CircleShape)
            ) {
                Icon(
                    imageVector = Icons.Default.Mic,
                    contentDescription = "Walkie-Talkie PTT",
                    tint = if (isRecordingAudio) Color.White else Color(0xFF00E5FF),
                    modifier = Modifier.size(20.dp)
                )
            }

            Spacer(modifier = Modifier.width(6.dp))

            // Send Text Message Button
            IconButton(
                onClick = {
                    if (inputText.isNotBlank()) {
                        val target = if (selectedChatTab == 1) (selectedContact?.deviceId ?: "") else ""
                        onSendMessage(inputText.trim(), target, null, 0)
                        inputText = ""
                    }
                },
                enabled = inputText.isNotBlank(),
                modifier = Modifier
                    .size(44.dp)
                    .background(
                        if (inputText.isNotBlank()) (if (selectedChatTab == 0) Color(0xFF00E5FF) else AmberAlert) else Color(0xFF1E1E1E),
                        CircleShape
                    )
            ) {
                Icon(
                    imageVector = Icons.Default.Send,
                    contentDescription = "Send",
                    tint = if (inputText.isNotBlank()) Color.Black else Color.Gray,
                    modifier = Modifier.size(18.dp)
                )
            }
        }
    }

    if (showAddContactDialog) {
        AddFamilyContactModal(
            onDismiss = { showAddContactDialog = false },
            onSave = { name, devId, rel ->
                onAddPrivateContact(name, devId, rel)
                showAddContactDialog = false
                Toast.makeText(context, "Saved $name ($devId) to Family Contacts!", Toast.LENGTH_SHORT).show()
            }
        )
    }
}

@Composable
private fun ChatBubbleItem(
    message: MeshChatMessage,
    isPlaying: Boolean,
    onPlayAudio: () -> Unit
) {
    val bubbleColor = when {
        message.isFromMe && message.targetId.isNotEmpty() -> Color(0xFF2D2512) // Private From Me (Amber Gold)
        message.isFromMe -> Color(0xFF0D2530) // Public From Me (Cyan Blue)
        message.targetId.isNotEmpty() -> Color(0xFF241D12) // Private To Me
        else -> Color(0xFF181818) // Public From Others
    }

    val accentColor = if (message.targetId.isNotEmpty()) AmberAlert else Color(0xFF00E5FF)

    Column(
        modifier = Modifier.fillMaxWidth(),
        horizontalAlignment = if (message.isFromMe) Alignment.End else Alignment.Start
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(
                text = message.senderName,
                fontSize = 11.sp,
                fontWeight = FontWeight.Bold,
                color = if (message.isFromMe) accentColor else Color(0xFFCCCCCC)
            )

            if (message.targetId.isNotEmpty()) {
                Spacer(modifier = Modifier.width(4.dp))
                Box(
                    modifier = Modifier
                        .background(AmberAlert.copy(alpha = 0.2f), RoundedCornerShape(4.dp))
                        .padding(horizontal = 4.dp, vertical = 1.dp)
                ) {
                    Text(
                        text = if (message.isFromMe) "TO: ${message.targetId}" else "PRIVATE",
                        fontSize = 9.sp,
                        fontWeight = FontWeight.Bold,
                        color = AmberAlert
                    )
                }
            }

            Spacer(modifier = Modifier.width(6.dp))

            Text(
                text = "${message.timestamp} • Hop #${message.hopCount}",
                fontSize = 10.sp,
                color = Color.Gray
            )
        }

        Spacer(modifier = Modifier.height(4.dp))

        Box(
            modifier = Modifier
                .clip(RoundedCornerShape(12.dp))
                .background(bubbleColor)
                .border(1.dp, accentColor.copy(alpha = if (message.isFromMe) 0.4f else 0.15f), RoundedCornerShape(12.dp))
                .padding(12.dp)
        ) {
            if (message.isVoiceMessage) {
                // Voice Walkie-Talkie Bubble with Play/Pause
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier.clickable { onPlayAudio() }
                ) {
                    Box(
                        modifier = Modifier
                            .size(34.dp)
                            .background(accentColor, CircleShape),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = if (isPlaying) Icons.Default.Pause else Icons.Default.PlayArrow,
                            contentDescription = null,
                            tint = Color.Black,
                            modifier = Modifier.size(20.dp)
                        )
                    }

                    Spacer(modifier = Modifier.width(10.dp))

                    Column {
                        Text(
                            text = "Walkie-Talkie Voice Memo",
                            fontSize = 12.sp,
                            fontWeight = FontWeight.Bold,
                            color = Color.White
                        )
                        Text(
                            text = if (isPlaying) "Playing audio..." else "Duration: ~${message.audioDurationSec}s • Tap to Play",
                            fontSize = 10.sp,
                            color = accentColor
                        )
                    }
                }
            } else {
                Text(
                    text = message.text,
                    fontSize = 14.sp,
                    color = Color.White,
                    lineHeight = 18.sp
                )
            }
        }
    }
}

@Composable
fun AddFamilyContactModal(
    onDismiss: () -> Unit,
    onSave: (name: String, deviceId: String, relation: String) -> Unit
) {
    var name by remember { mutableStateOf("") }
    var deviceId by remember { mutableStateOf("") }
    var relation by remember { mutableStateOf("Family") }

    Dialog(onDismissRequest = onDismiss) {
        Card(
            shape = RoundedCornerShape(16.dp),
            colors = CardDefaults.cardColors(containerColor = Color(0xFF181818)),
            border = androidx.compose.foundation.BorderStroke(1.dp, AmberAlert.copy(alpha = 0.5f)),
            modifier = Modifier.fillMaxWidth()
        ) {
            Column(modifier = Modifier.padding(18.dp)) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "Save Family Mesh Contact",
                        fontWeight = FontWeight.Bold,
                        color = Color.White,
                        fontSize = 17.sp
                    )
                    IconButton(onClick = onDismiss, modifier = Modifier.size(28.dp)) {
                        Icon(imageVector = Icons.Default.Close, contentDescription = "Close", tint = Color.Gray)
                    }
                }

                Text(
                    text = "Allows direct private messaging & voice walkie-talkie over multi-hop mesh.",
                    color = Color.Gray,
                    fontSize = 11.sp
                )

                Spacer(modifier = Modifier.height(14.dp))

                OutlinedTextField(
                    value = name,
                    onValueChange = { name = it },
                    label = { Text("Contact Name") },
                    placeholder = { Text("e.g. Papa, Mummy, Rohan") },
                    modifier = Modifier.fillMaxWidth(),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedTextColor = Color.White,
                        unfocusedTextColor = Color.White,
                        focusedBorderColor = AmberAlert,
                        unfocusedBorderColor = Color.DarkGray
                    ),
                    singleLine = true
                )

                Spacer(modifier = Modifier.height(10.dp))

                OutlinedTextField(
                    value = deviceId,
                    onValueChange = { deviceId = it },
                    label = { Text("Family Member's Device ID") },
                    placeholder = { Text("e.g. GD-8192") },
                    modifier = Modifier.fillMaxWidth(),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedTextColor = Color.White,
                        unfocusedTextColor = Color.White,
                        focusedBorderColor = AmberAlert,
                        unfocusedBorderColor = Color.DarkGray
                    ),
                    singleLine = true
                )

                Spacer(modifier = Modifier.height(10.dp))

                OutlinedTextField(
                    value = relation,
                    onValueChange = { relation = it },
                    label = { Text("Relationship / Tag") },
                    placeholder = { Text("e.g. Parent, Sibling, Spouse") },
                    modifier = Modifier.fillMaxWidth(),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedTextColor = Color.White,
                        unfocusedTextColor = Color.White,
                        focusedBorderColor = AmberAlert,
                        unfocusedBorderColor = Color.DarkGray
                    ),
                    singleLine = true
                )

                Spacer(modifier = Modifier.height(16.dp))

                Button(
                    onClick = {
                        if (name.isNotBlank() && deviceId.isNotBlank()) {
                            onSave(name, deviceId, relation)
                        }
                    },
                    modifier = Modifier.fillMaxWidth(),
                    colors = ButtonDefaults.buttonColors(containerColor = AmberAlert),
                    shape = RoundedCornerShape(8.dp),
                    enabled = name.isNotBlank() && deviceId.isNotBlank()
                ) {
                    Text("Save Family Contact", color = Color.Black, fontWeight = FontWeight.Bold)
                }
            }
        }
    }
}
