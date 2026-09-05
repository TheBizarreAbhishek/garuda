package com.project.garuda.data.db.entity

import androidx.room.Entity
import androidx.room.PrimaryKey

/**
 * Room Entity for storing local and relayed BLE Mesh SOS Telemetry packets.
 */
@Entity(tableName = "sos_packets")
data class SosPacketEntity(
    @PrimaryKey
    val packetId: Int,
    val senderId: String,
    val timestamp: Long,
    val latitude: Double,
    val longitude: Double,
    val emergencyType: Int,
    val hopCount: Int,
    val syncStatus: String = SYNC_STATUS_LOCAL
) {
    companion object {
        const val SYNC_STATUS_LOCAL = "LOCAL"
        const val SYNC_STATUS_RELAYED = "RELAYED"
        const val SYNC_STATUS_SYNCED = "SYNCED"
    }
}
