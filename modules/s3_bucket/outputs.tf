output "bucket_arn" {
  description = "ARN of the inventory S3 bucket."
  value       = aws_s3_bucket.s3_bucket.arn
}