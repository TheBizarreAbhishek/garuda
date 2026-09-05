import SwiftUI
import AppKit

public struct AiDisasterCopilotView: View {
    @ObservedObject var store: CommandCenterStore
    @StateObject private var aiEngine = GarudaAiEngine.shared
    
    @State private var selectedSubTab: CopilotSubTab = .sitrep
    @State private var queryInputText: String = ""
    @State private var isCopiedNotificationShown: Bool = false
    
    enum CopilotSubTab: String, CaseIterable {
        case sitrep = "📄 Official NDMA SITREP"
        case copilotChat = "🤖 AI Command Assistant"
        case smartTriage = "🧠 Smart Medical Triage"
    }
    
    public init(store: CommandCenterStore) {
        self.store = store
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // 1. Top Command Header
            headerBar
            
            Divider()
            
            // 2. Sub-Tab Switcher
            subTabBar
            
            Divider()
            
            // 3. Sub-Tab Content
            Group {
                switch selectedSubTab {
                case .sitrep:
                    sitrepGeneratorView
                case .copilotChat:
                    copilotChatView
                case .smartTriage:
                    smartTriageView
                }
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            if aiEngine.currentSitrep == nil {
                _ = aiEngine.generateSitrep(from: store)
            }
        }
    }
    
    // MARK: - Header Bar
    private var headerBar: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.purple.opacity(0.2))
                    .frame(width: 36, height: 36)
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.purple)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text("GARUDA AI DISASTER COPILOT & SITREP ENGINE")
                        .font(.system(size: 13, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 4) {
                        Circle().fill(Color.purple).frame(width: 6, height: 6)
                        Text("ON-DEVICE NEURAL REASONING")
                            .font(.system(size: 8, weight: .black, design: .monospaced))
                            .foregroundColor(.purple)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.purple.opacity(0.15))
                    .clipShape(Capsule())
                }
                
                Text("Real-time telemetry synthesis, automated NDMA Situation Reports (SITREP), and rapid medical triage classification.")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Generate / Refresh SITREP Button
            Button {
                _ = aiEngine.generateSitrep(from: store)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                    Text("Regenerate SITREP")
                }
                .font(.system(size: 11, weight: .bold))
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Sub-Tab Switcher
    private var subTabBar: some View {
        HStack(spacing: 12) {
            Picker("Copilot View", selection: $selectedSubTab) {
                ForEach(CopilotSubTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 480)
            
            Spacer()
            
            if isCopiedNotificationShown {
                Text("✓ SITREP Copied to Clipboard!")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.green)
                    .transition(.opacity)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.2))
    }
    
    // MARK: - Tab 1: SITREP Generator View
    private var sitrepGeneratorView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if let sitrep = aiEngine.currentSitrep {
                    // Top Action Bar: Copy & Export
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("OFFICIAL NDMA SITUATION REPORT")
                                .font(.system(size: 16, weight: .black, design: .monospaced))
                                .foregroundColor(.white)
                            Text("Generated: \(sitrep.generatedAt.formatted(date: .abbreviated, time: .standard)) IST • Classification: RESTRICTED")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Copy Markdown Button
                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(sitrep.rawMarkdown, forType: .string)
                            withAnimation {
                                isCopiedNotificationShown = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                withAnimation {
                                    isCopiedNotificationShown = false
                                }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "doc.on.doc")
                                Text("Copy SITREP Text")
                            }
                            .font(.system(size: 11, weight: .bold))
                        }
                        .buttonStyle(.bordered)
                        .tint(.cyan)
                    }
                    .padding(14)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    
                    // Threat Level & Executive Summary Card
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("OPERATIONAL THREAT LEVEL:")
                                .font(.system(size: 10, weight: .black, design: .monospaced))
                                .foregroundColor(.secondary)
                            
                            Text(sitrep.overallThreatLevel)
                                .font(.system(size: 11, weight: .black, design: .monospaced))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.red.opacity(0.2))
                                .foregroundColor(.red)
                                .clipShape(Capsule())
                        }
                        
                        Text(sitrep.executiveSummary)
                            .font(.system(size: 13))
                            .foregroundColor(.white)
                            .lineSpacing(4)
                    }
                    .padding(14)
                    .background(Color.purple.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.purple.opacity(0.3), lineWidth: 1))
                    
                    // 2-Column Metrics: Casualty Triage + Relief Shelter Status
                    HStack(alignment: .top, spacing: 14) {
                        // Left: Casualty Matrix
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "cross.case.fill")
                                    .foregroundColor(.red)
                                Text("CASUALTY & TRIAGE STATUS")
                                    .font(.system(size: 11, weight: .black, design: .monospaced))
                                    .foregroundColor(.white)
                                Spacer()
                                Text("\(sitrep.casualtyStats.rescueRatePercentage)% Saved")
                                    .font(.system(size: 10, weight: .black, design: .monospaced))
                                    .foregroundColor(.green)
                            }
                            
                            Divider().opacity(0.2)
                            
                            statRow(label: "Total SOS Transmissions", value: "\(sitrep.casualtyStats.totalSosReceived)", color: .white)
                            statRow(label: "🔴 Critical (Red Priority)", value: "\(sitrep.casualtyStats.criticalRed)", color: .red)
                            statRow(label: "🟠 Urgent (Orange Priority)", value: "\(sitrep.casualtyStats.urgentOrange)", color: .orange)
                            statRow(label: "🟡 Moderate (Yellow Priority)", value: "\(sitrep.casualtyStats.moderateYellow)", color: .yellow)
                            statRow(label: "🟢 Safely Rescued", value: "\(sitrep.casualtyStats.safelyRescued)", color: .green)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.08), lineWidth: 1))
                        
                        // Right: Shelter Matrix
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "tent.fill")
                                    .foregroundColor(.green)
                                Text("RELIEF CAMPS & HAVEN MATRIX")
                                    .font(.system(size: 11, weight: .black, design: .monospaced))
                                    .foregroundColor(.white)
                                Spacer()
                                Text("\(sitrep.shelterStatus.occupancyPercentage)% Full")
                                    .font(.system(size: 10, weight: .black, design: .monospaced))
                                    .foregroundColor(sitrep.shelterStatus.occupancyPercentage > 80 ? .orange : .cyan)
                            }
                            
                            Divider().opacity(0.2)
                            
                            statRow(label: "Active Field Shelters", value: "\(sitrep.shelterStatus.totalCamps)", color: .white)
                            statRow(label: "Total Bed Capacity", value: "\(sitrep.shelterStatus.totalCapacity)", color: .cyan)
                            statRow(label: "Current Evacuees Sheltered", value: "\(sitrep.shelterStatus.currentOccupancy)", color: .white)
                            statRow(label: "Available Intake Vacancy", value: "\(sitrep.shelterStatus.availableVacancy)", color: .green)
                            
                            if !sitrep.shelterStatus.criticallyFullCamps.isEmpty {
                                HStack {
                                    Text("Overcapacity Warning:")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.red)
                                    Text(sitrep.shelterStatus.criticallyFullCamps.joined(separator: ", "))
                                        .font(.system(size: 10))
                                        .foregroundColor(.red)
                                        .lineLimit(1)
                                }
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.08), lineWidth: 1))
                    }
                    
                    // AI Directive Action Recommendations
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(.yellow)
                            Text("AI DIRECTIVE ACTIONS FOR INCIDENT COMMANDER")
                                .font(.system(size: 11, weight: .black, design: .monospaced))
                                .foregroundColor(.white)
                        }
                        
                        Divider().opacity(0.2)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(sitrep.recommendedImmediateActions.enumerated()), id: \.offset) { index, action in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("\(index + 1).")
                                        .font(.system(size: 12, weight: .black, design: .monospaced))
                                        .foregroundColor(.yellow)
                                    Text(action)
                                        .font(.system(size: 12))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    }
                    .padding(14)
                    .background(Color.yellow.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.yellow.opacity(0.25), lineWidth: 1))
                }
            }
            .padding(20)
        }
    }
    
    private func statRow(label: String, value: String, color: Color) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(color)
        }
    }
    
    // MARK: - Tab 2: Interactive Copilot Chat
    private var copilotChatView: some View {
        VStack(spacing: 0) {
            // Chat Messages History
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(aiEngine.chatMessages) { msg in
                            ChatMessageRow(
                                message: msg,
                                onActionSelected: { action in
                                    handleAiAction(action)
                                }
                            )
                            .id(msg.id)
                        }
                    }
                    .padding(16)
                }
                .onChange(of: aiEngine.chatMessages.count) { _, _ in
                    if let last = aiEngine.chatMessages.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            Divider()
            
            // Quick Prompt Suggestions
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    quickPromptButton("📄 Generate SITREP Report")
                    quickPromptButton("⚠️ What are our critical bottlenecks?")
                    quickPromptButton("📢 Draft Hindi Evacuation Alert")
                    quickPromptButton("⛺ Check Relief Camp Capacities")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .background(Color.black.opacity(0.2))
            
            Divider()
            
            // Query Input Bar
            HStack(spacing: 10) {
                TextField("Ask Garuda AI (e.g. 'Draft evacuation order', 'Find red priority victims')...", text: $queryInputText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .padding(10)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.12), lineWidth: 1))
                    .onSubmit {
                        submitQuery()
                    }
                
                Button {
                    submitQuery()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "paperplane.fill")
                        Text("Send")
                    }
                    .font(.system(size: 11, weight: .bold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
                .disabled(queryInputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(14)
            .background(Color(NSColor.windowBackgroundColor))
        }
    }
    
    private func quickPromptButton(_ text: String) -> some View {
        Button {
            queryInputText = text
            submitQuery()
        } label: {
            Text(text)
                .font(.system(size: 10, weight: .medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.08))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
    
    private func submitQuery() {
        let trimmed = queryInputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        aiEngine.processCopilotQuery(prompt: trimmed, store: store)
        queryInputText = ""
    }
    
    private func handleAiAction(_ action: AiChatMessage.AiAction) {
        switch action.actionType {
        case .broadcastEvacuation(let text):
            if text == "SITREP" || text == "COPY_SITREP" {
                selectedSubTab = .sitrep
            } else {
                store.broadcastEmergencyActivation(
                    title: "🚨 URGENT EVACUATION DIRECTIVE",
                    severity: "EXTREME",
                    districts: ["Active Operational Disaster Zone"],
                    instructions: text
                )
            }
        case .dispatchTeam:
            break
        case .rerouteShelter:
            break
        case .viewMap:
            break
        }
    }
    
    // MARK: - Tab 3: Smart Medical Triage Matrix
    private var smartTriageView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("AUTOMATED START MEDICAL TRIAGE & NLP CLASSIFIER")
                            .font(.system(size: 13, weight: .black, design: .monospaced))
                            .foregroundColor(.white)
                        Text("AI scans victim notes, battery levels, and hop telemetry to extract high-risk factors and medical needs.")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(14)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                
                if store.signals.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "cross.case")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("No Distress Signals in Ingestion Stream")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                        Text("When SOS packets arrive over BLE mesh, AI will automatically analyze medical urgency.")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 340), spacing: 12)], spacing: 12) {
                        ForEach(store.signals) { signal in
                            AiTriageCard(signal: signal)
                        }
                    }
                }
            }
            .padding(20)
        }
    }
}

