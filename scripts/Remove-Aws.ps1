
function Clear-Bucket() {
  param (
    [Parameter(Mandatory)]
    [string]
    $BucketName
  )
  
  Write-Host ""
  Write-Host "Clearing bucket $BucketName....."
  Write-Host ""

  if ( $(aws s3api list-buckets --query "Buckets[?Name == ``$BucketName``]" | jq '. | length') -eq 1 ) {
    <# Bypass potential retention policy #>
    
  }

}

$ModuleDir = "$(Split-Path $PSScriptRoot)/modules"
Import-Module $ModuleDir/PwshCloudInfrastructure.psm1 -Force

$CallingDir = "$PWD"
$ScriptDir = "$($(Set-Location $PSScriptRoot) > $null && $PWD)"

<# Check if Deploy or Remove scripts already running #>
if ( (Get-Process -Name pwsh | Where-Object {$_.CommandLine -like "*Deploy-Infrastructure.ps1"} -ne $null ) -or (Get-Process -Name pwsh | Where-Object {$_.CommandLine -like "*Remove-Infrastructure.ps1"} -ne $null ) ) {
  Write-Host "The deploy or remove script is already running.  Only one of these scripts can be run at a time."
  exit 1
}

$DeployConfig = $(Get-DeployConfigPath)
$UidAws = "$(Get-UidAws)"
$DefaultRegionAws = "$(Get-RegionAws)"
$Regions = "$(Get-Regions)"

if ( ($Regions -eq "null") -or ($UidAws -eq "null") -or ($DefaultRegionAws -eq "none")) {
  Write-Host "AWS not configured.  Please run Deploy-Infrastructure.ps1 to enable AWS."
  exit 1
}

Write-Host ""
Write-Host "Removing AWS infrastructure....."
Write-Host ""

<# If CloudTrail bucket was built, stop CloudTrail and clear the bucket #>
$PwshCloudTrail = "$(aws cloudtrail list-trails | jq '.Trails[] | select(.name=="pwsh-cloudtrail").name')"

if ( $PwshCloudTrail -ne "" ) {
  aws cloudtrail delete-trail --name "$PwshCloudTrail"
}

Clear-Bucket -BucketName "pwsh-cloudtrail-$UidAws"


Set-Location "$(Split-Path -Path $ScriptDir)/infrastructure/terraform/aws"

terraform destroy -auto-approve -lock=false

Write-Host ""
Write-Host "Removing AWS Terraform state bucket....."
$TfstateBucketName = "pwsh-tfstate-$UidAws"
Clear-Bucket -BucketName "$TfstateBucketName"
aws s3api delete-bucket --bucket "$TfstateBucketName"

<# Delete the local tfstate file #>
Remove-Item -Path ./.terraform/terraform.tfstate -Force

(jq --arg uid "$UidAws" --arg timestamp "$(Get-Date -UFormat %s)" 'del( .uid.aws ) | .uid["aws_" + $timestamp] = $uid | .regions.aws = "none"' "$DeployConfig") | Set-Content "$DeployConfig" > $null

Set-Location $CallingDir