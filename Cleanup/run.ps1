# Input bindings are passed in via param block.
param($Timer)

# Write an information log with the current time.
Write-Host "PowerShell timer trigger function ran! TIME: $currentUTCtime"

Invoke-CleanupKeyVault