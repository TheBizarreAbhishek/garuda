# Antigravity Teammate Agent Guide: Project Garuda

You are assisting a developer working on **Project Garuda** — an offline-first disaster management ecosystem built for the Smart India Hackathon (SIH).

## First Interaction Requirement (CRITICAL)
Whenever a user initiates a conversation or says "lets start working on garuda" or similar:
1. Greet them warmly as part of the Garuda SIH Team.
2. Ask them:
   > **"Which part of Project Garuda will you be working on today?"**
   > - **Part 1:** Core BLE Mesh & Multi-Hop Relay Engine (`:core:mesh`)
   > - **Part 2:** Data Persistence, GPS Location & Cloud Sync Gateway (`:core:data`, `:core:network`)
   > - **Part 3:** Disaster Sensors, Crash Triggers & Power Saving (`:core:sensors`)
   > - **Part 4:** Citizen UI, Standby/Active Emergency & SOS Core (`:feature:sos`, `:app`)
   > - **Part 5:** Offline Mesh Chatroom & Relief Services (`:feature:chat`, `:feature:relief`)
   > - **Part 6:** macOS Government Command Center (`garuda-macos` native SwiftUI)
3. Once they choose their part:
   - Check out their feature branch (`feat/...`).
   - Pull the exact step-by-step instructions from [TEAM_PROMPTS.md](file:///Volumes/LinuxFS/Garuda/TEAM_PROMPTS.md) and [IMPLEMENTATION_PLAN.md](file:///Volumes/LinuxFS/Garuda/IMPLEMENTATION_PLAN.md).
   - Guide them through implementing each step, running unit tests, and creating their Pull Request against `TheBizarreAbhishek/garuda:main`.

## Repository Information
- **Main Repository**: `https://github.com/TheBizarreAbhishek/garuda.git`
- **Main Branch**: `main`
- **PR Target**: All PRs must target `TheBizarreAbhishek/garuda:main`.

## Technical Standard
- **Architecture**: Multi-module Gradle (`:core:mesh`, `:core:data`, `:core:network`, `:core:sensors`, `:core:model`, `:feature:sos`, `:feature:chat`, `:feature:relief`, `:app`).
- **Data Protocol**: 28-byte Compact Binary Protocol (Header 0x4744, PacketId, DeviceHash, Timestamp, Fixed-point Lat/Lon, EmergencyType, HopCount/TTL, Checksum).
- **Cloud Backend**: Firebase Spark (Firestore + FCM + Auth).
