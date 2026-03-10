<#
.SYNOPSIS
    Kurzbeschreibung was dieses Skript macht.

.DESCRIPTION
    Detailliertere Beschreibung.

.PARAMETER TicketID
    ID des genehmigten baseIT-Tickets (UUID v4).

.PARAMETER TargetUser
    SAMAccountName des Ziel-Users (z.B. u123456).

.NOTES
    Autor:      Auth & Access Team
    Version:    1.0
    Erstellt:   <DATUM EINTRAGEN>
    Ticket:     <TICKET-ID EINTRAGEN>
#>

# Modul-Abhängigkeit - bricht sofort ab wenn nicht installiert
#Requires -Modules ActiveDirectory

[CmdletBinding()]
param (
    # UUID v4 Pflicht
    [Parameter(Mandatory)]
    [ValidatePattern('^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')]
    [string]$TicketID,

    # SAMAccountName - kein UPN, da On-Prem AD
    [Parameter(Mandatory)]
    [ValidatePattern('^[a-zA-Z0-9]{1,20}$')]
    [string]$TargetUser
)

$ErrorActionPreference = 'Stop'

#region Audit Log Funktion
function Write-AuditLog {
    param (
        [string]$Action,
        [string]$Result,
        [string]$Details = ''
    )

    # Gleiche Struktur wie Cloud-Template - einheitlich parsebar in Sentinel
    $log = @{
        ScriptName  = $MyInvocation.ScriptName
        TicketID    = $TicketID
        TargetUser  = $TargetUser
        Action      = $Action
        Result      = $Result
        Details     = $Details
        Timestamp   = (Get-Date -Format 'o')    # ISO 8601
        ExecutedBy  = $env:USERNAME             # gMSA Name für Sentinel
        ComputerName = $env:COMPUTERNAME        # Scriptrunner Server
    } | ConvertTo-Json -Compress

    Write-Output "AUDITLOG: $log"
}
#endregion

try {
    # ── 1. AD-Verbindung prüfen ──────────────────────────────────────────
    # Stellt sicher dass das AD-Modul den DC erreicht bevor wir weitermachen
    Write-Output "Prüfe AD-Verbindung..."
    Get-ADDomain | Out-Null
    Write-Output "AD-Verbindung OK"

    # ── 2. Ziel-User prüfen ──────────────────────────────────────────────
    # User muss existieren bevor wir irgendwas machen
    Write-Output "Prüfe Ziel-User: $TargetUser"
    $user = Get-ADUser -Identity $TargetUser -ErrorAction Stop
    Write-Output "User gefunden: $($user.DistinguishedName)"

    # ── 3. Hauptlogik hier implementieren ────────────────────────────────
    # TODO: Skript-spezifische Logik hier einfügen



    # ── 4. Erfolg loggen ─────────────────────────────────────────────────
    Write-AuditLog -Action 'Execute' -Result 'SUCCESS'

} catch {
    Write-AuditLog -Action 'Execute' -Result 'FAILED' -Details $_.Exception.Message
    throw $_
}
