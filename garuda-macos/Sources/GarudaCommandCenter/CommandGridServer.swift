import Foundation
import Network

@MainActor
public protocol CommandGridServerDelegate: AnyObject {
    func serverDidReceiveSosSignal(_ signal: SosSignal)
    func serverDidReceiveHazardReport(_ hazard: HazardReport)
    func serverClientConnected(address: String)
    func serverClientDisconnected(address: String)
}

public final class CommandGridServer: @unchecked Sendable {
    public static let shared = CommandGridServer()
    
    private var listener: NWListener?
    private var activeConnections: [NWConnection] = []
    private let queue = DispatchQueue(label: "com.garuda.commandgrid.server", qos: .userInitiated)
    
    public weak var delegate: CommandGridServerDelegate?
    public private(set) var isRunning: Bool = false
    public private(set) var port: UInt16 = 8080
    
    public var currentAlertProvider: (() -> DisasterAlert?)?
    
    public init() {}
    
    public func start(port: UInt16 = 8080) {
        self.port = port
        do {
            let nwPort = NWEndpoint.Port(rawValue: port) ?? 8080
            let parameters = NWParameters.tcp
            listener = try NWListener(using: parameters, on: nwPort)
            
            listener?.stateUpdateHandler = { [weak self] state in
                switch state {
                case .ready:
                    print("[GarudaServer] Live Command Grid Server listening on port \(port)")
                    self?.isRunning = true
                case .failed(let error):
                    print("[GarudaServer] Failed to bind port \(port): \(error)")
                    self?.isRunning = false
                case .cancelled:
                    self?.isRunning = false
                default:
                    break
                }
            }
            
            listener?.newConnectionHandler = { [weak self] connection in
                self?.handleNewConnection(connection)
            }
            
            listener?.start(queue: queue)
        } catch {
            print("[GarudaServer] Error initializing NWListener: \(error)")
        }
    }
    
    public func stop() {
        listener?.cancel()
        listener = nil
        activeConnections.forEach { $0.cancel() }
        activeConnections.removeAll()
        isRunning = false
    }
    
    private func handleNewConnection(_ connection: NWConnection) {
        connection.start(queue: queue)
        activeConnections.append(connection)
        
        let clientAddress = "\(connection.endpoint)"
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.serverClientConnected(address: clientAddress)
        }
        
