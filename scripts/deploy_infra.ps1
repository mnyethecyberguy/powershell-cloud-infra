Set-PSDebug -Strict

$ScriptDir = Split-Path -parent $MyInvocation.MyCommand.Path
Import-Module $ScriptDir\..\modules\pci.psm1

<# Check if Deploy or Remove scripts already running #>
if ( deploy or remove scripts running ) {
  Write-Output "The deploy or remove script is already running.  Only one of these scripts can be run at a time."
  exit
}

<# Check if Deploy file exists, if not then create #>
if ( -not ( Test-Path -Path $DEPLOY_FILE ) ) {
  Write-Output "{}" | Set-Content $DEPLOY_FILE
}

$UNIQUE_STRING_AWS = "$(Get-UniqueStringAws)"
$UNIQUE_STRING_AZURE = "$(Get-UniqueStringAzure)"
$UNIQUE_STRING_GCP = "$(Get-UniqueStringGcp)"

if ( $UNIQUE_STRING_AWS -eq "null") {
  $UNIQUE_STRING = New-UniqueString
  Write-Output "Generated new AWS identifier: $UNIQUE_STRING"
  (jq --arg aws "$UNIQUE_STRING" '.unique_strings.aws = $aws' "$DEPLOY_FILE") | Set-Content $DEPLOY_FILE
}

if ( $UNIQUE_STRING_AZURE -eq "null") {
  $UNIQUE_STRING = New-UniqueString
  Write-Output "Generated new Azure identifier: $UNIQUE_STRING"
  (jq --arg azure "$UNIQUE_STRING" '.unique_strings.azure = $azure' "$DEPLOY_FILE") | Set-Content $DEPLOY_FILE
}

if ( $UNIQUE_STRING_GCP -eq "null") {
  $UNIQUE_STRING = New-UniqueString
  Write-Output "Generated new AWS identifier: $UNIQUE_STRING"
  (jq --arg gcp "$UNIQUE_STRING" '.unique_strings.gcp = $gcp' "$DEPLOY_FILE") | Set-Content $DEPLOY_FILE
}

$REGIONS="$(Get-Regions)"
$SELECTED_AWS_REGION="$(Get-RegionAws)"
$SELECTED_AZURE_REGION="$(Get-RegionAzure)"
$SELECTED_GCP_REGION="$(Get-RegionGcp)"
$NUMBER_REGIONS_ENABLED=0

if ( $SELECTED_AWS_REGION -eq "null" ) {
  $SELECTED_AWS_REGION = "none"
  (jq '.regions.aws = "none"' $DEPLOY_FILE) | Set-Content $DEPLOY_FILE
}

if ( $SELECTED_AZURE_REGION -eq "null" ) {
  $SELECTED_AZURE_REGION = "none"
  (jq '.regions.azure = "none"' $DEPLOY_FILE) | Set-Content $DEPLOY_FILE
}

if ( $SELECTED_GCP_REGION -eq "null" ) {
  $SELECTED_GCP_REGION = "none"
  (jq '.regions.gcp = "none"' $DEPLOY_FILE) | Set-Content $DEPLOY_FILE
}

if ( $REGIONS -ne "null" ) {
  if ( $SELECTED_AWS_REGION -ne "none" ) {
    $NUMBER_REGIONS_ENABLED++
  }

  if ( $SELECTED_AZURE_REGION -ne "none" ) {
    $NUMBER_REGIONS_ENABLED++
  }

  if ( $SELECTED_GCP_REGION -ne "none" ) {
    $NUMBER_REGIONS_ENABLED++
  }
}

if ( $NUMBER_REGIONS_ENABLED -gt 0 -and $NUMBER_REGIONS_ENABLED -lt 3 ) {
  <# Give the option to enable regions not previously enabled #>
  if ( $SELECTED_AWS_REGION -eq "none" ) {
    Write-Output ""
    $REPLY = Read-Host -Prompt "Would you like to enable AWS? (y/N) "
    Write-Output ""

    if ( $REPLY -eq 'y' -or $REPLY -eq 'Y' ) {
      Set-RegionAws
    }
  }

  if ( $SELECTED_AZURE_REGION -eq "none" ) {
    Write-Output ""
    $REPLY = Read-Host -Prompt "Would you like to enable Azure? (y/N) "
    Write-Output ""

    if ( $REPLY -eq 'y' -or $REPLY -eq 'Y' ) {
      Set-RegionAzure
    }
  }

  if ( $SELECTED_GCP_REGION -eq "none" ) {
    Write-Output ""
    $REPLY = Read-Host -Prompt "Would you like to enable GCP? (y/N) "
    Write-Output ""

    if ( $REPLY -eq 'y' -or $REPLY -eq 'Y' ) {
      Set-RegionGcp
    }
  }
}
elseif ( $NUMBER_REGIONS_ENABLED -eq 0 ) {
  <# Prompt User to select their initial regions. #>
  Set-RegionAws
  Set-RegionAzure
  Set-RegionGcp
}

$REGIONS="$(Get-Regions)"
$SELECTED_AWS_REGION="$(Get-RegionAws)"
$SELECTED_AZURE_REGION="$(Get-RegionAzure)"
$SELECTED_GCP_REGION="$(Get-RegionGcp)"

if ( $SELECTED_AWS_REGION -ne "none" ) {
  $AWS_DEFAULT_REGION = "$(aws configure get region)"

  if ( $SELECTED_AWS_REGION -ne $AWS_DEFAULT_REGION ) {
    Write-Output ""
    Write-Output "Selected AWS region does not match the region used by the AWS CLI. Please re-run \"aws configure\" and update the default region."
    exit
  }
}

$ADMIN_LOCKED_DOWN = Get-AdminLock

if ( $ADMIN_LOCKED_DOWN -eq "null" ) {
  Write-Output ""
  $REPLY = Read-Host -Prompt "Would you like to lock down certain administrative services (SSH, Azure Key Vault, and others) so that they can only be accessed from your current public IP address? This is NOT recommended if you will be switching networks frequently. (y/N) "
  Write-Output ""

  if ( $REPLY -eq 'y' -or $REPLY -eq 'Y' ) {
    $ADMIN_LOCKED_DOWN = "true"
  }
  else {
    $ADMIN_LOCKED_DOWN = "false"
  }

  (jq --arg admin_locked_down "$ADMIN_LOCKED_DOWN" '.admin_locked_down = $admin_locked_down' "$DEPLOY_FILE") | Set-Content $DEPLOY_FILE
}

Write-Output ""
Write-Output "Selected Regions:"
Write-Output ""
Write-Output "AWS: $SELECTED_AWS_REGION"
Write-Output "Azure: $SELECTED_AZURE_REGION"
Write-Output "GCP: $SELECTED_GCP_REGION"
Write-Output ""
Write-Output "Admin services locked down: $ADMIN_LOCKED_DOWN"