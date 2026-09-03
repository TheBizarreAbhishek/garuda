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
import com.project.garuda.mesh.protocol.GarudaPacket
import com.project.garuda.mesh.service.MeshForegroundService
import com.project.garuda.ui.theme.GarudaTheme
import kotlinx.coroutines.launch

class MainActivity : ComponentActivity() {

    private var meshService: MeshForegroundService? = null
    private var isServiceBound = mutableStateOf(false)
    private val receivedPackets = mutableStateListOf<GarudaPacket>()

    private val serviceConnection = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName?, service: IBinder?) {
            val binder = service as? MeshForegroundService.LocalBinder
            meshService = binder?.getService()
            isServiceBound.value = true

            // Observe incoming packets
            meshService?.let { s ->
                // Coroutine to collect incoming packets
                (this@MainActivity as? ComponentActivity)?.let {
                    // Collect packets from mesh relay engine
                }
            }
        }

        override fun onServiceDisconnected(name: ComponentName?) {
            meshService = null
            isServiceBound.value = false
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        setContent {
            GarudaTheme {
                MainScreen(
                    isServiceBound = isServiceBound.value,
                    onStartService = { startAndBindMeshService() },
                    onStopService = { stopMeshService() },
                    onSendSos = { broadcastSosBeacon() },
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

    private fun broadcastSosBeacon() {
        meshService?.let { service ->
            val packet = GarudaPacket(
                packetType = GarudaPacket.TYPE_SOS,
                packetId = (System.currentTimeMillis() and 0xFFFFFFFFL).toInt(),
                deviceHash = "GARUDA-DEVICE".hashCode(),
                timestamp = (System.currentTimeMillis() / 1000).toInt(),
                latitude = 11.6854,
                longitude = 76.1320,
                emergencyType = GarudaPacket.EMERGENCY_MEDICAL,
                hopCount = 0,
                ttl = 7
            )
            service.meshRelayEngine.broadcastPacket(packet)
            receivedPackets.add(0, packet)
            Toast.makeText(this, "Transmitted SOS Beacon over BLE Mesh!", Toast.LENGTH_SHORT).show()
        } ?: run {
            Toast.makeText(this, "Start BLE Mesh Service First!", Toast.LENGTH_SHORT).show()
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
    onStartService: () -> Unit,
    onStopService: () -> Unit,
    onSendSos: () -> Unit,
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
            // Status Card
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(
                    containerColor = if (isServiceBound) Color(0xFF1B5E20).copy(alpha = 0.2f) else Color(0xFFB71C1C).copy(alpha = 0.2f)
                )
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text(
                        text = if (isServiceBound) "BLE MESH ENGINE ACTIVE" else "STANDBY / OFFLINE MESH READY",
                        fontWeight = FontWeight.Bold,
                        color = if (isServiceBound) Color(0xFF4CAF50) else Color(0xFFFF5252),
                        fontSize = 14.sp
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = if (isServiceBound)
                            "Transmitting and relaying SOS beacons via Bluetooth Low Energy."
                        else
                            "Start mesh engine to join offline delay-tolerant disaster network.",
                        fontSize = 12.sp,
                        color = Color.Gray
                    )
                }
            }

            Spacer(modifier = Modifier.height(20.dp))

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
                        "Multi-hop BLE • No Internet Needed",
                        fontSize = 11.sp,
                        color = Color.White.copy(alpha = 0.8f)
                    )
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Service Toggle Button
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                Button(
                    onClick = if (isServiceBound) onStopService else onStartService,
                    modifier = Modifier.weight(1f),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = if (isServiceBound) Color.DarkGray else MaterialTheme.colorScheme.primary
                    )
                ) {
                    Text(if (isServiceBound) "Stop Mesh" else "Start Mesh")
                }
            }

            Spacer(modifier = Modifier.height(20.dp))

            // Packet Log Header
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text("Mesh Packet Telemetry", fontWeight = FontWeight.Bold, fontSize = 16.sp)
                Text("${receivedPackets.size} Relayed", fontSize = 12.sp, color = Color.Gray)
            }

            Spacer(modifier = Modifier.height(10.dp))

            if (receivedPackets.isEmpty()) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .weight(1f),
                    contentAlignment = Alignment.Center
                ) {
                    Text("No BLE packets detected yet.\nTap 'Broadcast SOS Beacon' to transmit.", color = Color.Gray, fontSize = 13.sp)
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
                    "Packet ID: 0x${Integer.toHexString(packet.packetId).uppercase()}",
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