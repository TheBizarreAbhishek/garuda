import SwiftUI

public struct TriageKanbanView: View {
    @ObservedObject var store: CommandCenterStore
    
    @State private var searchText: String = ""
    @State private var selectedPriorityFilter: PriorityFilter = .all
    @State private var selectedEmergencyType: String = "ALL"
    
    enum PriorityFilter: String, CaseIterable {
        case all = "All Priorities"
        case critical = "Critical (Red)"
        case urgent = "Urgent (Orange)"
        case moderate = "Moderate (Yellow)"
    }
    
    public init(store: CommandCenterStore) {
        self.store = store
    }
    
    private var pendingCount: Int { store.signals.filter { $0.status == .pending }.count }
    private var dispatchedCount: Int { store.signals.filter { $0.status == .dispatched }.count }
    private var inProgressCount: Int { store.signals.filter { $0.status == .inProgress }.count }
    private var rescuedCount: Int { store.signals.filter { $0.status == .rescued }.count }
    
    private func filterSignals(_ signals: [SosSignal]) -> [SosSignal] {
        signals.filter { signal in
            let matchesSearch = searchText.isEmpty ||
                signal.victimName.localizedCaseInsensitiveContains(searchText) ||
                signal.bloodGroup.localizedCaseInsensitiveContains(searchText) ||
                signal.notes.localizedCaseInsensitiveContains(searchText) ||
                signal.emergencyType.rawValue.localizedCaseInsensitiveContains(searchText)
            
            if !matchesSearch { return false }
            
            if selectedEmergencyType != "ALL" && !signal.emergencyType.rawValue.localizedCaseInsensitiveContains(selectedEmergencyType) {
                return false
            }
            
            switch selectedPriorityFilter {
            case .all:
                return true
            case .critical:
                return signal.priority == .critical
            case .urgent:
                return signal.priority == .urgent
            case .moderate:
                return signal.priority == .moderate
            }
        }
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // 1. Top Header Bar
            headerBar
            
            Divider()
            
            // 2. Metrics Bar
            metricsBar
            
            Divider()
            
            // 3. Search & Priority Filter Toolbar
            filterToolbar
            
            Divider()
            
            // 4. Kanban Columns Board
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 14) {
                    KanbanColumn(
                        title: "PENDING TRIAGE",
                        status: .pending,
                        color: .red,
                        icon: "exclamationmark.triangle.fill",
                        filteredSignals: filterSignals(store.signals.filter { $0.status == .pending }),
                        store: store
                    )
                    
                    KanbanColumn(
                        title: "NDRF DISPATCHED",
                        status: .dispatched,
                        color: .blue,
                        icon: "airplane.departure",
                        filteredSignals: filterSignals(store.signals.filter { $0.status == .dispatched }),
                        store: store
                    )
                    
                    KanbanColumn(
                        title: "RESCUE IN PROGRESS",
                        status: .inProgress,
                        color: .orange,
                        icon: "figure.walk.motion",
                        filteredSignals: filterSignals(store.signals.filter { $0.status == .inProgress }),
                        store: store
                    )
                    
                    KanbanColumn(
                        title: "RESOLVED / RESCUED",
                        status: .rescued,
                        color: .green,
                        icon: "checkmark.seal.fill",
                        filteredSignals: filterSignals(store.signals.filter { $0.status == .rescued }),
                        store: store
                    )
                }
                .padding(16)
            }
            .background(Color.black.opacity(0.15))
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Header Bar
    private var headerBar: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 36, height: 36)
                Image(systemName: "square.grid.3x2.fill")
                    .font(.system(size: 16, weight: .black))
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text("TRIAGE & RESCUE DISPATCH BOARD")
                        .font(.system(size: 13, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 4) {
                        Circle().fill(Color.green).frame(width: 6, height: 6)
                        Text("LIVE GROUND MESH SYNC")
                            .font(.system(size: 8, weight: .black, design: .monospaced))
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.15))
                    .clipShape(Capsule())
                }
                
                Text("NDRF / SDRF Incident Command: Real-time victim prioritization, unit allocation, and status progression.")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button {
                store.toggleSimulation()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: store.isSimulatingMeshArrivals ? "pause.fill" : "play.fill")
                    Text(store.isSimulatingMeshArrivals ? "Stop Simulation" : "Simulate Mesh Traffic")
                }
                .font(.system(size: 11, weight: .bold))
            }
            .buttonStyle(.bordered)
            .tint(store.isSimulatingMeshArrivals ? .orange : .blue)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Metrics Bar
    private var metricsBar: some View {
        HStack(spacing: 12) {
            metricCard(title: "PENDING TRIAGE", value: "\(pendingCount)", subtitle: "Unattended SOS", icon: "exclamationmark.triangle.fill", color: .red)
            metricCard(title: "NDRF DISPATCHED", value: "\(dispatchedCount)", subtitle: "Units En Route", icon: "airplane.departure", color: .blue)
            metricCard(title: "IN PROGRESS", value: "\(inProgressCount)", subtitle: "Ground Operations", icon: "figure.walk.motion", color: .orange)
            metricCard(title: "SAFELY RESCUED", value: "\(rescuedCount)", subtitle: "Triage Resolved", icon: "checkmark.seal.fill", color: .green)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.2))
    }
    
    private func metricCard(title: String, value: String, subtitle: String, icon: String, color: Color) -> some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 8, weight: .black, design: .monospaced))
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.system(size: 14, weight: .black, design: .monospaced))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(8)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }
    
    // MARK: - Filter Toolbar
    private var filterToolbar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search victim, blood group (e.g. O+), medical notes...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.1), lineWidth: 1))
            .frame(maxWidth: 320)
            
            Picker("Priority", selection: $selectedPriorityFilter) {
                ForEach(PriorityFilter.allCases, id: \.self) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Kanban Column Component
struct KanbanColumn: View {
    let title: String
    let status: RescueStatus
    let color: Color
    let icon: String
    let filteredSignals: [SosSignal]
    @ObservedObject var store: CommandCenterStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Column Header
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 13, weight: .bold))
                
                Text(title)
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(filteredSignals.count)")
                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(color.opacity(0.2))
                    .foregroundColor(color)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            
            Divider().opacity(0.3)
            
            // Cards List
            ScrollView {
                LazyVStack(spacing: 10) {
                    if filteredSignals.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "tray")
                                .font(.system(size: 24))
                                .foregroundColor(.secondary.opacity(0.4))
                            Text("No Incidents")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 120)
                    } else {
                        ForEach(filteredSignals) { signal in
                            TriageCardView(signal: signal, store: store)
                        }
                    }
                }
                .padding(4)
            }
        }
        .padding(10)
        .frame(width: 320)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Triage Card View
