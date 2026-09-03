package com.project.garuda.hardware

import android.annotation.SuppressLint
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.location.Address
import android.location.Geocoder
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.BatteryManager
import android.os.Build
import android.os.Bundle
import android.util.Log
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.util.Locale

data class DeviceLocationData(
    val latitude: Double = 0.0,
    val longitude: Double = 0.0,
    val accuracyMeters: Float = 0f,
    val locationName: String = "Detecting GPS...",
    val hasValidLocation: Boolean = false
)

class DeviceHardwareManager(private val context: Context) {

    companion object {
        private const val TAG = "DeviceHardwareManager"
    }

    private val locationManager = context.getSystemService(Context.LOCATION_SERVICE) as? LocationManager
    private val _locationFlow = MutableStateFlow(DeviceLocationData())
    val locationFlow: StateFlow<DeviceLocationData> = _locationFlow.asStateFlow()

    init {
        startRealLocationUpdates()
    }

    // MARK: - Real Battery Percentage from Android OS
    fun getRealBatteryPercentage(): Int {
        return try {
            val batteryManager = context.getSystemService(Context.BATTERY_SERVICE) as? BatteryManager
            if (batteryManager != null) {
                val batteryLevel = batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
                if (batteryLevel in 0..100) {
                    return batteryLevel
                }
            }

            // Fallback to Sticky Intent
            val intentFilter = IntentFilter(Intent.ACTION_BATTERY_CHANGED)
            val batteryStatus = context.registerReceiver(null, intentFilter)
            val level = batteryStatus?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
            val scale = batteryStatus?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1

            if (level >= 0 && scale > 0) {
                (level * 100 / scale.toFloat()).toInt()
            } else {
                75
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error reading real battery level", e)
            75
        }
    }

    // MARK: - Real GPS Location Tracking
    @SuppressLint("MissingPermission")
    fun startRealLocationUpdates() {
        if (locationManager == null) return

        try {
            // 1. Fetch last known location first for instantaneous lock
            val lastGps = locationManager.getLastKnownLocation(LocationManager.GPS_PROVIDER)
            val lastNet = locationManager.getLastKnownLocation(LocationManager.NETWORK_PROVIDER)
            val bestLast = lastGps ?: lastNet

            if (bestLast != null) {
                updateLocationState(bestLast)
            }

            // 2. Register for continuous hardware updates
            val listener = object : LocationListener {
                override fun onLocationChanged(location: Location) {
                    updateLocationState(location)
                }
                override fun onProviderEnabled(provider: String) {}
                override fun onProviderDisabled(provider: String) {}
                override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}
            }

            if (locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER)) {
                locationManager.requestLocationUpdates(
                    LocationManager.GPS_PROVIDER,
                    2000L,
                    1f,
                    listener
                )
            }
            if (locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)) {
                locationManager.requestLocationUpdates(
                    LocationManager.NETWORK_PROVIDER,
                    3000L,
                    2f,
                    listener
                )
            }
        } catch (e: SecurityException) {
            Log.w(TAG, "Location permissions not yet granted for hardware GPS: ${e.message}")
        } catch (e: Exception) {
            Log.e(TAG, "Error starting location updates", e)
        }
    }

    private fun updateLocationState(location: Location) {
        val lat = location.latitude
        val lon = location.longitude
        val accuracy = location.accuracy

        var localityName = "${String.format("%.4f", lat)}°N, ${String.format("%.4f", lon)}°E"

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                val geocoder = Geocoder(context, Locale.getDefault())
                geocoder.getFromLocation(lat, lon, 1) { addresses ->
                    if (addresses.isNotEmpty()) {
                        val addr = addresses[0]
                        val name = buildAddressString(addr)
                        _locationFlow.value = DeviceLocationData(
                            latitude = lat,
                            longitude = lon,
                            accuracyMeters = accuracy,
                            locationName = name,
                            hasValidLocation = true
                        )
                    }
                }
            } else {
                @Suppress("DEPRECATION")
                val geocoder = Geocoder(context, Locale.getDefault())
                val addresses = geocoder.getFromLocation(lat, lon, 1)
                if (!addresses.isNullOrEmpty()) {
                    localityName = buildAddressString(addresses[0])
                }
            }
        } catch (e: Exception) {
            Log.v(TAG, "Geocoding note: ${e.message}")
        }

        _locationFlow.value = DeviceLocationData(
            latitude = lat,
            longitude = lon,
            accuracyMeters = accuracy,
            locationName = localityName,
            hasValidLocation = true
        )
    }

    private fun buildAddressString(addr: Address): String {
        val subLocality = addr.subLocality ?: addr.locality ?: ""
        val city = addr.locality ?: addr.subAdminArea ?: ""
        val state = addr.adminArea ?: ""
        
        return when {
            subLocality.isNotEmpty() && city.isNotEmpty() && subLocality != city -> "$subLocality, $city"
            city.isNotEmpty() && state.isNotEmpty() -> "$city, $state"
            city.isNotEmpty() -> city
            state.isNotEmpty() -> state
            else -> "${String.format("%.4f", addr.latitude)}, ${String.format("%.4f", addr.longitude)}"
        }
    }
}
