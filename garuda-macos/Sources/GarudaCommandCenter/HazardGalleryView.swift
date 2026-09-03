import SwiftUI

public struct HazardGalleryView: View {
    @ObservedObject var store: CommandCenterStore
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Citizen Hazard & Infrastructure Damage Reports")
                            .font(.title2.bold())
                        Text("Crowdsourced geo-tagged damage reports submitted offline via BLE mesh and uploaded upon gateway sync.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), spacing: 16)], spacing: 16) {
                    ForEach(store.hazards) { hazard in
                        HazardCard(hazard: hazard)
                    }
                }
            }
            .padding(16)
        }
    }
}

struct HazardCard: View {
    let hazard: HazardReport
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                Rectangle()
                    .fill(Color.black.opacity(0.8))
                    .frame(height: 130)
                
                VStack(spacing: 6) {
                    Image(systemName: "photo.badge.exclamationmark.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.yellow)
                    Text("Geo-Tagged Damage Capture")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(hazard.category)
                        .font(.caption.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.yellow.opacity(0.2))
                        .foregroundColor(.yellow)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    
                    Spacer()
                    
                    if hazard.isVerified {
                        Label("NDRF Verified", systemImage: "checkmark.seal.fill")
                            .font(.caption2.bold())
                            .foregroundColor(.green)
                    }
                }
                
                Text(hazard.title)
                    .font(.headline)
                
                Text(hazard.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Divider()
                
                HStack {
                    Text("Reported by \(hazard.reporterName)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Lat: \(String(format: "%.4f", hazard.latitude)), Lon: \(String(format: "%.4f", hazard.longitude))")
                        .font(.caption2.monospaced())
                        .foregroundColor(.secondary)
                }
            }
            .padding(10)
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }
}
