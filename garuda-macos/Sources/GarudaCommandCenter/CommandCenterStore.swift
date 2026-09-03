import Foundation
import SwiftUI
import Combine

@MainActor
public final class CommandCenterStore: ObservableObject {
    @Published public var signals: [SosSignal] = []
    @Published public var alerts: [DisasterAlert] = []
    @Published public var hazards: [HazardReport] = []
    @Published public var selectedSignal: SosSignal?
    @Published public var isEmergencyBroadcastActive: Bool = true
    @Published public var activeDistrict: String = "Wayanad / Kerala Region"
    @Published public var isSimulatingMeshArrivals: Bool = false
    
    private var simulationTimer: AnyCancellable?
    
    public init() {
        loadMockData()
    }
    
    public var criticalCount: Int {
        signals.filter { $0.priority == .critical && $0.status != .rescued }.count
    }
    
    public var inProgressCount: Int {
        signals.filter { $0.status == .inProgress || $0.status == .dispatched }.count
    }
    
    public var resolvedCount: Int {
        signals.filter { $0.status == .rescued }.count
    }
    
    public var totalActiveSignals: Int {
        signals.filter { $0.status != .rescued }.count
    }
    
    public func updateSignalStatus(id: String, newStatus: RescueStatus, assignedUnit: String? = nil) {
        if let index = signals.firstIndex(where: { $0.id == id }) {
            signals[index].status = newStatus
            if let assignedUnit = assignedUnit {
                signals[index].assignedUnit = assignedUnit
            }
            if selectedSignal?.id == id {
                selectedSignal = signals[index]
            }
        }
    }
    
    public func broadcastEmergencyActivation(
        title: String,
        severity: String,
        district: String,
        instructions: String
    ) {
        let newAlert = DisasterAlert(
            title: title,
            severity: severity,
            targetDistrict: district,
            instructions: instructions,
            isEmergencyActive: true
        )
        alerts.insert(newAlert, at: 0)
        isEmergencyBroadcastActive = true
        activeDistrict = district
    }
    
    public func toggleSimulation() {
        isSimulatingMeshArrivals.toggle()
        if isSimulatingMeshArrivals {
            startSimulation()
        } else {
            simulationTimer?.cancel()
            simulationTimer = nil
        }
    }
    
    private func startSimulation() {
        simulationTimer = Timer.publish(every: 4.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.injectSimulatedMeshPacket()
            }
    }
    
    private func injectSimulatedMeshPacket() {
        let names = ["Aarav Sharma", "Priya Nair", "Mohammed Tariq", "Ananya Sen", "Rajesh Varma", "Sunita Patil"]
        let types: [EmergencyType] = [.trapped, .medical, .flood, .structuralCollapse, .general]
        let priorities: [TriagePriority] = [.critical, .urgent, .moderate]
        let bloodGroups = ["O+", "A+", "B+", "AB+", "O-"]
        
        let randomName = names.randomElement() ?? "Citizen Survivor"
        let randomType = types.randomElement() ?? .general
        let randomPriority = priorities.randomElement() ?? .urgent
        let randomBlood = bloodGroups.randomElement() ?? "O+"
        let randomHops = Int.random(in: 1...5)
        let randomBattery = Int.random(in: 15...80)
        
        // Jitter around disaster center (e.g. 11.6854, 76.1320 - Wayanad / Calicut)
        let latOffset = Double.random(in: -0.04...0.04)
        let lonOffset = Double.random(in: -0.04...0.04)
        
        let newSignal = SosSignal(
            victimName: randomName,
            bloodGroup: randomBlood,
            emergencyType: randomType,
            priority: randomPriority,
            latitude: 11.6854 + latOffset,
            longitude: 76.1320 + lonOffset,
            hopCount: randomHops,
            batteryLevel: randomBattery,
            timestamp: Date(),
            status: .pending,
            notes: "Incoming multi-hop mesh packet via Uplink Gateway #0\(Int.random(in: 1...3))",
            relayedByGatewayId: "GATEWAY-NODE-0\(Int.random(in: 1...4))"
        )
        
        withAnimation(.spring()) {
            self.signals.insert(newSignal, at: 0)
        }
    }
    
