import SwiftUI

public struct EmergencyBroadcasterView: View {
    @ObservedObject var store: CommandCenterStore
    
    // =========================================================================
    // SECTION 1: Emergency Declaration States
    // =========================================================================
    @State private var alertTitle: String = "Flash Flood & Inundation Immediate Evacuation Alert"
    @State private var selectedState: String = "Bihar"
    @State private var selectedDistrict: String = "Jehanabad"
    @State private var severityLevel: String = "Level 3 - Critical / Red Alert"
    @State private var alertMessage: String = "NDMA DIRECTIVE: Rapidly rising flood waters. Evacuate low-lying areas immediately. Keep Bluetooth Mesh enabled for beacon relay."
    @State private var geoSearchText: String = ""
    @State private var showDeclarationToast: String?
    
    // =========================================================================
    // SECTION 3: Targeted Push Notification States
    // =========================================================================
    @State private var notifTargetScope: String = "Specific District" // "Specific District", "Pan-India", "Active Mesh Nodes"
    @State private var notifSelectedState: String = "Bihar"
    @State private var notifSelectedDistrict: String = "Jehanabad"
    @State private var notifGeoSearchText: String = ""
    @State private var notifTitle: String = "NDMA Immediate Weather Advisory"
    @State private var notifMessage: String = "Heavy rainfall and flash flood alert issued for the next 6 hours. Stay tuned to mesh broadcast."
    @State private var notifPriority: String = "HIGH - Urgent Alert"
    @State private var showNotifToast: String?
    
    // Helpers for Section 1
    private var targetedGeofenceString: String {
        if selectedState == "National / Pan-India" {
            return selectedDistrict
        } else {
            return "\(selectedDistrict), \(selectedState)"
        }
    }
    
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
    
    // Helpers for Section 3
    private var notifTargetedGeofenceString: String {
        switch notifTargetScope {
        case "Pan-India":
            return "Pan-India (All Registered Nodes)"
        case "Active Mesh Nodes":
            return "All Connected Online Field Nodes"
        default:
            if notifSelectedState == "National / Pan-India" {
                return notifSelectedDistrict
            } else {
                return "\(notifSelectedDistrict), \(notifSelectedState)"
            }
        }
    }
    
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
    
