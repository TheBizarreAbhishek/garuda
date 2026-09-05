package com.project.garuda.data

import android.content.Context
import android.content.SharedPreferences
import android.os.Build
import com.project.garuda.ui.sos.ChecklistItem
import com.project.garuda.ui.sos.EmergencyContact
import com.project.garuda.ui.sos.MedicalProfile
import com.project.garuda.ui.sos.defaultChecklist
import org.json.JSONArray
import org.json.JSONObject

/**
 * Manages local persistence for Citizen Medical Profile and Survival Readiness Checklists.
 */
class CitizenPersistenceManager(context: Context) {

    private val prefs: SharedPreferences = context.getSharedPreferences("garuda_citizen_prefs", Context.MODE_PRIVATE)

    companion object {
        private const val KEY_FULL_NAME = "key_full_name"
        private const val KEY_BLOOD_GROUP = "key_blood_group"
        private const val KEY_ALLERGIES = "key_allergies"
        private const val KEY_CHRONIC = "key_chronic_conditions"
        private const val KEY_CONTACTS_JSON = "key_emergency_contacts_json"
        private const val KEY_CHECKED_ITEMS = "key_checked_checklist_items"
        private const val KEY_PRIVATE_CONTACTS_JSON = "key_private_mesh_contacts_json"
        private const val KEY_LAST_ALERT_TIMESTAMP = "key_last_alert_timestamp"
        private const val KEY_LAST_ALERT_ACTIVE = "key_last_alert_active"
        private const val KEY_DEVICE_HASH = "key_persistent_device_hash"
    }

    fun getOrCreateDeviceHash(): Int {
        val existing = prefs.getInt(KEY_DEVICE_HASH, 0)
        if (existing != 0) return existing
        
        val uuid = java.util.UUID.randomUUID()
        val modelHash = (Build.MANUFACTURER ?: "") + (Build.MODEL ?: "") + (Build.DEVICE ?: "")
        val rawHash = (uuid.hashCode() xor modelHash.hashCode() xor System.currentTimeMillis().toInt())
        val finalHash = if (rawHash != 0) rawHash else 0x4744A1
        prefs.edit().putInt(KEY_DEVICE_HASH, finalHash).apply()
        return finalHash
    }

    fun loadPrivateContacts(): List<PrivateMeshContact> {
        val json = prefs.getString(KEY_PRIVATE_CONTACTS_JSON, null) ?: return emptyList()
        val list = mutableListOf<PrivateMeshContact>()
        try {
            val array = JSONArray(json)
            for (i in 0 until array.length()) {
                val obj = array.getJSONObject(i)
                list.add(
                    PrivateMeshContact(
                        id = obj.optString("id", "$i"),
                        name = obj.optString("name", "Family Member"),
                        deviceId = obj.optString("deviceId", ""),
                        relation = obj.optString("relation", "Family")
                    )
                )
            }
        } catch (e: Exception) {
            // fallback
        }
        return list
    }

    fun savePrivateContacts(contacts: List<PrivateMeshContact>) {
        val array = JSONArray()
        contacts.forEach { c ->
            val obj = JSONObject().apply {
                put("id", c.id)
                put("name", c.name)
                put("deviceId", c.deviceId)
                put("relation", c.relation)
            }
            array.put(obj)
        }
        prefs.edit().putString(KEY_PRIVATE_CONTACTS_JSON, array.toString()).apply()
    }

    fun getLastAlertNotifiedTimestamp(): Long {
        return prefs.getLong(KEY_LAST_ALERT_TIMESTAMP, 0L)
    }

    fun setLastAlertNotifiedTimestamp(ts: Long) {
        prefs.edit().putLong(KEY_LAST_ALERT_TIMESTAMP, ts).apply()
    }

    fun getLastAlertActiveState(): Boolean {
        return prefs.getBoolean(KEY_LAST_ALERT_ACTIVE, false)
    }

    fun setLastAlertActiveState(active: Boolean) {
        prefs.edit().putBoolean(KEY_LAST_ALERT_ACTIVE, active).apply()
    }

    fun loadMedicalProfile(defaultName: String = "Citizen Node"): MedicalProfile {
        val fullName = prefs.getString(KEY_FULL_NAME, defaultName) ?: defaultName
        val bloodGroup = prefs.getString(KEY_BLOOD_GROUP, "O+") ?: "O+"
        val allergies = prefs.getString(KEY_ALLERGIES, "") ?: ""
        val chronic = prefs.getString(KEY_CHRONIC, "") ?: ""

        val contactsJson = prefs.getString(KEY_CONTACTS_JSON, null)
        val contacts = mutableListOf<EmergencyContact>()
        if (contactsJson != null) {
            try {
                val array = JSONArray(contactsJson)
                for (i in 0 until array.length()) {
                    val obj = array.getJSONObject(i)
                    contacts.add(
                        EmergencyContact(
                            id = obj.optString("id", "$i"),
                            name = obj.optString("name", "Emergency Contact"),
                            relation = obj.optString("relation", "Family"),
                            phone = obj.optString("phone", "112")
                        )
                    )
                }
            } catch (e: Exception) {
                // fallback to empty
            }
        }

        return MedicalProfile(
            fullName = fullName,
            bloodGroup = bloodGroup,
            allergies = allergies,
            chronicConditions = chronic,
            emergencyContacts = contacts
        )
    }

    fun saveMedicalProfile(profile: MedicalProfile) {
        val array = JSONArray()
        profile.emergencyContacts.forEach { contact ->
            val obj = JSONObject().apply {
                put("id", contact.id)
                put("name", contact.name)
                put("relation", contact.relation)
                put("phone", contact.phone)
            }
            array.put(obj)
        }

        prefs.edit()
            .putString(KEY_FULL_NAME, profile.fullName)
            .putString(KEY_BLOOD_GROUP, profile.bloodGroup)
            .putString(KEY_ALLERGIES, profile.allergies)
            .putString(KEY_CHRONIC, profile.chronicConditions)
            .putString(KEY_CONTACTS_JSON, array.toString())
            .apply()
    }

    fun loadChecklist(): List<ChecklistItem> {
        val checkedIds = prefs.getStringSet(KEY_CHECKED_ITEMS, emptySet()) ?: emptySet()
        return defaultChecklist().map { item ->
            item.copy(isChecked = checkedIds.contains(item.id))
        }
    }

    fun saveChecklist(items: List<ChecklistItem>) {
        val checkedIds = items.filter { it.isChecked }.map { it.id }.toSet()
        prefs.edit()
            .putStringSet(KEY_CHECKED_ITEMS, checkedIds)
            .apply()
    }
}

data class PrivateMeshContact(
    val id: String,
    val name: String,
    val deviceId: String,
    val relation: String = "Family"
)
