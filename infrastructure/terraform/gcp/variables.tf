variable "id_gcp" {
  description = "This is a unique identifier for GCP. It will be used to create globally unique resources (Ex. storage buckets)."
  type        = string
  default     = null
}

variable "deploy_config" {
  description = "Path to the cloud deployment file."
  type        = string
  default     = null
}