struct TriageCardView: View {
    let signal: SosSignal
    @ObservedObject var store: CommandCenterStore
    
    var priorityColor: Color {
        switch signal.priority {
        case .critical: return .red
        case .urgent: return .orange
        case .moderate: return .yellow
        case .safe: return .green
        }
    }
    
    let ndrfUnitsList: [String] = [
        "NDRF Battalion 9 (Water Rescue)",
        "NDRF Quick Response Team 4",
        "SDRF Disaster Unit Alpha",
        "Indian Army Air Wing Chopper 2",
        "State Emergency Medical Unit"
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header: Priority Dot + Victim Name + Blood Group
            HStack(spacing: 8) {
                Circle()
                    .fill(priorityColor)
                    .frame(width: 8, height: 8)
                
                Text(signal.victimName)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(signal.bloodGroup)
                    .font(.system(size: 9, weight: .heavy, design: .monospaced))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.red.opacity(0.2))
                    .foregroundColor(.red)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            
            // Emergency Type & Medical Condition
            HStack(spacing: 6) {
                Image(systemName: signal.emergencyType.icon)
                    .font(.system(size: 11))
                    .foregroundColor(.orange)
                Text(signal.emergencyType.rawValue)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            // Telemetry: Hops + Battery + Coordinates
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                    Text("\(signal.hopCount) Hops")
                }
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(.secondary)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "battery.50")
                    Text("\(signal.batteryLevel)%")
                }
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(signal.batteryLevel < 25 ? .red : .green)
            }
            
            // Notes
            if !signal.notes.isEmpty {
                Text(signal.notes)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .padding(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.black.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            
            // Assigned Unit Badge
            if let unit = signal.assignedUnit {
                HStack(spacing: 4) {
                    Image(systemName: "person.3.sequence.fill")
                        .font(.system(size: 9))
                    Text(unit)
                        .font(.system(size: 9, weight: .bold))
                }
                .foregroundColor(.cyan)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.cyan.opacity(0.15))
                .clipShape(Capsule())
            }
            
            Divider().opacity(0.2)
            
            // Actions Row: Move Backward / Assign Unit / Advance Status
            HStack(spacing: 6) {
                // Move Back (if not pending)
                if signal.status != .pending {
                    Button {
                        stepBackward()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .buttonStyle(.plain)
                    .padding(5)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
                }
                
                // Responder Unit Menu
                Menu {
                    ForEach(ndrfUnitsList, id: \.self) { unit in
                        Button(unit) {
                            store.updateSignalStatus(id: signal.id, newStatus: signal.status == .pending ? .dispatched : signal.status, assignedUnit: unit)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "person.badge.plus")
                        Text(signal.assignedUnit == nil ? "Assign NDRF" : "Reassign")
                    }
                    .font(.system(size: 9, weight: .bold))
                }
                .menuStyle(.borderlessButton)
                
                Spacer()
                
                // Fast Step Forward Action Button
                if signal.status != .rescued {
                    Button {
                        stepForward()
                    } label: {
                        HStack(spacing: 4) {
                            Text(nextActionTitle)
                            Image(systemName: "chevron.right")
                        }
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(nextActionColor)
                }
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(priorityColor.opacity(0.4), lineWidth: 1)
        )
    }
    
    private var nextActionTitle: String {
        switch signal.status {
        case .pending: return "Dispatch"
        case .dispatched: return "In Progress"
        case .inProgress: return "Mark Safe"
        case .rescued: return "Resolved"
        }
    }
    
    private var nextActionColor: Color {
        switch signal.status {
        case .pending: return .blue
        case .dispatched: return .orange
        case .inProgress: return .green
        case .rescued: return .secondary
        }
    }
    
    private func stepForward() {
        switch signal.status {
        case .pending:
            let defaultUnit = signal.assignedUnit ?? "NDRF Battalion 9 (Rapid Response)"
            store.updateSignalStatus(id: signal.id, newStatus: .dispatched, assignedUnit: defaultUnit)
        case .dispatched:
            store.updateSignalStatus(id: signal.id, newStatus: .inProgress, assignedUnit: signal.assignedUnit)
        case .inProgress:
            store.updateSignalStatus(id: signal.id, newStatus: .rescued, assignedUnit: signal.assignedUnit)
        case .rescued:
            break
        }
    }
    
    private func stepBackward() {
        switch signal.status {
        case .pending:
            break
        case .dispatched:
            store.updateSignalStatus(id: signal.id, newStatus: .pending, assignedUnit: signal.assignedUnit)
        case .inProgress:
            store.updateSignalStatus(id: signal.id, newStatus: .dispatched, assignedUnit: signal.assignedUnit)
        case .rescued:
            store.updateSignalStatus(id: signal.id, newStatus: .inProgress, assignedUnit: signal.assignedUnit)
        }
    }
}
