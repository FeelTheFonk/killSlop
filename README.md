# killSlop

![Version](https://img.shields.io/badge/Version-0.0.1-blue?style=flat-square)
![Platform](https://img.shields.io/badge/Platform-Windows%2011%2024H2-0078D4?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-gray?style=flat-square)

**killSlop** is a PowerShell automation suite designed to neutralize Microsoft Defender services and drivers on Windows 11 systems. It employs a Safe Mode Registry Injection vector with automatic ACL (Access Control List) modification to disable protected kernel-level components.

## Architecture

The protocol executes in three distinct phases, utilizing a reboot cycle to transition between **Normal Mode** (Ring 3 check/prep) and **Safe Mode** (Kernel bypass).

### 1. Global Lifecycle
High-level view of the system state transitions.

```mermaid
stateDiagram-v2
    direction LR

    classDef dark fill:#212121,stroke:#666,stroke-width:2px,color:#fff
    classDef norm fill:#0d47a1,stroke:#64b5f6,stroke-width:2px,color:#fff
    classDef safe fill:#b71c1c,stroke:#ff5252,stroke-width:2px,color:#fff

    state "Normal Mode (Initial)" as NM1
    state "Reboot (Safe Boot)" as Reboot_1
    state "Safe Mode (Networking)" as SM
    state "Reboot (Normal)" as Reboot_2
    state "Normal Mode (Post-Op)" as NM2

    NM1 --> Reboot_1 : 1_prepare_safemode.ps1
    Reboot_1 --> SM : BCD safeboot network
    SM --> Reboot_2 : 2_kill_defender.ps1 (RunOnce)
    Reboot_2 --> NM2 : BCD safeboot removed

    note right of NM1
        * Admin Check
        * Restore Point
        * Payload Staging
    end note

    note right of SM
        * ACL Takeover
        * Service Disable
        * GPO Injection
    end note

    note right of NM2
        * User Verification
        * Artifact Cleanup
    end note

    class NM1,NM2 norm
    class SM safe
    class Reboot_1,Reboot_2 dark
```

### 2. Phase 1: Preparation Vector
Detailed logic flow of `1_prepare_safemode.ps1`.

```mermaid
graph TD
    %% Styling - Dark Mode SOTA
    classDef check fill:#004d40,stroke:#00e5ff,stroke-width:2px,color:#fff;
    classDef action fill:#1b5e20,stroke:#69f0ae,stroke-width:2px,color:#fff;
    classDef critical fill:#b71c1c,stroke:#ff8a80,stroke-width:2px,color:#fff;
    classDef system fill:#e65100,stroke:#ffcc80,stroke-width:2px,color:#fff;

    Start(["Start: 1_prepare_safemode.ps1"]) --> AdminCheck{"Admin Privileges?"}
    AdminCheck -- No --> Exit1[Exit: Fatal Error]:::critical
    AdminCheck -- Yes --> SafetyCheck{"24H2 Safety Interlock<br/>(User Confirmation)"}:::check

    SafetyCheck -- "No Password / Cancel" --> Exit2[Exit: Safety Abort]:::critical
    SafetyCheck -- "Confirmed" --> TamperCheck{"Tamper Protection<br/>Disabled?"}:::check

    TamperCheck -- No --> Exit3[Exit: Manual Action Req]:::critical
    TamperCheck -- Yes --> RestorePoint["Create Restore Point<br/>Checkpoint-Computer"]:::action

    RestorePoint --> StagePayload["Stage Payload<br/>C:\DefenderKill\2_kill_defender.ps1"]:::action
    StagePayload --> GPOPre["Remove GPO Blockers<br/>DisableRunOnce"]:::action
    GPOPre --> InjectRunOnce["Inject RunOnce Trigger<br/>Key: *killSlop_Payload<br/>Value: Powershell -File ..."]:::critical

    InjectRunOnce --> SetSafeBoot["BCD Set Safeboot Network"]:::system
    SetSafeBoot --> Restart["System Restart"]:::system
```

### 3. Phase 2: Neutralization (The Kill)
Detailed logic flow of `2_kill_defender.ps1` executing in Safe Mode.

```mermaid
graph TD
    %% Styling - Dark Mode SOTA
    classDef loop fill:#4a148c,stroke:#ea80fc,stroke-width:2px,stroke-dasharray: 5 5,color:#fff;
    classDef attack fill:#b71c1c,stroke:#ff5252,stroke-width:2px,color:#fff;
    classDef config fill:#0d47a1,stroke:#82b1ff,stroke-width:2px,color:#fff;
    classDef exit fill:#212121,stroke:#cfd8dc,stroke-width:2px,color:#fff;

    Start(["Start: RunOnce Auto-Run"]):::exit --> LogStart["Init Logging<br/>C:\DefenderKill\log.txt"]:::config
    LogStart --> ServiceLoop[["Loop: Target Services"]]:::loop
    
    subgraph Service Neutralization
        ServiceLoop --> ACL["Grant-RegistryAccess<br/>TakeOwnership + FullControl"]:::attack
        ACL --> DisableSvc["Set Start = 4 (Disabled)"]:::attack
        DisableSvc --> NextSvc{"More Services?"}
        NextSvc -- Yes --> ServiceLoop
    end
    
    NextSvc -- No --> TaskKill["Disable Scheduled Tasks<br/>\Microsoft\Windows\Windows Defender\*"]:::attack
    
    TaskKill --> GPOInject[["Inject Group Policies"]]:::config
    
    subgraph GPO Overrides
        GPOInject --> DefPol["DisableAntiSpyware = 1"]
        GPOInject --> RTPol["DisableRealtimeMonitoring = 1"]
        GPOInject --> SpyNet["SubmitSamplesConsent = 2"]
    end
    
    SpyNet --> CleanBoot["BCD Delete Safeboot"]:::config
    CleanBoot --> Reboot["Restart System"]:::exit
```

## Prerequisites

1.  **Tamper Protection Disabled:** Must be turned off manually in *Windows Security > Virus & threat protection > Manage settings*.
2.  **Microsoft Account Password:** Required for Safe Mode login if Windows Hello PIN is unavailable (Windows 11 24H2 constraint).
3.  **Administrator Privileges:** Required for all scripts.

## Usage

1.  **Preparation:**
    Run `1_prepare_safemode.ps1` with PowerShell (Admin).
    Confirm safety checks when prompted.

2.  **Execution (Automated):**
    The system will reboot into Safe Mode with Networking.
    The payload (`2_kill_defender.ps1`) will execute automatically.
    The system will reboot back to normal mode.

3.  **Verification:**
    Run `3_verify_status.ps1` to inspect service states and logs.
    Logs are stored at `C:\DefenderKill\killSlop_log.txt`.

## Operational Impact (SOTA Analysis)

Disabling kernel-level security modules has distinct side effects. This protocol is designed to minimize instability, but users must be aware of the following 2026-era consequences:

| Component | Status | Impact Analysis |
| :--- | :--- | :--- |
| **Windows Update** | [Partial] | Core OS updates will continue. Updates specific to Defender (Intelligence/Engine) will fail. |
| **Microsoft Store** | [Stable] | Store Apps generally function. Some banking/enterprise apps requiring "Device Health Attestation" may refuse to run. |
| **Network Stack** | [Optimized] | `WdNisDrv` (Network Inspection) removal eliminates packet inspection overhead. No known stack breakage in 24H2. |
| **System Stability** | [Low Risk] | Removing `WdFilter.sys` prevents minifilter conflicts (`sprotect.sys`), potentially *reducing* BSODs on specific NVMe hardware. |
| **Security Center** | [Disabled] | The UI will report "Unknown" or be inaccessible. Notifications will cease. |

## Disclaimer

This software disables critical security features. It is intended for specialized environments (e.g., benchmark rigs, offline compute nodes) where background interference must be eliminated. Use at your own risk.
