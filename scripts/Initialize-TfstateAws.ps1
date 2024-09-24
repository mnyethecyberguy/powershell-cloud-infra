

$ModuleDir = "$(Split-Path $PSScriptRoot)/modules"
Import-Module $ModuleDir/PwshCloudInfrastructure.psm1 -Force

$Regions = "$(Get-Regions)"
$UidAws = "$(Get-UidAws)"
$DefaultRegionAws = "$(Get-RegionAws)"

if ( ($Regions -eq "null") -or ($UidAws -eq "null") -or ($DefaultRegionAws -eq "none")) {
  Write-Host "AWS not configured.  Please run Deploy-Infrastructure.ps1 to enable AWS."
  exit 1
}

Write-Host ""
Write-Host "Initializing AWS Tfstate....."
Write-Host "AWS Deployment ID: $UidAws"
Write-Host ""

Write-Host "Checking for AWS Terraform state bucket..."
$BucketName = "pwsh-tfstate-$UidAws"
$BucketExists = "$(aws s3api list-buckets --query "Buckets[?Name == ``$BucketName``]" | jq '. | length')"

if ( $BucketExists -eq 0 ) {
  Write-Host "AWS Terraform state bucket $BucketName does not exist. Creating now..."
  aws s3api create-bucket --bucket $BucketName --region $DefaultRegionAws --create-bucket-configuration LocationConstraint=$DefaultRegionAws
  #aws s3api put-bucket-versioning --bucket $BucketName --versioning-configuration Status=Enabled
}
else {
  Write-Host "AWS Terraform state bucket $BucketName already exists."
}

Write-Host "End Initializing AWS Tfstate bucket"
Write-Host ""