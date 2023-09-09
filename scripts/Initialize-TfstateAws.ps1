

$ModuleDir = "$(Split-Path $PSScriptRoot)/modules"
Import-Module $ModuleDir/PwshCloudInfrastructure.psm1 -Force

$Regions = "$(Get-Regions)"
$UniqueStringAws = "$(Get-UniqueStringAws)"
$DefaultRegionAws = "$(Get-RegionAws)"

if ( ($Regions -eq "null") -or ($UniqueStringAws -eq "null") -or ($DefaultRegionAws -eq "none")) {
  Write-Host "AWS not configured.  Please run Deploy-Infrastructure.ps1"
}

Write-Host ""
Write-Host "Initializing AWS Tfstate....."
Write-Host "AWS Deployment ID: $UniqueStringAws"
Write-Host ""

Write-Host "Checking for AWS Terraform state bucket..."
$BucketName = "tf-$UniqueStringAws"
#$BucketExists = "$(aws s3api list-buckets --query "Buckets[?Name == $BucketName]" | jq '. | length')"

if ( $(aws s3api list-buckets --query "Buckets[].Name" | jq -r '.[] | select(startswith("tf"))') -eq "" ) {
  Write-Host "AWS Terraform state bucket $BucketName does not exist. Creating now..."
  aws s3api create-bucket --bucket $BucketName --region $DefaultRegionAws --create-bucket-configuration LocationConstraint=$DefaultRegionAws
  #aws s3api put-bucket-versioning --bucket $BucketName --versioning-configuration Status=Enabled
}
else {
  Write-Host "AWS Terraform state bucket $BucketName already exists."
}

Write-Host "End Initializing AWS Tfstate bucket"
Write-Host ""