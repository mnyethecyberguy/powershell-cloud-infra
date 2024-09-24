resource "aws_s3_bucket" "cloudtrail" {
  bucket        = "pwsh-cloudtrail-${var.uid_aws}"
  force_destroy = true
}