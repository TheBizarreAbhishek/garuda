# Implementation Plan: Project Garuda — Full-Fledged Disaster Management System

Garuda is an offline-first disaster management ecosystem built for the Smart India Hackathon (SIH). It empowers citizens and disaster response authorities during total communication blackouts using a BLE Mesh multi-hop relay network that opportunistically flushes emergency telemetry and chat messages to a central Government Command Center via Firebase when any peer device touches an internet uplink.

---

## Team Execution Strategy & Antigravity Vibe-Coding

- The project is structured into **6 modular parts** to allow all 4 team members to develop simultaneously without Git merge conflicts.
- Git repository initialized at `https://github.com/TheBizarreAbhishek/garuda`.
- All team members will branch off `main` and submit Pull Requests to `TheBizarreAbhishek/garuda`.
- When any teammate loads the project in Antigravity, the custom onboarder will prompt: *"Which part of Project Garuda will you be working on today (Part 1 to Part 6)?"* and provide instant step-by-step guidance.

---

## System Architecture & The 6 Modular Parts

```
                           +-----------------------------------------------+
                           |      GOVERNMENT MAC COMMAND CENTER (Part 6)   |
                           |       Native macOS SwiftUI + MapKit + FCM     |
                           +-----------------------+-----------------------+
                                                   |
                                     (Internet / Firebase Spark)
                                                   |
                     +-----------------------------v-----------------------------+
                     |             UPLINK GATEWAY & CLOUD SYNC (Part 2)          |
                     |           Firebase Firestore + Room DB + WorkManager      |
                     +-----------------------------+-----------------------------+
                                                   |
                     +-----------------------------v-----------------------------+
                     |           OFFLINE BLE MESH ENGINE (Part 1)                |
                     |   Legacy 31B + BLE 5.0 Coded PHY Multi-Hop Store-Forward  |
                     +-----------------------------+-----------------------------+
                                                   |
         +-----------------------------------------+-----------------------------------------+
         |                                         |                                         |
+--------v----------------------+  +---------------v---------------+  +----------------------v-------+
|  SENSORS & AUTO-TRIGGERS      |  |  CITIZEN UI & SOS (Part 4)    |  |  OFFLINE CHAT & RELIEF (Part 5)
|         (Part 3)              |  |  Standby vs Active Emergency  |  |  P2P Mesh Walkie-Talkie Chat |
| Fall/Crash + Power Button     |  |  Big Red Panic + Safe Circle  |  |  Hybrid Shelter Radar + OSM  |
| Dead-Man Watchdog Timer       |  |  Government Activation Lock   |  |  Crowdsourced Hazard Reports |
+-------------------------------+  +-------------------------------+  +------------------------------+
```

---

## The 6 Work Packages & Team Assignment

| Part # | Pillar / Module Name | Assigned Lead | Core Responsibility |
| :--- | :--- | :--- | :--- |
| **Part 1** | **Core BLE Mesh & Multi-Hop Relay** (`:core:mesh`) | Abhishek (Lead) | BLE Advertising/Scanning, Compact Binary Protocol, TTL/Hop Relaying, LRU deduplication, Background Service |
| **Part 2** | **Data Persistence & Cloud Sync Gateway** (`:core:data`, `:core:network`) | Teammate 4 | Room Database, Network Connectivity Monitor, WorkManager Firebase Firestore Uplink Sync, GPS Provider |
| **Part 3** | **Sensors, Crash Triggers & Power Saving** (`:core:sensors`) | Teammate 3 | Accelerometer Fall/Crash detection, Power Button triple-press, Dead-man timer, Adaptive Duty Cycle & AMOLED Black mode |
| **Part 4** | **Citizen UI, Standby/Active & SOS Core** (`:feature:sos`, `:app`) | Teammate 2 | Standby Peace Mode, Gov Emergency Activation (FCM), Big Red Panic Button, Family Safety Circle |
| **Part 5** | **Offline Mesh Chatroom & Relief Services** (`:feature:chat`, `:feature:relief`) | Teammates 2 & 3 | P2P Local Broadcast Chatroom over BLE, Hybrid Shelter Radar (Compass bearing), Hazard Reporter with photo queue |
| **Part 6** | **macOS Government Command Center** (`garuda-macos`) | Abhishek (Lead) | Native SwiftUI macOS App, MapKit GIS victim heatmap, Triage Kanban Board, Alert Issuer & FCM Push broadcaster |

