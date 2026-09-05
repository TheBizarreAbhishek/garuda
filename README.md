# Project Garuda 🦅
### Offline-First Disaster Management & Multi-Hop BLE Mesh Grid for NDMA & Citizens
**Smart India Hackathon (SIH 2026)** • *Zero-Cellular • Zero-Internet • Multi-Hop Resilient*

---

## 📌 Executive Summary
During catastrophic disasters (cyclones, landslides, flash floods, earthquakes), cellular towers and power grids are often the first infrastructure to collapse, stranding citizens without communication or emergency services. 

**Project Garuda** is a decentralized, offline-first disaster response ecosystem that turns ordinary citizen smartphones into autonomous **Bluetooth Low Energy (BLE) Multi-Hop Mesh Nodes**, relaying SOS distress beacons, walkie-talkie voice notes, verified hazard reports, and shelter telemetry across kilometers without active internet, cellular connectivity, or SIM cards.

The system connects seamlessly with the **Garuda macOS Government Command Center**, enabling district magistrates, NDRF, and NDMA teams to monitor real-time ground GIS telemetry, verify community hazards with live camera geotags, and dispatch geofenced evacuation directives.

---

## 🌟 Key Features & Capabilities

### 📱 1. Citizen Mobile Application (Android • Jetpack Compose)
* **Real-Time BLE Mesh Peer Discovery:** Sliding-window active peer counter with live RF status (`🟢 Peers: N`).
* **Emergency SOS Distress Core:** 5-second cancelable countdown, high-decibel alarm, device-level auto-SMS distress dispatch, and zero-internet multi-hop packet broadcast.
* **Decentralized Mesh Chat & Walkie-Talkie:**
  * **Public Mesh (All):** Broadcast channel for open neighborhood relief coordination.
  * **Private Direct (Family):** Point-to-point direct encrypted messaging with 1-tap Copy ID and contact registry.
  * **Push-To-Talk (PTT) Voice Notes:** Offline compressed audio recording & instant mesh transmission.
* **Anti-Hoax Hazard Reporting with Live Camera Proof:** Geotagged camera capture (`TakePicturePreview`) stamping exact GPS coordinates and live thumbnail proof to prevent false panic.
* **Live Relief Shelter Radar:** District-aware and GPS distance-sorted shelter finder with bed capacity, medical availability, and offline compass bearings.
* **Standby Mode & Survival Kits:** 72-hour Go-Bag checklist, earthquake/flood readiness guides, and offline medical profile cards (Blood group, allergies, emergency contacts).

### 🖥️ 2. Government Command Center (macOS • Native SwiftUI)
* **Multi-Region Geofenced Emergency Dispatcher:** Target single or multi-district zones with precise geofencing (e.g. `Prayagraj (Allahabad); Wayanad (Kerala)`) and instant cloud-mesh synchronization.
* **Connected Devices & Mesh Network Registry:** Real-time visibility into all field ground nodes (Direct Cloud vs BLE Multi-Hop Relayed), tracking battery percentage, GPS position, and hop distance.
* **Live Interactive GIS Map:** Multi-layer map rendering SOS survivors, verified hazard spots, safe shelter zones, and active mesh nodes.
* **IMD Satellite & Doppler Weather Radar:** Embedded INSAT-3D/3DR satellite imagery and precipitation radar loops for real-time storm and cyclone tracking.
* **Survivor Triage & Rescue Management:** Live priority queue (Immediate, Delayed, Minimal) with 1-click status updates and offline CSV reporting.

---

## 🛰️ Architecture & Compact Binary Mesh Protocol

```
+-----------------------------------------------------------------------------------+
|                            GARUDA DISASTER GRID                                   |
+-----------------------------------------------------------------------------------+
|  [Citizen A]  ---(BLE Multi-Hop)--->  [Citizen B]  ---(BLE)--->  [Relay Gateway]  |
|  (No Internet)                        (No Internet)              (Edge Internet)  |
|                                                                         |         |
|                                                                 (HTTPS / Firestore|
|                                                                         v         |
|                                                                [Firebase Cloud]   |
|                                                                         |         |
|                                                                (Real-Time Sync)   |
|                                                                         v         |
|                                                          [macOS Command Center]   |
+-----------------------------------------------------------------------------------+
```

