resource "aws_s3_bucket" "cloudtrail" {
  bucket        = "pwsh-cloudtrail-${var.id_aws}"
  force_destroy = true
}