// MARK: - Chat Message Row
struct ChatMessageRow: View {
    let message: AiChatMessage
    let onActionSelected: (AiChatMessage.AiAction) -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if message.sender == .copilot {
                ZStack {
                    Circle().fill(Color.purple.opacity(0.2)).frame(width: 28, height: 28)
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.purple)
                }
            } else {
                Spacer()
            }
            
            VStack(alignment: message.sender == .copilot ? .leading : .trailing, spacing: 6) {
                Text(message.text)
                    .font(.system(size: 12))
                    .foregroundColor(.white)
                    .lineSpacing(3)
                    .padding(12)
                    .background(message.sender == .copilot ? Color.white.opacity(0.07) : Color.blue.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                
                // Suggested Quick Action Pills
                if let actions = message.suggestedActions, !actions.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(actions) { action in
                            Button {
                                onActionSelected(action)
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .foregroundColor(.purple)
                                    Text(action.title)
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.purple.opacity(0.2))
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(Color.purple.opacity(0.4), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 2)
                }
            }
            
            if message.sender == .user {
                ZStack {
                    Circle().fill(Color.blue.opacity(0.2)).frame(width: 28, height: 28)
                    Image(systemName: "person.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.blue)
                }
            } else {
                Spacer()
            }
        }
    }
}