---

## Detailed Specification for Each Part

### Part 1: Core BLE Mesh Networking & Multi-Hop Relay Engine (`:core:mesh`)
- **Protocol**: Compact Binary Protocol (supports Legacy 31-byte advertising & BLE 5.0 Extended Advertising / Coded PHY for long range).
- **Packet Format (28 bytes Legacy Frame)**:
  - `Header` (2 bytes): Magic `0x47, 0x44` ("GD" for Garuda).
  - `PacketType` (1 byte): `0x01` = SOS Telemetry, `0x02` = Mesh Chat, `0x03` = Heartbeat / Ack.
  - `PacketId` (4 bytes): CRC32 / truncated hash for unique packet deduplication.
  - `DeviceHash` (4 bytes): 32-bit user/device identifier.
  - `Timestamp` (4 bytes): Unix epoch seconds.
  - `Latitude` (4 bytes): Fixed-point `int32` (`lat * 1e6`).
  - `Longitude` (4 bytes): Fixed-point `int32` (`lon * 1e6`).
  - `EmergencyType & Triage` (1 byte): Bits 0-3: Emergency code (Trapped, Medical, Flood, Fire), Bits 4-7: Blood Group & Priority.
  - `HopCount & TTL` (1 byte): Bits 0-3: Current Hop Count (starts at 0, increments up to 7), Bits 4-7: Time-To-Live (decrements to 0).
  - `Checksum` (3 bytes): Packet integrity verification.
- **Relay Mechanism**:
  - Maintains an LRU memory cache of seen `PacketId`s.
  - When a packet is received via BLE scan: If not in cache and `TTL > 0`, decrement `TTL`, increment `HopCount`, update checksum, and schedule for re-advertisement for a randomized backoff interval (100ms - 800ms) to prevent broadcast storm.
- **Service**: Foreground service with notification channel `"Garuda Disaster Mesh Active"`.

---

### Part 2: Data Persistence, GPS Location & Cloud Sync Gateway (`:core:data`, `:core:network`)
- **Room Database**:
  - `SosPacketEntity`: Stores all generated and relayed SOS packets with status (`LOCAL`, `RELAYED`, `SYNCED_TO_CLOUD`).
  - `MeshMessageEntity`: Offline peer-to-peer chat history.
  - `HazardReportEntity`: Geo-tagged citizen reports with local image URI.
  - `ReliefShelterEntity`: Preloaded offline shelter list with coordinates, capacity, and supplies.
- **GPS Location Engine**: High-accuracy FusedLocationProvider fallback to last known location.
- **Uplink Sync Worker (`WorkManager`)**:
  - `ConnectivityManager.NetworkCallback` detects when Wi-Fi or Cellular data becomes active.
  - Immediately triggers `FirebaseSyncWorker`: queries unsynced packets from Room and writes batch documents to Firestore `disaster_sos/` collection.
  - Marks entities as `SYNCED_TO_CLOUD` upon completion.

---

### Part 3: Disaster Sensors, Crash Triggers & Power Saving (`:core:sensors`)
- **Fall & Impact Detector**:
  - Continuously samples Accelerometer & Gyroscope data using low-power sensor batching.
  - Detection algorithm: Peak acceleration $> 3.5g$ followed by $< 0.2g$ freefall / sudden impact and immobility for $> 5$ seconds.
  - Triggers a 15-second audible cancellation countdown before initiating emergency broadcast.
- **Hardware Button Trigger**:
  - Listens for 3 rapid power button presses (or volume combination) via a broadcast receiver / accessibility service helper.
- **Dead-Man Watchdog**:
  - When in disaster zone, prompts user every $N$ hours to confirm "I am OK". If unacknowledged within 10 minutes, triggers automatic SOS.
- **Adaptive Battery Throttling**:
  - `High Alert`: 100% duty cycle (continuous scanning and high-power advertising).
  - `Background Duty-Cycle`: Scans 5s, sleeps 25s (slashes battery consumption by ~80%).
  - `Extreme Survival Mode`: Forces AMOLED pure-black theme, dims brightness, disables non-essential animations.

---

### Part 4: Citizen UI, Standby/Active Emergency & SOS Core (`:feature:sos`, `:app`)
- **Standby Mode (Peace Time)**:
  - Clean UI: *"Status: Normal. No Disaster Detected in your Region."*
  - Offline Survival Manuals, Earthquake/Flood/Cyclone checklists, First Aid guidelines.
  - Family Circle setup & Medical Profile card.
