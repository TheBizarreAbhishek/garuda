package com.project.garuda.data.db.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.project.garuda.data.db.entity.MeshMessageEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface MeshMessageDao {

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertMessage(message: MeshMessageEntity)

    @Query("SELECT * FROM mesh_messages ORDER BY timestamp ASC")
    fun getAllMessages(): Flow<List<MeshMessageEntity>>
}
