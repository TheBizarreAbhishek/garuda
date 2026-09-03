package com.project.garuda

import android.Manifest
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.os.IBinder
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.ContextCompat
import androidx.lifecycle.lifecycleScope
import com.project.garuda.mesh.protocol.GarudaPacket
import com.project.garuda.mesh.service.MeshForegroundService
import com.project.garuda.network.GatewayConnectionState
import com.project.garuda.network.UplinkGatewayManager
import com.project.garuda.ui.theme.GarudaTheme
import kotlinx.coroutines.launch

class MainActivity : ComponentActivity() {

    private var meshService: MeshForegroundService? = null
    private var isServiceBound = mutableStateOf(false)
    private val receivedPackets = mutableStateListOf<GarudaPacket>()
    
    private lateinit var uplinkManager: UplinkGatewayManager

    private val serviceConnection = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName?, service: IBinder?) {
            val binder = service as? MeshForegroundService.LocalBinder
            meshService = binder?.getService()
            isServiceBound.value = true
        }

        override fun onServiceDisconnected(name: ComponentName?) {
            meshService = null
            isServiceBound.value = false
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        uplinkManager = UplinkGatewayManager(lifecycleScope)

        setContent {
            val gatewayState by uplinkManager.connectionState.collectAsState()

            GarudaTheme {
                MainScreen(
                    isServiceBound = isServiceBound.value,
                    gatewayState = gatewayState,
                    onStartService = { startAndBindMeshService() },
                    onStopService = { stopMeshService() },
                    onSendSos = { broadcastAndUploadSos() },
                    onRetryUplink = { uplinkManager.restartConnection() },
                    receivedPackets = receivedPackets
                )
            }
        }
    }

    private fun startAndBindMeshService() {
        val intent = Intent(this, MeshForegroundService::class.java).apply {
            action = MeshForegroundService.ACTION_START_HIGH_ALERT
        }
        ContextCompat.startForegroundService(this, intent)
        bindService(intent, serviceConnection, Context.BIND_AUTO_CREATE)
        Toast.makeText(this, "Garuda BLE Mesh Started", Toast.LENGTH_SHORT).show()
    }

    private fun stopMeshService() {
        if (isServiceBound.value) {
            unbindService(serviceConnection)
            isServiceBound.value = false
        }
        val intent = Intent(this, MeshForegroundService::class.java).apply {
            action = MeshForegroundService.ACTION_STOP_SERVICE
        }
        stopService(intent)
        Toast.makeText(this, "Garuda Mesh Stopped", Toast.LENGTH_SHORT).show()
    }

    private fun broadcastAndUploadSos() {
        val packet = GarudaPacket(
            packetType = GarudaPacket.TYPE_SOS,
            packetId = (System.currentTimeMillis() and 0xFFFFFFFFL).toInt(),
            deviceHash = "GALAXY-DEVICE".hashCode(),
            timestamp = (System.currentTimeMillis() / 1000).toInt(),
            latitude = 11.6854,
            longitude = 76.1320,
            emergencyType = GarudaPacket.EMERGENCY_MEDICAL,
            hopCount = 0,
            ttl = 7
        )

        // 1. Broadcast locally over BLE Mesh
        meshService?.let { service ->
            service.meshRelayEngine.broadcastPacket(packet)
        }
        receivedPackets.add(0, packet)

        // 2. Upload over Uplink Bridge to Garuda Command Grid (macOS)
        lifecycleScope.launch {
            val uploaded = uplinkManager.uploadSosPacket(
                packet = packet,
                victimName = "Citizen (Samsung Galaxy)",
                notes = "Live SOS triggered from mobile device over BLE + Gateway Uplink"
            )
            if (uploaded) {
                Toast.makeText(this@MainActivity, "⚡ SOS Relayed to Command Grid!", Toast.LENGTH_SHORT).show()
            } else {
                Toast.makeText(this@MainActivity, "Broadcasted via BLE Mesh (Gateway offline)", Toast.LENGTH_SHORT).show()
            }
        }
    }

    override fun onDestroy() {
        if (isServiceBound.value) {
            unbindService(serviceConnection)
        }
        super.onDestroy()
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MainScreen(
    isServiceBound: Boolean,
    gatewayState: GatewayConnectionState,
    onStartService: () -> Unit,
    onStopService: () -> Unit,
    onSendSos: () -> Unit,
    onRetryUplink: () -> Unit,
    receivedPackets: List<GarudaPacket>
) {
    val permissionsToRequest = remember {
        mutableListOf(
            Manifest.permission.ACCESS_FINE_LOCATION,
            Manifest.permission.ACCESS_COARSE_LOCATION
        ).apply {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                add(Manifest.permission.BLUETOOTH_SCAN)
                add(Manifest.permission.BLUETOOTH_ADVERTISE)
                add(Manifest.permission.BLUETOOTH_CONNECT)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                add(Manifest.permission.POST_NOTIFICATIONS)
            }
        }.toTypedArray()
    }

    var hasPermissions by remember { mutableStateOf(false) }

    val permissionLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestMultiplePermissions()
    ) { result ->
        hasPermissions = result.values.all { it }
    }

    LaunchedEffect(Unit) {
        permissionLauncher.launch(permissionsToRequest)
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Box(
                            modifier = Modifier
                                .size(10.dp)
                                .clip(CircleShape)
                                .background(if (isServiceBound) Color(0xFF4CAF50) else Color(0xFFFF5252))
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("PROJECT GARUDA", fontWeight = FontWeight.Black, letterSpacing = 1.sp)
                    }
                },
                actions = {
                    IconButton(onClick = onRetryUplink) {
                        Text(if (gatewayState.isConnected) "🟢" else "🔴", fontSize = 14.sp)
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.surface
                )
            )
        }
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            // Live Government Alert Banner (from Command Grid)
            if (gatewayState.isEmergencyActiveFromGov) {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(14.dp),
                    colors = CardDefaults.cardColors(containerColor = Color(0xFFB71C1C))
                ) {
                    Column(modifier = Modifier.padding(14.dp)) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Text("🚨", fontSize = 16.sp)
                            Spacer(modifier = Modifier.width(6.dp))
                            Text(
                                text = "GOVERNMENT DISASTER ALERT",
                                fontWeight = FontWeight.Black,
                                color = Color.White,
                                fontSize = 13.sp
                            )
                        }
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = gatewayState.alertHeadline,
                            fontWeight = FontWeight.Bold,
                            color = Color.Yellow,
                            fontSize = 14.sp
                        )
                        Spacer(modifier = Modifier.height(2.dp))
                        Text(
                            text = gatewayState.alertInstructions,
                            color = Color.White.copy(alpha = 0.9f),
                            fontSize = 12.sp
                        )
                    }
                }
                Spacer(modifier = Modifier.height(12.dp))
            }

            // Command Grid Uplink Status Card
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(14.dp),
                colors = CardDefaults.cardColors(
                    containerColor = if (gatewayState.isConnected) Color(0xFF0D47A1).copy(alpha = 0.15f) else Color.DarkGray.copy(alpha = 0.15f)
                )
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(12.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Column {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Box(
                                modifier = Modifier
                                    .size(8.dp)
                                    .clip(CircleShape)
                                    .background(if (gatewayState.isConnected) Color(0xFF29B6F6) else Color.Gray)
                            )
                            Spacer(modifier = Modifier.width(6.dp))
                            Text(
                                text = if (gatewayState.isConnected) "COMMAND GRID UPLINK ACTIVE" else "UPLINK GATEWAY SEARCHING...",
                                fontWeight = FontWeight.Bold,
                                fontSize = 12.sp,
                                color = if (gatewayState.isConnected) Color(0xFF29B6F6) else Color.Gray
                            )
                        }
                        Spacer(modifier = Modifier.height(2.dp))
                        Text(
                            text = if (gatewayState.isConnected)
                                "Connected: ${gatewayState.serverHost}:${gatewayState.serverPort} (${gatewayState.latencyMs}ms)"
                            else
                                "Auto-detecting Mac Command Center (port ${gatewayState.serverPort})",
                            fontSize = 11.sp,
                            fontFamily = FontFamily.Monospace,
                            color = Color.Gray
                        )
                    }

                    if (!gatewayState.isConnected) {
                        Button(
                            onClick = onRetryUplink,
                            shape = RoundedCornerShape(8.dp),
                            contentPadding = PaddingValues(horizontal = 8.dp, vertical = 2.dp)
                        ) {
                            Text("Retry", fontSize = 11.sp)
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // BIG RED SOS PANIC BUTTON
            Button(
                onClick = onSendSos,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(90.dp),
                shape = RoundedCornerShape(20.dp),
                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFD32F2F))
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text(
                        "BROADCAST SOS BEACON",
                        fontWeight = FontWeight.Black,
                        fontSize = 18.sp,
                        color = Color.White
                    )
                    Text(
                        "Relays via BLE Mesh + Command Grid Uplink",
                        fontSize = 11.sp,
                        color = Color.White.copy(alpha = 0.8f)
                    )
                }
            }

            Spacer(modifier = Modifier.height(14.dp))

            // Service Controls
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                Button(
                    onClick = if (isServiceBound) onStopService else onStartService,
                    modifier = Modifier.weight(1f),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = if (isServiceBound) Color.DarkGray else MaterialTheme.colorScheme.primary
                    )
                ) {
                    Text(if (isServiceBound) "Stop BLE Mesh" else "Start BLE Mesh")
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Packet Log Header
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text("Local Telemetry Stream", fontWeight = FontWeight.Bold, fontSize = 15.sp)
                Text("${receivedPackets.size} Relayed", fontSize = 12.sp, color = Color.Gray)
            }

            Spacer(modifier = Modifier.height(8.dp))

            if (receivedPackets.isEmpty()) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .weight(1f),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        "No BLE mesh packets recorded.\nTap 'Broadcast SOS Beacon' to transmit.",
                        color = Color.Gray,
                        fontSize = 13.sp
                    )
                }
            } else {
                LazyColumn(
                    modifier = Modifier.weight(1f),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    items(receivedPackets) { packet ->
                        PacketCard(packet = packet)
                    }
                }
            }
        }
    }
}

@Composable
fun PacketCard(packet: GarudaPacket) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant)
    ) {
        Column(modifier = Modifier.padding(12.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    "Packet: 0x${Integer.toHexString(packet.packetId).uppercase()}",
                    fontWeight = FontWeight.Bold,
                    fontFamily = FontFamily.Monospace,
                    fontSize = 13.sp
                )
                Text(
                    "Hops: ${packet.hopCount} | TTL: ${packet.ttl}",
                    fontWeight = FontWeight.Bold,
                    color = MaterialTheme.colorScheme.primary,
                    fontSize = 12.sp
                )
            }
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                "Lat: ${String.format("%.4f", packet.latitude)} | Lon: ${String.format("%.4f", packet.longitude)}",
                fontFamily = FontFamily.Monospace,
                fontSize = 11.sp,
                color = Color.Gray
            )
            Spacer(modifier = Modifier.height(2.dp))
            Text(
                "Triage: Critical | Type: Emergency SOS",
                fontSize = 11.sp,
                color = Color(0xFFFF5252),
                fontWeight = FontWeight.SemiBold
            )
        }
    }
}