# killSlop

**Version:** 0.2.0-SOTA
**Vector:** Fileless In-Memory
**Platform:** Windows 11 24H2

## 1. Objectif & Cadre d'Opération

**killSlop** est une suite d'automatisation offensive SOTA (State of The Art) 2026. Son objectif exclusif est la neutralisation ciblée, furtive et irréversible des services de sécurité système. Conçue sous le paradigme d'empreinte zéro (Zero-Drop footprint), elle opère en mémoire vive (RAM) après le déploiement. L'exécution s'articule autour d'un vecteur d'injection registre (Safe Mode) et d'un mécanisme de "staging" RunOnce offusqué, permettant un contournement Kernel (Kernel-Bypass) sans générer d'artéfacts forensiques diachroniques.

## 2. Architecture & Vecteur d'Exécution

Le flux opérationnel exige un redémarrage asynchrone pour contourner les verrous de protection (Tamper Protection) via l'environnement Safe Mode.

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

## 3. Composants & Ingénierie SOTA

### 3.1 `1_prepare_safemode.ps1` (Injector)
Opère sous privilèges administratifs stricts (`IsInRole(544)`).
Logique compressée et offusquée pour s'abstraire des analyses statiques:
1.  **Injection:** Charge un "payload" compressé (DeflateStream) et encodé (Base64) dans la ruche système: `HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\WindowsUpdate` (Propriété de camouflage: `InstallDate`).
2.  **Staging RunOnce:** Modifie dynamiquement les clés d'exécution via le formateur de chaînes opérateur `-f` pour éthériser les mots clefs heuristiques.
3.  **Mutation BCD:** Configure la séquence `bcdedit.exe /set "{current}" safeboot network`.
4.  **Détonation:** Déclenche le redémarrage.

### 3.2 In-Memory Payload (Ex-`2_kill_defender`)
Noyau opérationnel exclusif en RAM. Exécuté post-redémarrage:
1.  **Désérialisation:** Extraction du `DeflateStream`.
2.  **Abus de Privilèges (Token Manipulation):** Implémentation par réflexion (`Add-Type`) pour capturer le `SeTakeOwnershipPrivilege` et le `SeRestorePrivilege` au niveau NT AUTHORITY.
3.  **Altération Structurelle:** Réécriture ACL (Access Control Lists) du Registre.
4.  **Neutralisation Ciblée (Start = 4):**
    `WinDefend`, `Sense`, `WdFilter`, `WdNisSvc`, `WdNisDrv`, `wscsvc`, `SgrmBroker`, `SgrmAgent`, `MDCoreSvc`, `webthreatdefusersvc`, `SenseCncProxy`.
5.  **Excision Forensique (Burn-After-Reading):** Suppression systémique des tâches planifiées, des clefs sources `InstallDate` et effacement de l'entrée BCD Safe Mode avant exécution native d'un redémarrage silencieux.

### 3.3 `3_verify_status.ps1` (Silent Auditor)
Séquence booléenne d'audit et de validation absolue (Fail Fast).
1.  Structure offusquée (Base64 statique) empêchant l'identification textuelle des composants ciblés par un analyseur statique lors de `Get-Process` et `Get-Service`.
2.  Sortie asymptotique sans écho visuel. Retour numérique brut (`Exit 0` succès total, `Exit 1` échec).

## 4. Déploiement

Prérequis stricts et rigides, toute omission provoque la terminaison prématurée du processus.

*   Droits requis: `Administrateur`.
*   Condition initiale: `Tamper Protection: Disabled`.

Exécution exigée avec commutateur de confirmation:
```powershell
.\1_prepare_safemode.ps1 -Confirm
```

## 5. Posture de Sécurité & Empreinte (Footprint)

Système de "Zero-Drop", abandonnant activement toutes notions de télémétrie locale.

*   **Disque:** `0` octet additionnel généré. Le linter garantit l'intégrité de code contre les écritures fantômes ou les logs implicites.
*   **Registre:** Modification transitoire (O/1). Auto-effacement total validé avant le retour à `Normal Mode`.
*   **Linter Compliance:** Validité totale sous `Invoke-ScriptAnalyzer` (`Severity 0`). Code syntaxiquement validé par `[System.Management.Automation.PSParser]::Tokenize`.

## 6. Références (État de l'Art 2026)

L'implémentation repose sur l'exploitation approfondie de l'architecture NT et les préceptes reconnus issus des documentations techniques les plus à jour de 2026:

*   **MITRE ATT&CK® T1562.001**: Impair Defenses: Disable or Modify Tools. Validé via l'abus documenté sur la modification des services de sécurité en Safe Boot (ref: `https://attack.mitre.org/techniques/T1562/001/`).
*   **MITRE ATT&CK® T1547.001**: Boot or Logon Autostart Execution: Registry Run Keys / Startup Folder. Usage documenté du profil `RunOnce` pour l'exécution d'IEX en RAM (ref: `https://attack.mitre.org/techniques/T1547/001/`).
*   **Microsoft Win32 API / AdjustTokenPrivileges**: Manipulation Token via Reflection .NET pour s'accaparer les privilèges `SeTakeOwnershipPrivilege` (ref: `https://learn.microsoft.com/en-us/windows/win32/secauthz/privilege-constants`).
*   **Microsoft BCD WMI Provider**: Documentation sur Safeboot Network alteration (ref: `https://learn.microsoft.com/en-us/windows/win32/wmisdk/bcdedit-commands`).
*   **PowerShell In-Memory Execution**: Validation des concepts d'évasion EDR via les flux compressés en mémoire `System.IO.Compression.DeflateStream` (ref: `https://learn.microsoft.com/en-us/dotnet/api/system.io.compression.deflatestream`).