// MARK: - AI Triage Card
struct AiTriageCard: View {
    let signal: SosSignal
    
    private var extractedTags: [String] {
        var tags: [String] = []
        let combined = (signal.victimName + " " + signal.notes + " " + signal.emergencyType.rawValue).lowercased()
        
        if combined.contains("trapped") || combined.contains("debris") { tags.append("Debris Extraction") }
        if combined.contains("flood") || combined.contains("water") || combined.contains("drowning") { tags.append("Rising Water Threat") }
        if combined.contains("unconscious") || combined.contains("faint") { tags.append("Unconscious / Severe") }
        if combined.contains("pregnant") || combined.contains("maternity") { tags.append("Maternity Care") }
        if combined.contains("baby") || combined.contains("child") || combined.contains("infant") { tags.append("Infant at Risk") }
        if combined.contains("blood") || signal.bloodGroup == "O-" { tags.append("Rare Blood (\(signal.bloodGroup))") }
        if signal.batteryLevel < 20 { tags.append("Critical Low Battery (\(signal.batteryLevel)%)") }
        
        if tags.isEmpty { tags.append("Standard Distress") }
        return tags
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(signal.victimName)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(signal.priority.rawValue)
                    .font(.system(size: 8, weight: .black, design: .monospaced))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.red.opacity(0.2))
                    .foregroundColor(.red)
                    .clipShape(Capsule())
            }
            
            HStack(spacing: 6) {
                Image(systemName: signal.emergencyType.icon)
                    .foregroundColor(.orange)
                    .font(.system(size: 11))
                Text(signal.emergencyType.rawValue)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            
            Divider().opacity(0.2)
            
            Text("AI Extracted Medical Tags:")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(.secondary)
            
            HStack(spacing: 4) {
                ForEach(extractedTags, id: \.self) { tag in
                    Text(tag)
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.purple.opacity(0.2))
                        .foregroundColor(.purple)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.purple.opacity(0.25), lineWidth: 1))
    }
}
