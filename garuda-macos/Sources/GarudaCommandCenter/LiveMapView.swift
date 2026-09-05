import SwiftUI
import MapKit

public struct LiveMapView: View {
    @ObservedObject var store: CommandCenterStore
    
    // Default Pan-India 3D view calibrated for Indian subcontinent
    private static let panIndiaRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 21.8, longitude: 79.2),
        span: MKCoordinateSpan(latitudeDelta: 16.0, longitudeDelta: 16.0)
    )
    
    @State private var position: MapCameraPosition = .region(LiveMapView.panIndiaRegion)
    
    // UI HUD Controls
    @State private var showShelters: Bool = true
    @State private var showNdrfUnits: Bool = true
    @State private var showActiveDevices: Bool = true
    @State private var showPopulationHeatmap: Bool = true
    @State private var showMeshHops: Bool = true
    @State private var showWeatherDrawer: Bool = false
    @State private var selectedShelter: ReliefShelter?
    @State private var selectedUnit: NdrfRescueUnit?
    @State private var selectedDevice: ConnectedDevice?
    
    // GIS Search & Geocoding
    @State private var searchQuery: String = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching: Bool = false
    @State private var isSearchDropdownOpen: Bool = false
    @State private var searchedPlace: MKMapItem?
    
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
                
                // Live Connected Citizen & Mesh Relay Nodes
                if showActiveDevices {
                    ForEach(store.activeDevices.filter { $0.latitude != 0.0 && $0.longitude != 0.0 }) { device in
                        if let coord = device.coordinate {
                            Annotation(
                                device.name,
                                coordinate: coord,
                                anchor: .bottom
                            ) {
                                ActiveNodeMapPin(device: device, isSelected: selectedDevice?.id == device.id)
                                    .onTapGesture {
                                        selectedDevice = device
                                        store.selectedSignal = nil
                                        selectedShelter = nil
                                        selectedUnit = nil
                                    }
                            }
                        }
                    }
                }
                
                // Population Density Heatmap Halos (Crowd / Survivor Concentration)
                if showPopulationHeatmap {
                    ForEach(store.activeDevices.filter { $0.latitude != 0.0 && $0.longitude != 0.0 }) { device in
                        if let coord = device.coordinate {
                            MapCircle(center: coord, radius: 450)
                                .foregroundStyle(Color.green.opacity(0.18))
                            MapCircle(center: coord, radius: 200)
                                .foregroundStyle(Color.cyan.opacity(0.28))
                        }
                    }
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
                                    selectedDevice = nil
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
                                    selectedDevice = nil
                                }
                        }
                    }
                }
                
                // User Searched Place Highlight Pin
                if let place = searchedPlace {
                    Annotation(
                        place.name ?? "Target Location",
                        coordinate: place.placemark.coordinate,
                        anchor: .bottom
                    ) {
                        SearchedPlaceMapPin(place: place) {
                            self.searchedPlace = nil
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
            
            // 2. Top Unified Frosted Glass Command Bar
            HStack(spacing: 12) {
                // Garuda GIS Brand Header with Pulse Beacon
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(store.isEmergencyBroadcastActive ? Color.red : Color.green)
                            .frame(width: 8, height: 8)
                        Circle()
                            .stroke((store.isEmergencyBroadcastActive ? Color.red : Color.green).opacity(0.4), lineWidth: 4)
                            .frame(width: 14, height: 14)
                    }
                    
                    Text("GARUDA GIS")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(store.isEmergencyBroadcastActive ? "EMERGENCY" : "ACTIVE")
                        .font(.system(size: 9, weight: .heavy))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(store.isEmergencyBroadcastActive ? Color.red.opacity(0.9) : Color.blue.opacity(0.8))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                
                Divider().frame(height: 18)
                
                // Place Search Input Field
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.cyan)
                    
                    TextField("Search city, district, GPS...", text: $searchQuery)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11))
                        .frame(width: 170)
                        .onSubmit {
                            performPlaceSearch()
                        }
                        .onChange(of: searchQuery) { _, newValue in
                            if newValue.count >= 2 {
                                performPlaceSearch()
                            } else if newValue.isEmpty {
                                searchResults = []
                                isSearchDropdownOpen = false
                            }
                        }
                    
                    if isSearching {
                        ProgressView().controlSize(.mini)
                    } else if !searchQuery.isEmpty {
                        Button {
                            searchQuery = ""
                            searchResults = []
                            isSearchDropdownOpen = false
                            searchedPlace = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.18), lineWidth: 1))
                
                Divider().frame(height: 18)
                
                // Layer Selector Menu Button
                Menu {
                    Section("Satellite & GIS Mode") {
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
                    
                    Section("Map Display Overlays") {
                        Toggle("Live Mesh Field Nodes", isOn: $showActiveDevices)
                        Toggle("Population Density Heatmap", isOn: $showPopulationHeatmap)
                        Toggle("BLE Mesh Relay Lines", isOn: $showMeshHops)
                        Toggle("NDRF Rescue Teams", isOn: $showNdrfUnits)
                        Toggle("Relief Shelters", isOn: $showShelters)
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "square.3.layers.3d.fill")
                            .foregroundColor(.cyan)
                        Text(store.satelliteMapMode.rawValue)
                            .font(.system(size: 11, weight: .bold))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .menuStyle(.borderlessButton)
                
                Divider().frame(height: 18)
                
                // Live Operational Metrics
                HStack(spacing: 12) {
                    MetricDot(count: store.totalActiveSignals, label: "SOS", color: .red)
                    MetricDot(count: store.criticalCount, label: "Critical", color: .orange)
                    MetricDot(count: store.directCloudDevicesCount, label: "Cloud 🌐", color: .green)
                    MetricDot(count: store.meshRelayDevicesCount, label: "Mesh 📡", color: .cyan)
                    MetricDot(count: store.ndrfUnits.count, label: "NDRF", color: .blue)
                    MetricDot(count: store.shelters.count, label: "Camps", color: .purple)
                }
                
                Spacer()
                
                // Quick Camera Jump Buttons
                HStack(spacing: 6) {
                    Button {
                        withAnimation(.easeInOut(duration: 1.0)) {
                            position = .region(LiveMapView.panIndiaRegion)
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text("🇮🇳")
                            Text("Pan-India")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                    
                    if !store.signals.isEmpty {
                        Button {
                            withAnimation(.easeInOut(duration: 0.8)) {
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
                                Text("Victims (\(store.signals.count))")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    }
                    
                    if !store.activeDevices.isEmpty {
                        Button {
                            withAnimation(.easeInOut(duration: 0.8)) {
                                if let firstDev = store.activeDevices.first(where: { $0.latitude != 0.0 && $0.longitude != 0.0 }) {
                                    position = .region(
                                        MKCoordinateRegion(
                                            center: CLLocationCoordinate2D(latitude: firstDev.latitude, longitude: firstDev.longitude),
                                            span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
                                        )
                                    )
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Circle().fill(Color.green).frame(width: 6, height: 6)
                                Text("Nodes (\(store.activeDevices.count))")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.18))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    }
                    
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
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.cyan.opacity(0.18))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.cyan.opacity(0.35), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.35), radius: 12, x: 0, y: 6)
            .padding(.horizontal, 14)
            .padding(.top, 10)
            
            // Place Search Dropdown Floating Panel
            if isSearchDropdownOpen && !searchResults.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("LOCATIONS FOUND (\(searchResults.count))")
                            .font(.system(size: 9, weight: .black, design: .monospaced))
                            .foregroundColor(.secondary)
                        Spacer()
                        Button {
                            isSearchDropdownOpen = false
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.35))
                    
                    Divider()
                    
                    ScrollView {
                        VStack(spacing: 2) {
                            ForEach(searchResults, id: \.self) { item in
                                Button {
                                    selectPlace(item)
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "mappin.circle.fill")
                                            .foregroundColor(.cyan)
                                            .font(.system(size: 14))
                                        
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(item.name ?? "Unknown Place")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(.white)
                                            if let title = item.placemark.title {
                                                Text(title)
                                                    .font(.system(size: 9))
                                                    .foregroundColor(.secondary)
                                                    .lineLimit(1)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "arrow.up.right.circle")
                                            .font(.system(size: 11))
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.white.opacity(0.04))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(6)
                    }
                    .frame(maxHeight: 220)
                }
                .frame(width: 330)
                .background(.ultraThickMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color.cyan.opacity(0.35), lineWidth: 1))
                .shadow(color: .black.opacity(0.55), radius: 16, y: 8)
                .padding(.top, 56)
                .padding(.leading, 180)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // 3. Standby HUD Badge (Shown when 0 signals)
            if store.signals.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 7, height: 7)
                        Text("ALL SECTORS STANDBY")
                            .font(.system(size: 11, weight: .black, design: .monospaced))
                            .foregroundColor(.green)
                    }
                    Text("Pan-India Ground BLE Mesh & Satellite Gateway Active")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                    HStack(spacing: 10) {
                        Label("Port: \(String(store.serverPort)) SSE", systemImage: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(.cyan)
                        Label("Cloud Firestore Live", systemImage: "icloud.fill")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(.purple)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Color.white.opacity(0.15), lineWidth: 1))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .padding(.leading, 16)
                .padding(.bottom, 20)
            }
            
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
            } else if let device = selectedDevice {
                VStack {
                    Spacer().frame(height: 52)
                    NodeDetailOverlayCard(device: device) {
                        selectedDevice = nil
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
    
    // MARK: - GIS Search Helpers
    private func performPlaceSearch() {
        guard !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isSearching = true
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchQuery
        request.region = LiveMapView.panIndiaRegion
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            DispatchQueue.main.async {
                self.isSearching = false
                if let response = response {
                    self.searchResults = response.mapItems
                    self.isSearchDropdownOpen = !response.mapItems.isEmpty
                }
            }
        }
    }
    
    private func selectPlace(_ item: MKMapItem) {
        searchedPlace = item
        searchQuery = item.name ?? ""
        isSearchDropdownOpen = false
        withAnimation(.easeInOut(duration: 1.0)) {
            position = .region(
                MKCoordinateRegion(
                    center: item.placemark.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
            )
        }
    }
}

// MARK: - Searched Place Highlight Pin
struct SearchedPlaceMapPin: View {
    let place: MKMapItem
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 3) {
            ZStack {
                Circle()
                    .fill(Color.cyan.opacity(0.35))
                    .frame(width: 44, height: 44)
                Circle()
                    .fill(Color.cyan)
                    .frame(width: 26, height: 26)
                    .shadow(color: .cyan.opacity(0.8), radius: 8)
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.black)
            }
            
            HStack(spacing: 5) {
                Text(place.name ?? "Target Place")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(.ultraThickMaterial)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.cyan, lineWidth: 1))
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

// MARK: - Live IMD / MOSDAC INSAT-3DS Weather Satellite Radar Console
struct ImdSatelliteWeatherDrawer: View {
    @ObservedObject var store: CommandCenterStore
    @Binding var isPresented: Bool
    
    struct SatelliteChannel: Identifiable {
        let id: String
        let title: String
        let subtitle: String
        let resolution: String
        let band: String
        let urlString: String
        let icon: String
    }
    
    let channels: [SatelliteChannel] = [
        SatelliteChannel(
            id: "IR1",
            title: "Color Enhanced Infra-Red (IR1)",
            subtitle: "Deep convective storms & cyclone cloud tops",
            resolution: "4.0 km Spatial Res",
            band: "10.8 µm Thermal IR",
            urlString: "https://mausam.imd.gov.in/Satellite/3Dasiasec_ir1.jpg",
            icon: "thermometer.snowflake"
        ),
        SatelliteChannel(
            id: "CTBT",
            title: "Cloud Top Brightness Temp (CTBT)",
            subtitle: "Extreme cloudburst & flash-flood detection",
            resolution: "4.0 km Spatial Res",
            band: "Color Coded (-80°C to +40°C)",
            urlString: "https://mausam.imd.gov.in/Satellite/3Dasiasec_ctbt.jpg",
            icon: "cloud.bolt.rain.fill"
        ),
        SatelliteChannel(
            id: "VIS",
            title: "Visible High-Resolution (VIS)",
            subtitle: "Optical cyclone eye & coastal low-pressure",
            resolution: "1.0 km Optical Res",
            band: "0.65 µm Visible Channel",
            urlString: "https://mausam.imd.gov.in/Satellite/3Dasiasec_vis.jpg",
            icon: "eye.fill"
        ),
        SatelliteChannel(
            id: "WV",
            title: "Water Vapour Flow (WV)",
            subtitle: "Upper-troposphere jetstream & moisture flow",
            resolution: "8.0 km Spatial Res",
            band: "6.8 µm Absorption Band",
            urlString: "https://mausam.imd.gov.in/Satellite/3Dasiasec_wv.jpg",
            icon: "water.waves"
        ),
        SatelliteChannel(
            id: "GLOBE",
            title: "Hemispheric Full-Disc (Global IR)",
            subtitle: "Full Indian Ocean & Arabian Sea cyclone monitoring",
            resolution: "8.0 km Global",
            band: "Global Earth Disc",
            urlString: "https://mausam.imd.gov.in/Satellite/3Dglobe_ir1.jpg",
            icon: "globe.asia.australia.fill"
        )
    ]
    
    @State private var selectedChannelId: String = "IR1"
    @State private var refreshKey: UUID = UUID()
    @State private var isImageZoomed: Bool = false
    
    var currentChannel: SatelliteChannel {
        channels.first(where: { $0.id == selectedChannelId }) ?? channels[0]
    }
    
    var currentImageUrl: URL? {
        let ts = Int(Date().timeIntervalSince1970)
        return URL(string: "\(currentChannel.urlString)?ts=\(ts)")
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack(spacing: 12) {
                Image(systemName: "satellite.fill")
                    .foregroundColor(.cyan)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text("IMD INSAT-3DS LIVE SATELLITE RADAR")
                            .font(.system(size: 13, weight: .black, design: .monospaced))
                            .foregroundColor(.white)
                        
                        Text("ISRO • MOSDAC FEED")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.cyan.opacity(0.2))
                            .foregroundColor(.cyan)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    Text("Direct high-resolution optical & infrared telemetry from Geostationary Orbit (74°E)")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Refresh Button
                Button {
                    withAnimation {
                        refreshKey = UUID()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 10, weight: .bold))
                        Text("Refresh Feed")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                
                // Close Button
                Button {
                    withAnimation(.spring()) {
                        isPresented = false
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.3))
            
            Divider()
            
            // Main Content Area
            HStack(spacing: 16) {
                // Left Side: Live Satellite Image Viewer Frame
                VStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.black.opacity(0.85))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(Color.cyan.opacity(0.25), lineWidth: 1)
                            )
                        
                        if let url = currentImageUrl {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    VStack(spacing: 8) {
                                        ProgressView()
                                            .controlSize(.regular)
                                            .tint(.cyan)
                                        Text("Streaming live INSAT-3DS frame from IMD...")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                case .failure:
                                    VStack(spacing: 8) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.orange)
                                            .font(.title2)
                                        Text("Feed temporarily reconnecting to IMD gateway")
                                            .font(.caption2.bold())
                                            .foregroundColor(.secondary)
                                    }
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .id(refreshKey)
                            .padding(4)
                        }
                        
                        // Live HUD Stamp Overlay
                        VStack {
                            HStack {
                                Text("SENSOR: INSAT-3DS \(currentChannel.id)")
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .padding(4)
                                    .background(Color.black.opacity(0.75))
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                                    .foregroundColor(.cyan)
                                
                                Spacer()
                                
                                HStack(spacing: 4) {
                                    Circle().fill(Color.green).frame(width: 6, height: 6)
                                    Text("LIVE STREAM")
                                        .font(.system(size: 8, weight: .heavy, design: .monospaced))
                                        .foregroundColor(.green)
                                }
                                .padding(4)
                                .background(Color.black.opacity(0.75))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                            .padding(8)
                            
                            Spacer()
                        }
                    }
                    .frame(height: 230)
                    
                    // Metadata telemetry strip under image
                    HStack {
                        Label(currentChannel.band, systemImage: "wave.3.forward")
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Label(currentChannel.resolution, systemImage: "square.dashed")
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("Updated: 15-min cycle")
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 4)
                }
                .frame(maxWidth: .infinity)
                
                // Right Side: Spectral Channel Switcher & Map Overlay Controls
                VStack(alignment: .leading, spacing: 10) {
                    Text("SELECT SPECTRAL CHANNEL")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 6) {
                        ForEach(channels) { ch in
                            Button {
                                selectedChannelId = ch.id
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: ch.icon)
                                        .font(.system(size: 13))
                                        .foregroundColor(selectedChannelId == ch.id ? .cyan : .secondary)
                                        .frame(width: 18)
                                    
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(ch.title)
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(selectedChannelId == ch.id ? .white : .primary)
                                        Text(ch.subtitle)
                                            .font(.system(size: 9))
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                    
                                    Spacer()
                                    
                                    if selectedChannelId == ch.id {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.cyan)
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(selectedChannelId == ch.id ? Color.cyan.opacity(0.16) : Color.white.opacity(0.04))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(selectedChannelId == ch.id ? Color.cyan.opacity(0.4) : Color.white.opacity(0.06), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    Divider().padding(.vertical, 2)
                    
                    // Map Heat Layer Opacity Slider
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("GIS MAP RADAR INTENSITY")
                                .font(.system(size: 9, weight: .black, design: .monospaced))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(Int(store.imdRadarOpacity * 100))%")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(.cyan)
                        }
                        
                        Slider(value: $store.imdRadarOpacity, in: 0.1...1.0)
                            .tint(.cyan)
                            .controlSize(.mini)
                    }
                }
                .frame(width: 320)
            }
            .padding(14)
        }
        .frame(maxWidth: 880)
        .background(.ultraThickMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.cyan.opacity(0.3), lineWidth: 1.5)
        )
        .shadow(color: .black.opacity(0.6), radius: 24, y: -6)
    }
}