    private func loadMockData() {
        signals = [
            SosSignal(
                victimName: "Rohan Kulkarni & Family",
                bloodGroup: "B+",
                emergencyType: .trapped,
                priority: .critical,
                latitude: 11.6854,
                longitude: 76.1320,
                hopCount: 3,
                batteryLevel: 22,
                timestamp: Date().addingTimeInterval(-300),
                status: .pending,
                notes: "3 people trapped on 2nd floor, water level rising rapidly. Relayed over 3 BLE hops.",
                relayedByGatewayId: "GATEWAY-UPLINK-KERALA-01"
            ),
            SosSignal(
                victimName: "Dr. Meenakshi Sundaram",
                bloodGroup: "O+",
                emergencyType: .medical,
                priority: .critical,
                latitude: 11.6912,
                longitude: 76.1410,
                hopCount: 2,
                batteryLevel: 41,
                timestamp: Date().addingTimeInterval(-720),
                status: .dispatched,
                notes: "Elderly patient requiring oxygen and insulin. Debris blocking road.",
                relayedByGatewayId: "GATEWAY-UPLINK-KERALA-02",
                assignedUnit: "NDRF Team Alpha (12 Personnel)"
            ),
            SosSignal(
                victimName: "Vikas Deshmukh",
                bloodGroup: "AB+",
                emergencyType: .flood,
                priority: .urgent,
                latitude: 11.6780,
                longitude: 76.1250,
                hopCount: 1,
                batteryLevel: 68,
                timestamp: Date().addingTimeInterval(-1200),
                status: .inProgress,
                notes: "Stuck on bridge embankment. Boat needed.",
                relayedByGatewayId: "GATEWAY-UPLINK-KERALA-01",
                assignedUnit: "SDRF Boat Squadron 4"
            ),
            SosSignal(
                victimName: "Kavita Pillai",
                bloodGroup: "A+",
                emergencyType: .general,
                priority: .safe,
                latitude: 11.6990,
                longitude: 76.1550,
                hopCount: 4,
                batteryLevel: 89,
                timestamp: Date().addingTimeInterval(-1800),
                status: .rescued,
                notes: "Evacuated to Meppadi Community Relief Shelter.",
                relayedByGatewayId: "GATEWAY-UPLINK-KERALA-03",
                assignedUnit: "Local Volunteer Rescue Group"
            )
        ]
        
        alerts = [
            DisasterAlert(
                title: "Flash Flood & Landslide Red Alert",
                severity: "SEVERE EMERGENCY",
                targetDistrict: "Wayanad / Calicut District",
                instructions: "NDMA Directive: Immediate evacuation of low-lying flood zones. Offline BLE Mesh Activated on all citizen devices.",
                timestamp: Date().addingTimeInterval(-3600),
                isEmergencyActive: true
            )
        ]
        
        hazards = [
            HazardReport(
                title: "Meppadi Main Bridge Collapsed",
                category: "Structural / Road Cutoff",
                latitude: 11.6890,
                longitude: 76.1360,
                reporterName: "Mesh Node #104",
                reportedAt: Date().addingTimeInterval(-900),
                isVerified: true,
                description: "Bridge completely washed away. Route completely impassable for heavy rescue vehicles."
            ),
            HazardReport(
                title: "High Voltage Power Line Down",
                category: "Electrical Hazard",
                latitude: 11.6810,
                longitude: 76.1280,
                reporterName: "Mesh Node #082",
                reportedAt: Date().addingTimeInterval(-1400),
                isVerified: false,
                description: "Submerged transformer sparking in standing water. Electrocution risk."
            )
        ]
        
        selectedSignal = signals.first
    }
}
