import SwiftUI
import MapKit
import Combine

public struct ReliefCampsManagerView: View {
    @ObservedObject var store: CommandCenterStore
    @State private var searchText: String = ""
    @State private var selectedFilter: CampFilter = .all
    @State private var isShowingAddModal: Bool = false
    @State private var editingShelter: ReliefShelter? = nil
    
    enum CampFilter: String, CaseIterable {
        case all = "All Camps"
        case available = "Available Vacancy"
        case nearCapacity = "High Occupancy (>80%)"
        case full = "Full Capacity"
    }
    
    public init(store: CommandCenterStore) {
        self.store = store
    }
    
    private var totalCapacity: Int {
        store.shelters.reduce(0) { $0 + $1.capacity }
    }
    
    private var totalOccupancy: Int {
        store.shelters.reduce(0) { $0 + $1.currentOccupancy }
    }
    
    private var totalVacancy: Int {
        max(0, totalCapacity - totalOccupancy)
    }
    
    private var filteredShelters: [ReliefShelter] {
        store.shelters.filter { shelter in
            let matchesSearch = searchText.isEmpty ||
                shelter.name.localizedCaseInsensitiveContains(searchText) ||
                shelter.suppliesStatus.localizedCaseInsensitiveContains(searchText) ||
                shelter.contactPhone.localizedCaseInsensitiveContains(searchText)
            
            if !matchesSearch { return false }
            
            let occupancyRatio = shelter.capacity > 0 ? Double(shelter.currentOccupancy) / Double(shelter.capacity) : 0.0
            
            switch selectedFilter {
            case .all:
                return true
            case .available:
                return occupancyRatio < 0.8
            case .nearCapacity:
                return occupancyRatio >= 0.8 && occupancyRatio < 1.0
            case .full:
                return occupancyRatio >= 1.0
            }
        }
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // 1. Top Command Header
            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.green.opacity(0.2))
                            .frame(width: 36, height: 36)
                        Image(systemName: "tent.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.green)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("RELIEF CAMPS & EVACUATION HUBS")
                                .font(.system(size: 14, weight: .black, design: .monospaced))
                                .foregroundColor(.white)
                            
                            HStack(spacing: 4) {
                                Circle().fill(Color.green).frame(width: 6, height: 6)
                                Text("LIVE CLOUD & MESH SYNC")
                                    .font(.system(size: 8, weight: .black, design: .monospaced))
                                    .foregroundColor(.green)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.15))
                            .clipShape(Capsule())
                        }
                        
                        Text("Government of India / NDMA Civilian Safe Haven & Logistics Command")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button {
                    isShowingAddModal = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Relief Camp")
                    }
                    .font(.system(size: 12, weight: .bold))
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // 2. Metrics Bar (Total Camps, Capacity, Occupancy, Vacancy)
            HStack(spacing: 14) {
                metricBox(
                    title: "TOTAL RELIEF CAMPS",
                    value: "\(store.shelters.count)",
                    subtitle: "Active Field Shelters",
                    icon: "tent.fill",
                    color: .green
                )
                
                metricBox(
                    title: "TOTAL CAPACITY",
                    value: "\(totalCapacity)",
                    subtitle: "Emergency Beds / Space",
                    icon: "bed.double.fill",
                    color: .blue
                )
                
                let pct = totalCapacity > 0 ? Int((Double(totalOccupancy) / Double(totalCapacity)) * 100) : 0
                metricBox(
                    title: "CURRENT OCCUPANCY",
                    value: "\(totalOccupancy) (\(pct)%)",
                    subtitle: "Evacuees Sheltered",
                    icon: "person.3.fill",
                    color: pct > 85 ? .orange : .cyan
                )
                
                metricBox(
                    title: "AVAILABLE VACANCY",
                    value: "\(totalVacancy)",
                    subtitle: "Spots Ready for Intake",
                    icon: "checkmark.seal.fill",
                    color: .green
                )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.2))
            
            Divider()
            
            // 3. Search & Filter Bar
            HStack(spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search camp by name, supplies, or phone...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.1), lineWidth: 1))
                .frame(maxWidth: 320)
                
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(CampFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                
                Spacer()
                
                Text("\(filteredShelters.count) Camps Displayed")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // 4. Camps List / Grid
            if filteredShelters.isEmpty {
                VStack(spacing: 14) {
                    Spacer()
                    Image(systemName: "tent")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary.opacity(0.6))
                    
                    Text(store.shelters.isEmpty ? "No Relief Camps Added Yet" : "No Camps Match Filter Criteria")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Add official evacuation centers, school relief hubs, or sports complex shelters. They will automatically sync to citizens' mobile apps via Firebase Firestore and BLE mesh.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 460)
                    
                    Button {
                        isShowingAddModal = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                            Text("Create First Relief Camp")
                        }
                        .font(.system(size: 12, weight: .bold))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .padding(.top, 4)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 380), spacing: 14)], spacing: 14) {
                        ForEach(filteredShelters) { shelter in
                            ReliefCampCardView(
                                shelter: shelter,
                                onEdit: {
                                    editingShelter = shelter
                                },
                                onQuickAdjust: { delta in
                                    var updated = shelter
                                    let newOcc = max(0, min(shelter.capacity, shelter.currentOccupancy + delta))
                                    updated = ReliefShelter(
                                        id: shelter.id,
                                        name: shelter.name,
                                        latitude: shelter.latitude,
                                        longitude: shelter.longitude,
                                        capacity: shelter.capacity,
                                        currentOccupancy: newOcc,
                                        suppliesStatus: shelter.suppliesStatus,
                                        contactPhone: shelter.contactPhone
                                    )
                                    store.updateReliefShelter(updated)
                                },
                                onDelete: {
                                    store.deleteReliefShelter(id: shelter.id)
                                }
                            )
                        }
                    }
                    .padding(20)
                }
            }
        }
        .sheet(isPresented: $isShowingAddModal) {
            AddOrEditReliefCampModalView(store: store, initialShelter: nil)
        }
        .sheet(item: $editingShelter) { shelter in
            AddOrEditReliefCampModalView(store: store, initialShelter: shelter)
        }
    }
    
    private func metricBox(title: String, value: String, subtitle: String, icon: String, color: Color) -> some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color.opacity(0.15))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 9, weight: .black, design: .monospaced))
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.system(size: 14, weight: .black, design: .monospaced))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(10)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - Relief Camp Card Component
public struct ReliefCampCardView: View {
    let shelter: ReliefShelter
    let onEdit: () -> Void
    let onQuickAdjust: (Int) -> Void
    let onDelete: () -> Void
    
