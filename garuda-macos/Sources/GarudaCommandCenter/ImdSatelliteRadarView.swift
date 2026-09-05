import SwiftUI
import AppKit

public struct ImdSatelliteRadarView: View {
    @ObservedObject var store: CommandCenterStore
    @State private var selectedChannelId: String = "IR1"
    @State private var lastRefreshed: Date = Date()
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    struct SatelliteChannel: Identifiable {
        let id: String
        let title: String
        let subtitle: String
        let band: String
        let resolution: String
        let sensor: String
        let description: String
        let url: URL
        let icon: String
        let wavelength: String
    }
    
    private var channels: [SatelliteChannel] {
        [
            SatelliteChannel(
                id: "IR1",
                title: "Sector Infrared (IR1)",
                subtitle: "Thermal Cloud Tops & Cyclone Eye Tracking",
                band: "TIR-1 Thermal Infrared",
                resolution: "4.0 km GSD (Spatial)",
                sensor: "6-Channel Optical Imager",
                description: "Detects thermal radiation emitted by cloud tops and land surfaces. Essential for night-and-day tracking of tropical depressions, severe cyclones, and convective thunderstorm cells across the Indian subcontinent.",
                url: URL(string: "https://mausam.imd.gov.in/Satellite/3Dasiasec_ir1.jpg")!,
                icon: "waveform.path.badge.plus",
                wavelength: "10.3 - 11.3 µm"
            ),
            SatelliteChannel(
                id: "CTBT",
                title: "Cloud Top Brightness Temp (CTBT)",
                subtitle: "Calibrated Storm Intensity Matrix",
                band: "Color-Enhanced Thermal Matrix",
                resolution: "4.0 km Calibrated Radiometry",
                sensor: "19-Channel Atmospheric Sounder",
                description: "Color-coded thermal brightness map showing cloud-top heights. Violet/Dark Red zones indicate intense high-altitude cumulonimbus storm clouds capable of cloudbursts and torrential flooding.",
                url: URL(string: "https://mausam.imd.gov.in/Satellite/3Dasiasec_ctbt.jpg")!,
                icon: "thermometer.sun.fill",
                wavelength: "Color Coded (-80°C to +30°C)"
            ),
            SatelliteChannel(
                id: "VIS",
                title: "Visible Spectrum (VIS)",
                subtitle: "Daylight Optical Cloud & River Basin Feed",
                band: "Optical Solar Reflected",
                resolution: "1.0 km Ultra-High Resolution",
                sensor: "High-Resolution Visible Detector",
                description: "Captures reflected daylight from clouds, snow cover, and river basin terrain. Provides the sharpest 1km resolution visual evidence of flooding, storm rotation, and smoke plumes during daytime.",
                url: URL(string: "https://mausam.imd.gov.in/Satellite/3Dasiasec_vis.jpg")!,
                icon: "sun.max.fill",
                wavelength: "0.55 - 0.75 µm"
            ),
            SatelliteChannel(
                id: "WV",
                title: "Water Vapor Channel (WV)",
                subtitle: "Tropospheric Moisture Flux & Jet Streams",
                band: "Mid-Tropospheric Water Vapor",
                resolution: "8.0 km Upper-Air Matrix",
                sensor: "Infrared Atmospheric Imager",
                description: "Tracks moisture transport in the middle and upper troposphere (400–600 hPa). Crucial for forecasting monsoon troughs, heavy precipitation inflow, and atmospheric wind shear.",
                url: URL(string: "https://mausam.imd.gov.in/Satellite/3Dasiasec_wv.jpg")!,
                icon: "drop.fill",
                wavelength: "6.5 - 7.1 µm"
            ),
            SatelliteChannel(
                id: "GLOBE",
                title: "Full Disk Indian Ocean (GLOBE)",
                subtitle: "Synoptic Basin-Wide Maritime Surveillance",
                band: "Full Earth Geostationary Disk",
                resolution: "4.0 km Synoptic",
                sensor: "Full Earth Disc Imager (74.0°E)",
                description: "Complete full-disk observation of the Indian Ocean, Bay of Bengal, Arabian Sea, and Southern Maritime boundary from INSAT-3DS orbital slot at 74°E longitude.",
                url: URL(string: "https://mausam.imd.gov.in/Satellite/3Dglobe_ir1.jpg")!,
                icon: "globe.asia.australia.fill",
                wavelength: "10.8 µm Multi-Band"
            )
        ]
    }
    
    private var currentChannel: SatelliteChannel {
        channels.first(where: { $0.id == selectedChannelId }) ?? channels[0]
    }
    
