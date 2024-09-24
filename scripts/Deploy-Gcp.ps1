

$ModuleDir = "$(Split-Path $PSScriptRoot)/modules"
Import-Module $ModuleDir/PwshCloudInfrastructure.psm1 -Force

$CallingDir = "$PWD"

$Regions = "$(Get-Regions)"
$UidGcp = "$(Get-UidGcp)"
$DefaultRegionGcp = "$(Get-RegionGcp)"

if ( ($Regions -eq "null") -or ($UidGcp -eq "null") -or ($DefaultRegionGcp -eq "none")) {
  Write-Host "GCP not configured.  Please run Deploy-Infrastructure.ps1 to enable GCP."
  exit 1
}

Write-Host ""
Write-Host "Deploying GCP infrastructure....."
Write-Host ""

$TF_VAR_UidGcp = "$UidGcp"
$TF_VAR_DeployConfig = "$(Get-DeployConfigPath)"

Set-Location "$(Split-Path -Path $PSScriptRoot)/infrastructure/terraform/gcp"

terraform init -backend-config="bucket=pwsh-tfstate-$UidGcp"
terraform apply -auto-approve -lock=false

Write-Host ""

Set-Location $CallingDir