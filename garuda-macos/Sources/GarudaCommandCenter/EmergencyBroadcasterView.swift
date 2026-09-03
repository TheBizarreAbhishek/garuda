import SwiftUI

public struct EmergencyBroadcasterView: View {
    @ObservedObject var store: CommandCenterStore
    
    @State private var alertTitle: String = "Flash Flood & Landslide Immediate Evacuation Alert"
    @State private var selectedDistrict: String = "Wayanad / Calicut (Kerala)"
    @State private var severityLevel: String = "Level 3 - Critical / Red Alert"
    @State private var alertMessage: String = "NDMA DIRECTIVE: Imminent flash flood hazard. All citizen apps are now ACTIVATED. Bluetooth Mesh scanning active. Evacuate to nearest high ground or designated relief camp immediately."
    @State private var showConfirmationToast: Bool = false
    
    let districts = [
        "Wayanad / Calicut (Kerala)",
        "Idukki / Munnar (Kerala)",
        "Chamoli / Joshimath (Uttarakhand)",
        "Coastal Odisha / Puri",
        "Assam / Brahmaputra Basin",
        "National Emergency (All Districts)"
    ]
    
    let severities = [
        "Level 3 - Critical / Red Alert",
        "Level 2 - High Alert / Orange",
        "Level 1 - Watch & Warning / Yellow"
    ]
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header Banner
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Government Emergency Broadcast & Citizen Activation")
                            .font(.title2.bold())
                        Text("Broadcast high-priority disaster activation orders via Firebase Cloud Messaging (FCM) to immediately unlock Android devices in the targeted zone.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "antenna.radiowaves.left.and.right.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.red)
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Form Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Broadcast Parameters")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Target Disaster District / Geofence").font(.caption.bold())
                        Picker("", selection: $selectedDistrict) {
                            ForEach(districts, id: \.self) { district in
                                Text(district).tag(district)
                            }
                        }
                        .labelsHidden()
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Disaster Severity Level").font(.caption.bold())
                        Picker("", selection: $severityLevel) {
                            ForEach(severities, id: \.self) { level in
                                Text(level).tag(level)
                            }
                        }
                        .labelsHidden()
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Emergency Headline / Title").font(.caption.bold())
                        TextField("Enter headline", text: $alertTitle)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Citizen Instructions & Evacuation Directive").font(.caption.bold())
                        TextEditor(text: $alertMessage)
                            .font(.body)
                            .frame(height: 100)
                            .padding(4)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.3), lineWidth: 1))
                    }
                    
                    HStack {
                        Button {
                            store.broadcastEmergencyActivation(
                                title: alertTitle,
                                severity: severityLevel,
                                district: selectedDistrict,
                                instructions: alertMessage
                            )
                            withAnimation {
                                showConfirmationToast = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                withAnimation {
                                    showConfirmationToast = false
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "bolt.badge.automatic.fill")
                                Text("TRANSMIT EMERGENCY ACTIVATION & PUSH ALERTS")
                                    .fontWeight(.bold)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .controlSize(.large)
                        
                        if showConfirmationToast {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Broadcast Transmitted & FCM Push Dispatched!")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.green)
                            }
                            .padding(.leading, 12)
                            .transition(.opacity)
                        }
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Past Broadcasts Log
                VStack(alignment: .leading, spacing: 12) {
                    Text("Active Disaster Declarations")
                        .font(.headline)
                    
                    ForEach(store.alerts) { alert in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "exclamationmark.octagon.fill")
                                .font(.title3)
                                .foregroundColor(.red)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(alert.title).font(.subheadline.bold())
                                    Spacer()
                                    Text(alert.timestamp.formatted(date: .omitted, time: .shortened))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Text("Target: \(alert.targetDistrict) • \(alert.severity)")
                                    .font(.caption)
                                    .foregroundColor(.red)
                                Text(alert.instructions)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(10)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(16)
        }
    }
}
