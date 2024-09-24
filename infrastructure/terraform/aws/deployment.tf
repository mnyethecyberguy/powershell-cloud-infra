resource "aws_s3_bucket" "deployment" {
  bucket        = "pwsh-deployment-${var.uid_aws}"
  force_destroy = true
}