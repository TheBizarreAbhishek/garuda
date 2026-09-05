import Foundation
import SwiftUI
import Combine

@MainActor
public final class CommandCenterStore: ObservableObject, CommandGridServerDelegate {
    @Published public var signals: [SosSignal] = []
    @Published public var alerts: [DisasterAlert] = []
    @Published public var hazards: [HazardReport] = []
    @Published public var activeDevices: [ConnectedDevice] = []
    @Published public var notifications: [PushNotificationRecord] = []
    @Published public var shelters: [ReliefShelter] = []
    @Published public var ndrfUnits: [NdrfRescueUnit] = []
    @Published public var selectedSignal: SosSignal?
    @Published public var isEmergencyBroadcastActive: Bool = false
    @Published public var activeDistrict: String = "All Regions (Standby)"
    @Published public var isSimulatingMeshArrivals: Bool = false
    @Published public var connectedClientsCount: Int = 0
    @Published public var serverPort: UInt16 = 8080
    @Published public var isServerRunning: Bool = false
    
    // ISRO / IMD Satellite Layer Controls
    @Published public var satelliteMapMode: SatelliteMapLayerMode = .standardHybrid
    @Published public var imdRadarOpacity: Double = 0.65
    @Published public var isWeatherRadarDrawerOpen: Bool = false
    
    private var simulationTimer: AnyCancellable?
    
    public init() {
        // Pure Real Data Mode: No mock data loaded on startup.
        // Data is populated live from connected mobile devices via CommandGridServer (SSE / :8080)
        // and Firebase Firestore cloud listener.
        setupLiveServer()
        setupLiveFirebaseCloud()
    }
    
    private func setupLiveServer() {
        let server = CommandGridServer.shared
        server.delegate = self
        server.currentAlertProvider = { [weak self] in
            self?.alerts.first
        }
        server.start(port: 8080)
        isServerRunning = server.isRunning
        serverPort = server.port
    }
    
    private func setupLiveFirebaseCloud() {
        FirebaseFirestoreClient.shared.startLiveFirestoreListener { [weak self] cloudSignals in
            guard let self = self else { return }
            for signal in cloudSignals {
                if let index = self.signals.firstIndex(where: { $0.id == signal.id }) {
                    self.signals[index] = signal
                } else {
                    self.signals.insert(signal, at: 0)
                }
            }
        } onHazardsReceived: { [weak self] cloudHazards in
            guard let self = self else { return }
            for hazard in cloudHazards {
                if !self.hazards.contains(where: { $0.id == hazard.id }) {
                    self.hazards.insert(hazard, at: 0)
                }
            }
        } onDevicesReceived: { [weak self] devices in
            guard let self = self else { return }
            withAnimation(.easeInOut) {
                self.activeDevices = devices
                self.connectedClientsCount = devices.count
            }
        } onSheltersReceived: { [weak self] cloudShelters in
            guard let self = self else { return }
            withAnimation(.easeInOut) {
                for shelter in cloudShelters {
                    if let idx = self.shelters.firstIndex(where: { $0.id == shelter.id }) {
                        self.shelters[idx] = shelter
                    } else {
                        self.shelters.append(shelter)
                    }
                }
            }
        }
    }
    
    // MARK: - CommandGridServerDelegate
    public func serverDidReceiveSosSignal(_ signal: SosSignal) {
        withAnimation(.spring()) {
            // Deduplicate by ID if already present
            if let index = signals.firstIndex(where: { $0.id == signal.id }) {
                signals[index] = signal
            } else {
                signals.insert(signal, at: 0)
            }
            selectedSignal = signal
        }
    }
    
    public func serverDidReceiveHazardReport(_ hazard: HazardReport) {
        withAnimation(.spring()) {
            hazards.insert(hazard, at: 0)
        }
    }
    
    public func serverClientConnected(address: String) {
        withAnimation {
            connectedClientsCount += 1
        }
    }
    
    public func serverClientDisconnected(address: String) {
        withAnimation {
            connectedClientsCount = max(0, connectedClientsCount - 1)
        }
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
    
    public var directCloudDevicesCount: Int {
        activeDevices.filter { $0.isDirectCloud }.count
    }
    
    public var meshRelayDevicesCount: Int {
        activeDevices.filter { !$0.isDirectCloud }.count
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
            
            // Sync status update to Firebase Firestore Cloud
            FirebaseFirestoreClient.shared.updateSignalStatusOnCloud(
                signalId: id,
                status: newStatus,
                assignedUnit: assignedUnit
            )
        }
    }
    