// MARK: - Active Citizen & Mesh Relay Node Map Pin
public struct ActiveNodeMapPin: View {
    let device: ConnectedDevice
    let isSelected: Bool
    
    public var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // Pulsing outer beacon ring
                Circle()
                    .stroke((device.isDirectCloud ? Color.green : Color.cyan).opacity(0.4), lineWidth: isSelected ? 3 : 1.5)
                    .frame(width: isSelected ? 38 : 28, height: isSelected ? 38 : 28)
                
                // Pin background body
                Circle()
                    .fill(device.isDirectCloud ? Color.green.opacity(0.9) : Color.cyan.opacity(0.9))
                    .frame(width: isSelected ? 30 : 22, height: isSelected ? 30 : 22)
                    .shadow(color: (device.isDirectCloud ? Color.green : Color.cyan).opacity(0.6), radius: isSelected ? 8 : 4)
                
                // Icon
                Image(systemName: device.isDirectCloud ? "network" : "antenna.radiowaves.left.and.right")
                    .font(.system(size: isSelected ? 13 : 10, weight: .bold))
                    .foregroundColor(.black)
            }
            
            // Callout Label
            VStack(spacing: 1) {
                HStack(spacing: 3) {
                    Text(device.isDirectCloud ? "🌐" : "📡")
                        .font(.system(size: 8))
                    Text(device.name.components(separatedBy: " ").first ?? "Node")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                
                HStack(spacing: 2) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 7))
                        .foregroundColor(device.batteryLevel > 30 ? .green : .red)
                    Text("\(device.batteryLevel)%")
                        .font(.system(size: 8, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.85))
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.black.opacity(0.85))
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke((device.isDirectCloud ? Color.green : Color.cyan).opacity(0.4), lineWidth: 1)
            )
            .offset(y: 2)
        }
    }
}

