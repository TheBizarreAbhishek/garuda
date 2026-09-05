import Foundation
import CoreLocation

public enum EmergencyType: String, Codable, Hashable, CaseIterable, Identifiable {
    case trapped = "Trapped under Debris"
    case medical = "Medical Emergency"
    case flood = "Flash Flood / Drowning"
    case fire = "Fire Hazard"
    case structuralCollapse = "Building Collapse"
    case general = "General Assistance"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .trapped: return "person.fill.turn.down"
        case .medical: return "cross.case.fill"
        case .flood: return "water.waves"
        case .fire: return "flame.fill"
        case .structuralCollapse: return "building.2.crop.between.the.margins"
        case .general: return "exclamationmark.triangle.fill"
        }
    }
}

public enum TriagePriority: String, Codable, Hashable, CaseIterable, Comparable {
    case critical = "CRITICAL (Red)"
    case urgent = "URGENT (Orange)"
    case moderate = "MODERATE (Yellow)"
    case safe = "SAFE (Green)"
    
    public var order: Int {
        switch self {
        case .critical: return 0
        case .urgent: return 1
        case .moderate: return 2
        case .safe: return 3
        }
    }
    
    public static func < (lhs: TriagePriority, rhs: TriagePriority) -> Bool {
        lhs.order < rhs.order
    }
}

public enum RescueStatus: String, Codable, Hashable, CaseIterable, Identifiable {
    case pending = "Pending Triage"
    case dispatched = "NDRF Dispatched"
    case inProgress = "Rescue In Progress"
    case rescued = "Resolved / Safe"
    
    public var id: String { rawValue }
}

public struct SosSignal: Identifiable, Codable, Hashable {
    public let id: String
    public var victimName: String
    public var bloodGroup: String
    public var emergencyType: EmergencyType
    public var priority: TriagePriority
    public var latitude: Double
    public var longitude: Double
    public var hopCount: Int
    public var batteryLevel: Int
    public var timestamp: Date
    public var status: RescueStatus
    public var notes: String
    public var relayedByGatewayId: String
    public var assignedUnit: String?
    
    public var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    public init(
        id: String = UUID().uuidString,
        victimName: String,
        bloodGroup: String = "O+",
        emergencyType: EmergencyType,
        priority: TriagePriority,
        latitude: Double,
        longitude: Double,
        hopCount: Int = 1,
        batteryLevel: Int = 85,
        timestamp: Date = Date(),
        status: RescueStatus = .pending,
        notes: String = "",
        relayedByGatewayId: String = "GATEWAY-NODE-01",
        assignedUnit: String? = nil
    ) {
        self.id = id
        self.victimName = victimName
        self.bloodGroup = bloodGroup
        self.emergencyType = emergencyType
        self.priority = priority
        self.latitude = latitude
        self.longitude = longitude
        self.hopCount = hopCount
        self.batteryLevel = batteryLevel
        self.timestamp = timestamp
        self.status = status
        self.notes = notes
        self.relayedByGatewayId = relayedByGatewayId
        self.assignedUnit = assignedUnit
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: SosSignal, rhs: SosSignal) -> Bool {
        lhs.id == rhs.id
    }
}

public struct DisasterAlert: Identifiable, Codable, Hashable {
    public let id: String
    public var title: String
    public var severity: String
    public var targetDistrict: String
    public var instructions: String
    public var timestamp: Date
    public var isEmergencyActive: Bool
    
    public init(
        id: String = UUID().uuidString,
        title: String,
        severity: String,
        targetDistrict: String,
        instructions: String,
        timestamp: Date = Date(),
        isEmergencyActive: Bool = true
    ) {
        self.id = id
        self.title = title
        self.severity = severity
        self.targetDistrict = targetDistrict
        self.instructions = instructions
        self.timestamp = timestamp
        self.isEmergencyActive = isEmergencyActive
    }
}

public enum HazardStatus: String, Codable, CaseIterable, Identifiable {
    case unverified = "Pending Review"
    case roadBlocked = "Verified: Road Blocked"
    case verifiedActive = "Verified Hazard"
    case resolved = "Cleared / Resolved"
    case falseAlarm = "Flagged False Alarm"
    
    public var id: String { rawValue }
}

public struct HazardReport: Identifiable, Codable, Hashable {
    public let id: String
    public var title: String
    public var category: String
    public var latitude: Double
    public var longitude: Double
    public var reporterName: String
    public var reportedAt: Date
    public var isVerified: Bool
    public var description: String
    public var status: HazardStatus
    public var peerConfirmations: Int
    public var severity: String
    public var assignedTeam: String?
    
    public var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    public init(
        id: String = UUID().uuidString,
        title: String,
        category: String,
        latitude: Double,
        longitude: Double,
        reporterName: String = "Citizen via BLE Mesh",
        reportedAt: Date = Date(),
        isVerified: Bool = false,
        description: String = "",
        status: HazardStatus? = nil,
        peerConfirmations: Int = 1,
        severity: String = "High",
        assignedTeam: String? = nil
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.latitude = latitude
        self.longitude = longitude
        self.reporterName = reporterName
        self.reportedAt = reportedAt
        self.isVerified = isVerified
        self.description = description
        self.status = status ?? (isVerified ? .verifiedActive : .unverified)
        self.peerConfirmations = peerConfirmations
        self.severity = severity
        self.assignedTeam = assignedTeam
    }
}

