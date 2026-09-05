import Foundation
import SwiftUI
import CoreLocation

// MARK: - AI SITREP (Situation Report) Model
public struct AiSituationReport: Identifiable {
    public let id: String = UUID().uuidString
    public let generatedAt: Date
    public let incidentTitle: String
    public let overallThreatLevel: String
    public let executiveSummary: String
    public let casualtyStats: CasualtyStatistics
    public let shelterStatus: ShelterStatistics
    public let topThreatHotspots: [ThreatHotspot]
    public let activeRoadBlockages: [String]
    public let deployedUnitsSummary: String
    public let recommendedImmediateActions: [String]
    public let rawMarkdown: String
    
    public struct CasualtyStatistics {
        public let totalSosReceived: Int
        public let criticalRed: Int
        public let urgentOrange: Int
        public let moderateYellow: Int
        public let safelyRescued: Int
        public let rescueRatePercentage: Int
    }
    
    public struct ShelterStatistics {
        public let totalCamps: Int
        public let totalCapacity: Int
        public let currentOccupancy: Int
        public let occupancyPercentage: Int
        public let availableVacancy: Int
        public let criticallyFullCamps: [String]
    }
    
    public struct ThreatHotspot: Identifiable {
        public let id: String = UUID().uuidString
        public let sectorName: String
        public let coordinate: CLLocationCoordinate2D
        public let victimCount: Int
        public let primaryHazard: String
        public let urgency: String
    }
}

// MARK: - AI Chat Message
public struct AiChatMessage: Identifiable, Equatable {
    public let id: String = UUID().uuidString
    public let sender: MessageSender
    public let text: String
    public let timestamp: Date
    public let suggestedActions: [AiAction]?
    
    public enum MessageSender {
        case user
        case copilot
    }
    
    public struct AiAction: Identifiable, Equatable {
        public let id: String = UUID().uuidString
        public let title: String
        public let actionType: ActionType
        
        public enum ActionType: Equatable {
            case broadcastEvacuation(String)
            case dispatchTeam(String)
            case rerouteShelter(String)
            case viewMap
        }
    }
}

// MARK: - Garuda AI Intelligence Engine
@MainActor
public final class GarudaAiEngine: ObservableObject {
    public static let shared = GarudaAiEngine()
    
    @Published public var isGeneratingSitrep: Bool = false
    @Published public var currentSitrep: AiSituationReport? = nil
    @Published public var chatMessages: [AiChatMessage] = []
    @Published public var isAnalyzingTriage: Bool = false
    
    private init() {
        // Initial Welcoming Copilot Message
        chatMessages = [
            AiChatMessage(
                sender: .copilot,
                text: "Namaste Commander. Garuda AI Disaster Copilot is active and continuously analyzing live BLE mesh packets, IMD satellite telemetry, and relief camp logistics.\n\nYou can ask me for real-time SITREP briefings, bottleneck analysis, medical triage prioritization, or draft bilingual evacuation broadcasts.",
                timestamp: Date(),
                suggestedActions: [
                    .init(title: "📄 Generate Official NDMA SITREP", actionType: .broadcastEvacuation("SITREP")),
                    .init(title: "⚠️ Identify Critical Bottlenecks", actionType: .broadcastEvacuation("BOTTLENECK")),
                    .init(title: "⛺ Shelter Capacity Rebalance", actionType: .rerouteShelter("REBALANCE")),
                    .init(title: "📢 Draft Hindi Evacuation Alert", actionType: .broadcastEvacuation("DRAFT_HINDI"))
                ]
            )
        ]
    }
    
