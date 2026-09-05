package com.project.garuda.network

import android.os.Handler
import android.os.Looper
import android.util.Log
import com.project.garuda.mesh.protocol.GarudaPacket
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL

import android.content.Context
import com.project.garuda.notification.GarudaNotificationManager

data class GatewayConnectionState(
    val isConnected: Boolean = false,
    val serverHost: String = "127.0.0.1",
    val serverPort: Int = 8080,
    val latencyMs: Long = 0,
    val lastSyncTimestamp: Long = 0,
    val isEmergencyActiveFromGov: Boolean = false,
    val activeDistrictAlert: String = "Standby Mode",
    val alertHeadline: String = "No Active Emergency",
    val alertInstructions: String = "System ready."
)

class UplinkGatewayManager(
    private val scope: CoroutineScope,
    private val context: Context? = null
) {
    companion object {
        private const val TAG = "GarudaUplink"
    }

    private val _connectionState = MutableStateFlow(GatewayConnectionState())
    val connectionState: StateFlow<GatewayConnectionState> = _connectionState.asStateFlow()

    private var sseJob: Job? = null
    private var healthCheckJob: Job? = null

    // Candidates to auto-discover: localhost (adb reverse), typical hotspot gateways, and Mac Wi-Fi IP
    private val hostCandidates = listOf("127.0.0.1", "10.0.2.2", "192.168.1.100", "192.168.43.1")
    private var activeHost = "127.0.0.1"
    private var activePort = 8080

    init {
        startConnectionWatchdog()
    }

    fun setCustomHost(host: String, port: Int = 8080) {
        this.activeHost = host
        this.activePort = port
        restartConnection()
    }

    fun restartConnection() {
        sseJob?.cancel()
        healthCheckJob?.cancel()
        startConnectionWatchdog()
    }

    private fun startConnectionWatchdog() {
        healthCheckJob = scope.launch(Dispatchers.IO) {
            while (isActive) {
                checkServerReachability()
                kotlinx.coroutines.delay(4000)
            }
        }
    }

    private suspend fun checkServerReachability() {
        val hostsToTry = listOf(activeHost) + hostCandidates.filter { it != activeHost }
        for (host in hostsToTry) {
            val startTime = System.currentTimeMillis()
            try {
                val url = URL("http://$host:$activePort/api/v1/status")
                val connection = (url.openConnection() as HttpURLConnection).apply {
                    connectTimeout = 1500
                    readTimeout = 1500
                    requestMethod = "GET"
                }

                if (connection.responseCode == 200) {
                    val reader = BufferedReader(InputStreamReader(connection.inputStream))
                    val response = reader.readText()
                    reader.close()

                    val json = JSONObject(response)
                    val isEmergency = json.optBoolean("isEmergencyActive", false)
                    val district = json.optString("activeDistrict", "Wayanad")
                    val headline = json.optString("headline", "No Active Emergency")
                    val instructions = json.optString("instructions", "System ready.")
                    val latency = System.currentTimeMillis() - startTime

                    activeHost = host
                    _connectionState.value = _connectionState.value.copy(
                        isConnected = true,
                        serverHost = host,
                        serverPort = activePort,
                        latencyMs = latency,
                        lastSyncTimestamp = System.currentTimeMillis(),
                        isEmergencyActiveFromGov = isEmergency,
                        activeDistrictAlert = district,
                        alertHeadline = headline,
                        alertInstructions = instructions
                    )

                    // Start SSE Stream if not already running
                    if (sseJob == null || sseJob?.isActive == false) {
                        startSseStream(host, activePort)
                    }
                    return
                }
            } catch (e: Exception) {
                Log.v(TAG, "Host $host not reachable: ${e.message}")
            }
        }

        // None reachable
        _connectionState.value = _connectionState.value.copy(isConnected = false)
    }

    private fun startSseStream(host: String, port: Int) {
        sseJob?.cancel()
        sseJob = scope.launch(Dispatchers.IO) {
            try {
                val url = URL("http://$host:$port/api/v1/stream")
                val connection = (url.openConnection() as HttpURLConnection).apply {
                    connectTimeout = 5000
                    readTimeout = 0 // Infinite for SSE stream
                    requestMethod = "GET"
                    setRequestProperty("Accept", "text/event-stream")
                }

                val reader = BufferedReader(InputStreamReader(connection.inputStream))
                var line: String?
                var currentEvent: String = "message"

                while (isActive) {
                    line = reader.readLine() ?: break
                    if (line.startsWith("event: ")) {
                        currentEvent = line.removePrefix("event: ").trim()
                    } else if (line.startsWith("data: ")) {
                        val dataJson = line.removePrefix("data: ")
                        try {
                            if (currentEvent == "emergency_deactivated") {
                                _connectionState.value = _connectionState.value.copy(
                                    isEmergencyActiveFromGov = false,
                                    activeDistrictAlert = "Standby",
                                    alertHeadline = "",
                                    alertInstructions = ""
                                )
                                if (context != null) {
                                    GarudaNotificationManager.dismissEmergencyNotification(context)
                                }
                                continue
                            }

                            val json = JSONObject(dataJson)
                            val title = json.optString("title", "GOVERNMENT BROADCAST")
                            val message = json.optString("message", json.optString("instructions", "New directive received."))
                            val targetArea = json.optString("targetArea", json.optString("district", "All Regions"))
                            val priority = json.optString("priority", json.optString("severity", "HIGH"))
                            val isEmergency = (currentEvent == "emergency_activated") || priority.contains("Critical", true)

                            _connectionState.value = _connectionState.value.copy(
                                isEmergencyActiveFromGov = isEmergency,
                                activeDistrictAlert = targetArea,
                                alertHeadline = title,
                                alertInstructions = "$priority: $message"
                            )

                            // Trigger real-time system notification on citizen phone (deduplicated automatically)
                            if (context != null) {
                                GarudaNotificationManager.showHeadsUpNotification(
                                    context = context,
                                    title = title,
                                    message = message,
                                    targetArea = targetArea,
                                    isEmergency = isEmergency
                                )
                            }
                        } catch (e: Exception) {
                            Log.e(TAG, "Error parsing SSE event: $e")
                        }
                    }
                }
            } catch (e: Exception) {
                Log.w(TAG, "SSE Stream disconnected: ${e.message}")
            }
        }
    }

    suspend fun uploadSosPacket(
        packet: GarudaPacket,
        victimName: String = "Mobile Citizen",
        notes: String = "Real emergency beacon from Samsung Galaxy"
    ): Boolean = withContext(Dispatchers.IO) {
        if (!_connectionState.value.isConnected) return@withContext false

        try {
            val url = URL("http://$activeHost:$activePort/api/v1/sos")
            val connection = (url.openConnection() as HttpURLConnection).apply {
                connectTimeout = 3000
                readTimeout = 3000
                requestMethod = "POST"
                setRequestProperty("Content-Type", "application/json")
                doOutput = true
            }

            val payload = JSONObject().apply {
                put("id", "SOS-${packet.packetId}")
                put("victimName", victimName)
                put("bloodGroup", "O+")
                put("latitude", packet.latitude)
                put("longitude", packet.longitude)
                put("hopCount", packet.hopCount)
                put("batteryLevel", 85)
                put("relayedByGatewayId", "MOBILE-GATEWAY-${packet.deviceHash.toString(16).uppercase()}")
                put("notes", notes)
            }

            val writer = OutputStreamWriter(connection.outputStream)
            writer.write(payload.toString())
            writer.flush()
            writer.close()

            val success = connection.responseCode == 200
            if (success) {
                _connectionState.value = _connectionState.value.copy(
                    lastSyncTimestamp = System.currentTimeMillis()
                )
            }
            return@withContext success
        } catch (e: Exception) {
            Log.e(TAG, "Failed to upload SOS packet to Command Grid: ${e.message}")
            return@withContext false
        }
    }
}
