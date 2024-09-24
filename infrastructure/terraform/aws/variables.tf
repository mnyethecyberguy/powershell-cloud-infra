variable "uid_aws" {
  description = "This is a unique identifier for AWS. It will be used to create globally unique resources (Ex. S3 buckets)."
  type        = string
  default     = null
}

variable "deploy_config" {
  description = "Path to the cloud deployment file."
  type        = string
  default     = null
}