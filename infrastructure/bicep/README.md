# Bicep Templates
Infrastructure as Code für alle Azure-Ressourcen.
Deployment ausschließlich via CI/CD Pipeline - keine manuellen Portal-Änderungen.

Templates:
- automation-account.bicep  (Azure Automation Accounts + Managed Identities)
- logic-apps.bicep          (Automation Gateway)
- key-vault.bicep           (HMAC Secret, Certificates)
- new-spoke.bicep           (Erweiterung auf neue Subscriptions)
