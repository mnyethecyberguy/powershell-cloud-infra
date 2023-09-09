Set-PSDebug -Strict

$ModuleDir = "$(Split-Path $PSScriptRoot)/modules"
Import-Module $ModuleDir/PwshCloudInfrastructure.psm1 -Force

$CallingDir = "$PWD"
$ScriptDir = "$($(Set-Location $PSScriptRoot) > $null && $PWD)"

<# Check if Deploy or Remove scripts already running #>
if ( (Get-Process -Name pwsh | Where-Object {$_.CommandLine -like "*Deploy-Infrastructure.ps1"} -ne $null ) -or (Get-Process -Name pwsh | Where-Object {$_.CommandLine -like "*Remove-Infrastructure.ps1"} -ne $null ) ) {
  Write-Host "The deploy or remove script is already running.  Only one of these scripts can be run at a time."
  exit 1
}

$DeployFile = $(Get-DeployFilePath)
if ( -not ( Test-Path -Path $DeployFile ) ) {
  Write-Host "No Deploy file exists to teardown"
  exit 1
}

$ErrorsDir = "$(Get-ErrorsDir)"
if ( -not ( Test-Path -Path $ErrorsDir ) ) {
  Write-Host "No error log directory exists, creating now"
  New-Item -ItemType Directory -Path $ErrorsDir | Out-Null
}
else {
  Write-Host "Error Log directory already exists: $ErrorsDir"
}

<# Create error log directory for this run #>
$CurrentTime = "$(Get-Date -UFormat %s)"
$TargetDir = "$ErrorsDir/remove_$CurrentTime"
New-Item -ItemType Directory -Path $TargetDir | Out-Null
New-Item -ItemType File -Path $TargetDir/remove_aws.err | Out-Null
New-Item -ItemType File -Path $TargetDir/remove_azure.err | Out-Null
New-Item -ItemType File -Path $TargetDir/remove_gcp.err | Out-Null
New-Item -ItemType File -Path $TargetDir/confirm_aws.err | Out-Null
New-Item -ItemType File -Path $TargetDir/confirm_azure.err | Out-Null
New-Item -ItemType File -Path $TargetDir/confirm_gcp.err | Out-Null


$TeardownAws = "N/A"
$TeardownAzure = "N/A"
$TeardownGcp = "N/A"
$RemoveAdminLockdown = "N/A"

$SelectedRegionAws = "$(Get-RegionAws)"
$SelectedRegionAzure = "$(Get-RegionAzure)"
$SelectedRegionGcp = "$(Get-RegionGcp)"
$AdminLockedDown = "$(Get-AdminLock)"

if ( $SelectedRegionAws -ne "none" ) {
  $TeardownAws = "No"

  $Reply = Read-Host -Prompt "Would you like to teardown AWS? (y/N) "
  Write-Host ""

  if ( $Reply -eq 'y' -or $Reply -eq 'Y' ) {
    $TeardownAws = "Yes"
  }
}

if ( $SelectedRegionAzure -ne "none" ) {
  $TeardownAzure = "No"

  $Reply = Read-Host -Prompt "Would you like to teardown Azure? (y/N) "
  Write-Host ""

  if ( $Reply -eq 'y' -or $Reply -eq 'Y' ) {
    $TeardownAzure = "Yes"
  }
}

if ( $SelectedRegionGcp -ne "none" ) {
  $TeardownGcp = "No"

  $Reply = Read-Host -Prompt "Would you like to enable GCP? (y/N) "
  Write-Host ""

  if ( $Reply -eq 'y' -or $Reply -eq 'Y' ) {
    $TeardownGcp = "Yes"
  }
}

if ( $AdminLockedDown -ne "null" ) {
  $RemoveAdminLockdown = "No"

  $Reply = Read-Host -Prompt "Would you like to remove the admin lockdown settings? (y/N) "
  Write-Host ""

  if ( $Reply -eq 'y' -or $Reply -eq 'Y' ) {
    $RemoveAdminLockdown = "Yes"
  }
}

if ( $TeardownAws -ne "Yes" -and $TeardownAzure -ne "Yes" -and $TeardownGcp -ne "Yes" -and $RemoveAdminLockdown -ne "Yes" ) {
  Write-Host "Nothing selected to teardown. Exiting."
  exit 1
}

Write-Host ""
Write-Host "$($PSStyle.Bold)Teardown AWS: $TeardownAws"
Write-Host "$($PSStyle.Bold)Teardown Azure: $TeardownAzure"
Write-Host "$($PSStyle.Bold)Teardown GCP: $TeardownGcp"
Write-Host "$($PSStyle.Bold)Remove Admin Lockdown: $RemoveAdminLockdown"
Write-Host ""
$Reply = Read-Host -Prompt "$($PSStyle.Bold)Would you like to proceed with teardown? (y/N) $($PSStyle.Reset)"
Write-Host ""

$TF_VAR_AllowedAdminCidr = "0.0.0.0/0"
if ( Test-Path -Path Get-WksSshPubKeyPath ) {
  $TF_VAR_WorkstationSshPublicKey = "$(Get-WksSshPubKey)"
}
$TF_VAR_DeploymentFile = "$(Get-DeployFilePath)"

