package com.project.garuda.data.db.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.project.garuda.data.db.entity.ReliefShelterEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface ReliefShelterDao {

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertShelters(shelters: List<ReliefShelterEntity>)

    @Query("SELECT * FROM relief_shelters ORDER BY name ASC")
    fun getAllShelters(): Flow<List<ReliefShelterEntity>>
}
