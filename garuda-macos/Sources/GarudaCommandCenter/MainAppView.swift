import SwiftUI

public enum NavigationTab: String, CaseIterable, Identifiable {
    case liveMap = "Live GIS Map"
    case triageKanban = "Triage & Rescue"
    case emergencyBroadcast = "Emergency Broadcast"
    case imdRadar = "IMD Satellite Radar"
    case hazardReports = "Hazard Reports"
    case meshTelemetry = "Mesh Telemetry"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .liveMap: return "map.fill"
        case .triageKanban: return "square.grid.3x2.fill"
        case .emergencyBroadcast: return "antenna.radiowaves.left.and.right"
        case .imdRadar: return "satellite.fill"
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
            VStack(spacing: 12) {
                // 1. Garuda Brand Header Box Card
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.blue.opacity(0.25))
                            .frame(width: 32, height: 32)
                        Image(systemName: "shield.checkered")
                            .font(.system(size: 16, weight: .black))
                            .foregroundColor(.blue)
                    }
                    
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
                .padding(10)
                .background(Color.blue.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal, 12)
                .padding(.top, 12)
                
                // 2. Navigation Items: Modular Boxed Cards
                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(NavigationTab.allCases) { tab in
                            Button {
                                selectedTab = tab
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: tab.icon)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(selectedTab == tab ? .cyan : .secondary)
                                        .frame(width: 18)
                                    
                                    Text(tab.rawValue)
                                        .font(.system(size: 12, weight: selectedTab == tab ? .bold : .medium))
                                        .foregroundColor(selectedTab == tab ? .white : .primary)
                                    
                                    Spacer()
                                    
                                    // Contextual Badges
                                    switch tab {
                                    case .liveMap, .triageKanban:
                                        if !store.signals.isEmpty {
                                            Text("\(store.signals.count)")
                                                .font(.system(size: 9, weight: .black, design: .monospaced))
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.red)
                                                .foregroundColor(.white)
                                                .clipShape(Capsule())
                                        }
                                    case .hazardReports:
                                        if !store.hazards.isEmpty {
                                            Text("\(store.hazards.count)")
                                                .font(.system(size: 9, weight: .black, design: .monospaced))
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.yellow.opacity(0.9))
                                                .foregroundColor(.black)
                                                .clipShape(Capsule())
                                        }
                                    case .emergencyBroadcast:
                                        if store.isEmergencyBroadcastActive {
                                            Circle()
                                                .fill(Color.red)
                                                .frame(width: 7, height: 7)
                                        }
                                    case .imdRadar:
                                        Circle()
                                            .fill(Color.cyan)
                                            .frame(width: 6, height: 6)
                                    case .meshTelemetry:
                                        if store.activeDevices.count > 0 {
                                            Circle()
                                                .fill(Color.green)
                                                .frame(width: 6, height: 6)
                                        }
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(selectedTab == tab ? Color.cyan.opacity(0.15) : Color.white.opacity(0.03))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(selectedTab == tab ? Color.cyan.opacity(0.5) : Color.white.opacity(0.06), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 12)
                }
                
                Spacer()
                
                // 3. Bottom Status & Uplink Box Cards
                VStack(spacing: 8) {
                    // Box A: Emergency Mode Status Card
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Circle()
                                .fill(store.isEmergencyBroadcastActive ? Color.red : Color.green)
                                .frame(width: 7, height: 7)
                            Text(store.isEmergencyBroadcastActive ? "ACTIVE EMERGENCY" : "ALL SECTORS STANDBY")
                                .font(.system(size: 9, weight: .black, design: .monospaced))
                                .foregroundColor(store.isEmergencyBroadcastActive ? .red : .green)
                            Spacer()
                        }
                        
                        Text(store.activeDistrict)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    .padding(10)
                    .background(store.isEmergencyBroadcastActive ? Color.red.opacity(0.10) : Color.green.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(store.isEmergencyBroadcastActive ? Color.red.opacity(0.35) : Color.green.opacity(0.25), lineWidth: 1)
                    )
                    
                    // Box B: Gateway & Field Nodes Registry Card
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(store.isServerRunning ? Color.blue : Color.gray)
                                .frame(width: 5, height: 5)
                            Text("Gateway SSE: :\(String(store.serverPort))")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("Online")
                                .font(.system(size: 8, weight: .black, design: .monospaced))
                                .foregroundColor(.green)
                        }
                        
                        Divider().opacity(0.3)
                        
                        Button {
                            isShowingDevicesModal = true
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("FIELD NODES REGISTRY")
                                        .font(.system(size: 8, weight: .black, design: .monospaced))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 7, weight: .bold))
                                        .foregroundColor(.secondary)
                                }
                                
                                HStack(spacing: 6) {
                                    HStack(spacing: 3) {
                                        Circle().fill(Color.green).frame(width: 5, height: 5)
                                        Text("\(store.directCloudDevicesCount) Cloud")
                                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                                            .foregroundColor(.green)
                                    }
                                    
                                    Text("•").foregroundColor(.secondary).font(.system(size: 8))
                                    
                                    HStack(spacing: 3) {
                                        Circle().fill(Color.cyan).frame(width: 5, height: 5)
                                        Text("\(store.meshRelayDevicesCount) Mesh")
                                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                                            .foregroundColor(.cyan)
                                    }
                                }
                            }
                            .padding(8)
                            .background(Color.white.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(10)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
            .frame(minWidth: 200, maxWidth: 220)
            .background(Color(NSColor.windowBackgroundColor))
        } detail: {
            Group {
                switch selectedTab {
                case .liveMap:
                    LiveMapView(store: store)
                case .triageKanban:
                    TriageKanbanView(store: store)
                case .emergencyBroadcast:
                    EmergencyBroadcasterView(store: store)
                case .imdRadar:
                    ImdSatelliteRadarView(store: store)
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
