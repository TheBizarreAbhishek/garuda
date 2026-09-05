import SwiftUI

public struct EmergencyDeclarationModalView: View {
    @ObservedObject var store: CommandCenterStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var alertTitle: String = "Flash Flood & Inundation Immediate Evacuation Alert"
    @State private var selectedState: String = "Uttar Pradesh"
    @State private var selectedDistrict: String = "Prayagraj (Allahabad)"
    @State private var severityLevel: String = "Level 3 - Critical / Red Alert"
    @State private var alertMessage: String = "NDMA DIRECTIVE: Imminent flash flood hazard. All citizen apps are now ACTIVATED. Bluetooth Mesh scanning active. Evacuate to nearest high ground or designated relief camp immediately."
    @State private var isShowingGeoPicker: Bool = false
    @State private var geoSearchText: String = ""
    @State private var successToast: String?
    
    public init(store: CommandCenterStore) {
        self.store = store
    }
    
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
        let query = geoSearchText.lowercased()
        
        for stateObj in IndiaGeoData.states {
            for dist in stateObj.districts {
                if dist.lowercased().contains(query) || stateObj.stateName.lowercased().contains(query) {
                    results.append((state: stateObj.stateName, district: dist))
                }
            }
        }
        return results
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(store.isEmergencyBroadcastActive ? Color.red.opacity(0.2) : Color.orange.opacity(0.2))
                        .frame(width: 40, height: 40)
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.title3.bold())
                        .foregroundColor(store.isEmergencyBroadcastActive ? .red : .orange)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Emergency Disaster Broadcast Authority")
                        .font(.headline.bold())
                    Text("Geofenced high-priority activation targeting specific State & District devices")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Scrollable Content
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 16) {
                    // Quick Scenario Presets
                    VStack(alignment: .leading, spacing: 6) {
                        Text("QUICK SCENARIO TEMPLATES")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            PresetChip(title: "🌊 Flash Flood Alert", color: .blue) {
                                alertTitle = "Flash Flood & Inundation Red Alert"
                                severityLevel = "Level 3 - Critical / Red Alert"
                                alertMessage = "NDMA DIRECTIVE: Rapidly rising flood waters. Evacuate low-lying areas immediately. Keep Bluetooth Mesh enabled for beacon relay."
                            }
                            PresetChip(title: "🏔️ Landslide Warning", color: .brown) {
                                alertTitle = "Massive Landslide & Slope Collapse Alert"
                                severityLevel = "Level 3 - Critical / Red Alert"
                                alertMessage = "DISASTER DIRECTIVE: Hillside slope failure reported. Evacuate vulnerable structures. Do not use bridges or riverbank roads."
                            }
                            PresetChip(title: "🏚️ Earthquake Warning", color: .orange) {
                                alertTitle = "Major Earthquake Seismic Warning"
                                severityLevel = "Level 3 - Critical / Red Alert"
                                alertMessage = "NDMA ALERT: High-magnitude seismic shocks. Stay in open areas away from buildings. Emergency services are deploying."
                            }
                            PresetChip(title: "🔥 Industrial Hazard", color: .red) {
                                alertTitle = "Severe Fire & Industrial Hazard Warning"
                                severityLevel = "Level 2 - High Alert / Orange"
                                alertMessage = "EVACUATION ORDER: Industrial perimeter fire hazard. Follow designated escape corridors to safe relief camps."
                            }
                        }
                    }
                    
                    Divider()
                    
                    // State & District Geofence Picker
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("TARGET GEOFENCE (STATE & DISTRICT)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("Only phones in this zone will activate")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.orange)
                        }
                        
                        // Search bar for districts
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            TextField("Search any Indian State or District (e.g. Prayagraj, Wayanad)...", text: $geoSearchText)
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
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                        
                        if !geoSearchText.isEmpty {
                            // Instant search search list
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(filteredGeoSearchResults.prefix(6), id: \.district) { res in
                                    Button {
                                        selectedState = res.state
                                        selectedDistrict = res.district
                                        geoSearchText = ""
                                    } label: {
                                        HStack {
                                            Image(systemName: "mappin.and.ellipse")
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
                            .padding(6)
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(8)
                        } else {
                            // Hierarchical State -> District Two-Picker Grid
                            HStack(spacing: 12) {
                                // 1. State Selector
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Select State / Region").font(.caption2.bold()).foregroundColor(.secondary)
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
                                
                                // 2. District Selector
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Select Targeted District").font(.caption2.bold()).foregroundColor(.secondary)
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
                        
                        // Active Target Badge
                        HStack(spacing: 6) {
                            Image(systemName: "target")
                                .foregroundColor(.red)
                            Text("Active Geofence Target:")
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
                    
                    // Form Details
                    VStack(alignment: .leading, spacing: 12) {
                        // Severity Level
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Severity Level")
                                .font(.caption.bold())
                            
                            Picker("", selection: $severityLevel) {
                                Text("Level 3 - Critical / Red Alert (Immediate Evacuation)").tag("Level 3 - Critical / Red Alert")
                                Text("Level 2 - High Alert / Orange (Preparedness)").tag("Level 2 - High Alert / Orange")
                                Text("Level 1 - Watch & Warning / Yellow").tag("Level 1 - Watch / Yellow")
                            }
                            .labelsHidden()
                        }
                        
                        // Headline
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Emergency Headline / Title")
                                .font(.caption.bold())
                            TextField("Enter emergency headline", text: $alertTitle)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        // Directives & Instructions
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Citizen Evacuation Instructions & Directives")
                                .font(.caption.bold())
                            TextEditor(text: $alertMessage)
                                .font(.system(size: 12))
                                .frame(height: 60)
                                .padding(6)
                                .background(Color(NSColor.controlBackgroundColor))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                )
                        }
                    }
                    
                    if let success = successToast {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.green)
                            Text(success)
                                .font(.caption.bold())
                                .foregroundColor(.green)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.green.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
                .padding(20)
            }
            
            Divider()
            
            // Action Buttons Footer
            HStack(spacing: 12) {
                Button {
                    store.broadcastEmergencyDeactivation()
                    successToast = "Emergency Deactivated. All devices returned to Standby mode."
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        dismiss()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "shield.slash")
                        Text("Standby / Cancel")
                            .font(.system(size: 11, weight: .medium))
                    }
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button {
                    store.broadcastEmergencyActivation(
                        title: alertTitle,
                        severity: severityLevel,
                        district: targetedGeofenceString,
                        instructions: alertMessage
                    )
                    successToast = "🚨 EMERGENCY ACTIVATION TRANSMITTED to [\(targetedGeofenceString)]!"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismiss()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.fill")
                        Text("TRANSMIT EMERGENCY TO TARGETED ZONE")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .padding(.horizontal, 8)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 580, height: 620)
    }
}

struct PresetChip: View {
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(1)
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(color.opacity(0.35), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
