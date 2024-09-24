variable "id_aws" {
  description = "This is a unique identifier associated with AWS that must be the same on every Terraform run. It will be used to create infrastructure that needs a globally unique name (Ex. S3 buckets)."
  type        = string
  default     = null
}

variable "deploy_config" {
  description = "Path to the cloud deployment file."
  type        = string
  default     = null
}