// MARK: - Node Detail Floating Card
public struct NodeDetailOverlayCard: View {
    let device: ConnectedDevice
    let onClose: () -> Void
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill((device.isDirectCloud ? Color.green : Color.cyan).opacity(0.2))
                            .frame(width: 32, height: 32)
                        Image(systemName: device.isDirectCloud ? "network" : "antenna.radiowaves.left.and.right")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(device.isDirectCloud ? .green : .cyan)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(device.name)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                        Text("ID: \(device.id)")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button {
                    onClose()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            Divider()
            
            // Connection Type Pill Badge
            HStack(spacing: 6) {
                Circle()
                    .fill(device.isDirectCloud ? Color.green : Color.cyan)
                    .frame(width: 6, height: 6)
                Text(device.isDirectCloud ? "DIRECT CLOUD UPLINK (FCM / CELLULAR)" : "BLE MULTI-HOP MESH RELAY")
                    .font(.system(size: 9, weight: .black, design: .monospaced))
                    .foregroundColor(device.isDirectCloud ? .green : .cyan)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background((device.isDirectCloud ? Color.green : Color.cyan).opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke((device.isDirectCloud ? Color.green : Color.cyan).opacity(0.3), lineWidth: 1)
            )
            
            // Telemetry Grid
            VStack(spacing: 6) {
                HStack {
                    Text("GPS Coordinates")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(String(format: "%.4f", device.latitude))°N, \(String(format: "%.4f", device.longitude))°E")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.cyan)
                }
                
                HStack {
                    Text("Sector / Location")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(device.location)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                
                HStack {
                    Text("Battery Level")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 8))
                            .foregroundColor(device.batteryLevel > 30 ? .green : .red)
                        Text("\(device.batteryLevel)%")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(device.batteryLevel > 30 ? .green : .red)
                    }
                }
                
                HStack {
                    Text("Mesh Role")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(device.meshRole)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.primary)
                }
                
                HStack {
                    Text("Last Uplink")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(device.lastSeen.formatted(date: .omitted, time: .standard))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
            .padding(10)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Population Density Guidance
            HStack(spacing: 6) {
                Image(systemName: "person.3.sequence.fill")
                    .foregroundColor(.cyan)
                    .font(.system(size: 11))
                Text("Device telemetry creates survivor density zones on the pan-India GIS grid for targeted relief deployment.")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
            .padding(8)
            .background(Color.cyan.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .padding(14)
        .frame(width: 290)
        .background(.ultraThickMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.5), radius: 18, x: -4, y: 6)
    }
}
