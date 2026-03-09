# Runbooks
PowerShell-Runbooks für Azure Automation.
Namenskonvention: <Verb>-<Objekt>.ps1 (z.B. Add-UserToPIMGroup.ps1)
Jedes Runbook authentifiziert sich ausschließlich via Managed Identity (Connect-MgGraph -Identity).
Keine Service Accounts, keine gespeicherten Credentials.
