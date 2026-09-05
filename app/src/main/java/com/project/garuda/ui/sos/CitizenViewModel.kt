package com.project.garuda.ui.sos

import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.project.garuda.mesh.ble.BleAdvertiserManager
import com.project.garuda.mesh.ble.BleScannerManager
import com.project.garuda.mesh.engine.MeshRelayEngine
import com.project.garuda.mesh.protocol.GarudaPacket
import com.project.garuda.mesh.service.MeshForegroundService
import com.project.garuda.network.FirebaseCloudGateway
import com.project.garuda.network.UplinkGatewayManager
import com.project.garuda.data.CitizenPersistenceManager
import com.project.garuda.ui.chat.MeshChatMessage
import com.project.garuda.ui.hazards.HazardAlert
import com.project.garuda.ui.shelter.ReliefShelter
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import android.location.Location
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlin.random.Random

class CitizenViewModel(
    private val appContext: Context? = null
) : ViewModel() {

    companion object {
        private const val TAG = "CitizenViewModel"
    }

    private val persistenceManager: CitizenPersistenceManager? = appContext?.let { CitizenPersistenceManager(it) }

    private var localDeviceHash: Int = persistenceManager?.getOrCreateDeviceHash() ?: (Build.MODEL ?: "GarudaNode").hashCode()

    val myDeviceId: String = {
        "GD-" + Math.abs(localDeviceHash).toString(16).uppercase().padStart(4, '0').take(6)
    }()

    private val _uiState = MutableStateFlow(
        CitizenUiState(
            medicalProfile = persistenceManager?.loadMedicalProfile((Build.MANUFACTURER ?: "User") + " " + (Build.MODEL ?: "Device")) ?: MedicalProfile(fullName = (Build.MANUFACTURER ?: "User") + " " + (Build.MODEL ?: "Device")),
            survivalChecklist = persistenceManager?.loadChecklist() ?: defaultChecklist()
        )
    )
    val uiState: StateFlow<CitizenUiState> = _uiState.asStateFlow()

    // Mesh Chatroom Stream (Public & Private)
    private val _chatMessages = MutableStateFlow<List<MeshChatMessage>>(emptyList())
    val chatMessages: StateFlow<List<MeshChatMessage>> = _chatMessages.asStateFlow()

    // Private Family Mesh Contacts
    private val _privateContacts = MutableStateFlow<List<com.project.garuda.data.PrivateMeshContact>>(
        persistenceManager?.loadPrivateContacts() ?: emptyList()
    )
    val privateContacts: StateFlow<List<com.project.garuda.data.PrivateMeshContact>> = _privateContacts.asStateFlow()

    // Dynamic Live Shelter Radar Stream
    private val _shelters = MutableStateFlow<List<ReliefShelter>>(emptyList())
    val shelters: StateFlow<List<ReliefShelter>> = _shelters.asStateFlow()

    // Dynamic Hazard Alerts Stream
    private val _hazardList = MutableStateFlow<List<HazardAlert>>(emptyList())
    val hazardList: StateFlow<List<HazardAlert>> = _hazardList.asStateFlow()

    private var countdownJob: Job? = null
    private var broadcastingJob: Job? = null

    // BLE Mesh Components
    private var advertiserManager: BleAdvertiserManager? = null
    private var scannerManager: BleScannerManager? = null
    private var meshRelayEngine: MeshRelayEngine? = null

    // Cloud Firebase Gateway & Local Command Grid Uplink
    val firebaseGateway = FirebaseCloudGateway(viewModelScope, appContext)
    val uplinkGateway = UplinkGatewayManager(viewModelScope, appContext)

    init {
        initBleMeshEngine()
        observeFirebaseGovernmentAlerts()
        observeUplinkGatewayEvents()
        observeMeshTelemetry()
        startSheltersAndHazardsSync()
    }

    private fun observeUplinkGatewayEvents() {
        viewModelScope.launch {
            uplinkGateway.connectionState.collect { connState ->
                if (connState.isEmergencyActiveFromGov) {
                    if (_uiState.value.mode == DisasterMode.STANDBY && !_uiState.value.isGovernmentAlertDialogOpen) {
                        _uiState.update {
                            it.copy(
                                pendingGovAlert = GovernmentAlert(
                                    headline = connState.alertHeadline,
                                    region = connState.activeDistrictAlert,
                                    instructions = connState.alertInstructions,
                                    timestampFormatted = "Live from Command Grid"
                                ),
                                isGovernmentAlertDialogOpen = true
                            )
                        }
                    }
                } else if (!connState.isEmergencyActiveFromGov && _uiState.value.isGovernmentAlertDialogOpen) {
                    _uiState.update { it.copy(isGovernmentAlertDialogOpen = false) }
                }
            }
        }
    }

    private fun initBleMeshEngine() {
        if (appContext != null) {
            try {
                // 1. Start Persistent Background Foreground Service so Mesh is never killed by OS
                try {
                    val serviceIntent = Intent(appContext, MeshForegroundService::class.java).apply {
                        action = MeshForegroundService.ACTION_START_HIGH_ALERT
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        appContext.startForegroundService(serviceIntent)
                    } else {
                        appContext.startService(serviceIntent)
                    }
                } catch (e: Exception) {
                    Log.v(TAG, "Foreground service start note: ${e.message}")
                }

                advertiserManager = BleAdvertiserManager(appContext)
                scannerManager = BleScannerManager(appContext)
                meshRelayEngine = MeshRelayEngine(advertiserManager, scannerManager, viewModelScope, localDeviceHash = localDeviceHash)

                startMeshScanner()
                startHeartbeatBroadcaster()
                observeMeshTelemetry()

                // Listen to live incoming mesh packets over Bluetooth
                viewModelScope.launch {
                    meshRelayEngine?.incomingPackets?.collect { packet ->
                        Log.d(TAG, "Received live BLE Mesh Packet: ID=0x${packet.packetId.toString(16)}, type=${packet.packetType}, hops=${packet.hopCount}")
                        val realPeers = meshRelayEngine?.getActivePeerCount() ?: 0
                        _uiState.update { current ->
                            current.copy(
                                meshStatus = current.meshStatus.copy(
                                    peersNearby = realPeers,
                                    packetsRelayed = current.meshStatus.packetsRelayed + 1,
                                    hopCount = packet.hopCount.coerceAtLeast(1),
                                    lastSyncAgo = "Just now"
                                )
                            )
                        }

                        // 💬 Mesh Walkie-Talkie Chat Packets (Public Broadcast + Targeted Private Direct)
                        if (packet.packetType == GarudaPacket.TYPE_CHAT) {
                            val rawString = try {
                                String(packet.payload, Charsets.UTF_8).trim()
                            } catch (e: Exception) { "" }
                            if (rawString.isNotBlank()) {
                                val isMine = packet.deviceHash == localDeviceHash
                                val senderId = "GD-" + Math.abs(packet.deviceHash).toString(16).uppercase().padStart(4, '0').take(6)

                                var targetId = ""
                                var content = rawString
                                var audioBase64: String? = null
                                var audioDur = 0
                                var isVoice = false

                                if (content.startsWith("[PRIVATE:")) {
                                    val endIdx = content.indexOf(']')
                                    if (endIdx != -1) {
                                        targetId = content.substring(9, endIdx).trim()
                                        content = content.substring(endIdx + 1).trim()
                                    }
                                } else if (content.startsWith("[PRIVATE_VOICE:")) {
                                    val endIdx = content.indexOf(']')
                                    if (endIdx != -1) {
                                        val meta = content.substring(15, endIdx).split(':')
                                        targetId = meta.getOrNull(0)?.trim() ?: ""
                                        audioDur = meta.getOrNull(1)?.toIntOrNull() ?: 1
                                        audioBase64 = content.substring(endIdx + 1).trim()
                                        content = "🎙️ Voice Walkie-Talkie ($audioDur s)"
                                        isVoice = true
                                    }
                                } else if (content.startsWith("[VOICE:")) {
                                    val endIdx = content.indexOf(']')
                                    if (endIdx != -1) {
                                        audioDur = content.substring(7, endIdx).toIntOrNull() ?: 1
                                        audioBase64 = content.substring(endIdx + 1).trim()
                                        content = "🎙️ Public Walkie-Talkie ($audioDur s)"
                                        isVoice = true
                                    }
                                }

                                val isForMe = targetId.isEmpty() || targetId.equals(myDeviceId, ignoreCase = true) || isMine
                                if (isForMe) {
                                    val contactName = _privateContacts.value.firstOrNull { it.deviceId.equals(senderId, ignoreCase = true) }?.name
                                    val sender = if (isMine) "You" else (contactName ?: "Peer $senderId")
                                    val timeFormat = SimpleDateFormat("HH:mm", Locale.getDefault())
                                    val timeStr = timeFormat.format(Date(packet.timestamp * 1000L))
                                    val newMsg = MeshChatMessage(
                                        id = "msg-${packet.packetId}-${packet.timestamp}",
                                        senderName = sender,
                                        senderId = senderId,
                                        targetId = targetId,
                                        senderRole = if (isMine) "You" else if (targetId.isNotEmpty()) "Private Family" else "Relay Peer",
                                        text = content,
                                        audioBase64 = audioBase64,
                                        audioDurationSec = audioDur,
                                        timestamp = timeStr,
                                        hopCount = packet.hopCount,
                                        isFromMe = isMine,
                                        isVoiceMessage = isVoice
                                    )
                                    _chatMessages.update { list ->
                                        if (list.any { it.id == newMsg.id }) list else list + newMsg
                                    }
                                }
                            }
                        }

                        // 🌐 EDGE GATEWAY RELAY TO CLOUD: If this phone has Internet, relay ONLY offline mesh peers (who do not have direct internet)
                        val isPeerDirectOnline = (packet.emergencyType == 0x7F.toByte())
                        if (firebaseGateway.syncState.value.isConnected && 
                            packet.deviceHash != 0 && 
                            packet.deviceHash != localDeviceHash && 
                            !isPeerDirectOnline) {
                            viewModelScope.launch {
                                firebaseGateway.uploadMeshPeerToFirestore(
                                    peerHash = packet.deviceHash,
                                    latitude = packet.latitude,
                                    longitude = packet.longitude,
                                    hopCount = packet.hopCount.coerceAtLeast(1)
                                )
                            }
                        }

                        // 🚨 Emergency Declaration Relayed via BLE Mesh from other peer nodes
                        if (packet.packetType == GarudaPacket.TYPE_EMERGENCY_BROADCAST || 
                            (packet.packetType == GarudaPacket.TYPE_SOS && packet.emergencyType != GarudaPacket.EMERGENCY_NONE)) {
                            
                            // If SOS, relay distress signal up to Firestore Cloud if this node has internet
                            if (packet.packetType == GarudaPacket.TYPE_SOS && firebaseGateway.syncState.value.isConnected) {
                                viewModelScope.launch {
                                    firebaseGateway.uploadSosToFirestore(
                                        packet = packet,
                                        victimName = "Survivor Node (BLE Mesh)",
                                        notes = "Offline BLE distress signal relayed to Cloud by Gateway Node $localDeviceHash (Hop #${packet.hopCount})"
                                    )
                                }
                            }

                            val packetTime = packet.timestamp.toLong()
                            val lastSavedTs = persistenceManager?.getLastAlertNotifiedTimestamp() ?: 0L
                            val shouldNotify = (packetTime > lastSavedTs && packetTime > 0L)

                            if (shouldNotify) {
                                persistenceManager?.setLastAlertNotifiedTimestamp(packetTime)
                                persistenceManager?.setLastAlertActiveState(true)
                                appContext?.let { ctx ->
                                    com.project.garuda.notification.GarudaNotificationManager.showHeadsUpNotification(
                                        context = ctx,
                                        title = "DISASTER EMERGENCY (MESH RELAY)",
                                        message = "Critical disaster declaration received via Bluetooth Mesh multi-hop relay. Evacuate or seek immediate high ground.",
                                        targetArea = "Your Region",
                                        isEmergency = true
                                    )
                                }
                            }
                            if (_uiState.value.mode == DisasterMode.STANDBY && !_uiState.value.isGovernmentAlertDialogOpen) {
                                _uiState.update {
                                    it.copy(
                                        pendingGovAlert = GovernmentAlert(
                                            headline = "DISASTER EMERGENCY (MESH RELAY)",
                                            region = "Disaster Zone",
                                            instructions = "Emergency alert received via multi-hop BLE mesh (Hop #${packet.hopCount}). Seek shelter or follow evacuation directives.",
                                            timestampFormatted = "Relayed via Mesh Hop #${packet.hopCount}"
                                        ),
                                        isGovernmentAlertDialogOpen = true
                                    )
                                }
                            }
                        }
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error initializing BLE Mesh Engine", e)
            }
        }
    }

    private fun observeFirebaseGovernmentAlerts() {
        viewModelScope.launch {
            firebaseGateway.syncState.collect { syncState ->
                if (syncState.isEmergencyActive) {
                    val currentLoc = firebaseGateway.hardwareManager?.locationFlow?.value?.locationName ?: ""
                    val targetZone = syncState.alertDistrict
                    val isApplicable = isGeofenceMatch(currentLoc, targetZone)

                    // 📡 Re-broadcast Cloud Emergency Alert onto BLE Mesh for all offline nearby citizens!
                    val meshAlertPacket = GarudaPacket(
                        packetType = GarudaPacket.TYPE_EMERGENCY_BROADCAST,
                        packetId = (syncState.alertHeadline.hashCode() xor syncState.alertDistrict.hashCode()),
                        deviceHash = localDeviceHash,
                        timestamp = (System.currentTimeMillis() / 1000).toInt(),
                        latitude = firebaseGateway.hardwareManager?.locationFlow?.value?.latitude ?: 0.0,
                        longitude = firebaseGateway.hardwareManager?.locationFlow?.value?.longitude ?: 0.0,
                        emergencyType = GarudaPacket.EMERGENCY_TRAPPED,
                        hopCount = 0,
                        ttl = 7
                    )
                    meshRelayEngine?.broadcastPacket(meshAlertPacket)

                    if (isApplicable) {
                        Log.i(TAG, "🚨 Geofence MATCH! Alert targeting '$targetZone' applies to current location '$currentLoc'")
                        if (_uiState.value.mode == DisasterMode.STANDBY && !_uiState.value.isGovernmentAlertDialogOpen) {
                            _uiState.update {
                                it.copy(
                                    pendingGovAlert = GovernmentAlert(
                                        headline = syncState.alertHeadline,
                                        region = syncState.alertDistrict,
                                        instructions = syncState.alertInstructions,
                                        timestampFormatted = "Live from Command Grid"
                                    ),
                                    isGovernmentAlertDialogOpen = false
                                )

                            }
                        }
                    } else {
                        Log.v(TAG, "ℹ️ Alert for '$targetZone' does not match device location '$currentLoc'. Remaining in Standby.")
                    }
                } else if (!syncState.isEmergencyActive && _uiState.value.isGovernmentAlertDialogOpen) {
                    _uiState.update { it.copy(isGovernmentAlertDialogOpen = false) }
                }
            }
        }
    }

    private fun isGeofenceMatch(deviceLocation: String, targetGeofence: String): Boolean {
        if (targetGeofence.isEmpty() || targetGeofence.contains("All", ignoreCase = true) || targetGeofence.contains("National", ignoreCase = true) || targetGeofence.contains("Pan-India", ignoreCase = true)) {
            return true
        }
        if (deviceLocation.isEmpty() || deviceLocation.contains("Detecting", ignoreCase = true)) {
            return true // Fallback to safe alert if GPS is still warming up
        }

        val devClean = deviceLocation.lowercase()
        val targetClean = targetGeofence.lowercase()

        // Check substring containment
        if (targetClean.contains(devClean) || devClean.contains(targetClean)) return true

        // Check matching words (e.g. "Uttar Pradesh", "Prayagraj", "Phaphamau", "Kerala", "Wayanad")
        val devTokens = devClean.split(',', ' ', '/', '(', ')').filter { it.length > 3 }
        val targetTokens = targetClean.split(',', ' ', '/', '(', ')').filter { it.length > 3 }

        return devTokens.any { token -> targetTokens.contains(token) }
    }

    private fun observeMeshTelemetry() {
        viewModelScope.launch {
            while (isActive) {
                delay(1000) // Fast 1-second auto refresh for responsive UI peer count
                val activePeers = meshRelayEngine?.getActivePeerCount() ?: 0
                _uiState.update { current ->
                    current.copy(
                        meshStatus = current.meshStatus.copy(
                            peersNearby = activePeers
                        )
                    )
                }
            }
        }
    }

    private fun startSheltersAndHazardsSync() {
        viewModelScope.launch {
            while (isActive) {
                try {
                    // 1. Fetch live shelters from Firestore or fallback
                    val cloudShelters = firebaseGateway.fetchReliefSheltersFromFirestore()
                    val loc = firebaseGateway.hardwareManager?.locationFlow?.value
                    val uLat = if (loc != null && loc.hasValidLocation && loc.latitude != 0.0) loc.latitude else 11.6854
                    val uLon = if (loc != null && loc.hasValidLocation && loc.longitude != 0.0) loc.longitude else 76.1320

                    val parsedShelters = if (cloudShelters.isNotEmpty()) {
                        cloudShelters.mapNotNull { doc ->
                            val fields = doc.optJSONObject("fields") ?: return@mapNotNull null
                            val nameDoc = doc.optString("name", "")
                            val docId = nameDoc.substringAfterLast("/")
                            val name = fields.optJSONObject("name")?.optString("stringValue") ?: "Relief Shelter"
                            val lat = fields.optJSONObject("latitude")?.optDouble("doubleValue") ?: 0.0
                            val lon = fields.optJSONObject("longitude")?.optDouble("doubleValue") ?: 0.0
                            val cap = fields.optJSONObject("capacity")?.optString("integerValue")?.toIntOrNull() ?: 500
                            val occ = fields.optJSONObject("currentOccupancy")?.optString("integerValue")?.toIntOrNull() ?: 0
                            val supplies = fields.optJSONObject("suppliesStatus")?.optString("stringValue") ?: "Supplies Available"
                            val phone = fields.optJSONObject("contactPhone")?.optString("stringValue") ?: "1078 (Helpline)"

                            val results = FloatArray(2)
                            Location.distanceBetween(uLat, uLon, lat, lon, results)
                            val dist = results[0].toInt()
                            val bearing = (results[1] + 360f) % 360f

                            // Strict Proximity Filter: Show only shelters within 50km reachable district perimeter
                            if (dist <= 50_000) {
                                ReliefShelter(
                                    id = docId,
                                    name = name,
                                    latitude = lat,
                                    longitude = lon,
                                    distanceMeters = dist,
                                    bearingDegrees = bearing,
                                    capacityCurrent = occ,
                                    capacityMax = cap,
                                    hasMedical = true,
                                    hasWater = true,
                                    hasPower = true,
                                    statusText = "$supplies • ${maxOf(0, cap - occ)} Spots Open",
                                    phone = phone
                                )
                            } else {
                                null
                            }
                        }.sortedBy { it.distanceMeters }
                    } else {
                        emptyList()
                    }

                    _shelters.value = parsedShelters

                    // 2. Fetch live hazards from Firestore
                    val cloudHazards = firebaseGateway.fetchHazardsFromFirestore()
                    if (cloudHazards.isNotEmpty()) {
                        val parsedHazards = cloudHazards.mapNotNull { doc ->
                            val fields = doc.optJSONObject("fields") ?: return@mapNotNull null
                            val nameDoc = doc.optString("name", "")
                            val docId = nameDoc.substringAfterLast("/")
                            val title = fields.optJSONObject("title")?.optString("stringValue") ?: "Hazard"
                            val desc = fields.optJSONObject("description")?.optString("stringValue") ?: ""
                            val severity = fields.optJSONObject("severity")?.optString("stringValue") ?: "High"
                            val lat = fields.optJSONObject("latitude")?.optDouble("doubleValue") ?: 0.0
                            val lon = fields.optJSONObject("longitude")?.optDouble("doubleValue") ?: 0.0
                            val confirmations = fields.optJSONObject("peerConfirmations")?.optString("integerValue")?.toIntOrNull() ?: 1
                            val imageProof = fields.optJSONObject("imageProof")?.optString("stringValue")
                            val isCamVerified = fields.optJSONObject("isCameraVerified")?.optBoolean("booleanValue") ?: false

                            val res = FloatArray(2)
                            Location.distanceBetween(uLat, uLon, lat, lon, res)
                            val dist = res[0].toInt()

                            HazardAlert(
                                id = docId,
                                title = title,
                                location = desc.ifBlank { "GPS: ${String.format("%.4f", lat)}, ${String.format("%.4f", lon)}" },
                                distanceMeters = dist,
                                severity = severity.uppercase(),
                                reportedAgo = "Live Feed",
                                confirmationCount = confirmations,
                                imageProof = imageProof,
                                isCameraVerified = isCamVerified,
                                latitude = lat,
                                longitude = lon
                            )
                        }.sortedBy { it.distanceMeters }
                        _hazardList.value = parsedHazards
                    }

                    // 3. Fetch live mesh chat messages (Public & Private)
                    val cloudChat = firebaseGateway.fetchMeshChatMessages()
                    if (cloudChat.isNotEmpty()) {
                        val parsedChat = cloudChat.mapNotNull { doc ->
                            val fields = doc.optJSONObject("fields") ?: return@mapNotNull null
                            val msgId = fields.optJSONObject("msgId")?.optString("stringValue") ?: return@mapNotNull null
                            val senderId = fields.optJSONObject("senderId")?.optString("stringValue") ?: "Peer"
                            val senderName = fields.optJSONObject("senderName")?.optString("stringValue") ?: senderId
                            val targetId = fields.optJSONObject("targetId")?.optString("stringValue") ?: ""
                            val text = fields.optJSONObject("text")?.optString("stringValue") ?: ""
                            val audioBase64 = fields.optJSONObject("audioBase64")?.optString("stringValue")
                            val audioDurationSec = fields.optJSONObject("audioDurationSec")?.optString("integerValue")?.toIntOrNull() ?: 0
                            val tsEpoch = fields.optJSONObject("timestamp")?.optString("integerValue")?.toLongOrNull() ?: (System.currentTimeMillis() / 1000)

                            val isMine = senderId.equals(myDeviceId, ignoreCase = true)
                            val isForMe = targetId.isEmpty() || targetId.equals(myDeviceId, ignoreCase = true) || isMine

                            if (!isForMe) return@mapNotNull null

                            val contactName = _privateContacts.value.firstOrNull { it.deviceId.equals(senderId, ignoreCase = true) }?.name
                            val sName = if (isMine) "You" else (contactName ?: senderName)
                            val timeFormat = SimpleDateFormat("HH:mm", Locale.getDefault())
                            val timeStr = timeFormat.format(Date(tsEpoch * 1000L))

                            MeshChatMessage(
                                id = msgId,
                                senderName = sName,
                                senderId = senderId,
                                targetId = targetId,
                                senderRole = if (isMine) "You" else if (targetId.isNotEmpty()) "Private Family" else "Mesh Peer",
                                text = if (audioBase64 != null) "🎙️ Voice Walkie-Talkie ($audioDurationSec s)" else text,
                                audioBase64 = audioBase64,
                                audioDurationSec = audioDurationSec,
                                timestamp = timeStr,
                                hopCount = 0,
                                isFromMe = isMine,
                                isVoiceMessage = audioBase64 != null
                            )
                        }

                        _chatMessages.update { currentList ->
                            var updated = currentList
                            for (cMsg in parsedChat) {
                                if (updated.none { it.id == cMsg.id }) {
                                    updated = updated + cMsg
                                }
                            }
                            updated
                        }
                    }
                } catch (e: Exception) {
                    Log.v(TAG, "Sync error: ${e.message}")
                }
                delay(3000) // Sync every 3s
            }
        }
    }

    fun sendMeshChatMessage(
        text: String,
        targetDeviceId: String = "",
        audioBase64: String? = null,
        audioDurationSec: Int = 0
    ) {
        if (text.isBlank() && audioBase64 == null) return
        val nowEpoch = (System.currentTimeMillis() / 1000).toInt()
        val timeFormat = SimpleDateFormat("HH:mm", Locale.getDefault())
        val timeStr = timeFormat.format(Date())
        val packetId = Random.nextInt(10000, 99999)
        val isVoice = audioBase64 != null

        val localMsg = MeshChatMessage(
            id = "msg-$packetId-$nowEpoch",
            senderName = "You",
            senderId = myDeviceId,
            targetId = targetDeviceId,
            senderRole = "You",
            text = if (isVoice) "🎙️ Voice Walkie-Talkie ($audioDurationSec s)" else text,
            audioBase64 = audioBase64,
            audioDurationSec = audioDurationSec,
            timestamp = timeStr,
            hopCount = 0,
            isFromMe = true,
            isVoiceMessage = isVoice
        )
        _chatMessages.update { it + localMsg }

        // Format packet payload for BLE mesh transmission
        val payloadString = when {
            isVoice && targetDeviceId.isNotEmpty() -> "[PRIVATE_VOICE:$targetDeviceId:$audioDurationSec]$audioBase64"
            isVoice -> "[VOICE:$audioDurationSec]$audioBase64"
            targetDeviceId.isNotEmpty() -> "[PRIVATE:$targetDeviceId]$text"
            else -> text
        }

        // Broadcast over multi-hop BLE Mesh
        val packet = GarudaPacket(
            packetType = GarudaPacket.TYPE_CHAT,
            packetId = packetId,
            deviceHash = localDeviceHash,
            timestamp = nowEpoch,
            latitude = firebaseGateway.hardwareManager?.locationFlow?.value?.latitude ?: 0.0,
            longitude = firebaseGateway.hardwareManager?.locationFlow?.value?.longitude ?: 0.0,
            emergencyType = GarudaPacket.EMERGENCY_NONE,
            hopCount = 0,
            ttl = GarudaPacket.DEFAULT_TTL,
            payload = payloadString.toByteArray(Charsets.UTF_8)
        )
        try {
            meshRelayEngine?.broadcastPacket(packet)
            Log.d(TAG, "Broadcasted Mesh Chat (target='$targetDeviceId', voice=$isVoice)")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to broadcast chat packet", e)
        }

        // Dual Delivery: Also upload to Firebase Cloud Gateway so messages never drop across cellular/wifi/gateway
        viewModelScope.launch {
            firebaseGateway.uploadMeshChatMessage(
                msgId = localMsg.id,
                senderId = myDeviceId,
                senderName = _uiState.value.medicalProfile.fullName.ifBlank { myDeviceId },
                targetId = targetDeviceId,
                text = text,
                audioBase64 = audioBase64,
                audioDurationSec = audioDurationSec
            )
        }
    }

    fun addPrivateContact(name: String, deviceId: String, relation: String = "Family") {
        if (name.isBlank() || deviceId.isBlank()) return
        val newContact = com.project.garuda.data.PrivateMeshContact(
            id = "contact-${System.currentTimeMillis()}",
            name = name.trim(),
            deviceId = deviceId.trim().uppercase(),
            relation = relation.trim().ifBlank { "Family" }
        )
        val updated = _privateContacts.value + newContact
        _privateContacts.value = updated
        persistenceManager?.savePrivateContacts(updated)
    }

    fun deletePrivateContact(id: String) {
        val updated = _privateContacts.value.filter { it.id != id }
        _privateContacts.value = updated
        persistenceManager?.savePrivateContacts(updated)
    }

    fun reportHazard(
        title: String,
        location: String,
        severity: String,
        description: String,
        imageBase64: String? = null,
        isCameraVerified: Boolean = false
    ) {
        val loc = firebaseGateway.hardwareManager?.locationFlow?.value
        val lat = loc?.latitude ?: 11.6854
        val lon = loc?.longitude ?: 76.1320
        val hazardId = "haz-${System.currentTimeMillis()}"

        val localHazard = HazardAlert(
            id = hazardId,
            title = title,
            location = location.ifBlank { description },
            distanceMeters = 0,
            severity = severity.uppercase(),
            reportedAgo = "Just now",
            confirmationCount = 1,
            imageProof = imageBase64,
            isCameraVerified = isCameraVerified,
            latitude = lat,
            longitude = lon
        )
        _hazardList.update { listOf(localHazard) + it }

        viewModelScope.launch {
            val reporter = _uiState.value.medicalProfile.fullName
            firebaseGateway.uploadHazardReport(
                title = title,
                category = "Obstacle / Danger",
                description = if (description.isNotBlank()) description else location,
                severity = severity,
                latitude = lat,
                longitude = lon,
                reporterName = reporter,
                imageProof = imageBase64,
                isCameraVerified = isCameraVerified
            )
        }

        // Broadcast via BLE Mesh
        val packet = GarudaPacket(
            packetType = GarudaPacket.TYPE_EMERGENCY_BROADCAST,
            packetId = Random.nextInt(10000, 99999),
            deviceHash = localDeviceHash,
            timestamp = (System.currentTimeMillis() / 1000).toInt(),
            latitude = lat,
            longitude = lon,
            emergencyType = GarudaPacket.EMERGENCY_TRAPPED,
            hopCount = 0,
            ttl = 5,
            payload = "$title: $description".toByteArray(Charsets.UTF_8)
        )
        meshRelayEngine?.broadcastPacket(packet)
    }

    fun confirmHazard(hazardId: String) {
        _hazardList.update { list ->
            list.map { h ->
                if (h.id == hazardId) {
                    val updatedCount = h.confirmationCount + 1
                    viewModelScope.launch {
                        firebaseGateway.confirmHazardOnFirestore(hazardId, h.confirmationCount)
                    }
                    h.copy(confirmationCount = updatedCount)
                } else h
            }
        }
    }

    fun toggleChecklistItem(id: String) {
        _uiState.update { current ->
            val updated = current.survivalChecklist.map { item ->
                if (item.id == id) item.copy(isChecked = !item.isChecked) else item
            }
            persistenceManager?.saveChecklist(updated)
            current.copy(survivalChecklist = updated)
        }
    }

    fun updateMedicalProfile(profile: MedicalProfile) {
        persistenceManager?.saveMedicalProfile(profile)
        _uiState.update { it.copy(medicalProfile = profile) }
    }

    fun selectEmergencyType(type: EmergencyType) {
        _uiState.update { it.copy(selectedEmergencyType = type) }
    }

    fun triggerGovernmentEmergencyAlert() {
        _uiState.update {
            it.copy(
                pendingGovAlert = GovernmentAlert(),
                isGovernmentAlertDialogOpen = false
            )
        }
    }


    fun dismissGovernmentAlert() {
        _uiState.update { it.copy(isGovernmentAlertDialogOpen = false) }
    }

    fun acknowledgeAlertAndEnterEmergency() {
        _uiState.update {
            it.copy(
                mode = DisasterMode.ACTIVE_EMERGENCY,
                isGovernmentAlertDialogOpen = false,
                meshStatus = it.meshStatus.copy(isMeshActive = true)
            )
        }
        startMeshScanner()
    }

    fun setDisasterMode(mode: DisasterMode) {
        if (mode == DisasterMode.STANDBY) {
            cancelSosCountdown()
            stopBroadcasting()
        }
        _uiState.update { it.copy(mode = mode) }
    }

    private var heartbeatJob: Job? = null

    private fun startHeartbeatBroadcaster() {
        heartbeatJob?.cancel()
        heartbeatJob = viewModelScope.launch {
            while (isActive) {
                val nowEpoch = (System.currentTimeMillis() / 1000).toInt()
                val isOnline = firebaseGateway.syncState.value.isConnected
                val heartbeatPacket = GarudaPacket(
                    packetType = GarudaPacket.TYPE_HEARTBEAT,
                    packetId = Random.nextInt(10000, 99999),
                    deviceHash = localDeviceHash,
                    timestamp = nowEpoch,
                    latitude = 0.0,
                    longitude = 0.0,
                    emergencyType = if (isOnline) 0x7F.toByte() else GarudaPacket.EMERGENCY_NONE,
                    hopCount = 0,
                    ttl = 1
                )
                try {
                    meshRelayEngine?.broadcastPacket(heartbeatPacket)
                    Log.d(TAG, "Sent presence heartbeat beacon (hash=$localDeviceHash)")
                } catch (e: Exception) {
                    Log.v(TAG, "Heartbeat broadcast failed", e)
                }
                delay(2000) // Periodic 2s BLE presence beacon for stable active nearby peer discovery
            }
        }
    }

    private fun startMeshScanner() {
        try {
            scannerManager?.startScanning { deviceAddress, rawBytes ->
                meshRelayEngine?.processIncomingRawBytes(deviceAddress, rawBytes)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start BLE scanning", e)
        }
    }

    private fun stopMeshScanner() {
        try {
            scannerManager?.stopScanning()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to stop BLE scanning", e)
        }
    }

    fun startSosCountdown() {
        if (_uiState.value.sosState is SosBroadcastState.Broadcasting) return
        countdownJob?.cancel()

        _uiState.update { it.copy(sosState = SosBroadcastState.Countdown(5)) }

        countdownJob = viewModelScope.launch {
            for (sec in 4 downTo 1) {
                delay(1000)
                _uiState.update {
                    if (it.sosState is SosBroadcastState.Countdown) {
                        it.copy(sosState = SosBroadcastState.Countdown(sec))
                    } else it
                }
            }
            delay(1000)
            triggerActiveBroadcasting()
        }
    }

    fun cancelSosCountdown() {
        countdownJob?.cancel()
        countdownJob = null
        _uiState.update { it.copy(sosState = SosBroadcastState.Idle) }
    }

    private fun triggerActiveBroadcasting() {
        val emergencyType = _uiState.value.selectedEmergencyType
        val packetIdInt = Random.nextInt(10000, 99999)
        val packetHex = "GD-" + packetIdInt.toString(16).uppercase()
        val nowEpoch = (System.currentTimeMillis() / 1000).toInt()

        _uiState.update {
            it.copy(
                mode = DisasterMode.ACTIVE_EMERGENCY,
                sosState = SosBroadcastState.Broadcasting(
                    emergencyType = emergencyType,
                    elapsedSeconds = 0,
                    packetId = packetHex,
                    timestampEpoch = nowEpoch.toLong()
                ),
                meshStatus = it.meshStatus.copy(
                    isMeshActive = true,
                    peersNearby = meshRelayEngine?.getActivePeerCount() ?: 0
                )
            )
        }

        val protocolEmergencyCode = when (emergencyType) {
            EmergencyType.MEDICAL -> GarudaPacket.EMERGENCY_MEDICAL
            EmergencyType.TRAPPED -> GarudaPacket.EMERGENCY_TRAPPED
            EmergencyType.FIRE -> GarudaPacket.EMERGENCY_FIRE
            EmergencyType.FLOOD -> GarudaPacket.EMERGENCY_FLOOD
            EmergencyType.GENERAL -> GarudaPacket.EMERGENCY_MEDICAL
        }

        val loc = firebaseGateway.hardwareManager?.locationFlow?.value
        val realLat = if (loc != null && loc.hasValidLocation && loc.latitude != 0.0) loc.latitude else 12.9716
        val realLon = if (loc != null && loc.hasValidLocation && loc.longitude != 0.0) loc.longitude else 77.5946

        val garudaPacket = GarudaPacket(
            packetType = GarudaPacket.TYPE_SOS,
            packetId = packetIdInt,
            deviceHash = localDeviceHash,
            timestamp = nowEpoch,
            latitude = realLat,
            longitude = realLon,
            emergencyType = protocolEmergencyCode,
            hopCount = 0,
            ttl = GarudaPacket.DEFAULT_TTL
        )

        // 1. Transmit Real 28-Byte Binary Packet over BLE Mesh
        try {
            meshRelayEngine?.broadcastPacket(garudaPacket)
            Log.i(TAG, "Transmitted Real BLE SOS Beacon: $packetHex with EmergencyCode=$protocolEmergencyCode")
        } catch (e: Exception) {
            Log.e(TAG, "BLE SOS Broadcast failed", e)
        }

        // 2. Upload to Firebase Firestore in Cloud
        viewModelScope.launch {
            val victimName = _uiState.value.medicalProfile.fullName
            firebaseGateway.uploadSosToFirestore(
                packet = garudaPacket,
                victimName = victimName,
                notes = "Live SOS beacon (${emergencyType.title}) with blood group ${_uiState.value.medicalProfile.bloodGroup}"
            )
        }

        // 3. Start Foreground Service
        appContext?.let { ctx ->
            try {
                val intent = Intent(ctx, MeshForegroundService::class.java).apply {
                    action = MeshForegroundService.ACTION_START_HIGH_ALERT
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    ctx.startForegroundService(intent)
                } else {
                    ctx.startService(intent)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Could not start MeshForegroundService", e)
            }
        }

        // 4. Elapsed Time Coroutine
        broadcastingJob?.cancel()
        broadcastingJob = viewModelScope.launch {
            var seconds = 0
            while (isActive) {
                delay(1000)
                seconds++
                _uiState.update { current ->
                    if (current.sosState is SosBroadcastState.Broadcasting) {
                        current.copy(
                            sosState = current.sosState.copy(elapsedSeconds = seconds)
                        )
                    } else current
                }
            }
        }
    }

    fun stopBroadcasting() {
        broadcastingJob?.cancel()
        broadcastingJob = null

        try {
            advertiserManager?.stopAdvertising()
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping BLE advertising", e)
        }

        appContext?.let { ctx ->
            try {
                val intent = Intent(ctx, MeshForegroundService::class.java).apply {
                    action = MeshForegroundService.ACTION_STOP_SERVICE
                }
                ctx.startService(intent)
            } catch (e: Exception) {
                Log.e(TAG, "Error stopping MeshForegroundService", e)
            }
        }

        _uiState.update { it.copy(sosState = SosBroadcastState.Idle) }
    }

    fun markUserSafe() {
        countdownJob?.cancel()
        stopBroadcasting()

        val contactsCount = _uiState.value.medicalProfile.emergencyContacts.size

        _uiState.update {
            it.copy(
                sosState = SosBroadcastState.ResolvedSafe(
                    checkInTimestamp = System.currentTimeMillis(),
                    smsSentCount = contactsCount
                ),
                safeStatusMessage = "You are marked SAFE. Distress signal cancelled and automated SMS queued for $contactsCount contacts."
            )
        }
    }

    fun clearSafeMessage() {
        _uiState.update { it.copy(safeStatusMessage = null) }
    }

    override fun onCleared() {
        super.onCleared()
        stopBroadcasting()
        stopMeshScanner()
    }
}
