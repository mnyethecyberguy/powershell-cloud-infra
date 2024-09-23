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
if ( $(aws cloudtrail list-trails | jq '.Trails[] | select(.name=="pwsh-cloud-trail").name') -ne $null ) {
  Write-Host "CloudTrail still exists."
}

<# Check if tfstate bucket exists #>
if ( $(aws s3api list-buckets --query "Buckets[].Name" | jq -r '.[] | select(startswith("pwsh-tfstate"))') -ne $null ) {
  Write-Host "tfstate S3 bucket still exists."
}

<# Check if deployment bucket exists #>
if ( $(aws s3api list-buckets --query "Buckets[].Name" | jq -r '.[] | select(startswith("deployment"))') -ne $null ) {
  Write-Host "deployment S3 bucket still exists."
}

<# Check if EC2 instance exists #>
if ( $(aws ec2 describe-instances --filters Name=tag-value,Values=bwsrv --query Reservations[0]) -ne "null" ) {
  Write-Host "EC2 instance exists."
}