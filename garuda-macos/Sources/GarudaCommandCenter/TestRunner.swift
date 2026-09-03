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
        
        // 1. Initial State
        let store = CommandCenterStore()
        test("Initial Store State Verification") {
            assert(store.totalActiveSignals >= 3, "Total active signals must be >= 3")
            assert(store.criticalCount >= 1, "Critical signals must be >= 1")
            assert(store.inProgressCount >= 1, "In-progress signals must be >= 1")
            assert(store.resolvedCount >= 1, "Resolved signals must be >= 1")
        }
        
        // 2. Status Transition Workflow
        test("Rescue Status Transition & NDRF Assignment") {
            guard let pending = store.signals.first(where: { $0.status == .pending }) else {
                throw NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "No pending signal"])
            }
            
            store.updateSignalStatus(
                id: pending.id,
                newStatus: .dispatched,
                assignedUnit: "NDRF Battalion 4"
            )
            
            let dispatchedSignal = store.signals.first(where: { $0.id == pending.id })
            assert(dispatchedSignal?.status == .dispatched, "Status should be dispatched")
            assert(dispatchedSignal?.assignedUnit == "NDRF Battalion 4", "Unit should be assigned")
            
            store.updateSignalStatus(id: pending.id, newStatus: .rescued)
            let rescuedSignal = store.signals.first(where: { $0.id == pending.id })
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