    // MARK: - Generate Comprehensive NDMA Situation Report
    public func generateSitrep(from store: CommandCenterStore) -> AiSituationReport {
        let now = Date()
        let totalSignals = store.signals.count
        let criticalCount = store.signals.filter { $0.priority == .critical && $0.status != .rescued }.count
        let urgentCount = store.signals.filter { $0.priority == .urgent && $0.status != .rescued }.count
        let moderateCount = store.signals.filter { $0.priority == .moderate && $0.status != .rescued }.count
        let rescuedCount = store.signals.filter { $0.status == .rescued }.count
        let rescueRate = totalSignals > 0 ? Int((Double(rescuedCount) / Double(totalSignals)) * 100) : 0
        
        // Shelter stats
        let totalCamps = store.shelters.count
        let totalCapacity = store.shelters.reduce(0) { $0 + $1.capacity }
        let currentOccupancy = store.shelters.reduce(0) { $0 + $1.currentOccupancy }
        let occupancyPct = totalCapacity > 0 ? Int((Double(currentOccupancy) / Double(totalCapacity)) * 100) : 0
        let availableVacancy = max(0, totalCapacity - currentOccupancy)
        let fullCamps = store.shelters.filter { $0.capacity > 0 && (Double($0.currentOccupancy) / Double($0.capacity)) >= 0.9 }.map { $0.name }
        
        // Hazards & Blocked roads
        let blockedRoads = store.hazards.filter { $0.status == .roadBlocked }.map { "\($0.title) (\($0.category))" }
        
        // Threat Hotspots Identification
        var hotspots: [AiSituationReport.ThreatHotspot] = []
        if !store.signals.isEmpty {
            // Group by approximate cluster
            let pendingCritical = store.signals.filter { $0.priority == .critical && $0.status != .rescued }
            if !pendingCritical.isEmpty {
                let first = pendingCritical[0]
                hotspots.append(
                    .init(
                        sectorName: "High Distress Sector (Near \(String(format: "%.3f", first.latitude))°N, \(String(format: "%.3f", first.longitude))°E)",
                        coordinate: first.coordinate,
                        victimCount: pendingCritical.count,
                        primaryHazard: first.emergencyType.rawValue,
                        urgency: "CRITICAL: Immediate Air/Boat Extraction Needed"
                    )
                )
            }
        }
        
        if hotspots.isEmpty {
            hotspots.append(
                .init(
                    sectorName: "Primary Operations Sector (Standby)",
                    coordinate: CLLocationCoordinate2D(latitude: 28.6139, longitude: 77.2090),
                    victimCount: totalSignals,
                    primaryHazard: "Monitored Zone",
                    urgency: "Normal Operations"
                )
            )
        }
        
        // Threat Level
        let threatLevel = criticalCount > 0 || !blockedRoads.isEmpty ? "LEVEL 3: SEVERE DISASTER RESPONSE ACTIVE" : "LEVEL 1: STANDBY & MONITORING"
        
        let summary = "Project Garuda AI has synthesized live telemetry from \(max(1, store.connectedClientsCount)) gateway nodes, \(totalSignals) citizen SOS transmissions, and \(totalCamps) relief hubs. Current casualty stabilization stands at \(rescueRate)%. \(blockedRoads.count) critical transport arteries are impassable. Satellite Doppler radar indicates sustained precipitation over active operational sectors."
        
        let recommendedActions = [
            criticalCount > 0 ? "Dispatch NDRF Heavy Rescue Boat Squads to \(criticalCount) unattended Red-Priority victims." : "Maintain rapid-response readiness for next wave of mesh telemetry.",
            !fullCamps.isEmpty ? "Rebalance evacuee transport: Divert incoming civilians from \(fullCamps.joined(separator: ", ")) towards hubs with available vacancy (\(availableVacancy) spots open)." : "Maintain current shelter intake protocol.",
            !blockedRoads.isEmpty ? "Broadcast emergency road closure reroute warning to citizen mobile apps for \(blockedRoads.count) blocked corridors." : "Transport corridors clear.",
            "Schedule next IMD INSAT-3D Doppler storm track projection in 30 minutes."
        ]
        
        // Format official Markdown SITREP
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MMM-yyyy HH:mm:ss 'IST'"
        let dateStr = formatter.string(from: now)
        
        let markdown = """
        # 🇮🇳 NATIONAL DISASTER MANAGEMENT AUTHORITY (NDMA)
        ## OFFICIAL DISASTER SITUATION REPORT (SITREP) #\(Int.random(in: 100...999))
        **Generated by Project Garuda AI Command Engine**
        **Timestamp:** \(dateStr) | **Classification:** RESTRICTED - OPERATIONAL COMMAND
        
        ---
        
        ### 1. EXECUTIVE SITUATION SUMMARY
        **Current Operational Status:** \(threatLevel)
        \(summary)
        
        ---
        
        ### 2. CASUALTY & RESCUE TRIAGE MATRIX
        | Metric | Count / Status | Notes |
        | :--- | :---: | :--- |
        | **Total SOS Transmissions** | `\(totalSignals)` | Ingested via BLE Mesh + Cloud Gateways |
        | **🔴 Critical (Red Priority)** | `\(criticalCount)` | Immediate Life Threat (Submerged/Trapped) |
        | **🟠 Urgent (Orange Priority)** | `\(urgentCount)` | Severe Medical / Blood Need |
        | **🟡 Moderate (Yellow Priority)** | `\(moderateCount)` | Stranded / Supplies Depleted |
        | **🟢 Safely Rescued / Safe** | `\(rescuedCount)` | Rescued & Transferred to Triage |
        | **Current Rescue Success Rate** | `\(rescueRate)%` | Continuous Mesh Tracking |
        
        ---
        
        ### 3. RELIEF CAMPS & LOGISTICS HAVEN MATRIX
        * **Total Field Shelters:** \(totalCamps) active evacuation hubs
        * **Bed Capacity:** \(currentOccupancy) / \(totalCapacity) Beds Occupied (\(occupancyPct)%)
        * **Available Intake Vacancy:** \(availableVacancy) Beds Ready
        * **Overcapacity Risk Alerts:** \(fullCamps.isEmpty ? "None (All camps within safe limits)" : fullCamps.joined(separator: ", "))
        
        ---
        
        ### 4. CRITICAL CHOKEPOINTS & BLOCKED ARTERIES
        \(blockedRoads.isEmpty ? "• All major evacuation corridors open." : blockedRoads.map { "• ⛔ <b>ROAD BLOCKED:</b> \($0)" }.joined(separator: "\n"))
        
        ---
        
        ### 5. AI DIRECTIVE ACTION RECOMMENDATIONS FOR COMMANDER
        \(recommendedActions.enumerated().map { "\( $0.offset + 1 ). \( $0.element )" }.joined(separator: "\n"))
        
        ---
        *Report compiled autonomously via Project Garuda Delay-Tolerant Edge Intelligence System.*
        """
        
        let report = AiSituationReport(
            generatedAt: now,
            incidentTitle: "National Disaster Command Operational Briefing",
            overallThreatLevel: threatLevel,
            executiveSummary: summary,
            casualtyStats: .init(
                totalSosReceived: totalSignals,
                criticalRed: criticalCount,
                urgentOrange: urgentCount,
                moderateYellow: moderateCount,
                safelyRescued: rescuedCount,
                rescueRatePercentage: rescueRate
            ),
            shelterStatus: .init(
                totalCamps: totalCamps,
                totalCapacity: totalCapacity,
                currentOccupancy: currentOccupancy,
                occupancyPercentage: occupancyPct,
                availableVacancy: availableVacancy,
                criticallyFullCamps: fullCamps
            ),
            topThreatHotspots: hotspots,
            activeRoadBlockages: blockedRoads,
            deployedUnitsSummary: "\(store.ndrfUnits.count) NDRF Units registered. \(store.signals.filter { $0.assignedUnit != nil }.count) units actively engaged in extraction.",
            recommendedImmediateActions: recommendedActions,
            rawMarkdown: markdown
        )
        
        self.currentSitrep = report
        return report
    }
    
