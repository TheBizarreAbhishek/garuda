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
    
    // UI HUD Controls
    @State private var showShelters: Bool = true
    @State private var showNdrfUnits: Bool = true
    @State private var showMeshHops: Bool = true
    @State private var showWeatherDrawer: Bool = false
    @State private var selectedShelter: ReliefShelter?
    @State private var selectedUnit: NdrfRescueUnit?
    
    // Live IMD / ISRO Radar Simulation Pulse
    @State private var radarPulsePhase: CGFloat = 0.0
    
    public var body: some View {
        ZStack(alignment: .topTrailing) {
            // Main Interactive Map
            Map(position: $position, selection: $store.selectedSignal) {
                // 1. Victim SOS Signals
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
                
                // 2. Hazard Reports
                ForEach(store.hazards) { hazard in
                    Annotation(hazard.title, coordinate: hazard.coordinate) {
                        HazardMapPin(hazard: hazard)
                    }
                }
                
                // 3. Relief Shelters (Toggleable)
                if showShelters {
                    ForEach(store.shelters) { shelter in
                        Annotation(shelter.name, coordinate: shelter.coordinate) {
                            ShelterMapPin(shelter: shelter, isSelected: selectedShelter?.id == shelter.id)
                                .onTapGesture {
                                    selectedShelter = shelter
                                    store.selectedSignal = nil
                                    selectedUnit = nil
                                }
                        }
                    }
                }
                
                // 4. NDRF Rescue Units (Toggleable)
                if showNdrfUnits {
                    ForEach(store.ndrfUnits) { unit in
                        Annotation(unit.unitName, coordinate: unit.coordinate) {
                            NdrfUnitMapPin(unit: unit, isSelected: selectedUnit?.id == unit.id)
                                .onTapGesture {
                                    selectedUnit = unit
                                    store.selectedSignal = nil
                                    selectedShelter = nil
                                }
                        }
                    }
                }
                
                // 5. Mesh Multi-Hop Polyline Overlay (Victim -> Gateway Routing)
                if showMeshHops {
                    ForEach(store.signals.filter { $0.status != .rescued }) { signal in
                        MapPolyline(coordinates: [
                            signal.coordinate,
                            CLLocationCoordinate2D(latitude: signal.latitude + 0.006, longitude: signal.longitude + 0.005),
                            CLLocationCoordinate2D(latitude: 11.6960, longitude: 76.1480) // Gateway Base
                        ])
                        .stroke(
                            signal.priority == .critical ? Color.red.opacity(0.65) : Color.blue.opacity(0.55),
                            style: StrokeStyle(lineWidth: 2, dash: [6, 4])
                        )
                    }
                }
                
                // 6. ISRO / IMD Satellite Storm Radar Heat Zones
                if store.satelliteMapMode == .imdDopplerRadar {
                    MapCircle(center: CLLocationCoordinate2D(latitude: 11.6854, longitude: 76.1320), radius: 4500)
                        .foregroundStyle(Color.red.opacity(store.imdRadarOpacity * 0.35))
                    
                    MapCircle(center: CLLocationCoordinate2D(latitude: 11.6854, longitude: 76.1320), radius: 8000)
                        .foregroundStyle(Color.orange.opacity(store.imdRadarOpacity * 0.22))
                    
                    MapCircle(center: CLLocationCoordinate2D(latitude: 11.6854, longitude: 76.1320), radius: 14000)
                        .foregroundStyle(Color.yellow.opacity(store.imdRadarOpacity * 0.12))
                }
            }
            .mapStyle(currentMapStyle)
            .mapControls {
                MapCompass()
                MapScaleView()
                MapPitchToggle()
            }
            
            // Top Left: Indian Government Satellite & Layer Control Bar
            VStack(alignment: .leading, spacing: 10) {
                SatelliteLayerControlCard(
                    store: store,
                    showShelters: $showShelters,
                    showNdrfUnits: $showNdrfUnits,
                    showMeshHops: $showMeshHops,
                    showWeatherDrawer: $showWeatherDrawer
                )
                
                CameraQuickJumpBar(position: $position, store: store)
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            
            // Top Right: Live Metrics & Incident Detail Cards
            VStack(alignment: .trailing, spacing: 12) {
                MapMetricsOverlay(store: store)
                
                if let selected = store.selectedSignal {
                    SignalDetailOverlayCard(signal: selected, store: store)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                } else if let shelter = selectedShelter {
                    ShelterDetailOverlayCard(shelter: shelter) {
                        selectedShelter = nil
                    }
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                } else if let unit = selectedUnit {
                    NdrfUnitDetailOverlayCard(unit: unit) {
                        selectedUnit = nil
                    }
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            
            // Bottom Drawer / Slide-Over: IMD & ISRO Live Weather Satellite Feed
            if showWeatherDrawer {
                ImdSatelliteWeatherDrawer(store: store, isPresented: $showWeatherDrawer)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
    
    private var currentMapStyle: MapStyle {
        switch store.satelliteMapMode {
        case .standardHybrid:
            return .hybrid(elevation: .realistic)
        case .isroBhuvan:
            return .imagery(elevation: .realistic)
        case .imdDopplerRadar:
            return .hybrid(elevation: .realistic, pointsOfInterest: .including([.hospital, .police, .fireStation]))
        }
    }
}

// MARK: - Satellite & Government Layer Control Card
struct SatelliteLayerControlCard: View {
    @ObservedObject var store: CommandCenterStore
    @Binding var showShelters: Bool
    @Binding var showNdrfUnits: Bool
    @Binding var showMeshHops: Bool
    @Binding var showWeatherDrawer: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .foregroundColor(.cyan)
                Text("GOVERNMENT SATELLITE & GIS FEEDS")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            // Mode Picker
            Picker("", selection: $store.satelliteMapMode) {
                ForEach(SatelliteMapLayerMode.allCases) { mode in
                    Label(mode.rawValue, systemImage: mode.icon).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            
            HStack {
                Text("Agency:")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(store.satelliteMapMode.agency)
                    .font(.caption2.bold())
                    .foregroundColor(.cyan)
                Spacer()
            }
            
            Divider()
            
            // Layer Toggles
            HStack(spacing: 12) {
                Toggle(isOn: $showMeshHops) {
                    Label("BLE Mesh Hops", systemImage: "arrow.triangle.swap")
                        .font(.caption.bold())
                }
                .toggleStyle(.checkbox)
                
                Toggle(isOn: $showNdrfUnits) {
                    Label("NDRF Teams", systemImage: "shield.fill")
                        .font(.caption.bold())
                }
                .toggleStyle(.checkbox)
                
                Toggle(isOn: $showShelters) {
                    Label("Relief Camps", systemImage: "house.fill")
                        .font(.caption.bold())
                }
                .toggleStyle(.checkbox)
            }
            
            Divider()
            
            // Live IMD Radar Button & Opacity Slider
            HStack(spacing: 12) {
                Button {
                    withAnimation(.spring()) {
                        showWeatherDrawer.toggle()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "cloud.sun.bolt.fill")
                            .foregroundColor(.orange)
                        Text("Live IMD INSAT-3DS Feed")
                            .font(.caption.bold())
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.18))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                
                if store.satelliteMapMode == .imdDopplerRadar {
                    HStack(spacing: 6) {
                        Text("Radar Density:")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Slider(value: $store.imdRadarOpacity, in: 0.2...1.0)
                            .frame(width: 80)
                    }
                }
            }
        }
        .padding(14)
        .frame(width: 380)
        .background(.ultraThickMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.white.opacity(0.18), lineWidth: 1))
        .shadow(color: .black.opacity(0.35), radius: 10, y: 4)
    }
}

// MARK: - Camera Quick Jump Toolbar
struct CameraQuickJumpBar: View {
    @Binding var position: MapCameraPosition
    @ObservedObject var store: CommandCenterStore
    
    var body: some View {
        HStack(spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 1.2)) {
                    position = .region(
                        MKCoordinateRegion(
                            center: CLLocationCoordinate2D(latitude: 22.5937, longitude: 78.9629),
                            span: MKCoordinateSpan(latitudeDelta: 22.0, longitudeDelta: 22.0)
                        )
                    )
                }
            } label: {
                HStack(spacing: 4) {
                    Text("🇮🇳 Pan-India")
                        .font(.caption.bold())
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.4))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            
            Button {
                withAnimation(.easeInOut(duration: 1.0)) {
                    if let firstSignal = store.signals.first {
                        position = .region(
                            MKCoordinateRegion(
                                center: firstSignal.coordinate,
                                span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
                            )
                        )
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "cross.case.fill")
                        .foregroundColor(.red)
                    Text("Focus Victims (\(store.signals.count))")
                        .font(.caption.bold())
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.red.opacity(0.2))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            
            Button {
                withAnimation(.easeInOut(duration: 1.0)) {
                    if let firstShelter = store.shelters.first {
                        position = .region(
                            MKCoordinateRegion(
                                center: firstShelter.coordinate,
                                span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
                            )
                        )
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "house.fill")
                        .foregroundColor(.green)
                    Text("Relief Camps")
                        .font(.caption.bold())
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.green.opacity(0.2))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(6)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
    }
}

// MARK: - Map Pins
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
                    .frame(width: isSelected ? 46 : 34, height: isSelected ? 46 : 34)
                
                Circle()
                    .fill(pinColor)
                    .frame(width: isSelected ? 30 : 24, height: isSelected ? 30 : 24)
                    .shadow(color: pinColor.opacity(0.8), radius: 6)
                
                Image(systemName: signal.emergencyType.icon)
                    .font(.system(size: isSelected ? 14 : 11, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // Hop Badge
            Text("\(signal.hopCount)H • \(signal.bloodGroup)")
                .font(.system(size: 9, weight: .heavy))
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(pinColor, lineWidth: 1))
        }
        .scaleEffect(isSelected ? 1.18 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

struct ShelterMapPin: View {
    let shelter: ReliefShelter
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.25))
                    .frame(width: 36, height: 36)
                Circle()
                    .fill(Color.green)
                    .frame(width: 24, height: 24)
                    .shadow(color: .green.opacity(0.6), radius: 4)
                Image(systemName: "house.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Text("\(shelter.currentOccupancy)/\(shelter.capacity)")
                .font(.system(size: 8, weight: .bold))
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(.ultraThickMaterial)
                .clipShape(Capsule())
                .foregroundColor(.green)
        }
    }
}

struct NdrfUnitMapPin: View {
    let unit: NdrfRescueUnit
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.25))
                    .frame(width: 36, height: 36)
                Circle()
                    .fill(Color.blue)
                    .frame(width: 24, height: 24)
                    .shadow(color: .blue.opacity(0.6), radius: 4)
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Text("NDRF")
                .font(.system(size: 8, weight: .bold))
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(.ultraThickMaterial)
                .clipShape(Capsule())
                .foregroundColor(.blue)
        }
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

