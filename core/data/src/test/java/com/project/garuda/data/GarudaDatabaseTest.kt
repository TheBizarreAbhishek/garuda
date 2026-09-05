package com.project.garuda.data

import com.project.garuda.data.db.entity.HazardReportEntity
import com.project.garuda.data.db.entity.MeshMessageEntity
import com.project.garuda.data.db.entity.ReliefShelterEntity
import com.project.garuda.data.db.entity.SosPacketEntity
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Test

class GarudaDatabaseTest {

    @Test
    fun testSosPacketEntityCreationAndSyncStatus() {
        val entity = SosPacketEntity(
            packetId = 1001,
            senderId = "node_alpha",
            timestamp = 1700000000L,
            latitude = 28.6139,
            longitude = 77.2090,
            emergencyType = 1,
            hopCount = 2,
            syncStatus = SosPacketEntity.SYNC_STATUS_LOCAL
        )

        assertEquals(1001, entity.packetId)
        assertEquals("node_alpha", entity.senderId)
        assertEquals(SosPacketEntity.SYNC_STATUS_LOCAL, entity.syncStatus)

        val updatedEntity = entity.copy(syncStatus = SosPacketEntity.SYNC_STATUS_SYNCED)
        assertEquals(SosPacketEntity.SYNC_STATUS_SYNCED, updatedEntity.syncStatus)
    }

    @Test
    fun testMeshMessageEntityCreation() {
        val message = MeshMessageEntity(
            messageId = "msg_001",
            senderName = "Citizen 1",
            text = "Need medical supplies at shelter 2",
            timestamp = 1700000500L,
            hopCount = 1
        )

        assertEquals("msg_001", message.messageId)
        assertEquals("Citizen 1", message.senderName)
        assertEquals("Need medical supplies at shelter 2", message.text)
        assertEquals(1, message.hopCount)
    }

    @Test
    fun testHazardReportEntityCreation() {
        val report = HazardReportEntity(
            id = "hazard_101",
            photoUri = "content://media/external/images/1",
            hazardType = "Landslide",
            description = "Main road blocked by fallen rocks",
            latitude = 19.0760,
            longitude = 72.8777,
            timestamp = 1700001000L,
            syncStatus = HazardReportEntity.SYNC_STATUS_LOCAL
        )

        assertEquals("hazard_101", report.id)
        assertEquals("Landslide", report.hazardType)
        assertNotNull(report.photoUri)
        assertEquals(HazardReportEntity.SYNC_STATUS_LOCAL, report.syncStatus)
    }

    @Test
    fun testReliefShelterEntityCreation() {
        val shelter = ReliefShelterEntity(
            id = "shelter_01",
            name = "St. Mary School Relief Camp",
            latitude = 28.6100,
            longitude = 77.2000,
            capacity = 250,
            suppliesStatus = "Food & Water Available"
        )

        assertEquals("shelter_01", shelter.id)
        assertEquals("St. Mary School Relief Camp", shelter.name)
        assertEquals(250, shelter.capacity)
    }
}