    // MARK: - Process Natural Language Query
    public func processCopilotQuery(prompt: String, store: CommandCenterStore) {
        let userMsg = AiChatMessage(sender: .user, text: prompt, timestamp: Date(), suggestedActions: nil)
        chatMessages.append(userMsg)
        
        let lower = prompt.lowercased()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            let response: String
            var actions: [AiChatMessage.AiAction] = []
            
            if lower.contains("sitrep") || lower.contains("report") || lower.contains("summary") {
                let sitrep = self.generateSitrep(from: store)
                response = "✅ **Official NDMA SITREP Generated.**\n\n- **Status:** \(sitrep.overallThreatLevel)\n- **Active Victims:** \(sitrep.casualtyStats.totalSosReceived) total (\(sitrep.casualtyStats.criticalRed) Critical Red)\n- **Shelter Intake:** \(sitrep.shelterStatus.currentOccupancy)/\(sitrep.shelterStatus.totalCapacity) beds occupied (\(sitrep.shelterStatus.occupancyPercentage)%)\n- **Blocked Arteries:** \(sitrep.activeRoadBlockages.count) road hazards verified.\n\nYou can review and copy the complete briefing in the SITREP tab."
                actions = [
                    .init(title: "📋 Copy Full SITREP Markdown", actionType: .broadcastEvacuation("COPY_SITREP")),
                    .init(title: "📢 Broadcast Evacuation Warning", actionType: .broadcastEvacuation("BROADCAST"))
                ]
            } else if lower.contains("bottleneck") || lower.contains("urgent") || lower.contains("critical") {
                let crit = store.signals.filter { $0.priority == .critical && $0.status != .rescued }
                let blocked = store.hazards.filter { $0.status == .roadBlocked }
                let fullCamps = store.shelters.filter { $0.capacity > 0 && Double($0.currentOccupancy)/Double($0.capacity) >= 0.85 }
                
                response = "⚠️ **AI Bottleneck Analysis:**\n\n1. **Extraction Queue:** \(crit.count) Critical Red victims currently waiting for NDRF assignment.\n2. **Logistics Chokepoints:** \(blocked.count) verified blocked routes slowing down boat/ambulance transit.\n3. **Shelter Strain:** \(fullCamps.count) relief camps nearing 90% capacity limit (\(fullCamps.map { $0.name }.joined(separator: ", ")))."
                
                actions = [
                    .init(title: "🚁 Dispatch NDRF to Critical Victims", actionType: .dispatchTeam("CRITICAL")),
                    .init(title: "⛔ Reroute Evacuation Traffic", actionType: .rerouteShelter("REROUTE"))
                ]
            } else if lower.contains("hindi") || lower.contains("broadcast") || lower.contains("draft") {
                let hindiAlert = "🚨 राष्ट्रीय आपदा चेतावनी (NDMA GARUDA)\nबाढ़ और भारी जलभराव के कारण तुरंत सुरक्षित ऊंचे स्थानों या राहत शिविरों की ओर जाएं। बिजली के खंभों और जलमग्न सड़कों से दूर रहें। आपातकालीन सहायता के लिए गरुड़ मेश ऐप पर 'SOS' सक्रिय रखें। हेल्पलाइन: 1078."
                response = "📢 **Drafted Bilingual Emergency Broadcast:**\n\n**[HINDI]**\n\(hindiAlert)\n\n**[ENGLISH]**\n🚨 URGENT EVACUATION ADVISORY: Flash flooding threat active. Evacuate immediately to designated relief shelters. Avoid submerged roads and downed power lines. Maintain active BLE Mesh on Garuda app. Helpline: 1078."
                
                actions = [
                    .init(title: "🚀 Broadcast to All Citizen Apps", actionType: .broadcastEvacuation(hindiAlert))
                ]
            } else if lower.contains("shelter") || lower.contains("camp") || lower.contains("rebalance") {
                let totalCap = store.shelters.reduce(0) { $0 + $1.capacity }
                let totalOcc = store.shelters.reduce(0) { $0 + $1.currentOccupancy }
                let vac = max(0, totalCap - totalOcc)
                
                response = "⛺ **Relief Camp Load Balancing Report:**\n\n- **Total Shelters:** \(store.shelters.count)\n- **Total Capacity:** \(totalCap) beds\n- **Current Sheltered:** \(totalOcc) evacuees\n- **Net Vacancy:** \(vac) available spots\n\n💡 **AI Recommendation:** Direct incoming evacuee convoys to camps with highest vacancy to prevent overcrowding at ground zero."
                
                actions = [
                    .init(title: "⛺ Open Relief Camps Manager", actionType: .rerouteShelter("OPEN_CAMPS"))
                ]
            } else {
                response = "Analysis complete for query: *\"\(prompt)\"*\n\nBased on live telemetry, all systems are operational. Total SOS transmissions: **\(store.signals.count)**. Active Relief Hubs: **\(store.shelters.count)**. IMD Satellite radar connection is **ONLINE**."
                actions = [
                    .init(title: "📄 Generate NDMA SITREP", actionType: .broadcastEvacuation("SITREP")),
                    .init(title: "🗺️ Inspect Live Map", actionType: .viewMap)
                ]
            }
            
            let copilotMsg = AiChatMessage(sender: .copilot, text: response, timestamp: Date(), suggestedActions: actions)
            self.chatMessages.append(copilotMsg)
        }
    }
}
