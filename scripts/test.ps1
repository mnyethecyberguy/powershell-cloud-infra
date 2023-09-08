$ScriptDir = Split-Path -parent $MyInvocation.MyCommand.Path
Import-Module $PSScriptRoot/PwshCloudInfrastructure.psm1 -Force
Write-Host "PSScriptRoot: $PSScriptRoot"
Write-Host "ScriptDir: $ScriptDir"
# Write-Host "Errors Dir: $(Get-ErrorsDir)"
# Write-Host "Deploy File Path Function: $(Get-DeployFilePath)"
# Write-Host "Hash Table Variable SupportedRegionsAws: $(Get-SupportedRegionsAws)"
# Write-Host "Hash Table Variable SupportedRegionsAzure: $(Get-SupportedRegionsAzure)"
# Write-Host "Hash Table Variable SupportedRegionsGcp: $(Get-SupportedRegionsGcp)"
#Set-RegionAws
#Set-RegionAzure
#Set-RegionGcp
#Start-Sleep -Seconds 10
# $DeployFile = "$(Get-DeployFilePath)"
# if ( -not ( Test-Path -Path $DeployFile ) ) {
#     Write-Host "No Deploy file exists, creating now"
#     Write-Output "{}" | Set-Content $DeployFile
# }
# else {
#     Write-Host "Deploy File already exists: $DeployFile"
# }

# $test_unique_string = Get-UniqueStringAws
# Write-Host ("**Unique String AWS: $test_unique_string**" | ConvertFrom-Markdown -AsVT100EncodedString).VT100EncodedString -NoNewline

# if ( $test_unique_string -eq "null") {
#     $test_unique = New-UniqueString
#     Write-Host "Generated new AWS identifier: $test_unique"
#     (jq --arg aws "$test_unique" '.unique_strings.aws = $aws' "$DeployFile") | Set-Content $DeployFile
# }


# (jq '.regions.aws = "none"' $DeployFile) | Set-Content $DeployFile
# (jq '.regions.azure = "none"' $DeployFile) | Set-Content $DeployFile
# (jq '.regions.gcp = "none"' $DeployFile) | Set-Content $DeployFile
# if ( Get-UniqueStringAzure -eq "null") {
#     $UNIQUE_STRING = New-UniqueString
#     Write-Host "Generated new Azure identifier: $UNIQUE_STRING"
#     (jq --arg azure "$UNIQUE_STRING" '.unique_strings.azure = $azure' "$DeployFile") | Set-Content $DeployFile
#   }
  
#   if ( Get-UniqueStringGcp -eq "null") {
#     $UNIQUE_STRING = New-UniqueString
#     Write-Host "Generated new AWS identifier: $UNIQUE_STRING"
#     (jq --arg gcp "$UNIQUE_STRING" '.unique_strings.gcp = $gcp' "$DeployFile") | Set-Content $DeployFile
#   }

$TEST_AWS_REGION = "$(Get-RegionAws)"
$TEST_AZURE_REGION = "$(Get-RegionAzure)"
$TEST_GCP_REGION = "$(Get-RegionGcp)"
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

$arrAws = @("aws", $TEST_AWS_REGION, $PSScriptRoot, $TargetDir)
$arrAzure = @("azure", $TEST_AZURE_REGION, $PSScriptRoot, $TargetDir)
$arrGcp = @("gcp", $TEST_GCP_REGION, $PSScriptRoot, $TargetDir)

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

#if ( Test-Path -Path $TargetDir/deploy_aws.err -or Test-Path -Path $TargetDir/deploy_azure.err -or Test-Path -Path $TargetDir/deploy_gcp.err ) {
if ( Test-Path -Path $TargetDir/deploy_aws.err, $TargetDir/deploy_azure.err, $TargetDir/deploy_gcp.err ) {
    Get-Content $TargetDir/deploy_*.err

    Write-Host ""
    Write-Host "Incomplete deployment:"
    Write-Host ""
}
