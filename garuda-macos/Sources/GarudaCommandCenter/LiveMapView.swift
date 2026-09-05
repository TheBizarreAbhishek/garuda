import SwiftUI
import MapKit

public struct LiveMapView: View {
    @ObservedObject var store: CommandCenterStore
    
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 20.5937, longitude: 78.9629),
            span: MKCoordinateSpan(latitudeDelta: 22.0, longitudeDelta: 22.0)
        )
    )
    
    // UI HUD Controls
    @State private var showShelters: Bool = true
    @State private var showNdrfUnits: Bool = true
    @State private var showMeshHops: Bool = true
    @State private var showWeatherDrawer: Bool = false
    @State private var selectedShelter: ReliefShelter?
    @State private var selectedUnit: NdrfRescueUnit?
    
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
    
    public var body: some View {
        ZStack(alignment: .top) {
            // 1. Full-Screen Interactive GIS Map
            Map(position: $position, selection: $store.selectedSignal) {
                // Victim SOS Signals
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
                
                // Hazard Reports
                ForEach(store.hazards) { hazard in
                    Annotation(hazard.title, coordinate: hazard.coordinate) {
                        HazardMapPin(hazard: hazard)
                    }
                }
                
                // Relief Shelters
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
                
                // NDRF Rescue Units
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
                
                // Mesh Multi-Hop Polyline Overlay
                if showMeshHops {
                    ForEach(store.signals.filter { $0.status != .rescued }) { signal in
                        if let shelter = store.shelters.first {
                            MapPolyline(coordinates: [
                                signal.coordinate,
                                CLLocationCoordinate2D(latitude: signal.latitude + 0.003, longitude: signal.longitude + 0.003),
                                shelter.coordinate
                            ])
                            .stroke(
                                signal.priority == .critical ? Color.red.opacity(0.7) : Color.blue.opacity(0.6),
                                style: StrokeStyle(lineWidth: 2.5, dash: [6, 4])
                            )
                        } else {
                            MapPolyline(coordinates: [
                                signal.coordinate,
                                CLLocationCoordinate2D(latitude: signal.latitude + 0.004, longitude: signal.longitude + 0.004)
                            ])
                            .stroke(
                                signal.priority == .critical ? Color.red.opacity(0.7) : Color.blue.opacity(0.6),
                                style: StrokeStyle(lineWidth: 2.5, dash: [6, 4])
                            )
                        }
                    }
                }
                
                // ISRO / IMD Satellite Storm Radar Heat Zones
                if store.satelliteMapMode == .imdDopplerRadar, let activeCenter = store.signals.first?.coordinate ?? store.hazards.first?.coordinate {
                    MapCircle(center: activeCenter, radius: 4500)
                        .foregroundStyle(Color.red.opacity(store.imdRadarOpacity * 0.35))
                    
                    MapCircle(center: activeCenter, radius: 8000)
                        .foregroundStyle(Color.orange.opacity(store.imdRadarOpacity * 0.22))
                    
                    MapCircle(center: activeCenter, radius: 14000)
                        .foregroundStyle(Color.yellow.opacity(store.imdRadarOpacity * 0.12))
                }
            }
            .mapStyle(currentMapStyle)
            .mapControls {
                MapCompass()
                MapScaleView()
                MapPitchToggle()
            }
            
            // 2. Top Unified Slim Floating Control Bar (Non-Intrusive)
            HStack(spacing: 12) {
                // Layer Selector Menu Button
                Menu {
                    Section("Indian Satellite & GIS Providers") {
                        ForEach(SatelliteMapLayerMode.allCases) { mode in
                            Button {
                                store.satelliteMapMode = mode
                            } label: {
                                HStack {
                                    Image(systemName: mode.icon)
                                    Text(mode.rawValue)
                                    if store.satelliteMapMode == mode {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }
                    
                    Divider()
                    
                    Section("Map Display Layers") {
                        Toggle("BLE Mesh Relay Lines", isOn: $showMeshHops)
                        Toggle("NDRF Rescue Teams", isOn: $showNdrfUnits)
                        Toggle("Relief Shelters", isOn: $showShelters)
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "square.3.layers.3d.fill")
                            .foregroundColor(.cyan)
                        Text(store.satelliteMapMode.rawValue)
                            .font(.system(size: 12, weight: .bold))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.ultraThickMaterial)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 1))
                }
                .menuStyle(.borderlessButton)
                
                // Metrics Capsule
                HStack(spacing: 10) {
                    MetricDot(count: store.totalActiveSignals, label: "SOS", color: .red)
                    Text("•").foregroundColor(.secondary).font(.caption2)
                    MetricDot(count: store.criticalCount, label: "Critical", color: .orange)
                    Text("•").foregroundColor(.secondary).font(.caption2)
                    MetricDot(count: store.ndrfUnits.count, label: "NDRF", color: .blue)
                    Text("•").foregroundColor(.secondary).font(.caption2)
                    MetricDot(count: store.shelters.count, label: "Camps", color: .green)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.ultraThickMaterial)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 1))
                
                Spacer()
                
                // Quick Camera Jump Buttons
                HStack(spacing: 6) {
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
                        Text("🇮🇳 Pan-India")
                            .font(.system(size: 11, weight: .semibold))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(.ultraThickMaterial)
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
                            Circle().fill(Color.red).frame(width: 6, height: 6)
                            Text("Victims")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(.ultraThickMaterial)
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
                            Circle().fill(Color.green).frame(width: 6, height: 6)
                            Text("Camps")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(.ultraThickMaterial)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        withAnimation(.spring()) {
                            showWeatherDrawer.toggle()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "satellite.fill")
                                .foregroundColor(.cyan)
                            Text("IMD Radar")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.cyan)
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(Color.cyan.opacity(0.2))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.cyan.opacity(0.4), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            
            // 3. Right-Side Inspector Drawer
            if let selected = store.selectedSignal {
                VStack {
                    Spacer().frame(height: 52)
                    SignalDetailOverlayCard(signal: selected, store: store)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                    Spacer()
                }
                .padding(.trailing, 16)
                .frame(maxWidth: .infinity, alignment: .trailing)
            } else if let shelter = selectedShelter {
                VStack {
                    Spacer().frame(height: 52)
                    ShelterDetailOverlayCard(shelter: shelter) {
                        selectedShelter = nil
                    }
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    Spacer()
                }
                .padding(.trailing, 16)
                .frame(maxWidth: .infinity, alignment: .trailing)
            } else if let unit = selectedUnit {
                VStack {
                    Spacer().frame(height: 52)
                    NdrfUnitDetailOverlayCard(unit: unit) {
                        selectedUnit = nil
                    }
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    Spacer()
                }
                .padding(.trailing, 16)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            
            // 4. Bottom Drawer: IMD INSAT-3DS Weather Satellite HUD
            if showWeatherDrawer {
                VStack {
                    Spacer()
                    ImdSatelliteWeatherDrawer(store: store, isPresented: $showWeatherDrawer)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .padding(14)
            }
        }
        .onChange(of: store.selectedSignal) { _, newSignal in
            if let newSignal = newSignal {
                withAnimation(.easeInOut(duration: 0.8)) {
                    position = .region(
                        MKCoordinateRegion(
                            center: newSignal.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
                        )
                    )
                }
            }
        }
        .onChange(of: store.signals.count) { oldCount, newCount in
            if oldCount == 0, let firstSignal = store.signals.first {
                withAnimation(.easeInOut(duration: 1.2)) {
                    position = .region(
                        MKCoordinateRegion(
                            center: firstSignal.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                        )
                    )
                }
            }
        }
    }
}

// MARK: - Metric Dot Item
struct MetricDot: View {
    let count: Int
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text("\(count)")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
        }
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
                    .fill(pinColor.opacity(0.35))
                    .frame(width: isSelected ? 42 : 32, height: isSelected ? 42 : 32)
                
                Circle()
                    .fill(pinColor)
                    .frame(width: isSelected ? 28 : 22, height: isSelected ? 28 : 22)
                    .shadow(color: pinColor.opacity(0.8), radius: 6)
                
                Image(systemName: signal.emergencyType.icon)
                    .font(.system(size: isSelected ? 13 : 10, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Text("\(signal.hopCount)H • \(signal.bloodGroup)")
                .font(.system(size: 8, weight: .heavy))
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

struct ShelterMapPin: View {
    let shelter: ReliefShelter
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.25))
                    .frame(width: 34, height: 34)
                Circle()
                    .fill(Color.green)
                    .frame(width: 22, height: 22)
                    .shadow(color: .green.opacity(0.6), radius: 4)
                Image(systemName: "house.fill")
                    .font(.system(size: 10, weight: .bold))
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
                    .frame(width: 34, height: 34)
                Circle()
                    .fill(Color.blue)
                    .frame(width: 22, height: 22)
                    .shadow(color: .blue.opacity(0.6), radius: 4)
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 10, weight: .bold))
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
                .font(.system(size: 16))
                .foregroundColor(.yellow)
                .background(Circle().fill(.black).frame(width: 20, height: 20))
                .shadow(radius: 4)
            
            Text(hazard.title)
                .font(.system(size: 8, weight: .semibold))
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(.ultraThickMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 3))
        }
    }
}