// MARK: - Metrics Overlay
struct MapMetricsOverlay: View {
    @ObservedObject var store: CommandCenterStore
    
    var body: some View {
        HStack(spacing: 12) {
            MetricPill(title: "Active SOS", value: "\(store.totalActiveSignals)", color: .red)
            MetricPill(title: "Critical Triage", value: "\(store.criticalCount)", color: .orange)
            MetricPill(title: "NDRF Units", value: "\(store.ndrfUnits.count)", color: .blue)
            MetricPill(title: "Relief Camps", value: "\(store.shelters.count)", color: .green)
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

// MARK: - Signal Detail Sheet
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
                        assignedUnit: "10th Battalion NDRF Airborne"
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
        .frame(width: 310)
        .background(.ultraThickMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.white.opacity(0.2), lineWidth: 1))
        .shadow(color: .black.opacity(0.4), radius: 16, y: 6)
    }
}

// MARK: - Shelter Detail Sheet
struct ShelterDetailOverlayCard: View {
    let shelter: ReliefShelter
    let onClose: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(shelter.name)
                        .font(.headline.bold())
                    Text("Official NDMA Relief Shelter")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Capacity:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(shelter.currentOccupancy) / \(shelter.capacity) Citizens")
                        .font(.caption.bold())
                }
                
                ProgressView(value: Double(shelter.currentOccupancy), total: Double(shelter.capacity))
                    .tint(.green)
                
                Text(shelter.suppliesStatus)
                    .font(.caption)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.green.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                HStack {
                    Image(systemName: "phone.fill")
                        .foregroundColor(.blue)
                    Text("Helpline: \(shelter.contactPhone)")
                        .font(.caption.bold())
                }
            }
        }
        .padding(16)
        .frame(width: 310)
        .background(.ultraThickMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.white.opacity(0.2), lineWidth: 1))
        .shadow(color: .black.opacity(0.4), radius: 16, y: 6)
    }
}

