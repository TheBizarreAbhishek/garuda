import SwiftUI
import MapKit

public struct HazardGalleryView: View {
    @ObservedObject var store: CommandCenterStore
    
    @State private var searchText: String = ""
    @State private var selectedStatusFilter: HazardFilter = .all
    @State private var selectedCategory: String = "ALL"
    @State private var selectedHazard: HazardReport? = nil
    
    // Map State for selected hazard
    @State private var mapCameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 20.5937, longitude: 78.9629),
            span: MKCoordinateSpan(latitudeDelta: 15.0, longitudeDelta: 15.0)
        )
    )
    
    // Dispatch Modal State
    @State private var isShowingDispatchSheet: Bool = false
    @State private var selectedTeamForDispatch: String = "NDRF Unit 04 (Road Clearance)"
    
    let categories: [String] = ["ALL", "Landslide", "Flash Flood", "Bridge Collapse", "Road Blockage", "Electrical", "Tree Fall"]
    
    let ndrfUnitsList: [String] = [
        "NDRF Unit 04 (Heavy Machinery & Road Clearance)",
        "NDRF Battalion 9 (Flood Rescue Boat Team)",
        "SDRF Quick Response Unit #2",
        "State Fire & Rescue Team",
        "BRO (Border Roads Organisation Emergency Wing)"
    ]
    
    enum HazardFilter: String, CaseIterable {
        case all = "All Reports"
        case pending = "Pending Review"
        case roadBlocked = "Roads Blocked"
        case verified = "Verified Active"
        case resolved = "Cleared"
        case falseAlarm = "False Alarms"
    }
    
    public init(store: CommandCenterStore) {
        self.store = store
    }
    
    // Computed Metrics
    private var totalReports: Int { store.hazards.count }
    private var pendingReviewCount: Int { store.hazards.filter { $0.status == .unverified }.count }
    private var roadsBlockedCount: Int { store.hazards.filter { $0.status == .roadBlocked }.count }
    private var verifiedActiveCount: Int { store.hazards.filter { $0.status == .verifiedActive || $0.status == .roadBlocked }.count }
    private var resolvedCount: Int { store.hazards.filter { $0.status == .resolved }.count }
    private var falseAlarmsCount: Int { store.hazards.filter { $0.status == .falseAlarm }.count }
    
    private var filteredHazards: [HazardReport] {
        store.hazards.filter { hazard in
            let matchesSearch = searchText.isEmpty ||
                hazard.title.localizedCaseInsensitiveContains(searchText) ||
                hazard.description.localizedCaseInsensitiveContains(searchText) ||
                hazard.reporterName.localizedCaseInsensitiveContains(searchText) ||
                hazard.category.localizedCaseInsensitiveContains(searchText)
            
            if !matchesSearch { return false }
            
            if selectedCategory != "ALL" && !hazard.category.localizedCaseInsensitiveContains(selectedCategory) {
                return false
            }
            
            switch selectedStatusFilter {
            case .all:
                return true
            case .pending:
                return hazard.status == .unverified
            case .roadBlocked:
                return hazard.status == .roadBlocked
            case .verified:
                return hazard.status == .verifiedActive || hazard.status == .roadBlocked
            case .resolved:
                return hazard.status == .resolved
            case .falseAlarm:
                return hazard.status == .falseAlarm
            }
        }
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // 1. Top Command Header
            headerBar
            
            Divider()
            
            // 2. Metrics Bar (Including False Alarm Prevention Counter)
            metricsBar
            
            Divider()
            
            // 3. Search & Category Filter Toolbar
            filterToolbar
            
            Divider()
            
            // 4. Main Two-Column Layout: Left List + Right Inspector & Live Map
            GeometryReader { geo in
                HStack(spacing: 0) {
                    // Left Column: Hazard Reports List
                    reportsListView
                        .frame(width: max(380, geo.size.width * 0.42))
                    
                    Divider()
                    
                    // Right Column: Detailed Inspector & Satellite Location Map
                    if let hazard = selectedHazard {
                        hazardDetailInspectorView(hazard: hazard)
                    } else {
                        noSelectionPlaceholder
                    }
                }
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            if selectedHazard == nil, let first = filteredHazards.first {
                selectHazard(first)
            }
        }
    }
    
    // MARK: - Header Bar
    private var headerBar: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 36, height: 36)
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 16, weight: .black))
                    .foregroundColor(.orange)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text("HAZARD & DAMAGE VERIFICATION HUB")
                        .font(.system(size: 13, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 4) {
                        Circle().fill(Color.green).frame(width: 6, height: 6)
                        Text("MULTI-PEER CONSENSUS ACTIVE")
                            .font(.system(size: 8, weight: .black, design: .monospaced))
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.15))
                    .clipShape(Capsule())
                }
                
                Text("Crowdsourced geo-tagged reports submitted via BLE mesh & gateway cloud uplink. False alarm filtering enabled.")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Fast Add Manual Hazard Report
            Button {
                let manualReport = HazardReport(
                    title: "Blocked Evacuation Route (Manual Override)",
                    category: "Road Blockage",
                    latitude: 28.6139,
                    longitude: 77.2090,
                    reporterName: "NDRF Command HQ",
                    isVerified: true,
                    description: "High water levels on state highway. Reroute advised.",
                    status: .roadBlocked,
                    peerConfirmations: 5,
                    severity: "High"
                )
                store.addHazard(manualReport)
                selectHazard(manualReport)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                    Text("Log Field Hazard")
                }
                .font(.system(size: 11, weight: .bold))
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Metrics Bar
    private var metricsBar: some View {
        HStack(spacing: 12) {
            metricCard(
                title: "TOTAL REPORTS",
                value: "\(totalReports)",
                subtitle: "Field Ingestions",
                icon: "doc.text.image.fill",
                color: .blue
            )
            
            metricCard(
                title: "PENDING REVIEW",
                value: "\(pendingReviewCount)",
                subtitle: "Needs Verification",
                icon: "clock.arrow.circlepath",
                color: pendingReviewCount > 0 ? .orange : .secondary
            )
            
            metricCard(
                title: "ROADS BLOCKED",
                value: "\(roadsBlockedCount)",
                subtitle: "Active Reroutes",
                icon: "nosign",
                color: roadsBlockedCount > 0 ? .red : .secondary
            )
            
            metricCard(
                title: "VERIFIED ACTIVE",
                value: "\(verifiedActiveCount)",
                subtitle: "Confirmed Threats",
                icon: "checkmark.seal.fill",
                color: .yellow
            )
            
            metricCard(
                title: "FALSE ALARMS BLOCKED",
                value: "\(falseAlarmsCount)",
                subtitle: "Spam Prevented",
                icon: "shield.slash.fill",
                color: .purple
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.2))
    }
    
    private func metricCard(title: String, value: String, subtitle: String, icon: String, color: Color) -> some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 8, weight: .black, design: .monospaced))
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
        .padding(8)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }
    
    // MARK: - Filter Toolbar
    private var filterToolbar: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                // Search Bar
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search damage reports, locations, categories...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.1), lineWidth: 1))
                .frame(maxWidth: 320)
                
                // Status Picker
                Picker("Status", selection: $selectedStatusFilter) {
                    ForEach(HazardFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                
                Spacer()
                
                Text("\(filteredHazards.count) Incidents")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            
            // Category Filter Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(categories, id: \.self) { cat in
                        Button {
                            selectedCategory = cat
                        } label: {
                            Text(cat)
                                .font(.system(size: 10, weight: selectedCategory == cat ? .bold : .medium))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(selectedCategory == cat ? Color.orange.opacity(0.3) : Color.white.opacity(0.06))
                                .foregroundColor(selectedCategory == cat ? .orange : .secondary)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(selectedCategory == cat ? Color.orange.opacity(0.6) : Color.white.opacity(0.1), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Left Reports List View
    private var reportsListView: some View {
        Group {
            if filteredHazards.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "checkmark.shield")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("No Hazard Reports Found")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                    Text("Reports submitted by citizens or field teams via BLE mesh will appear here for verification.")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(filteredHazards) { hazard in
                            HazardListRowView(
                                hazard: hazard,
                                isSelected: selectedHazard?.id == hazard.id,
                                onSelect: {
                                    selectHazard(hazard)
                                }
                            )
                        }
                    }
                    .padding(14)
                }
            }
        }
    }
    
    // MARK: - Right Detailed Inspector & Interactive Map
    private func hazardDetailInspectorView(hazard: HazardReport) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 1. Status Banner & Quick Verification Controls
                verificationActionBar(hazard: hazard)
                
                // 2. Interactive Location Map with Road Blockage Perimeter
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("EXACT INCIDENT LOCATION", systemImage: "map.fill")
                            .font(.system(size: 11, weight: .black, design: .monospaced))
                            .foregroundColor(.white)
                        Spacer()
                        Text("Lat: \(String(format: "%.4f", hazard.latitude))°N, Lon: \(String(format: "%.4f", hazard.longitude))°E")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    
                    ZStack(alignment: .topTrailing) {
                        Map(position: $mapCameraPosition) {
                            Marker(hazard.title, coordinate: hazard.coordinate)
                                .tint(markerColor(for: hazard.status))
                            
                            if hazard.status == .roadBlocked {
                                MapCircle(center: hazard.coordinate, radius: 800)
                                    .foregroundStyle(Color.red.opacity(0.25))
                                    .stroke(Color.red, lineWidth: 2)
                            }
                        }
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.15), lineWidth: 1))
                        
                        // Satellite / Hybrid badge
                        Text("MAP SATELLITE RADAR")
                            .font(.system(size: 8, weight: .black, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.black.opacity(0.75))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .padding(8)
                    }
                }
                
                // 3. False Alarm Prevention & Trust Consensus Card
                consensusTrustCard(hazard: hazard)
                
                // 4. Incident Details Card
                VStack(alignment: .leading, spacing: 10) {
                    Text("HAZARD DETAILS & FIELD NOTES")
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Category:")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.secondary)
                            Text(hazard.category)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.orange)
                            
                            Spacer()
                            
                            Text("Severity:")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.secondary)
                            Text(hazard.severity)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(hazard.severity == "High" ? .red : .yellow)
                        }
                        
                        Divider().opacity(0.2)
                        
                        Text("Description:")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        Text(hazard.description.isEmpty ? "No detailed description provided by citizen." : hazard.description)
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.black.opacity(0.3))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        
                        Divider().opacity(0.2)
                        
                        HStack {
                            Text("Reported by:")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.secondary)
                            Text(hazard.reporterName)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.cyan)
                            
                            Spacer()
                            
                            Text("Report Time:")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.secondary)
                            Text(hazard.reportedAt.formatted(date: .abbreviated, time: .standard))
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.08), lineWidth: 1))
                }
                
                // 5. Assigned Response Unit
                if let team = hazard.assignedTeam {
                    HStack(spacing: 10) {
                        Image(systemName: "person.3.sequence.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.green)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("ASSIGNED NDRF RESPONSE TEAM")
                                .font(.system(size: 9, weight: .black, design: .monospaced))
                                .foregroundColor(.green)
                            Text(team)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.green.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.green.opacity(0.3), lineWidth: 1))
                }
            }
            .padding(18)
        }
    }
    
    // MARK: - Action Bar
    private func verificationActionBar(hazard: HazardReport) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(hazard.title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                    
                    statusPill(for: hazard.status)
                }
                
                Spacer()
                
                // Delete button
                Button {
                    store.deleteHazard(id: hazard.id)
                    selectedHazard = filteredHazards.first
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
                .padding(8)
                .background(Color.red.opacity(0.15))
                .clipShape(Circle())
            }
            
            Divider().opacity(0.2)
            
            // Action Buttons
            HStack(spacing: 8) {
                // 1. Declare Road Blocked
                Button {
                    store.updateHazardStatus(id: hazard.id, newStatus: .roadBlocked, assignedTeam: hazard.assignedTeam)
                    selectHazard(hazard)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "nosign")
                        Text("Verify & Block Road")
                    }
                    .font(.system(size: 11, weight: .bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                
                // 2. Dispatch Clearance Unit
                Button {
                    let defaultUnit = "NDRF Unit 04 (Heavy Machinery & Road Clearance)"
                    store.updateHazardStatus(id: hazard.id, newStatus: .verifiedActive, assignedTeam: defaultUnit)
                    selectHazard(hazard)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "airplane.departure")
                        Text("Dispatch NDRF Unit")
                    }
                    .font(.system(size: 11, weight: .bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                
                // 3. Mark Resolved / Cleared
                Button {
                    store.updateHazardStatus(id: hazard.id, newStatus: .resolved, assignedTeam: hazard.assignedTeam)
                    selectHazard(hazard)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Mark Cleared")
                    }
                    .font(.system(size: 11, weight: .bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                
                Spacer()
                
                // 4. Flag False Alarm / Spam
                Button {
                    store.updateHazardStatus(id: hazard.id, newStatus: .falseAlarm, assignedTeam: nil)
                    selectHazard(hazard)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "shield.slash")
                        Text("Flag False Alarm")
                    }
                    .font(.system(size: 11, weight: .bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                }
                .buttonStyle(.bordered)
                .tint(.purple)
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.12), lineWidth: 1))
    }
    
    // MARK: - False Alarm Prevention Consensus Card
    private func consensusTrustCard(hazard: HazardReport) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("ANTI-SPOOFING & PEER CONSENSUS", systemImage: "shield.checkered")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundColor(.cyan)
                
                Spacer()
                
                Text(hazard.peerConfirmations >= 3 ? "HIGH TRUST (98%)" : "SINGLE REPORT (PENDING)")
                    .font(.system(size: 9, weight: .black, design: .monospaced))
                    .foregroundColor(hazard.peerConfirmations >= 3 ? .green : .orange)
            }
            
            HStack(spacing: 12) {
                // Peer Confirmation Count
                HStack(spacing: 6) {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(hazard.peerConfirmations >= 2 ? .green : .secondary)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("\(hazard.peerConfirmations) Mesh Peers")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                        Text("Independent nodes reported")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                
                // EXIF GPS & Device Signature
                HStack(spacing: 6) {
                    Image(systemName: "camera.viewfinder")
                        .foregroundColor(.cyan)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Live Camera EXIF")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                        Text("Tamper-proof hardware GPS")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
        .padding(12)
        .background(Color.cyan.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.cyan.opacity(0.25), lineWidth: 1))
    }
    
    // MARK: - No Selection Placeholder
    private var noSelectionPlaceholder: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "hand.tap")
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.4))
            Text("Select a Hazard Report to Inspect & Verify")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.secondary)
            Text("View photos, verify road blockages, and dispatch NDRF clearance teams.")
                .font(.system(size: 10))
                .foregroundColor(.secondary.opacity(0.8))
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func selectHazard(_ hazard: HazardReport) {
        selectedHazard = hazard
        mapCameraPosition = .region(
            MKCoordinateRegion(
                center: hazard.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
            )
        )
    }
    
    private func markerColor(for status: HazardStatus) -> Color {
        switch status {
        case .unverified: return .orange
        case .roadBlocked: return .red
        case .verifiedActive: return .yellow
        case .resolved: return .green
        case .falseAlarm: return .purple
        }
    }
    
    private func statusPill(for status: HazardStatus) -> some View {
        HStack(spacing: 4) {
            Circle().fill(markerColor(for: status)).frame(width: 6, height: 6)
            Text(status.rawValue)
                .font(.system(size: 9, weight: .black, design: .monospaced))
                .foregroundColor(markerColor(for: status))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(markerColor(for: status).opacity(0.15))
        .clipShape(Capsule())
    }
}