// MARK: - Signal Detail Sheet
struct SignalDetailOverlayCard: View {
    let signal: SosSignal
    @ObservedObject var store: CommandCenterStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(signal.victimName)
                        .font(.headline.bold())
                    Text(signal.emergencyType.rawValue)
                        .font(.caption.bold())
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
            
            Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 6) {
                GridRow {
                    Text("Blood Group:").foregroundColor(.secondary).font(.caption2)
                    Text(signal.bloodGroup).font(.caption2.bold())
                }
                GridRow {
                    Text("Mesh Hops:").foregroundColor(.secondary).font(.caption2)
                    Text("\(signal.hopCount) Hop(s) via BLE").font(.caption2.bold())
                }
                GridRow {
                    Text("Battery:").foregroundColor(.secondary).font(.caption2)
                    Text("\(signal.batteryLevel)%").font(.caption2.bold())
                }
                GridRow {
                    Text("Gateway:").foregroundColor(.secondary).font(.caption2)
                    Text(signal.relayedByGatewayId).font(.system(size: 10, design: .monospaced))
                }
            }
            
            if !signal.notes.isEmpty {
                Text(signal.notes)
                    .font(.caption2)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.secondary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            
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
        .padding(14)
        .frame(width: 270)
        .background(.ultraThickMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.white.opacity(0.2), lineWidth: 1))
        .shadow(color: .black.opacity(0.4), radius: 14, y: 4)
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
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(shelter.currentOccupancy) / \(shelter.capacity)")
                        .font(.caption2.bold())
                }
                
                ProgressView(value: Double(shelter.currentOccupancy), total: Double(shelter.capacity))
                    .tint(.green)
                
                Text(shelter.suppliesStatus)
                    .font(.caption2)
                    .padding(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.green.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                
                HStack {
                    Image(systemName: "phone.fill")
                        .foregroundColor(.blue)
                        .font(.caption2)
                    Text(shelter.contactPhone)
                        .font(.caption2.bold())
                }
            }
        }
        .padding(14)
        .frame(width: 270)
        .background(.ultraThickMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.white.opacity(0.2), lineWidth: 1))
        .shadow(color: .black.opacity(0.4), radius: 14, y: 4)
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
                    Text("Capability:")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(unit.type)
                        .font(.caption2.bold())
                }
                
                HStack {
                    Text("Status:")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(unit.status)
                        .font(.caption2.bold())
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(14)
        .frame(width: 270)
        .background(.ultraThickMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.white.opacity(0.2), lineWidth: 1))
        .shadow(color: .black.opacity(0.4), radius: 14, y: 4)
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
        "Visible Cyclone Eye (VIS)"
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "satellite.fill")
                    .foregroundColor(.cyan)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("IMD INSAT-3DS Live Satellite Radar")
                        .font(.headline.bold())
                    Text("India Meteorological Department (IMD) • MOSDAC Live Feed")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 6) {
                    Circle().fill(Color.green).frame(width: 7, height: 7)
                    Text("15-MIN REFRESH")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
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
            
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.black.opacity(0.9))
                        .frame(height: 160)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                        )
                    
                    VStack {
                        HStack {
                            Text("SECTOR: INDIAN SUBCONTINENT")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(.cyan)
                            Spacer()
                            Text(Date().formatted(date: .omitted, time: .standard))
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        .padding(8)
                        
                        Spacer()
                        
                        HStack(spacing: 12) {
                            Image(systemName: "tornado")
                                .font(.system(size: 32))
                                .foregroundColor(.orange)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Cyclone Front & Cloudburst Watch")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.white)
                                Text("Heavy precipitation moving NW at 18 km/h. Cloud top: -64°C.")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(12)
                        
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity)
                
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(channels, id: \.self) { ch in
                        Button {
                            selectedChannel = ch
                        } label: {
                            HStack {
                                Image(systemName: selectedChannel == ch ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selectedChannel == ch ? .cyan : .secondary)
                                    .font(.caption)
                                Text(ch)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(selectedChannel == ch ? .white : .secondary)
                                Spacer()
                            }
                            .padding(6)
                            .background(selectedChannel == ch ? Color.cyan.opacity(0.15) : Color.white.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(width: 250)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(.ultraThickMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.white.opacity(0.2), lineWidth: 1))
        .shadow(color: .black.opacity(0.5), radius: 18, y: -4)
    }
}
