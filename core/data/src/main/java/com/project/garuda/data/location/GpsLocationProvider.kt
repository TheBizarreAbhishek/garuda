package com.project.garuda.data.location

import android.annotation.SuppressLint
import android.content.Context
import android.location.Location
import android.os.Looper
import android.util.Log
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationCallback
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationResult
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/**
 * GPS Location Provider utilizing Google Play Services FusedLocationProviderClient.
 * Emits live high-accuracy location updates with fallback to last known location.
 */
class GpsLocationProvider(private val context: Context) {

    companion object {
        private const val TAG = "GpsLocationProvider"
        const val UPDATE_INTERVAL_MS = 5000L
        const val FASTEST_INTERVAL_MS = 2000L
    }

    private val fusedLocationClient: FusedLocationProviderClient =
        LocationServices.getFusedLocationProviderClient(context)

    private val _currentLocation = MutableStateFlow<Location?>(null)
    val currentLocation: StateFlow<Location?> = _currentLocation.asStateFlow()

    private val locationCallback = object : LocationCallback() {
        override fun onLocationResult(result: LocationResult) {
            val location = result.lastLocation ?: return
            Log.d(TAG, "Live GPS Location Update: Lat=${location.latitude}, Lon=${location.longitude}")
            _currentLocation.value = location
        }
    }

    @SuppressLint("MissingPermission")
    fun startLocationUpdates() {
        try {
            // 1. Fetch last known location for immediate response
            fusedLocationClient.lastLocation.addOnSuccessListener { location ->
                if (location != null && _currentLocation.value == null) {
                    Log.d(TAG, "Last known GPS location: Lat=${location.latitude}, Lon=${location.longitude}")
                    _currentLocation.value = location
                }
            }

            // 2. Request high accuracy continuous location updates
            val request = LocationRequest.Builder(Priority.PRIORITY_HIGH_ACCURACY, UPDATE_INTERVAL_MS)
                .setMinUpdateIntervalMillis(FASTEST_INTERVAL_MS)
                .build()

            fusedLocationClient.requestLocationUpdates(request, locationCallback, Looper.getMainLooper())
        } catch (e: SecurityException) {
            Log.e(TAG, "Missing location permissions to start location updates", e)
        } catch (e: Exception) {
            Log.e(TAG, "Error starting location updates", e)
        }
    }

    fun stopLocationUpdates() {
        try {
            fusedLocationClient.removeLocationUpdates(locationCallback)
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping location updates", e)
        }
    }
}
