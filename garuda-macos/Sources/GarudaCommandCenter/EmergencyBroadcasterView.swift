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
    @State private var alertMessage: String = "NDMA DIRECTIVE: Rapidly rising flood waters. Evacuate low-lying areas immediately. Keep Bluetooth Mesh enabled."
    @State private var geoSearchText: String = ""
    @State private var showDeclarationToast: String?
    
    // =========================================================================
    // SECTION 3: Targeted Push Notification States
    // =========================================================================
    @State private var notifTargetScope: String = "Specific District"
    @State private var notifSelectedState: String = "Bihar"
    @State private var notifSelectedDistrict: String = "Jehanabad"
    @State private var notifGeoSearchText: String = ""
    @State private var notifTitle: String = "NDMA Immediate Weather Advisory"
    @State private var notifMessage: String = "Heavy rainfall and flash flood alert for the next 6 hours. Stay tuned to mesh broadcast."
    @State private var notifPriority: String = "HIGH - Urgent Alert"
    @State private var showNotifToast: String?
    
    // Geofence helpers
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
            VStack(alignment: .leading, spacing: 14) {
                // -------------------------------------------------------------
                // COMPACT TOP HEADER
                // -------------------------------------------------------------
                HStack(spacing: 12) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.title2.bold())
                        .foregroundColor(store.isEmergencyBroadcastActive ? .red : .green)
                        .frame(width: 36, height: 36)
                        .background(store.isEmergencyBroadcastActive ? Color.red.opacity(0.15) : Color.green.opacity(0.15))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Government Emergency Command & Broadcast Hub")
                            .font(.headline.bold())
                        Text("NDMA Multi-Region Geofenced Activation & Field Push Grid")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Live Status Badges
                    HStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(store.isEmergencyBroadcastActive ? Color.red : Color.green)
                                .frame(width: 7, height: 7)
                            Text(store.isEmergencyBroadcastActive ? "ACTIVE EMERGENCY" : "SYSTEM STANDBY")
                                .font(.caption2.bold())
                                .foregroundColor(store.isEmergencyBroadcastActive ? .red : .green)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.black.opacity(0.35))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(store.isEmergencyBroadcastActive ? Color.red.opacity(0.4) : Color.green.opacity(0.4), lineWidth: 1))
                        
                        Text("\(activeAlerts.count) Active Zone(s)")
                            .font(.caption2.bold())
                            .foregroundColor(activeAlerts.isEmpty ? .secondary : .orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                
                // -------------------------------------------------------------
                // 2-COLUMN COMPACT & ORGANIZED GRID
                // -------------------------------------------------------------
                HStack(alignment: .top, spacing: 14) {
                    // =========================================================
                    // LEFT COLUMN: DECLARE EMERGENCY (SECTION 1)
                    // =========================================================
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("1. Declare Emergency in Specific Region", systemImage: "exclamationmark.triangle.fill")
                                .font(.subheadline.bold())
                                .foregroundColor(.red)
                            Spacer()
                            Text("Geofenced Activation")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        // Scenario Chips
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                CompactChip(title: "🌊 Flood", color: .blue) {
                                    alertTitle = "Flash Flood & Inundation Evacuation Alert"
                                    severityLevel = "Level 3 - Critical / Red Alert"
                                    alertMessage = "NDMA DIRECTIVE: Rising water levels. Evacuate low-lying zones. Keep BLE Mesh active."
                                }
                                CompactChip(title: "🏔️ Landslide", color: .brown) {
                                    alertTitle = "Massive Landslide & Slope Failure Alert"
                                    severityLevel = "Level 3 - Critical / Red Alert"
                                    alertMessage = "DISASTER DIRECTIVE: Hillside collapse reported. Avoid riverbanks and vulnerable bridges."
                                }
                                CompactChip(title: "🏚️ Quake", color: .orange) {
                                    alertTitle = "Major Earthquake Seismic Warning"
                                    severityLevel = "Level 3 - Critical / Red Alert"
                                    alertMessage = "NDMA ALERT: High-intensity tremors. Move to open grounds away from masonry."
                                }
                                CompactChip(title: "🔥 Fire", color: .red) {
                                    alertTitle = "Severe Fire & Perimeter Hazard Warning"
                                    severityLevel = "Level 2 - High Alert / Orange"
                                    alertMessage = "EVACUATION ORDER: Uncontained fire spreading. Follow designated escape corridors."
                                }
                                CompactChip(title: "🌪️ Cyclone", color: .purple) {
                                    alertTitle = "Severe Cyclone & Gale Warning"
                                    severityLevel = "Level 3 - Critical / Red Alert"
                                    alertMessage = "NDMA ALERT: Extreme storm surge. Take shelter in cyclone centers."
                                }
                            }
                        }
                        
                        Divider()
                        
                        // Search Bar
                        HStack(spacing: 6) {
                            Image(systemName: "magnifyingglass")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("Search Indian district (e.g. Jehanabad, Wayanad, Pune)...", text: $geoSearchText)
                                .textFieldStyle(.plain)
                                .font(.caption)
                            if !geoSearchText.isEmpty {
                                Button {
                                    geoSearchText = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(6)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(6)
                        
                        // Search Results Dropdown
                        if !geoSearchText.isEmpty {
                            VStack(alignment: .leading, spacing: 3) {
                                if filteredGeoSearchResults.isEmpty {
                                    Text("No district matching '\(geoSearchText)'")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .padding(4)
                                } else {
                                    ForEach(filteredGeoSearchResults.prefix(5), id: \.district) { res in
                                        Button {
                                            selectedState = res.state
                                            selectedDistrict = res.district
                                            geoSearchText = ""
                                        } label: {
                                            HStack {
                                                Image(systemName: "mappin.circle.fill")
                                                    .foregroundColor(.red)
                                                    .font(.caption2)
                                                Text(res.district)
                                                    .font(.caption.bold())
                                                Text("(\(res.state))")
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                                Spacer()
                                                Text("Select")
                                                    .font(.caption2.bold())
                                                    .foregroundColor(.blue)
                                            }
                                            .padding(4)
                                            .background(Color.white.opacity(0.04))
                                            .cornerRadius(4)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .padding(4)
                            .background(Color.black.opacity(0.4))
                            .cornerRadius(6)
                        } else {
                            // State & District Dropdowns
                            HStack(spacing: 8) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("State / UT").font(.caption2).foregroundColor(.secondary)
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
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("District").font(.caption2).foregroundColor(.secondary)
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
                                .font(.caption2)
                            Text("Target:")
                                .font(.caption2.bold())
                                .foregroundColor(.secondary)
                            Text(targetedGeofenceString)
                                .font(.caption2.bold())
                                .foregroundColor(.red)
                            Spacer()
                        }
                        .padding(5)
                        .background(Color.red.opacity(0.12))
                        .cornerRadius(6)
                        
                        // Severity & Headline
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Severity").font(.caption2).foregroundColor(.secondary)
                                    Picker("", selection: $severityLevel) {
                                        Text("Level 3 (Red Alert)").tag("Level 3 - Critical / Red Alert")
                                        Text("Level 2 (Orange)").tag("Level 2 - High Alert / Orange")
                                        Text("Level 1 (Yellow)").tag("Level 1 - Watch & Warning / Yellow")
                                    }
                                    .labelsHidden()
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Headline").font(.caption2).foregroundColor(.secondary)
                                    TextField("Alert Headline", text: $alertTitle)
                                        .textFieldStyle(.roundedBorder)
                                        .font(.caption)
                                }
                            }
                        }
                        
                        // Instructions
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Citizen Instructions / Directive").font(.caption2).foregroundColor(.secondary)
                            TextEditor(text: $alertMessage)
                                .font(.system(size: 11))
                                .frame(height: 48)
                                .padding(4)
                                .background(Color(nsColor: .controlBackgroundColor))
                                .cornerRadius(6)
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.12), lineWidth: 1))
                        }
                        
                        // Action Buttons
                        HStack(spacing: 10) {
                            Button {
                                store.broadcastEmergencyActivation(
                                    title: alertTitle,
                                    severity: severityLevel,
                                    district: targetedGeofenceString,
                                    instructions: alertMessage
                                )
                                withAnimation {
                                    showDeclarationToast = "🚨 Emergency Activated in [\(targetedGeofenceString)]!"
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "bolt.fill")
                                    Text("DECLARE IN [\(selectedDistrict)]")
                                        .font(.caption.bold())
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.red)
                            
                            Button {
                                store.broadcastEmergencyDeactivation()
                                withAnimation {
                                    showDeclarationToast = "🛡️ All Emergencies Cleared. System Standby."
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "shield.slash")
                                    Text("Standby / Clear")
                                        .font(.caption.bold())
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        if let toast = showDeclarationToast {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.green)
                                    .font(.caption2)
                                Text(toast)
                                    .font(.caption2.bold())
                                    .foregroundColor(.green)
                            }
                            .padding(6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.green.opacity(0.15))
                            .cornerRadius(6)
                        }
                    }
                    .padding(12)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .frame(maxWidth: .infinity)
                    
                    // =========================================================
                    // RIGHT COLUMN: ACTIVE ZONES (2) + PUSH NOTIFICATIONS (3)
                    // =========================================================
                    VStack(spacing: 12) {
                        // -----------------------------------------------------
                        // SECTION 2: ACTIVE EMERGENCY ZONES
                        // -----------------------------------------------------
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label("2. Active Emergency Zones", systemImage: "map.circle.fill")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.orange)
                                Spacer()
                                Text("\(activeAlerts.count) Active")
                                    .font(.caption2.bold())
                                    .foregroundColor(activeAlerts.isEmpty ? .green : .red)
                            }
                            
                            if activeAlerts.isEmpty {
                                HStack(spacing: 10) {
                                    Image(systemName: "checkmark.shield.fill")
                                        .font(.title3)
                                        .foregroundColor(.green)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("All 28 States & 8 UTs in Standby")
                                            .font(.caption.bold())
                                            .foregroundColor(.green)
                                        Text("No active disaster declarations. Citizen nodes are in low-power standby.")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.green.opacity(0.08))
                                .cornerRadius(8)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.green.opacity(0.2), lineWidth: 1))
                            } else {
                                ForEach(activeAlerts) { alert in
                                    HStack(alignment: .center, spacing: 10) {
                                        Circle()
                                            .fill(Color.red)
                                            .frame(width: 8, height: 8)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            HStack(spacing: 6) {
                                                Text(alert.targetDistrict)
                                                    .font(.caption.bold())
                                                    .foregroundColor(.red)
                                                Text("• \(alert.severity)")
                                                    .font(.caption2)
                                                    .foregroundColor(.orange)
                                                Spacer()
                                                Text(alert.timestamp.formatted(date: .omitted, time: .shortened))
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                            }
                                            Text(alert.title)
                                                .font(.caption2)
                                                .lineLimit(1)
                                        }
                                        
                                        Button {
                                            store.deactivateSpecificAlert(id: alert.id)
                                        } label: {
                                            Text("End")
                                                .font(.caption2.bold())
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(Color.red.opacity(0.15))
                                                .foregroundColor(.red)
                                                .cornerRadius(4)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(8)
                                    .background(Color(nsColor: .controlBackgroundColor))
                                    .cornerRadius(6)
                                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.red.opacity(0.3), lineWidth: 1))
                                }
                            }
                        }
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        
                        // -----------------------------------------------------
                        // SECTION 3: TARGETED PUSH NOTIFICATIONS
                        // -----------------------------------------------------
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Label("3. Dispatch Push Notification", systemImage: "bell.badge.fill")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.blue)
                                Spacer()
                                Text("FCM + BLE Relay")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            // Presets
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    CompactChip(title: "🏃 Evacuation", color: .red) {
                                        notifTitle = "IMMEDIATE EVACUATION DIRECTIVE"
                                        notifMessage = "Move to higher ground or nearest shelter immediately."
                                        notifPriority = "CRITICAL - Highest Priority"
                                    }
                                    CompactChip(title: "⛺ Relief Camp", color: .green) {
                                        notifTitle = "Relief Camp & Potable Water Open"
                                        notifMessage = "Community center relief camp active with food and clean drinking water."
                                        notifPriority = "MEDIUM - Information"
                                    }
                                    CompactChip(title: "🏥 Medical Aid", color: .cyan) {
                                        notifTitle = "Medical Aid Post Active"
                                        notifMessage = "Ambulances and trauma first aid stationed at District Health Camp."
                                        notifPriority = "HIGH - Urgent Alert"
                                    }
                                    CompactChip(title: "⛈️ Weather", color: .orange) {
                                        notifTitle = "Severe Thunderstorm Warning"
                                        notifMessage = "Intense rainfall expected in 2 hours. Avoid open culverts."
                                        notifPriority = "HIGH - Urgent Alert"
                                    }
                                }
                            }
                            
                            // Scope Selection
                            HStack(spacing: 8) {
                                Picker("", selection: $notifTargetScope) {
                                    Text("District").tag("Specific District")
                                    Text("Pan-India").tag("Pan-India")
                                    Text("Active Nodes").tag("Active Mesh Nodes")
                                }
                                .pickerStyle(.segmented)
                                
                                Picker("", selection: $notifPriority) {
                                    Text("CRITICAL").tag("CRITICAL - Highest Priority")
                                    Text("HIGH").tag("HIGH - Urgent Alert")
                                    Text("MEDIUM").tag("MEDIUM - Information")
                                }
                                .labelsHidden()
                                .frame(width: 90)
                            }
                            
                            if notifTargetScope == "Specific District" {
                                HStack(spacing: 6) {
                                    Picker("", selection: $notifSelectedState) {
                                        ForEach(IndiaGeoData.states) { s in
                                            Text(s.stateName).tag(s.stateName)
                                        }
                                    }
                                    .labelsHidden()
                                    .onChange(of: notifSelectedState) { _, newState in
                                        if let firstDist = IndiaGeoData.states.first(where: { $0.stateName == newState })?.districts.first {
                                            notifSelectedDistrict = firstDist
                                        }
                                    }
                                    
                                    let currentDistricts = IndiaGeoData.states.first(where: { $0.stateName == notifSelectedState })?.districts ?? []
                                    Picker("", selection: $notifSelectedDistrict) {
                                        ForEach(currentDistricts, id: \.self) { d in
                                            Text(d).tag(d)
                                        }
                                    }
                                    .labelsHidden()
                                    
                                    Button {
                                        notifSelectedState = selectedState
                                        notifSelectedDistrict = selectedDistrict
                                    } label: {
                                        Image(systemName: "arrow.triangle.2.circlepath")
                                            .font(.caption2)
                                    }
                                    .buttonStyle(.bordered)
                                    .help("Match Section 1 selection")
                                }
                            }
                            
                            // Target Preview
                            HStack(spacing: 4) {
                                Image(systemName: "paperplane.fill")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                                Text("Target:")
                                    .font(.caption2.bold())
                                    .foregroundColor(.secondary)
                                Text(notifTargetedGeofenceString)
                                    .font(.caption2.bold())
                                    .foregroundColor(.blue)
                                Spacer()
                            }
                            .padding(4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(4)
                            
                            // Title & Body
                            TextField("Notification Title", text: $notifTitle)
                                .textFieldStyle(.roundedBorder)
                                .font(.caption)
                            
                            TextField("Notification Body Message", text: $notifMessage)
                                .textFieldStyle(.roundedBorder)
                                .font(.caption)
                            
                            // Send Button
                            Button {
                                let actualTarget = (notifTargetScope == "Specific District") ? notifTargetedGeofenceString : notifTargetScope
                                store.sendAreaPushNotification(
                                    title: notifTitle,
                                    message: notifMessage,
                                    priority: notifPriority,
                                    targetArea: actualTarget
                                )
                                withAnimation {
                                    showNotifToast = "📨 Dispatched to [\(actualTarget)]!"
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "paperplane.fill")
                                    Text("SEND PUSH TO [\(notifTargetScope == "Specific District" ? notifSelectedDistrict : notifTargetedGeofenceString)]")
                                        .font(.caption.bold())
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
                            
                            if let notifToast = showNotifToast {
                                HStack(spacing: 6) {
                                    Image(systemName: "paperplane.circle.fill")
                                        .foregroundColor(.blue)
                                        .font(.caption2)
                                    Text(notifToast)
                                        .font(.caption2.bold())
                                        .foregroundColor(.blue)
                                }
                                .padding(6)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.blue.opacity(0.12))
                                .cornerRadius(6)
                            }
                        }
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(14)
        }
    }
}

// Compact Chip View Component
struct CompactChip: View {
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption2.bold())
                .foregroundColor(color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(color.opacity(0.12))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(color.opacity(0.3), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