public struct ConnectedDevice: Identifiable, Codable, Hashable {
    public let id: String
    public var name: String
    public var batteryLevel: Int
    public var status: String
    public var meshRole: String
    public var location: String
    public var latitude: Double
    public var longitude: Double
    public var lastSeen: Date
    public var isOnline: Bool
    public var connectionType: String
    public var hopCount: Int
    
    public var isDirectCloud: Bool {
        connectionType.uppercased().contains("CLOUD") || 
        connectionType.uppercased().contains("DIRECT") || 
        connectionType.uppercased().contains("INTERNET") ||
        meshRole.localizedCaseInsensitiveContains("Gateway") ||
        hopCount == 0
    }
    
    public var coordinate: CLLocationCoordinate2D? {
        if latitude != 0.0 && longitude != 0.0 {
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
        return nil
    }
    
    public init(
        id: String,
        name: String,
        batteryLevel: Int = 100,
        status: String = "ONLINE",
        meshRole: String = "Relay Gateway Node",
        location: String = "Detecting GPS...",
        latitude: Double = 0.0,
        longitude: Double = 0.0,
        lastSeen: Date = Date(),
        isOnline: Bool = true,
        connectionType: String = "CLOUD_DIRECT",
        hopCount: Int = 0
    ) {
        self.id = id
        self.name = name
        self.batteryLevel = batteryLevel
        self.status = status
        self.meshRole = meshRole
        self.location = location
        self.latitude = latitude
        self.longitude = longitude
        self.lastSeen = lastSeen
        self.isOnline = isOnline
        self.connectionType = connectionType
        self.hopCount = hopCount
    }
}

public struct PushNotificationRecord: Identifiable, Codable, Hashable {
    public let id: String
    public let title: String
    public let message: String
    public let targetArea: String
    public let priority: String
    public let timestamp: Date
    public let deliveredCount: Int
    
    public init(
        id: String = UUID().uuidString,
        title: String,
        message: String,
        targetArea: String,
        priority: String,
        timestamp: Date = Date(),
        deliveredCount: Int = 1
    ) {
        self.id = id
        self.title = title
        self.message = message
        self.targetArea = targetArea
        self.priority = priority
        self.timestamp = timestamp
        self.deliveredCount = deliveredCount
    }
}

public enum SatelliteMapLayerMode: String, CaseIterable, Identifiable {
    case standardHybrid = "3D Hybrid Satellite"
    case isroBhuvan = "ISRO Bhuvan NDEM GIS"
    case imdDopplerRadar = "IMD INSAT-3DS Live Radar"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .standardHybrid: return "globe.asia.australia.fill"
        case .isroBhuvan: return "building.columns.fill"
        case .imdDopplerRadar: return "cloud.bolt.rain.fill"
        }
    }
    
    public var agency: String {
        switch self {
        case .standardHybrid: return "Apple MapKit Ultra-HD 3D"
        case .isroBhuvan: return "ISRO NRSC Cartosat & NDEM Layers"
        case .imdDopplerRadar: return "IMD & ISRO MOSDAC Live Weather Radar"
        }
    }
}

public struct ReliefShelter: Identifiable, Hashable, Codable {
    public let id: String
    public let name: String
    public let latitude: Double
    public let longitude: Double
    public let capacity: Int
    public let currentOccupancy: Int
    public let suppliesStatus: String
    public let contactPhone: String
    
    public var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        latitude: Double,
        longitude: Double,
        capacity: Int,
        currentOccupancy: Int,
        suppliesStatus: String = "Ample Food, Water & Medical Aid",
        contactPhone: String = "1078 (Disaster Helpline)"
    ) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.capacity = capacity
        self.currentOccupancy = currentOccupancy
        self.suppliesStatus = suppliesStatus
        self.contactPhone = contactPhone
    }
}

public struct NdrfRescueUnit: Identifiable, Hashable, Codable {
    public let id: String
    public let unitName: String
    public let battalion: String
    public let type: String
    public let latitude: Double
    public let longitude: Double
    public let status: String
    public let assignedVictimId: String?
    
    public var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    public init(
        id: String = UUID().uuidString,
        unitName: String,
        battalion: String = "10th Battalion NDRF",
        type: String = "Rapid Flood & Airborne Rescue Unit",
        latitude: Double,
        longitude: Double,
        status: String = "Deployed On-Scene",
        assignedVictimId: String? = nil
    ) {
        self.id = id
        self.unitName = unitName
        self.battalion = battalion
        self.type = type
        self.latitude = latitude
        self.longitude = longitude
        self.status = status
        self.assignedVictimId = assignedVictimId
    }
}
