package com.project.garuda.mesh.protocol

/**
 * Project Garuda Compact Binary Protocol Packet Structure.
 * Fits within 28 bytes for Legacy BLE 31-byte Advertising frames (or extended frames).
 *
 * Byte Layout (27-28 bytes total):
 * - Header (2 bytes): 0x47, 0x44 ("GD")
 * - PacketType (1 byte): 0x01 = SOS, 0x02 = Mesh Chat, 0x03 = Heartbeat / Ack
 * - PacketId (4 bytes): CRC32 / unique hash
 * - DeviceHash (4 bytes): 32-bit device identifier
 * - Timestamp (4 bytes): Unix epoch seconds
 * - Latitude (4 bytes): Int32 fixed-point (lat * 1e7)
 * - Longitude (4 bytes): Int32 fixed-point (lon * 1e7)
 * - EmergencyType (1 byte): 0x00 = None, 0x01 = Medical, 0x02 = Trapped, 0x03 = Fire, 0x04 = Flood
 * - HopAndTtl (1 byte): HopCount (lower 4 bits 0..15), TTL (upper 4 bits 0..15)
 * - Checksum (2 bytes): CRC16-CCITT calculation over pre-checksum byte array
 */
data class GarudaPacket(
    val header: ByteArray = byteArrayOf(MAGIC_BYTE_1, MAGIC_BYTE_2), // "GD"
    val packetType: Byte,
    val packetId: Int,
    val deviceHash: Int,
    val timestamp: Int,
    val latitude: Double,
    val longitude: Double,
    val emergencyType: Byte = EMERGENCY_NONE,
    val hopCount: Int = 0,
    val ttl: Int = DEFAULT_TTL,
    val payload: ByteArray = byteArrayOf(),
    val checksum: Short = 0
) {
    companion object {
        const val MAGIC_BYTE_1: Byte = 0x47.toByte() // 'G'
        const val MAGIC_BYTE_2: Byte = 0x44.toByte() // 'D'

        const val TYPE_SOS: Byte = 0x01
        const val TYPE_CHAT: Byte = 0x02
        const val TYPE_HEARTBEAT: Byte = 0x03
        const val TYPE_EMERGENCY_BROADCAST: Byte = 0x04

        const val EMERGENCY_NONE: Byte = 0x00
        const val EMERGENCY_MEDICAL: Byte = 0x01
        const val EMERGENCY_TRAPPED: Byte = 0x02
        const val EMERGENCY_FIRE: Byte = 0x03
        const val EMERGENCY_FLOOD: Byte = 0x04

        const val DEFAULT_TTL: Int = 5
        const val MAX_HOPS: Int = 15
        const val LEGACY_FRAME_SIZE: Int = 27
    }

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false

        other as GarudaPacket

        if (!header.contentEquals(other.header)) return false
        if (packetType != other.packetType) return false
        if (packetId != other.packetId) return false
        if (deviceHash != other.deviceHash) return false
        if (timestamp != other.timestamp) return false
        if (latitude != other.latitude) return false
        if (longitude != other.longitude) return false
        if (emergencyType != other.emergencyType) return false
        if (hopCount != other.hopCount) return false
        if (ttl != other.ttl) return false
        if (!payload.contentEquals(other.payload)) return false
        if (checksum != other.checksum) return false

        return true
    }

    override fun hashCode(): Int {
        var result = header.contentHashCode()
        result = 31 * result + packetType
        result = 31 * result + packetId
        result = 31 * result + deviceHash
        result = 31 * result + timestamp
        result = 31 * result + latitude.hashCode()
        result = 31 * result + longitude.hashCode()
        result = 31 * result + emergencyType
        result = 31 * result + hopCount
        result = 31 * result + ttl
        result = 31 * result + payload.contentHashCode()
        result = 31 * result + checksum
        return result
    }
}
