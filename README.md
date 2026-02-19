# killSlop

**Version:** 2.0.0 (Apogée SOTA Edition)
**Vecteur d'Exécution:** Fileless In-Memory (Zero-Drop Service Injector)
**Plateforme Cible:** Windows 11 (24H2)

## 1. Philosophie et Périmètre

`killSlop` est un outil d'administration drastique, asynchrone et chirurgical conçu pour la neutralisation ciblée, irréversible et furtive des composants de télémétrie, des routines d'E/S en arrière-plan et des services de sécurité embarqués (Defender/EDR).

L'architecture repose sur un principe absolu d'**Empreinte Nulle (Zero-Drop)** et de **Furtivité Maximale (Stealth Obfuscation)** :
*   **Zero-Drop :** Aucun binaire exécutable (.exe, .dll) n'est déposé sur le disque.
*   **In-Memory :** L'intégralité de la charge d'ablation s'exécute en mémoire vive via un flux natif compressé (`DeflateStream`).
*   **Stealth Maxillaire & Obfuscation SOTA :** L'intégralité des pointeurs de services (`ksSvc`, `powershell.exe`) et des arguments d'amorçage BCD (`safeboot`, `network`) est reconstruite formellement à la volée via des matrices d'entiers (`[char[]]`). Les chemins système critiques extirpés (ruches Registre `Policies`, répertoires `Tasks`) sont désérialisés dynamiquement depuis du Base64, éradiquant virtuellement la signature comportementale contre l'analyse statique et parasismique des EDR. Le pointeur d'amorçage lui-même emploie l'appel `EncodedCommand` (`-e`).
*   **Privilège Actif :** L'acquisition de privilèges ring-0/SYSTEM (notamment `SeTakeOwnershipPrivilege`) est gérée dynamiquement par réflexion C# (`P/Invoke`) dans le PowerShell.
*   **Furtivité Log :** Toute trace comportementale de l'exécution en Safe Mode est dissimulée dans un fichier journal en mode Caché/Système (`C:\ProgramData\ksi.log`).

## 2. Architecture Technique & Fail-Safe

La séquence critique exploite un passage transitif et invisible par le **Safe Mode System** (Mode sans échec) pour contourner les protections `Tamper Protection` qui verrouillent les ruches de registre et ACLs MS de l'environnement standard.

### La Chaîne d'Infection (Zero-Interaction)

1.  **Phase d'Injection Normale (`i.ps1`) :** Le script d'injection (tournant avec UAC Administrateur Bypass) encode et dissimule la charge utile compressée au sein de la clé Registre `InstallDate` de Windows Update. Il crée ensuite le **Service Système Autonome Temporaire** (`ksSvc`) pointant sur le flux de décodage chiffré. L'exception d'amorçage en mode sécurisé (`SafeBoot\Network`) est appliquée au service pour garantir son lancement pré-logon (sans nécessité du mot de passe utilisateur). L'instruction BCD de SafeBoot est envoyée. La machine redémarre.
2.  **Phase Asynchrone (Safe Mode Logon) :** Avant l'interface de connexion, le *Service LocalSystem* `ksSvc` est invoqué. Il décompresse via flux Deflate la payload d'ablation.
3.  **Éradication Physique (`p.ps1`) :** Les processus et clés Registres ETW/Télémétrie/Defender sont désactivés ou corrompus. Les tâches planifiées (inaccessibles par API en mode sans échec) sont détruites *à la hache* via les routines bas niveau du système de fichiers (`takeown`, `icacls`).
4.  **Auto-Nettoyage :** La payload efface sa clé d'hibernation `InstallDate`, purge le service `ksSvc` et purifie l'exception SafeBoot. Le reboot normal est appelé.

### Sécurité Anti-Blocage : Mécanisme "Fail-Safe"
Pour éliminer le risque (boot-loop ou blocage en Safe Mode) lié aux modifications du BCD, un blindage applicatif est intégré :
*   **Purge Top-Chrono :** La MILLISECONDE 0 du script en Safe Mode force l'ablation du tag BCD `safeboot`. En cas de crash instantané consécutif, la machine redémarrera de façon classique.
*   **Encapsulage Restrictif (`Try/Catch/Finally`) :** Même si un vecteur (ACL invalide, processus MS manquant) jette une exception critique bloquante, le bloc `Finally` est déclenché inconditionnellement pour purger le Registre, purger le BCD et lancer un `shutdown.exe /r /t 0 /f` chirurgical.

## 3. Guide d'Exécution (How-To)

L'exécution doit être infaillible. Aucune action humaine n'est requise.

### Prérequis
*   Tamper Protection Windows : **Désactivé** (Nécessaire temporairement pour l'injection).
*   Privilèges : **Administrateur local**.

### Déploiement

Un point d'exécution unique et masqué est fourni : `run.bat`.

1.  Double-cliquez simplement sur `run.bat`.
2.  L'invite UAC va s'afficher (approbation des privilèges administrateur).
3.  **Ne touchez plus à rien.** Le terminal se fermera après quelques secondes. L'ordinateur redémarrera automatiquement, affichera un écran noir/de chargement puis redémarrera une **seconde** fois pour aboutir sur votre session classique, net et purifié.

### Audit Post-Opération (Lecture des Logs Furtifs)

Pour suivre l'audit temporel de l'exécution, vous pouvez lire le log caché :

```powershell
Get-Content -Path "C:\ProgramData\ksi.log" -Force
```

Une exécution parfaite laissera 2 empreintes : *[INJECT] DEPLOY* et *[INJECT] BCK_OK*. L'environnement cible aura perdu sa télémétrie silencieusement.

## 4. Compilation et Build (Zero-Intervention)

En cas d'altération ou d'ajout de vecteurs d'attaque au sein du module noyau `src/p.ps1`, la reconstruction de l'injecteur est **100% automatisée**, silencieuse et sans intermédiaire.
Exécutez la routine de compilation :

```powershell
.\build.ps1
```

Le compilo s'occupe d'appliquer un **Minifier formel** stricte (ablation des Return/Linefeed, compression des variables logiques), et une compression GZip absolue de niveau `Optimal` (`DeflateStream`). Le code génère le hash matriciel Base64 et l'**injecte directement** via substitution par Regex au travers de la variable dormante de l'injecteur racine `i.ps1`.
Zéro extraction manuelle, zéro manipulation de buffer binaire intermédiaire, zéro faille. Architecture hermétique, prête au déploiement instantané.
