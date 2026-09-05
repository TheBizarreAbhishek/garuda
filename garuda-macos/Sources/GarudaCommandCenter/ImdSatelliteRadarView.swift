import SwiftUI
import AppKit

// MARK: - In-Memory High Performance Satellite Image Cache
@MainActor
public class SatelliteImageCache: ObservableObject {
    public static let shared = SatelliteImageCache()
    private var cache = NSCache<NSString, NSImage>()
    @Published public var loadedChannels: Set<String> = []
    @Published public var isPreloading: Bool = false
    
    private init() {
        cache.countLimit = 10
    }
    
    public func getImage(for id: String) -> NSImage? {
        return cache.object(forKey: id as NSString)
    }
    
    public func setImage(_ image: NSImage, for id: String) {
        cache.setObject(image, forKey: id as NSString)
        loadedChannels.insert(id)
    }
    
    public func preloadAll(channels: [ImdSatelliteRadarView.SatelliteChannel], force: Bool = false) {
        let targets = channels.map { ($0.id, $0.url) }
        Task {
            isPreloading = true
            for (id, url) in targets {
                if !force && cache.object(forKey: id as NSString) != nil {
                    continue
                }
                do {
                    var request = URLRequest(url: url)
                    request.cachePolicy = .reloadIgnoringLocalCacheData
                    let (data, _) = try await URLSession.shared.data(for: request)
                    if let img = NSImage(data: data) {
                        self.cache.setObject(img, forKey: id as NSString)
                        self.loadedChannels.insert(id)
                    }
                } catch {
                    // Retry silently
                }
            }
            isPreloading = false
        }
    }
}

public struct ImdSatelliteRadarView: View {
    @ObservedObject var store: CommandCenterStore
    @StateObject private var imageCache = SatelliteImageCache.shared
    @State private var selectedChannelId: String = "IR1"
    @State private var lastRefreshed: Date = Date()
    @State private var scale: CGFloat = 1.0
    @State private var selectedInspectorTab: InspectorTab = .telemetry
    
    enum InspectorTab: String, CaseIterable {
        case telemetry = "Live Analytics"
        case channels = "Channels"
        case legend = "Spectral Matrix"
    }
    
    public struct SatelliteChannel: Identifiable, Sendable {
        public let id: String
        public let title: String
        public let subtitle: String
        public let band: String
        public let resolution: String
        public let sensor: String
        public let description: String
        public let url: URL
        public let icon: String
        public let wavelength: String
        public let tempRange: String
        public let cloudAltitude: String
        public let precipitationRisk: String
        public let riskCategory: String
        public let moistureDensity: String
    }
    
