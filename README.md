# killSlop

**Version:** 1.0.1
**Vecteur d'Exécution:** Fileless In-Memory (Safe Mode Stager)
**Plateforme Cible:** Windows 11 (24H2)

## 1. Philosophie et Périmètre

`killSlop` est un outil d'administration asynchrone conçu pour la neutralisation ciblée et irréversible des composants de télémétrie, des routines d'E/S en arrière-plan, et des services de sécurité embarqués (Defender/EDR). 

L'architecture repose sur un principe d'**empreinte nulle (Zero-Drop)** :
*   Aucun binaire n'est déposé sur le disque de la machine cible.
*   L'intégralité du code asymétrique s'exécute en mémoire vive (RAM) via un flux compressé (`DeflateStream`).
*   L'élévation de privilèges (Acquisition de `SeTakeOwnershipPrivilege`) se fait via réflexion C# `.NET` native, s'affranchissant des utilitaires tiers.
*   L'opération nettoie asynchroniquement ses propres clés de registre d'injection avant de restituer l'environnement standard.

Ce projet s'adresse à des environnements maîtrisés (postes dédiés à la performance stricte, machines d'analyse isolées) où les cycles CPU, l'IOPS, et la bande passante réseau ne doivent subir aucune interférence de l'OS.

## 2. Architecture Technique

La séquence d'exécution exploite le passage par le **Safe Mode** pour contourner le verrouillage (`Tamper Protection`) des ruches de registre et des ACL des services Windows.

1.  **Phase d'Injection Normale (`i.ps1`) :** Le script d'injection requiert les privilèges Administrateur. Il encode la charge utile dans la clé `InstallDate` de Windows Update (`HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\WindowsUpdate`). Il inscrit ensuite une tâche de lancement asynchrone (RunOnce) ciblant l'exécutable PowerShell en mode non-interactif et masqué.
2.  **Modification d'Amorçage :** Le `bcdedit` est configuré pour forcer le prochain redémarrage en `safeboot network`. 
3.  **Phase Asynchrone (Safe Mode Logon) :** Le Stager s'exécute. Il désérialise, décompresse, et exécute en mémoire le flux contenant les instructions d'ablation.
4.  **Éradication & Restitution :** Les services ciblés sont passés en statut `4` (Désactivé), les tâches planifiées sont annihilées. L'injecteur nettoie la clé `InstallDate`, supprime l'indicateur `safeboot` du BCD, et déclenche le redémarrage final vers l'environnement standard.

## 3. Guide d'Exécution (How-To)

L'exécution doit être infaillible. Toute intervention humaine ou popup est proscrite durant la séquence.

### Prérequis
*   Tamper Protection : **Désactivé** (Nécessaire pour l'injection initiale).
*   Privilèges : **Administrateur local** exigé.

### Déploiement

Un point d'exécution unique, stable et pré-configuré est fourni via le script batch `run.bat`.

1.  Lancez le fichier `run.bat` d'un simple clic (ou depuis un terminal `cmd` / `powershell`).
2.  Le script gère dynamiquement l'élévation de privilèges UAC si nécessaire.
3.  Le script applique un `ExecutionPolicy Bypass` à l'instance pour éviter tout blocage pré-SafeMode.
4.  Il transfère le contrôle à l'injecteur silencié (`i.ps1 -Confirm`).
5.  Aucune interaction n'est requise de votre part. La machine redémarrera d'elle-même en Safe Mode, exécutera le nettoyage en millisecondes de manière invisible, puis redémarrera une seconde fois en mode normal.

### Audit Post-Opération

Pour valider cliniquement le succès du déploiement sans générer de logs verbeux, exécutez le senseur booléen :

```powershell
powershell -ExecutionPolicy Bypass -File .\c.ps1
```

*   Une exécution sans aucune sortie et un `Exit Code 0` (`$LASTEXITCODE` sous PowerShell) confirme que l'intégralité des 19 vecteurs cibles (Services, Autologgers WMI, Télémétrie, GPO Applicative) est neutralisée.

## 4. Maintenance / Modifications du Payload

Le code source d'ablation réside dans `src/p.ps1`. Il n'est pas utilisé directement lors de l'attaque. En cas de modification (ajout d'un service cible, retrait d'un ETW), la mécanique suivante s'impose :

1.  Mettez à jour `src/p.ps1`.
2.  Compressez et encodez son contenu : Le flux est minifié (suppression des retours charriots), converti en `MemoryStream`, compressé via `DeflateStream`, puis encodé en Base64.
3.  La chaîne Base64 résultante (`src/e.bin`) doit être assignée à la variable `$b` dans `i.ps1`.
4.  Privilégiez toujours l'usage du `$ErrorActionPreference = 'SilentlyContinue'` (minifié en `$E`) pour garantir un `No-Block` lors de l'exécution RunOnce.
