variable "uid_azure" {
  description = "This is a unique identifier for Azure. It will be used to create globally unique resources (Ex. storage accounts)."
  type        = string
  default     = null
}

variable "deploy_config" {
  description = "Path to the cloud deployment file."
  type        = string
  default     = null
}