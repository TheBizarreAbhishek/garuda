# Project Garuda: Teammate Vibe-Coding Prompts (Parts 1 - 6)

Welcome to **Project Garuda**! Each team member can pick their assigned part and copy-paste the corresponding prompt directly into Antigravity to build and submit their PR.

---

## Part 1: Core BLE Mesh & Multi-Hop Relay Engine (`:core:mesh`)
**Assigned Lead**: Abhishek  
**Branch Name**: `feat/ble-mesh-engine`

### Antigravity Prompt:
```text
I am working on Part 1 of Project Garuda: Core BLE Mesh & Multi-Hop Relay Engine.
Target Module: :core:mesh
Please guide and implement this step-by-step:
1. Create the Compact Binary Protocol encoder/decoder (Legacy 31-byte frame + BLE 5.0 extended frame) packing Header, PacketType, PacketId, DeviceHash, Timestamp, Fixed-point Lat/Lon, EmergencyType, HopCount/TTL, and Checksum into 28 bytes.
2. Build unit tests for encoding and decoding to ensure zero loss and byte-level precision.
3. Implement the BleAdvertiser class using Android BluetoothLeAdvertiser with ADVERTISE_MODE_LOW_LATENCY and ADVERTISE_TX_POWER_HIGH.
4. Implement the BleScanner class with ScanFilter matching Garuda Manufacturer ID (0x4744) and low-latency scan settings.
5. Create the MeshRelayEngine:
   - Maintains an LRU cache of seen PacketIds (size 500).
   - If a new packet arrives with TTL > 0: decrement TTL, increment HopCount, recalculate checksum, and schedule re-broadcast with randomized jitter (100ms - 600ms).
6. Wrap this inside a Foreground Service (MeshForegroundService) with an ongoing notification "Garuda Disaster Mesh Active" and adaptive duty-cycling (High alert continuous vs background 5s scan / 25s idle).
Run all unit tests to verify everything passes cleanly.
```

---

## Part 2: Data Persistence, GPS Location & Cloud Sync Gateway (`:core:data`, `:core:network`)
**Assigned Teammate**: Teammate 4  
**Branch Name**: `feat/data-cloud-sync`

### Antigravity Prompt:
```text
I am working on Part 2 of Project Garuda: Data Persistence, GPS Location & Cloud Sync Gateway.
Target Modules: :core:data and :core:network
Please guide and implement this step-by-step:
1. Setup Room Database (GarudaDatabase) with:
   - SosPacketEntity: packetId, senderId, timestamp, lat, lon, emergencyType, hopCount, syncStatus (LOCAL, RELAYED, SYNCED)
   - MeshMessageEntity: messageId, senderName, text, timestamp, hopCount
   - HazardReportEntity: id, photoUri, hazardType, description, lat, lon, syncStatus
   - ReliefShelterEntity: id, name, lat, lon, capacity, suppliesStatus
2. Create Room DAOs with Kotlin Coroutines Flow for real-time observation.
3. Implement GpsLocationProvider using Google Play Services FusedLocationProviderClient with high accuracy and fallback to last known location.
4. Implement NetworkConnectivityMonitor using ConnectivityManager.NetworkCallback to observe Wi-Fi and Cellular data availability.
5. Implement FirebaseSyncWorker (using AndroidX WorkManager):
   - Triggered automatically when NetworkConnectivityMonitor reports internet connectivity.
   - Queries all un-synced SOS packets and hazard reports from Room DB.
   - Performs batch upload to Firebase Firestore collection "disaster_sos".
   - Updates entity syncStatus to SYNCED upon successful upload.
6. Write Room DAO unit tests with in-memory database to verify insertion, querying, and syncStatus updates.
```

---

## Part 3: Disaster Sensors, Emergency Triggers & Power Saving (`:core:sensors`)
**Assigned Teammate**: Teammate 3  
**Branch Name**: `feat/sensors-emergency-triggers`

### Antigravity Prompt:
```text
I am working on Part 3 of Project Garuda: Disaster Sensors, Emergency Triggers & Power Saving.
Target Module: :core:sensors
Please guide and implement this step-by-step:
1. Implement FallAndCrashDetector using SensorManager (TYPE_ACCELEROMETER and TYPE_GYROSCOPE):
   - Algorithm: Detects sudden spike (> 3.5g) followed by freefall/impact and complete immobility (> 5 seconds).
   - Fires an onEmergencyTriggerDetected callback with a 15-second cancel countdown.
2. Implement HardwareButtonTrigger:
   - Listens for 3 rapid power button presses to silently trigger SOS without looking at the screen.
3. Implement DeadManWatchdogTimer:
   - Configurable check-in interval (e.g. every 2 hours during active disaster).
   - If user fails to tap "I am Safe" within 10 minutes of notification, triggers automatic SOS broadcast.
4. Implement AdaptivePowerManager:
   - HighAlertMode: 100% duty cycle.
   - DutyCycleMode: throttles BLE mesh scanning to 5s ON / 25s OFF to save 80% battery.
   - ExtremeSurvivalMode: enables battery-saving configuration and signals UI to use pure AMOLED black.
5. Create mathematical unit tests with simulated accelerometer time-series data to verify the fall detection algorithm does not produce false positives on normal walking/running.
```

