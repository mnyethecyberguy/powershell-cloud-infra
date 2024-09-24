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

<# Check if Deploy file exists, if not then create #>
$DeployConfig = $(Get-DeployConfigPath)
if ( -not ( Test-Path -Path $DeployConfig ) ) {
  Write-Host "No Deploy config file exists, creating now"
  Write-Output "{}" | Set-Content $DeployConfig
}
else {
  Write-Host "Deploy config file already exists: $DeployConfig"
}

<# Check if error log directory exists, if not then create #>
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
$TargetDir = "$ErrorsDir/deploy_$CurrentTime"
New-Item -ItemType Directory -Path $TargetDir | Out-Null
New-Item -ItemType File -Path $TargetDir/deploy_aws.err | Out-Null
New-Item -ItemType File -Path $TargetDir/deploy_azure.err | Out-Null
New-Item -ItemType File -Path $TargetDir/deploy_gcp.err | Out-Null

$UidAws = "$(Get-UidAws)"
$UidAzure = "$(Get-UidAzure)"
$UidGcp = "$(Get-UidGcp)"

if ( $UidAws -eq "null" ) {
  $Uid = New-Uid
  Write-Host "Generated new AWS identifier: $Uid"
  (jq --arg aws "$Uid" '.uid.aws = $aws' "$DeployConfig") | Set-Content $DeployConfig
}

if ( $UidAzure -eq "null" ) {
  $Uid = New-Uid
  Write-Host "Generated new Azure identifier: $Uid"
  (jq --arg azure "$Uid" '.uid.azure = $azure' "$DeployConfig") | Set-Content $DeployConfig
}

if ( $UidGcp -eq "null" ) {
  $Uid = New-Uid
  Write-Host "Generated new AWS identifier: $Uid"
  (jq --arg gcp "$Uid" '.uid.gcp = $gcp' "$DeployConfig") | Set-Content $DeployConfig
}

$Regions = "$(Get-Regions)"
$SelectedRegionAws = "$(Get-RegionAws)"
$SelectedRegionAzure = "$(Get-RegionAzure)"
$SelectedRegionGcp = "$(Get-RegionGcp)"
$NumberRegionsEnabled = 0

if ( $SelectedRegionAws -eq "null" ) {
  $SelectedRegionAws = "none"
  (jq '.regions.aws = "none"' $DeployConfig) | Set-Content $DeployConfig
}

if ( $SelectedRegionAzure -eq "null" ) {
  $SelectedRegionAzure = "none"
  (jq '.regions.azure = "none"' $DeployConfig) | Set-Content $DeployConfig
}

if ( $SelectedRegionGcp -eq "null" ) {
  $SelectedRegionGcp = "none"
  (jq '.regions.gcp = "none"' $DeployConfig) | Set-Content $DeployConfig
}

if ( $Regions -ne "null" ) {
  if ( $SelectedRegionAws -ne "none" ) {
    $NumberRegionsEnabled++
  }

  if ( $SelectedRegionAzure -ne "none" ) {
    $NumberRegionsEnabled++
  }

  if ( $SelectedRegionGcp -ne "none" ) {
    $NumberRegionsEnabled++
  }
}

if ( $NumberRegionsEnabled -gt 0 -and $NumberRegionsEnabled -lt 3 ) {
  <# Give the option to enable regions not previously enabled #>
  if ( $SelectedRegionAws -eq "none" ) {
    Write-Host ""
    $Reply = Read-Host -Prompt "Would you like to enable AWS? (y/N) "
    Write-Host ""

    if ( $Reply -eq 'y' -or $Reply -eq 'Y' ) {
      Set-RegionAws
    }
  }

  if ( $SelectedRegionAzure -eq "none" ) {
    Write-Host ""
    $Reply = Read-Host -Prompt "Would you like to enable Azure? (y/N) "
    Write-Host ""

    if ( $Reply -eq 'y' -or $Reply -eq 'Y' ) {
      Set-RegionAzure
    }
  }

  if ( $SelectedRegionGcp -eq "none" ) {
    Write-Host ""
    $Reply = Read-Host -Prompt "Would you like to enable GCP? (y/N) "
    Write-Host ""

    if ( $Reply -eq 'y' -or $Reply -eq 'Y' ) {
      Set-RegionGcp
    }
  }
}
elseif ( $NumberRegionsEnabled -eq 0 ) {
  <# Prompt User to select their initial regions. #>
  Set-RegionAws
  Set-RegionAzure
  Set-RegionGcp
}

$Regions = "$(Get-Regions)"
$SelectedRegionAws = "$(Get-RegionAws)"
$SelectedRegionAzure = "$(Get-RegionAzure)"
$SelectedRegionGcp = "$(Get-RegionGcp)"

if ( $SelectedRegionAws -ne "none" ) {
  $DefaultRegionAws = "$(aws configure get region)"

  if ( $SelectedRegionAws -ne $DefaultRegionAws ) {
    Write-Host ""
    Write-Host "Selected AWS region does not match the region used by the AWS CLI. Please re-run \"aws configure\" and update the default region."
    exit 1
  }
}

$AdminLockedDown = Get-AdminLock

if ( $AdminLockedDown -eq "null" ) {
  Write-Host ""
  $Reply = Read-Host -Prompt "Lock down certain administrative services (SSH, RDP, and more) so that they can only be accessed from your current public IP address? NOT recommended if you will be switching networks frequently. (y/N) "
  Write-Host ""

  if ( $Reply -eq 'y' -or $Reply -eq 'Y' ) {
    $AdminLockedDown = "true"
  }
  else {
    $AdminLockedDown = "false"
  }

  (jq --arg admin_locked_down "$AdminLockedDown" '.admin_locked_down = $admin_locked_down' "$DeployConfig") | Set-Content $DeployConfig
}