    private var activeAlerts: [DisasterAlert] {
        store.alerts.filter { $0.isEmergencyActive }
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header Banner
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(store.isEmergencyBroadcastActive ? Color.red.opacity(0.2) : Color.green.opacity(0.2))
                            .frame(width: 48, height: 48)
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.title2.bold())
                            .foregroundColor(store.isEmergencyBroadcastActive ? .red : .green)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Government Emergency Command & Broadcast Hub")
                            .font(.title2.bold())
                        Text("National Disaster Management Authority (NDMA) Unified Multi-Region Broadcast Grid")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    
                    // Live Status Pill
                    HStack(spacing: 8) {
                        Circle()
                            .fill(store.isEmergencyBroadcastActive ? Color.red : Color.green)
                            .frame(width: 9, height: 9)
                        Text(store.isEmergencyBroadcastActive 
                             ? "\(activeAlerts.count) ACTIVE EMERGENCY ZONE(S)" 
                             : "SYSTEM STANDBY")
                            .font(.caption.bold())
                            .foregroundColor(store.isEmergencyBroadcastActive ? .red : .green)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.35))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(store.isEmergencyBroadcastActive ? Color.red.opacity(0.4) : Color.green.opacity(0.4), lineWidth: 1))
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                
                // =========================================================================
                // SECTION 1: EMERGENCY DECLARATION & ACTIVATION (SPECIFIC REGION)
                // =========================================================================
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Label("1. Declare Emergency in Specific Region", systemImage: "exclamationmark.triangle.fill")
                            .font(.title3.bold())
                            .foregroundColor(.red)
                        Spacer()
                        Text("Geofenced Disaster Activation")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                    }
                    
                    // Quick Disaster Scenario Templates
                    VStack(alignment: .leading, spacing: 6) {
                        Text("QUICK SCENARIO TEMPLATES")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            PresetChip(title: "🌊 Flash Flood", color: .blue) {
                                alertTitle = "Flash Flood & Inundation Immediate Evacuation Alert"
                                severityLevel = "Level 3 - Critical / Red Alert"
                                alertMessage = "NDMA DIRECTIVE: Rapidly rising flood waters. Evacuate low-lying areas immediately. Keep Bluetooth Mesh enabled for beacon relay."
                            }
                            PresetChip(title: "🏔️ Landslide", color: .brown) {
                                alertTitle = "Massive Landslide & Slope Collapse Alert"
                                severityLevel = "Level 3 - Critical / Red Alert"
                                alertMessage = "DISASTER DIRECTIVE: Hillside slope failure reported. Evacuate vulnerable structures. Do not use bridges or riverbank roads."
                            }
                            PresetChip(title: "🏚️ Earthquake", color: .orange) {
                                alertTitle = "Major Earthquake Seismic Warning"
                                severityLevel = "Level 3 - Critical / Red Alert"
                                alertMessage = "NDMA ALERT: High-magnitude seismic shocks. Stay in open areas away from buildings. Emergency rescue teams deploying."
                            }
                            PresetChip(title: "🔥 Fire Hazard", color: .red) {
                                alertTitle = "Severe Industrial & Forest Fire Warning"
                                severityLevel = "Level 2 - High Alert / Orange"
                                alertMessage = "EVACUATION ORDER: Severe fire perimeter spreading. Follow designated escape corridors to safe relief camps."
                            }
                            PresetChip(title: "🌪️ Cyclone / Storm", color: .purple) {
                                alertTitle = "Severe Tropical Cyclone & Gale Wind Alert"
                                severityLevel = "Level 3 - Critical / Red Alert"
                                alertMessage = "NDMA WARNING: Extreme wind speeds and storm surge. Seek refuge in pucca cyclone shelters immediately."
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Target Geofence Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("SELECT TARGET STATE & DISTRICT")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        // Universal Search Bar
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            TextField("Search any Indian State or District (e.g. Jehanabad, Wayanad, Pune, Chamoli)...", text: $geoSearchText)
                                .textFieldStyle(.plain)
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
                        .padding(8)
                        .background(Color(NSColor.controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 1))
                        
                        // Search Results Dropdown
                        if !geoSearchText.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                if filteredGeoSearchResults.isEmpty {
                                    Text("No matching Indian districts found for '\(geoSearchText)'")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(8)
                                } else {
                                    ForEach(filteredGeoSearchResults.prefix(8), id: \.district) { res in
                                        Button {
                                            selectedState = res.state
                                            selectedDistrict = res.district
                                            geoSearchText = ""
                                        } label: {
                                            HStack {
                                                Image(systemName: "mappin.circle.fill")
                                                    .foregroundColor(.red)
                                                Text(res.district)
                                                    .font(.system(size: 12, weight: .bold))
                                                Text("(\(res.state))")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                Spacer()
                                                Text("Select")
                                                    .font(.caption2.bold())
                                                    .foregroundColor(.blue)
                                            }
                                            .padding(6)
                                            .background(Color.white.opacity(0.04))
                                            .cornerRadius(6)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .padding(6)
                            .background(Color.black.opacity(0.4))
                            .cornerRadius(8)
                        } else {
                            HStack(spacing: 12) {
                                // State Dropdown
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("1. State / Union Territory").font(.caption2.bold()).foregroundColor(.secondary)
                                    Picker("", selection: $selectedState) {
                                        ForEach(IndiaGeoData.states) { stateObj in
                                            Text(stateObj.stateName).tag(stateObj.stateName)
                                        }
                                    }
                                    .labelsHidden()
                                    .onChange(of: selectedState) { _, newState in
                                        if let firstDist = IndiaGeoData.states.first(where: { $0.stateName == newState })?.districts.first {
                                            selectedDistrict = firstDist
                                        }
                                    }
                                }
                                
                                // District Dropdown
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("2. Targeted District").font(.caption2.bold()).foregroundColor(.secondary)
                                    let currentDistricts = IndiaGeoData.states.first(where: { $0.stateName == selectedState })?.districts ?? []
                                    Picker("", selection: $selectedDistrict) {
                                        ForEach(currentDistricts, id: \.self) { dist in
                                            Text(dist).tag(dist)
                                        }
                                    }
                                    .labelsHidden()
                                }
                            }
                        }
                        
                        // Active Target Preview Badge
                        HStack(spacing: 6) {
                            Image(systemName: "target")
                                .foregroundColor(.red)
                            Text("Selected Activation Geofence:")
                                .font(.caption.bold())
                                .foregroundColor(.secondary)
                            Text(targetedGeofenceString)
                                .font(.caption.bold())
                                .foregroundColor(.red)
                            Spacer()
                        }
                        .padding(8)
                        .background(Color.red.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }
                    
                    Divider()
                    
                    // Severity & Headline
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Disaster Severity Level").font(.caption.bold())
                            Picker("", selection: $severityLevel) {
                                Text("Level 3 - Critical / Red Alert (Immediate Evacuation)").tag("Level 3 - Critical / Red Alert")
                                Text("Level 2 - High Alert / Orange (Preparedness)").tag("Level 2 - High Alert / Orange")
                                Text("Level 1 - Watch & Warning / Yellow").tag("Level 1 - Watch & Warning / Yellow")
                            }
                            .labelsHidden()
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Emergency Headline").font(.caption.bold())
                            TextField("Enter alert title", text: $alertTitle)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    
                    // Directive
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Citizen Instructions & Evacuation Directive").font(.caption.bold())
                        TextEditor(text: $alertMessage)
                            .font(.system(size: 12))
                            .frame(height: 70)
                            .padding(6)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 1))
                    }
                    
                    // Section 1 Action Buttons
                    HStack(spacing: 14) {
                        Button {
                            store.broadcastEmergencyActivation(
                                title: alertTitle,
                                severity: severityLevel,
                                district: targetedGeofenceString,
                                instructions: alertMessage
                            )
                            withAnimation {
                                showDeclarationToast = "🚨 Emergency Broadcast Activated in [\(targetedGeofenceString)]!"
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "bolt.fill")
                                Text("DECLARE EMERGENCY IN [\(selectedDistrict)]")
                                    .fontWeight(.bold)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .controlSize(.large)
                        
                        Button {
                            store.broadcastEmergencyDeactivation()
                            withAnimation {
                                showDeclarationToast = "🛡️ All Active Emergencies Revoked. System is in Standby."
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "shield.slash")
                                Text("Deactivate All / System Standby")
                                    .fontWeight(.medium)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
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
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                
                // =========================================================================
                // SECTION 2: ACTIVE EMERGENCY ZONES (KAHA KAHA EMERGENCY ACTIVE HAI)
                // =========================================================================
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Label("2. Active Emergency Zones", systemImage: "map.circle.fill")
                            .font(.title3.bold())
                            .foregroundColor(.orange)
                        
                        Spacer()
                        
                        Text("\(activeAlerts.count) Area(s) Currently Active")
                            .font(.caption.bold())
                            .foregroundColor(activeAlerts.isEmpty ? .secondary : .red)
                    }
                    
                    if activeAlerts.isEmpty {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.shield.fill")
                                .font(.title2)
                                .foregroundColor(.green)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("All 28 States & 8 UTs in Normal Standby")
                                    .font(.headline)
                                    .foregroundColor(.green)
                                Text("No active disaster emergency declarations currently in force. Citizen nodes remain in ultra-low-power standby mode.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.green.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color.green.opacity(0.25), lineWidth: 1))
                    } else {
                        ForEach(activeAlerts) { alert in
                            HStack(alignment: .top, spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(Color.red.opacity(0.2))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: "exclamationmark.octagon.fill")
                                        .font(.headline)
                                        .foregroundColor(.red)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(alert.targetDistrict)
                                            .font(.headline.bold())
                                            .foregroundColor(.red)
                                        
                                        Text("• \(alert.severity)")
                                            .font(.caption.bold())
                                            .foregroundColor(.orange)
                                        
                                        Spacer()
                                        
                                        Text(alert.timestamp.formatted(date: .omitted, time: .shortened))
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Text(alert.title)
                                        .font(.subheadline.weight(.semibold))
                                    
                                    Text(alert.instructions)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                                
                                Spacer()
                                
                                // Direct Deactivate / End Emergency Button per District
                                Button {
                                    store.deactivateSpecificAlert(id: alert.id)
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "xmark.circle")
                                        Text("End Emergency")
                                            .font(.caption.bold())
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.red.opacity(0.15))
                                    .foregroundColor(.red)
                                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                                }
                                .buttonStyle(.plain)
                                .help("Revoke emergency status for this district and return to standby")
                            }
                            .padding(14)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color.red.opacity(0.3), lineWidth: 1))
                        }
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                
                // =========================================================================
                // SECTION 3: TARGETED PUSH NOTIFICATION (SPECIFIC AREA MEIN BHEJNA)
                // =========================================================================
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Label("3. Dispatch Push Notification to Specific Area", systemImage: "bell.badge.fill")
                            .font(.title3.bold())
                            .foregroundColor(.blue)
                        Spacer()
                        Text("Firebase FCM + Mesh Uplink")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                    }
                    
                    // Quick Notification Presets
                    VStack(alignment: .leading, spacing: 6) {
                        Text("QUICK NOTIFICATION TEMPLATES")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            PresetChip(title: "🏃 Evacuation Order", color: .red) {
                                notifTitle = "IMMEDIATE EVACUATION DIRECTIVE"
                                notifMessage = "Move to higher ground or nearest designated shelter immediately. Emergency rescue in progress."
                                notifPriority = "CRITICAL - Highest Priority"
                            }
                            PresetChip(title: "⛺ Food & Relief Camp", color: .green) {
                                notifTitle = "Relief Camp & Potable Water Distribution Open"
                                notifMessage = "Community hall relief camp active with food, dry rations, and clean drinking water."
                                notifPriority = "MEDIUM - Information"
                            }
                            PresetChip(title: "🏥 Medical Aid Center", color: .cyan) {
                                notifTitle = "Emergency Medical & First Aid Post Established"
                                notifMessage = "Medical teams and ambulances stationed at District Health Camp with trauma and first aid supplies."
                                notifPriority = "HIGH - Urgent Alert"
                            }
                            PresetChip(title: "⛈️ Weather Warning", color: .orange) {
                                notifTitle = "Severe Thunderstorm & Rainfall Warning"
                                notifMessage = "Intense spells of rain expected in the next 3 hours. Avoid flood-prone culverts and loose power lines."
                                notifPriority = "HIGH - Urgent Alert"
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Target Scope Selection
                    VStack(alignment: .leading, spacing: 10) {
                        Text("TARGET RECIPIENT REGION / AREA").font(.system(size: 10, weight: .bold)).foregroundColor(.secondary)
                        
                        HStack(spacing: 12) {
                            Picker("Scope", selection: $notifTargetScope) {
                                Text("📍 Specific District / City").tag("Specific District")
                                Text("🇮🇳 Pan-India (All Registered Nodes)").tag("Pan-India")
                                Text("🌐 All Currently Connected Online Field Nodes").tag("Active Mesh Nodes")
                            }
                            .pickerStyle(.segmented)
                            
                            Picker("Priority", selection: $notifPriority) {
                                Text("CRITICAL - High Priority").tag("CRITICAL - Highest Priority")
                                Text("HIGH - Urgent Alert").tag("HIGH - Urgent Alert")
                                Text("MEDIUM - Information").tag("MEDIUM - Information")
                            }
                            .frame(width: 180)
                        }
                        
                        // IF "Specific District" is chosen, show State + District Pickers + Search Box
                        if notifTargetScope == "Specific District" {
                            VStack(alignment: .leading, spacing: 8) {
                                // Notification Area Search Bar
                                HStack(spacing: 8) {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundColor(.secondary)
                                    TextField("Search district to notify (e.g. Jehanabad, Patna, Wayanad, Pune)...", text: $notifGeoSearchText)
                                        .textFieldStyle(.plain)
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
                                .padding(8)
                                .background(Color(NSColor.controlBackgroundColor))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 1))
                                
                                if !notifGeoSearchText.isEmpty {
                                    VStack(alignment: .leading, spacing: 4) {
                                        if notifFilteredGeoSearchResults.isEmpty {
                                            Text("No matching Indian districts found for '\(notifGeoSearchText)'")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .padding(6)
                                        } else {
                                            ForEach(notifFilteredGeoSearchResults.prefix(6), id: \.district) { res in
                                                Button {
                                                    notifSelectedState = res.state
                                                    notifSelectedDistrict = res.district
                                                    notifGeoSearchText = ""
                                                } label: {
                                                    HStack {
                                                        Image(systemName: "bell.badge.fill")
                                                            .foregroundColor(.blue)
                                                        Text(res.district)
                                                            .font(.system(size: 12, weight: .bold))
                                                        Text("(\(res.state))")
                                                            .font(.caption)
                                                            .foregroundColor(.secondary)
                                                        Spacer()
                                                        Text("Select")
                                                            .font(.caption2.bold())
                                                            .foregroundColor(.blue)
                                                    }
                                                    .padding(6)
                                                    .background(Color.white.opacity(0.04))
                                                    .cornerRadius(6)
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                    }
                                    .padding(6)
                                    .background(Color.black.opacity(0.4))
                                    .cornerRadius(8)
                                } else {
                                    HStack(spacing: 12) {
                                        // State Dropdown
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("State / Region").font(.caption2.bold()).foregroundColor(.secondary)
                                            Picker("", selection: $notifSelectedState) {
                                                ForEach(IndiaGeoData.states) { stateObj in
                                                    Text(stateObj.stateName).tag(stateObj.stateName)
                                                }
                                            }
                                            .labelsHidden()
                                            .onChange(of: notifSelectedState) { _, newState in
                                                if let firstDist = IndiaGeoData.states.first(where: { $0.stateName == newState })?.districts.first {
                                                    notifSelectedDistrict = firstDist
                                                }
                                            }
                                        }
                                        
                                        // District Dropdown
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Specific Targeted District").font(.caption2.bold()).foregroundColor(.secondary)
                                            let currentDistricts = IndiaGeoData.states.first(where: { $0.stateName == notifSelectedState })?.districts ?? []
                                            Picker("", selection: $notifSelectedDistrict) {
                                                ForEach(currentDistricts, id: \.self) { dist in
                                                    Text(dist).tag(dist)
                                                }
                                            }
                                            .labelsHidden()
                                        }
                                        
                                        // Quick Match Section 1 Button
                                        Button {
                                            notifSelectedState = selectedState
                                            notifSelectedDistrict = selectedDistrict
                                        } label: {
                                            HStack(spacing: 4) {
                                                Image(systemName: "arrow.triangle.2.circlepath")
                                                Text("Match Section 1")
                                                    .font(.caption2.bold())
                                            }
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 6)
                                        }
                                        .buttonStyle(.bordered)
                                        .help("Copy current geofence from Section 1")
                                    }
                                }
                            }
                        }
                        
                        // Active Target Preview Badge
                        HStack(spacing: 6) {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(.blue)
                            Text("Notification Delivery Target:")
                                .font(.caption.bold())
                                .foregroundColor(.secondary)
                            Text(notifTargetedGeofenceString)
                                .font(.caption.bold())
                                .foregroundColor(.blue)
                            Spacer()
                        }
                        .padding(8)
                        .background(Color.blue.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }
                    
                    // Notification Headline & Message
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Notification Title").font(.caption.bold())
                        TextField("Enter push notification title...", text: $notifTitle)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Notification Body / Message").font(.caption.bold())
                        TextEditor(text: $notifMessage)
                            .font(.system(size: 12))
                            .frame(height: 60)
                            .padding(6)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 1))
                    }
                    
                    // Action Button
                    HStack(spacing: 14) {
                        Button {
                            store.sendAreaPushNotification(
                                title: notifTitle,
                                message: notifMessage,
                                priority: notifPriority,
                                targetArea: notifTargetedGeofenceString
                            )
                            withAnimation {
                                showNotifToast = "📨 Push Notification successfully dispatched to [\(notifTargetedGeofenceString)]!"
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "paperplane.fill")
                                Text("SEND PUSH NOTIFICATION TO [\(notifTargetScope == "Specific District" ? notifSelectedDistrict : notifTargetedGeofenceString)]")
                                    .fontWeight(.bold)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
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
                    
                    // Recent Dispatched Push Notifications Log
                    if !store.notifications.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("RECENT DISPATCHED PUSH NOTIFICATIONS")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.secondary)
                            
                            ForEach(store.notifications.prefix(4)) { notif in
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: "bell.fill")
                                        .foregroundColor(.blue)
                                        .font(.caption)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack {
                                            Text(notif.title).font(.caption.bold())
                                            Spacer()
                                            Text(notif.timestamp.formatted(date: .omitted, time: .shortened))
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                        Text("Target: \(notif.targetArea) • Priority: \(notif.priority)")
                                            .font(.caption2)
                                            .foregroundColor(.blue)
                                        Text(notif.message)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(8)
                                .background(Color.black.opacity(0.2))
                                .cornerRadius(6)
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .padding(16)
        }
    }
}