    public func broadcastEmergencyActivation(
        title: String,
        severity: String,
        districts: [String],
        instructions: String
    ) {
        guard !districts.isEmpty else { return }
        
        for district in districts {
            let newAlert = DisasterAlert(
                title: title,
                severity: severity,
                targetDistrict: district,
                instructions: instructions,
                isEmergencyActive: true
            )
            // If alert for same district exists, update it, else insert at top
            if let existingIdx = alerts.firstIndex(where: { $0.targetDistrict.lowercased() == district.lowercased() }) {
                alerts[existingIdx] = newAlert
            } else {
                alerts.insert(newAlert, at: 0)
            }
            
            // Sync to Firebase Firestore
            FirebaseFirestoreClient.shared.publishEmergencyActivation(alert: newAlert)
        }
        
        isEmergencyBroadcastActive = true
        let activeList = alerts.filter { $0.isEmergencyActive }.map { $0.targetDistrict }
        activeDistrict = activeList.joined(separator: ", ")
        
        // Broadcast over SSE to connected phones
        CommandGridServer.shared.broadcastSseEvent(
            event: "emergency_activated",
            data: [
                "title": title,
                "severity": severity,
                "district": activeDistrict,
                "districts": districts,
                "instructions": instructions,
                "timestamp": Date().timeIntervalSince1970
            ]
        )
    }
    
    public func broadcastEmergencyActivation(
        title: String,
        severity: String,
        district: String,
        instructions: String
    ) {
        broadcastEmergencyActivation(
            title: title,
            severity: severity,
            districts: [district],
            instructions: instructions
        )
    }
    
    public func broadcastEmergencyDeactivation() {
        isEmergencyBroadcastActive = false
        activeDistrict = "All Regions (Standby)"
        for i in 0..<alerts.count {
            alerts[i].isEmergencyActive = false
        }
        
        // 1. Publish Standby / Deactivation to Firebase Firestore in Cloud
        FirebaseFirestoreClient.shared.deactivateEmergencyOnCloud()
        
        // 2. Broadcast Deactivation to connected devices
        CommandGridServer.shared.broadcastSseEvent(
            event: "emergency_deactivated",
            data: [
                "status": "standby",
                "timestamp": Date().timeIntervalSince1970
            ]
        )
    }
    
    public func deactivateSpecificAlert(id: String) {
        if let idx = alerts.firstIndex(where: { $0.id == id }) {
            alerts[idx].isEmergencyActive = false
        }
        let activeRemaining = alerts.filter { $0.isEmergencyActive }
        if activeRemaining.isEmpty {
            isEmergencyBroadcastActive = false
            activeDistrict = "All Regions (Standby)"
            FirebaseFirestoreClient.shared.deactivateEmergencyOnCloud()
        } else {
            activeDistrict = activeRemaining.map { $0.targetDistrict }.joined(separator: ", ")
        }
    }
    
    public func sendAreaPushNotification(
        title: String,
        message: String,
        priority: String,
        targetArea: String
    ) {
        sendAreaPushNotification(
            title: title,
            message: message,
            priority: priority,
            targetAreas: [targetArea]
        )
    }
    
    public func sendAreaPushNotification(
        title: String,
        message: String,
        priority: String,
        targetAreas: [String]
    ) {
        let joinedTarget = targetAreas.isEmpty ? "Pan-India" : targetAreas.joined(separator: ", ")
        let newNotif = PushNotificationRecord(
            title: title,
            message: message,
            targetArea: joinedTarget,
            priority: priority,
            timestamp: Date(),
            deliveredCount: max(1, activeDevices.count)
        )
        withAnimation(.spring()) {
            notifications.insert(newNotif, at: 0)
        }
        
        // 1. Broadcast SSE push event to all connected field Android nodes
        CommandGridServer.shared.broadcastSseEvent(
            event: "push_notification",
            data: [
                "title": title,
                "message": message,
                "priority": priority,
                "targetArea": joinedTarget,
                "targetAreas": targetAreas,
                "timestamp": Date().timeIntervalSince1970
            ]
        )
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
    
    // MARK: - Relief Shelters Management
    public func addReliefShelter(_ shelter: ReliefShelter) {
        withAnimation(.spring()) {
            if let idx = shelters.firstIndex(where: { $0.id == shelter.id }) {
                shelters[idx] = shelter
            } else {
                shelters.insert(shelter, at: 0)
            }
        }
        FirebaseFirestoreClient.shared.publishReliefShelter(shelter)
    }
    
    public func updateReliefShelter(_ shelter: ReliefShelter) {
        withAnimation(.spring()) {
            if let idx = shelters.firstIndex(where: { $0.id == shelter.id }) {
                shelters[idx] = shelter
            }
        }
        FirebaseFirestoreClient.shared.publishReliefShelter(shelter)
    }
    
    public func deleteReliefShelter(id: String) {
        withAnimation(.spring()) {
            shelters.removeAll(where: { $0.id == id })
        }
        FirebaseFirestoreClient.shared.deleteReliefShelter(id: id)
    }
}