Write-Host ""
Write-Host "$($PSStyle.Bold)Selected Regions:$($PSStyle.Reset)"
Write-Host ""
Write-Host "$($PSStyle.Bold)AWS: $SelectedRegionAws$($PSStyle.Reset)"
Write-Host "$($PSStyle.Bold)Azure: $SelectedRegionAzure$($PSStyle.Reset)"
Write-Host "$($PSStyle.Bold)GCP: $SelectedRegionGcp$($PSStyle.Reset)"
Write-Host ""
Write-Host "$($PSStyle.Bold)Admin services locked down: $AdminLockedDown$($PSStyle.Reset)"
Write-Host ""

if ( $AdminLockedDown -eq "true" ) {
  $TF_VAR_AllowedAdminCidr = "$((Invoke-WebRequest -Uri ipinfo.io/ip).Content)/32"
}
else {
  $TF_VAR_AllowedAdminCidr = "0.0.0.0/0"
}

if ( Test-Path -Path Get-WksSshPubKeyPath ) {
  $TF_VAR_WorkstationSshPublicKey = "$(Get-WksSshPubKey)"
}

if ( $SelectedRegionAws -ne "none" -or $SelectedRegionAzure -ne "none" -or $SelectedRegionGcp -ne "none" ) {
  <# Turn off gcloud HTTP loggin if it is enabled.  HTTP logging writes to stderr, resulting in deployment appearing as partial #>
  $GcloudLogHttp = "$(gcloud config get-value log_http)"
  if ( $GcloudLogHttp -eq "true" ) {
    gcloud config set log_http false
  }
  
  $arrAws = @("aws", $SelectedRegionAws, $ScriptDir, $TargetDir)
  $arrAzure = @("azure", $SelectedRegionAzure, $ScriptDir, $TargetDir)
  $arrGcp = @("gcp", $SelectedRegionGcp, $ScriptDir, $TargetDir)

  <# Initialize Tfstate and deploy for each provider in parallel #>
  $arrAws, $arrAzure, $arrGcp | ForEach-Object -ThrottleLimit 3 -Parallel {
    $Provider = $_[0]
    $ProviderRegion = $_[1]
    $ScriptRoot = $_[2]
    $ErrDir = $_[3]

    if ( $ProviderRegion -ne "none" ) {
      <# Initialize Tfstate for the provider #>
      $InitializeCommand = "{0}/Initialize-Tfstate{1}.ps1 2>> {2}/deploy_{1}.err" -f $ScriptRoot, $Provider, $ErrDir
      Invoke-Expression $InitializeCommand

      <# Deploy Infrastructure for the provider #>
      $DeployCommand = "{0}/Deploy-{1}.ps1 2>> {2}/deploy_{1}.err" -f $ScriptRoot, $Provider, $ErrDir
      Invoke-Expression $DeployCommand
    }
  }

  <# Restore gcloud HTTP logging if necessary #>
  if ( $GcloudLogHttp -eq "true" ) {
    gcloud config set log_http false
  }

  if (((Get-Content -Path $TargetDir/deploy_aws.err).Length -gt 0) -or `
    ((Get-Content -Path $TargetDir/deploy_azure.err).Length -gt 0) -or `
    ((Get-Content -Path $TargetDir/deploy_gcp.err).Length -gt 0)) {

    Get-Content $TargetDir/deploy_*.err

    Write-Host ""
    Write-Host "$($PSStyle.Bold)Incomplete deployment:$($PSStyle.Reset)"
    Write-Host ""

    if ($SelectedRegionAws -ne "none") {
      if ( (Get-Content -Path $TargetDir/deploy_aws.err).Length -gt 0 ) {
        Write-Host "$($PSStyle.Foreground.BrightRed)$($PSStyle.Bold)AWS: Partial Deployment$($PSStyle.Reset)"
      }
      else {
        Write-Host "$($PSStyle.Foreground.BrightGreen)$($PSStyle.Bold)AWS: Deployment Successful!$($PSStyle.Reset)"
      }
    }

    if ($SelectedRegionAzure -ne "none") {
      if ( (Get-Content -Path $TargetDir/deploy_azure.err).Length -gt 0 ) {
        Write-Host "$($PSStyle.Foreground.BrightRed)$($PSStyle.Bold)Azure: Partial Deployment$($PSStyle.Reset)"
      }
      else {
        Write-Host "$($PSStyle.Foreground.BrightGreen)$($PSStyle.Bold)Azure: Deployment Successful!$($PSStyle.Reset)"
      }
    }

    if ($SelectedRegionGcp -ne "none") {
      if ( (Get-Content -Path $TargetDir/deploy_gcp.err).Length -gt 0 ) {
        Write-Host "$($PSStyle.Foreground.BrightRed)$($PSStyle.Bold)GCP: Partial Deployment$($PSStyle.Reset)"
      }
      else {
        Write-Host "$($PSStyle.Foreground.BrightGreen)$($PSStyle.Bold)GCP: Deployment Successful!$($PSStyle.Reset)"
      }
    }

    Write-Host ""
    Write-Host "$($PSStyle.Bold)You can proceed for all successful deployments.$($PSStyle.Reset)"
    Write-Host "For the partial deployments, please re-run the deployment one time to resolve intermittent issues."
    Write-Host "If issues persist, please review the error logs in the $TargetDir directory."

    [System.Console]::Beep()
    exit 1
  }
}

Write-Host ""
Write-Host "$($PSStyle.Foreground.BrightGreen)$($PSStyle.Bold)All Deployments Successful!$($PSStyle.Reset)"
Write-Host ""

[System.Console]::Beep()

Set-Location $CallingDir