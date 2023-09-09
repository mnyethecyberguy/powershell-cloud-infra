# powershell-cloud-infra

This is a framework of PowerShell scripts and Terraform for deploying and tearing down cloud infrastructure across the big 3 cloud providers: AWS, Azure, and GCP.  The terraform files can be used to deploy and manage virtual networking, storage buckets, serverless functions, IAM policies, key management, database services, and logging.

This is suitable for lab or sandbox environments and for testing purposes.  Not recommended for production environments.

## Dependencies

- PowerShell 7.0+
- CLI tools installed and configured for each of the 3 cloud providers: `awscliv2`, `azurecli`, `gcloud`
- Terraform installed
- `jq` for parsing JSON

## Supported Regions

The default configuration of the scripts allows for using regions in the US only.  To change the available regions per provider, modify the `SupportedRegionsAws`, `SupportedRegionsAzure`, and `SupportedRegionsGcp` keys respectively within the `PwshCloudInfrastructure.psm1` module.

```
$PwshCloudInfrastructure = [ordered]@{
  DeployFile            = "$(Split-Path $PSScriptRoot)/deploy_config.json"
  ErrorsDir             = "$(Split-Path $PSScriptRoot)/deploy_errors"
  SupportedRegionsAws   = "us-east-1", "us-east-2", "us-west-1", "us-west-2"
  SupportedRegionsAzure = "eastus", "eastus2", "centralus", "southcentralus", "westus", "westus2", "westus3"
  SupportedRegionsGcp   = "us-east1", "us-east4", "us-east5", "us-central1", "us-south1", "us-west1", "us-west2"
  WksSshPubKey          = "$(Split-Path $PSScriptRoot)/id_rsa.pub"
}
```

## Default Deployments

The deployment scripts and Terraform files are preconfigured with some basic resources and can be modified as needed.  You will need to know what SKUs are available in your regions for successful deployment, particularly for compute resources.

### Default VM SKUs

- AWS: `t2.micro` (configured in ./infrastructure/terraform/aws/vm.tf)
- Azure: `Standard_DS1_v2` (configured in ./infrastructure/terraform/azure/vm.tf)
- GCP: `n2-standard-2` (configured in ./infrastructure/terraform/gcp/vm.tf)

### Default Files

- `./deploy_config.json` - This file will be built in the root of the project folder and updated by the deployment scripts to track regions and unique identifiers for each provider
- `~/.ssh/id_rsa.pub` and `~/.ssh/id_rsa` - An SSH keypair needs to be pre-created that will be uploaded to the created VMs for SSH

### Default Storage Buckets

- `deployment` - will be used to store a copy of the `deploy_config.json` file and any additional files needed for deployment and setup of infrastructure, including startup scripts and serverless functions.
- `tfstate` - The Terraform state will be configured to use a backend stored in each providers respective environments

## Folder Structure

- [infrastructure](./infrastructure) - Infrastructure-as-Code used to deploy infrastructure to the 3 cloud providers.
- [scripts](./scripts) - PowerShell scripts used to configure, deploy, and teardown your cloud environments.

## PowerShell Scripts

- [PwshCloudInfrastructure.psm1](./modules/PwshCloudInfrastructure.psm1) - Primary module containing functions and variables used throughout the deployment scripts.
- [Deploy-Infrastructure.ps1](./scripts/Deploy-Infrastructure.ps1) - Deploys infrastructure using Terraform. Calls
    - [Initialize-TfstateAws.ps1](./scripts/Initialize-TfstateAws.ps1)
    - [Initialize-TfstateAzure.ps1](./scripts/Initialize-TfstateAzure.ps1)
    - [Initialize-TfstateGcp.ps1](./scripts/Initialize-TfstateGcp.ps1)
    - [Deploy-Aws.ps1](./scripts/Deploy-Aws.ps1)
    - [Deploy-Azure.ps1](./scripts/Deploy-Azure.ps1)
    - [Deploy-Gcp.ps1](./scripts/Deploy-Gcp.ps1)
- [Remove-Infrastructure.ps1](./scripts/Remove-Infrastructure.ps1) - Removes infrastructure using Terraform. Calls
    - [Remove-Aws.ps1](./scripts/Remove-Aws.ps1)
    - [Remove-Azure.ps1](./scripts/Remove-Azure.ps1)
    - [Remove-Gcp.ps1](./scripts/Remove-Gcp.ps1)

**Other scripts:**

- [Confirm-ResourcesAws.ps1](./scripts/Confirm-ResourcesAws.ps1) / [Confirm-ResourcesAzure.ps1](./scripts/Confirm-ResourcesAzure.ps1) / [Confirm-ResourcesGcp.ps1](./scripts/Confirm-ResourcesGcp.ps1) - Checks whether or not key cloud resources for the given provider exist, if the given cloud has its CLI properly configured. Performed after a teardown, if the given cloud is torn down, to reduce the risk that resources remain which would incur charges. Includes Terraform state and deployment buckets.

## Usage

To deploy the desired infrastructure to one or more providers, simply run
`pwsh /<repo root>/scripts/Deploy-Infrastructure.ps1`

To completely teardown infrastructure for one or more providers use
`pwsh /<repo root>/scripts/Remove-Infrastructure.ps1`

## Service Account Permissions

The accounts used to configure the CLI tools should have the necessary permissions for management of whatever resources you choose to define in your Terraform files.

### AWS

- `AdministratorAccess` for the given account may be suitable for lab/testing environments but it is highly recommended to reduce these permissions in any production environment.

### Azure

- `Global Admin` permissions may work for a lab/testing environment but should not be used for production environments.

### GCP

- `Project IAM Admin` is sufficient for the GCP service account to assign the required permissions to itself.  This can be reduced in a production environment.  Minimal permissions required:
  - cloudkms.admin
  - cloudkms.cryptoKeyEncrypter
  - cloudsql.admin
  - compute.admin
  - iam.roleAdmin
  - iam.serviceAccountAdmin
  - iam.serviceAccountUser
  - resourcemanager.projectIamAdmin
  - iam.securityAdmin
  - iam.serviceAccountKeyAdmin
  - secretmanager.admin
  - servicenetworking.networksAdmin
  - serviceusage.serviceUsageAdmin
  - storage.admin
  - logging.admin
  - cloudfunctions.admin
  - deploymentmanager.editor
  - appengine.appAdmin
  - appengine.serviceAdmin
  - appengine.appCreator
  - cloudbuild.builds.editor

