package com.project.garuda.data.db.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.project.garuda.data.db.entity.HazardReportEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface HazardReportDao {

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertHazardReport(report: HazardReportEntity)

    @Query("SELECT * FROM hazard_reports ORDER BY timestamp DESC")
    fun getAllHazardReports(): Flow<List<HazardReportEntity>>

    @Query("SELECT * FROM hazard_reports WHERE syncStatus != 'SYNCED'")
    suspend fun getUnsyncedHazardReports(): List<HazardReportEntity>

    @Query("UPDATE hazard_reports SET syncStatus = :syncStatus WHERE id = :reportId")
    suspend fun updateSyncStatus(reportId: String, syncStatus: String)
}
