# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Lint (local)
```powershell
Invoke-ScriptAnalyzer -Path . -Recurse -Severity Error,Warning -Settings ./PSScriptAnalyzerSettings.psd1
```
Zero errors and zero warnings are required. `PSAvoidUsingWriteHost` and `PSAvoidUsingPositionalParameters` are intentionally suppressed via `PSScriptAnalyzerSettings.psd1` (uses `ExcludeRules` format).

### Syntax validation (local)
```powershell
Get-ChildItem -Path . -Filter *.ps1 -Recurse | ForEach-Object {
    $err = $null
    [System.Management.Automation.PSParser]::Tokenize((Get-Content $_.FullName -Raw), [ref]$err) | Out-Null
    if ($err) { Write-Error "Syntax error in $($_.Name)" }
}
```

## Architecture

The project is a three-phase PowerShell suite targeting Windows 11 24H2. Each phase corresponds to one numbered script.

```
Normal Mode (Admin)         Safe Mode (Networking)       Normal Mode (Post-Op)
1_prepare_safemode.ps1  →  2_kill_defender.ps1       →  3_verify_status.ps1
- Privilege check           (auto-run via RunOnce*)       - Log audit
- Restore point             - Token escalation            - Process scan
- Payload staging           - Registry ACL takeover       - Service registry check
- RunOnce* injection        - Service disable (11x)
- BCD safeboot set          - Task disable
- Forced reboot             - GPO injection (12 vals)
                            - BCD safeboot removed
                            - Forced reboot
```

**Phase 2 auto-execution mechanism:** Phase 1 writes the payload path into `HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce` under the key `*killSlop_Payload` (the `*` prefix forces execution in Safe Mode) and sets `bcdedit /set "{current}" safeboot network`.

**Privilege escalation in Phase 2:** An inline C# `TokenManipulator` class is compiled at runtime via `Add-Type` to call `advapi32.dll` directly and enable `SeTakeOwnershipPrivilege`/`SeRestorePrivilege` on the process token.

**Staging directory:** `C:\DefenderKill\` — contains the staged payload and the log file `killSlop_log.txt`.

## Commit conventions

Semantic versioning is automated via GitHub Actions (`release.yml`) based on commit message prefixes:
- `fix:` → patch bump
- `feat:` → minor bump
- `BREAKING:` → major bump

Releases are only cut from `main`. The `dev` branch is for development; open PRs to `main` to trigger a release.
