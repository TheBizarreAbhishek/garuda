import SwiftUI

// MARK: - Selected Geo Region Model
public struct SelectedGeoRegion: Identifiable, Hashable, Sendable {
    public var id: String { "\(district), \(state)" }
    public let state: String
    public let district: String
    
    public init(state: String, district: String) {
        self.state = state
        self.district = district
    }
    
    public var displayName: String {
        if state == "National / Pan-India" || state.isEmpty {
            return district
        }
        return "\(district), \(state)"
    }
}

public struct EmergencyBroadcasterView: View {
    @ObservedObject var store: CommandCenterStore
    
    // =========================================================================
    // SECTION 1: Emergency Declaration States (Multi-Region Selection)
    // =========================================================================
    @State private var alertTitle: String = "Flash Flood & Inundation Immediate Evacuation Alert"
    @State private var severityLevel: String = "Level 3 - Critical / Red Alert"
    @State private var alertMessage: String = "NDMA DIRECTIVE: Rapidly rising flood waters. Evacuate low-lying areas immediately. Keep Bluetooth Mesh enabled for beacon relay."
    
    // Multi-Region Staged List (Initialized empty - NO hardcoded bias)
    @State private var stagedEmergencyRegions: [SelectedGeoRegion] = []
    
    // Search & Picker States for Section 1
    @State private var geoSearchText: String = ""
    @State private var pickerSelectedState: String = ""
    @State private var pickerSelectedDistrict: String = ""
    @State private var showDeclarationToast: String?
    
    // =========================================================================
    // SECTION 3: Targeted Push Notification States (Multi-Target Selection)
    // =========================================================================
    @State private var notifTargetScope: String = "Active Emergency Zones" // "Active Emergency Zones", "Custom Regions", "Pan-India", "Active Mesh Nodes"
    @State private var stagedNotifRegions: [SelectedGeoRegion] = []
    @State private var notifGeoSearchText: String = ""
    @State private var notifPickerSelectedState: String = ""
    @State private var notifPickerSelectedDistrict: String = ""
    @State private var notifTitle: String = "NDMA Immediate Evacuation & Safety Advisory"
    @State private var notifMessage: String = "Move to higher ground or nearest relief camp immediately. Keep phone battery saver enabled."
    @State private var notifPriority: String = "CRITICAL - Highest Priority"
    @State private var showNotifToast: String?
    
    // Computed active emergency alerts from store
    private var activeAlerts: [DisasterAlert] {
        store.alerts.filter { $0.isEmergencyActive }
    }
    
    // Filtered search results for Section 1
    private var filteredGeoSearchResults: [(state: String, district: String)] {
        guard !geoSearchText.isEmpty else { return [] }
        var results: [(state: String, district: String)] = []
        let query = geoSearchText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        for stateObj in IndiaGeoData.states {
            for dist in stateObj.districts {
                if dist.lowercased().contains(query) || stateObj.stateName.lowercased().contains(query) {
                    results.append((state: stateObj.stateName, district: dist))
                }
            }
        }
        return results
    }
    
    // Filtered search results for Section 3
    private var notifFilteredGeoSearchResults: [(state: String, district: String)] {
        guard !notifGeoSearchText.isEmpty else { return [] }
        var results: [(state: String, district: String)] = []
        let query = notifGeoSearchText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        for stateObj in IndiaGeoData.states {
            for dist in stateObj.districts {
                if dist.lowercased().contains(query) || stateObj.stateName.lowercased().contains(query) {
                    results.append((state: stateObj.stateName, district: dist))
                }
            }
        }
        return results
    }
    
