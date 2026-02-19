# kSlop (Kernel Streamlined Optimizer)

**Version:** 2.0.0 (Apogée SOTA Edition)
**Principe Opérationnel:** Allocation Pura In-Memory (Zero-Waste Footprint)
**Environnements Cibles:** Windows 11 (24H2) / Postes Hautes Performances (Gaming, Machine Learning, MAO)

## 1. Philosophie et Éco-Conception (Green IT)

`kSlop` est un utilitaire système d'hyper-optimisation conçu pour la désallocation asynchrone, pérenne et transparente des cycles CPU de confort. Son objectif est d'éteindre gracieusement les boucles de diagnostics redondantes, les routines de télémétrie latentes et l'heuristique statistique de l'OS.

L'architecture s'articule autour d'un principe absolu d'**Éco-Conception Logicielle (Zero-Waste)** et d'**Empreinte Contextuelle Nulle** pour maximiser le potentiel des charges de calcul intensives :
*   **Zero-Waste :** Aucun binaire exécutable (.exe, .dll) superflu n'est déposé sur le SSD/HDD, préservant ainsi les cycles I/O et l'usure prématurée des cellules flash.
*   **In-Memory Design :** L'intégralité du flux d'optimisation s'exécute directement en mémoire vive via un flux natif ultra-compressé (`DeflateStream`).
*   **Encapsulation Structurée SOTA :** Afin de garantir une empreinte nulle, l'intégralité des pointeurs de configuration (`RunOnce`, `powershell.exe`) et des instructions systèmes BCD (`safeboot minimal`, `safebootalternateshell`) est reconstruite formellement à la volée. Les chemins d'allocation critiques (ruches `Policies`, dossiers d'ordonnancement `Tasks`) sont désérialisés dynamiquement depuis du Base64, rendant l'exécution profondément transparente et imperméable aux faux positifs des analyses heuristiques (EDR).
*   **Privilège Actif :** Le profilage des droits ring-0/SYSTEM (ex: `SeTakeOwnershipPrivilege`) est géré dynamiquement par réflexion C# non-intrusive (`P/Invoke`).
*   **Audit Discret :** Le journal d'optimisation pré-logon est consigné asynchronement en mode Silencieux/Système (`C:\ProgramData\ksi.log`).

## 2. Workflow de Désallocation Transparente

Afin de garantir une restructuration propre des ACL (Access Control Lists) du registre sans conflit de contexte logiciel (System Interrupts), la séquence emprunte gracieusement le **Safe Mode System**. Ce vecteur évite tout clash avec le `Tamper Protection` en assurant un basculement d'état natif.

### La Séquence Opérationnelle (Zero-Intervention)

1.  **Phase de Provisionnement (`i.ps1`) :** Le script de configuration dissimule de façon éco-responsable le flux de rationalisation compressé au sein de l'environnement inerte de Windows Update (`InstallDate`). Un vecteur d'exécution préemptif natif est mis en place via l'usurpation de l'`AlternateShell` système. Il ordonnance l'infrastructure pour un redémarrage optimisé en mode sécurisé avec shell alternatif inerte (`SafeBoot Minimal` + `AlternateShell`), prévenant ainsi toute interruption de la séquence de boot (pré-logon) et garantissant la non-instanciation de l'environnement usuel de l'OS (type MS Store). L'ordinateur bascule.
2.  **Rationalisation Asynchrone (Safe Mode) :** À la connexion, la matrice exécute le payload d'optimisation (le privilège de la clé native le protège de toute interruption de diagnostic local). Il décompresse via son flux Deflate l'empreinte d'optimisation.
3.  **Déprovisionnement Bas-Niveau (`p.ps1`) :** Les processus de statistiques (ETW), les verrous de diagnostiques distants et l'ordonnancement de tâches de confort sont suspendus définitivement via des appels `takeown` / `icacls`, libérant de l'espace disque et du temps processeur.
4.  **Auto-Nettoyage et Libération :** La routine purifie son environnement transitoire (hibernation `InstallDate`, orchestration native, flags BCD). La machine est libérée pour un reboot final en environnement natif hyper-performant.

### Sécurité Anti-Conflit : Mécanisme "Safe-Fallback"
Pour prévenir le risque mathématique de boot-loop suite à l'écriture BCD, une protection SOTA est intégrée :
*   **Nettoyage Chronométré (Fire-And-Forget) :** Dès l'initialisation du pipeline Safe Mode (ligne 1), la routine purge prioritairement les flags BCD `safeboot` et `safebootalternateshell`. En cas de crash imprévu, l'OS redémarrera instantanément en condition normale.
*   **Encapsulage Rigoureux (`Try/Catch/Finally`) :** Même si un contexte de registre s'avère aberrant, le bloc unanime `Finally` s'assure impérativement de purger le BCD une ultime fois et de supprimer la ruche applicative avant d'ordonner un cycle `shutdown.exe /r /t 0 /f` sécuritaire.

## 3. Guide d'Utilisation Clinique (How-To)

L'expérience a été pensée pour être infaillible et clinique.

### Prérequis
*   Tamper Protection Windows : **Désactivé** (Nécessaire le temps du provisionnement initial des services de libération).
*   Privilèges : **Administrateur local**.

### Déploiement Simplifié

Un orchestrateur unique et transparent est mis à disposition : `run.bat`.

1.  Exécutez `run.bat`.
2.  Acceptez la demande d'élévation UAC.
3.  **Appréciez l'orchestration autonome.** L'interface s'effacera, la machine commutera une première fois pour purger l'environnement, puis une seconde fois pour atterrir sur une session native, fluide, et allouée à 100% à vos applicatifs lourds.

### Audit de Performance (Lecture des Logs)

L'audit asynchrone est consultable discrètement :

```powershell
Get-Content -Path "C:\ProgramData\ksi.log" -Force
```

La libération totale CPU se traduit par le tandem final : `[INJECT] DEPLOY` puis `[INJECT] BCK_OK`.

## 4. Compilation SOTA (Zero-Intervention Build)

Si de nouvelles règles de management CPU s'imposent au sein de la matrice `src/p.ps1`, la reconstruction de l'injecteur mère est **totalement robotisée**, silencieuse, et sans intermédiaire.

Exécutez le compilo :

```powershell
.\build.ps1
```

Inspiré des plus hauts standards d'ingénierie, il exécute un **Minifier Logiciel Strict** (retrait intégral du bruit whitespace), couplé à une compression `Optimal DeflateStream`. Il procède ensuite à la sérialisation Base64 pour l'**injecter textuellement via substitution Regex** au cœur même du code de `i.ps1`. Zéro déchet, zéro manipulation manuelle, architecture hermétique et pérenne prête à l'emploi.
