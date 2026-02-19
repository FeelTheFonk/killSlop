# killSlop

**Version:** 1.0.0-SOTA (Unified Climax)
**Vector:** Fileless In-Memory
**Platform:** Windows 11 24H2

## 1. Objectif & Cadre d'Opération

**killSlop** est une suite d'automatisation offensive SOTA (State of The Art) 2026. Son objectif exclusif est l'annihilation simultanée, furtive et irréversible des **services de sécurité système (Defender/EDR)** et de l'**infrastructure de Télémétrie/I-O Polling (ETW, WaaSMedic, SysMain)**. 

Conçue sous le paradigme d'empreinte zéro (Zero-Drop footprint), l'architecture opère en mémoire vive (RAM) de manière isolée. L'exécution s'articule autour d'un vecteur d'injection registre (Safe Boot) et d'un mécanisme de "staging" RunOnce extrêmement compressé, permettant un contournement Kernel (Kernel-Bypass) sans générer d'artéfacts forensiques.

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

    NM1 --> RegInj : i.ps1
    RegInj --> SM_Boot : Reboot (Safeboot BCD)
    SM_Boot --> SM_Stager : OS Logon Trigger
    SM_Stager --> SM_Mem : IEX (Memory Stream)
    SM_Mem --> NM2 : Registry Burn & Reboot

    class NM1,NM2,SM_Boot dark
    class RegInj inject
    class SM_Stager,SM_Mem mem
```

## 3. Composants SOTA & Furtivité

L'architecture legacy fragmentée a été abolie. Le repo se concentre sur deux composants ultra-densifiés :

### 3.1 `i.ps1` (L'Injecteur)
Opère sous privilèges administratifs stricts (`IsInRole(544)`).
Charge un flux `DeflateStream` Base64 monolithique (Defender + Silence) dans la ruche système (Propriété de camouflage: `InstallDate`). Modifie le BCD et reboot.

### 3.2 Le Payload In-Memory (`src/p.ps1`)
Noyau opérationnel exclusif en RAM. Ses macros-actions :
1.  **Abus de Privilèges :** Capture du `SeTakeOwnershipPrivilege` (NT AUTHORITY) via réflexion C#.
2.  **Neutralisation EDR/AV :** Destruction de `WinDefend`, `WdFilter`, `Sense`, `SgrmBroker`, etc.
3.  **Ablation Télémétrie & I/O :** Neutralisation de `DiagTrack`, `WaaSMedicSvc`, `SysMain`.
4.  **Extinction ETW :** Shutdown des Autologgers (`AutoLogger-Diagtrack-Listener`, `LwtNetLog`, etc).
5.  **Excision Forensique (Burn-After-Reading) :** Autodestruction de la clé `InstallDate` encodée et du profil SafeBoot BCD.

### 3.3 `c.ps1` (Silent Auditor)
Séquence booléenne validant 19 vecteurs d'attaque. Sortie asymptotique sans écho. (`Exit 0` succès, `Exit 1` échec).

## 4. Déploiement

Prérequis stricts et rigides, toute omission provoque la terminaison prématurée du processus.

*   Droits requis: `Administrateur`.
*   Condition initiale: `Tamper Protection: Disabled`.

Exécution exigée avec commutateur de confirmation:
```powershell
.\i.ps1 -Confirm
```

## 5. Posture de Sécurité & Empreinte

Système de "Zero-Drop", abandonnant activement toutes notions de logs ou traces.
*   **Disque:** `0` octet additionnel généré post-déploiement.
*   **Registre:** Modification transitoire (O/1). Auto-effacement total validé en RAM.
*   **Linter Compliance:** Validité totale sous `Invoke-ScriptAnalyzer` (`Severity 0`).