    private var occupancyRatio: Double {
        shelter.capacity > 0 ? Double(shelter.currentOccupancy) / Double(shelter.capacity) : 0.0
    }
    
    private var statusColor: Color {
        if occupancyRatio >= 1.0 {
            return .red
        } else if occupancyRatio >= 0.8 {
            return .orange
        } else {
            return .green
        }
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header: Icon + Name + Occupancy Badge
            HStack(alignment: .top, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(statusColor.opacity(0.2))
                        .frame(width: 36, height: 36)
                    Image(systemName: "tent.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(statusColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(shelter.name)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.cyan)
                        Text("\(String(format: "%.4f", shelter.latitude))°N, \(String(format: "%.4f", shelter.longitude))°E")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Status Pill
                HStack(spacing: 4) {
                    Circle().fill(statusColor).frame(width: 5, height: 5)
                    Text(occupancyRatio >= 1.0 ? "FULL" : (occupancyRatio >= 0.8 ? "NEAR CAPACITY" : "OPEN"))
                        .font(.system(size: 8, weight: .black, design: .monospaced))
                        .foregroundColor(statusColor)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(statusColor.opacity(0.15))
                .clipShape(Capsule())
            }
            
            // Occupancy Progress Bar
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Occupancy: \(shelter.currentOccupancy) / \(shelter.capacity) Beds")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(Int(occupancyRatio * 100))% Filled")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(statusColor)
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 6)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [statusColor.opacity(0.8), statusColor]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: min(geo.size.width, geo.size.width * CGFloat(occupancyRatio)), height: 6)
                    }
                }
                .frame(height: 6)
                
                HStack {
                    Text("\(max(0, shelter.capacity - shelter.currentOccupancy)) Beds Available")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            .padding(8)
            .background(Color.white.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            
            // Supplies & Resources Pill
            HStack(spacing: 6) {
                Image(systemName: "cross.case.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.green)
                Text(shelter.suppliesStatus)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(1)
            }
            
            // Helpline Phone
            HStack(spacing: 6) {
                Image(systemName: "phone.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.orange)
                Text("Helpline / Incharge: \(shelter.contactPhone)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            
            Divider().opacity(0.4)
            
            // Quick Intake Actions & Controls
            HStack(spacing: 8) {
                Text("Intake:")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(.secondary)
                
                Button("-10") {
                    onQuickAdjust(-10)
                }
                .buttonStyle(.plain)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .disabled(shelter.currentOccupancy <= 0)
                
                Button("+10") {
                    onQuickAdjust(10)
                }
                .buttonStyle(.plain)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.green.opacity(0.2))
                .foregroundColor(.green)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .disabled(shelter.currentOccupancy >= shelter.capacity)
                
                Spacer()
                
                Button {
                    onEdit()
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 10))
                }
                .buttonStyle(.plain)
                .padding(5)
                .background(Color.white.opacity(0.08))
                .clipShape(Circle())
                
                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 10))
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
                .padding(5)
                .background(Color.red.opacity(0.12))
                .clipShape(Circle())
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }
}

