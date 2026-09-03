import Foundation
import Combine

public final class FirebaseFirestoreClient: ObservableObject, @unchecked Sendable {
    public static let shared = FirebaseFirestoreClient()
    
    @Published public var projectId: String = "garuda-disaster-sih"
    @Published public var apiKey: String = ""
    @Published public var isSyncing: Bool = false
    @Published public var lastSyncTime: Date?
    @Published public var connectionStatus: String = "Connected to Firebase Firestore"
    
    private var cancellables = Set<AnyCancellable>()
    private var pollTimer: AnyCancellable?
    
    public init(projectId: String = "garuda-disaster-sih") {
        self.projectId = projectId
    }
    
    public var firestoreBaseUrl: String {
        "https://firestore.googleapis.com/v1/projects/\(projectId)/databases/(default)/documents"
    }
    
    // MARK: - Polling / Streaming Listener
    public func startLiveFirestoreListener(
        onSosReceived: @escaping @MainActor ([SosSignal]) -> Void,
        onHazardsReceived: @escaping @MainActor ([HazardReport]) -> Void
    ) {
        pollTimer?.cancel()
        
        // Initial fetch
        fetchSosSignals(completion: onSosReceived)
        fetchHazards(completion: onHazardsReceived)
        
        // Live poll every 3 seconds for new cloud documents
        pollTimer = Timer.publish(every: 3.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.fetchSosSignals(completion: onSosReceived)
                self?.fetchHazards(completion: onHazardsReceived)
            }
    }
    
    public func stopListener() {
        pollTimer?.cancel()
        pollTimer = nil
    }
    
