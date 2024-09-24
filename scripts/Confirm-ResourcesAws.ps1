Write-Host ""
Write-Host "Confirming AWS resources are removed....."
Write-Host ""

$ModuleDir = "$(Split-Path $PSScriptRoot)/modules"
Import-Module $ModuleDir/PwshCloudInfrastructure.psm1 -Force

#$CallingDir = "$PWD"
#$ScriptDir = "$($(Set-Location $PSScriptRoot) > $null && $PWD)"

#$DeployFile = $(Get-DeployFilePath)
#$UniqueStringAws = "$(Get-UniqueStringAws)"

<# Check if CloudTrail exists #>
if ( $null -ne $(aws cloudtrail list-trails | jq '.Trails[] | select(.name=="pwsh-cloudtrail").name') ) {
  Write-Host "CloudTrail still exists."
}

<# Check if tfstate bucket exists #>
if ( $null -ne $(aws s3api list-buckets --query "Buckets[].Name" | jq -r '.[] | select(startswith("pwsh-tfstate"))') ) {
  Write-Host "tfstate S3 bucket still exists."
}

<# Check if deployment bucket exists #>
if ( $null -ne $(aws s3api list-buckets --query "Buckets[].Name" | jq -r '.[] | select(startswith("pwsh-deployment"))') ) {
  Write-Host "deployment S3 bucket still exists."
}

<# Check if EC2 instance exists #>
if ( "null" -ne $(aws ec2 describe-instances --filters Name=tag-value,Values=bwsrv --query Reservations[0]) ) {
  Write-Host "EC2 instance exists."
}