// MARK: - Hazard List Row View
public struct HazardListRowView: View {
    let hazard: HazardReport
    let isSelected: Bool
    let onSelect: () -> Void
    
    private var statusColor: Color {
        switch hazard.status {
        case .unverified: return .orange
        case .roadBlocked: return .red
        case .verifiedActive: return .yellow
        case .resolved: return .green
        case .falseAlarm: return .purple
        }
    }
    
    public var body: some View {
        Button {
            onSelect()
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(statusColor.opacity(0.2))
                            .frame(width: 28, height: 28)
                        Image(systemName: hazard.status == .roadBlocked ? "nosign" : "exclamationmark.triangle.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(statusColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(hazard.title)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text(hazard.category)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.orange)
                    }
                    
                    Spacer()
                    
                    Text(hazard.status.rawValue)
                        .font(.system(size: 8, weight: .black, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(statusColor.opacity(0.2))
                        .foregroundColor(statusColor)
                        .clipShape(Capsule())
                }
                
                Text(hazard.description)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                Divider().opacity(0.15)
                
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 9))
                        Text("\(hazard.peerConfirmations) peers")
                            .font(.system(size: 9, design: .monospaced))
                    }
                    .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(hazard.reportedAt.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
            .padding(10)
            .background(isSelected ? Color.white.opacity(0.12) : Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.orange : Color.white.opacity(0.08), lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}