---

## Part 4: Citizen UI, Standby/Active Emergency & SOS Core (`:feature:sos`, `:app`)
**Assigned Teammate**: Teammate 2  
**Branch Name**: `feat/citizen-ui-sos`

### Antigravity Prompt:
```text
I am working on Part 4 of Project Garuda: Citizen UI, Standby/Active Emergency & SOS Core.
Target Module: :feature:sos and :app
Please guide and implement this step-by-step:
1. Design System & Emergency Theme:
   - Modern Material 3 dark mode with high-contrast emergency palette (Blood Red #E53935, Amber Alert #FFB300, Safe Green #43A047, Pure AMOLED Black #000000).
2. Peace-Time Standby Screen:
   - Status badge: "Standby Mode — No Active Disaster in your Region".
   - Offline Survival Kits: Interactive checklists for Earthquake, Flood, Cyclone.
   - First Aid Guidelines & Emergency Bag Checklist.
   - Medical Profile card setup (Blood group, allergies, emergency contacts).
3. Government Emergency Activation Listener:
   - Listens to Firebase Cloud Messaging (FCM) high-priority push notification and Firestore system_status.
   - Unlocks Active Emergency Mode with a bold alert dialog.
4. Active Emergency Screen:
   - Big Red SOS Panic Button with pulse animation and 5-second cancel countdown timer.
   - Real-time mesh status indicator: "Broadcasting SOS • Relayed by X peers".
   - "I am Safe" one-tap check-in button with SMS fallback.
   - Emergency contacts quick-dial.
5. Ensure smooth Jetpack Compose previews for both Standby and Active Emergency states.
```

---

## Part 5: Offline Mesh Chatroom & Relief Services (`:feature:chat`, `:feature:relief`)
**Assigned Teammates**: Teammates 2 & 3  
**Branch Name**: `feat/offline-chat-relief`

### Antigravity Prompt:
```text
I am working on Part 5 of Project Garuda: Offline Mesh Chatroom & Relief Services.
Target Modules: :feature:chat and :feature:relief
Please guide and implement this step-by-step:
1. Offline P2P Mesh Chatroom (ChatScreen.kt):
   - Local broadcast channel: "Nearby Survivors & Volunteers".
   - Integrates with :core:mesh to broadcast chat packets and observe incoming mesh messages.
   - Displays sender name, timestamp, and hop count (e.g. "1 hop away (~30m)").
2. Hybrid Shelter Radar (ShelterScreen.kt):
   - Online mode: Interactive Google Map showing relief shelters, current capacity, and available supplies.
   - Offline mode: Minimalist GPS Compass Bearing Radar arrow pointing directly toward the nearest shelter with live distance (meters/km).
3. Crowdsourced Hazard & Damage Reporter (HazardReportScreen.kt):
   - Camera photo capture for damaged infrastructure (collapsed bridge, blocked road, fallen electrical wire).
   - Hazard type selector & severity tags.
   - Saves locally to Room DB queue and triggers background upload when internet is detected.
4. Missing Persons Directory (MissingPersonsScreen.kt):
   - Offline searchable list of reported missing persons with photos, last seen coordinates, and status.
   - "Report Missing Person" form.
```

---

## Part 6: macOS Government Command Center (`garuda-macos`)
**Assigned Lead**: Abhishek  
**Branch Name**: `feat/macos-command-center` (in separate repo `garuda-macos`)

### Antigravity Prompt:
```text
I am working on Part 6 of Project Garuda: macOS Government Command Center.
Target: Native macOS App in SwiftUI (Xcode)
Please guide and implement this step-by-step:
1. SwiftUI Native Desktop Architecture with NavigationSplitView.
2. Firebase Swift SDK Integration:
   - Real-time snapshot listener on Firestore "disaster_sos" collection.
3. Live MapKit GIS Dashboard:
   - Interactive macOS map with custom victim pin annotations.
   - Color-coded triage severity: Red (Critical/Trapped), Orange (Injured), Yellow (Assistance Needed), Green (Safe).
   - Hop-relay visualization showing which gateway device uploaded the signal and hop count.
4. Triage & Rescue Dispatch Board:
   - Live triage list sorted by urgency.
   - Rescue dispatch workflow (Pending -> NDRF Dispatched -> Rescued).
5. Government Emergency Activation Broadcaster:
   - Interactive district/geofence selector.
   - Push notification composer that calls Firebase Cloud Messaging (FCM) API to activate Android citizen apps in the disaster zone.
6. Hazard Reviewer Panel:
   - Visual gallery of citizen-submitted damage photos with coordinates to validate danger zones on the map.
```

---

## Git Workflow for Team Members

1. **Clone the main repo**:
   ```bash
   git clone https://github.com/TheBizarreAbhishek/garuda.git
   cd garuda
   ```
2. **Create your feature branch**:
   ```bash
   git checkout -b feat/<your-assigned-feature>
   ```
3. **Commit and Push**:
   ```bash
   git add .
   git commit -m "feat(module): implement <feature details>"
   git push origin feat/<your-assigned-feature>
   ```
4. **Open Pull Request** on GitHub against `TheBizarreAbhishek/garuda:main`.
