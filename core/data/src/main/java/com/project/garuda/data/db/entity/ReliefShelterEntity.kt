package com.project.garuda.data.db.entity

import androidx.room.Entity
import androidx.room.PrimaryKey

/**
 * Room Entity for storing local relief shelter locations, capacity, and supply status.
 */
@Entity(tableName = "relief_shelters")
data class ReliefShelterEntity(
    @PrimaryKey
    val id: String,
    val name: String,
    val latitude: Double,
    val longitude: Double,
    val capacity: Int,
    val suppliesStatus: String
)
