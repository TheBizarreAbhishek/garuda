package com.project.garuda.data.db.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.project.garuda.data.db.entity.SosPacketEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface SosPacketDao {

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertSosPacket(packet: SosPacketEntity)

    @Query("SELECT * FROM sos_packets ORDER BY timestamp DESC")
    fun getAllSosPackets(): Flow<List<SosPacketEntity>>

    @Query("SELECT * FROM sos_packets WHERE syncStatus != 'SYNCED'")
    suspend fun getUnsyncedSosPackets(): List<SosPacketEntity>

    @Query("UPDATE sos_packets SET syncStatus = :syncStatus WHERE packetId = :packetId")
    suspend fun updateSyncStatus(packetId: Int, syncStatus: String)
}
