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
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.white.opacity(0.18), lineWidth: 1))
        .shadow(color: .black.opacity(0.35), radius: 12, y: 4)
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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(signal.victimName)
                        .font(.headline.bold())
                    Text(signal.emergencyType.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
                Spacer()
                Button {
                    store.selectedSignal = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            Divider()
            
            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
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
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.secondary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            
            // Dispatch Actions
            HStack(spacing: 8) {
                Button {
                    store.updateSignalStatus(
                        id: signal.id,
                        newStatus: .dispatched,
                        assignedUnit: "NDRF Quick Response Team"
                    )
                } label: {
                    Text("Dispatch NDRF")
                        .font(.system(size: 11, weight: .bold))
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .controlSize(.small)
                
                Button {
                    store.updateSignalStatus(id: signal.id, newStatus: .rescued)
                } label: {
                    Text("Mark Safe")
                        .font(.system(size: 11, weight: .bold))
                }
                .buttonStyle(.bordered)
                .tint(.green)
                .controlSize(.small)
            }
        }
        .padding(16)
        .frame(width: 300)
        .background(.ultraThickMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.white.opacity(0.2), lineWidth: 1))
        .shadow(color: .black.opacity(0.4), radius: 16, y: 6)
    }
}
