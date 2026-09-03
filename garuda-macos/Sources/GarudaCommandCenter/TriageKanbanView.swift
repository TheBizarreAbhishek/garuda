import SwiftUI

public struct TriageKanbanView: View {
    @ObservedObject var store: CommandCenterStore
    
    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 16) {
                KanbanColumn(
                    title: "Pending Triage",
                    status: .pending,
                    color: .red,
                    icon: "exclamationmark.triangle.fill",
                    store: store
                )
                
                KanbanColumn(
                    title: "NDRF Dispatched",
                    status: .dispatched,
                    color: .blue,
                    icon: "airplane.departure",
                    store: store
                )
                
                KanbanColumn(
                    title: "Rescue In Progress",
                    status: .inProgress,
                    color: .orange,
                    icon: "figure.walk.motion",
                    store: store
                )
                
                KanbanColumn(
                    title: "Resolved / Rescued",
                    status: .rescued,
                    color: .green,
                    icon: "checkmark.seal.fill",
                    store: store
                )
            }
            .padding(16)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

struct KanbanColumn: View {
    let title: String
    let status: RescueStatus
    let color: Color
    let icon: String
    @ObservedObject var store: CommandCenterStore
    
    var signalsInColumn: [SosSignal] {
        store.signals.filter { $0.status == status }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Column Header
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
                Spacer()
                Text("\(signalsInColumn.count)")
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(color.opacity(0.15))
                    .foregroundColor(color)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 4)
            
            Divider()
            
            // Cards List
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(signalsInColumn) { signal in
                        TriageCardView(signal: signal, store: store)
                    }
                    if signalsInColumn.isEmpty {
                        Text("No incidents in this stage")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, minHeight: 80)
                    }
                }
            }
        }
        .padding(12)
        .frame(width: 310)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }
}

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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(priorityColor)
                    .frame(width: 8, height: 8)
                Text(signal.victimName)
                    .font(.subheadline.bold())
                Spacer()
                Text(signal.bloodGroup)
                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color.red.opacity(0.1))
                    .foregroundColor(.red)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            
            HStack(spacing: 4) {
                Image(systemName: signal.emergencyType.icon)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(signal.emergencyType.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Label("\(signal.hopCount) Hops", systemImage: "antenna.radiowaves.left.and.right")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Label("\(signal.batteryLevel)%", systemImage: "battery.50")
                    .font(.caption2)
                    .foregroundColor(signal.batteryLevel < 25 ? .red : .secondary)
            }
            
            if let unit = signal.assignedUnit {
                Text("Assigned: \(unit)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.blue)
                    .padding(.top, 2)
            }
            
            // Fast status transition picker
            HStack {
                Spacer()
                Menu {
                    Button("Move to Pending") {
                        store.updateSignalStatus(id: signal.id, newStatus: .pending)
                    }
                    Button("Dispatch NDRF Alpha") {
                        store.updateSignalStatus(id: signal.id, newStatus: .dispatched, assignedUnit: "NDRF Battalion 4")
                    }
                    Button("Dispatch SDRF Team") {
                        store.updateSignalStatus(id: signal.id, newStatus: .dispatched, assignedUnit: "SDRF Rapid Response")
                    }
                    Button("Mark In Progress") {
                        store.updateSignalStatus(id: signal.id, newStatus: .inProgress)
                    }
                    Button("Mark Rescued / Safe") {
                        store.updateSignalStatus(id: signal.id, newStatus: .rescued)
                    }
                } label: {
                    Text("Action ▾")
                        .font(.caption.bold())
                }
                .menuStyle(.borderlessButton)
            }
        }
        .padding(10)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.08), radius: 2, y: 1)
    }
}
