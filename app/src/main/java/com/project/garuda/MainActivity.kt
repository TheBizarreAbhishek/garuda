package com.project.garuda

import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.project.garuda.notification.GarudaFirebaseMessagingService
import com.project.garuda.ui.navigation.GarudaMainScreen
import com.project.garuda.ui.sos.CitizenViewModel
import com.project.garuda.ui.theme.AmoledBlack
import com.project.garuda.ui.theme.GarudaTheme
import com.project.garuda.util.BatteryOptimizationHelper

class MainActivity : ComponentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        // 1. Initialize notification channels for Emergency siren and Push notifications
        GarudaFirebaseMessagingService.createNotificationChannels(this)

        // 2. Request BLE and Notification runtime permissions
        requestBlePermissions()

        // 3. Request battery optimization whitelist so Android OS does not kill background BLE mesh relay
        BatteryOptimizationHelper.requestIgnoreBatteryOptimization(this)

        setContent {
            val context = LocalContext.current
            val viewModel = remember { CitizenViewModel(context.applicationContext) }

            GarudaTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = AmoledBlack
                ) {
                    GarudaMainScreen(viewModel = viewModel)
                }
            }
        }
    }

    private fun requestBlePermissions() {
        val permissions = mutableListOf<String>()
        
        // Location permissions for GPS Hardware
        permissions.add(android.Manifest.permission.ACCESS_FINE_LOCATION)
        permissions.add(android.Manifest.permission.ACCESS_COARSE_LOCATION)
        
        // Bluetooth permissions for BLE Mesh
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            permissions.add(android.Manifest.permission.BLUETOOTH_SCAN)
            permissions.add(android.Manifest.permission.BLUETOOTH_ADVERTISE)
            permissions.add(android.Manifest.permission.BLUETOOTH_CONNECT)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            permissions.add(android.Manifest.permission.POST_NOTIFICATIONS)
        }

        val missing = permissions.filter {
            ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
        }
        if (missing.isNotEmpty()) {
            ActivityCompat.requestPermissions(this, missing.toTypedArray(), 101)
        }
    }
}
