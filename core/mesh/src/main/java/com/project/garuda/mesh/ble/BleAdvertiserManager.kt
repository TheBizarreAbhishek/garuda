package com.project.garuda.mesh.ble

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.bluetooth.le.AdvertiseCallback
import android.bluetooth.le.AdvertiseData
import android.bluetooth.le.AdvertiseSettings
import android.bluetooth.le.BluetoothLeAdvertiser
import android.content.Context
import android.util.Log

/**
 * Manages BLE Advertising for Project Garuda mesh broadcast network.
 * Compatible with all Android vendor chipsets.
 */
class BleAdvertiserManager(private val context: Context) {

    companion object {
        private const val TAG = "BleAdvertiserManager"
        const val MANUFACTURER_ID = 0x4744 // "GD" for Garuda
        const val MAX_ADVERTISE_BYTES = 24
    }

    private var isAdvertising = false

    private val advertiseCallback = object : AdvertiseCallback() {
        override fun onStartSuccess(settingsInEffect: AdvertiseSettings?) {
            super.onStartSuccess(settingsInEffect)
            isAdvertising = true
            Log.d(TAG, "BLE Mesh Advertising active")
        }

        override fun onStartFailure(errorCode: Int) {
            super.onStartFailure(errorCode)
            isAdvertising = false
            Log.w(TAG, "BLE Mesh Advertising failed: $errorCode")
        }
    }

    private fun getAdvertiser(): BluetoothLeAdvertiser? {
        val bluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
        val adapter = bluetoothManager?.adapter ?: BluetoothAdapter.getDefaultAdapter()
        return adapter?.bluetoothLeAdvertiser
    }

    /**
     * Broadcasts a raw Garuda binary packet over BLE manufacturer data.
     */
    fun startAdvertising(packetBytes: ByteArray) {
        val advertiser = getAdvertiser() ?: run {
            Log.e(TAG, "BluetoothLeAdvertiser is unavailable on this device")
            return
        }

        try {
            advertiser.stopAdvertising(advertiseCallback)
        } catch (_: Exception) {}

        val settings = AdvertiseSettings.Builder()
            .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY)
            .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_HIGH)
            .setConnectable(false)
            .setTimeout(0)
            .build()

        // Ensure payload fits within standard 31-byte advertising frame limit
        val safeBytes = if (packetBytes.size > MAX_ADVERTISE_BYTES) {
            packetBytes.copyOf(MAX_ADVERTISE_BYTES)
        } else {
            packetBytes
        }

        val data = AdvertiseData.Builder()
            .setIncludeDeviceName(false)
            .setIncludeTxPowerLevel(false)
            .addManufacturerData(MANUFACTURER_ID, safeBytes)
            .build()

        try {
            advertiser.startAdvertising(settings, data, advertiseCallback)
            Log.d(TAG, "Broadcasting BLE Mesh Packet (${safeBytes.size} bytes)")
        } catch (e: SecurityException) {
            Log.e(TAG, "Missing Bluetooth permissions to start advertising", e)
        } catch (e: Exception) {
            Log.e(TAG, "Error starting BLE advertising", e)
        }
    }

    /**
     * Stops active BLE advertising.
     */
    fun stopAdvertising() {
        try {
            getAdvertiser()?.stopAdvertising(advertiseCallback)
        } catch (_: Exception) {}
        isAdvertising = false
    }
}