    // Computed description of targeted push recipients
    private var notifTargetSummaryString: String {
        switch notifTargetScope {
        case "Active Emergency Zones":
            if activeAlerts.isEmpty {
                return "All Disaster Standby Zones (No Active Emergencies)"
            } else {
                let names = activeAlerts.map { $0.targetDistrict }
                return "\(names.count) Active Emergency Zone(s): " + names.joined(separator: ", ")
            }
        case "Pan-India":
            return "Pan-India (All Registered Citizen Devices)"
        case "Active Mesh Nodes":
            return "All Live Connected Online Field Mesh Nodes"
        case "Custom Regions":
            if stagedNotifRegions.isEmpty {
                return "No Regions Selected (Select from search or dropdown below)"
            } else {
                return stagedNotifRegions.map { $0.displayName }.joined(separator: "; ")
            }
        default:
            return notifTargetScope
        }
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // =============================================================
                // 1. TOP COMMAND HEADER
                // =============================================================
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(activeAlerts.isEmpty ? Color.green.opacity(0.18) : Color.red.opacity(0.2))
                            .frame(width: 48, height: 48)
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.title2.bold())
                            .foregroundColor(activeAlerts.isEmpty ? .green : .red)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Government Emergency Command & Multi-Region Broadcast Hub")
                            .font(.title2.bold())
                        Text("National Disaster Management Authority (NDMA) Unified All-India Multi-Zone Dispatcher")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Live Status Badges
                    HStack(spacing: 12) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(activeAlerts.isEmpty ? Color.green : Color.red)
                                .frame(width: 8, height: 8)
                            Text(activeAlerts.isEmpty ? "SYSTEM STANDBY" : "ACTIVE EMERGENCY (\(activeAlerts.count) ZONES)")
                                .font(.caption.bold())
                                .foregroundColor(activeAlerts.isEmpty ? .green : .red)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.35))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(activeAlerts.isEmpty ? Color.green.opacity(0.4) : Color.red.opacity(0.5), lineWidth: 1))
                        
                        if !activeAlerts.isEmpty {
                            Button {
                                store.broadcastEmergencyDeactivation()
                                stagedEmergencyRegions.removeAll()
                                withAnimation {
                                    showDeclarationToast = "🛡️ All Active Emergency Declarations Revoked. System is in Global Standby."
                                }
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: "shield.slash")
                                    Text("Deactivate All")
                                        .font(.caption.bold())
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.red.opacity(0.2))
                                .foregroundColor(.red)
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                            .help("Revoke all active emergencies across all regions and return to standby")
                        }
                    }
                }
                .padding(18)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                
                // =============================================================
                // 2. SECTION 1: DECLARE EMERGENCY IN SPECIFIC / MULTIPLE REGIONS
                // =============================================================
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .center) {
                        Label("1. Declare Emergency (Single or Multiple Regions)", systemImage: "exclamationmark.triangle.fill")
                            .font(.title3.bold())
                            .foregroundColor(.red)
                        Spacer()
                        Text("Multi-Zone Geofenced Activation")
                            .font(.subheadline.bold())
                            .foregroundColor(.secondary)
                    }
                    
                    // Quick Scenario Presets
                    VStack(alignment: .leading, spacing: 8) {
                        Text("QUICK DISASTER SCENARIO PRESETS")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ScenarioPresetButton(title: "🌊 Flash Flood", color: .blue) {
                                alertTitle = "Flash Flood & Inundation Immediate Evacuation Alert"
                                severityLevel = "Level 3 - Critical / Red Alert"
                                alertMessage = "NDMA DIRECTIVE: Rapidly rising flood waters. Evacuate low-lying areas immediately. Keep Bluetooth Mesh enabled for beacon relay."
                            }
                            ScenarioPresetButton(title: "🏔️ Landslide", color: .brown) {
                                alertTitle = "Massive Landslide & Slope Collapse Alert"
                                severityLevel = "Level 3 - Critical / Red Alert"
                                alertMessage = "DISASTER DIRECTIVE: Hillside slope failure reported. Evacuate vulnerable structures. Do not use bridges or riverbank roads."
                            }
                            ScenarioPresetButton(title: "🏚️ Earthquake", color: .orange) {
                                alertTitle = "Major Earthquake Seismic Warning"
                                severityLevel = "Level 3 - Critical / Red Alert"
                                alertMessage = "NDMA ALERT: High-magnitude seismic shocks. Stay in open areas away from buildings. Emergency rescue teams deploying."
                            }
                            ScenarioPresetButton(title: "🔥 Fire Hazard", color: .red) {
                                alertTitle = "Severe Industrial & Forest Fire Warning"
                                severityLevel = "Level 2 - High Alert / Orange"
                                alertMessage = "EVACUATION ORDER: Severe fire perimeter spreading. Follow designated escape corridors to safe relief camps."
                            }
                            ScenarioPresetButton(title: "🌪️ Cyclone / Storm", color: .purple) {
                                alertTitle = "Severe Tropical Cyclone & Gale Wind Alert"
                                severityLevel = "Level 3 - Critical / Red Alert"
                                alertMessage = "NDMA WARNING: Extreme wind speeds and storm surge. Seek refuge in pucca cyclone shelters immediately."
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Multi-Region Selector Box
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("SELECT & ADD TARGET REGIONS (28 STATES & 8 UTs)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.secondary)
                            Spacer()
                            if !stagedEmergencyRegions.isEmpty {
                                Button("Clear Selected Regions") {
                                    stagedEmergencyRegions.removeAll()
                                }
                                .font(.caption.bold())
                                .foregroundColor(.red)
                                .buttonStyle(.plain)
                            }
                        }
                        
                        // Universal Instant Search Across All India
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            TextField("Search any Indian district or state (e.g. Wayanad, Chamoli, Pune, Patna, Shimla, Darjeeling)...", text: $geoSearchText)
                                .textFieldStyle(.plain)
                                .font(.body)
                            if !geoSearchText.isEmpty {
                                Button {
                                    geoSearchText = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(10)
                        .background(Color(NSColor.controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 1))
                        
                        // Search Suggestions Dropdown (if searching)
                        if !geoSearchText.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                if filteredGeoSearchResults.isEmpty {
                                    Text("No matching Indian districts found for '\(geoSearchText)'")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .padding(8)
                                } else {
                                    ForEach(filteredGeoSearchResults.prefix(6), id: \.district) { res in
                                        let isAlreadyAdded = stagedEmergencyRegions.contains(where: { $0.district == res.district && $0.state == res.state })
                                        Button {
                                            if !isAlreadyAdded {
                                                stagedEmergencyRegions.append(SelectedGeoRegion(state: res.state, district: res.district))
                                            }
                                            geoSearchText = ""
                                        } label: {
                                            HStack {
                                                Image(systemName: isAlreadyAdded ? "checkmark.circle.fill" : "plus.circle.fill")
                                                    .foregroundColor(isAlreadyAdded ? .green : .red)
                                                Text(res.district)
                                                    .font(.subheadline.bold())
                                                Text("(\(res.state))")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                Spacer()
                                                Text(isAlreadyAdded ? "Added" : "+ Add to Emergency List")
                                                    .font(.caption.bold())
                                                    .foregroundColor(isAlreadyAdded ? .green : .red)
                                            }
                                            .padding(8)
                                            .background(Color.white.opacity(0.04))
                                            .cornerRadius(6)
                                        }
                                        .buttonStyle(.plain)
                                        .disabled(isAlreadyAdded)
                                    }
                                }
                            }
                            .padding(6)
                            .background(Color.black.opacity(0.4))
                            .cornerRadius(8)
                        } else {
                            // State & District Dropdowns for manual selection
                            HStack(spacing: 12) {
                                // State Dropdown
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("State / UT").font(.caption.bold()).foregroundColor(.secondary)
                                    Picker("", selection: $pickerSelectedState) {
                                        Text("Select State / UT...").tag("")
                                        ForEach(IndiaGeoData.states) { stateObj in
                                            Text(stateObj.stateName).tag(stateObj.stateName)
                                        }
                                    }
                                    .labelsHidden()
                                    .onChange(of: pickerSelectedState) { _, newState in
                                        pickerSelectedDistrict = ""
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                
                                // District Dropdown
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("District").font(.caption.bold()).foregroundColor(.secondary)
                                    let currentDistricts = IndiaGeoData.states.first(where: { $0.stateName == pickerSelectedState })?.districts ?? []
                                    Picker("", selection: $pickerSelectedDistrict) {
                                        Text(pickerSelectedState.isEmpty ? "Select State First..." : "Select District...").tag("")
                                        ForEach(currentDistricts, id: \.self) { dist in
                                            Text(dist).tag(dist)
                                        }
                                    }
                                    .labelsHidden()
                                    .disabled(pickerSelectedState.isEmpty)
                                }
                                .frame(maxWidth: .infinity)
                                
                                // Add Button
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(" ").font(.caption)
                                    Button {
                                        guard !pickerSelectedState.isEmpty && !pickerSelectedDistrict.isEmpty else { return }
                                        let newRegion = SelectedGeoRegion(state: pickerSelectedState, district: pickerSelectedDistrict)
                                        if !stagedEmergencyRegions.contains(newRegion) {
                                            stagedEmergencyRegions.append(newRegion)
                                        }
                                    } label: {
                                        HStack(spacing: 5) {
                                            Image(systemName: "plus")
                                            Text("Add Region")
                                                .fontWeight(.bold)
                                        }
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 7)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.red)
                                    .disabled(pickerSelectedState.isEmpty || pickerSelectedDistrict.isEmpty)
                                }
                            }
                        }
                        
                        // Selected Regions Chips Display
                        if !stagedEmergencyRegions.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("STAGED REGIONS FOR ACTIVATION (\(stagedEmergencyRegions.count)):")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.red)
                                
                                FlowLayout(spacing: 8) {
                                    ForEach(stagedEmergencyRegions) { region in
                                        HStack(spacing: 6) {
                                            Image(systemName: "mappin.circle.fill")
                                                .foregroundColor(.red)
                                            Text(region.displayName)
                                                .font(.subheadline.bold())
                                            Button {
                                                stagedEmergencyRegions.removeAll(where: { $0.id == region.id })
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.secondary)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color.red.opacity(0.15))
                                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Color.red.opacity(0.4), lineWidth: 1))
                                    }
                                }
                            }
                            .padding(10)
                            .background(Color.black.opacity(0.25))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        } else {
                            HStack {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.secondary)
                                Text("No regions staged yet. Search any Indian district above or pick from dropdown to stage one or multiple disaster zones.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(8)
                            .background(Color.white.opacity(0.03))
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        }
                    }
                    
                    Divider()
                    
                    // Severity & Headline
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Disaster Severity Level").font(.subheadline.bold())
                            Picker("", selection: $severityLevel) {
                                Text("Level 3 - Critical / Red Alert (Immediate Evacuation)").tag("Level 3 - Critical / Red Alert")
                                Text("Level 2 - High Alert / Orange (Preparedness)").tag("Level 2 - High Alert / Orange")
                                Text("Level 1 - Watch & Warning / Yellow").tag("Level 1 - Watch & Warning / Yellow")
                            }
                            .labelsHidden()
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Emergency Headline").font(.subheadline.bold())
                            TextField("Enter headline...", text: $alertTitle)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    
                    // Directive
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Citizen Instructions & Evacuation Directive").font(.subheadline.bold())
                        TextEditor(text: $alertMessage)
                            .font(.system(size: 13))
                            .frame(height: 70)
                            .padding(6)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 1))
                    }
                    
                    // Section 1 Action Buttons
                    HStack(spacing: 16) {
                        let regionCount = stagedEmergencyRegions.count
                        let buttonTitle: String = {
                            if regionCount == 0 {
                                return "DECLARE EMERGENCY (Select Regions First)"
                            } else if regionCount == 1 {
                                return "DECLARE EMERGENCY IN [\(stagedEmergencyRegions[0].displayName)]"
                            } else {
                                return "DECLARE EMERGENCY IN [\(regionCount) SELECTED REGIONS]"
                            }
                        }()
                        
                        Button {
                            guard !stagedEmergencyRegions.isEmpty else { return }
                            let districtStrings = stagedEmergencyRegions.map { $0.displayName }
                            store.broadcastEmergencyActivation(
                                title: alertTitle,
                                severity: severityLevel,
                                districts: districtStrings,
                                instructions: alertMessage
                            )
                            let joinedNames = districtStrings.joined(separator: ", ")
                            withAnimation {
                                showDeclarationToast = "🚨 Emergency Broadcast Activated in [\(joinedNames)]!"
                            }
                            stagedEmergencyRegions.removeAll()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "bolt.fill")
                                Text(buttonTitle)
                                    .fontWeight(.bold)
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .controlSize(.large)
                        .disabled(stagedEmergencyRegions.isEmpty)
                        
                        if !activeAlerts.isEmpty {
                            Text("ℹ️ \(activeAlerts.count) zone(s) currently active. Declaring new regions will add them incrementally.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if let toast = showDeclarationToast {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.green)
                            Text(toast)
                                .font(.subheadline.bold())
                                .foregroundColor(.green)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.green.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .transition(.opacity)
                    }
                }
                .padding(18)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                
                // =============================================================
                // 3. SECTION 2: ACTIVE EMERGENCY ZONES (MULTI-REGION MONITOR)
                // =============================================================
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Label("2. Active Emergency Zones", systemImage: "map.circle.fill")
                            .font(.title3.bold())
                            .foregroundColor(.orange)
                        
                        Spacer()
                        
                        Text("\(activeAlerts.count) Area(s) Currently Active")
                            .font(.subheadline.bold())
                            .foregroundColor(activeAlerts.isEmpty ? .secondary : .red)
                    }
                    
                    if activeAlerts.isEmpty {
                        HStack(spacing: 14) {
                            Image(systemName: "checkmark.shield.fill")
                                .font(.title)
                                .foregroundColor(.green)
                            VStack(alignment: .leading, spacing: 3) {
                                Text("All 28 States & 8 UTs in Normal Standby")
                                    .font(.headline)
                                    .foregroundColor(.green)
                                Text("No active disaster declarations currently in force. Citizen nodes remain in ultra-low-power standby mode.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.green.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color.green.opacity(0.25), lineWidth: 1))
                    } else {
                        VStack(spacing: 12) {
                            ForEach(activeAlerts) { alert in
                                HStack(alignment: .top, spacing: 14) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.red.opacity(0.2))
                                            .frame(width: 42, height: 42)
                                        Image(systemName: "exclamationmark.octagon.fill")
                                            .font(.title3)
                                            .foregroundColor(.red)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(alert.targetDistrict)
                                                .font(.headline.bold())
                                                .foregroundColor(.red)
                                            
                                            Text("• \(alert.severity)")
                                                .font(.subheadline.bold())
                                                .foregroundColor(.orange)
                                            
                                            Spacer()
                                            
                                            Text(alert.timestamp.formatted(date: .omitted, time: .shortened))
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Text(alert.title)
                                            .font(.subheadline.weight(.semibold))
                                        
                                        Text(alert.instructions)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    // Individual Action Buttons for this specific district
                                    HStack(spacing: 8) {
                                        Button {
                                            notifTargetScope = "Custom Regions"
                                            // Split district string if possible
                                            let parts = alert.targetDistrict.components(separatedBy: ",")
                                            let dist = parts.first?.trimmingCharacters(in: .whitespaces) ?? alert.targetDistrict
                                            let state = parts.count > 1 ? parts[1].trimmingCharacters(in: .whitespaces) : ""
                                            let newReg = SelectedGeoRegion(state: state, district: dist)
                                            if !stagedNotifRegions.contains(newReg) {
                                                stagedNotifRegions.append(newReg)
                                            }
                                        } label: {
                                            HStack(spacing: 4) {
                                                Image(systemName: "bell.badge")
                                                Text("Send Push")
                                                    .font(.caption.bold())
                                            }
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 8)
                                            .background(Color.blue.opacity(0.15))
                                            .foregroundColor(.blue)
                                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                        }
                                        .buttonStyle(.plain)
                                        .help("Target push notification to this active district")
                                        
                                        Button {
                                            store.deactivateSpecificAlert(id: alert.id)
                                        } label: {
                                            HStack(spacing: 4) {
                                                Image(systemName: "xmark.circle")
                                                Text("End Emergency")
                                                    .font(.caption.bold())
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(Color.red.opacity(0.15))
                                            .foregroundColor(.red)
                                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                        }
                                        .buttonStyle(.plain)
                                        .help("Revoke emergency status for this district and return to standby")
                                    }
                                }
                                .padding(14)
                                .background(Color(nsColor: .controlBackgroundColor))
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color.red.opacity(0.3), lineWidth: 1))
                            }
                        }
                    }
                }
                .padding(18)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                
                // =============================================================
                // 4. SECTION 3: TARGETED PUSH NOTIFICATION DISPATCHER
                // =============================================================
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        Label("3. Dispatch Targeted Push Notification", systemImage: "bell.badge.fill")
                            .font(.title3.bold())
                            .foregroundColor(.blue)
                        Spacer()
                        Text("Firebase FCM + Field BLE Mesh Relay")
                            .font(.subheadline.bold())
                            .foregroundColor(.secondary)
                    }
                    
                    // Quick Notification Presets
                    VStack(alignment: .leading, spacing: 8) {
                        Text("QUICK NOTIFICATION TEMPLATES")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ScenarioPresetButton(title: "🏃 Evacuation Order", color: .red) {
                                notifTitle = "IMMEDIATE EVACUATION DIRECTIVE"
                                notifMessage = "Move to higher ground or nearest designated shelter immediately. Emergency rescue teams deploying."
                                notifPriority = "CRITICAL - Highest Priority"
                            }
                            ScenarioPresetButton(title: "⛺ Food & Relief Camp", color: .green) {
                                notifTitle = "Relief Camp & Potable Water Distribution Open"
                                notifMessage = "Community hall relief camp active with food, dry rations, and clean drinking water."
                                notifPriority = "MEDIUM - Information"
                            }
                            ScenarioPresetButton(title: "🏥 Medical Aid Center", color: .cyan) {
                                notifTitle = "Emergency Medical & First Aid Post Established"
                                notifMessage = "Medical teams and ambulances stationed at District Health Camp with trauma and first aid supplies."
                                notifPriority = "HIGH - Urgent Alert"
                            }
                            ScenarioPresetButton(title: "⛈️ Weather Warning", color: .orange) {
                                notifTitle = "Severe Thunderstorm & Rainfall Warning"
                                notifMessage = "Intense spells of rain expected in the next 3 hours. Avoid flood-prone culverts and loose power lines."
                                notifPriority = "HIGH - Urgent Alert"
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Target Scope Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("TARGET RECIPIENT RECIPIENTS / SCOPE")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 16) {
                            Picker("Scope", selection: $notifTargetScope) {
                                Text("⚡ Active Emergency Zones (\(activeAlerts.count))").tag("Active Emergency Zones")
                                Text("📍 Custom Selected Regions").tag("Custom Regions")
                                Text("🇮🇳 Pan-India").tag("Pan-India")
                                Text("🌐 Online Field Mesh Nodes").tag("Active Mesh Nodes")
                            }
                            .pickerStyle(.segmented)
                            
                            Picker("Priority", selection: $notifPriority) {
                                Text("CRITICAL - High Priority").tag("CRITICAL - Highest Priority")
                                Text("HIGH - Urgent Alert").tag("HIGH - Urgent Alert")
                                Text("MEDIUM - Information").tag("MEDIUM - Information")
                            }
                            .frame(width: 200)
                        }
                        
                        // If "Custom Regions" is selected: show multi-select search and dropdown
                        if notifTargetScope == "Custom Regions" {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 10) {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundColor(.secondary)
                                    TextField("Search district or state to notify (e.g. Wayanad, Pune, Chamoli, Patna)...", text: $notifGeoSearchText)
                                        .textFieldStyle(.plain)
                                        .font(.body)
                                    if !notifGeoSearchText.isEmpty {
                                        Button {
                                            notifGeoSearchText = ""
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.secondary)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(10)
                                .background(Color(NSColor.controlBackgroundColor))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 1))
                                
                                if !notifGeoSearchText.isEmpty {
                                    VStack(alignment: .leading, spacing: 4) {
                                        if notifFilteredGeoSearchResults.isEmpty {
                                            Text("No matching Indian districts found for '\(notifGeoSearchText)'")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                                .padding(6)
                                        } else {
                                            ForEach(notifFilteredGeoSearchResults.prefix(6), id: \.district) { res in
                                                let isAdded = stagedNotifRegions.contains(where: { $0.district == res.district && $0.state == res.state })
                                                Button {
                                                    if !isAdded {
                                                        stagedNotifRegions.append(SelectedGeoRegion(state: res.state, district: res.district))
                                                    }
                                                    notifGeoSearchText = ""
                                                } label: {
                                                    HStack {
                                                        Image(systemName: isAdded ? "checkmark.circle.fill" : "plus.circle.fill")
                                                            .foregroundColor(isAdded ? .green : .blue)
                                                        Text(res.district)
                                                            .font(.subheadline.bold())
                                                        Text("(\(res.state))")
                                                            .font(.caption)
                                                            .foregroundColor(.secondary)
                                                        Spacer()
                                                        Text(isAdded ? "Added" : "+ Add to Recipients")
                                                            .font(.caption.bold())
                                                            .foregroundColor(isAdded ? .green : .blue)
                                                    }
                                                    .padding(8)
                                                    .background(Color.white.opacity(0.04))
                                                    .cornerRadius(6)
                                                }
                                                .buttonStyle(.plain)
                                                .disabled(isAdded)
                                            }
                                        }
                                    }
                                    .padding(6)
                                    .background(Color.black.opacity(0.4))
                                    .cornerRadius(8)
                                } else {
                                    HStack(spacing: 12) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("State / UT").font(.caption.bold()).foregroundColor(.secondary)
                                            Picker("", selection: $notifPickerSelectedState) {
                                                Text("Select State / UT...").tag("")
                                                ForEach(IndiaGeoData.states) { stateObj in
                                                    Text(stateObj.stateName).tag(stateObj.stateName)
                                                }
                                            }
                                            .labelsHidden()
                                            .onChange(of: notifPickerSelectedState) { _, _ in
                                                notifPickerSelectedDistrict = ""
                                            }
                                        }
                                        .frame(maxWidth: .infinity)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("District").font(.caption.bold()).foregroundColor(.secondary)
                                            let currentDistricts = IndiaGeoData.states.first(where: { $0.stateName == notifPickerSelectedState })?.districts ?? []
                                            Picker("", selection: $notifPickerSelectedDistrict) {
                                                Text(notifPickerSelectedState.isEmpty ? "Select State First..." : "Select District...").tag("")
                                                ForEach(currentDistricts, id: \.self) { dist in
                                                    Text(dist).tag(dist)
                                                }
                                            }
                                            .labelsHidden()
                                            .disabled(notifPickerSelectedState.isEmpty)
                                        }
                                        .frame(maxWidth: .infinity)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(" ").font(.caption)
                                            Button {
                                                guard !notifPickerSelectedState.isEmpty && !notifPickerSelectedDistrict.isEmpty else { return }
                                                let newReg = SelectedGeoRegion(state: notifPickerSelectedState, district: notifPickerSelectedDistrict)
                                                if !stagedNotifRegions.contains(newReg) {
                                                    stagedNotifRegions.append(newReg)
                                                }
                                            } label: {
                                                HStack(spacing: 4) {
                                                    Image(systemName: "plus")
                                                    Text("Add Region")
                                                        .fontWeight(.bold)
                                                }
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 7)
                                            }
                                            .buttonStyle(.borderedProminent)
                                            .tint(.blue)
                                            .disabled(notifPickerSelectedState.isEmpty || notifPickerSelectedDistrict.isEmpty)
                                        }
                                    }
                                }
                                
                                // Custom chips
                                if !stagedNotifRegions.isEmpty {
                                    FlowLayout(spacing: 8) {
                                        ForEach(stagedNotifRegions) { region in
                                            HStack(spacing: 6) {
                                                Image(systemName: "bell.badge.fill")
                                                    .foregroundColor(.blue)
                                                Text(region.displayName)
                                                    .font(.subheadline.bold())
                                                Button {
                                                    stagedNotifRegions.removeAll(where: { $0.id == region.id })
                                                } label: {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .foregroundColor(.secondary)
                                                }
                                                .buttonStyle(.plain)
                                            }
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(Color.blue.opacity(0.15))
                                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                            .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Color.blue.opacity(0.4), lineWidth: 1))
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Active Target Preview Badge
                        HStack(spacing: 8) {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(.blue)
                            Text("Notification Delivery Target:")
                                .font(.subheadline.bold())
                                .foregroundColor(.secondary)
                            Text(notifTargetSummaryString)
                                .font(.subheadline.bold())
                                .foregroundColor(.blue)
                                .lineLimit(2)
                            Spacer()
                        }
                        .padding(10)
                        .background(Color.blue.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    
                    // Title & Message
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Notification Title").font(.subheadline.bold())
                        TextField("Enter push notification title...", text: $notifTitle)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Notification Body / Message").font(.subheadline.bold())
                        TextEditor(text: $notifMessage)
                            .font(.system(size: 13))
                            .frame(height: 65)
                            .padding(6)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 1))
                    }
                    
                    // Action Button
                    HStack(spacing: 16) {
                        Button {
                            var targetList: [String] = []
                            switch notifTargetScope {
                            case "Active Emergency Zones":
                                targetList = activeAlerts.map { $0.targetDistrict }
                            case "Custom Regions":
                                targetList = stagedNotifRegions.map { $0.displayName }
                            case "Pan-India":
                                targetList = ["Pan-India"]
                            case "Active Mesh Nodes":
                                targetList = ["Active Field Nodes"]
                            default:
                                targetList = [notifTargetScope]
                            }
                            
                            store.sendAreaPushNotification(
                                title: notifTitle,
                                message: notifMessage,
                                priority: notifPriority,
                                targetAreas: targetList
                            )
                            withAnimation {
                                showNotifToast = "📨 Push Notification dispatched to [\(notifTargetSummaryString)]!"
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "paperplane.fill")
                                Text("SEND PUSH NOTIFICATION")
                                    .fontWeight(.bold)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                        .controlSize(.large)
                    }
                    
                    if let notifToast = showNotifToast {
                        HStack(spacing: 8) {
                            Image(systemName: "paperplane.circle.fill")
                                .foregroundColor(.blue)
                            Text(notifToast)
                                .font(.subheadline.bold())
                                .foregroundColor(.blue)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.blue.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .transition(.opacity)
                    }
                }
                .padding(18)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor).opacity(0.6))
    }
}

