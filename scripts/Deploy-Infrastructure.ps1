Set-PSDebug -Strict

$ScriptDir = Split-Path -parent $MyInvocation.MyCommand.Path
Import-Module $ScriptDir\..\modules\pci.psm1

<# Check if Deploy or Remove scripts already running #>
if ( (Get-Process -Name pwsh | Where-Object {$_.CommandLine -like "*Deploy-Infrastructure.ps1"} -ne $null ) -or (Get-Process -Name pwsh | Where-Object {$_.CommandLine -like "*Remove-Infrastructure.ps1"} -ne $null ) ) {
  Write-Host "The deploy or remove script is already running.  Only one of these scripts can be run at a time."
  exit
}

<# Check if Deploy file exists, if not then create #>
if ( -not ( Test-Path -Path $DEPLOY_FILE ) ) {
  Write-Host "No Deploy file exists, creating now"
  Write-Output "{}" | Set-Content $DEPLOY_FILE
}
else {
  Write-Host "Deploy File already exists: $(Get-DeployFilePath)"
}

$UNIQUE_STRING_AWS = "$(Get-UniqueStringAws)"
$UNIQUE_STRING_AZURE = "$(Get-UniqueStringAzure)"
$UNIQUE_STRING_GCP = "$(Get-UniqueStringGcp)"

if ( $UNIQUE_STRING_AWS -eq "null") {
  $UNIQUE_STRING = New-UniqueString
  Write-Host "Generated new AWS identifier: $UNIQUE_STRING"
  (jq --arg aws "$UNIQUE_STRING" '.unique_strings.aws = $aws' "$DEPLOY_FILE") | Set-Content $DEPLOY_FILE
}

if ( $UNIQUE_STRING_AZURE -eq "null") {
  $UNIQUE_STRING = New-UniqueString
  Write-Host "Generated new Azure identifier: $UNIQUE_STRING"
  (jq --arg azure "$UNIQUE_STRING" '.unique_strings.azure = $azure' "$DEPLOY_FILE") | Set-Content $DEPLOY_FILE
}

if ( $UNIQUE_STRING_GCP -eq "null") {
  $UNIQUE_STRING = New-UniqueString
  Write-Host "Generated new AWS identifier: $UNIQUE_STRING"
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
    Write-Host ""
    $REPLY = Read-Host -Prompt "Would you like to enable AWS? (y/N) "
    Write-Host ""

    if ( $REPLY -eq 'y' -or $REPLY -eq 'Y' ) {
      Set-RegionAws
    }
  }

  if ( $SELECTED_AZURE_REGION -eq "none" ) {
    Write-Host ""
    $REPLY = Read-Host -Prompt "Would you like to enable Azure? (y/N) "
    Write-Host ""

    if ( $REPLY -eq 'y' -or $REPLY -eq 'Y' ) {
      Set-RegionAzure
    }
  }

  if ( $SELECTED_GCP_REGION -eq "none" ) {
    Write-Host ""
    $REPLY = Read-Host -Prompt "Would you like to enable GCP? (y/N) "
    Write-Host ""

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
    Write-Host ""
    Write-Host "Selected AWS region does not match the region used by the AWS CLI. Please re-run \"aws configure\" and update the default region."
    exit
  }
}

$ADMIN_LOCKED_DOWN = Get-AdminLock

if ( $ADMIN_LOCKED_DOWN -eq "null" ) {
  Write-Host ""
  $REPLY = Read-Host -Prompt "Lock down certain administrative services (SSH, RDP, and more) so that they can only be accessed from your current public IP address? NOT recommended if you will be switching networks frequently. (y/N) "
  Write-Host ""

  if ( $REPLY -eq 'y' -or $REPLY -eq 'Y' ) {
    $ADMIN_LOCKED_DOWN = "true"
  }
  else {
    $ADMIN_LOCKED_DOWN = "false"
  }

  (jq --arg admin_locked_down "$ADMIN_LOCKED_DOWN" '.admin_locked_down = $admin_locked_down' "$DEPLOY_FILE") | Set-Content $DEPLOY_FILE
}

Write-Host ""
Write-Host ("**Selected Regions:**" | ConvertFrom-Markdown -AsVT100EncodedString).VT100EncodedString -NoNewline
Write-Host ""
Write-Host ("**AWS: $SELECTED_AWS_REGION**" | ConvertFrom-Markdown -AsVT100EncodedString).VT100EncodedString -NoNewline
Write-Host ("**Azure: $SELECTED_AZURE_REGION**" | ConvertFrom-Markdown -AsVT100EncodedString).VT100EncodedString -NoNewline
Write-Host ("**GCP: $SELECTED_GCP_REGION**" | ConvertFrom-Markdown -AsVT100EncodedString).VT100EncodedString -NoNewline
Write-Host ""
Write-Host ("**Admin services locked down: $ADMIN_LOCKED_DOWN**" | ConvertFrom-Markdown -AsVT100EncodedString).VT100EncodedString

if ( $ADMIN_LOCKED_DOWN -eq "true" ) {
  $TF_VAR_AllowedAdminCidr = "$((Invoke-WebRequest -Uri ipinfo.io/ip).Content)/32"
}
else {
  $TF_VAR_AllowedAdminCidr = "0.0.0.0/0"
}

$TF_VAR_WorkstationSshPublicKey = "$(Get-WksSshPubKey)"

if ( $SELECTED_AWS_REGION -ne "none" -or $SELECTED_AZURE_REGION -ne "none" -or $SELECTED_GCP_REGION -ne "none" ) {
  Remove-Item -Force $ERRORS_DIR/deploy_*.err

  <# Execute initialize and deploy scripts in parallel #>
  "aws", "azure", "gcp" | ForEach-Object -Parallel {
    $PROVIDERUPPER = $_.ToUpper()
    if ( "$SELECTED_($_.ToUpper())_REGION" )
  }  -ThrottleLimit 3
}