Write-Host "Initializing AWS Tfstate************"
Write-Host ""
Write-Host "PSScriptRoot: $PSScriptRoot"
Write-Host ""
Write-Error -Message "Initialize-TfstateAws.ps1 -- Test Error message redirection to log."

Import-Module $PSScriptRoot/PwshCloudInfrastructure.psm1 -Force