// MARK: - NDRF Unit Detail Sheet
struct NdrfUnitDetailOverlayCard: View {
    let unit: NdrfRescueUnit
    let onClose: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(unit.unitName)
                        .font(.headline.bold())
                    Text(unit.battalion)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Equipment / Capability:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(unit.type)
                        .font(.caption.bold())
                }
                
                HStack {
                    Text("Deployment Status:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(unit.status)
                        .font(.caption.bold())
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(16)
        .frame(width: 310)
        .background(.ultraThickMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.white.opacity(0.2), lineWidth: 1))
        .shadow(color: .black.opacity(0.4), radius: 16, y: 6)
    }
}

// MARK: - Live IMD / MOSDAC INSAT-3DS Weather Satellite Drawer
struct ImdSatelliteWeatherDrawer: View {
    @ObservedObject var store: CommandCenterStore
    @Binding var isPresented: Bool
    
    @State private var selectedChannel: String = "Color Enhanced Infra-Red (IR1)"
    
    let channels = [
        "Color Enhanced Infra-Red (IR1)",
        "Doppler Weather Radar (DWR Composite)",
        "Water Vapour Cloud Motion (WV)",
        "Visible Channel Cyclone Eye (VIS)"
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "satellite.fill")
                    .foregroundColor(.cyan)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("IMD INSAT-3DS / MOSDAC Live Satellite Weather Radar")
                        .font(.headline.bold())
                    Text("India Meteorological Department (IMD) • Ministry of Earth Sciences, Govt of India")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Circle().fill(Color.green).frame(width: 8, height: 8)
                    Text("LIVE SAT-FEED 15-MIN REFRESH")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.12))
                .clipShape(Capsule())
                
                Button {
                    withAnimation(.spring()) {
                        isPresented = false
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            Divider()
            
            HStack(spacing: 20) {
                // Live Radar Simulation Canvas / Preview
                VStack(alignment: .leading, spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.85))
                            .frame(height: 220)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                            )
                        
                        // Simulated Radar Sweep & Satellite Contour Visualizer
                        VStack {
                            HStack {
                                Text("INSAT-3DS SECTOR: INDIAN SUBCONTINENT")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(.cyan)
                                Spacer()
                                Text(Date().formatted(date: .abbreviated, time: .standard))
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                            .padding(10)
                            
                            Spacer()
                            
                            HStack(spacing: 16) {
                                Image(systemName: "tornado")
                                    .font(.system(size: 44))
                                    .foregroundColor(.orange)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Active Cyclone & Deep Depression Front")
                                        .font(.subheadline.bold())
                                        .foregroundColor(.white)
                                    Text("Heavy precipitation band moving NW at 18 km/h. Cloud top temp: -64°C.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding(16)
                            
                            Spacer()
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                
                // Channel Selection & Scientific Metrics
                VStack(alignment: .leading, spacing: 10) {
                    Text("SELECT SATELLITE CHANNEL")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                    
                    ForEach(channels, id: \.self) { ch in
                        Button {
                            selectedChannel = ch
                        } label: {
                            HStack {
                                Image(systemName: selectedChannel == ch ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selectedChannel == ch ? .cyan : .secondary)
                                Text(ch)
                                    .font(.caption.bold())
                                    .foregroundColor(selectedChannel == ch ? .white : .secondary)
                                Spacer()
                            }
                            .padding(8)
                            .background(selectedChannel == ch ? Color.cyan.opacity(0.15) : Color.white.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(width: 320)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(.ultraThickMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.white.opacity(0.2), lineWidth: 1))
        .shadow(color: .black.opacity(0.5), radius: 20, y: -4)
        .padding(16)
        .frame(maxHeight: .infinity, alignment: .bottom)
    }
}
