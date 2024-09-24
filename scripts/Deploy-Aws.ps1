

$ModuleDir = "$(Split-Path $PSScriptRoot)/modules"
Import-Module $ModuleDir/PwshCloudInfrastructure.psm1 -Force

$CallingDir = "$PWD"

$Regions = "$(Get-Regions)"
$UidAws = "$(Get-UidAws)"
$DefaultRegionAws = "$(Get-RegionAws)"

if ( ($Regions -eq "null") -or ($UidAws -eq "null") -or ($DefaultRegionAws -eq "none")) {
  Write-Host "AWS not configured.  Please run Deploy-Infrastructure.ps1 to enable AWS."
  exit 1
}

Write-Host ""
Write-Host "Deploying AWS infrastructure....."
Write-Host ""

$TF_VAR_UidAws = "$UidAws"
$TF_VAR_DeployConfig = "$(Get-DeployConfigPath)"

Set-Location "$(Split-Path -Path $PSScriptRoot)/infrastructure/terraform/aws"

terraform init -backend-config="bucket=pwsh-tfstate-$UidAws"
terraform apply -auto-approve -lock=false

Write-Host ""

Set-Location $CallingDir