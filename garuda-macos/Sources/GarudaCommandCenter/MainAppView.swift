import SwiftUI

public enum NavigationTab: String, CaseIterable, Identifiable {
    case liveMap = "Live GIS Map"
    case triageKanban = "Triage & Rescue"
    case emergencyBroadcast = "Emergency Broadcast"
    case hazardReports = "Hazard Reports"
    case meshTelemetry = "Mesh Telemetry"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .liveMap: return "map.fill"
        case .triageKanban: return "square.grid.3x2.fill"
        case .emergencyBroadcast: return "antenna.radiowaves.left.and.right"
        case .hazardReports: return "exclamationmark.triangle.fill"
        case .meshTelemetry: return "waveform.path.ecg"
        }
    }
}

public struct MainAppView: View {
    @StateObject private var store = CommandCenterStore()
    @State private var selectedTab: NavigationTab = .liveMap
    
    public init() {}
    
    public var body: some View {
        NavigationSplitView {
            List(NavigationTab.allCases, selection: $selectedTab) { tab in
                NavigationLink(value: tab) {
                    Label(tab.rawValue, systemImage: tab.icon)
                        .font(.headline)
                }
            }
            .navigationTitle("Garuda Command Grid")
            .listStyle(.sidebar)
            
            // Sidebar Footer Alert Status & Live Uplink Status
            VStack(alignment: .leading, spacing: 6) {
                Divider()
                HStack {
                    Circle()
                        .fill(store.isEmergencyBroadcastActive ? Color.red : Color.green)
                        .frame(width: 8, height: 8)
                    Text(store.isEmergencyBroadcastActive ? "ACTIVE EMERGENCY" : "STANDBY")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundColor(store.isEmergencyBroadcastActive ? .red : .green)
                }
                Text(store.activeDistrict)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Divider()
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(store.isServerRunning ? Color.blue : Color.gray)
                        .frame(width: 6, height: 6)
                    Text("Gateway Server: Port \(store.serverPort)")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                
                Text("\(store.connectedClientsCount) Mobile Gateway(s) Linked")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(store.connectedClientsCount > 0 ? .green : .secondary)
            }
            .padding(12)
        } detail: {
            Group {
                switch selectedTab {
                case .liveMap:
                    LiveMapView(store: store)
                case .triageKanban:
                    TriageKanbanView(store: store)
                case .emergencyBroadcast:
                    EmergencyBroadcasterView(store: store)
                case .hazardReports:
                    HazardGalleryView(store: store)
                case .meshTelemetry:
                    MeshTelemetryView(store: store)
                }
            }
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button {
                        store.toggleSimulation()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: store.isSimulatingMeshArrivals ? "dot.radiowaves.left.and.right" : "play.fill")
                                .foregroundColor(store.isSimulatingMeshArrivals ? .green : .secondary)
                            Text(store.isSimulatingMeshArrivals ? "Simulating Mesh..." : "Demo Simulation")
                                .font(.caption.bold())
                        }
                    }
                    .help("Simulate incoming multi-hop BLE mesh SOS packets for live demo")
                }
            }
        }
    }
}
