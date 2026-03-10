<#
.SYNOPSIS
    Kurzbeschreibung was dieses Runbook macht.

.DESCRIPTION
    Detailliertere Beschreibung.

.PARAMETER TicketID
    ID des genehmigten baseIT-Tickets (UUID v4).

.PARAMETER TargetUser
    UPN des Ziel-Users (z.B. user@domain.de).

.PARAMETER TargetGroup
    Name der Ziel-Gruppe (muss in allowed-roles.json stehen).

.PARAMETER AssignmentType
    Typ der Zuweisung: Eligible oder Active.

.NOTES
    Autor:      Auth & Access Team
    Version:    1.0
    Erstellt:   <DATUM EINTRAGEN>
    Ticket:     <TICKET-ID EINTRAGEN>
#>

# Modul-Abhängigkeit - bricht sofort ab wenn nicht installiert
#Requires -Modules Microsoft.Graph.Authentication

# CmdletBinding aktiviert -Verbose, -Debug, -ErrorAction automatisch
[CmdletBinding()]
param (
    # UUID v4 Pflicht - Regex verhindert manipulierte oder falsche IDs
    [Parameter(Mandatory)]
    [ValidatePattern('^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')]
    [string]$TicketID,

    # UPN Format Pflicht - verhindert ungültige Ziel-User
    [Parameter(Mandatory)]
    [ValidatePattern('^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')]
    [string]$TargetUser,

    [Parameter(Mandatory)]
    [string]$TargetGroup,

    # Nur diese zwei Werte erlaubt - alles andere wird von PowerShell selbst abgelehnt
    [Parameter(Mandatory)]
    [ValidateSet('Eligible', 'Active')]
    [string]$AssignmentType
)

# Jeder Fehler wird zu terminating error - verhindert dass das Skript bei Fehler weiterläuft
$ErrorActionPreference = 'Stop'

#region Audit Log Funktion
function Write-AuditLog {
    param (
        [string]$Action,
        [string]$Result,
        [string]$Details = ''
    )

    # Strukturierter JSON-Log - einheitlich parsebar in Sentinel via KQL
    # Prefix AUDITLOG: ermöglicht einfaches Filtern: where ResultDescription startswith "AUDITLOG:"
    $log = @{
        RunbookName    = $MyInvocation.ScriptName  # Name des laufenden Runbooks
        TicketID       = $TicketID
        TargetUser     = $TargetUser
        TargetGroup    = $TargetGroup
        AssignmentType = $AssignmentType
        Action         = $Action
        Result         = $Result
        Details        = $Details
        Timestamp      = (Get-Date -Format 'o')        # ISO 8601 - universell parsebar
        JobID          = $PSPrivateMetadata.JobId      # Azure Automation Job ID für Sentinel-Verknüpfung
    } | ConvertTo-Json -Compress

    Write-Output "AUDITLOG: $log"
}
#endregion

#region Whitelist Check
function Test-GroupAllowed {
    param ([string]$GroupName, [string]$Type)

    # AllowedRoles Variable wird im Automation Account gepflegt
    # wird bei jedem CD-Deploy automatisch aus allowed-roles.json aktualisiert
    $allowedRoles = Get-AutomationVariable -Name 'AllowedRoles' | ConvertFrom-Json

    switch ($Type) {
        'Eligible' { return $GroupName -in $allowedRoles.eligibleGroups }
        'Active'   { return $GroupName -in $allowedRoles.activeGroups }
        default    { return $false } # unbekannte Typen sind automatisch verboten
    }
}
#endregion

try {
    # ── 1. Whitelist prüfen ───────────────────────────────────────────────
    # Erste Prüfung vor jedem anderen Schritt - kein Auth-Call wenn Gruppe nicht erlaubt
    Write-Output "Prüfe Whitelist für Gruppe: $TargetGroup ($AssignmentType)"
    if (-not (Test-GroupAllowed -GroupName $TargetGroup -Type $AssignmentType)) {
        Write-AuditLog -Action 'WhitelistCheck' -Result 'FAILED' `
            -Details "Gruppe $TargetGroup nicht in Whitelist für Typ $AssignmentType"
        throw "Gruppe '$TargetGroup' ist nicht in der Whitelist für Typ '$AssignmentType'."
    }
    Write-Output "Whitelist OK"

    # ── 2. Managed Identity Authentifizierung ────────────────────────────
    # -Identity = Managed Identity des Automation Accounts - kein Passwort, kein Secret
    # -NoWelcome unterdrückt den Banner im Job-Output
    Write-Output "Authentifizierung via Managed Identity..."
    Connect-MgGraph -Identity -NoWelcome
    Write-Output "Authentifizierung erfolgreich"

    # ── 3. Hauptlogik hier implementieren ────────────────────────────────
    # TODO: Runbook-spezifische Logik hier einfügen



    # ── 4. Erfolg loggen ─────────────────────────────────────────────────
    Write-AuditLog -Action 'Execute' -Result 'SUCCESS'

} catch {
    # Fehler loggen mit genauer Fehlermeldung für Sentinel
    Write-AuditLog -Action 'Execute' -Result 'FAILED' -Details $_.Exception.Message

    # throw weiterwerfen damit Azure Automation Job als "Failed" markiert wird
    # ohne throw würde Sentinel keinen Alert feuern
    throw $_
}
