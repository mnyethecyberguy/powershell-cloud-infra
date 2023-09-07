$ScriptDir = Split-Path -parent $MyInvocation.MyCommand.Path
Import-Module $PSScriptRoot/PwshCloudInfrastructure.psm1 -Force
Write-Host "PSScriptRoot: $PSScriptRoot"
Write-Host "ScriptDir: $ScriptDir"
Write-Host "Deploy file: $DEPLOY_FILE"
Write-Host "Errors Dir: $ERRORS_DIR"
Write-Host "Deploy File Path Function: $(Get-DeployFilePath)"
Write-Host "Hash Table Variable AWS Regions: $(Get-SupportedRegionsAws)"
#Set-RegionAws
#Set-RegionAzure
#Set-RegionGcp
#Start-Sleep -Seconds 10
if ( -not ( Test-Path -Path $DEPLOY_FILE ) ) {
    Write-Host "No Deploy file exists, creating now"
    Write-Output "{}" | Set-Content $DEPLOY_FILE
}
else {
    Write-Host "Deploy File already exists: $(Get-DeployFilePath)"
}

$test_unique_string = Get-UniqueStringAws
Write-Host ("**Unique String AWS: $test_unique_string**" | ConvertFrom-Markdown -AsVT100EncodedString).VT100EncodedString -NoNewline

if ( $test_unique_string -eq "null") {
    $test_unique = New-UniqueString
    Write-Host "Generated new AWS identifier: $test_unique"
    (jq --arg aws "$test_unique" '.unique_strings.aws = $aws' "$DEPLOY_FILE") | Set-Content $DEPLOY_FILE
}


# (jq '.regions.aws = "none"' $DEPLOY_FILE) | Set-Content $DEPLOY_FILE
# (jq '.regions.azure = "none"' $DEPLOY_FILE) | Set-Content $DEPLOY_FILE
# (jq '.regions.gcp = "none"' $DEPLOY_FILE) | Set-Content $DEPLOY_FILE
# if ( Get-UniqueStringAzure -eq "null") {
#     $UNIQUE_STRING = New-UniqueString
#     Write-Host "Generated new Azure identifier: $UNIQUE_STRING"
#     (jq --arg azure "$UNIQUE_STRING" '.unique_strings.azure = $azure' "$DEPLOY_FILE") | Set-Content $DEPLOY_FILE
#   }
  
#   if ( Get-UniqueStringGcp -eq "null") {
#     $UNIQUE_STRING = New-UniqueString
#     Write-Host "Generated new AWS identifier: $UNIQUE_STRING"
#     (jq --arg gcp "$UNIQUE_STRING" '.unique_strings.gcp = $gcp' "$DEPLOY_FILE") | Set-Content $DEPLOY_FILE
#   }

$TEST_AWS_REGION = "$(Get-RegionAws)"
$TEST_AZURE_REGION = "$(Get-RegionAzure)"
$TEST_GCP_REGION = "$(Get-RegionGcp)"

$arrAws = @("aws", $TEST_AWS_REGION)
$arrAzure = @("azure", $TEST_AZURE_REGION)
$arrGcp = @("gcp", $TEST_GCP_REGION)

$arrAws, $arrAzure, $arrGcp | ForEach-Object -Parallel {
    $prov = $_[0]
    $provregion = $_[1]
    # $message = "I am: {0}, my region is: {1}" -f $prov, $provregion
    # Write-Host $message
    Invoke-Expression "$ScriptDir/initialize_tfstate_$prov.ps1" #$(Join-Path -Path $PWD -ChildPath initialize_tfstate_$prov.ps1)
    #$ScriptDir/initialize_tfstate_$prov.ps1
} -ThrottleLimit 3
