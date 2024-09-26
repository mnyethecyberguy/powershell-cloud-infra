

$ModuleDir = "$(Split-Path $PSScriptRoot)/modules"
Import-Module $ModuleDir/PwshCloudInfrastructure.psm1 -Force

$CallingDir = "$PWD"

$Regions = "$(Get-Regions)"
$UidAzure = "$(Get-UidAzure)"
$DefaultRegionAzure = "$(Get-RegionAzure)"

# if ( ($Regions -eq "null") -or ($UidAzure -eq "null") -or ($DefaultRegionAzure -eq "none")) {
if ( Test-AzureEnabled -eq "false" ) {
  Write-Host "Azure not configured.  Please run Deploy-Infrastructure.ps1 to enable Azure."
  exit 1
}

Write-Host ""
Write-Host "Deploying Azure infrastructure....."
Write-Host ""

<# Set Terraform environment variables #>
$env:TF_VAR_uid_azure = "$UidAzure"
$env:TF_VAR_deploy_config = "$(Get-DeployConfigPath)"

Set-Location "$(Split-Path -Path $PSScriptRoot)/infrastructure/terraform/azure"

terraform init -backend-config="bucket=pwsh-tfstate-$UidAzure"
terraform apply -auto-approve -lock=false

Write-Host ""

Set-Location $CallingDir