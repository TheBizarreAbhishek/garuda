package com.project.garuda.data.db.entity

import androidx.room.Entity
import androidx.room.PrimaryKey

/**
 * Room Entity for storing P2P BLE Mesh chat messages.
 */
@Entity(tableName = "mesh_messages")
data class MeshMessageEntity(
    @PrimaryKey
    val messageId: String,
    val senderName: String,
    val text: String,
    val timestamp: Long,
    val hopCount: Int
)
