function Get-UniqueStringAws() {
  Get-Content $DEPLOY_FILE | jq -r '.unique_strings.aws'
}

function Get-UniqueStringAzure() {
  Get-Content $DEPLOY_FILE | jq -r '.unique_strings.azure'
}
  
function Get-UniqueStringGcp() {
  Get-Content $DEPLOY_FILE | jq -r '.unique_strings.gcp'
}
  
function Get-RegionAws() {
  Get-Content $DEPLOY_FILE | jq -r '.regions.aws'
}
  
function Get-RegionAzure() {
  Get-Content $DEPLOY_FILE | jq -r '.regions.azure'
}
  
function Get-RegionGcp() {
  Get-Content $DEPLOY_FILE | jq -r '.regions.gcp'
}
  
function Get-Regions() {
  Get-Content $DEPLOY_FILE | jq -r '.regions'
}
  
function Get-AdminLock() {
  Get-Content $DEPLOY_FILE | jq -r '.admin_locked_down'
}
  
function Test-AwsEnabled() {
  $SELECTED_AWS_REGION = Get-RegionAws
  
  if ( $SELECTED_AWS_REGION -ne "null" -and $SELECTED_AWS_REGION -ne "none" ) {
    Write-Output "true"
  }
  else {
    Write-Output "false"
  }
}
  
function Test-AzureEnabled() {
  $SELECTED_AZURE_REGION = Get-RegionAzure
  
  if ( $SELECTED_AZURE_REGION -ne "null" -and $SELECTED_AZURE_REGION -ne "none" ) {
    Write-Output "true"
  }
  else {
    Write-Output "false"
  }
}
  
function Test-GcpEnabled() {
  $SELECTED_GCP_REGION = Get-RegionGcp
  
  if ( $SELECTED_GCP_REGION -ne "null" -and $SELECTED_GCP_REGION -ne "none" ) {
    Write-Output "true"
  }
  else {
    Write-Output "false"
  }
}
  
function Select-Region() {
  param (
    [Parameter(Mandatory)]
    [string]$Provider
  )

  

}
  
  select_region() {
    TOTAL_REGIONS=$#
    PROVIDER=$1
    shift
  
    echo ""
  
    export PS3="
  Select a supported $PROVIDER region: "
  
    select SELECTION in "$@" none
    do
      if [[ "$SELECTION" ]]
      then
        jq --arg region "$SELECTION" --arg provider "$PROVIDER" '.regions[$provider] = $region' "$DEPLOY_FILE" | sudo sponge "$DEPLOY_FILE" > /dev/null
        break
      else
        echo ""
        echo "Invalid selection. Type a number between 1 and $TOTAL_REGIONS."
        exit 1
      fi
    done
  }
  
function Set-RegionAws() {
  Select-Region aws us-east-1 us-east-2 us-west-1 us-west-2
}

function Set-RegionAzure() {
  Select-Region azure eastus eastus2 centralus southcentralus westus westus2 westus3
}

function Set-RegionGcp() {
  Select-Region gcp us-east1 us-east4 us-east5 us-central1 us-south1 us-west1 us-west2
}

function Get-WksSshPubKey() {
  Get-Content $WKS_SSH_PUB_KEY
}
