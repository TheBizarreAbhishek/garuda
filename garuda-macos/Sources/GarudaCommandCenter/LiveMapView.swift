import SwiftUI
import MapKit

public struct LiveMapView: View {
    @ObservedObject var store: CommandCenterStore
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 11.6854, longitude: 76.1320),
            span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
        )
    )
    
    public var body: some View {
        ZStack(alignment: .topTrailing) {
            Map(position: $position, selection: $store.selectedSignal) {
                ForEach(store.signals) { signal in
                    Annotation(
                        signal.victimName,
                        coordinate: signal.coordinate,
                        anchor: .bottom
                    ) {
                        VictimMapPin(signal: signal, isSelected: store.selectedSignal?.id == signal.id)
                    }
                    .tag(signal)
                }
                
                ForEach(store.hazards) { hazard in
                    Annotation(hazard.title, coordinate: hazard.coordinate) {
                        HazardMapPin(hazard: hazard)
                    }
                }
            }
            .mapStyle(.hybrid(elevation: .realistic))
            .mapControls {
                MapCompass()
                MapScaleView()
                MapPitchToggle()
            }
            
            // Floating Status Overlay Card
            VStack(alignment: .trailing, spacing: 12) {
                MapMetricsOverlay(store: store)
                
                if let selected = store.selectedSignal {
                    SignalDetailOverlayCard(signal: selected, store: store)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .padding(16)
        }
    }
}

struct VictimMapPin: View {
    let signal: SosSignal
    let isSelected: Bool
    
    var pinColor: Color {
        switch signal.priority {
        case .critical: return .red
        case .urgent: return .orange
        case .moderate: return .yellow
        case .safe: return .green
        }
    }
    
    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .fill(pinColor.opacity(0.3))
                    .frame(width: isSelected ? 44 : 34, height: isSelected ? 44 : 34)
                
                Circle()
                    .fill(pinColor)
                    .frame(width: isSelected ? 30 : 24, height: isSelected ? 30 : 24)
                    .shadow(color: pinColor.opacity(0.8), radius: 6)
                
                Image(systemName: signal.emergencyType.icon)
                    .font(.system(size: isSelected ? 14 : 11, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // Hop Badge
            Text("\(signal.hopCount)H")
                .font(.system(size: 9, weight: .heavy))
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(pinColor, lineWidth: 1))
        }
        .scaleEffect(isSelected ? 1.15 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

struct HazardMapPin: View {
    let hazard: HazardReport
    
    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 18))
                .foregroundColor(.yellow)
                .background(Circle().fill(.black).frame(width: 22, height: 22))
                .shadow(radius: 4)
            
            Text(hazard.title)
                .font(.system(size: 9, weight: .semibold))
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(.ultraThickMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 3))
        }
    }
}

struct MapMetricsOverlay: View {
    @ObservedObject var store: CommandCenterStore
    
    var body: some View {
        HStack(spacing: 12) {
            MetricPill(title: "Active SOS", value: "\(store.totalActiveSignals)", color: .red)
            MetricPill(title: "Critical Triage", value: "\(store.criticalCount)", color: .orange)
            MetricPill(title: "In Rescue", value: "\(store.inProgressCount)", color: .blue)
            MetricPill(title: "Rescued", value: "\(store.resolvedCount)", color: .green)
        }
        .padding(10)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.15), lineWidth: 1))
        .shadow(color: .black.opacity(0.2), radius: 8)
    }
}

struct MetricPill: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.secondary)
            HStack(spacing: 4) {
                Circle().fill(color).frame(width: 7, height: 7)
                Text(value)
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}

struct SignalDetailOverlayCard: View {
    let signal: SosSignal
    @ObservedObject var store: CommandCenterStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(signal.victimName)
                        .font(.headline)
                    Text(signal.emergencyType.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
                Spacer()
                Button {
                    store.selectedSignal = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            Divider()
            
            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 6) {
                GridRow {
                    Text("Blood Group:").foregroundColor(.secondary).font(.caption)
                    Text(signal.bloodGroup).font(.caption.bold())
                }
                GridRow {
                    Text("Mesh Hops:").foregroundColor(.secondary).font(.caption)
                    Text("\(signal.hopCount) Hop(s) via BLE").font(.caption.bold())
                }
                GridRow {
                    Text("Battery:").foregroundColor(.secondary).font(.caption)
                    Text("\(signal.batteryLevel)%").font(.caption.bold())
                }
                GridRow {
                    Text("Gateway Node:").foregroundColor(.secondary).font(.caption)
                    Text(signal.relayedByGatewayId).font(.caption.monospaced())
                }
            }
            
            if !signal.notes.isEmpty {
                Text(signal.notes)
                    .font(.caption)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(6)
            }
            
            // Dispatch Actions
            HStack(spacing: 8) {
                Button("Dispatch NDRF") {
                    store.updateSignalStatus(
                        id: signal.id,
                        newStatus: .dispatched,
                        assignedUnit: "NDRF Quick Response Team"
                    )
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .controlSize(.small)
                
                Button("Mark Safe") {
                    store.updateSignalStatus(id: signal.id, newStatus: .rescued)
                }
                .buttonStyle(.bordered)
                .tint(.green)
                .controlSize(.small)
            }
        }
        .padding(14)
        .frame(width: 280)
        .background(.ultraThickMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.2), lineWidth: 1))
        .shadow(radius: 10)
    }
}
