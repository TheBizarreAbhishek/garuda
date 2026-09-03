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
        description: String = ""
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
    }
}