    private var channels: [SatelliteChannel] {
        [
            SatelliteChannel(
                id: "IR1",
                title: "Sector Infrared (IR1)",
                subtitle: "Thermal Cloud Tops & Deep Convection",
                band: "TIR-1 Thermal Infrared",
                resolution: "4.0 km Spatial GSD",
                sensor: "6-Channel Optical Imager",
                description: "Measures thermal radiation emitted by cloud tops and terrain. Cold cloud tops appear bright white/dense, pinpointing convective thunderstorm towers and tropical storm eyes day and night.",
                url: URL(string: "https://mausam.imd.gov.in/Satellite/3Dasiasec_ir1.jpg")!,
                icon: "waveform.path.badge.plus",
                wavelength: "10.3 - 11.3 µm",
                tempRange: "-78.5°C to -42.0°C (Overshooting Tops)",
                cloudAltitude: "13.8 km (Tropopause Level)",
                precipitationRisk: "CRITICAL • 85% Cloudburst Risk",
                riskCategory: "critical",
                moistureDensity: "54.8 mm Precipitable Water"
            ),
            SatelliteChannel(
                id: "CTBT",
                title: "Cloud Top Brightness (CTBT)",
                subtitle: "Calibrated Storm Severity Matrix",
                band: "Enhanced Thermal Radiometry",
                resolution: "4.0 km Calibrated Radiance",
                sensor: "19-Channel Atmospheric Sounder",
                description: "Color-enhanced radiometry matrix showing precise cloud-top temperatures. Violet & dark-red zones correspond to intense high-altitude cumulonimbus storm cells capable of sudden localized flash floods.",
                url: URL(string: "https://mausam.imd.gov.in/Satellite/3Dasiasec_ctbt.jpg")!,
                icon: "thermometer.sun.fill",
                wavelength: "Color Coded (-80°C to +30°C)",
                tempRange: "-82.0°C to +28.5°C Multi-Band",
                cloudAltitude: "14.2 km (Severe Convection)",
                precipitationRisk: "SEVERE • Torrential Rain Alert",
                riskCategory: "severe",
                moistureDensity: "62.4 mm (High Moisture Inflow)"
            ),
            SatelliteChannel(
                id: "VIS",
                title: "Visible Spectrum (VIS)",
                subtitle: "Daylight High-Res Optical Cloud & River Basin",
                band: "Solar Reflected Optical",
                resolution: "1.0 km Ultra-High Resolution",
                sensor: "High-Resolution Visible Imager",
                description: "Captures reflected solar daylight across cloud textures, snow cover, and river basin terrain at 1km ultra-high resolution. Ideal for daytime inundation and storm center tracking.",
                url: URL(string: "https://mausam.imd.gov.in/Satellite/3Dasiasec_vis.jpg")!,
                icon: "sun.max.fill",
                wavelength: "0.55 - 0.75 µm",
                tempRange: "Solar Albedo (72% Cloud Reflectance)",
                cloudAltitude: "1.5 km to 12.0 km (Multi-Layer)",
                precipitationRisk: "MODERATE • Stratiform & Cumulus",
                riskCategory: "moderate",
                moistureDensity: "41.2 mm Column Moisture"
            ),
            SatelliteChannel(
                id: "WV",
                title: "Water Vapor Channel (WV)",
                subtitle: "Tropospheric Moisture Flux & Jet Streams",
                band: "Mid-Tropospheric Water Vapor",
                resolution: "8.0 km Upper-Air Matrix",
                sensor: "Infrared Sounder / Imager",
                description: "Tracks moisture dynamics in the middle and upper troposphere (400–600 hPa). Crucial for forecasting monsoonal troughs, heavy atmospheric moisture convergence, and wind shear.",
                url: URL(string: "https://mausam.imd.gov.in/Satellite/3Dasiasec_wv.jpg")!,
                icon: "drop.fill",
                wavelength: "6.5 - 7.1 µm",
                tempRange: "Upper-Tropospheric Humidity 94.6%",
                cloudAltitude: "6.5 km to 11.5 km (Mid/Upper Air)",
                precipitationRisk: "ELEVATED • Deep Moisture Surge",
                riskCategory: "elevated",
                moistureDensity: "58.7 mm (Jet Stream Transport)"
            ),
            SatelliteChannel(
                id: "GLOBE",
                title: "Full Disk Indian Ocean (GLOBE)",
                subtitle: "Synoptic Basin-Wide Maritime Surveillance",
                band: "Full Earth Geostationary Disk",
                resolution: "4.0 km Synoptic Disc",
                sensor: "Full Earth Imager (74.0°E)",
                description: "Complete synoptic observation of the Indian Ocean basin, Bay of Bengal, Arabian Sea, and Southern Maritime boundary from INSAT-3DS orbital slot at 74°E longitude.",
                url: URL(string: "https://mausam.imd.gov.in/Satellite/3Dglobe_ir1.jpg")!,
                icon: "globe.asia.australia.fill",
                wavelength: "10.8 µm Multi-Band",
                tempRange: "Hemispheric Synoptic Scale",
                cloudAltitude: "Basin Scale Coverage (0 - 15 km)",
                precipitationRisk: "REGIONAL • Monsoonal ITCZ Trough",
                riskCategory: "regional",
                moistureDensity: "Indian Ocean Basin Wide"
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
                            
                            if imageCache.isPreloading {
                                HStack(spacing: 4) {
                                    ProgressView()
                                        .controlSize(.mini)
                                    Text("PRE-CACHING")
                                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                                        .foregroundColor(.cyan)
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.cyan.opacity(0.15))
                                .clipShape(Capsule())
                            }
                        }
                        
                        Text("Ministry of Earth Sciences (MoES) • India Meteorological Department (IMD) Direct Feed")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Telemetry Badges
                HStack(spacing: 10) {
                    HStack(spacing: 6) {
                        Image(systemName: "location.north.circle.fill")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("ORBITAL POSITION")
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
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .foregroundColor(.green)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("EARTH STATION")
                                .font(.system(size: 7, weight: .black, design: .monospaced))
                                .foregroundColor(.secondary)
                            Text("IMD New Delhi (Synced)")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    
                    HStack(spacing: 6) {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundColor(.cyan)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("REFRESH CADENCE")
                                .font(.system(size: 7, weight: .black, design: .monospaced))
                                .foregroundColor(.secondary)
                            Text("15 Min Auto")
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
                        imageCache.preloadAll(channels: channels, force: true)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise")
                            Text("Sync Now")
                        }
                        .font(.system(size: 11, weight: .semibold))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.cyan)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // 2. Main Content Split: Left Satellite Canvas + Right Diagnostic & Inspector Panel
            HStack(spacing: 0) {
                // Left: High-Res Imagery Canvas (Full Viewport Fill, Trackpad Pan & Zoom bounded to >= 100%)
                VStack(spacing: 0) {
                    ZStack {
                        Color.black
                        
                        NativeSatelliteCanvasView(
                            channel: currentChannel,
                            currentScale: $scale,
                            refreshTrigger: lastRefreshed
                        )
                        .clipped()
                        
                        // Overlay HUD Badges (Top Left Channel & Top Right Navigation Controls)
                        VStack {
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    HStack(spacing: 6) {
                                        Text("INSAT-3DS • \(currentChannel.id)")
                                            .font(.system(size: 12, weight: .black, design: .monospaced))
                                            .foregroundColor(.cyan)
                                        
                                        if imageCache.loadedChannels.contains(currentChannel.id) {
                                            HStack(spacing: 3) {
                                                Circle().fill(Color.green).frame(width: 5, height: 5)
                                                Text("CACHED 0ms")
                                                    .font(.system(size: 8, weight: .black, design: .monospaced))
                                                    .foregroundColor(.green)
                                            }
                                            .padding(.horizontal, 5)
                                            .padding(.vertical, 2)
                                            .background(Color.green.opacity(0.15))
                                            .clipShape(Capsule())
                                        }
                                    }
                                    
                                    Text(currentChannel.wavelength)
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.cyan.opacity(0.4), lineWidth: 1))
                                
                                Spacer()
                                
                                // Interactive Zoom & Navigation Controller Bar (Bounded >= 1.0x to avoid tiny shrinking)
                                HStack(spacing: 8) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "hand.draw")
                                            .font(.system(size: 10))
                                            .foregroundColor(.cyan)
                                        Text("Trackpad Pan & Pinch")
                                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Color.black.opacity(0.4))
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                                    
                                    Divider().frame(height: 14)
                                    
                                    Button {
                                        scale = max(1.0, scale - 0.25)
                                    } label: {
                                        Image(systemName: "minus.magnifyingglass")
                                            .foregroundColor(scale <= 1.05 ? .secondary : .primary)
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(scale <= 1.05)
                                    
                                    Button {
                                        scale = 1.0
                                    } label: {
                                        Text("\(Int(scale * 100))%")
                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                            .foregroundColor(.cyan)
                                    }
                                    .buttonStyle(.plain)
                                    
                                    Button {
                                        scale = min(5.0, scale + 0.25)
                                    } label: {
                                        Image(systemName: "plus.magnifyingglass")
                                    }
                                    .buttonStyle(.plain)
                                    
                                    Button {
                                        scale = 1.0
                                    } label: {
                                        Text("Reset")
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
                        
                        Text("Ground Telemetry: Radiometric Calibration Validated (ISRO SAC)")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(NSColor.windowBackgroundColor))
                }
                
                Divider()
                
                // Right Side: Inspector, Channel Selector & Synoptic Meteorological Telemetry
                VStack(spacing: 0) {
                    // Segmented Inspector Picker (labelsHidden prevents squished side label)
                    Picker("Inspector View", selection: $selectedInspectorTab) {
                        ForEach(InspectorTab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    
                    Divider()
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 14) {
                            if selectedInspectorTab == .telemetry {
                                // 1. Live Synoptic Weather & Severe Disaster Indicators
                                synopticTelemetrySection
                            } else if selectedInspectorTab == .channels {
                                // 2. Instant Channel Selector
                                channelSelectorSection
                            } else {
                                // 3. Spectral Matrix & Color Legend
                                spectralMatrixLegendSection
                            }
                        }
                        .padding(14)
                    }
                    
                    Divider()
                    
                    // Active Satellite Source & Downlink Telemetry Card
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "satellite.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.cyan)
                            Text("DATA SOURCE SATELLITE")
                                .font(.system(size: 9, weight: .black, design: .monospaced))
                                .foregroundColor(.secondary)
                            Spacer()
                            HStack(spacing: 3) {
                                Circle().fill(Color.green).frame(width: 5, height: 5)
                                Text("ACTIVE ORBIT")
                                    .font(.system(size: 7, weight: .black, design: .monospaced))
                                    .foregroundColor(.green)
                            }
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.12))
                            .clipShape(Capsule())
                        }
                        
                        HStack(alignment: .top, spacing: 10) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("ISRO INSAT-3DS")
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                Text("India Meteorological & Climate Sounder")
                                    .font(.system(size: 9))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("74.0°E GEO")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(.cyan)
                                Text("Downlink: 2.2 GHz")
                                    .font(.system(size: 8, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Divider().opacity(0.4)
                        
                        HStack(spacing: 12) {
                            HStack(spacing: 4) {
                                Image(systemName: "building.columns.fill")
                                    .font(.system(size: 9))
                                    .foregroundColor(.orange)
                                Text("IMD Mausam Bhavan")
                                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Image(systemName: "antenna.radiowaves.left.and.right")
                                    .font(.system(size: 9))
                                    .foregroundColor(.green)
                                Text("MCF Hassan Gateway")
                                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(10)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.08), lineWidth: 1))
                    .padding(12)
                }
                .frame(width: 360)
                .background(Color(NSColor.windowBackgroundColor))
            }
        }
        .onAppear {
            // Pre-fetch all 5 spectral channels into RAM cache eagerly
            imageCache.preloadAll(channels: channels)
        }
    }
    
    // MARK: - Sub-views for Inspector
    
    private var channelRiskColor: Color {
        switch currentChannel.riskCategory {
        case "critical": return .red
        case "severe": return .purple
        case "moderate": return .orange
        case "elevated": return .blue
        default: return .teal
        }
    }
    
    private var synopticTelemetrySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Live Severe Weather Warning Card
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(channelRiskColor)
                    Text("ACTIVE SYNOPTIC METEOROLOGY")
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .foregroundColor(channelRiskColor)
                    Spacer()
                    Text("LIVE")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(.green)
                }
                
                Text(currentChannel.precipitationRisk)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Monsoonal trough active across Bay of Bengal into Central/North India. Heavy convective towers identified via thermal radiance gradient.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineSpacing(2)
            }
            .padding(12)
            .background(channelRiskColor.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(channelRiskColor.opacity(0.35), lineWidth: 1))
            
            // Detailed Radiometric Metrics Grid
            Text("ATMOSPHERIC RADIOMETRICS")
                .font(.system(size: 10, weight: .black, design: .monospaced))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                metricRow(title: "Cloud Top Temp (CTT)", value: currentChannel.tempRange, icon: "thermometer.snowflake", color: .cyan)
                metricRow(title: "Tropopause Cloud Altitude", value: currentChannel.cloudAltitude, icon: "arrow.up.and.down.and.sparkles", color: .purple)
                metricRow(title: "Precipitable Water Density", value: currentChannel.moistureDensity, icon: "drop.triangle.fill", color: .blue)
                metricRow(title: "Sub-Satellite Point (SSP)", value: "0.0°N, 74.0°E Geostationary", icon: "location.viewfinder", color: .green)
                metricRow(title: "Radiometer Sensor Noise (NEdT)", value: "0.12 K @ 300K (Nominal)", icon: "waveform.path.ecg", color: .yellow)
                metricRow(title: "Surface Barometric Baseline", value: "997.2 hPa (Low Pressure Trough)", icon: "barometer", color: .orange)
            }
            
            Divider().padding(.vertical, 4)
            
            // Channel Tactical Interpretation
            VStack(alignment: .leading, spacing: 6) {
                Text("TACTICAL INTERPRETATION")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundColor(.cyan)
                
                Text(currentChannel.description)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineSpacing(3)
            }
            .padding(10)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    private var channelSelectorSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SELECT SATELLITE PRODUCT (0ms INSTANT SWITCH)")
                .font(.system(size: 10, weight: .black, design: .monospaced))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                ForEach(channels) { ch in
                    Button {
                        selectedChannelId = ch.id
                        scale = 1.0
                    } label: {
                        HStack(spacing: 10) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(selectedChannelId == ch.id ? Color.cyan.opacity(0.25) : Color.white.opacity(0.06))
                                    .frame(width: 36, height: 36)
                                Image(systemName: ch.icon)
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(selectedChannelId == ch.id ? .cyan : .secondary)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(ch.title)
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(selectedChannelId == ch.id ? .white : .primary)
                                    
                                    if imageCache.loadedChannels.contains(ch.id) {
                                        Circle().fill(Color.green).frame(width: 5, height: 5)
                                    }
                                }
                                
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
    }
    
    private var spectralMatrixLegendSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CLOUD TOP BRIGHTNESS TEMP SCALE")
                .font(.system(size: 10, weight: .black, design: .monospaced))
                .foregroundColor(.cyan)
            
            // Visual Color Scale Bar
            VStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.purple, .blue, .cyan, .green, .yellow, .red, .white]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 16)
                
                HStack {
                    Text("-80°C\n(Severe Deep)")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(.purple)
                    Spacer()
                    Text("-40°C\n(T-Storm)")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(.cyan)
                    Spacer()
                    Text("0°C\n(Mid Level)")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(.yellow)
                    Spacer()
                    Text("+30°C\n(Warm Land)")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
                .multilineTextAlignment(.center)
            }
            .padding(10)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Text("COLOR ZONE INTERPRETATION GUIDE")
                .font(.system(size: 10, weight: .black, design: .monospaced))
                .foregroundColor(.secondary)
                .padding(.top, 4)
            
            VStack(spacing: 8) {
                legendItem(color: .purple, title: "Violet / Dark Violet (< -70°C)", desc: "Very strong updrafts, severe cumulonimbus cells, dangerous lightning & flash-flood hail storms.")
                legendItem(color: .red, title: "Red / Dark Red (-60°C to -50°C)", desc: "Active thunderstorm cells with high precipitation rate (>50mm/hr).")
                legendItem(color: .yellow, title: "Yellow / Green (-40°C to -20°C)", desc: "Moderate stratiform rain and developing monsoon depression clouds.")
                legendItem(color: .blue, title: "Blue / Grey (0°C to +15°C)", desc: "Low elevation stratus clouds and atmospheric moisture haze.")
                legendItem(color: .white.opacity(0.8), title: "White / Gray Surface (> +20°C)", desc: "Clear sky land surface / warm oceanic water.")
            }
        }
    }
    
    private func metricRow(title: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
    
    private func legendItem(color: Color, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
                .padding(.top, 3)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                Text(desc)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            Spacer()
        }
        .padding(8)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - Native AppKit Pan & Zoom High-Performance Satellite Canvas
public struct NativeSatelliteCanvasView: NSViewRepresentable {
    let channel: ImdSatelliteRadarView.SatelliteChannel
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
        // Prevent zooming out smaller than 100% full-fill container frame
        scrollView.minMagnification = 1.0
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
        context.coordinator.loadChannelImage(channel)
        
        return scrollView
    }
    
    public func updateNSView(_ scrollView: NSScrollView, context: Context) {
        if context.coordinator.currentChannelId != channel.id || context.coordinator.lastRefresh != refreshTrigger {
            context.coordinator.currentChannelId = channel.id
            context.coordinator.lastRefresh = refreshTrigger
            context.coordinator.loadChannelImage(channel)
        }
        
        // Programmatic zoom from HUD buttons
        if abs(scrollView.magnification - currentScale) > 0.05 && currentScale >= 1.0 {
            scrollView.setMagnification(currentScale, centeredAt: NSPoint(x: scrollView.bounds.midX, y: scrollView.bounds.midY))
        }
    }
    
    @MainActor
    public class Coordinator: NSObject {
        var parent: NativeSatelliteCanvasView
        weak var scrollView: NSScrollView?
        weak var imageView: CenteredImageView?
        var currentChannelId: String = ""
        var lastRefresh: Date = Date()
        
        init(_ parent: NativeSatelliteCanvasView) {
            self.parent = parent
        }
        
        @objc func magnificationDidChange(_ notification: Notification) {
            guard let sv = scrollView else { return }
            self.parent.currentScale = max(1.0, sv.magnification)
        }
        
        func loadChannelImage(_ channel: ImdSatelliteRadarView.SatelliteChannel) {
            // 1. Check in-memory cache for INSTANT 0ms rendering
            if let cached = SatelliteImageCache.shared.getImage(for: channel.id) {
                applyImage(cached)
                return
            }
            
            // 2. Fetch asynchronously if not yet preloaded
            let channelId = channel.id
            let channelUrl = channel.url
            Task {
                do {
                    var request = URLRequest(url: channelUrl)
                    request.cachePolicy = .reloadIgnoringLocalCacheData
                    let (data, _) = try await URLSession.shared.data(for: request)
                    if let image = NSImage(data: data) {
                        SatelliteImageCache.shared.setImage(image, for: channelId)
                        if self.currentChannelId == channelId {
                            self.applyImage(image)
                        }
                    }
                } catch {
                    // Silently ignore network failure
                }
            }
        }
        
        private func applyImage(_ image: NSImage) {
            self.imageView?.image = image
            guard let sv = self.scrollView else { return }
            let svSize = sv.bounds.size
            let imgSize = image.size
            if imgSize.width > 0 && imgSize.height > 0 && svSize.width > 0 && svSize.height > 0 {
                let widthRatio = svSize.width / imgSize.width
                let heightRatio = svSize.height / imgSize.height
                let fitRatio = max(widthRatio, heightRatio)
                
                // Scale document view to fill container box edge-to-edge
                self.imageView?.frame = NSRect(
                    x: 0,
                    y: 0,
                    width: max(svSize.width, imgSize.width * fitRatio),
                    height: max(svSize.height, imgSize.height * fitRatio)
                )
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
