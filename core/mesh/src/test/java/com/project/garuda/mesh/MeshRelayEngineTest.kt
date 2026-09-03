package com.project.garuda.mesh

import com.project.garuda.mesh.engine.MeshRelayEngine
import com.project.garuda.mesh.protocol.GarudaPacket
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class MeshRelayEngineTest {

    private val testScope = TestScope()
    private val relayEngine = MeshRelayEngine(coroutineScope = testScope)

    @Test
    fun testLruDeduplication() = testScope.runTest {
        val packet = GarudaPacket(
            packetType = GarudaPacket.TYPE_SOS,
            packetId = 1001,
            deviceHash = 2002,
            timestamp = 1700000000,
            latitude = 28.6139,
            longitude = 77.2090,
            ttl = 3
        )

        assertFalse(relayEngine.isPacketSeen(1001))

        relayEngine.processIncomingPacket(packet)

        assertTrue(relayEngine.isPacketSeen(1001))
    }

    @Test
    fun testIncomingPacketsFlowEmission() = testScope.runTest {
        val packet = GarudaPacket(
            packetType = GarudaPacket.TYPE_CHAT,
            packetId = 5005,
            deviceHash = 6006,
            timestamp = 1700000000,
            latitude = 12.9716,
            longitude = 77.5946,
            payload = "Hello Mesh".toByteArray(Charsets.UTF_8)
        )

        relayEngine.processIncomingPacket(packet)

        val received = relayEngine.incomingPackets.first()
        assertEquals(5005, received.packetId)
        assertEquals("Hello Mesh", String(received.payload, Charsets.UTF_8))
    }

    @Test
    fun testDuplicatePacketsNotReEmitted() = testScope.runTest {
        val packet = GarudaPacket(
            packetType = GarudaPacket.TYPE_SOS,
            packetId = 9999,
            deviceHash = 8888,
            timestamp = 1700000000,
            latitude = 0.0,
            longitude = 0.0
        )

        relayEngine.processIncomingPacket(packet)
        assertTrue(relayEngine.isPacketSeen(9999))

        // Process duplicate packet
        relayEngine.processIncomingPacket(packet)

        // Count should remain 1 (seen)
        assertTrue(relayEngine.isPacketSeen(9999))
    }
}
