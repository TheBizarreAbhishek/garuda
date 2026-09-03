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
                    Text("Gateway Server: :\(store.serverPort)")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(store.connectedClientsCount > 0 ? Color.green : Color.orange)
                        .frame(width: 6, height: 6)
                    Text("\(store.connectedClientsCount) Citizen Device(s) Online")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(store.connectedClientsCount > 0 ? .green : .orange)
                }
                
                if let firstDev = store.activeDevices.first {
                    Text("📱 \(firstDev.name)")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(.green.opacity(0.8))
                        .lineLimit(1)
                }
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
                ToolbarItem(placement: .navigation) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(store.connectedClientsCount > 0 ? Color.green : Color.orange)
                            .frame(width: 8, height: 8)
                        Text(store.connectedClientsCount > 0 
                             ? "🟢 \(store.connectedClientsCount) Active Device (\(store.activeDevices.first?.name ?? "Online"))"
                             : "🟡 Waiting for Phone Link...")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(store.connectedClientsCount > 0 ? .green : .secondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(6)
                }
                
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
