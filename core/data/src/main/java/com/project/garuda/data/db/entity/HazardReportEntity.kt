package com.project.garuda.data.db.entity

import androidx.room.Entity
import androidx.room.PrimaryKey

/**
 * Room Entity for storing crowdsourced hazard reports (e.g. Landslide, Flooded Bridge, Fallen Tree).
 */
@Entity(tableName = "hazard_reports")
data class HazardReportEntity(
    @PrimaryKey
    val id: String,
    val photoUri: String? = null,
    val hazardType: String,
    val description: String,
    val latitude: Double,
    val longitude: Double,
    val timestamp: Long,
    val syncStatus: String = SYNC_STATUS_LOCAL
) {
    companion object {
        const val SYNC_STATUS_LOCAL = "LOCAL"
        const val SYNC_STATUS_SYNCED = "SYNCED"
    }
}
