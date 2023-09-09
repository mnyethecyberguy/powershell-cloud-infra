

$ModuleDir = "$(Split-Path $PSScriptRoot)/modules"
Import-Module $ModuleDir/PwshCloudInfrastructure.psm1 -Force

$CallingDir = "$PWD"

$Regions = "$(Get-Regions)"
$UniqueStringAws = "$(Get-UniqueStringAws)"
$DefaultRegionAws = "$(Get-RegionAws)"

if ( ($Regions -eq "null") -or ($UniqueStringAws -eq "null") -or ($DefaultRegionAws -eq "none")) {
  Write-Host "AWS not configured.  Please run Deploy-Infrastructure.ps1 to enable AWS."
  exit 1
}

Write-Host ""
Write-Host "Deploying AWS infrastructure....."
Write-Host ""

$TF_VAR_UniqueStringAws = "$UniqueStringAws"
$TF_VAR_DeploymentFile = "$(Get-DeployFilePath)"

Set-Location "$(Split-Path -Path $PSScriptRoot)/infrastructure/terraform/aws"

terraform init -backend-config="bucket=tf-$UniqueStringAws"
terraform apply -auto-approve -lock=false

Write-Host ""

Set-Location $CallingDir