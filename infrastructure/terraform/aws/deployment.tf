resource "aws_s3_bucket" "deployment" {
  bucket        = "pwsh-deployment-${var.id_aws}"
  force_destroy = true
}