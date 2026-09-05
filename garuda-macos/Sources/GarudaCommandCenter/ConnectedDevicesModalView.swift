import SwiftUI

public struct ConnectedDevicesModalView: View {
    @ObservedObject var store: CommandCenterStore
    @Environment(\.dismiss) private var dismiss
    @State private var searchText: String = ""
    @State private var selectedFilter: ConnectionFilter = .all
    
    enum ConnectionFilter: String, CaseIterable, Identifiable {
        case all = "All Nodes"
        case directCloud = "Direct Cloud 🌐"
        case meshRelay = "BLE Mesh 📡"
        
        var id: String { rawValue }
    }
    
    public init(store: CommandCenterStore) {
        self.store = store
    }
    
    private var filteredDevices: [ConnectedDevice] {
        var list = store.activeDevices
        
        switch selectedFilter {
        case .all:
            break
        case .directCloud:
            list = list.filter { $0.isDirectCloud }
        case .meshRelay:
            list = list.filter { !$0.isDirectCloud }
        }
        
        if !searchText.isEmpty {
            list = list.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.id.localizedCaseInsensitiveContains(searchText) ||
                $0.location.localizedCaseInsensitiveContains(searchText)
            }
        }
        return list
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.title2.bold())
                        .foregroundColor(.cyan)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Connected Devices & Mesh Network Registry")
                            .font(.headline.bold())
                        Text("Live Cloud & BLE Multi-Hop Ground Grid • Firebase (garuda-2aba2)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Dual Count Badges
                HStack(spacing: 6) {
                    HStack(spacing: 4) {
                        Circle().fill(Color.green).frame(width: 7, height: 7)
                        Text("\(store.directCloudDevicesCount) Cloud")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.12))
                    .clipShape(Capsule())
                    
                    HStack(spacing: 4) {
                        Circle().fill(Color.cyan).frame(width: 7, height: 7)
                        Text("\(store.meshRelayDevicesCount) Mesh")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.cyan)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.cyan.opacity(0.12))
                    .clipShape(Capsule())
                }
                
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .padding(.leading, 8)
            }
            .padding(16)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Search Bar + Segmented Filter
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search connected devices by model, ID or district...", text: $searchText)
                        .textFieldStyle(.plain)
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(8)
                .background(Color.black.opacity(0.2))
                .cornerRadius(8)
                
                // Segmented Picker
                Picker("Filter", selection: $selectedFilter) {
                    Text("All (\(store.activeDevices.count))").tag(ConnectionFilter.all)
                    Text("Direct Cloud (\(store.directCloudDevicesCount))").tag(ConnectionFilter.directCloud)
                    Text("BLE Mesh Relay (\(store.meshRelayDevicesCount))").tag(ConnectionFilter.meshRelay)
                }
                .pickerStyle(.segmented)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            
            // Devices Grid / List
            if filteredDevices.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "iphone.slash")
                        .font(.system(size: 44))
                        .foregroundColor(.secondary)
                    Text("No Matching Devices Found")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Devices appear here live as they register via Cloud or relay over BLE multi-hop mesh.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(filteredDevices) { device in
                            DeviceCard(device: device)
                        }
                    }
                    .padding(16)
                }
            }
            
            Divider()
            
            // Footer
            HStack {
                Text("Auto-refreshing via Firebase Firestore heartbeat every 3 seconds")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(12)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(minWidth: 620, idealWidth: 660, minHeight: 460, idealHeight: 520)
    }
}

struct DeviceCard: View {
    let device: ConnectedDevice
    
    var body: some View {
        HStack(spacing: 14) {
            // Device Icon
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill((device.isDirectCloud ? Color.green : Color.cyan).opacity(0.15))
                    .frame(width: 50, height: 50)
                Image(systemName: device.isDirectCloud ? "network" : "antenna.radiowaves.left.and.right")
                    .font(.title2)
                    .foregroundColor(device.isDirectCloud ? .green : .cyan)
            }
            
            // Details
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(device.name)
                        .font(.system(size: 14, weight: .bold))
                    
                    Circle()
                        .fill(device.isDirectCloud ? Color.green : Color.cyan)
                        .frame(width: 7, height: 7)
                    
                    Text("ONLINE")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundColor(device.isDirectCloud ? .green : .cyan)
                }
                
                HStack(spacing: 8) {
                    Text("ID: \(device.id)")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text("📍 \(device.location)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.primary.opacity(0.85))
                }
                
                if device.latitude != 0.0 && device.longitude != 0.0 {
                    Text("🛰️ GPS: \(String(format: "%.4f", device.latitude))°N, \(String(format: "%.4f", device.longitude))°E")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.cyan.opacity(0.9))
                }
                
                HStack(spacing: 6) {
                    // Connection Channel Badge
                    HStack(spacing: 4) {
                        Text(device.isDirectCloud ? "🌐 DIRECT CLOUD" : "📡 MESH RELAY")
                            .font(.system(size: 9, weight: .black, design: .monospaced))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background((device.isDirectCloud ? Color.green : Color.cyan).opacity(0.18))
                    .foregroundColor(device.isDirectCloud ? .green : .cyan)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    
                    Text(device.meshRole)
                        .font(.system(size: 10, weight: .semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.08))
                        .foregroundColor(.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
            }
            
            Spacer()
            
            // Battery & Health Gauge
            VStack(alignment: .trailing, spacing: 6) {
                if device.isDirectCloud {
                    HStack(spacing: 4) {
                        Image(systemName: batteryIconName(for: device.batteryLevel))
                            .foregroundColor(batteryColor(for: device.batteryLevel))
                        Text("\(device.batteryLevel)%")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(batteryColor(for: device.batteryLevel))
                    }
                    
                    Text("Cloud: Live")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.green.opacity(0.9))
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .foregroundColor(.cyan)
                        Text("Hop #\(max(device.hopCount, 1))")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.cyan)
                    }
                    
                    Text("Mesh: Relayed")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.cyan.opacity(0.9))
                }
            }
        }
        .padding(14)
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke((device.isDirectCloud ? Color.green : Color.cyan).opacity(0.18), lineWidth: 1)
        )
    }
    
    private func batteryIconName(for level: Int) -> String {
        if level > 75 { return "battery.100" }
        if level > 50 { return "battery.75" }
        if level > 25 { return "battery.50" }
        return "battery.25"
    }
    
    private func batteryColor(for level: Int) -> Color {
        if level > 50 { return .green }
        if level > 20 { return .yellow }
        return .red
    }
}