        receiveData(on: connection)
    }
    
    private func receiveData(on connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, context, isComplete, error in
            guard let self = self else { return }
            
            if let data = data, !data.isEmpty {
                self.processHttpRequest(data: data, connection: connection)
            }
            
            if isComplete || error != nil {
                self.activeConnections.removeAll { $0 === connection }
                let clientAddress = "\(connection.endpoint)"
                DispatchQueue.main.async {
                    self.delegate?.serverClientDisconnected(address: clientAddress)
                }
            } else {
                self.receiveData(on: connection)
            }
        }
    }
    
    private func processHttpRequest(data: Data, connection: NWConnection) {
        guard let requestString = String(data: data, encoding: .utf8) else { return }
        let lines = requestString.components(separatedBy: "\r\n")
        guard let requestLine = lines.first else { return }
        
        let parts = requestLine.components(separatedBy: " ")
        guard parts.count >= 2 else { return }
        
        let method = parts[0]
        let path = parts[1]
        
        // Extract Body if present
        var bodyData = Data()
        if let bodyRange = requestString.range(of: "\r\n\r\n") {
            let bodySubstring = requestString[bodyRange.upperBound...]
            bodyData = Data(bodySubstring.utf8)
        }
        
        switch (method, path) {
        case ("GET", "/api/v1/status"):
            handleGetStatus(connection: connection)
            
        case ("POST", "/api/v1/sos"):
            handlePostSos(body: bodyData, connection: connection)
            
        case ("POST", "/api/v1/hazard"):
            handlePostHazard(body: bodyData, connection: connection)
            
        case ("GET", "/api/v1/stream"):
            handleSseStream(connection: connection)
            
        default:
            sendHttpResponse(connection: connection, statusCode: 404, body: "{\"error\":\"Not Found\"}")
        }
    }
    
    private func handleGetStatus(connection: NWConnection) {
        let alert = currentAlertProvider?()
        let responseJson: [String: Any] = [
            "server": "Garuda Command Grid v1.0",
            "isEmergencyActive": alert?.isEmergencyActive ?? false,
            "activeDistrict": alert?.targetDistrict ?? "Normal / Standby",
            "headline": alert?.title ?? "No Active Emergency",
            "instructions": alert?.instructions ?? "System in peacetime standby.",
            "timestamp": Date().timeIntervalSince1970
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: responseJson, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            sendHttpResponse(connection: connection, statusCode: 200, body: jsonString)
        }
    }
    
    private func handlePostSos(body: Data, connection: NWConnection) {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        if let signal = try? decoder.decode(SosSignal.self, from: body) {
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.serverDidReceiveSosSignal(signal)
            }
            sendHttpResponse(connection: connection, statusCode: 200, body: "{\"status\":\"ACK_INGESTED\",\"id\":\"\(signal.id)\"}")
        } else {
            // Try raw parameter fallback if JSON key format differs
            if let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any] {
                let name = json["victimName"] as? String ?? "Mobile Citizen"
                let blood = json["bloodGroup"] as? String ?? "O+"
                let lat = json["latitude"] as? Double ?? 11.6854
                let lon = json["longitude"] as? Double ?? 76.1320
                let hops = json["hopCount"] as? Int ?? 0
                let battery = json["batteryLevel"] as? Int ?? 100
                let notes = json["notes"] as? String ?? "Relayed via Android Gateway"
                let gateway = json["relayedByGatewayId"] as? String ?? "\(connection.endpoint)"
                
                let signal = SosSignal(
                    victimName: name,
                    bloodGroup: blood,
                    emergencyType: .medical,
                    priority: .critical,
                    latitude: lat,
                    longitude: lon,
                    hopCount: hops,
                    batteryLevel: battery,
                    timestamp: Date(),
                    status: .pending,
                    notes: notes,
                    relayedByGatewayId: gateway
                )
                
                DispatchQueue.main.async { [weak self] in
                    self?.delegate?.serverDidReceiveSosSignal(signal)
                }
                sendHttpResponse(connection: connection, statusCode: 200, body: "{\"status\":\"ACK_INGESTED\",\"id\":\"\(signal.id)\"}")
            } else {
                sendHttpResponse(connection: connection, statusCode: 400, body: "{\"error\":\"Invalid SOS Payload\"}")
            }
        }
    }
    
    private func handlePostHazard(body: Data, connection: NWConnection) {
        if let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any] {
            let title = json["title"] as? String ?? "Road Blockage"
            let category = json["category"] as? String ?? "General Hazard"
            let lat = json["latitude"] as? Double ?? 11.6854
            let lon = json["longitude"] as? Double ?? 76.1320
            let desc = json["description"] as? String ?? ""
            let reporter = json["reporterName"] as? String ?? "Mobile Mesh Node"
            
            let hazard = HazardReport(
                title: title,
                category: category,
                latitude: lat,
                longitude: lon,
                reporterName: reporter,
                reportedAt: Date(),
                isVerified: false,
                description: desc
            )
            
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.serverDidReceiveHazardReport(hazard)
            }
            sendHttpResponse(connection: connection, statusCode: 200, body: "{\"status\":\"ACK_HAZARD_INGESTED\"}")
        } else {
            sendHttpResponse(connection: connection, statusCode: 400, body: "{\"error\":\"Invalid Hazard Payload\"}")
        }
    }
    
    private func handleSseStream(connection: NWConnection) {
        let header = "HTTP/1.1 200 OK\r\nContent-Type: text/event-stream\r\nCache-Control: no-cache\r\nConnection: keep-alive\r\nAccess-Control-Allow-Origin: *\r\n\r\n"
        connection.send(content: Data(header.utf8), completion: .contentProcessed({ _ in }))
        
        // Send initial heartbeat
        let initialEvent = "event: connected\ndata: {\"msg\":\"Connected to Garuda Command Grid SSE\"}\n\n"
        connection.send(content: Data(initialEvent.utf8), completion: .contentProcessed({ _ in }))
    }
    
    public func broadcastSseEvent(event: String, data: [String: Any]) {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: data),
              let jsonString = String(data: jsonData, encoding: .utf8) else { return }
        
        let ssePayload = "event: \(event)\ndata: \(jsonString)\n\n"
        let payloadData = Data(ssePayload.utf8)
        
        for connection in activeConnections {
            connection.send(content: payloadData, completion: .contentProcessed({ _ in }))
        }
    }
    
    private func sendHttpResponse(connection: NWConnection, statusCode: Int, body: String) {
        let statusText = statusCode == 200 ? "OK" : (statusCode == 400 ? "Bad Request" : "Not Found")
        let response = """
        HTTP/1.1 \(statusCode) \(statusText)\r
        Content-Type: application/json; charset=utf-8\r
        Content-Length: \(body.utf8.count)\r
        Access-Control-Allow-Origin: *\r
        Connection: close\r
        \r
        \(body)
        """
        connection.send(content: Data(response.utf8), completion: .contentProcessed({ _ in
            connection.cancel()
        }))
    }
}