// MARK: - Flow Layout for multi-region chips
public struct FlowLayout: Layout {
    public var spacing: CGFloat = 8
    
    public init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }
    
    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 500
        var height: CGFloat = 0
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var maxHeightInRow: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > width && currentX > 0 {
                currentX = 0
                currentY += maxHeightInRow + spacing
                maxHeightInRow = 0
            }
            currentX += size.width + spacing
            maxHeightInRow = max(maxHeightInRow, size.height)
            height = max(height, currentY + maxHeightInRow)
        }
        return CGSize(width: width, height: max(height, maxHeightInRow))
    }
    
    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var maxHeightInRow: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX && currentX > bounds.minX {
                currentX = bounds.minX
                currentY += maxHeightInRow + spacing
                maxHeightInRow = 0
            }
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: ProposedViewSize(size))
            currentX += size.width + spacing
            maxHeightInRow = max(maxHeightInRow, size.height)
        }
    }
}

// MARK: - Quick Scenario Preset Button
public struct ScenarioPresetButton: View {
    public let title: String
    public let color: Color
    public let action: () -> Void
    
    public init(title: String, color: Color, action: @escaping () -> Void) {
        self.title = title
        self.color = color
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .padding(.horizontal, 6)
                .background(color.opacity(0.15))
                .foregroundColor(color)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(color.opacity(0.35), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
