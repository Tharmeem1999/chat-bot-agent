resource "aws_s3_object" "object" {
  bucket = var.bucket_name
  key    = var.bucket_key
  source = var.bucket_source
}