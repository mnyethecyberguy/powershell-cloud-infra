

$ModuleDir = "$(Split-Path $PSScriptRoot)/modules"
Import-Module $ModuleDir/PwshCloudInfrastructure.psm1 -Force

$CallingDir = "$PWD"

$Regions = "$(Get-Regions)"
$UniqueStringGcp = "$(Get-UniqueStringGcp)"
$DefaultRegionGcp = "$(Get-RegionGcp)"

if ( ($Regions -eq "null") -or ($UniqueStringGcp -eq "null") -or ($DefaultRegionGcp -eq "none")) {
  Write-Host "GCP not configured.  Please run Deploy-Infrastructure.ps1 to enable GCP."
  exit 1
}

Write-Host ""
Write-Host "Deploying GCP infrastructure....."
Write-Host ""

$TF_VAR_UniqueStringGcp = "$UniqueStringGcp"
$TF_VAR_DeploymentFile = "$(Get-DeployFilePath)"

Set-Location "$(Split-Path -Path $PSScriptRoot)/infrastructure/terraform/gcp"

terraform init -backend-config="bucket=pwsh-tfstate-$UniqueStringGcp"
terraform apply -auto-approve -lock=false

Write-Host ""

Set-Location $CallingDir