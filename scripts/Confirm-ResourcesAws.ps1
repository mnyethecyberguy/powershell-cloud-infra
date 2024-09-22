Write-Host ""
Write-Host "Confirming AWS resources are removed....."
Write-Host ""

$ModuleDir = "$(Split-Path $PSScriptRoot)/modules"
Import-Module $ModuleDir/PwshCloudInfrastructure.psm1 -Force

$CallingDir = "$PWD"
$ScriptDir = "$($(Set-Location $PSScriptRoot) > $null && $PWD)"

$DeployFile = $(Get-DeployFilePath)
$UniqueStringAws = "$(Get-UniqueStringAws)"

<# Check if CloudTrail exists #>
if ( $(aws cloudtrail list-trails | jq '.Trails[] | select(.name=="pwsh-cloud-trail").name') -ne "" ) {
  Write-Host "CloudTrail still exists."
}

<# Check if tfstate bucket exists #>
if ( $(aws s3api list-buckets --query "Buckets[?Name == ``pwsh-tfstate-$UniqueStringAws``]" | jq '. | length') -ne 0 ) {
  Write-Host "tfstate bucket still exists."
}

<# Check if tfstate bucket exists #>
if ( $(aws s3api list-buckets --query "Buckets[].Name" | jq -r '.[] | select(startswith("pwsh-tfstate"))') -ne 0 ) {
    Write-Host "tfstate bucket still exists."
}

<# Check if EC2 instance exists #>