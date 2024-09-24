

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

<# Set Terraform environment variables #>
$env:TF_VAR_uid_aws = "$UidAws"
$env:TF_VAR_deploy_config = "$(Get-DeployConfigPath)"

Set-Location "$(Split-Path -Path $PSScriptRoot)/infrastructure/terraform/aws"

terraform init -upgrade -backend-config="bucket=pwsh-tfstate-$UidAws" -backend-config="region=$DefaultRegionAws"
terraform apply -auto-approve -lock=false

Write-Host ""

Set-Location $CallingDir