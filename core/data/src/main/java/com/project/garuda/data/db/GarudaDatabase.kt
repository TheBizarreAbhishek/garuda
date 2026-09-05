package com.project.garuda.data.db

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import com.project.garuda.data.db.dao.HazardReportDao
import com.project.garuda.data.db.dao.MeshMessageDao
import com.project.garuda.data.db.dao.ReliefShelterDao
import com.project.garuda.data.db.dao.SosPacketDao
import com.project.garuda.data.db.entity.HazardReportEntity
import com.project.garuda.data.db.entity.MeshMessageEntity
import com.project.garuda.data.db.entity.ReliefShelterEntity
import com.project.garuda.data.db.entity.SosPacketEntity

@Database(
    entities = [
        SosPacketEntity::class,
        MeshMessageEntity::class,
        HazardReportEntity::class,
        ReliefShelterEntity::class
    ],
    version = 1,
    exportSchema = false
)
abstract class GarudaDatabase : RoomDatabase() {

    abstract fun sosPacketDao(): SosPacketDao
    abstract fun meshMessageDao(): MeshMessageDao
    abstract fun hazardReportDao(): HazardReportDao
    abstract fun reliefShelterDao(): ReliefShelterDao

    companion object {
        @Volatile
        private var INSTANCE: GarudaDatabase? = null

        fun getInstance(context: Context): GarudaDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    GarudaDatabase::class.java,
                    "garuda_disaster_db"
                ).fallbackToDestructiveMigration().build()
                INSTANCE = instance
                instance
            }
        }
    }
}
