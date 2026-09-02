package com.project.garuda.mesh

import com.project.garuda.mesh.protocol.GarudaPacket
import com.project.garuda.mesh.protocol.GarudaProtocolEncoderDecoder
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Test

class GarudaProtocolTest {

    @Test
    fun testSosPacketEncodingAndDecodingRoundtrip() {
        val sosPacket = GarudaPacket(
            packetType = GarudaPacket.TYPE_SOS,
            packetId = 0x12345678,
            deviceHash = 0xABCDEF01,
            timestamp = 1700000000,
            latitude = 28.613939,
            longitude = 77.209021,
            emergencyType = GarudaPacket.EMERGENCY_MEDICAL,
            hopCount = 1,
            ttl = 4
        )

        val encodedBytes = GarudaProtocolEncoderDecoder.encode(sosPacket)
        assertEquals(GarudaPacket.LEGACY_FRAME_SIZE, encodedBytes.size)

        val decodedPacket = GarudaProtocolEncoderDecoder.decode(encodedBytes)
        assertNotNull(decodedPacket)
        assertEquals(GarudaPacket.TYPE_SOS, decodedPacket!!.packetType)
        assertEquals(0x12345678, decodedPacket.packetId)
        assertEquals(0xABCDEF01, decodedPacket.deviceHash)
        assertEquals(1700000000, decodedPacket.timestamp)
        assertEquals(28.613939, decodedPacket.latitude, 1e-6)
        assertEquals(77.209021, decodedPacket.longitude, 1e-6)
        assertEquals(GarudaPacket.EMERGENCY_MEDICAL, decodedPacket.emergencyType)
        assertEquals(1, decodedPacket.hopCount)
        assertEquals(4, decodedPacket.ttl)
    }

    @Test
    fun testExtendedChatPacketPayload() {
        val chatMessage = "SOS: Medical help needed near shelter 3"
        val payloadBytes = chatMessage.toByteArray(Charsets.UTF_8)

        val chatPacket = GarudaPacket(
            packetType = GarudaPacket.TYPE_CHAT,
            packetId = 987654321,
            deviceHash = 123456789,
            timestamp = 1700001000,
            latitude = 19.0760,
            longitude = 72.8777,
            emergencyType = GarudaPacket.EMERGENCY_NONE,
            hopCount = 0,
            ttl = 5,
            payload = payloadBytes
        )

        val encodedBytes = GarudaProtocolEncoderDecoder.encode(chatPacket)
        assertEquals(GarudaPacket.LEGACY_FRAME_SIZE + payloadBytes.size, encodedBytes.size)

        val decodedPacket = GarudaProtocolEncoderDecoder.decode(encodedBytes)
        assertNotNull(decodedPacket)
        assertArrayEquals(payloadBytes, decodedPacket!!.payload)
        assertEquals(chatMessage, String(decodedPacket.payload, Charsets.UTF_8))
    }

    @Test
    fun testInvalidMagicHeaderRejection() {
        val validPacket = GarudaPacket(
            packetType = GarudaPacket.TYPE_HEARTBEAT,
            packetId = 111,
            deviceHash = 222,
            timestamp = 1000,
            latitude = 0.0,
            longitude = 0.0
        )

        val bytes = GarudaProtocolEncoderDecoder.encode(validPacket)
        // Corrupt magic header
        bytes[0] = 0x00.toByte()

        val decoded = GarudaProtocolEncoderDecoder.decode(bytes)
        assertNull(decoded)
    }

    @Test
    fun testCorruptedChecksumRejection() {
        val validPacket = GarudaPacket(
            packetType = GarudaPacket.TYPE_SOS,
            packetId = 555,
            deviceHash = 666,
            timestamp = 2000,
            latitude = 12.9716,
            longitude = 77.5946
        )

        val bytes = GarudaProtocolEncoderDecoder.encode(validPacket)
        // Corrupt checksum byte at the end
        bytes[bytes.size - 1] = (bytes[bytes.size - 1] + 1).toByte()

        val decoded = GarudaProtocolEncoderDecoder.decode(bytes)
        assertNull(decoded)
    }
}
