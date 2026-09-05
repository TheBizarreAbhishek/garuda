package com.project.garuda.ui.sos

enum class DisasterMode {
    STANDBY,
    ACTIVE_EMERGENCY
}

enum class EmergencyType(val title: String, val code: Int, val description: String) {
    TRAPPED("Trapped in Debris", 0x01, "Trapped under collapsed structure or rubble"),
    MEDICAL("Medical Urgent", 0x02, "Severe injury, blood loss, or unconsciousness"),
    FLOOD("Rising Flood Water", 0x03, "Cut off by water / trapped on roof"),
    FIRE("Fire / Gas Hazard", 0x04, "Fire outbreak or toxic smoke hazard"),
    GENERAL("General SOS", 0x05, "Critical danger, need immediate rescue")
}

enum class ChecklistCategory(val label: String) {
    GO_BAG("72-Hour Go-Bag"),
    EARTHQUAKE("Earthquake Safety"),
    FLOOD("Flood Readiness"),
    CYCLONE("Cyclone Protocol"),
    FIRST_AID("First Aid Essentials")
}

data class ChecklistItem(
    val id: String,
    val title: String,
    val detail: String = "",
    val category: ChecklistCategory,
    val isChecked: Boolean = false
)

data class EmergencyContact(
    val id: String,
    val name: String,
    val relation: String,
    val phone: String
)

data class MedicalProfile(
    val fullName: String = "Citizen Node",
    val bloodGroup: String = "O+",
    val allergies: String = "",
    val chronicConditions: String = "",
    val emergencyContacts: List<EmergencyContact> = emptyList()
)

sealed interface SosBroadcastState {
    object Idle : SosBroadcastState
    data class Countdown(val secondsRemaining: Int) : SosBroadcastState
    data class Broadcasting(
        val emergencyType: EmergencyType,
        val elapsedSeconds: Int,
        val packetId: String,
        val timestampEpoch: Long
    ) : SosBroadcastState
    data class ResolvedSafe(
        val checkInTimestamp: Long,
        val smsSentCount: Int
    ) : SosBroadcastState
}

data class MeshRelayStatus(
    val isMeshActive: Boolean = true,
    val peersNearby: Int = 4,
    val hopCount: Int = 2,
    val packetsRelayed: Int = 18,
    val lastSyncAgo: String = "12s ago",
    val signalStrengthDbm: Int = -68
)

data class GovernmentAlert(
    val alertId: String = "NDMA-2026-RED-09",
    val agency: String = "National Disaster Management Authority (NDMA)",
    val severity: String = "CRITICAL RED ALERT",
    val headline: String = "Severe Cyclone & Flash Flood Warning",
    val instructions: String = "Move to higher ground immediately. Power and cell towers may drop. Project Garuda BLE Mesh is active for civilian distress tracking.",
    val region: String = "Coastal & Low-Lying Districts",
    val timestampFormatted: String = "Today, 14:30 IST"
)

data class CitizenUiState(
    val mode: DisasterMode = DisasterMode.STANDBY,
    val medicalProfile: MedicalProfile = MedicalProfile(),
    val survivalChecklist: List<ChecklistItem> = defaultChecklist(),
    val sosState: SosBroadcastState = SosBroadcastState.Idle,
    val meshStatus: MeshRelayStatus = MeshRelayStatus(),
    val pendingGovAlert: GovernmentAlert? = null,
    val isGovernmentAlertDialogOpen: Boolean = false,
    val selectedEmergencyType: EmergencyType = EmergencyType.TRAPPED,
    val isSafetyConfirmationDialogOpen: Boolean = false,
    val safeStatusMessage: String? = null
)

fun defaultChecklist(): List<ChecklistItem> = listOf(
    // Go-Bag
    ChecklistItem("gb-1", "3L Bottled Drinking Water per person", "Survival minimum for 72 hours", ChecklistCategory.GO_BAG, true),
    ChecklistItem("gb-2", "Non-perishable energy rations / dry fruits", "High calorie, requires no cooking", ChecklistCategory.GO_BAG, true),
    ChecklistItem("gb-3", "High-power LED flashlight + spare batteries", "Waterproof flashlight or hand-crank", ChecklistCategory.GO_BAG, false),
    ChecklistItem("gb-4", "Charged power bank (20,000 mAh)", "Keeps Garuda BLE relay alive", ChecklistCategory.GO_BAG, true),
    ChecklistItem("gb-5", "Emergency whistle (high decibel)", "Audible to search dogs and rescue crews", ChecklistCategory.GO_BAG, false),
    ChecklistItem("gb-6", "Waterproof pouch for Aadhaar/ID & Cash", "Paper documents ruin easily in flood", ChecklistCategory.GO_BAG, false),

    // First Aid
    ChecklistItem("fa-1", "Sterile gauze bandages & adhesive tape", "Bleeding control", ChecklistCategory.FIRST_AID, true),
    ChecklistItem("fa-2", "Antiseptic solution (Betadine/Dettol)", "Wound cleansing", ChecklistCategory.FIRST_AID, false),
    ChecklistItem("fa-3", "Tourniquet & trauma shears", "Critical limb hemorrhage control", ChecklistCategory.FIRST_AID, false),
    ChecklistItem("fa-4", "Personal prescribed medicines (7 days)", "Pack extra in ziplock bag", ChecklistCategory.FIRST_AID, true),

    // Earthquake
    ChecklistItem("eq-1", "DROP, COVER, and HOLD ON protocol practiced", "Under sturdy desk or table", ChecklistCategory.EARTHQUAKE, true),
    ChecklistItem("eq-2", "Main gas valve and electrical mains located", "Know how to shut off instantly", ChecklistCategory.EARTHQUAKE, false),
    ChecklistItem("eq-3", "Safe outdoor open area identified", "Away from glass facades and utility poles", ChecklistCategory.EARTHQUAKE, true),

    // Flood
    ChecklistItem("fl-1", "Rooftop access verified and unobstructed", "Prepare ladder or hatch key", ChecklistCategory.FLOOD, false),
    ChecklistItem("fl-2", "Electrical appliances disconnected from floor sockets", "Prevent electrocution hazard", ChecklistCategory.FLOOD, true),
    ChecklistItem("fl-3", "Life jackets / flotation rings checked", "Secure inflatable vests if available", ChecklistCategory.FLOOD, false),

    // Cyclone
    ChecklistItem("cy-1", "Window panes taped / storm shutters closed", "Prevent flying debris shards", ChecklistCategory.CYCLONE, false),
    ChecklistItem("cy-2", "Unsecured rooftop water tanks/furniture tied down", "Wind velocity can exceed 150 km/h", ChecklistCategory.CYCLONE, false)
)