    public init(store: CommandCenterStore) {
        self.store = store
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // 1. Top Defense Header Bar
            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "satellite.fill")
                        .font(.title2.bold())
                        .foregroundColor(.cyan)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("ISRO INSAT-3DS / 3DR SATELLITE RADAR")
                                .font(.system(size: 14, weight: .black, design: .monospaced))
                                .foregroundColor(.white)
                            
                            HStack(spacing: 4) {
                                Circle().fill(Color.green).frame(width: 6, height: 6)
                                Text("LIVE FEED")
                                    .font(.system(size: 8, weight: .black, design: .monospaced))
                                    .foregroundColor(.green)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.15))
                            .clipShape(Capsule())
                        }
                        
                        Text("Ministry of Earth Sciences (MoES) • India Meteorological Department (IMD) Ground Station")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Telemetry Badges
                HStack(spacing: 12) {
                    HStack(spacing: 6) {
                        Image(systemName: "location.north.circle.fill")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("ORBITAL SLOT")
                                .font(.system(size: 7, weight: .black, design: .monospaced))
                                .foregroundColor(.secondary)
                            Text("74.0°E GEO")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(.primary)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    
                    HStack(spacing: 6) {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundColor(.green)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("UPDATE CYCLE")
                                .font(.system(size: 7, weight: .black, design: .monospaced))
                                .foregroundColor(.secondary)
                            Text("15 Minutes")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(.primary)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    
                    Button {
                        lastRefreshed = Date()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise")
                            Text("Refresh")
                        }
                        .font(.system(size: 11, weight: .semibold))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.cyan)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // 2. Main Content Split: Left Satellite Viewer + Right Channel Selector
            HStack(spacing: 0) {
                // Left: High-Res Imagery Canvas (Full Box Utilization & Trackpad Navigation)
                VStack(spacing: 0) {
                    ZStack {
                        Color.black
                        
                        NativeSatelliteCanvasView(
                            url: currentChannel.url,
                            currentScale: $scale,
                            refreshTrigger: lastRefreshed
                        )
                        .clipped()
                        
                        // Overlay HUD Badges (Top Left & Top Right)
                        VStack {
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("INSAT-3DS • \(currentChannel.id)")
                                        .font(.system(size: 11, weight: .black, design: .monospaced))
                                        .foregroundColor(.cyan)
                                    Text(currentChannel.wavelength)
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.cyan.opacity(0.4), lineWidth: 1))
                                
                                Spacer()
                                
                                // Interactive Zoom & Navigation Controller Bar
                                HStack(spacing: 8) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "hand.draw")
                                            .font(.system(size: 10))
                                            .foregroundColor(.cyan)
                                        Text("2-Finger Pan / Pinch")
                                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Color.black.opacity(0.4))
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                                    
                                    Divider().frame(height: 14)
                                    
                                    Button {
                                        scale = max(0.5, scale - 0.35)
                                    } label: {
                                        Image(systemName: "minus.magnifyingglass")
                                    }
                                    .buttonStyle(.plain)
                                    
                                    Button {
                                        scale = 1.0
                                    } label: {
                                        Text("\(Int(scale * 100))%")
                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                            .foregroundColor(.cyan)
                                    }
                                    .buttonStyle(.plain)
                                    
                                    Button {
                                        scale = min(5.0, scale + 0.35)
                                    } label: {
                                        Image(systemName: "plus.magnifyingglass")
                                    }
                                    .buttonStyle(.plain)
                                    
                                    Button {
                                        scale = 1.0
                                    } label: {
                                        Text("Fit")
                                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                                            .foregroundColor(.white)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .font(.system(size: 12, weight: .bold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Color.white.opacity(0.18), lineWidth: 1))
                            }
                            .padding(14)
                            
                            Spacer()
                        }
                    }
                    
                    // Bottom Metadata Banner
                    HStack(spacing: 20) {
                        Label(currentChannel.band, systemImage: "wave.3.forward")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(.cyan)
                        
                        Label(currentChannel.resolution, systemImage: "square.dashed")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(.secondary)
                        
                        Label(currentChannel.sensor, systemImage: "camera.sensor.fill")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("Ground Telemetry: Synchronized with MCF Bhopal")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(NSColor.windowBackgroundColor))
                }
                
                Divider()
                
                // Right Side: Channel Controls & Descriptions
                VStack(alignment: .leading, spacing: 14) {
                    Text("SPECTRAL PRODUCTS")
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .foregroundColor(.secondary)
                    
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(channels) { ch in
                                Button {
                                    selectedChannelId = ch.id
                                    scale = 1.0
                                } label: {
                                    HStack(spacing: 12) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                .fill(selectedChannelId == ch.id ? Color.cyan.opacity(0.25) : Color.white.opacity(0.06))
                                                .frame(width: 36, height: 36)
                                            Image(systemName: ch.icon)
                                                .font(.system(size: 15, weight: .bold))
                                                .foregroundColor(selectedChannelId == ch.id ? .cyan : .secondary)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(ch.title)
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(selectedChannelId == ch.id ? .white : .primary)
                                            Text(ch.subtitle)
                                                .font(.system(size: 10))
                                                .foregroundColor(.secondary)
                                                .lineLimit(1)
                                        }
                                        
                                        Spacer()
                                        
                                        if selectedChannelId == ch.id {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.cyan)
                                        }
                                    }
                                    .padding(10)
                                    .background(selectedChannelId == ch.id ? Color.cyan.opacity(0.12) : Color.white.opacity(0.03))
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .stroke(selectedChannelId == ch.id ? Color.cyan.opacity(0.4) : Color.white.opacity(0.06), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Selected Product Scientific Profile
                    VStack(alignment: .leading, spacing: 8) {
                        Text("TACTICAL INTERPRETATION")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundColor(.cyan)
                        
                        Text(currentChannel.description)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineSpacing(3)
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    
                    // Open in Browser Button
                    Link(destination: currentChannel.url) {
                        HStack {
                            Image(systemName: "arrow.up.right.square")
                            Text("Open Full-Res Stream on IMD Portal")
                        }
                        .font(.system(size: 11, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
                .frame(width: 340)
                .background(Color(NSColor.windowBackgroundColor))
            }
        }
    }
}

// MARK: - Native AppKit Pan & Zoom High-Performance Satellite Canvas
public struct NativeSatelliteCanvasView: NSViewRepresentable {
    let url: URL
    @Binding var currentScale: CGFloat
    let refreshTrigger: Date
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasHorizontalScroller = false
        scrollView.hasVerticalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.allowsMagnification = true
        scrollView.minMagnification = 0.5
        scrollView.maxMagnification = 6.0
        scrollView.drawsBackground = true
        scrollView.backgroundColor = .black
        scrollView.automaticallyAdjustsContentInsets = false
        
        let imageView = CenteredImageView()
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.animates = false
        
        scrollView.documentView = imageView
        
        // Listen to magnification changes to sync with HUD
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.magnificationDidChange(_:)),
            name: NSScrollView.didEndLiveMagnifyNotification,
            object: scrollView
        )
        
        context.coordinator.scrollView = scrollView
        context.coordinator.imageView = imageView
        context.coordinator.loadImage(from: url)
        
        return scrollView
    }
    
    public func updateNSView(_ scrollView: NSScrollView, context: Context) {
        if context.coordinator.currentUrl != url || context.coordinator.lastRefresh != refreshTrigger {
            context.coordinator.currentUrl = url
            context.coordinator.lastRefresh = refreshTrigger
            context.coordinator.loadImage(from: url)
        }
        
        // Programmatic zoom from HUD buttons
        if abs(scrollView.magnification - currentScale) > 0.05 && currentScale >= 0.5 {
            scrollView.setMagnification(currentScale, centeredAt: NSPoint(x: scrollView.bounds.midX, y: scrollView.bounds.midY))
        }
    }
    
    @MainActor
    public class Coordinator: NSObject {
        var parent: NativeSatelliteCanvasView
        weak var scrollView: NSScrollView?
        weak var imageView: CenteredImageView?
        var currentUrl: URL?
        var lastRefresh: Date = Date()
        
        init(_ parent: NativeSatelliteCanvasView) {
            self.parent = parent
        }
        
        @objc func magnificationDidChange(_ notification: Notification) {
            guard let sv = scrollView else { return }
            self.parent.currentScale = sv.magnification
        }
        
        func loadImage(from url: URL) {
            Task {
                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    if let image = NSImage(data: data) {
                        self.imageView?.image = image
                        if let sv = self.scrollView {
                            let svSize = sv.bounds.size
                            let imgSize = image.size
                            if imgSize.width > 0 && imgSize.height > 0 {
                                let widthRatio = svSize.width / imgSize.width
                                let heightRatio = svSize.height / imgSize.height
                                let fitRatio = max(widthRatio, heightRatio)
                                
                                // Scale document view to fill container box
                                self.imageView?.frame = NSRect(
                                    x: 0,
                                    y: 0,
                                    width: max(svSize.width, imgSize.width * fitRatio),
                                    height: max(svSize.height, imgSize.height * fitRatio)
                                )
                            }
                        }
                    }
                } catch {
                    // Silently ignore network retry
                }
            }
        }
    }
}

public class CenteredImageView: NSImageView {
    public override func scrollWheel(with event: NSEvent) {
        // Forward scroll wheel directly to parent NSScrollView for buttery-smooth 2-finger panning
        self.enclosingScrollView?.scrollWheel(with: event)
    }
}

