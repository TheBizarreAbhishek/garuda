import SwiftUI

public struct ConnectedDevicesModalView: View {
    @ObservedObject var store: CommandCenterStore
    @Environment(\.dismiss) private var dismiss
    @State private var searchText: String = ""
    
    public init(store: CommandCenterStore) {
        self.store = store
    }
    
    private var filteredDevices: [ConnectedDevice] {
        if searchText.isEmpty {
            return store.activeDevices
        } else {
            return store.activeDevices.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.id.localizedCaseInsensitiveContains(searchText) ||
                $0.location.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.title2.bold())
                        .foregroundColor(.green)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Connected Devices & Mesh Gateways")
                            .font(.headline.bold())
                        Text("Live Cloud & BLE Mesh Registry • Firebase (garuda-2aba2)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Count Badge
                HStack(spacing: 6) {
                    Circle()
                        .fill(store.activeDevices.isEmpty ? Color.orange : Color.green)
                        .frame(width: 8, height: 8)
                    Text("\(store.activeDevices.count) Online Node(s)")
                        .font(.caption.bold())
                        .foregroundColor(store.activeDevices.isEmpty ? .orange : .green)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.black.opacity(0.3))
                .cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1), lineWidth: 1))
                
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
            
            // Search / Filter
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
            .padding(10)
            .background(Color.black.opacity(0.2))
            .cornerRadius(8)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            
            // Devices Grid / List
            if store.activeDevices.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "iphone.slash")
                        .font(.system(size: 44))
                        .foregroundColor(.secondary)
                    Text("No Devices Connected Yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Open the Garuda app on your Android phone to register as an active mesh node.")
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
        .frame(minWidth: 580, idealWidth: 620, minHeight: 420, idealHeight: 480)
    }
}

struct DeviceCard: View {
    let device: ConnectedDevice
    
    var body: some View {
        HStack(spacing: 14) {
            // Device Icon
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 50, height: 50)
                Image(systemName: "iphone.gen3")
                    .font(.title2)
                    .foregroundColor(.green)
            }
            
            // Details
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(device.name)
                        .font(.system(size: 14, weight: .bold))
                    
                    Circle()
                        .fill(Color.green)
                        .frame(width: 7, height: 7)
                    
                    Text("ONLINE")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundColor(.green)
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
                        .foregroundColor(.blue.opacity(0.9))
                }
                
                HStack(spacing: 6) {
                    Text(device.meshRole)
                        .font(.system(size: 10, weight: .semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    
                    Text("Live Uplink Active")
                        .font(.system(size: 10, weight: .medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.purple.opacity(0.2))
                        .foregroundColor(.purple)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
            }
            
            Spacer()
            
            // Battery & Health Gauge
            VStack(alignment: .trailing, spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: batteryIconName(for: device.batteryLevel))
                        .foregroundColor(batteryColor(for: device.batteryLevel))
                    Text("\(device.batteryLevel)%")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(batteryColor(for: device.batteryLevel))
                }
                
                Text("Heartbeat: Live")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.green.opacity(0.9))
            }
        }
        .padding(14)
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
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
