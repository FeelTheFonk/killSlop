# killSlop

```text
 _    _ _ _ _____ _           
| |  (_) | |  ___| |          
| | ___| | | \ `--.| | ___  _ __ 
| |/ / | | |  `--. \ |/ _ \| '_ \
|   <| | | | /\__/ / | (_) | |_) |
|_|\_\_|_|_| \____/|_|\___/| .__/ 
                           | |    
                           |_|    
```

![Version](https://img.shields.io/badge/Version-0.2.0--stealth-blue?style=flat-square)
![Vector](https://img.shields.io/badge/Vector-Fileless_In--Memory-b71c1c?style=flat-square)
![Platform](https://img.shields.io/badge/Platform-Windows_11_24H2-0078D4?style=flat-square)

**killSlop** is an aggressive, zero-drop, fileless automation suite engineered to neutralize specific operating system security services. Operating exclusively in-memory after initial deployment, it utilizes a Safe Mode registry injection vector and an obfuscated RunOnce staging mechanism to execute kernel-bypass operations without leaving conventional disk-based forensic artifacts.

## Architecture & Operational Flow

The execution relies on a multi-stage, zero-noise architecture executing across standard and Safe Mode environments.

### System State Transitions
```mermaid
stateDiagram-v2
    direction LR

    classDef dark fill:#121212,stroke:#424242,stroke-width:2px,color:#e0e0e0
    classDef inject fill:#0d47a1,stroke:#1565c0,stroke-width:2px,color:#fff
    classDef mem fill:#b71c1c,stroke:#d32f2f,stroke-width:2px,color:#fff

    state "Normal Mode (Initial)" as NM1
    state "Registry Injection" as RegInj
    state "Safe Mode (Boot)" as SM_Boot
    state "RunOnce Stager" as SM_Stager
    state "In-Memory Payload" as SM_Mem
    state "Normal Mode (Post-Op)" as NM2

    NM1 --> RegInj : 1_prepare_safemode.ps1
    RegInj --> SM_Boot : Reboot (Safeboot BCD)
    SM_Boot --> SM_Stager : OS Logon Trigger
    SM_Stager --> SM_Mem : IEX (Memory Stream)
    SM_Mem --> NM2 : Registry Burn & Reboot

    class NM1,NM2,SM_Boot dark
    class RegInj inject
    class SM_Stager,SM_Mem mem
```

### Components Verification

#### 1. The Injector (`1_prepare_safemode.ps1`)
Operates under Administrative privileges to prep the environment.
- Validates token constraints (`IsInRole(544)`).
- Interlocks logic via a silent parametric bypass (`-Confirm`).
- Injects a pre-compiled, Base64-encoded and Deflate-compressed payload into `HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\WindowsUpdate` under the camouflage property `InstallDate`.
- Stages an obfuscated inline PowerShell command in `HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce`.
- Mutates Boot Configuration Data (BCD) for `safeboot network`.
- Executes hard asynchronous restart.

#### 2. The In-Memory Payload (Ex-`2_kill_defender`)
The true operational core exists solely in RAM.
- **Activation**: Triggered by the *RunOnce* stager passing the Base64 registry payload through a `DeflateStream` direct to `Invoke-Expression` (IEX).
- **Execution**: Compiles the `TokenManipulator` struct via reflection (`Add-Type`) to seize `SeTakeOwnershipPrivilege` and `SeRestorePrivilege`.
- **Targeting**: Automatically overrides Registry Access Control Lists (ACLs) to assert NT AUTHORITY owner rights. Modifies the `Start` DWORD to `4` (Disabled) for the following services: `WinDefend`, `Sense`, `WdFilter`, `WdNisSvc`, `WdNisDrv`, `wscsvc`, `SgrmBroker`, `SgrmAgent`, `MDCoreSvc`, `webthreatdefusersvc`, `SenseCncProxy`.
- **Annihilation**: Purges scheduled tasks (`\Microsoft\Windows\Windows Defender\*`) and injects Group Policy overrides.
- **Scrubbing**: The memory-bound payload forcefully removes its origin vector (`InstallDate` key) from the registry, clears the Safe Mode BCD entry, and immediately fires `Restart-Computer -Force`.

#### 3. The Silent Auditor (`3_verify_status.ps1`)
Operates as a fail-fast boolean confirmation sequence.
- Parses running processes and kernel service registries.
- Omits all visual output.
- Returns `Exit 0` upon confirmation of systemic neutralization. Returns `Exit 1` if active threats or incorrect service states exist.

## Deployment Strategy

Requirements:
1. Base privileges: `Administrator`
2. Tamper Protection: Disabled (System constraint pre-requisite).

Execution:
```powershell
# Mandatory confirmation switch required to avoid accidental discharge
.\1_prepare_safemode.ps1 -Confirm
```

## Security Posture & Traces

This mechanism abandons telemetry, logging, and restore points to ensure absolute stealth. 

**Forensic Footprint:**
- **Disk Drop**: 0 bytes. The `2_kill_defender.ps1` file has been structurally absorbed.
- **Registry**: Transient. Staging keys are deleted post-execution by the payload running within memory space.
- **Logs**: Disabled. No script transcription or operational records are written to the host filesystem.

***

*Subject to exhaustive code reviews and strict syntax requirements (`Invoke-ScriptAnalyzer` compliant, 0 severity).*