    // MARK: - Fetch SOS Signals from Firestore
    public func fetchSosSignals(completion: @escaping @MainActor ([SosSignal]) -> Void) {
        guard let url = URL(string: "\(firestoreBaseUrl)/disaster_sos") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 5.0
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self, let data = data, error == nil else { return }
            
            do {
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let documents = json["documents"] as? [[String: Any]] else {
                    return
                }
                
                var parsedSignals: [SosSignal] = []
                for doc in documents {
                    guard let fields = doc["fields"] as? [String: Any],
                          let name = doc["name"] as? String else { continue }
                    
                    let docId = name.components(separatedBy: "/").last ?? UUID().uuidString
                    let victimName = (fields["victimName"] as? [String: Any])?["stringValue"] as? String ?? "Distress Victim"
                    let bloodGroup = (fields["bloodGroup"] as? [String: Any])?["stringValue"] as? String ?? "O+"
                    let lat = (fields["latitude"] as? [String: Any])?["doubleValue"] as? Double 
                        ?? Double((fields["latitude"] as? [String: Any])?["integerValue"] as? String ?? "") ?? 11.6854
                    let lon = (fields["longitude"] as? [String: Any])?["doubleValue"] as? Double 
                        ?? Double((fields["longitude"] as? [String: Any])?["integerValue"] as? String ?? "") ?? 76.1320
                    let hopCount = Int((fields["hopCount"] as? [String: Any])?["integerValue"] as? String ?? "1") ?? 1
                    let batteryLevel = Int((fields["batteryLevel"] as? [String: Any])?["integerValue"] as? String ?? "80") ?? 80
                    let notes = (fields["notes"] as? [String: Any])?["stringValue"] as? String ?? "Cloud Synced via Gateway"
                    let gatewayId = (fields["relayedByGatewayId"] as? [String: Any])?["stringValue"] as? String ?? "GATEWAY-CLOUD"
                    let priorityStr = (fields["priority"] as? [String: Any])?["stringValue"] as? String ?? "CRITICAL (Red)"
                    let statusStr = (fields["status"] as? [String: Any])?["stringValue"] as? String ?? "Pending Triage"
                    
                    let priority = TriagePriority(rawValue: priorityStr) ?? .critical
                    let status = RescueStatus(rawValue: statusStr) ?? .pending
                    
                    let signal = SosSignal(
                        id: docId,
                        victimName: victimName,
                        bloodGroup: bloodGroup,
                        emergencyType: .trapped,
                        priority: priority,
                        latitude: lat,
                        longitude: lon,
                        hopCount: hopCount,
                        batteryLevel: batteryLevel,
                        timestamp: Date(),
                        status: status,
                        notes: notes,
                        relayedByGatewayId: gatewayId
                    )
                    parsedSignals.append(signal)
                }
                
                DispatchQueue.main.async {
                    self.lastSyncTime = Date()
                    self.isSyncing = false
                    completion(parsedSignals)
                }
            } catch {
                // Ignore parse errors on empty collection
            }
        }.resume()
    }
    
    // MARK: - Fetch Hazards
    public func fetchHazards(completion: @escaping @MainActor ([HazardReport]) -> Void) {
        guard let url = URL(string: "\(firestoreBaseUrl)/hazard_reports") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 5.0
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else { return }
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let documents = json["documents"] as? [[String: Any]] {
                var parsedHazards: [HazardReport] = []
                for doc in documents {
                    guard let fields = doc["fields"] as? [String: Any],
                          let name = doc["name"] as? String else { continue }
                    
                    let docId = name.components(separatedBy: "/").last ?? UUID().uuidString
                    let title = (fields["title"] as? [String: Any])?["stringValue"] as? String ?? "Hazard"
                    let category = (fields["category"] as? [String: Any])?["stringValue"] as? String ?? "Obstacle"
                    let desc = (fields["description"] as? [String: Any])?["stringValue"] as? String ?? ""
                    let reporter = (fields["reporterName"] as? [String: Any])?["stringValue"] as? String ?? "Citizen"
                    let lat = (fields["latitude"] as? [String: Any])?["doubleValue"] as? Double ?? 11.6854
                    let lon = (fields["longitude"] as? [String: Any])?["doubleValue"] as? Double ?? 76.1320
                    let isVerified = (fields["isVerified"] as? [String: Any])?["booleanValue"] as? Bool ?? false
                    
                    let hazard = HazardReport(
                        id: docId,
                        title: title,
                        category: category,
                        latitude: lat,
                        longitude: lon,
                        reporterName: reporter,
                        reportedAt: Date(),
                        isVerified: isVerified,
                        description: desc
                    )
                    parsedHazards.append(hazard)
                }
                
                DispatchQueue.main.async {
                    completion(parsedHazards)
                }
            }
        }.resume()
    }
    
    // MARK: - Broadcast Emergency Activation Order to Firestore
    public func publishEmergencyActivation(alert: DisasterAlert) {
        guard let url = URL(string: "\(firestoreBaseUrl)/alerts/current_status") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "fields": [
                "title": ["stringValue": alert.title],
                "severity": ["stringValue": alert.severity],
                "targetDistrict": ["stringValue": alert.targetDistrict],
                "instructions": ["stringValue": alert.instructions],
                "isEmergencyActive": ["booleanValue": alert.isEmergencyActive],
                "timestamp": ["integerValue": "\(Int(alert.timestamp.timeIntervalSince1970))"]
            ]
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else { return }
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("[FirebaseClient] Error publishing alert: \(error)")
            } else {
                print("[FirebaseClient] Emergency activation successfully written to Firestore!")
            }
        }.resume()
    }
    
    // MARK: - Update Signal Status on Firestore
    public func updateSignalStatusOnCloud(signalId: String, status: RescueStatus, assignedUnit: String?) {
        guard let url = URL(string: "\(firestoreBaseUrl)/disaster_sos/\(signalId)?updateMask.fieldPaths=status&updateMask.fieldPaths=assignedUnit") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var fields: [String: Any] = [
            "status": ["stringValue": status.rawValue]
        ]
        if let assignedUnit = assignedUnit {
            fields["assignedUnit"] = ["stringValue": assignedUnit]
        }
        
        let body: [String: Any] = ["fields": fields]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request).resume()
    }
}
