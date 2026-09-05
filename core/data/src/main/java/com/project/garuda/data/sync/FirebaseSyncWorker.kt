package com.project.garuda.data.sync

import android.content.Context
import android.util.Log
import androidx.work.Constraints
import androidx.work.CoroutineWorker
import androidx.work.ExistingWorkPolicy
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import com.google.firebase.firestore.FirebaseFirestore
import com.project.garuda.data.db.GarudaDatabase
import com.project.garuda.data.db.entity.HazardReportEntity
import com.project.garuda.data.db.entity.SosPacketEntity
import kotlinx.coroutines.tasks.await

/**
 * AndroidX WorkManager worker for auto-flushing offline Room DB data (SOS telemetry & Hazard reports)
 * to Firebase Firestore whenever internet connectivity is restored.
 */
class FirebaseSyncWorker(
    appContext: Context,
    workerParams: WorkerParameters
) : CoroutineWorker(appContext, workerParams) {

    companion object {
        private const val TAG = "FirebaseSyncWorker"
        const val WORK_NAME = "GarudaFirebaseSyncWork"

        fun scheduleSync(context: Context) {
            val constraints = Constraints.Builder()
                .setRequiredNetworkType(NetworkType.CONNECTED)
                .build()

            val syncRequest = OneTimeWorkRequestBuilder<FirebaseSyncWorker>()
                .setConstraints(constraints)
                .build()

            WorkManager.getInstance(context).enqueueUniqueWork(
                WORK_NAME,
                ExistingWorkPolicy.REPLACE,
                syncRequest
            )
        }
    }

    override suspend fun doWork(): Result {
        Log.d(TAG, "Starting Firebase Cloud Sync Worker...")
        val db = GarudaDatabase.getInstance(applicationContext)
        val firestore = try {
            FirebaseFirestore.getInstance()
        } catch (e: Exception) {
            Log.e(TAG, "FirebaseFirestore unavailable", e)
            null
        }

        if (firestore == null) {
            return Result.retry()
        }

        var hasFailures = false

        // 1. Sync un-synced SOS packets
        val unsyncedSosPackets = db.sosPacketDao().getUnsyncedSosPackets()
        Log.d(TAG, "Found ${unsyncedSosPackets.size} un-synced SOS packets to flush to Firestore")

        for (sos in unsyncedSosPackets) {
            try {
                val data = mapOf(
                    "packetId" to sos.packetId,
                    "senderId" to sos.senderId,
                    "timestamp" to sos.timestamp,
                    "latitude" to sos.latitude,
                    "longitude" to sos.longitude,
                    "emergencyType" to sos.emergencyType,
                    "hopCount" to sos.hopCount,
                    "syncedAt" to System.currentTimeMillis()
                )

                firestore.collection("disaster_sos")
                    .document("sos_${sos.packetId}")
                    .set(data)
                    .await()

                db.sosPacketDao().updateSyncStatus(sos.packetId, SosPacketEntity.SYNC_STATUS_SYNCED)
                Log.d(TAG, "Flushed SOS Packet 0x${sos.packetId.toString(16)} to Firestore successfully")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to upload SOS Packet 0x${sos.packetId.toString(16)}", e)
                hasFailures = true
            }
        }

        // 2. Sync un-synced Hazard reports
        val unsyncedHazardReports = db.hazardReportDao().getUnsyncedHazardReports()
        Log.d(TAG, "Found ${unsyncedHazardReports.size} un-synced Hazard Reports to flush to Firestore")

        for (hazard in unsyncedHazardReports) {
            try {
                val data = mapOf(
                    "id" to hazard.id,
                    "photoUri" to (hazard.photoUri ?: ""),
                    "hazardType" to hazard.hazardType,
                    "description" to hazard.description,
                    "latitude" to hazard.latitude,
                    "longitude" to hazard.longitude,
                    "timestamp" to hazard.timestamp,
                    "syncedAt" to System.currentTimeMillis()
                )

                firestore.collection("hazard_reports")
                    .document(hazard.id)
                    .set(data)
                    .await()

                db.hazardReportDao().updateSyncStatus(hazard.id, HazardReportEntity.SYNC_STATUS_SYNCED)
                Log.d(TAG, "Flushed Hazard Report ${hazard.id} to Firestore successfully")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to upload Hazard Report ${hazard.id}", e)
                hasFailures = true
            }
        }

        return if (hasFailures) Result.retry() else Result.success()
    }
}
