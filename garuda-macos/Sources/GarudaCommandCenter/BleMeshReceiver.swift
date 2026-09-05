import Foundation
import CoreBluetooth
import Combine

@MainActor
public protocol BleMeshReceiverDelegate: AnyObject {
    func bleMeshDidReceiveSosSignal(_ signal: SosSignal)
    func bleMeshDidDiscoverNode(device: ConnectedDevice)
    func bleMeshDidReceiveHazard(_ hazard: HazardReport)
    func bleMeshActiveNodesUpdated(count: Int)
}

public final class BleMeshReceiver: NSObject, CBCentralManagerDelegate, @unchecked Sendable {
    public static let shared = BleMeshReceiver()
    
    private var centralManager: CBCentralManager?
    public weak var delegate: BleMeshReceiverDelegate?
    
    public private(set) var isScanning: Bool = false
    private let queue = DispatchQueue(label: "com.garuda.macos.blemesh", qos: .userInitiated)
    
    // Track active nearby mesh nodes: deviceHash -> lastSeen Date
    private var activeNodes: [Int32: (device: ConnectedDevice, lastSeen: Date)] = [:]
    private var cleanupTimer: Timer?
    
    private static let FIXED_POINT_SCALE = 1e7
    private static let GARUDA_MANUFACTURER_ID: UInt16 = 0x4744
    
    override public init() {
        super.init()
    }
    
    public func start() {
        if centralManager == nil {
            centralManager = CBCentralManager(delegate: self, queue: queue, options: [
                CBCentralManagerOptionShowPowerAlertKey: true
            ])
        } else if centralManager?.state == .poweredOn {
            startScanning()
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.startCleanupTimer()
        }
    }
    
    public func stop() {
        centralManager?.stopScan()
        isScanning = false
        cleanupTimer?.invalidate()
        cleanupTimer = nil
    }
    
