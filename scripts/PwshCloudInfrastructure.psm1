# Global variables and functions
New-Variable -Name DEPLOY_FILE -Value "$PSScriptRoot/deploy_config.json" -Scope Global
#$DEPLOY_FILE = "$PSScriptRoot/deploy_config.json"
$ERRORS_DIR = "deploy_errors"
$COLOR_ERROR = "Red"
$COLOR_SUCCESS = "Green"
$COLOR_INFO = "Cyan"
$SUPPORTED_REGIONS_AWS = "us-east-1", "us-east-2", "us-west-1", "us-west-2"
$SUPPORTED_REGIONS_AZURE = "eastus", "eastus2", "centralus", "southcentralus", "westus", "westus2", "westus3"
$SUPPORTED_REGIONS_GCP = "us-east1", "us-east4", "us-east5", "us-central1", "us-south1", "us-west1", "us-west2"

$PwshCloudInfrastructure = [ordered]@{
  DeployFile            = "$PSScriptRoot/deploy_config.json"
  ErrorsDir             = "$PSScriptRoot/deploy_errors"
  ColorError            = "Red"
  ColorSuccess          = "Green"
  ColorInfo             = "Cyan"
  SupportedRegionsAws   = "us-east-1", "us-east-2", "us-west-1", "us-west-2"
  SupportedRegionsAzure = "eastus", "eastus2", "centralus", "southcentralus", "westus", "westus2", "westus3"
  SupportedRegionsGcp   = "us-east1", "us-east4", "us-east5", "us-central1", "us-south1", "us-west1", "us-west2"
}

function Get-SupportedRegionsAws() {
  $PwshCloudInfrastructure.SupportedRegionsAws
}

function Get-DeployFilePath() {
  $DEPLOY_FILE
}

function Get-UniqueStringAws() {
  Get-Content $DEPLOY_FILE | jq -r '.unique_strings.aws'
}

function Get-UniqueStringAzure() {
  Get-Content $DEPLOY_FILE | jq -r '.unique_strings.azure'
}

function Get-UniqueStringGcp() {
  Get-Content $DEPLOY_FILE | jq -r '.unique_strings.gcp'
}

function Get-RegionAws() {
  Get-Content $DEPLOY_FILE | jq -r '.regions.aws'
}

function Get-RegionAzure() {
  Get-Content $DEPLOY_FILE | jq -r '.regions.azure'
}

function Get-RegionGcp() {
  Get-Content $DEPLOY_FILE | jq -r '.regions.gcp'
}

function Get-Regions() {
  Get-Content $DEPLOY_FILE | jq -r '.regions'
}

function Get-AdminLock() {
  Get-Content $DEPLOY_FILE | jq -r '.admin_locked_down'
}

function Test-AwsEnabled() {
  $SELECTED_AWS_REGION = Get-RegionAws

  if ( $SELECTED_AWS_REGION -ne "null" -and $SELECTED_AWS_REGION -ne "none" ) {
    Write-Output "true"
  }
  else {
    Write-Output "false"
  }
}

function Test-AzureEnabled() {
  $SELECTED_AZURE_REGION = Get-RegionAzure

  if ( $SELECTED_AZURE_REGION -ne "null" -and $SELECTED_AZURE_REGION -ne "none" ) {
    Write-Output "true"
  }
  else {
    Write-Output "false"
  }
}

function Test-GcpEnabled() {
  $SELECTED_GCP_REGION = Get-RegionGcp

  if ( $SELECTED_GCP_REGION -ne "null" -and $SELECTED_GCP_REGION -ne "none" ) {
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

  (jq --arg region "$Selection" --arg provider "$Provider" '.regions[$provider] = $region' "$DEPLOY_FILE") | Set-Content $DEPLOY_FILE
}

function Set-RegionAws() {
  Select-Region -Provider aws -Regions $SUPPORTED_REGIONS_AWS
}

function Set-RegionAzure() {
  Select-Region -Provider azure -Regions $SUPPORTED_REGIONS_AZURE
}

function Set-RegionGcp() {
  Select-Region -Provider gcp -Regions $SUPPORTED_REGIONS_GCP
}

function Get-WksSshPubKey() {
  Get-Content $WKS_SSH_PUB_KEY
}

function New-UniqueString() {
  -join ((48..57) + (97..122) | Get-Random -Count 12 | ForEach-Object {[char]$_})
}
