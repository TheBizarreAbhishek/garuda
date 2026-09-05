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
            VStack(spacing: 0) {
                // Garuda Brand Header
                HStack(spacing: 10) {
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text("PROJECT GARUDA")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                        Text("National Disaster Command")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.black.opacity(0.15))
                
                Divider()
                
                // Sidebar Navigation List with Badges
                List(NavigationTab.allCases, selection: $selectedTab) { tab in
                    NavigationLink(value: tab) {
                        HStack {
                            Label(tab.rawValue, systemImage: tab.icon)
                                .font(.system(size: 13, weight: .semibold))
                            
                            Spacer()
                            
                            // Contextual Tab Badges
                            switch tab {
                            case .liveMap, .triageKanban:
                                if !store.signals.isEmpty {
                                    Text("\(store.signals.count)")
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.red)
                                        .foregroundColor(.white)
                                        .clipShape(Capsule())
                                }
                            case .hazardReports:
                                if !store.hazards.isEmpty {
                                    Text("\(store.hazards.count)")
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.yellow.opacity(0.8))
                                        .foregroundColor(.black)
                                        .clipShape(Capsule())
                                }
                            case .emergencyBroadcast:
                                if store.isEmergencyBroadcastActive {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 8, height: 8)
                                }
                            case .meshTelemetry:
                                if store.activeDevices.count > 0 {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 7, height: 7)
                                }
                            }
                        }
                    }
                }
                .listStyle(.sidebar)
                
                // Sidebar Footer Alert Status & Live Uplink Status
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                    
                    // Emergency Mode Indicator
                    HStack {
                        Circle()
                            .fill(store.isEmergencyBroadcastActive ? Color.red : Color.green)
                            .frame(width: 8, height: 8)
                        Text(store.isEmergencyBroadcastActive ? "ACTIVE EMERGENCY" : "ALL SECTORS STANDBY")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundColor(store.isEmergencyBroadcastActive ? .red : .green)
                    }
                    Text(store.activeDistrict)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    Divider()
                    
                    // Server Port Info
                    HStack(spacing: 4) {
                        Circle()
                            .fill(store.isServerRunning ? Color.blue : Color.gray)
                            .frame(width: 6, height: 6)
                        Text("Gateway SSE: :\(store.serverPort)")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("Online")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.green)
                    }
                    
                    // Clickable Sidebar Device Pill Button
                    Button {
                        isShowingDevicesModal = true
                    } label: {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(store.activeDevices.isEmpty ? Color.secondary : Color.green)
                                .frame(width: 7, height: 7)
                            
                            Text("\(store.activeDevices.count) Field Node(s)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(store.activeDevices.isEmpty ? .secondary : .green)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Color.black.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(store.activeDevices.isEmpty ? Color.white.opacity(0.1) : Color.green.opacity(0.35), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .help("Click to inspect all connected mobile nodes and gateways")
                }
                .padding(12)
            }
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