### 📦 24-Byte Compact Binary Protocol Packet Structure
To ensure 100% transmission reliability across diverse Android chipsets without hitting legacy 31-byte BLE advertising truncation, Project Garuda uses an optimized 24-byte binary frame:

| Offset (Bytes) | Field Name | Type / Encoding | Description |
| :--- | :--- | :--- | :--- |
| `0x00 - 0x01` | **Sync Header** | `0x4744` ("GD") | Magic byte identifier |
| `0x02 - 0x03` | **Packet ID** | 16-bit Integer | Unique sequence identifier for LRU deduplication |
| `0x04 - 0x07` | **Device Hash** | 32-bit Integer | Hardware/UUID pseudo-hash of origin node |
| `0x08 - 0x0B` | **Timestamp** | 32-bit Unix Epoch | Packet creation timestamp |
| `0x0C - 0x0F` | **Latitude** | 32-bit Fixed Point | Micro-degrees latitude ($Lat \times 10^6$) |
| `0x10 - 0x13` | **Longitude** | 32-bit Fixed Point | Micro-degrees longitude ($Lon \times 10^6$) |
| `0x14` | **Emergency / Type** | 8-bit Enum | SOS type (`0x01` Medical, `0x02` Trap, `0x03` Heartbeat, `0x05` Hazard) |
| `0x15` | **Hop Count & TTL** | 8-bit Bitmask | High 4-bits: Hop Count, Low 4-bits: TTL |
| `0x16 - 0x17` | **Checksum (CRC16)**| 16-bit CRC | Data integrity and error detection |

---

## 📂 Project Structure & Multi-Module Architecture

```
garuda/
├── app/                                 # Android Citizen Application
│   ├── src/main/java/com/project/garuda/
│   │   ├── audio/                       # WalkieTalkie audio recorder & player
│   │   ├── data/                        # Local persistence (Contacts, UUID hash)
│   │   ├── network/                     # FirebaseCloudGateway (Cloud sync)
│   │   └── ui/                          # Jetpack Compose UI Screens
│   │       ├── chat/                    # MeshChatScreen (Public & Private)
│   │       ├── hazards/                 # HazardDirectoryScreen (Photo proof)
│   │       ├── shelter/                 # ShelterRadarScreen (Distance radar)
│   │       └── sos/                     # StandbyScreen, ActiveEmergency, CitizenVM
├── core/
│   ├── mesh/                            # BleAdvertiserManager, BleScannerManager, MeshRelayEngine
│   ├── data/                            # Room database, repositories, offline storage
│   ├── network/                         # Cloud sync & MQTT/HTTP edge connectors
│   ├── sensors/                         # Crash detection, accelerometer, barometer triggers
│   └── model/                           # Domain data models & entities
└── garuda-macos/                        # Native macOS SwiftUI Command Center
    └── Sources/GarudaCommandCenter/     # Dashboard, LiveMapView, ImdSatelliteRadarView, etc.
```

---

## 🛠️ Tech Stack

* **Mobile (Android):** Kotlin, Jetpack Compose, Material 3, Coroutines & Flow, Android BLE Stack, CameraX, Android AudioRecorder/MediaPlayer.
* **Desktop (macOS):** Swift 5.9, SwiftUI, MapKit, WebKit, Combine, Apple Network APIs.
* **Cloud & Edge Backend:** Firebase Firestore, Firebase Cloud Messaging (FCM), Cloud Functions.
* **Testing & Quality:** JUnit 5, MockK, AndroidX Test, Robolectric.

---

## 🚀 Getting Started

### 1. Android Citizen App
```bash
# Clone the repository
git clone https://github.com/TheBizarreAbhishek/garuda.git
cd garuda

# Build debug APK
./gradlew assembleDebug

# Install on connected Android device via ADB
adb install -r app/build/outputs/apk/debug/app-debug.apk
```

### 2. macOS Command Center
```bash
cd garuda-macos

# Build and run native macOS application
swift run GarudaCommandCenter
```

---

## 👥 Contributors & SIH 2026 Team
Built with ❤️ by **Team Garuda** for the **Smart India Hackathon (SIH 2026)**.
