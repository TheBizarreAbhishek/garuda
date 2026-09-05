import Foundation

public struct TestRunner {
    @MainActor
    public static func runAllTests() -> Bool {
        print("========================================")
        print("    GARUDA COMMAND GRID TEST SUITE")
        print("========================================")
        
        var passed = 0
        var failed = 0
        
        func test(_ name: String, block: () throws -> Void) {
            do {
                try block()
                print("  [PASS] \(name)")
                passed += 1
            } catch {
                print("  [FAIL] \(name): \(error)")
                failed += 1
            }
        }
        
        func asyncTest(_ name: String, block: () async throws -> Void) async {
            do {
                try await block()
                print("  [PASS] \(name)")
                passed += 1
            } catch {
                print("  [FAIL] \(name): \(error)")
                failed += 1
            }
        }
        
        // 1. Initial State (Clean Real-World Mode)
        let store = CommandCenterStore()
        test("Initial Clean Real-World Store State") {
            assert(store.signals.isEmpty, "Signals should be empty on startup (no mock data)")
            assert(store.hazards.isEmpty, "Hazards should be empty on startup")
            assert(store.isEmergencyBroadcastActive == false, "Emergency broadcast should be standby initially")
        }
        
        // 2. Real-time Ingestion & Status Transition Workflow
        test("Rescue Status Transition & NDRF Assignment") {
            let testSignal = SosSignal(
                id: "TEST-SIG-001",
                victimName: "Real Citizen Node",
                bloodGroup: "O+",
                emergencyType: .medical,
                priority: .critical,
                latitude: 19.0760,
                longitude: 72.8777,
                hopCount: 2,
                batteryLevel: 45,
                timestamp: Date(),
                status: .pending,
                notes: "Direct live packet test",
                relayedByGatewayId: "GATEWAY-LIVE-01"
            )
            store.serverDidReceiveSosSignal(testSignal)
            assert(store.signals.count == 1, "Store should contain received live signal")
            
            store.updateSignalStatus(
                id: "TEST-SIG-001",
                newStatus: .dispatched,
                assignedUnit: "NDRF Battalion 4"
            )
            
            let dispatchedSignal = store.signals.first(where: { $0.id == "TEST-SIG-001" })
            assert(dispatchedSignal?.status == .dispatched, "Status should be dispatched")
            assert(dispatchedSignal?.assignedUnit == "NDRF Battalion 4", "Unit should be assigned")
            
            store.updateSignalStatus(id: "TEST-SIG-001", newStatus: .rescued)
            let rescuedSignal = store.signals.first(where: { $0.id == "TEST-SIG-001" })
            assert(rescuedSignal?.status == .rescued, "Status should be rescued")
        }
        
        // 3. Emergency Activation Broadcast
        test("Emergency Activation Broadcast & Geofence Setting") {
            let initialCount = store.alerts.count
            store.broadcastEmergencyActivation(
                title: "Flash Flood Warning",
                severity: "Level 3 - Critical",
                district: "Wayanad District",
                instructions: "Immediate evacuation ordered."
            )
            
            assert(store.alerts.count == initialCount + 1, "Alert count should increment")
            assert(store.isEmergencyBroadcastActive == true, "Emergency broadcast should be active")
            assert(store.activeDistrict == "Wayanad District", "Active district should update")
        }
        
        // 4. Triage Priority Ordering
        test("Triage Priority Ordering Logic") {
            assert(TriagePriority.critical < TriagePriority.urgent, "Critical must be higher priority than urgent")
            assert(TriagePriority.urgent < TriagePriority.moderate, "Urgent must be higher priority than moderate")
            assert(TriagePriority.moderate < TriagePriority.safe, "Moderate must be higher priority than safe")
        }
        
        // 5. Model Serialization & Hashability
        test("SOS Signal JSON Serialization and MapKit Hashability") {
            let signal1 = SosSignal(
                id: "TEST-UUID-01",
                victimName: "Aarav Sharma",
                emergencyType: .trapped,
                priority: .critical,
                latitude: 11.6854,
                longitude: 76.1320
            )
            
            let signal2 = SosSignal(
                id: "TEST-UUID-01",
                victimName: "Aarav Sharma",
                emergencyType: .trapped,
                priority: .critical,
                latitude: 11.6854,
                longitude: 76.1320
            )
            
            assert(signal1 == signal2, "Equality check must match by ID")
            assert(signal1.hashValue == signal2.hashValue, "Hash values must match for MapKit selection")
            
            let data = try JSONEncoder().encode(signal1)
            let decoded = try JSONDecoder().decode(SosSignal.self, from: data)
            assert(decoded.id == signal1.id, "Decoded ID must match")
            assert(decoded.victimName == "Aarav Sharma", "Decoded name must match")
        }
        
        print("========================================")
        print("  SUMMARY: \(passed) passed, \(failed) failed")
        print("========================================")
        
        return failed == 0
    }
}