    private func startScanning() {
        guard centralManager?.state == .poweredOn else { return }
        // Scan with allow duplicates to continuously capture periodic heartbeats and SOS beacons
        centralManager?.scanForPeripherals(
            withServices: nil,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        )
        isScanning = true
        print("[BleMeshReceiver] CoreBluetooth BLE Mesh Scanner started on macOS")
    }
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("[BleMeshReceiver] macOS Bluetooth Powered ON - Starting Mesh Scan")
            startScanning()
        case .poweredOff:
            print("[BleMeshReceiver] macOS Bluetooth Powered OFF")
            isScanning = false
        case .unauthorized:
            print("[BleMeshReceiver] macOS Bluetooth Unauthorized")
            isScanning = false
        default:
            break
        }
    }
    
    public func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        guard let mfgData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data else {
            return
        }
        
        parseGarudaManufacturerData(mfgData, peripheralName: peripheral.name, rssi: RSSI.intValue)
    }
    
    private func parseGarudaManufacturerData(_ data: Data, peripheralName: String?, rssi: Int) {
        // BLE Manufacturer Data in CoreBluetooth:
        // First 2 bytes are Company ID (0x44, 0x47 in little-endian or 0x47, 0x44 in big-endian)
        // Followed by our 27-byte payload
        var payloadData: Data?
        
        if data.count >= 29 {
            let mfgId = UInt16(data[0]) | (UInt16(data[1]) << 8)
            let mfgIdBig = (UInt16(data[0]) << 8) | UInt16(data[1])
            if mfgId == Self.GARUDA_MANUFACTURER_ID || mfgIdBig == Self.GARUDA_MANUFACTURER_ID {
                payloadData = data.subdata(in: 2..<data.count)
            }
        }
        
        if payloadData == nil && data.count >= 27 {
            // Check if first 2 bytes are 0x47 0x44 directly
            if data[0] == 0x47 && data[1] == 0x44 {
                payloadData = data
            }
        }
        
        guard let packetBytes = payloadData, packetBytes.count >= 27 else { return }
        
        // Validate Header (0x47, 0x44)
        guard packetBytes[0] == 0x47 && packetBytes[1] == 0x44 else { return }
        
        // Extract fields
        let packetType = packetBytes[2]
        
        let packetId = packetBytes.withUnsafeBytes { $0.load(fromByteOffset: 3, as: UInt32.self).bigEndian }
        let deviceHash = packetBytes.withUnsafeBytes { $0.load(fromByteOffset: 7, as: Int32.self).bigEndian }
        let timestamp = packetBytes.withUnsafeBytes { $0.load(fromByteOffset: 11, as: UInt32.self).bigEndian }
        
        let latRaw = packetBytes.withUnsafeBytes { $0.load(fromByteOffset: 15, as: Int32.self).bigEndian }
        let lonRaw = packetBytes.withUnsafeBytes { $0.load(fromByteOffset: 19, as: Int32.self).bigEndian }
        
        let latitude = Double(latRaw) / Self.FIXED_POINT_SCALE
        let longitude = Double(lonRaw) / Self.FIXED_POINT_SCALE
        
        let emergencyTypeCode = packetBytes[23]
        let hopAndTtl = packetBytes[24]
        let hopCount = Int(hopAndTtl & 0x0F)
        
        let nodeName = peripheralName ?? "Mesh Node #\(abs(deviceHash) % 9000 + 1000)"
        let deviceId = "BLE-MESH-\(deviceHash)"
        
        let node = ConnectedDevice(
            id: deviceId,
            name: nodeName,
            batteryLevel: 90,
            status: "ONLINE (BLE)",
            meshRole: "Offline BLE Relay Node",
            location: (latitude != 0.0 && longitude != 0.0) ? String(format: "%.4f°N, %.4f°E", latitude, longitude) : "Nearby Mesh Range",
            latitude: (latitude != 0.0) ? latitude : 25.4358,
            longitude: (longitude != 0.0) ? longitude : 81.8463,
            lastSeen: Date(),
            isOnline: true,
            connectionType: "BLE_MESH_DIRECT",
            hopCount: hopCount
        )
        
        queue.async { [weak self] in
            guard let self = self else { return }
            self.activeNodes[deviceHash] = (device: node, lastSeen: Date())
            let activeCount = self.activeNodes.count
            
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.bleMeshDidDiscoverNode(device: node)
                self?.delegate?.bleMeshActiveNodesUpdated(count: activeCount)
            }
        }
        
        // Handle Specific Packet Types
        if packetType == 1 { // SOS Signal
            let emergencyType: EmergencyType = {
                switch emergencyTypeCode {
                case 1: return .medical
                case 2: return .trapped
                case 3: return .fire
                case 4: return .flood
                default: return .general
                }
            }()
            
            let signal = SosSignal(
                id: "SOS-\(packetId)",
                victimName: "Survivor (\(nodeName))",
                bloodGroup: "O+",
                emergencyType: emergencyType,
                priority: .critical,
                latitude: (latitude != 0.0) ? latitude : 25.4358,
                longitude: (longitude != 0.0) ? longitude : 81.8463,
                hopCount: hopCount,
                batteryLevel: 85,
                timestamp: Date(timeIntervalSince1970: TimeInterval(timestamp)),
                status: .pending,
                notes: "Live distress signal received directly over Offline CoreBluetooth BLE Mesh (Hop #\(hopCount)).",
                relayedByGatewayId: "MAC-DIRECT-BLE"
            )
            
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.bleMeshDidReceiveSosSignal(signal)
            }
        }
    }
    
    private func startCleanupTimer() {
        cleanupTimer?.invalidate()
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.queue.async {
                let now = Date()
                let initialCount = self.activeNodes.count
                // 25-second active presence sliding window
                self.activeNodes = self.activeNodes.filter { now.timeIntervalSince($0.value.lastSeen) < 25.0 }
                if self.activeNodes.count != initialCount {
                    let updatedCount = self.activeNodes.count
                    DispatchQueue.main.async { [weak self] in
                        self?.delegate?.bleMeshActiveNodesUpdated(count: updatedCount)
                    }
                }
            }
        }
    }
}
