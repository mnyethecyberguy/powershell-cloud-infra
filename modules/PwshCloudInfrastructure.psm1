<# Global variables and functions #>
$PwshCloudInfrastructure = [ordered]@{
  DeployFile            = "$(Split-Path $PSScriptRoot)/deploy_config.json"
  ErrorsDir             = "$(Split-Path $PSScriptRoot)/deploy_errors"
  SupportedRegionsAws   = "us-east-1", "us-east-2", "us-west-1", "us-west-2"
  SupportedRegionsAzure = "eastus", "eastus2", "centralus", "southcentralus", "westus", "westus2", "westus3"
  SupportedRegionsGcp   = "us-east1", "us-east4", "us-east5", "us-central1", "us-south1", "us-west1", "us-west2"
  WksSshPubKey          = "$(Split-Path $PSScriptRoot)/id_rsa.pub"
}

New-Variable -Name PwshCloudInfrastructure -Value $PwshCloudInfrastructure -Scope Script -Force

function Get-DeployFilePath() {
  $PwshCloudInfrastructure.DeployFile
}

function Get-ErrorsDir() {
  $PwshCloudInfrastructure.ErrorsDir
}

function Get-UniqueStringAws() {
  Get-Content $PwshCloudInfrastructure.DeployFile | jq -r '.unique_strings.aws'
}

function Get-UniqueStringAzure() {
  Get-Content $PwshCloudInfrastructure.DeployFile | jq -r '.unique_strings.azure'
}

function Get-UniqueStringGcp() {
  Get-Content $PwshCloudInfrastructure.DeployFile | jq -r '.unique_strings.gcp'
}

function Get-RegionAws() {
  Get-Content $PwshCloudInfrastructure.DeployFile | jq -r '.regions.aws'
}

function Get-RegionAzure() {
  Get-Content $PwshCloudInfrastructure.DeployFile | jq -r '.regions.azure'
}

function Get-RegionGcp() {
  Get-Content $PwshCloudInfrastructure.DeployFile | jq -r '.regions.gcp'
}

function Get-Regions() {
  Get-Content $PwshCloudInfrastructure.DeployFile | jq -r '.regions'
}

function Get-AdminLock() {
  Get-Content $PwshCloudInfrastructure.DeployFile | jq -r '.admin_locked_down'
}

function Get-SupportedRegionsAws() {
  $PwshCloudInfrastructure.SupportedRegionsAws
}

function Get-SupportedRegionsAzure() {
  $PwshCloudInfrastructure.SupportedRegionsAzure
}

function Get-SupportedRegionsGcp() {
  $PwshCloudInfrastructure.SupportedRegionsGcp
}
function Test-AwsEnabled() {
  $SelectedAwsRegion = Get-RegionAws

  if ( $SelectedAwsRegion -ne "null" -and $SelectedAwsRegion -ne "none" ) {
    Write-Output "true"
  }
  else {
    Write-Output "false"
  }
}

function Test-AzureEnabled() {
  $SelectedAzureRegion = Get-RegionAzure

  if ( $SelectedAzureRegion -ne "null" -and $SelectedAzureRegion -ne "none" ) {
    Write-Output "true"
  }
  else {
    Write-Output "false"
  }
}

function Test-GcpEnabled() {
  $SelectedGcpRegion = Get-RegionGcp

  if ( $SelectedGcpRegion -ne "null" -and $SelectedGcpRegion -ne "none" ) {
    Write-Output "true"
  }
  else {
    Write-Output "false"
  }
}

function Select-Region() {
  param (
    [Parameter(Mandatory)]
    [string] $Provider,

    [Parameter(Mandatory)]
    [string[]] $Regions
  )
  
  $title = 'Select Region'
  $message = "Select a supported $Provider region:"
  [System.Management.Automation.Host.ChoiceDescription[]] $options = @()
  
  foreach ( $region in $Regions ) {
    $options += New-Object System.Management.Automation.Host.ChoiceDescription $region
  }

  $options += New-Object System.Management.Automation.Host.ChoiceDescription 'none'

  $result = $host.ui.PromptForChoice($title, $message, $options, $Regions.length)
  
  if ( $result -eq $Regions.length ) {
    $Selection = 'none'
  }
  else {
    $Selection = $Regions[$result]
  }

  (jq --arg region "$Selection" --arg provider "$Provider" '.regions[$provider] = $region' $PwshCloudInfrastructure.DeployFile) | Set-Content $PwshCloudInfrastructure.DeployFile
}

function Set-RegionAws() {
  Select-Region -Provider aws -Regions $PwshCloudInfrastructure.SupportedRegionsAws
}

function Set-RegionAzure() {
  Select-Region -Provider azure -Regions $PwshCloudInfrastructure.SupportedRegionsAzure
}

function Set-RegionGcp() {
  Select-Region -Provider gcp -Regions $PwshCloudInfrastructure.SupportedRegionsGcp
}

function Get-WksSshPubKey() {
  Get-Content $PwshCloudInfrastructure.WksSshPubKey
}

function Get-WksSshPubKeyPath() {
  $PwshCloudInfrastructure.WksSshPubKey
}

function New-UniqueString() {
  -join ((48..57) + (97..122) | Get-Random -Count 12 | ForEach-Object {[char]$_})
}
