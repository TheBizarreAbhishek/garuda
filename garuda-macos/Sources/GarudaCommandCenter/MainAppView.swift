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
    @State private var isShowingDevicesModal: Bool = false
    @State private var isShowingEmergencyModal: Bool = false
    
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
            VStack(alignment: .leading, spacing: 8) {
                Divider()
                
                // Emergency Mode Indicator
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
                
                // Server Port Info
                HStack(spacing: 4) {
                    Circle()
                        .fill(store.isServerRunning ? Color.blue : Color.gray)
                        .frame(width: 6, height: 6)
                    Text("Gateway Server: :\(store.serverPort)")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                
                // Clickable Sidebar Device Pill Button
                Button {
                    isShowingDevicesModal = true
                } label: {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(store.activeDevices.isEmpty ? Color.orange : Color.green)
                            .frame(width: 7, height: 7)
                        
                        Text("\(store.activeDevices.count) Online Node(s)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(store.activeDevices.isEmpty ? .orange : .green)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.25))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(store.activeDevices.isEmpty ? Color.orange.opacity(0.3) : Color.green.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .help("Click to inspect all connected mobile nodes and gateways")
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
        }
        .sheet(isPresented: $isShowingDevicesModal) {
            ConnectedDevicesModalView(store: store)
        }
    }
}
