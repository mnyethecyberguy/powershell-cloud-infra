

$ModuleDir = "$(Split-Path $PSScriptRoot)/modules"
Import-Module $ModuleDir/PwshCloudInfrastructure.psm1 -Force

$CallingDir = "$PWD"

$Regions = "$(Get-Regions)"
$UniqueStringAzure = "$(Get-UniqueStringAzure)"
$DefaultRegionAzure = "$(Get-RegionAzure)"

if ( ($Regions -eq "null") -or ($UniqueStringAzure -eq "null") -or ($DefaultRegionAzure -eq "none")) {
  Write-Host "Azure not configured.  Please run Deploy-Infrastructure.ps1 to enable Azure."
  exit 1
}

Write-Host ""
Write-Host "Deploying Azure infrastructure....."
Write-Host ""

$TF_VAR_UniqueStringAzure = "$UniqueStringAzure"
$TF_VAR_DeploymentFile = "$(Get-DeployFilePath)"

Set-Location "$(Split-Path -Path $PSScriptRoot)/infrastructure/terraform/azure"

terraform init -backend-config="bucket=pwsh-tfstate-$UniqueStringAzure"
terraform apply -auto-approve -lock=false

Write-Host ""

Set-Location $CallingDir