- **Government Emergency Activation Handler**:
  - Receives high-priority FCM push notification from Government Command Mac App.
  - Triggers full-screen alert: *"EMERGENCY ACTIVATED BY NDMA / STATE DISASTER AUTHORITY"*.
  - Unlocks active emergency mode and spins up the BLE mesh engine.
- **Active Emergency Mode**:
  - Big Red SOS Panic Button with 5-second cancel countdown.
  - Active broadcast indicator showing nearby peer count and hop relay count.
  - "I am Safe" one-tap check-in with automated SMS fallback to emergency contacts.

---

### Part 5: Offline Mesh Chatroom & Relief Services (`:feature:chat`, `:feature:relief`)
- **Offline P2P Mesh Chatroom**:
  - Local broadcast channel: "Nearby Survivors & Volunteers".
  - Messages framed into the binary protocol (or fragmented if $> 28$ bytes in BLE 5.0) and hopped across the mesh.
  - Displays sender distance/hops (e.g. *"1 hop away (~30m)"*).
- **Hybrid Shelter Radar**:
  - When online: Interactive Google Map showing active relief shelters, capacity, and food/medical aid availability.
  - When offline: GPS Compass Bearing radar arrow pointing directly to the closest shelter with real-time distance in meters/kilometers.
- **Crowdsourced Hazard & Damage Reporting**:
  - Camera capture for photo of damaged infrastructure (bridge collapsed, road blocked, live wire).
  - Stores report locally in Room DB queue and auto-uploads when internet is regained.
- **Missing Persons Hub**:
  - Offline searchable directory of reported missing persons with photos, last seen coordinates, and contact details.

---

### Part 6: macOS Government Command Center (`garuda-macos`)
- **Stack**: Native SwiftUI on macOS with MapKit, CoreLocation, and Firebase Swift SDK.
- **Features**:
  - **Live MapKit GIS Dashboard**: Real-time victim pins, heatmap density, color-coded triage (Red = Critical/Trapped, Orange = Injured, Yellow = Assistance Needed, Green = Safe), hop-relay lineage tracking.
  - **Emergency Dispatch & Triage Board**: Kanban view (Pending -> Dispatched -> Rescued) for NDRF / SDRF / Volunteer teams.
  - **Government Emergency Activation Issuer**: Interactive regional map selector (or district dropdown) to send official emergency activation broadcasts via FCM Push API.
  - **Citizen Hazard Photo Reviewer**: Visual inspection panel of crowd-sourced damage photos to mark danger zones on the live map.

---

## Gradle Multi-Module Structure

```
Garuda/
├── app/                      # Application entry point, NavHost, DI wiring
├── core/
│   ├── model/                # Common Kotlin data classes & packet models
│   ├── mesh/                 # BLE Advertiser, Scanner, Relay Engine, Protocol
│   ├── data/                 # Room Database, Daos, Repositories, WorkManager
│   ├── network/              # Firebase Firestore, FCM Service, Network Monitor
│   └── sensors/              # Fall detection, Power button listener, Dead-man timer
└── feature/
    ├── sos/                  # Standby & Active SOS Compose Screens, Panic Button
    ├── chat/                 # Offline P2P Mesh Chatroom UI
    └── relief/               # Hybrid Shelter Radar, Hazard Reporter, Missing Persons
```

---

## Verification Plan

### Automated Tests
- **Unit Tests (`:core:mesh`)**:
  - Binary Packet Encoding/Decoding integrity test: serialize packet to byte array, verify exact 28-byte size, deserialize and assert field equality.
  - Hop/TTL decrement logic test: verify packet drops when TTL reaches 0.
  - Deduplication cache test: verify seen packet is ignored.
- **Unit Tests (`:core:data`)**:
  - Room DAO unit tests using in-memory database (`SosDaoTest`, `MessageDaoTest`).
- **Sensor Tests (`:core:sensors`)**:
  - Fall detector algorithm mathematical unit tests with simulated accelerometer time-series data.

### Manual Verification
- Two Android test devices (or emulator + physical phone) running BLE advertising/scanning.
- Verify packet hopping: Device A triggers SOS offline -> Device B (offline) receives and re-broadcasts -> Device C (online) receives and uploads to Firebase Firestore.
- Run macOS SwiftUI app: verify pin immediately drops on MapKit when Firebase Firestore receives the SOS packet.