if ( $TeardownAws -eq "Yes" -or $TeardownAzure -eq "Yes" -or $TeardownGcp -eq "Yes" ) {
  $arrAws = @("aws", $TeardownAws, $ScriptDir, $TargetDir)
  $arrAzure = @("azure", $TeardownAzure, $ScriptDir, $TargetDir)
  $arrGcp = @("gcp", $TeardownGcp, $ScriptDir, $TargetDir)

  <# Run removal for each provider in parallel #>
  $arrAws, $arrAzure, $arrGcp | ForEach-Object -ThrottleLimit 3 -Parallel {
    $Provider = $_[0]
    $Teardown = $_[1]
    $ScriptRoot = $_[2]
    $ErrDir = $_[3]

    if ( $Teardown -eq "Yes" ) {
      <# Run teardown script for the provider #>
      $InitializeCommand = "{0}/Remove-{1}.ps1 2>> {2}/remove_{1}.err" -f $ScriptRoot, $Provider, $ErrDir
      Invoke-Expression $InitializeCommand
    }
  }

  if (((Get-Content -Path $TargetDir/remove_aws.err).Length -gt 0) -or `
    ((Get-Content -Path $TargetDir/remove_azure.err).Length -gt 0) -or `
    ((Get-Content -Path $TargetDir/remove_gcp.err).Length -gt 0)) {

    Get-Content $TargetDir/remove_*.err

    Write-Host ""
    Write-Host "$($PSStyle.Bold)Incomplete teardown:$($PSStyle.Reset)"
    Write-Host ""

    if ( $TeardownAws -eq "Yes" ) {
      if ( (Get-Content -Path $TargetDir/remove_aws.err).Length -gt 0 ) {
        Write-Host "$($PSStyle.Foreground.BrightRed)$($PSStyle.Bold)AWS: Partial Teardown$($PSStyle.Reset)"
      }
      else {
        Write-Host "$($PSStyle.Foreground.BrightGreen)$($PSStyle.Bold)AWS: Teardown Successful!$($PSStyle.Reset)"
      }
    }

    if ( $TeardownAzure -eq "Yes" ) {
      if ( (Get-Content -Path $TargetDir/remove_azure.err).Length -gt 0 ) {
        Write-Host "$($PSStyle.Foreground.BrightRed)$($PSStyle.Bold)Azure: Partial Teardown$($PSStyle.Reset)"
      }
      else {
        Write-Host "$($PSStyle.Foreground.BrightGreen)$($PSStyle.Bold)Azure: Teardown Successful!$($PSStyle.Reset)"
      }
    }

    if ( $TeardownGcp -eq "Yes" ) {
      if ( (Get-Content -Path $TargetDir/remove_gcp.err).Length -gt 0 ) {
        Write-Host "$($PSStyle.Foreground.BrightRed)$($PSStyle.Bold)GCP: Partial Teardown$($PSStyle.Reset)"
      }
      else {
        Write-Host "$($PSStyle.Foreground.BrightGreen)$($PSStyle.Bold)GCP: Teardown Successful!$($PSStyle.Reset)"
      }
    }

    Write-Host ""
    Write-Host "$($PSStyle.Bold)There should not be any resources, other than your AWS IAM user and GCP service account (if you ever created these), in the cloud accounts with successful teardowns. You can confirm this by exploring the cloud consoles.$($PSStyle.Reset)"
    Write-Host "Please re-run the teardown one time to resolve intermittent issues."
    Write-Host "If issues persist, please review the error logs in the $TargetDir directory."

    [System.Console]::Beep()
    exit 1
  }
}

if ( $RemoveAdminLockdown -eq "Yes" ) {
  (jq 'del( .admin_locked_down )' "$DeployFile") | Set-Content $DeployFile 
}

<# Get updated region info to check for remaining resources in each provider #>
$SelectedRegionAws = "$(Get-RegionAws)"
$SelectedRegionAzure = "$(Get-RegionAzure)"
$SelectedRegionGcp = "$(Get-RegionGcp)"

if ( $TeardownAws -eq "Yes" -or $TeardownAzure -eq "Yes" -or $TeardownGcp -eq "Yes" ) {
  Write-Host "$($PSStyle.Bold)Checking for remaining resources...$($PSStyle.Reset)"

  $arrAws = @("aws", $SelectedRegionAws, $ScriptDir, $TargetDir)
  $arrAzure = @("azure", $SelectedRegionAzure, $ScriptDir, $TargetDir)
  $arrGcp = @("gcp", $SelectedRegionGcp, $ScriptDir, $TargetDir)

  <# Run confirm-resources for each provider in parallel #>
  $arrAws, $arrAzure, $arrGcp | ForEach-Object -ThrottleLimit 3 -Parallel {
    $Provider = $_[0]
    $ProviderRegion = $_[1]
    $ScriptRoot = $_[2]
    $ErrDir = $_[3]

    if ( $ProviderRegion -eq "none" ) {
      <# Run confirm-resources script for the provider #>
      $InitializeCommand = "{0}/Confirm-Resources{1}.ps1 2>> {2}/confirm_{1}.err" -f $ScriptRoot, $Provider, $ErrDir
      Invoke-Expression $InitializeCommand
    }
  }

  if (((Get-Content -Path $TargetDir/confirm_aws.err).Length -gt 0) -or `
    ((Get-Content -Path $TargetDir/confirm_azure.err).Length -gt 0) -or `
    ((Get-Content -Path $TargetDir/confirm_gcp.err).Length -gt 0)) {

    Get-Content $TargetDir/confirm_*.err

    Write-Host ""
    Write-Host "$($PSStyle.Bold)Cloud resources still exist.  This may result in addtional cloud charges to accumulate.$($PSStyle.Reset)"
    Write-Host "Please re-run the teardown one time to resolve intermittent issues."
    Write-Host "If issues persist, please review the error logs in the $TargetDir directory."

    [System.Console]::Beep()
    exit 1
  }

  Write-Host "$($PSStyle.Bold)There should not be any resources, other than your AWS IAM user and GCP service account (if you ever created these), in the cloud accounts with successful teardowns. You can confirm this by exploring the cloud consoles.$($PSStyle.Reset)"
}

[System.Console]::Beep()

Set-Location $CallingDir