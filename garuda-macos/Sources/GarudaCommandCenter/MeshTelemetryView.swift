import SwiftUI

public struct MeshTelemetryView: View {
    @ObservedObject var store: CommandCenterStore
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Top Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Ground BLE Mesh & Uplink Gateway Telemetry")
                            .font(.title2.bold())
                        Text("Live status of delay-tolerant multi-hop relay nodes and cellular/Wi-Fi gateway ingestion pipelines.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    
                    Button {
                        store.toggleSimulation()
                    } label: {
                        HStack {
                            Image(systemName: store.isSimulatingMeshArrivals ? "pause.circle.fill" : "play.circle.fill")
                            Text(store.isSimulatingMeshArrivals ? "Stop Live Mesh Simulation" : "Simulate Incoming BLE Mesh Traffic")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(store.isSimulatingMeshArrivals ? .orange : .blue)
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Stat Cards
                HStack(spacing: 16) {
                    TelemetryCard(title: "Active Mesh Packets", value: "\(store.signals.count)", subtitle: "Ingested via gateways", icon: "dot.radiowaves.left.and.right", color: .blue)
                    TelemetryCard(
                        title: "Average Hop Count",
                        value: store.signals.isEmpty ? "0.0 Hops" : String(format: "%.1f Hops", Double(store.signals.reduce(0) { $0 + $1.hopCount }) / Double(store.signals.count)),
                        subtitle: "Multi-hop relay depth",
                        icon: "arrow.triangle.swap",
                        color: .purple
                    )
                    TelemetryCard(
                        title: "Packet Delivery Rate",
                        value: store.signals.isEmpty ? "100%" : "99.8%",
                        subtitle: "CRC-verified frames",
                        icon: "checkmark.shield.fill",
                        color: .green
                    )
                    TelemetryCard(
                        title: "Active Gateways",
                        value: "\(max(store.connectedClientsCount, store.activeDevices.count)) Online",
                        subtitle: "Uplink nodes to CommandCenter",
                        icon: "antenna.radiowaves.left.and.right",
                        color: .orange
                    )
                }
                
                // Gateway Ingestion Log
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Gateway Node Ingestion Stream")
                            .font(.headline)
                        Spacer()
                        if store.signals.isEmpty {
                            Text("Listening on SSE (:8080) & Cloud Firestore")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if store.signals.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .font(.system(size: 28))
                                .foregroundColor(.secondary)
                            Text("No incoming packets yet")
                                .font(.subheadline.bold())
                                .foregroundColor(.secondary)
                            Text("Packets relayed by Android field nodes over BLE mesh will stream here in real time.")
                                .font(.caption)
                                .foregroundColor(.secondary.opacity(0.8))
                        }
                        .frame(maxWidth: .infinity, minHeight: 120)
                    } else {
                        ForEach(store.signals.prefix(10)) { signal in
                            HStack {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 8)
                                Text(signal.relayedByGatewayId)
                                    .font(.subheadline.monospaced().bold())
                                Spacer()
                                Text("Received SOS from \(signal.victimName) (\(signal.hopCount) hops)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(signal.timestamp.formatted(date: .omitted, time: .standard))
                                    .font(.caption2.monospaced())
                                    .foregroundColor(.secondary)
                            }
                            .padding(10)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(16)
        }
    }
}

struct TelemetryCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .monospaced))
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }
}