// MARK: - Add / Edit Relief Camp Interactive Modal Sheet
public struct AddOrEditReliefCampModalView: View {
    @ObservedObject var store: CommandCenterStore
    @Environment(\.dismiss) var dismiss
    let initialShelter: ReliefShelter?
    
    @State private var name: String = ""
    @State private var capacityString: String = "500"
    @State private var occupancyString: String = "0"
    @State private var suppliesStatus: String = "Ample Food, Water, Medical Aid & Solar Backup"
    @State private var contactPhone: String = "1078 (Disaster Helpline)"
    
    // Interactive Map & Pinpoint States
    @State private var selectedCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 28.6139, longitude: 77.2090)
    @State private var mapCameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 28.6139, longitude: 77.2090),
            span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
        )
    )
    
    // Place Search
    @State private var searchPlaceText: String = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching: Bool = false
    
    // Preset Quick Cities
    let quickCities: [(name: String, lat: Double, lon: Double)] = [
        ("Delhi NCR", 28.6139, 77.2090),
        ("Mumbai", 19.0760, 72.8777),
        ("Patna", 25.5941, 85.1376),
        ("Wayanad", 11.6854, 76.1320),
        ("Guwahati", 26.1445, 91.7362),
        ("Chennai", 13.0827, 80.2707),
        ("Kolkata", 22.5726, 88.3639),
        ("Bengaluru", 12.9716, 77.5946)
    ]
    
    public init(store: CommandCenterStore, initialShelter: ReliefShelter?) {
        self.store = store
        self.initialShelter = initialShelter
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "tent.fill")
                        .foregroundColor(.green)
                    Text(initialShelter == nil ? "CREATE NEW RELIEF CAMP" : "EDIT RELIEF CAMP")
                        .font(.system(size: 13, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            HStack(spacing: 0) {
                // Left Column: Interactive Map with Click-to-Pin & Place Search
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundColor(.cyan)
                        Text("PINPOINT LOCATION ON MAP")
                            .font(.system(size: 11, weight: .black, design: .monospaced))
                            .foregroundColor(.cyan)
                        Spacer()
                        Text("Click map to reposition pin")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                    
                    // Place Search Bar
                    HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search school, stadium, city, or landmark...", text: $searchPlaceText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 11))
                            .onSubmit {
                                searchLocations()
                            }
                            .onChange(of: searchPlaceText) { _, newQuery in
                                if newQuery.count >= 2 {
                                    searchLocations()
                                } else {
                                    searchResults = []
                                }
                            }
                        
                        if isSearching {
                            ProgressView().controlSize(.mini)
                        } else if !searchPlaceText.isEmpty {
                            Button {
                                searchPlaceText = ""
                                searchResults = []
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(8)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.12), lineWidth: 1))
                    
                    // Search Results Dropdown Overlay
                    if !searchResults.isEmpty {
                        ScrollView {
                            VStack(spacing: 2) {
                                ForEach(searchResults, id: \.self) { item in
                                    Button {
                                        let coord = item.placemark.coordinate
                                        selectedCoordinate = coord
                                        mapCameraPosition = .region(
                                            MKCoordinateRegion(
                                                center: coord,
                                                span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
                                            )
                                        )
                                        if name.isEmpty || name.starts(with: "Relief Camp") {
                                            name = "\(item.name ?? "Evacuation Hub") Relief Camp"
                                        }
                                        searchResults = []
                                    } label: {
                                        HStack {
                                            Image(systemName: "mappin.circle.fill")
                                                .foregroundColor(.green)
                                            VStack(alignment: .leading, spacing: 1) {
                                                Text(item.name ?? "Place")
                                                    .font(.system(size: 11, weight: .bold))
                                                    .foregroundColor(.white)
                                                if let address = item.placemark.title {
                                                    Text(address)
                                                        .font(.system(size: 9))
                                                        .foregroundColor(.secondary)
                                                        .lineLimit(1)
                                                }
                                            }
                                            Spacer()
                                        }
                                        .padding(6)
                                        .background(Color.white.opacity(0.05))
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .frame(maxHeight: 120)
                        .padding(6)
                        .background(Color.black.opacity(0.8))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    // Quick City Presets
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(quickCities, id: \.name) { city in
                                Button {
                                    let coord = CLLocationCoordinate2D(latitude: city.lat, longitude: city.lon)
                                    selectedCoordinate = coord
                                    mapCameraPosition = .region(
                                        MKCoordinateRegion(
                                            center: coord,
                                            span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
                                        )
                                    )
                                } label: {
                                    Text(city.name)
                                        .font(.system(size: 9, weight: .medium))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.white.opacity(0.08))
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // MapKit Canvas with Pin Marker & Tap Handler
                    ZStack {
                        MapReader { reader in
                            Map(position: $mapCameraPosition) {
                                Annotation("Selected Relief Shelter Location", coordinate: selectedCoordinate) {
                                    VStack(spacing: 2) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.green)
                                                .frame(width: 32, height: 32)
                                                .shadow(color: .green.opacity(0.6), radius: 8)
                                            Image(systemName: "tent.fill")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                        
                                        Text(name.isEmpty ? "New Shelter" : name)
                                            .font(.system(size: 8, weight: .bold))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(.ultraThinMaterial)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                            .mapStyle(.hybrid)
                            .onTapGesture { screenPoint in
                                if let coord = reader.convert(screenPoint, from: .local) {
                                    selectedCoordinate = coord
                                }
                            }
                        }
                        
                        // Overlay Coordinates HUD Box
                        VStack {
                            Spacer()
                            HStack {
                                HStack(spacing: 6) {
                                    Image(systemName: "location.fill")
                                        .foregroundColor(.green)
                                    Text("LAT: \(String(format: "%.5f", selectedCoordinate.latitude)) • LON: \(String(format: "%.5f", selectedCoordinate.longitude))")
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.green.opacity(0.4), lineWidth: 1))
                                
                                Spacer()
                            }
                            .padding(10)
                        }
                    }
                    .frame(height: 320)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.15), lineWidth: 1))
                }
                .padding(16)
                .frame(width: 440)
                
                Divider()
                
                // Right Column: Form Details & Resource Toggles
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("CAMP PROFILE & RESOURCES")
                            .font(.system(size: 11, weight: .black, design: .monospaced))
                            .foregroundColor(.secondary)
                        
                        // Camp Name
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Relief Camp / Facility Name")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.secondary)
                            
                            TextField("e.g. KV School Relief Hub Sector 4", text: $name)
                                .textFieldStyle(.plain)
                                .font(.system(size: 12, weight: .semibold))
                                .padding(8)
                                .background(Color.white.opacity(0.06))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.12), lineWidth: 1))
                        }
                        
                        // Capacity & Initial Occupancy Grid
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Total Bed Capacity")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.secondary)
                                
                                TextField("500", text: $capacityString)
                                    .textFieldStyle(.plain)
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .padding(8)
                                    .background(Color.white.opacity(0.06))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.12), lineWidth: 1))
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Current Intake / Occupancy")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.secondary)
                                
                                TextField("0", text: $occupancyString)
                                    .textFieldStyle(.plain)
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .padding(8)
                                    .background(Color.white.opacity(0.06))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.12), lineWidth: 1))
                            }
                        }
                        
                        // Supplies & Medical Status
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Supplies, Food & Medical Status")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.secondary)
                            
                            TextField("Ample Food, Drinking Water, Medical Aid & Solar Power", text: $suppliesStatus)
                                .textFieldStyle(.plain)
                                .font(.system(size: 11))
                                .padding(8)
                                .background(Color.white.opacity(0.06))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.12), lineWidth: 1))
                        }
                        
                        // Contact Phone & Incharge
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Disaster Helpline / Contact Phone")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.secondary)
                            
                            TextField("1078 (Disaster Helpline) / Officer Sharma", text: $contactPhone)
                                .textFieldStyle(.plain)
                                .font(.system(size: 11, design: .monospaced))
                                .padding(8)
                                .background(Color.white.opacity(0.06))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.12), lineWidth: 1))
                        }
                        
                        // Quick Presets for Supplies
                        VStack(alignment: .leading, spacing: 6) {
                            Text("QUICK RESOURCE TEMPLATES")
                                .font(.system(size: 9, weight: .black, design: .monospaced))
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 6) {
                                Button("Full Aid & Food") {
                                    suppliesStatus = "Ample Food, Potable Water, Doctor On-Duty & Generator Backup"
                                }
                                .font(.system(size: 9))
                                .padding(4)
                                .background(Color.green.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                
                                Button("Ration Urgent") {
                                    suppliesStatus = "Shelter Open • Food Ration Resupply Requested"
                                }
                                .font(.system(size: 9))
                                .padding(4)
                                .background(Color.orange.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                        }
                        
                        Spacer().frame(height: 10)
                        
                        // Save Button
                        Button {
                            saveCamp()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                Text(initialShelter == nil ? "Save & Broadcast to Citizens" : "Update Relief Camp")
                            }
                            .font(.system(size: 13, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(16)
                }
                .frame(width: 360)
            }
        }
        .frame(width: 820, height: 500)
        .onAppear {
            if let shelter = initialShelter {
                name = shelter.name
                capacityString = "\(shelter.capacity)"
                occupancyString = "\(shelter.currentOccupancy)"
                suppliesStatus = shelter.suppliesStatus
                contactPhone = shelter.contactPhone
                selectedCoordinate = shelter.coordinate
                mapCameraPosition = .region(
                    MKCoordinateRegion(
                        center: shelter.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
                    )
                )
            }
        }
    }
    
    private func searchLocations() {
        guard searchPlaceText.count >= 2 else { return }
        isSearching = true
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchPlaceText
        request.region = MKCoordinateRegion(
            center: selectedCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 2.0, longitudeDelta: 2.0)
        )
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            isSearching = false
            if let response = response {
                searchResults = Array(response.mapItems.prefix(5))
            }
        }
    }
    
    private func saveCamp() {
        let cap = Int(capacityString) ?? 500
        let occ = Int(occupancyString) ?? 0
        let finalShelter = ReliefShelter(
            id: initialShelter?.id ?? UUID().uuidString,
            name: name.trimmingCharacters(in: .whitespaces),
            latitude: selectedCoordinate.latitude,
            longitude: selectedCoordinate.longitude,
            capacity: cap,
            currentOccupancy: occ,
            suppliesStatus: suppliesStatus,
            contactPhone: contactPhone
        )
        
        if initialShelter != nil {
            store.updateReliefShelter(finalShelter)
        } else {
            store.addReliefShelter(finalShelter)
        }
        
        dismiss()
    }
}
